import 'dart:typed_data';

import 'package:omr_core/omr_core.dart'
    show MarkedResponse, QuestionId, SheetRead;
import 'package:omr_spec/omr_spec.dart' show DetectionTemplate;

import '../cv/opencv_service.dart'
    show CvExclude, CvMat, CvPointI, CvRectI, CvSizeI, OpencvService;
import '../decode/field_decoder.dart' show FieldDecoder;
import '../models/bubble_read.dart' show FieldRead;
import '../registration/curvature_gate.dart' show CurvatureGate, CurvatureReport;
import '../registration/fiducial_registrar.dart'
    show FiducialMatch, FiducialRegistrar, FiducialSearch, RegistrationReport,
        fiducialSearchPlan;
import '../registration/homography_warper.dart' show HomographyWarper;
import '../thresholds/threshold_config.dart' show ThresholdConfig;
import '../thresholds/threshold_engine.dart'
    show ThresholdEngine, ThresholdResult;
import 'bubble_classifier.dart' show BubbleClassifier;
import 'bubble_reader.dart' show BubbleReader;
import 'confidence_aggregator.dart'
    show ConfidenceAggregator, RegistrationQuality;

/// Which rung of the registration ladder produced the warp (plan §3).
enum RegistrationPath {
  /// Rung 1: all four anchors found in their quadrants — the primary path.
  fiducialQuadrant,

  /// Rung 2: a rejected corner recovered by unrestricted re-search (with the
  /// L template where the alt anchor is printed). Proceeds un-capped: these
  /// are still printed anchors, only the search window widened.
  fiducialRelaxed,

  /// Rung 3: anchors unusable, the page outline (capture-loop quad) warped
  /// onto the canvas instead. Paper edges are weaker evidence than printed
  /// anchors — the read proceeds but confidence is capped below the review
  /// floor, so the sheet always lands in the review queue.
  ///
  /// The plan's rung 3 names a timing-track least-squares affine; measuring
  /// the timing track in the UNWARPED image is circular (its expected
  /// positions are canvas coordinates), so this rung uses the page quad —
  /// available now, affine-plus-perspective, and honestly weaker, which is
  /// exactly what the confidence cap encodes. The timing track keeps its
  /// designed role: curvature validation after the warp.
  pageQuad,

  /// Rung 4: nothing registered. The still is rejected for human
  /// corner-drag, not silently graded.
  none,
}

/// Why a still was rejected outright (reason codes, plan §3 ladder rung 4).
enum RejectionReason {
  /// No fiducials matched and the page outline yielded no usable quad —
  /// the capture never showed a registerable sheet.
  noRegistration,
}

enum StageStatus { ok, fallback, failed, skipped }

/// One pipeline stage's outcome, for per-stage error attribution (plan §9).
class StageTraceEntry {
  const StageTraceEntry({
    required this.stage,
    required this.status,
    required this.detail,
    required this.elapsedMicros,
  });

  final String stage;
  final StageStatus status;

  /// Human-readable numbers (scores, residuals, counts) — what the harness
  /// prints when a golden-image run fails and needs attributing.
  final String detail;
  final int elapsedMicros;

  @override
  String toString() => '$stage:${status.name}($elapsedMicros µs) $detail';
}

/// Everything one still's evaluation produced — the read the grading engine
/// consumes, plus the intermediate verdicts the review queue and the golden
/// harness attribute errors with. Rejection is a VALUE, not an exception:
/// capture problems are normal operator reality, not control flow.
class StillEvaluation {
  const StillEvaluation({
    required this.read,
    required this.fields,
    required this.registrationPath,
    required this.trace,
    this.thresholds,
    this.curvature,
    this.registration,
    this.rejection,
  });

  /// Terminal result: responses, roll, set code, flags, confidences. Empty
  /// (and zero-confidence) when [rejected].
  final SheetRead read;

  /// Classified fields with confidences, sheet order. Empty when rejected.
  final List<FieldRead> fields;

  final ThresholdResult? thresholds;
  final CurvatureReport? curvature;
  final RegistrationReport? registration;
  final RegistrationPath registrationPath;
  final List<StageTraceEntry> trace;
  final RejectionReason? rejection;

  bool get rejected => rejection != null;

  /// Review routing: rejection, or any read flag (by construction a flag IS
  /// a review reason — the decoder raises one for every anomaly it routes).
  bool get needsReview => rejected || read.flags.isNotEmpty;
}

/// Orchestrates stages 1–10 over one grayscale still (plan §3).
///
/// Constructed once per layout and reused across stills; every stage is a
/// const-constructible value object, so the orchestrator carries no per-sheet
/// state beyond what it returns. Per-stage timings land in the trace — the
/// M1 acceptance criteria are judged from that, not from ad-hoc prints.
class OmrPipeline {
  const OmrPipeline({
    required this.cv,
    required this.template,
    this.thresholdConfig = const ThresholdConfig(),
    this.registrar = const FiducialRegistrar(),
    this.roster,
    this.pageQuadConfidenceCap = 0.75,
  });

  final OpencvService cv;
  final DetectionTemplate template;
  final ThresholdConfig thresholdConfig;

  /// Stage-2 matcher; overridable so the ladder can be force-failed in
  /// tests (an acceptScore beyond TM_CCOEFF_NORMED's range).
  final FiducialRegistrar registrar;

  /// Roll numbers known to the institute; null skips the roster check.
  final Set<String>? roster;

  /// Cap applied on the rung-3 page-quad path. The default sits below the
  /// 0.90 review floor so a page-quad read ALWAYS routes to review.
  final double pageQuadConfidenceCap;

  /// Evaluates one decoded grayscale still.
  ///
  /// [grayBytes] is row-major, one byte per pixel, [imageWidth] ×
  /// [imageHeight]. Decoding the camera's JPEG/YUV to this buffer belongs to
  /// the caller (the capture isolate) — the pipeline starts at plan §3
  /// stage 2, registration.
  StillEvaluation evaluateGray(
    int imageWidth,
    int imageHeight,
    Uint8List grayBytes,
  ) {
    final trace = <StageTraceEntry>[];
    final gray = cv.grayFromBytes(imageWidth, imageHeight, grayBytes);
    try {
      return _evaluate(gray, imageWidth, imageHeight, trace);
    } finally {
      cv.dispose(gray);
    }
  }

  StillEvaluation _evaluate(
    CvMat gray,
    int imageWidth,
    int imageHeight,
    List<StageTraceEntry> trace,
  ) {
    // ------------------------------------------------------ registration
    final plan = fiducialSearchPlan(template, imageWidth, imageHeight);
    final regWatch = Stopwatch()..start();
    var registration = registrar.register(
      cv,
      gray,
      plan,
      imageWidth: imageWidth,
    );
    var path = RegistrationPath.fiducialQuadrant;
    double? confidenceCap;

    // Rung 2 (filled in only when the quadrant pass fails): unrestricted
    // re-search of each rejected corner, with the L template where the alt
    // anchor is printed. The anchors the quadrant pass accepted are
    // suppressed as targets — a square re-search would otherwise land on a
    // NEIGHBOUR's identical square at full score. An empty string once the
    // ladder leaves this block means "no recovery attempt was blocked".
    var recoveryBlocked = '';
    if (!registration.ok) {
      final exclude = <CvExclude>[
        for (final i in registration.accepted)
          if (registration.matches[i] != null)
            CvExclude(
              x: registration.matches[i]!.center.x.toDouble(),
              y: registration.matches[i]!.center.y.toDouble(),
              r: _excludeRadius(plan[i].baseBlackPx,
                  registration.matches[i]!.scale),
            ),
      ];
      final recovered = <int, FiducialMatch>{};
      for (var i = 0; i < plan.length; i++) {
        if (registration.accepted.contains(i)) continue;
        final match = registrar.reSearch(
          cv,
          gray,
          plan[i],
          imageWidth: imageWidth,
          imageHeight: imageHeight,
          exclude: exclude,
        );
        if (match != null && match.score >= registrar.acceptScore) {
          recovered[i] = match;
          // A recovered anchor is as much "already claimed" as an accepted
          // one — later re-searches must not land on it either.
          exclude.add(CvExclude(
            x: match.center.x.toDouble(),
            y: match.center.y.toDouble(),
            r: _excludeRadius(plan[i].baseBlackPx, match.scale),
          ));
        }
      }
      if (recovered.length + registration.accepted.length == plan.length) {
        if (_recoveryIsCoherent(plan, registration, recovered)) {
          registration = _withRecoveries(registration, recovered);
          path = RegistrationPath.fiducialRelaxed;
        } else {
          // A decoy won at least one re-search: the four centres no longer
          // form a convex quad in printed-corner order. Trust nothing from
          // the recovery — the page quad (capped) is the honest next rung.
          recoveryBlocked = ' — recovery incoherent (decoy?)';
        }
      }
    }

    final CvMat warped;
    if (registration.ok) {
      regWatch.stop();
      trace.add(StageTraceEntry(
        stage: 'registration',
        status: path == RegistrationPath.fiducialQuadrant
            ? StageStatus.ok
            : StageStatus.fallback,
        detail: 'path ${path.name}, scores '
            '${registration.matches.map((m) => (m?.score ?? 0).toStringAsFixed(2)).join(' ')}',
        elapsedMicros: regWatch.elapsedMicroseconds,
      ));
      warped = HomographyWarper().warp(cv, gray, registration, plan, template);
    } else {
      regWatch.stop();
      trace.add(StageTraceEntry(
        stage: 'registration',
        status: StageStatus.failed,
        detail: 'quadrant+relaxed accepted '
            '${registration.accepted.length}/${plan.length} anchors'
            '$recoveryBlocked',
        elapsedMicros: regWatch.elapsedMicroseconds,
      ));

      // Rung 3: the page outline, with a 180° guard the quad alone cannot
      // provide (three of the four anchors are identical squares).
      final quadWatch = Stopwatch()..start();
      final quad = cv.detectQuad(gray);
      if (quad == null) {
        quadWatch.stop();
        trace.add(StageTraceEntry(
          stage: 'registration',
          status: StageStatus.failed,
          detail: 'no page quad either — rejected '
              '(${RejectionReason.noRegistration.name})',
          elapsedMicros: quadWatch.elapsedMicroseconds,
        ));
        return _rejected(trace);
      }
      warped = _pageQuadWarp(gray, quad);
      path = RegistrationPath.pageQuad;
      confidenceCap = pageQuadConfidenceCap;
      quadWatch.stop();
      trace.add(StageTraceEntry(
        stage: 'registration',
        status: StageStatus.fallback,
        detail: 'page quad $quad, confidence capped at $pageQuadConfidenceCap',
        elapsedMicros: quadWatch.elapsedMicroseconds,
      ));
    }

    try {
      return _readWarped(warped, registration, path, confidenceCap, trace);
    } finally {
      cv.dispose(warped);
    }
  }

  // ------------------------------------------------------------ registration

  /// Index into the search plan of the alternate (L-shaped) anchor, or null
  /// when every anchor is a square (a spec deviation; presets print one L).
  int? get _altCornerIndex {
    for (var i = 0; i < template.fiducials.length; i++) {
      if (template.fiducials[i].isAltAnchor) return i;
    }
    return null;
  }

  static RegistrationReport _withRecoveries(
    RegistrationReport base,
    Map<int, FiducialMatch> recovered,
  ) {
    final matches = [...base.matches];
    final accepted = [...base.accepted];
    recovered.forEach((i, match) {
      matches[i] = match;
      accepted.add(i);
    });
    return RegistrationReport(
      matches: matches,
      globalBest: base.globalBest,
      accepted: accepted,
    );
  }

  /// Suppression radius around an accepted anchor for rung-2 re-search:
  /// twice the anchor's swept black-square size at the accepted scale —
  /// room for its white surround, and far enough that a neighbouring
  /// anchor's own match cannot win the re-search.
  double _excludeRadius(int baseBlackPx, double scale) =>
      2 * baseBlackPx * scale;

  /// A rung-2 recovery is only trusted when the four centres still form a
  /// convex quadrilateral in printed-corner order (tl→tr→br→bl). Suppression
  /// keeps the re-search off the accepted anchors, but a mid-sheet DECOY —
  /// a bubble cluster, a shadow edge — can still win; a reflex or degenerate
  /// quad would warp the sheet inside-out at high confidence, so it must
  /// fall through to the capped page-quad rung instead.
  bool _recoveryIsCoherent(
    List<FiducialSearch> plan,
    RegistrationReport base,
    Map<int, FiducialMatch> recovered,
  ) {
    final centres = <String, CvPointI>{};
    for (var i = 0; i < plan.length; i++) {
      final m = recovered[i] ?? base.matches[i];
      if (m == null) return false;
      centres[plan[i].corner] = m.center;
    }
    const cyclic = ['tl', 'tr', 'br', 'bl'];
    if (centres.length != cyclic.length) return false;

    int cross(CvPointI o, CvPointI a, CvPointI b) =>
        (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x);

    var positive = false, negative = false;
    for (var i = 0; i < cyclic.length; i++) {
      final o = centres[cyclic[i]]!;
      final a = centres[cyclic[(i + 1) % cyclic.length]]!;
      final b = centres[cyclic[(i + 2) % cyclic.length]]!;
      final z = cross(o, a, b);
      if (z == 0) return false; // collinear — a degenerate warp
      z > 0 ? positive = true : negative = true;
    }
    return !(positive && negative);
  }

  /// Rung-3 warp: page corners → canvas corners, with the 180° guard.
  ///
  /// A quad orders its corners geometrically and cannot tell upside-down
  /// from upright. The printed anchors can: at the alt corner the sheet
  /// carries an L, whose bounding-box CENTRE stays white — a square there
  /// instead means the page came in rotated. Both orientations are warped;
  /// the one whose alt-centre reads lighter (more L-like) wins. The
  /// confidence cap routes the result to review either way.
  CvMat _pageQuadWarp(CvMat gray, List<CvPointI> quad) {
    CvMat warpOf(List<CvPointI> corners) => cv.warpToCanvas(
          gray,
          corners,
          CvSizeI(template.canvasWidth, template.canvasHeight),
        );

    var best = warpOf(quad);
    final alt = _altCornerIndex;
    if (alt != null) {
      final upright = _altCentreWhiteness(best, alt);
      // 180° = corners rotated by two positions (tl↔br, tr↔bl).
      final rotated = warpOf([quad[2], quad[3], quad[0], quad[1]]);
      if (_altCentreWhiteness(rotated, alt) > upright) {
        cv.dispose(best);
        best = rotated;
      } else {
        cv.dispose(rotated);
      }
    }
    return best;
  }

  /// Mean intensity at the alt anchor's centre half: the L's hole is
  /// paper-white there, a square is ink-dark. Higher = more L-like.
  double _altCentreWhiteness(CvMat warped, int altIndex) {
    final f = template.fiducials[altIndex];
    final q = f.size / 4;
    return cv.roiMean(
      warped,
      CvRectI(
        (f.centerX - q).round(),
        (f.centerY - q).round(),
        (2 * q).round(),
        (2 * q).round(),
      ),
    );
  }

  StillEvaluation _rejected(List<StageTraceEntry> trace) => StillEvaluation(
        read: const SheetRead(
          responses: <QuestionId, MarkedResponse>{},
          sheetConfidence: 0,
        ),
        fields: const [],
        registrationPath: RegistrationPath.none,
        trace: trace,
        rejection: RejectionReason.noRegistration,
      );

  // ------------------------------------------------- stages 4–10 on the warp

  StillEvaluation _readWarped(
    CvMat warped,
    RegistrationReport registration,
    RegistrationPath path,
    double? confidenceCap,
    List<StageTraceEntry> trace,
  ) {
    // Stage 4: timing-track curvature residuals.
    final curvature = _measureCurvature(warped, trace);

    // Stage 6: bubble means in template order.
    final readWatch = Stopwatch()..start();
    final samples = BubbleReader().read(cv, warped, template);
    readWatch.stop();
    trace.add(StageTraceEntry(
      stage: 'read',
      status: StageStatus.ok,
      detail: '${samples.length} bubbles',
      elapsedMicros: readWatch.elapsedMicroseconds,
    ));

    // Stage 7: strips are per-field option runs. Samples arrive block-
    // ordered with each field's options contiguous and option-ordered
    // (template order), so one pass builds the strips directly.
    final strips = <String, List<double>>{};
    for (final s in samples) {
      strips.putIfAbsent(s.fieldKey, () => []).add(s.meanIntensity);
    }

    final thresholdWatch = Stopwatch()..start();
    final thresholds = ThresholdEngine(config: thresholdConfig).compute(strips);
    thresholdWatch.stop();
    trace.add(StageTraceEntry(
      stage: 'threshold',
      status: StageStatus.ok,
      detail: 'global ${thresholds.globalThreshold.toStringAsFixed(1)} '
          '(${thresholds.globalUsedFallback
              ? 'fallback'
              : 'gap ${thresholds.globalLargestGap.toStringAsFixed(0)}'})',
      elapsedMicros: thresholdWatch.elapsedMicroseconds,
    ));

    // Stage 8: three-zone classification per field.
    final fields = BubbleClassifier(config: thresholdConfig)
        .classify(samples, thresholds);

    // Stage 10: confidences must exist before the decoder copies them into
    // MarkedResponse.confidence.
    final fiducialScores = [
      for (final i in registration.accepted)
        if (registration.matches[i] != null) registration.matches[i]!.score,
    ];
    final assessment = ConfidenceAggregator(config: thresholdConfig).assess(
      fields,
      registration: RegistrationQuality(
        fiducialScores: fiducialScores,
        timingResidualRatio: curvature?.ratio ?? 0,
        confidenceCap: confidenceCap,
      ),
    );

    // Stage 9: decode to the grading engine's SheetRead.
    final read = FieldDecoder(config: thresholdConfig, roster: roster).decode(
      fields: assessment.fields,
      sheetConfidence: assessment.sheetConfidence,
      rollConfidence: assessment.rollConfidence,
      curlDetected: curvature?.curlDetected ?? false,
    );

    return StillEvaluation(
      read: read,
      fields: assessment.fields,
      thresholds: thresholds,
      curvature: curvature,
      registration: registration,
      registrationPath: path,
      trace: trace,
    );
  }

  /// Stage 4: measure each timing bar's centroid on the warped canvas inside
  /// a window grown around its expected rect, and compare against the
  /// template grid. Bars with no measurable dark mass (track not printed,
  /// occluded by a thumb) are skipped; fewer than two measurable bars cannot
  /// indict a homography, so the stage reports skipped rather than guessing.
  CurvatureReport? _measureCurvature(CvMat warped, List<StageTraceEntry> trace) {
    final watch = Stopwatch()..start();
    final bubbleHeight = _questionBubbleHeight();
    final slack = 0.35 * bubbleHeight;

    final measured = <({double x, double y})>[];
    final expected = <({double x, double y})>[];
    for (final bar in template.timingBars) {
      final win = CvRectI(
        (bar.x - slack).round(),
        (bar.y - slack).round(),
        (bar.w + 2 * slack).round(),
        (bar.h + 2 * slack).round(),
      );
      if (win.x < 0 || win.y < 0) continue;
      if (win.x + win.width > template.canvasWidth ||
          win.y + win.height > template.canvasHeight) {
        continue;
      }
      final c = cv.darkCentroid(warped, win);
      if (c == null) continue;
      measured.add(c);
      expected.add((x: bar.x + bar.w / 2, y: bar.y + bar.h / 2));
    }
    watch.stop();

    if (measured.length < 2) {
      trace.add(StageTraceEntry(
        stage: 'curvature',
        status: StageStatus.skipped,
        detail: '${measured.length} measurable bars of '
            '${template.timingBars.length}',
        elapsedMicros: watch.elapsedMicroseconds,
      ));
      return null;
    }
    final report = CurvatureGate(config: thresholdConfig).evaluate(
      measuredCentroids: measured,
      expectedCentroids: expected,
      bubbleHeightPx: bubbleHeight,
    );
    trace.add(StageTraceEntry(
      stage: 'curvature',
      status: report.curlDetected ? StageStatus.failed : StageStatus.ok,
      detail: 'rms ${report.residualRms.toStringAsFixed(1)}px '
          'tol ${report.tolerancePx.toStringAsFixed(1)}px '
          '(${report.barsChecked} bars)',
      elapsedMicros: watch.elapsedMicroseconds,
    ));
    return report;
  }

  /// Smallest MCQ bubble height on the canvas — the scale the curl tolerance
  /// is expressed in. Falls back to the first bubble when no MCQ field is
  /// found (specs always have MCQ blocks; the guard keeps specs honest).
  double _questionBubbleHeight() {
    for (final b in template.bubbles) {
      if (template.questionFieldKeys.contains(b.fieldKey)) return b.h;
    }
    return template.bubbles.isEmpty ? 0.0 : template.bubbles.first.h;
  }
}
