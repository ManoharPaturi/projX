import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;

import '../models/field_block.dart';
import '../models/sheet_spec.dart';
import 'layout_geometry.dart';

/// Pixels per mm on the canonical detection canvas. 8.0 gives a 5.0mm bubble
/// a 40px major axis — OMRChecker's proven working size — and a 7.6mm pitch
/// 61px (OMRChecker: 59) on a 1680x2376 portrait-A4 canvas.
const double pxPerMm = 8.0;

/// One bubble on the canonical canvas: everything the reader needs, nothing
/// it doesn't. The bubble list is FLAT and ordered block-by-block so a strip
/// (per-question option run) is a contiguous slice.
class BubbleRect {
  const BubbleRect({
    required this.fieldKey,
    required this.blockId,
    required this.optionIndex,
    required this.optionValue,
    required this.centerX,
    required this.centerY,
    required this.w,
    required this.h,
  });

  final String fieldKey;
  final String blockId;
  final int optionIndex;
  final String optionValue;

  /// Centre on the canonical canvas, px.
  final double centerX;
  final double centerY;

  /// Full outline size, px (the reader samples the inner ~70%).
  final double w;
  final double h;

  /// The measurement ROI: the inner [fraction] of the outline, which excludes
  /// the printed 0.25mm stroke.
  ({int x, int y, int w, int h}) roi({double fraction = 0.70}) {
    final rw = (w * fraction).round();
    final rh = (h * fraction).round();
    return (
      x: (centerX - rw / 2).round(),
      y: (centerY - rh / 2).round(),
      w: rw,
      h: rh,
    );
  }

  Map<String, Object?> toJson() => {
        'fieldKey': fieldKey,
        'blockId': blockId,
        'optionIndex': optionIndex,
        'optionValue': optionValue,
        'center': [centerX, centerY],
        'w': w,
        'h': h,
      };

  static BubbleRect fromJson(Map<String, Object?> j) => BubbleRect(
        fieldKey: j['fieldKey']! as String,
        blockId: j['blockId']! as String,
        optionIndex: j['optionIndex']! as int,
        optionValue: j['optionValue']! as String,
        centerX: ((j['center']! as List).first as num).toDouble(),
        centerY: ((j['center']! as List).last as num).toDouble(),
        w: (j['w']! as num).toDouble(),
        h: (j['h']! as num).toDouble(),
      );
}

/// A registration anchor on the canonical canvas.
class FiducialRect {
  const FiducialRect({
    required this.corner,
    required this.isAltAnchor,
    required this.centerX,
    required this.centerY,
    required this.size,
  });

  final String corner;

  /// True for the distinct L-shaped anchor (orientation disambiguator).
  final bool isAltAnchor;
  final double centerX;
  final double centerY;
  final double size;

  Map<String, Object?> toJson() => {
        'corner': corner,
        'isAltAnchor': isAltAnchor,
        'center': [centerX, centerY],
        'size': size,
      };

  static FiducialRect fromJson(Map<String, Object?> j) => FiducialRect(
        corner: j['corner']! as String,
        isAltAnchor: j['isAltAnchor']! as bool,
        centerX: ((j['center']! as List).first as num).toDouble(),
        centerY: ((j['center']! as List).last as num).toDouble(),
        size: (j['size']! as num).toDouble(),
      );
}

/// The compiled detection geometry: what the pipeline actually consumes.
///
/// Produced ONLY from a validated [SheetSpec]; its [specHash] is checked
/// against the stored hash at load time so a stale template can never be
/// applied to a newer sheet.
class DetectionTemplate {
  const DetectionTemplate({
    required this.layoutId,
    required this.layoutVersion,
    required this.specHash,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.bubbles,
    required this.fiducials,
    required this.timingBars,
    required this.qrRect,
    required this.rollFieldKeys,
    required this.setFieldKey,
    required this.questionFieldKeys,
    required this.qrPayload,
    required this.minPxPerMmOnCapture,
  });

  final String layoutId;
  final int layoutVersion;

  /// sha256 of the source spec's canonical JSON. Persisted with every scan.
  final String specHash;

  final int canvasWidth;
  final int canvasHeight;

  /// Flat, block-ordered bubble list.
  final List<BubbleRect> bubbles;
  final List<FiducialRect> fiducials;

  /// Timing-bar rects on the canvas (derived from the shared MCQ row grid).
  final List<({double x, double y, double w, double h})> timingBars;

  /// Expected QR location, canvas px.
  final ({double x, double y, double w, double h}) qrRect;

  /// Roll columns in reading order (checksum last), e.g. [roll1..roll8].
  final List<String> rollFieldKeys;

  /// The set-code field key ('set'), empty when absent.
  final String setFieldKey;

  /// MCQ field keys in sheet serial order.
  final List<String> questionFieldKeys;

  final String qrPayload;

  /// Capture-resolution floor implied by this layout: the smallest px/mm the
  /// phone's still may carry while keeping >= [minBubblePx] on the bubble's
  /// MINOR axis. The capture gate enforces it per preset.
  final double minPxPerMmOnCapture;

  /// Field-key → contiguous bubble slice start index. Strips are contiguous
  /// by construction; this map avoids per-read linear scans.
  Map<String, int> get fieldStartIndex {
    final m = <String, int>{};
    for (var i = 0; i < bubbles.length; i++) {
      final key = bubbles[i].fieldKey;
      // First occurrence wins: bubbles are block-ordered and a field's
      // options are always emitted consecutively.
      m.putIfAbsent(key, () => i);
    }
    return m;
  }

  /// The minimum px/mm a capture needs to resolve this layout's bubbles.
  static double requiredPxPerMm(double bubbleMinorAxisMm,
          {double minBubblePx = 40}) =>
      minBubblePx / bubbleMinorAxisMm;

  Map<String, Object?> toJson() => {
        'templateVersion': 1,
        'layoutId': layoutId,
        'layoutVersion': layoutVersion,
        'specHash': specHash,
        'pxPerMm': pxPerMm,
        'canvas': [canvasWidth, canvasHeight],
        'bubbles': [for (final b in bubbles) b.toJson()],
        'fiducials': [for (final f in fiducials) f.toJson()],
        'timingBars': [
          for (final t in timingBars) [t.x, t.y, t.w, t.h],
        ],
        'qrRect': [qrRect.x, qrRect.y, qrRect.w, qrRect.h],
        'rollFieldKeys': rollFieldKeys,
        'setFieldKey': setFieldKey,
        'questionFieldKeys': questionFieldKeys,
        'qrPayload': qrPayload,
        'minPxPerMmOnCapture': minPxPerMmOnCapture,
      };

  static DetectionTemplate fromJson(Map<String, Object?> j) {
    final qr = (j['qrRect']! as List).cast<num>();
    return DetectionTemplate(
      layoutId: j['layoutId']! as String,
      layoutVersion: j['layoutVersion']! as int,
      specHash: j['specHash']! as String,
      canvasWidth: (j['canvas']! as List).first as int,
      canvasHeight: (j['canvas']! as List).last as int,
      bubbles: [
        for (final b in j['bubbles']! as List<Object?>)
          BubbleRect.fromJson(b! as Map<String, Object?>),
      ],
      fiducials: [
        for (final f in j['fiducials']! as List<Object?>)
          FiducialRect.fromJson(f! as Map<String, Object?>),
      ],
      timingBars: [
        for (final t in j['timingBars']! as List<Object?>)
          _rectFromJson(t! as List<Object?>),
      ],
      qrRect: (
        x: qr[0].toDouble(),
        y: qr[1].toDouble(),
        w: qr[2].toDouble(),
        h: qr[3].toDouble(),
      ),
      rollFieldKeys: (j['rollFieldKeys']! as List<Object?>).cast<String>(),
      setFieldKey: j['setFieldKey']! as String,
      questionFieldKeys:
          (j['questionFieldKeys']! as List<Object?>).cast<String>(),
      qrPayload: j['qrPayload']! as String,
      minPxPerMmOnCapture: (j['minPxPerMmOnCapture']! as num).toDouble(),
    );
  }

  String toJsonString() => const JsonEncoder.withIndent('  ').convert(toJson());

  static DetectionTemplate fromJsonString(String s) =>
      fromJson(jsonDecode(s) as Map<String, Object?>);
}

/// Compiles a validated spec to the detection template.
///
/// Every mm coordinate maps to canvas px by exactly one multiply; the PDF
/// compiler renders the same mm coordinates, so template-vs-print drift is
/// impossible rather than merely tested for.
DetectionTemplate compileDetectionTemplate(SheetSpec spec) {
  final geo = LayoutGeometry.of(spec);
  final bs = spec.bubbleStyle;
  final canvasW = (spec.paperWidthMm * pxPerMm).round();
  final canvasH = (spec.paperHeightMm * pxPerMm).round();

  final bubbles = <BubbleRect>[];
  final rollKeys = <String>[];
  var setKey = '';
  final questionKeys = <String>[];

  for (final block in spec.fieldBlocks) {
    final fields = block.fields;
    final values = block.optionValues;
    for (var f = 0; f < fields.length; f++) {
      for (var o = 0; o < values.length; o++) {
        final c = block.bubbleCenter(f, o);
        bubbles.add(BubbleRect(
          fieldKey: fields[f],
          blockId: block.blockId,
          optionIndex: o,
          optionValue: values[o],
          centerX: _px(c.x),
          centerY: _px(c.y),
          w: _px(bs.wMm),
          h: _px(bs.hMm),
        ));
      }
      switch (block.blockType) {
        case BlockType.rollDigits:
          rollKeys.add(fields[f]);
        case BlockType.setCode:
          setKey = fields[f];
        case BlockType.mcq || BlockType.matrix:
          questionKeys.add(fields[f]);
        case BlockType.intDigits:
          questionKeys.add(fields[f]);
      }
    }
  }

  final fiducials = <FiducialRect>[
    for (final e in [
      ('tl', geo.fiducialCenters['tl']!),
      ('tr', geo.fiducialCenters['tr']!),
      ('br', geo.fiducialCenters['br']!),
      ('bl', geo.fiducialCenters['bl']!),
    ])
      FiducialRect(
        corner: e.$1,
        isAltAnchor: e.$1 == spec.fiducials.altAnchorCorner,
        centerX: _px(e.$2.x),
        centerY: _px(e.$2.y),
        size: _px(spec.fiducials.sizeMm),
      ),
  ];

  return DetectionTemplate(
    layoutId: spec.layoutId,
    layoutVersion: spec.layoutVersion,
    specHash: specSha256(spec),
    canvasWidth: canvasW,
    canvasHeight: canvasH,
    bubbles: bubbles,
    fiducials: fiducials,
    timingBars: [
      for (final b in geo.timingBars)
        (
          x: _px(b.x),
          y: _px(b.y),
          w: _px(b.w),
          h: _px(b.h),
        ),
    ],
    qrRect: (
      x: _px(geo.qrRect.x),
      y: _px(geo.qrRect.y),
      w: _px(geo.qrRect.w),
      h: _px(geo.qrRect.h),
    ),
    rollFieldKeys: rollKeys,
    setFieldKey: setKey,
    questionFieldKeys: questionKeys,
    qrPayload: spec.qrPayload,
    minPxPerMmOnCapture: DetectionTemplate.requiredPxPerMm(bs.hMm),
  );
}

double _px(double mm) => mm * pxPerMm;

({double x, double y, double w, double h}) _rectFromJson(List<Object?> l) => (
      x: (l[0]! as num).toDouble(),
      y: (l[1]! as num).toDouble(),
      w: (l[2]! as num).toDouble(),
      h: (l[3]! as num).toDouble(),
    );

/// sha256 hex of the spec's canonical JSON — the identity stored with every
/// layout row, scan and scoring run.
String specSha256(SheetSpec spec) =>
    crypto.sha256.convert(utf8.encode(spec.canonicalJson())).toString();
