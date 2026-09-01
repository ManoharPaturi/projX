import 'dart:math' as math;
import 'dart:typed_data';

import 'package:opencv_dart/opencv_dart.dart' as cv;

import 'opencv_service.dart';

/// The only file in the repo that imports the binding package.
///
/// Everything is a thin, allocation-careful mapping onto dartcv4: mats are
/// constructed with the right [cv.MatType], used once, and disposed on the
/// way out — native memory is not GC-managed, so every temporary is wrapped
/// so a throw can't leak it.
class OpencvDartImpl implements OpencvService {
  cv.Mat _mat(CvMat m) => m.inner as cv.Mat;

  @override
  CvMat grayFromBytes(int width, int height, Uint8List bytes) => CvMat(
        cv.Mat.fromList(height, width, cv.MatType.CV_8UC1, bytes),
      );

  @override
  CvMat bgrFromBytes(int width, int height, Uint8List bytes) => CvMat(
        cv.Mat.fromList(height, width, cv.MatType.CV_8UC3, bytes),
      );

  @override
  DecodedStill decodeStill(Uint8List bytes) {
    // imdecode applies EXIF orientation itself on this build (4.13.0) —
    // verified by still_decode_test's dims assertions, which exist so a
    // codec bump that silently DROPS the tag fails a test instead of
    // feeding the registrar tipped-sideways sheets.
    final mat = cv.imdecode(bytes, cv.IMREAD_GRAYSCALE);
    try {
      if (mat.isEmpty) {
        throw StateError(
          'still bytes are not a decodable image (${bytes.length} bytes)',
        );
      }
      return DecodedStill(
        width: mat.cols,
        height: mat.rows,
        gray: Uint8List.fromList(mat.data),
      );
    } finally {
      mat.dispose();
    }
  }

  @override
  Uint8List encodeGrayJpeg(int width, int height, Uint8List gray) {
    final mat = cv.Mat.fromList(height, width, cv.MatType.CV_8UC1, gray);
    try {
      final (ok, bytes) = cv.imencode('.jpg', mat);
      if (!ok) {
        throw StateError('imencode failed for ${width}x$height gray');
      }
      return bytes;
    } finally {
      mat.dispose();
    }
  }

  @override
  void dispose(CvMat m) => _mat(m).dispose();

  @override
  CvMat crop(CvMat src, CvRectI roi) {
    final inner = _mat(src);
    return CvMat(
      cv.Mat.fromMat(
        inner,
        roi: cv.Rect(roi.x, roi.y, roi.width, roi.height),
        copy: true,
      ),
    );
  }

  @override
  Uint8List grayBytes(CvMat m) {
    // Mat.data is a VIEW over native memory that dangles once the mat is
    // disposed — the caller keeps the copy, not the mat.
    return Uint8List.fromList(_mat(m).data);
  }

  @override
  CvMat toGray(CvMat bgr) =>
      CvMat(cv.cvtColor(_mat(bgr), cv.COLOR_BGR2GRAY));

  @override
  CvMat gaussianBlur(CvMat src, int ksize) => CvMat(
        cv.gaussianBlur(_mat(src), (ksize, ksize), 0),
      );

  @override
  CvMatch matchTemplate(
    CvMat image,
    CvRectI roi,
    CvMat templ, {
    List<CvExclude>? exclude,
  }) {
    // Restrict the search to the quadrant first — a match must not be able
    // to straddle a sheet midline (plan §3, stage 2).
    final search = crop(image, roi);
    final result =
        cv.matchTemplate(_mat(search), _mat(templ), cv.TM_CCOEFF_NORMED);
    try {
      _suppress(result, roi, templ, exclude);
      final (_, maxVal, _, maxLoc) = cv.minMaxLoc(result);
      return CvMatch(
        maxVal,
        CvPointI(roi.x + maxLoc.x, roi.y + maxLoc.y),
      );
    } finally {
      result.dispose();
      dispose(search);
    }
  }

  /// Punches each [CvExclude] disk out of the score map so it can't win.
  ///
  /// Result cell (x, y) corresponds to the template's top-left landing at
  /// `(roi.x + x, roi.y + y)`; the cell's patch centre is therefore half a
  /// template further in, and the suppressed zone is the disk translated by
  /// that offset. Rectangular approximation of the disk — conservative in
  /// the right direction (it can only exclude slightly more).
  void _suppress(
    cv.Mat result,
    CvRectI roi,
    CvMat templ,
    List<CvExclude>? exclude,
  ) {
    if (exclude == null || exclude.isEmpty) return;
    final t = _mat(templ);
    final halfW = t.cols / 2, halfH = t.rows / 2;
    for (final e in exclude) {
      final x0 = math.max(0, (e.x - e.r - roi.x - halfW).round());
      final x1 = math.min(result.cols, (e.x + e.r - roi.x - halfW).ceil());
      final y0 = math.max(0, (e.y - e.r - roi.y - halfH).round());
      final y1 = math.min(result.rows, (e.y + e.r - roi.y - halfH).ceil());
      if (x0 >= x1 || y0 >= y1) continue;
      final rows = result.rowRange(y0, y1);
      try {
        final cell = rows.colRange(x0, x1);
        try {
          // Below any score TM_CCOEFF_NORMED can produce.
          cell.setTo(cv.Scalar.all(-2));
        } finally {
          cell.dispose();
        }
      } finally {
        rows.dispose();
      }
    }
  }

  @override
  CvMat warpToCanvas(CvMat src, List<CvPointI> corners, CvSizeI canvas) {
    // The canonical detection canvas corners, clockwise from top-left.
    return warp(
      src,
      corners,
      [
        CvPointI(0, 0),
        CvPointI(canvas.width - 1, 0),
        CvPointI(canvas.width - 1, canvas.height - 1),
        CvPointI(0, canvas.height - 1),
      ],
      canvas,
    );
  }

  @override
  CvMat warp(
    CvMat src,
    List<CvPointI> srcPoints,
    List<CvPointI> dstPoints,
    CvSizeI canvas,
  ) {
    final dst = cv.VecPoint.fromList([
      for (final p in dstPoints) cv.Point(p.x, p.y),
    ]);
    final srcPts = cv.VecPoint.fromList([
      for (final p in srcPoints) cv.Point(p.x, p.y),
    ]);
    final homography = cv.getPerspectiveTransform(srcPts, dst);
    try {
      final warped =
          cv.warpPerspective(_mat(src), homography, (canvas.width, canvas.height));
      return CvMat(warped);
    } finally {
      homography.dispose();
      srcPts.dispose();
      dst.dispose();
    }
  }

  @override
  double roiMean(CvMat gray, CvRectI roi) {
    final m = _mat(gray);
    final sub = cv.Mat.fromMat(
      m,
      roi: cv.Rect(roi.x, roi.y, roi.width, roi.height),
    );
    try {
      // Gray is single-channel: val1 is the mean of channel 0.
      return cv.mean(sub).val1;
    } finally {
      sub.dispose();
    }
  }

  @override
  ({double x, double y})? darkCentroid(
    CvMat gray,
    CvRectI roi, {
    int threshold = 100,
  }) {
    final sub = cv.Mat.fromMat(
      _mat(gray),
      roi: cv.Rect(roi.x, roi.y, roi.width, roi.height),
    );
    cv.Mat? bin;
    try {
      (_, bin) = cv.threshold(
        sub,
        threshold.toDouble(),
        255,
        cv.THRESH_BINARY_INV,
      );
      final m = cv.moments(bin, binaryImage: true);
      // Under ~1 px of dark mass the centroid is noise on an empty region.
      if (m.m00 < 1) return null;
      return (x: roi.x + m.m10 / m.m00, y: roi.y + m.m01 / m.m00);
    } finally {
      bin?.dispose();
      sub.dispose();
    }
  }

  @override
  double laplacianVariance(CvMat gray, CvRectI? roi) {
    final m = _mat(gray);
    final measured = roi == null
        ? m
        : cv.Mat.fromMat(m, roi: cv.Rect(roi.x, roi.y, roi.width, roi.height));
    final ownedSub = roi == null ? null : measured;
    // Laplacian of a flat region is exactly 0; its variance over the ROI is
    // the classic sharpness score (stage 0 / blur gate).
    final lap = cv.laplacian(measured, cv.MatType.CV_16S, ksize: 3);
    try {
      final (_, stddev) = cv.meanStdDev(lap);
      return stddev.val1 * stddev.val1;
    } finally {
      lap.dispose();
      ownedSub?.dispose();
    }
  }

  @override
  List<CvPointI>? detectQuad(CvMat gray) {
    final m = _mat(gray);
    final blurred = cv.gaussianBlur(m, (5, 5), 0);
    final edges = cv.canny(blurred, 85, 185);
    final kernel = cv.getStructuringElement(cv.MORPH_RECT, (10, 10));
    final closed = cv.morphologyEx(edges, cv.MORPH_CLOSE, kernel);
    final (contours, _) = cv.findContours(closed, cv.RETR_EXTERNAL,
        cv.CHAIN_APPROX_SIMPLE);
    try {
      cv.Contour? best;
      var bestArea = 0.0;
      for (final contour in contours) {
        final area = cv.contourArea(contour);
        if (area > bestArea) {
          bestArea = area;
          best = contour;
        }
      }
      if (best == null) return null;
      // Below the capture gate's minimum area fraction: no quad to show.
      if (bestArea < 0.15 * m.cols * m.rows) return null;

      // Convex hull before approx is planned for the capture loop (plan
      // §3); for a sheet-shaped contour the largest-area contour already
      // approximates to 4 points, so the smoke path skips the hull hop.
      final perimeter = cv.arcLength(best, true);
      final approx = cv.approxPolyDP(best, 0.02 * perimeter, true);
      try {
        if (approx.length != 4) return null;
        final quad = <CvPointI>[
          for (final p in approx) CvPointI(p.x, p.y),
        ];
        return _orderCorners(quad);
      } finally {
        approx.dispose();
      }
    } finally {
      blurred.dispose();
      edges.dispose();
      kernel.dispose();
      closed.dispose();
      contours.dispose();
    }
  }

  /// Orders corners tl, tr, br, bl by the sum/difference trick (plan §3):
  /// tl minimises x+y, br maximises it, tr minimises y−x, bl maximises it.
  List<CvPointI> _orderCorners(List<CvPointI> pts) {
    int bySum(bool asc) {
      var best = pts.first;
      var bestKey = best.x + best.y;
      for (final p in pts.skip(1)) {
        final key = p.x + p.y;
        if (asc ? key < bestKey : key > bestKey) {
          bestKey = key;
          best = p;
        }
      }
      return pts.indexOf(best);
    }

    int byDiff(bool asc) {
      var best = pts.first;
      var bestKey = best.y - best.x;
      for (final p in pts.skip(1)) {
        final key = p.y - p.x;
        if (asc ? key < bestKey : key > bestKey) {
          bestKey = key;
          best = p;
        }
      }
      return pts.indexOf(best);
    }

    final tl = pts[bySum(true)];
    final br = pts[bySum(false)];
    final tr = pts[byDiff(true)];
    final bl = pts[byDiff(false)];
    return [tl, tr, br, bl];
  }
}
