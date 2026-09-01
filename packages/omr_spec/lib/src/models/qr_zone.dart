/// QR code zone: authoritative sheet identity.
///
/// Encoding layoutId + layoutVersion means the detection pipeline never has to
/// guess which template to apply — a 2024 print run still grades correctly in
/// 2027 because the QR resolves the exact immutable layout version.
class QrZone {
  const QrZone({required this.sizeMm, this.position = 'tr'});

  /// Symbol size, mm (>= 15 recommended; ECC level M is fixed by the
  /// compiler).
  final double sizeMm;

  /// Corner position on the page. v1: 'tr' (top-right) only.
  final String position;

  Map<String, Object?> toJson() => {'sizeMm': sizeMm, 'position': position};

  static QrZone fromJson(Map<String, Object?> j) => QrZone(
        sizeMm: (j['sizeMm']! as num).toDouble(),
        position: j['position'] as String? ?? 'tr',
      );
}
