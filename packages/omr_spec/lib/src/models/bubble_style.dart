import 'units.dart';

/// Bubble geometry + ink. Ovals with thin uniform strokes fill completely and
/// are the best-recognized shape across deployed OMR systems; thick outlines
/// are a documented misread source, hence the 0.15–0.35 mm validation band.
class BubbleStyle {
  const BubbleStyle({
    required this.wMm,
    required this.hMm,
    this.strokeMm = 0.25,
    required this.pitchMm,
    this.outlineColorHex = '#D64000',
    this.labelColorHex = '#D64000',
  });

  /// Major axis (horizontal), mm. 3–6 mm valid; 4.5–5.5 recommended.
  final double wMm;

  /// Minor axis (vertical), mm.
  final double hMm;

  /// The longer of the two axes — the size every pitch ratio is measured
  /// against.
  double get majorAxisMm => wMm >= hMm ? wMm : hMm;

  /// Outline stroke width in mm.
  final double strokeMm;

  /// Centre-to-centre pitch along the option axis, mm.
  /// Must be >= 1.4x the major axis so neighbouring marks never straddle.
  final double pitchMm;

  /// Drop-out colour for bubble outlines. Everything the student should NOT
  /// be judged on prints in this colour; detection reads the channel where it
  /// is weakest so outlines vanish digitally.
  final String outlineColorHex;

  /// Drop-out colour for the small in-bubble option letters.
  final String labelColorHex;

  Map<String, Object?> toJson() => {
        'wMm': wMm,
        'hMm': hMm,
        'strokeMm': strokeMm,
        'pitchMm': pitchMm,
        'outlineColorHex': outlineColorHex,
        'labelColorHex': labelColorHex,
      };

  static BubbleStyle fromJson(Map<String, Object?> j) => BubbleStyle(
        wMm: (j['wMm']! as num).toDouble(),
        hMm: (j['hMm']! as num).toDouble(),
        strokeMm: (j['strokeMm'] as num?)?.toDouble() ?? 0.25,
        pitchMm: (j['pitchMm']! as num).toDouble(),
        outlineColorHex: j['outlineColorHex'] as String? ?? '#D64000',
        labelColorHex: j['labelColorHex'] as String? ?? '#D64000',
      );

  BubbleStyle copyWith({
    double? wMm,
    double? hMm,
    double? strokeMm,
    double? pitchMm,
    String? outlineColorHex,
    String? labelColorHex,
  }) =>
      BubbleStyle(
        wMm: wMm ?? this.wMm,
        hMm: hMm ?? this.hMm,
        strokeMm: strokeMm ?? this.strokeMm,
        pitchMm: pitchMm ?? this.pitchMm,
        outlineColorHex: outlineColorHex ?? this.outlineColorHex,
        labelColorHex: labelColorHex ?? this.labelColorHex,
      );

  /// The smallest rectangle (centred on origin) covering the bubble outline.
  MmRect bubbleRectAt(MmPoint center) =>
      MmRect(center.x - wMm / 2, center.y - hMm / 2, wMm, hMm);
}
