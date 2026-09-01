import 'dart:math' as math;
import 'dart:typed_data';

import 'package:omr_spec/omr_spec.dart' show DetectionTemplate, FiducialRect;

import '../cv/opencv_service.dart'
    show CvMat, CvPointI, CvSizeI, OpencvService;

/// Renders synthetic marked-sheet photos for tests and the golden harness
/// (plan §9): the sheet is drawn ON THE DETECTION CANVAS — template
/// coordinates, trivially correct rects — then warped into the photo
/// through the four anchor correspondences, which is the exact homography
/// the registrar inverts. Fixture geometry and pipeline estimate cancel,
/// leaving only the measurement chain under test.
///
/// Lineage: adapted from `test/pipeline_test.dart`'s fixture; the golden
/// harness (`tools/omr_cli`, M1) builds its perturbation suite on this, and
/// the app's end-to-end test uses it to feed REAL JPEG bytes through the
/// decode seam.

/// One ink mark: a deliberate pen-dot smaller than the bubble outline.
typedef InkMark = ({int x, int y, int w, int h});

/// The ink ROI for a (fieldKey, optionValue) bubble, inner-72 % as a real
/// pen dot lands.
InkMark inkAt(DetectionTemplate template, String fieldKey, String optionValue) {
  return template.bubbles
      .firstWhere((b) => b.fieldKey == fieldKey && b.optionValue == optionValue)
      .roi(fraction: 0.72);
}

/// Draws and warps one photo.
///
/// [marks] are canvas-px ink rects (see [inkAt]). [barShiftMiddleThird]
/// displaces the middle third of the timing track in canvas px — the
/// synthetic stand-in for a curled sheet. [anchorDst] repositions the four
/// anchors in photo px (moving them off the centred layout produces the
/// off-axis captures the fallback ladder exists for).
Uint8List renderSheetPhoto(
  OpencvService cv,
  DetectionTemplate template, {
  required int imageWidth,
  required int imageHeight,
  List<InkMark> marks = const [],
  double barShiftMiddleThird = 0,
  Map<String, CvPointI> anchorDst = const {},
}) {
  final cw = template.canvasWidth, ch = template.canvasHeight;

  // 1. The sheet, in template coordinates. Canvas 0 is reserved as the
  //    warp's outside-sheet sentinel, so "black" prints as 4, not 0.
  final canvas = Uint8List(cw * ch);
  canvas.fillRange(0, canvas.length, 238);
  void fill(int x, int y, int w, int h, int g) {
    for (var yy = math.max(0, y); yy < math.min(ch, y + h); yy++) {
      canvas.fillRange(
        yy * cw + math.max(0, x),
        yy * cw + math.min(cw, x + w),
        g,
      );
    }
  }

  for (final f in template.fiducials) {
    final x = (f.centerX - f.size / 2).round();
    final y = (f.centerY - f.size / 2).round();
    final e = f.size.round();
    if (f.isAltAnchor) {
      // As pdf_sheet_compiler prints it: vertical arm full height along
      // the left edge, horizontal arm full width along the bottom.
      const arm = 20; // 2.5 mm × PX_PER_MM
      fill(x, y, arm, e, 4);
      fill(x, y + e - arm, e, arm, 4);
    } else {
      fill(x, y, e, e, 4);
    }
  }
  final third = template.timingBars.length ~/ 3;
  for (var i = 0; i < template.timingBars.length; i++) {
    final t = template.timingBars[i];
    final shift = (i >= third && i < 2 * third) ? barShiftMiddleThird : 0.0;
    fill((t.x + shift).round(), t.y.round(), t.w.round(), t.h.round(), 4);
  }
  for (final m in marks) {
    fill(m.x, m.y, m.w, m.h, 18);
  }

  // 2. Canvas → photo through the anchor correspondences. Default: the
  //    sheet centred at the largest scale that leaves a desk margin.
  final srcPts = [
    for (final f in template.fiducials)
      CvPointI(f.centerX.round(), f.centerY.round()),
  ];
  final dstPts = [
    for (final f in template.fiducials)
      anchorDst[f.corner] ?? _centredAnchorDst(f, template, imageWidth, imageHeight),
  ];
  final canvasMat = cv.grayFromBytes(cw, ch, canvas);
  final CvMat warpedMat;
  try {
    warpedMat = cv.warp(canvasMat, srcPts, dstPts, CvSizeI(imageWidth, imageHeight));
  } finally {
    cv.dispose(canvasMat);
  }
  final warped = cv.grayBytes(warpedMat);
  cv.dispose(warpedMat);

  // 3. Desk composite: warpPerspective zeroes everything outside the
  //    mapped sheet.
  final bytes = Uint8List(imageWidth * imageHeight);
  bytes.fillRange(0, bytes.length, 60);
  for (var i = 0; i < bytes.length; i++) {
    if (warped[i] != 0) bytes[i] = warped[i];
  }
  return bytes;
}

/// Where [f] lands in the default centred capture: the sheet scaled to
/// ~70 % of the photo, so anchors sit at their natural proportional
/// offsets inside it.
CvPointI _centredAnchorDst(
  FiducialRect f,
  DetectionTemplate template,
  int imageWidth,
  int imageHeight,
) {
  final scale = math.min(
    imageWidth * 0.70 / template.canvasWidth,
    imageHeight * 0.78 / template.canvasHeight,
  );
  final sheetW = template.canvasWidth * scale;
  final sheetH = template.canvasHeight * scale;
  final originX = (imageWidth - sheetW) / 2;
  final originY = (imageHeight - sheetH) / 2;
  return CvPointI(
    (originX + f.centerX * scale).round(),
    (originY + f.centerY * scale).round(),
  );
}
