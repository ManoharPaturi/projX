/// Redundant registration: a black timing bar per row-band along one edge.
///
/// The corner fiducials fix a 4-point homography, but a page curved on a desk
/// bends rows several mm mid-sheet where a homography cannot follow. The
/// timing bars give (a) per-row index recovery, (b) a curvature residual
/// measurement that routes curled sheets to review instead of mis-grading
/// them, and (c) a least-squares affine fallback when corner matching fails.
///
/// Bar positions are DERIVED at compile time from the first MCQ block's row
/// grid (validation requires all question blocks to share rowPitchMm and a
/// common origin y), so the track can never drift from the question rows.
class TimingTrack {
  const TimingTrack({
    this.edge = 'left',
    required this.barWMm,
    required this.barHMm,
    this.clearanceMm = 5.0,
  });

  /// Which page edge the track runs along. v1: 'left' only.
  final String edge;

  /// Bar width/height, mm (recommended 5.5 x 2.5).
  final double barWMm;
  final double barHMm;

  /// Gap between the track and the leftmost question column, mm.
  final double clearanceMm;

  Map<String, Object?> toJson() => {
        'edge': edge,
        'barWMm': barWMm,
        'barHMm': barHMm,
        'clearanceMm': clearanceMm,
      };

  static TimingTrack fromJson(Map<String, Object?> j) => TimingTrack(
        edge: j['edge'] as String? ?? 'left',
        barWMm: (j['barWMm']! as num).toDouble(),
        barHMm: (j['barHMm']! as num).toDouble(),
        clearanceMm: (j['clearanceMm'] as num?)?.toDouble() ?? 5.0,
      );
}
