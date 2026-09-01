import 'dart:math' as math;
import 'dart:typed_data';

import 'package:omr_spec/omr_spec.dart' show DetectionTemplate;

import '../cv/opencv_service.dart'
    show CvExclude, CvMat, CvPointI, CvRectI, OpencvService;

/// Where to hunt for one anchor: the IMAGE-space search rect, the anchor's
/// canonical position on the detection canvas, and which SHAPE it is — the
/// alt anchor prints as an L and must be matched with an L template in both
/// the quadrant pass and any re-search, or it only ever scores mid-band
/// against a square and depresses the sheet confidence.
class FiducialSearch {
  const FiducialSearch({
    required this.corner,
    required this.quadrant,
    required this.canvasX,
    required this.canvasY,
    required this.baseBlackPx,
    this.altAnchor = false,
    this.lArmPx = 0,
  });

  /// Sheet corner this anchor occupies: tl, tr, br, bl.
  final String corner;

  /// Search rect in image px. Quadrant-sized with a bleed toward the sheet
  /// centre, so an off-centre capture still keeps its corner anchor inside
  /// its own quadrant — a match must never straddle a midline (plan §3).
  final CvRectI quadrant;

  /// Anchor centre on the canvas, px — the warp destination.
  final double canvasX;
  final double canvasY;

  /// Whether this anchor is the spec's alternate (L-shaped) one.
  final bool altAnchor;

  /// The anchor's black-square size in IMAGE px when the sheet spans the
  /// full frame width — the scale the sweep normalises against. Derived
  /// from the template (not a frame heuristic) so `scale` means what it
  /// says: 1.0 ⇔ sheet fills the frame, and the sweep floor of 0.35 is the
  /// smallest sheet the registrar promises to find.
  final int baseBlackPx;

  /// L-arm thickness in IMAGE px at sweep scale 1.0 (0 when [altAnchor] is
  /// false).
  final double lArmPx;
}

/// One anchor's winning match.
class FiducialMatch {
  const FiducialMatch({
    required this.center,
    required this.score,
    required this.scale,
  });

  /// Anchor centre in IMAGE space (patch top-left + half patch).
  final CvPointI center;

  /// Best TM_CCOEFF_NORMED score across the scale sweep.
  final double score;

  /// Sweep scale that produced it (1.0 = sheet spans the frame).
  final double scale;
}

/// Stage-2 verdict: where the four anchors are, and whether to trust them.
class RegistrationReport {
  const RegistrationReport({
    required this.matches,
    required this.globalBest,
    required this.accepted,
  });

  /// Winning match per search, same order as the plan. Null where the
  /// quadrant was rejected.
  final List<FiducialMatch?> matches;

  /// Highest score seen anywhere — the reference the deviation test uses.
  final double globalBest;

  /// Indices the registrar accepted; the warp consumes exactly these.
  final List<int> accepted;

  /// All four anchors accepted ⇒ the primary path proceeds. Anything less
  /// hands control to the fallback ladder (plan §3), not to the warp.
  bool get ok => accepted.length == matches.length;

  /// The weakest accepted anchor; feeds sheetConf (plan §3 stage 10).
  double get worstScore {
    var worst = 1.0;
    for (final i in accepted) {
      final m = matches[i];
      if (m != null && m.score < worst) worst = m.score;
    }
    return worst;
  }
}

/// Finds the four registration anchors in a grayscale still.
///
/// Per quadrant: synthesize the anchor appearance (black square inside its
/// printed white surround — the surround is what gives the patch variance,
/// so TM_CCOEFF_NORMED is well-defined) at each swept scale, template-match,
/// keep the best. A quadrant is accepted when its score clears
/// [acceptScore] AND stays within [deviationReject] of the global best.
/// Note what the deviation gate is NOT for: a faint print. TM_CCOEFF_NORMED
/// is contrast-invariant, so a photocopied anchor still scores ~1.0 (the
/// fixture suite pins this); the gate's real job is decoys — a shadow edge
/// or bubble cluster winning one quadrant while the true anchors win the
/// rest. A genuinely eroded anchor scores mid-band, trips the gate, and
/// falls to the page-quad rung, which is exactly the degrade-not-guess
/// behaviour the ladder wants.
///
/// Pure logic over [OpencvService]: every pixel is touched through the
/// interface, so the host suite drives it with the same synthetic fixtures
/// the device does.
class FiducialRegistrar {
  const FiducialRegistrar({
    this.acceptScore = 0.3,
    this.deviationReject = 0.41,
    this.scaleSteps = 10,
    this.minScale = 0.35,
    this.squareFraction = 0.6,
    this.bleedFraction = 0.15,
    this.comparablePeakBand = 0.10,
  });

  /// Plan §3 stage 2: accept a quadrant at or above this score.
  final double acceptScore;

  /// Plan §3 stage 2: reject when the score deviates this far from the
  /// global best — one strong corner plus one weak corner means the weak
  /// one matched a decoy, not the anchor.
  final double deviationReject;

  /// Sweep resolution from [minScale] to 1.0 inclusive.
  final int scaleSteps;

  /// Smallest swept scale (sheet at 35% of frame width).
  final double minScale;

  /// Black square's share of the synthesized patch's edge. The spec's 9mm
  /// square in its 16mm white-surround box is 0.5625; 0.6 trades a hair of
  /// surround for a stronger gradient, and the sweep absorbs the rest.
  final double squareFraction;

  /// How far each quadrant bleeds toward the sheet centre, as a fraction of
  /// the quadrant's own size.
  final double bleedFraction;

  /// Two peaks score "comparably" when they sit within this band of each
  /// other — close enough that position, not score, should decide (see
  /// [_searchQuadrant]'s second-peak check).
  final double comparablePeakBand;

  RegistrationReport register(
    OpencvService cv,
    CvMat gray,
    List<FiducialSearch> plan, {
    required int imageWidth,
  }) {
    final perQuadrant = <FiducialMatch?>[];
    var globalBest = 0.0;
    for (final search in plan) {
      final match = _searchQuadrant(cv, gray, search, imageWidth);
      perQuadrant.add(match);
      if (match != null && match.score > globalBest) globalBest = match.score;
    }
    final accepted = <int>[];
    for (var i = 0; i < perQuadrant.length; i++) {
      final m = perQuadrant[i];
      if (m == null) continue;
      final deviates = globalBest - m.score >= deviationReject;
      if (m.score >= acceptScore && !deviates) accepted.add(i);
    }
    return RegistrationReport(
      matches: perQuadrant,
      globalBest: globalBest,
      accepted: accepted,
    );
  }

  FiducialMatch? _searchQuadrant(
    OpencvService cv,
    CvMat gray,
    FiducialSearch search,
    int imageWidth,
  ) {
    // imageWidth only remains because the sweep asserts templates fit the
    // window; the size model itself lives on the search (template-derived).
    assert(imageWidth > 0);
    final fitLimit = math.min(search.quadrant.width, search.quadrant.height);
    final best = _bestOfShapes(
      cv,
      gray,
      search.quadrant,
      search.baseBlackPx,
      fitLimit,
      altAnchor: search.altAnchor,
      lArmPx: search.lArmPx,
    );
    if (best == null) return null;

    // Second, separated peak. An off-centre capture can put TWO anchors of
    // identical shape inside one window, and a plain max hands every search
    // the scan-order-first one — both corners then "register" onto the same
    // physical anchor and the warp silently folds. When a second peak scores
    // comparably and sits nearer THIS quadrant's outer corner, it is the
    // honest candidate: the true anchor for a corner lives toward the
    // frame's edge, a foreign one only ever appears deep inside the window.
    final second = _bestOfShapes(
      cv,
      gray,
      search.quadrant,
      search.baseBlackPx,
      fitLimit,
      altAnchor: search.altAnchor,
      lArmPx: search.lArmPx,
      exclude: [
        CvExclude(
          x: best.center.x.toDouble(),
          y: best.center.y.toDouble(),
          r: 1.5 * search.baseBlackPx * best.scale,
        ),
      ],
    );
    if (second == null) return best;
    if (second.score >= best.score - comparablePeakBand &&
        _outerDistance(search, second) < _outerDistance(search, best)) {
      return second;
    }
    return best;
  }

  /// Distance from a match's centre to its quadrant window's OUTER corner —
  /// the frame corner the quadrant is named after (tl's top-left, br's
  /// bottom-right, …). Lesser = more plausibly this corner's own anchor.
  double _outerDistance(FiducialSearch search, FiducialMatch m) {
    final q = search.quadrant;
    final ox = search.corner.contains('l') ? q.x : q.x + q.width;
    final oy = search.corner == 'tl' || search.corner == 'tr'
        ? q.y
        : q.y + q.height;
    final dx = m.center.x - ox, dy = m.center.y - oy;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Fallback-ladder rung 2 (plan §3): re-search a corner the quadrant pass
  /// rejected, over the WHOLE frame, with both anchor shapes.
  ///
  /// Two failure modes pull a corner out of its quadrant without hiding the
  /// anchor: strong perspective (the far corner's anchor drifts across a
  /// midline) and a decoy that won the quadrant while the true anchor sat
  /// just outside it. An unrestricted window answers both — but ONLY with
  /// [exclude] suppressing the anchors the quadrant pass already accepted:
  /// three of the four anchors are identical squares, and an unrestricted
  /// square search would otherwise return a neighbour at full score,
  /// handing the warp a wrong correspondence with high confidence.
  FiducialMatch? reSearch(
    OpencvService cv,
    CvMat gray,
    FiducialSearch search, {
    required int imageWidth,
    required int imageHeight,
    List<CvExclude>? exclude,
  }) {
    return _bestOfShapes(
      cv,
      gray,
      CvRectI(0, 0, imageWidth, imageHeight),
      search.baseBlackPx,
      math.min(imageWidth, imageHeight),
      altAnchor: search.altAnchor,
      lArmPx: search.lArmPx,
      exclude: exclude,
    );
  }

  /// Best match over one window trying every shape the anchor could print
  /// as: always the square, plus the L when the search says the anchor is
  /// the alternate one.
  FiducialMatch? _bestOfShapes(
    OpencvService cv,
    CvMat gray,
    CvRectI window,
    int baseBlackPx,
    int fitLimit, {
    required bool altAnchor,
    required double lArmPx,
    List<CvExclude>? exclude,
  }) {
    final square = _sweep(
      cv,
      gray,
      window,
      baseBlackPx,
      fitLimit,
      lArmPx: null,
      exclude: exclude,
    );
    if (!altAnchor || lArmPx <= 0) return square;
    final lShape = _sweep(
      cv,
      gray,
      window,
      baseBlackPx,
      fitLimit,
      lArmPx: lArmPx,
      exclude: exclude,
    );
    if (lShape == null) return square;
    if (square == null || lShape.score > square.score) return lShape;
    return square;
  }

  /// Scale sweep of one patch shape over one window, keeping the best match.
  FiducialMatch? _sweep(
    OpencvService cv,
    CvMat gray,
    CvRectI window,
    int baseBlackPx,
    int fitLimit, {
    required double? lArmPx,
    List<CvExclude>? exclude,
  }) {
    FiducialMatch? best;
    for (var step = 0; step < scaleSteps; step++) {
      final scale = minScale + (1.0 - minScale) * step / (scaleSteps - 1);
      final blackPx = (baseBlackPx * scale).round();
      // Below any printable anchor, or too big to fit the search rect
      // (OpenCV asserts templ ⊆ image): skip, don't crash.
      if (blackPx < 6 || blackPx / squareFraction >= fitLimit) continue;
      final templ = lArmPx == null
          ? _synthesizePatch(cv, blackPx)
          : _synthesizeLPatch(cv, blackPx, lArmPx * scale);
      final match = cv.matchTemplate(gray, window, templ, exclude: exclude);
      cv.dispose(templ);
      if (best == null || match.score > best.score) {
        final patch = (blackPx / squareFraction).round();
        final center = CvPointI(
          match.at.x + patch ~/ 2,
          match.at.y + patch ~/ 2,
        );
        best = FiducialMatch(center: center, score: match.score, scale: scale);
      }
    }
    return best;
  }

  /// Black square centred on a white field, as a grayscale patch. The white
  /// border is load-bearing: a flat template has zero variance and
  /// TM_CCOEFF_NORMED is undefined (0/0) against it.
  CvMat _synthesizePatch(OpencvService cv, int blackPx) {
    final patch = (blackPx / squareFraction).round();
    final bytes = Uint8List(patch * patch);
    bytes.fillRange(0, bytes.length, 255);
    final off = (patch - blackPx) ~/ 2;
    for (var y = 0; y < blackPx; y++) {
      final rowStart = (off + y) * patch + off;
      bytes.fillRange(rowStart, rowStart + blackPx, 0);
    }
    return cv.grayFromBytes(patch, patch, bytes);
  }

  /// The alternate L anchor, drawn exactly as `pdf_sheet_compiler` prints it:
  /// vertical arm full height along the left edge, horizontal arm full width
  /// along the bottom, inside the same bounding box a square anchor would
  /// occupy. White elsewhere — the L's hole is what distinguishes it from a
  /// square, so it must stay bright in the template too.
  CvMat _synthesizeLPatch(OpencvService cv, int blackPx, double armPx) {
    final patch = (blackPx / squareFraction).round();
    final bytes = Uint8List(patch * patch);
    bytes.fillRange(0, bytes.length, 255);
    final off = (patch - blackPx) ~/ 2;
    // An arm as thick as the box IS a square — clamp inside (1, blackPx).
    final arm = math.min(math.max(1, armPx.round()), blackPx);
    for (var y = 0; y < blackPx; y++) {
      // Left arm: full height of the box.
      final rowStart = (off + y) * patch + off;
      bytes.fillRange(rowStart, rowStart + arm, 0);
      // Bottom arm: full width, only over its own rows.
      if (y >= blackPx - arm) {
        bytes.fillRange(rowStart, rowStart + blackPx, 0);
      }
    }
    return cv.grayFromBytes(patch, patch, bytes);
  }
}

/// Builds the search plan from a compiled template and the still's size.
///
/// Quadrants are exact quarters grown by the bleed toward the centre —
/// overlap is intentional, so a corner anchor sitting near a midline stays
/// inside its own quadrant instead of being cut in half.
List<FiducialSearch> fiducialSearchPlan(
  DetectionTemplate template,
  int imageWidth,
  int imageHeight, {
  FiducialRegistrar registrar = const FiducialRegistrar(),
}) {
  final halfW = imageWidth ~/ 2;
  final halfH = imageHeight ~/ 2;
  final bleedW = (halfW * registrar.bleedFraction).round();
  final bleedH = (halfH * registrar.bleedFraction).round();

  CvRectI quadrant(String corner) {
    final leftHalf = corner.contains('l');
    final topHalf = corner == 'tl' || corner == 'tr';
    // Outer edges pinned to the frame; inner edges grown by the bleed.
    final x0 = leftHalf ? 0 : math.max(0, halfW - bleedW);
    final y0 = topHalf ? 0 : math.max(0, halfH - bleedH);
    final x1 = leftHalf ? math.min(imageWidth, halfW + bleedW) : imageWidth;
    final y1 = topHalf ? math.min(imageHeight, halfH + bleedH) : imageHeight;
    return CvRectI(x0, y0, x1 - x0, y1 - y0);
  }

  return [
    for (final f in template.fiducials)
      FiducialSearch(
        corner: f.corner,
        quadrant: quadrant(f.corner),
        canvasX: f.centerX,
        canvasY: f.centerY,
        altAnchor: f.isAltAnchor,
        // The anchor's image size when the sheet spans the frame width:
        // template px scaled by the frame-to-canvas ratio. This is the
        // sweep's scale-1.0 anchor — NOT a frame heuristic (the plan's
        // original 1/17-of-width guess ran 37% large, which every match
        // silently absorbed as a wrong scale and shifted centres).
        baseBlackPx: (f.size * imageWidth / template.canvasWidth).round(),
        // Arm thickness off that same base, as its share of the anchor
        // box. The template does not carry lArmMm (a spec-compile gap
        // worth closing if a preset ever deviates from the 2.5 mm default
        // the PDF compiler prints); the sweep absorbs small mismatches.
        lArmPx: f.isAltAnchor
            ? f.size * imageWidth / template.canvasWidth * (2.5 / (f.size / 8.0))
            : 0,
      ),
  ];
}
