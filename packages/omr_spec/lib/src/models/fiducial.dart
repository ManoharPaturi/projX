/// Registration fiducials — the primary registration anchor for detection.
///
/// Three identical solid-black squares (default corners TL, TR, BR) plus one
/// DISTINCT L-shaped anchor at the remaining corner (default BL). The odd one
/// out makes sheet orientation unambiguous after the perspective warp, and the
/// alternate shape is the fallback anchor when a square is occluded or glazed.
class FiducialLayout {
  const FiducialLayout({
    required this.sizeMm,
    required this.insetMm,
    required this.whiteSurroundMm,
    this.squareCorners = const ['tl', 'tr', 'br'],
    this.altAnchorCorner = 'bl',
    this.lArmMm = 2.5,
  });

  /// Square side / L bounding-box side, mm (6–12 valid; ~9 recommended:
  /// roughly 1/17 of the sheet width, ~2.5–3x a bubble).
  final double sizeMm;

  /// Distance of each fiducial's centre from the page corner, mm.
  final double insetMm;

  /// Clear white space that must surround every fiducial, mm (>= 3).
  final double whiteSurroundMm;

  /// Corners carrying the square shape.
  final List<String> squareCorners;

  /// The corner carrying the distinct L anchor.
  final String altAnchorCorner;

  /// Arm thickness of the L anchor, mm.
  final double lArmMm;

  FiducialLayout copyWith({
    double? sizeMm,
    double? insetMm,
    double? whiteSurroundMm,
    List<String>? squareCorners,
    String? altAnchorCorner,
    double? lArmMm,
  }) =>
      FiducialLayout(
        sizeMm: sizeMm ?? this.sizeMm,
        insetMm: insetMm ?? this.insetMm,
        whiteSurroundMm: whiteSurroundMm ?? this.whiteSurroundMm,
        squareCorners: squareCorners ?? this.squareCorners,
        altAnchorCorner: altAnchorCorner ?? this.altAnchorCorner,
        lArmMm: lArmMm ?? this.lArmMm,
      );

  Map<String, Object?> toJson() => {
        'sizeMm': sizeMm,
        'insetMm': insetMm,
        'whiteSurroundMm': whiteSurroundMm,
        'squareCorners': squareCorners,
        'altAnchorCorner': altAnchorCorner,
        'lArmMm': lArmMm,
      };

  static FiducialLayout fromJson(Map<String, Object?> j) => FiducialLayout(
        sizeMm: (j['sizeMm']! as num).toDouble(),
        insetMm: (j['insetMm']! as num).toDouble(),
        whiteSurroundMm: (j['whiteSurroundMm']! as num).toDouble(),
        squareCorners:
            (j['squareCorners'] as List<Object?>? ?? const ['tl', 'tr', 'br'])
                .cast<String>(),
        altAnchorCorner: j['altAnchorCorner'] as String? ?? 'bl',
        lArmMm: (j['lArmMm'] as num?)?.toDouble() ?? 2.5,
      );
}
