import 'dart:convert';

import 'bubble_style.dart';
import 'fiducial.dart';
import 'field_block.dart';
import 'qr_zone.dart';
import 'section.dart';
import 'timing_track.dart';
import 'units.dart';

/// A4 portrait in mm.
const double a4WidthMm = 210.0;
const double a4HeightMm = 297.0;

/// The single source of truth for an OMR sheet layout.
///
/// One declarative mm-based spec compiles to BOTH the printable PDF and the
/// detection template; neither representation is ever authored independently.
/// A layout is IMMUTABLE once printed — any geometric change is a new
/// layoutVersion, and the QR code printed on the sheet resolves exactly that
/// version forever.
class SheetSpec {
  const SheetSpec({
    required this.specVersion,
    required this.layoutId,
    required this.layoutVersion,
    required this.paperSizeMm,
    required this.marginMm,
    required this.headerHeightMm,
    required this.bubbleStyle,
    required this.fiducials,
    required this.timingTrack,
    required this.qrZone,
    required this.fieldBlocks,
    required this.sections,
    this.rollDigits = 7,
    this.rollChecksum = true,
    this.setValues = const ['A', 'B', 'C', 'D'],
    this.serialText = '',
    this.instructionText = '',
  });

  /// Schema version of the spec format itself.
  final int specVersion;

  /// Immutable identity, encoded in the printed QR.
  final String layoutId;

  /// Bumped by ANY geometric change; colours/instruction text are exempt.
  final int layoutVersion;

  /// Paper size (w, h) in mm.
  final (double, double) paperSizeMm;

  /// Printable safety margin on all sides, mm (>= 10 enforced).
  final double marginMm;

  /// Height of the header band (title / instructions / QR / serial), mm.
  final double headerHeightMm;

  final BubbleStyle bubbleStyle;
  final FiducialLayout fiducials;
  final TimingTrack timingTrack;
  final QrZone qrZone;
  final List<FieldBlock> fieldBlocks;
  final List<SectionSpec> sections;

  /// Roll-number digit count (excluding the checksum digit).
  final int rollDigits;

  /// Whether a trailing checksum digit column is appended to the roll block.
  final bool rollChecksum;

  /// Legal set-code values for the set-code block.
  final List<String> setValues;

  /// Human-readable serial printed at the bottom edge.
  final String serialText;

  /// Instruction text printed in the header band.
  final String instructionText;

  double get paperWidthMm => paperSizeMm.$1;
  double get paperHeightMm => paperSizeMm.$2;

  /// The rectangle all field blocks must stay inside: inside the margin,
  /// below the header, above the bottom serial strip.
  MmRect get contentRect => MmRect(
        marginMm,
        headerHeightMm,
        paperWidthMm - 2 * marginMm,
        paperHeightMm - headerHeightMm - marginMm,
      );

  /// The roll block, if present.
  FieldBlock? get rollBlock {
    for (final b in fieldBlocks) {
      if (b.blockType == BlockType.rollDigits) return b;
    }
    return null;
  }

  /// The set-code block, if present.
  FieldBlock? get setBlock {
    for (final b in fieldBlocks) {
      if (b.blockType == BlockType.setCode) return b;
    }
    return null;
  }

  /// The content string encoded in the printed QR. Detection resolves the
  /// exact immutable layout from this — no template guessing, ever.
  String get qrPayload => 'OMR1:$layoutId:v$layoutVersion';

  /// Fields are keyed globally by their expanded label — these keys flow
  /// verbatim into detection templates, bubble_reads and grading.
  Iterable<String> get allFieldKeys sync* {
    for (final block in fieldBlocks) {
      yield* block.fields;
    }
  }

  /// The first MCQ block defines the shared row grid the timing track is
  /// derived from (validated: all MCQ blocks share rowPitchMm and origin y).
  FieldBlock? get firstMcqBlock {
    for (final b in fieldBlocks) {
      if (b.blockType == BlockType.mcq) return b;
    }
    return null;
  }

  /// Canonical JSON — sorted keys, stable number formatting — the hash input.
  /// Layout-identity fields (layoutVersion) are INCLUDED: bumping the version
  /// must change the hash so stale templates can never load silently.
  String canonicalJson() {
    final buf = StringBuffer();
    _writeCanonical(buf, toJson());
    return buf.toString();
  }

  /// sha256 hex of [canonicalJson] — see `specHash` in package:crypto use at
  /// the library boundary. Kept as a pure string function here so this file
  /// stays dependency-light for tests.
  String specHash(String Function(String) hash) => hash(canonicalJson());

  Map<String, Object?> toJson() => _withoutNulls({
        'specVersion': specVersion,
        'layoutId': layoutId,
        'layoutVersion': layoutVersion,
        'paperSizeMm': [paperWidthMm, paperHeightMm],
        'marginMm': marginMm,
        'headerHeightMm': headerHeightMm,
        'bubbleStyle': bubbleStyle.toJson(),
        'fiducials': fiducials.toJson(),
        'timingTrack': timingTrack.toJson(),
        'qrZone': qrZone.toJson(),
        'rollDigits': rollDigits,
        'rollChecksum': rollChecksum,
        'setValues': setValues,
        'serialText': serialText,
        'instructionText': instructionText,
        'fieldBlocks': [for (final b in fieldBlocks) b.toJson()],
        'sections': [for (final s in sections) s.toJson()],
      });

  static SheetSpec fromJson(Map<String, Object?> j) {
    final paper = (j['paperSizeMm']! as List<Object?>)
        .map((e) => (e! as num).toDouble())
        .toList();
    return SheetSpec(
      specVersion: j['specVersion']! as int,
      layoutId: j['layoutId']! as String,
      layoutVersion: j['layoutVersion']! as int,
      paperSizeMm: (paper[0], paper[1]),
      marginMm: (j['marginMm']! as num).toDouble(),
      headerHeightMm: (j['headerHeightMm']! as num).toDouble(),
      bubbleStyle: BubbleStyle.fromJson(j['bubbleStyle']! as Map<String, Object?>),
      fiducials: FiducialLayout.fromJson(j['fiducials']! as Map<String, Object?>),
      timingTrack: TimingTrack.fromJson(j['timingTrack']! as Map<String, Object?>),
      qrZone: QrZone.fromJson(j['qrZone']! as Map<String, Object?>),
      rollDigits: j['rollDigits'] as int? ?? 7,
      rollChecksum: j['rollChecksum'] as bool? ?? true,
      setValues: (j['setValues'] as List<Object?>? ?? const ['A', 'B', 'C', 'D'])
          .cast<String>(),
      serialText: j['serialText'] as String? ?? '',
      instructionText: j['instructionText'] as String? ?? '',
      fieldBlocks: [
        for (final b in j['fieldBlocks']! as List<Object?>)
          FieldBlock.fromJson(b! as Map<String, Object?>),
      ],
      sections: [
        for (final s in j['sections']! as List<Object?>)
          SectionSpec.fromJson(s! as Map<String, Object?>),
      ],
    );
  }

  /// Field-preserving copy — used by tests and spec-authoring tools to derive
  /// variants; production specs come from the builders or JSON.
  SheetSpec copyWith({
    int? specVersion,
    String? layoutId,
    int? layoutVersion,
    (double, double)? paperSizeMm,
    double? marginMm,
    double? headerHeightMm,
    BubbleStyle? bubbleStyle,
    FiducialLayout? fiducials,
    TimingTrack? timingTrack,
    QrZone? qrZone,
    List<FieldBlock>? fieldBlocks,
    List<SectionSpec>? sections,
    int? rollDigits,
    bool? rollChecksum,
    List<String>? setValues,
    String? serialText,
    String? instructionText,
  }) =>
      SheetSpec(
        specVersion: specVersion ?? this.specVersion,
        layoutId: layoutId ?? this.layoutId,
        layoutVersion: layoutVersion ?? this.layoutVersion,
        paperSizeMm: paperSizeMm ?? this.paperSizeMm,
        marginMm: marginMm ?? this.marginMm,
        headerHeightMm: headerHeightMm ?? this.headerHeightMm,
        bubbleStyle: bubbleStyle ?? this.bubbleStyle,
        fiducials: fiducials ?? this.fiducials,
        timingTrack: timingTrack ?? this.timingTrack,
        qrZone: qrZone ?? this.qrZone,
        fieldBlocks: fieldBlocks ?? this.fieldBlocks,
        sections: sections ?? this.sections,
        rollDigits: rollDigits ?? this.rollDigits,
        rollChecksum: rollChecksum ?? this.rollChecksum,
        setValues: setValues ?? this.setValues,
        serialText: serialText ?? this.serialText,
        instructionText: instructionText ?? this.instructionText,
      );

  /// Compact canonical writer: sorted keys, no whitespace, ints stay ints,
  /// doubles printed via their shortest round-trip form.
  static void _writeCanonical(StringBuffer buf, Object? v) {
    switch (v) {
      case null:
        buf.write('null');
      case final bool b:
        buf.write(b);
      case final num n:
        if (n is int || n == n.roundToDouble()) {
          buf.write(n is int ? n : n.toInt());
        } else {
          buf.write(n);
        }
      case final String s:
        buf.write(jsonEncode(s));
      case final List<Object?> l:
        buf.write('[');
        for (var i = 0; i < l.length; i++) {
          if (i > 0) buf.write(',');
          _writeCanonical(buf, l[i]);
        }
        buf.write(']');
      case final Map<Object?, Object?> m:
        final keys = m.keys.cast<String>().toList()..sort();
        buf.write('{');
        for (var i = 0; i < keys.length; i++) {
          if (i > 0) buf.write(',');
          buf.write(jsonEncode(keys[i]));
          buf.write(':');
          _writeCanonical(buf, m[keys[i]]);
        }
        buf.write('}');
    }
  }

  static Map<String, Object?> _withoutNulls(Map<String, Object?> m) => {
        for (final e in m.entries)
          if (e.value != null) e.key: e.value,
      };
}
