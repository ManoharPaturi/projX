import 'dart:math' as math;


import '../models/sheet_spec.dart';
import '../models/units.dart';

/// Page-level geometry DERIVED from a validated [SheetSpec].
///
/// Both compilers (PDF and detection template) consume THIS class — never
/// their own corner arithmetic — so the printed sheet and the detection grid
/// agree by construction. There is exactly one place in the codebase that
/// knows where the fiducials, QR and timing bars sit.
class LayoutGeometry {
  LayoutGeometry._(
    this.spec, {
    required this.fiducialCenters,
    required this.qrRect,
    required this.timingBars,
  });

  /// Computes page geometry. Call after [validateSheetSpec].
  static LayoutGeometry of(SheetSpec spec) {
    final w = spec.paperWidthMm;
    final h = spec.paperHeightMm;
    final inset = spec.fiducials.insetMm;

    // All four corners carry an anchor; the alt corner is drawn as an L but
    // occupies the same square bounding box.
    final centers = <String, MmPoint>{
      'tl': MmPoint(inset, inset),
      'tr': MmPoint(w - inset, inset),
      'bl': MmPoint(inset, h - inset),
      'br': MmPoint(w - inset, h - inset),
    };

    // QR: top-right, top edge at the margin, right edge pulled in to clear the
    // TR fiducial's white-surround zone (1mm extra breathing room).
    final f = spec.fiducials;
    final qrClearRight = w - f.insetMm - f.sizeMm / 2 - f.whiteSurroundMm - 1.0;
    final qrRight = math.min(w - spec.marginMm, qrClearRight);
    final qrRect = MmRect(
      qrRight - spec.qrZone.sizeMm,
      spec.marginMm,
      spec.qrZone.sizeMm,
      spec.qrZone.sizeMm,
    );

    // Timing track: one bar per row of the first MCQ block's grid, hugging
    // the left margin. Derived — the track can never drift from the rows.
    final mcq = spec.firstMcqBlock;
    final bars = <MmRect>[];
    if (mcq != null) {
      final t = spec.timingTrack;
      final rows = mcq.fields.length;
      final originX = t.edge == 'left' ? spec.marginMm : 0.0;
      for (var i = 0; i < rows; i++) {
        final cy = mcq.originMm.y + i * mcq.rowPitchMm;
        bars.add(MmRect(originX, cy - t.barHMm / 2, t.barWMm, t.barHMm));
      }
    }

    return LayoutGeometry._(spec,
        fiducialCenters: centers, qrRect: qrRect, timingBars: bars);
  }

  final SheetSpec spec;
  final Map<String, MmPoint> fiducialCenters;
  final MmRect qrRect;
  final List<MmRect> timingBars;

  /// The anchors used for the primary homography, in canvas-corner order
  /// tl, tr, br, bl.
  List<MmPoint> get orderedFiducialCenters => [
        fiducialCenters['tl']!,
        fiducialCenters['tr']!,
        fiducialCenters['br']!,
        fiducialCenters['bl']!,
      ];

  /// Body rect of the fiducial at [corner] (solid square / L bounding box).
  MmRect fiducialRect(String corner) {
    final c = fiducialCenters[corner]!;
    final s = spec.fiducials.sizeMm;
    return MmRect(c.x - s / 2, c.y - s / 2, s, s);
  }

  /// The fiducial plus its mandatory clear white surround — nothing may be
  /// printed inside this zone.
  MmRect fiducialZone(String corner) =>
      fiducialRect(corner).inflate(spec.fiducials.whiteSurroundMm);

  /// The full strip the timing track occupies (bars grown by the clearance),
  /// used for overlap validation.
  MmRect? get timingTrackZone {
    if (timingBars.isEmpty) return null;
    final first = timingBars.first;
    final last = timingBars.last;
    return MmRect(first.x, first.y, first.w, last.bottom - first.y)
        .inflate(spec.timingTrack.clearanceMm);
  }
}
