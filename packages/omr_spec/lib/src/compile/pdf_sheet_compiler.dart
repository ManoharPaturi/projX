import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:qr/qr.dart' as qr;

import '../models/field_block.dart';
import '../models/sheet_spec.dart';
import '../models/units.dart';
import '../schema/sheet_spec_schema.dart';
import 'layout_geometry.dart';

/// Compiles a validated [SheetSpec] to a print-ready, vector PDF.
///
/// The ONLY other consumer of the spec's mm geometry is the detection
/// template; both go through [LayoutGeometry], so what you print is exactly
/// what the reader expects — by construction, not by testing.
///
/// Ink discipline: everything a student writes near (bubble outlines, option
/// letters, question numbers, labels) prints in the drop-out colour; only the
/// registration marks (fiducials, timing bars, QR) print black.
Future<Uint8List> compileSheetPdf(
  SheetSpec spec, {
  String? examTitle,
}) {
  validateSheetSpec(spec);

  final doc = PdfDocument(compress: true);
  final format = PdfPageFormat(
    spec.paperWidthMm * PdfPageFormat.mm,
    spec.paperHeightMm * PdfPageFormat.mm,
  );
  final page = PdfPage(doc, pageFormat: format);
  final canvas = page.getGraphics();

  _SheetPainter(
    spec: spec,
    geometry: LayoutGeometry.of(spec),
    canvas: canvas,
    format: format,
    font: PdfFont.helvetica(doc),
    boldFont: PdfFont.helveticaBold(doc),
  ).paint(examTitle);

  return doc.save();
}

class _SheetPainter {
  _SheetPainter({
    required this.spec,
    required this.geometry,
    required this.canvas,
    required this.format,
    required this.font,
    required this.boldFont,
  });

  final SheetSpec spec;
  final LayoutGeometry geometry;
  final PdfGraphics canvas;
  final PdfPageFormat format;
  final PdfFont font;
  final PdfFont boldFont;

  static const double _mm = PdfPageFormat.mm;

  /// Drop-out orange #D64000 — const ctor, 0–1 components.
  static const PdfColor _dropout = PdfColor(214 / 255, 64 / 255, 0);
  static const PdfColor _ink = PdfColor(0, 0, 0);

  /// y-flip happens HERE and nowhere else: spec mm (origin top-left, y down)
  /// -> PDF pt (origin bottom-left, y up).
  double _y(double mmY) => format.height - mmY * _mm;
  double _x(double mmX) => mmX * _mm;

  void paint(String? examTitle) {
    // Explicit white ground. A PDF page paints nothing by default and several
    // real-world consumers rasterize unpainted transparency as BLACK (sips,
    // some Android print pipelines, dark-mode PDF previews) — which would
    // swallow every black element on the sheet. Ground must be opaque white.
    canvas.setFillColor(PdfColors.white);
    canvas.drawRect(0, 0, format.width, format.height);
    canvas.fillPath();

    _paintHeader(examTitle);
    _paintFiducials();
    _paintTimingTrack();
    _paintQr();
    _paintBlocks();
    _paintSerial();
  }

  // ---------------------------------------------------------------- header

  void _paintHeader(String? examTitle) {
    final title = examTitle ?? 'OMR ANSWER SHEET';
    final top = spec.marginMm + 4.0;
    _drawTextCentered(
      boldFont,
      12,
      title,
      spec.paperWidthMm / 2,
      top,
      color: _ink,
    );
    final sub = '${spec.layoutId} v${spec.layoutVersion}'
        // '·' (U+00B7) is Latin-1 safe; Helvetica here has no Unicode
        // support and anything beyond Latin-1 throws at measure time.
        '  ·  ${spec.instructionText}'.trim();
    _drawTextCentered(
      font,
      7,
      sub,
      spec.paperWidthMm / 2,
      top + 6,
      color: _ink,
    );
  }

  void _paintSerial() {
    final text = spec.serialText.isEmpty
        ? '${spec.layoutId} v${spec.layoutVersion}'
        : spec.serialText;
    _drawTextCentered(
      font,
      7,
      text,
      spec.paperWidthMm / 2,
      spec.paperHeightMm - spec.marginMm / 2 + 1.5,
      color: _ink,
    );
  }

  // ------------------------------------------------------------ registration

  void _paintFiducials() {
    final fid = spec.fiducials;
    canvas.setFillColor(_ink);
    for (final corner in geometry.fiducialCenters.keys) {
      final rect = geometry.fiducialRect(corner);
      if (corner == fid.altAnchorCorner) {
        _paintLAnchor(rect);
      } else {
        _fillRect(rect);
      }
    }
  }

  void _paintLAnchor(MmRect box) {
    final arm = spec.fiducials.lArmMm;
    // Vertical arm (full height) + horizontal arm (full width), sharing the
    // corner nearest the page corner — visually an L, geometrically a stable
    // alternate anchor distinct from any square.
    _fillRect(MmRect(box.x, box.y, arm, box.h));
    _fillRect(MmRect(box.x, box.bottom - arm, box.w, arm));
  }

  void _paintTimingTrack() {
    canvas.setFillColor(_ink);
    for (final bar in geometry.timingBars) {
      _fillRect(bar);
    }
  }

  void _paintQr() {
    // ECC M (QrErrorCorrectLevel.M): ~15% codeword recovery — the right
    // trade for a 16mm symbol on a phone photo.
    final code = qr.QrCode.fromData(
      data: spec.qrPayload,
      errorCorrectLevel: qr.QrErrorCorrectLevel.M,
    );
    final image = qr.QrImage(code);
    final n = image.moduleCount;
    final quiet = 4; // modules of mandatory quiet zone
    final moduleMm = spec.qrZone.sizeMm / (n + 2 * quiet);
    final rect = geometry.qrRect;

    // Quiet zone explicitly painted so photocopies keep a clean border even
    // when the surrounding print darkens.
    canvas.setFillColor(PdfColors.white);
    _fillRect(rect);

    canvas.setFillColor(_ink);
    for (var row = 0; row < n; row++) {
      for (var col = 0; col < n; col++) {
        if (!image.isDark(row, col)) continue;
        _fillRect(MmRect(
          rect.x + (quiet + col) * moduleMm,
          rect.y + (quiet + row) * moduleMm,
          moduleMm,
          moduleMm,
        ));
      }
    }
  }

  // ----------------------------------------------------------------- fields

  void _paintBlocks() {
    final bs = spec.bubbleStyle;
    canvas.setStrokeColor(_dropout);
    canvas.setFillColor(_dropout);
    canvas.setLineWidth(bs.strokeMm * _mm);

    for (final block in spec.fieldBlocks) {
      switch (block.blockType) {
        case BlockType.mcq:
        case BlockType.matrix:
          _paintMcqBlock(block);
        case BlockType.rollDigits:
          _paintRollBlock(block);
        case BlockType.intDigits:
          _paintIntBlock(block);
        case BlockType.setCode:
          _paintSetBlock(block);
      }
    }
  }

  void _paintMcqBlock(FieldBlock block) {
    final bs = spec.bubbleStyle;
    final fields = block.fields;
    final values = block.optionValues;

    // Per row: question number in the left gutter, a drop-out writing guide
    // BELOW the ovals, then the bubbles with their option letters.
    for (var f = 0; f < fields.length; f++) {
      final first = block.bubbleCenter(f, 0);
      final last = block.bubbleCenter(f, values.length - 1);

      // Question number, right-aligned just left of the row's first bubble.
      _drawTextRight(
        font,
        7,
        _displayLabel(fields[f]),
        first.x - bs.wMm / 2 - 1.2,
        first.y,
        color: _dropout,
      );

      // Writing guide: a 0.15mm drop-out rule BELOW the ovals, never through
      // them — the reader samples the inner 70% of each bubble and printed
      // ink inside that ROI contaminates the mean on photocopied sheets
      // (photocopy grayscale keeps drop-out ink visible). 0.5mm under the
      // rims clears both presets' row pitches (std90 +3.8mm, neet180 +2.2mm
      // to the next row's top).
      canvas.setStrokeColor(_dropout);
      canvas.setLineWidth(0.15 * _mm);
      final guideY = first.y + bs.hMm / 2 + 0.5;
      canvas.drawLine(
        _x(first.x - bs.wMm / 2 - 0.8),
        _y(guideY),
        _x(last.x + bs.wMm / 2 + 0.8),
        _y(guideY),
      );
      canvas.strokePath();

      for (var o = 0; o < values.length; o++) {
        _paintBubble(block, f, o, label: values[o], sizePt: 6.5);
      }
    }
  }

  void _paintRollBlock(FieldBlock block) {
    _drawBlockCaption(block, 'ROLL NO.');
    final fields = block.fields;
    final topMm = _horizontalGridTopMm(block);
    // Digit-position markers above the grid so a misaligned column is
    // visible to a human at a glance. The checksum column is marked '#'.
    for (var f = 0; f < fields.length; f++) {
      final c = block.bubbleCenter(f, 0);
      _drawTextCentered(
        font,
        6,
        f == fields.length - 1 && spec.rollChecksum ? '#' : '${f + 1}',
        c.x,
        topMm - 1.2,
        color: _dropout,
      );
    }
    for (var f = 0; f < fields.length; f++) {
      for (var o = 0; o < 10; o++) {
        // 6.5pt matches the MCQ option letters — visually confirmed legible
        // on a 150dpi raster while 5.5pt digits were not. Drop-out ink makes
        // the digit invisible to detection regardless of print size.
        _paintBubble(block, f, o, label: '$o', sizePt: 6.5);
      }
    }
  }

  void _paintIntBlock(FieldBlock block) {
    _drawBlockCaption(block, 'ANSWER');
    final topMm = _horizontalGridTopMm(block);
    for (var f = 0; f < block.fields.length; f++) {
      final c = block.bubbleCenter(f, 0);
      _drawTextCentered(
        font,
        6,
        '${f + 1}',
        c.x,
        topMm - 1.2,
        color: _dropout,
      );
      for (var o = 0; o < 10; o++) {
        _paintBubble(block, f, o, label: '$o', sizePt: 6.5);
      }
    }
  }

  /// Top edge (mm) of a horizontal digit grid — above it is where column
  /// labels go.
  double _horizontalGridTopMm(FieldBlock block) =>
      block.originMm.y - spec.bubbleStyle.hMm / 2;

  void _paintSetBlock(FieldBlock block) {
    _drawBlockCaption(block, 'SET');
    final values = block.optionValues;
    for (var o = 0; o < values.length; o++) {
      _paintBubble(block, 0, o, label: values[o], sizePt: 6.5);
    }
  }

  void _paintBubble(
    FieldBlock block,
    int fieldIndex,
    int optionIndex, {
    required String label,
    required double sizePt,
  }) {
    final bs = spec.bubbleStyle;
    final c = block.bubbleCenter(fieldIndex, optionIndex);

    canvas.setStrokeColor(_dropout);
    canvas.setLineWidth(bs.strokeMm * _mm);
    canvas.drawEllipse(
      _x(c.x),
      _y(c.y),
      bs.wMm / 2 * _mm,
      bs.hMm / 2 * _mm,
    );
    canvas.strokePath();

    // Option letter/digit printed INSIDE the bubble in drop-out ink: the
    // reader samples the inner 70% where the mark sits, and the letter
    // vanishes in the drop-out channel anyway.
    _drawTextCentered(
      font,
      sizePt,
      label,
      c.x,
      c.y,
      color: _dropout,
    );
  }

  void _drawBlockCaption(FieldBlock block, String caption) {
    final extent = block.extentMm(
      bubbleW: spec.bubbleStyle.wMm,
      bubbleH: spec.bubbleStyle.hMm,
    );
    // 4.2mm above the block top: clear of the per-column position labels
    // that sit 1.2mm above digit grids.
    _drawTextCentered(
      boldFont,
      7,
      caption,
      extent.centerX,
      extent.y - 4.2,
      color: _dropout,
    );
  }

  // ---------------------------------------------------------------- helpers

  void _fillRect(MmRect r) {
    canvas.drawRect(_x(r.x), _y(r.bottom), r.w * _mm, r.h * _mm);
    canvas.fillPath();
  }

  void _drawText(
    PdfFont f,
    double sizePt,
    String s,
    double xMm,
    double yCenterMm, {
    required PdfColor color,
  }) {
    // Baseline nudged so yCenterMm vertically centres the glyphs. PDF y grows
    // UP, so the baseline sits BELOW the centre by ~half a cap height and the
    // glyph body straddles it. (A '+' here rides the top rim — verified
    // defect on the rendered sheet: digits clipped by the oval outline.)
    canvas.setColor(color);
    canvas.drawString(f, sizePt, s, _x(xMm), _y(yCenterMm) - sizePt * 0.35);
  }

  void _drawTextCentered(
    PdfFont f,
    double sizePt,
    String s,
    double xCenterMm,
    double yCenterMm, {
    required PdfColor color,
  }) {
    _drawText(
      f,
      sizePt,
      s,
      xCenterMm - _textWidthMm(f, sizePt, s) / 2,
      yCenterMm,
      color: color,
    );
  }

  void _drawTextRight(
    PdfFont f,
    double sizePt,
    String s,
    double xRightMm,
    double yCenterMm, {
    required PdfColor color,
  }) {
    _drawText(
      f,
      sizePt,
      s,
      xRightMm - _textWidthMm(f, sizePt, s),
      yCenterMm,
      color: color,
    );
  }

  // stringMetrics returns advances in EM-FRACTIONS (Helvetica space = 0.278),
  // so points-at-size = advanceWidth * sizePt — no /1000. An earlier version
  // divided by 1000, making every measured width 1000x too small: centered
  // text started at its anchor and extended right by the full width.
  double _textWidthMm(PdfFont f, double sizePt, String s) =>
      textWidthMm(f, sizePt, s);

  /// q3 -> "3." for the row gutter (compact, human-familiar).
  String _displayLabel(String fieldKey) {
    final m = RegExp(r'^[a-zA-Z]+(\d+)$').firstMatch(fieldKey);
    return m == null ? fieldKey : '${m.group(1)}.';
  }
}

/// Exposed for tests/tools: the drop-out colour the compilers agree on.
const PdfColor kDropoutColor = _SheetPainter._dropout;

/// Exposed for tests/tools: text width in mm for layout assertions.
///
/// [PdfFont.stringMetrics] advances are em-fractions (Helvetica space =
/// 0.278), so points at [sizePt] = advanceWidth * sizePt; converting via
/// [PdfPageFormat.mm] gives mm.
double textWidthMm(PdfFont f, double sizePt, String s) =>
    f.stringMetrics(s).advanceWidth * sizePt / PdfPageFormat.mm;
