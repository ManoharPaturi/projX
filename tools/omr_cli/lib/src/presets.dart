import 'package:omr_spec/omr_spec.dart';

/// CLI-facing preset registry. `A`/`B` are the stable short names; the
/// layoutIds stay immutable for QR resolution.
enum SheetPreset {
  a('A', 'Standard-90', '90 questions, comfortable geometry (MVP default)'),
  b('B', 'NEET-180', '180 questions, dense vendor-grade geometry');

  const SheetPreset(this.flag, this.label, this.description);

  final String flag;
  final String label;
  final String description;

  SheetSpec build() => switch (this) {
        SheetPreset.a => buildStandard90(),
        SheetPreset.b => buildNeet180(),
      };

  static SheetPreset? parse(String? flag) {
    if (flag == null) return SheetPreset.a;
    return SheetPreset.values
        .where((p) => p.flag.equalsIgnoreCase(flag) || p.name == flag)
        .firstOrNull;
  }
}

extension on String {
  bool equalsIgnoreCase(String other) =>
      toLowerCase() == other.toLowerCase();
}
