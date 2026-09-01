/// The OpenCV firewall (plan §1).
///
/// Every `cv.*` call the pipeline makes goes through this interface, and the
/// interface speaks only in plain Dart value types — no `Mat`, `Point` or
/// `Scalar` from the binding package ever crosses the boundary. Two reasons
/// this exists:
///
/// 1. **opencv_dart is single-maintainer, pinned, and builds OpenCV from
///    source.** If it breaks, one file is rewritten against another binding
///    (or raw FFI) and every stage above survives untouched.
/// 2. **The live capture loop has a frame budget** (~32 ms at 640×480 on a
///    low-end device). If the Dart bridge can't meet it, a Kotlin
///    implementation of `detectQuad` + gates slots in behind the same
///    method signatures — the pipeline code is untouched (plan §3).
///
/// Mats are owned by the service: callers pass opaque [CvMat] handles back
/// in and call [dispose] when done. Native memory is not GC-managed.
library;

import 'dart:typed_data';

/// Opaque handle to a native image. Only [OpencvService] implementations
/// may look inside [inner] — everyone else passes the handle around.
class CvMat {
  const CvMat(this.inner);

  /// The binding package's mat object. Public only because Dart privacy is
  /// per-library and implementations live in their own files.
  final Object inner;
}

/// Integer point in analysis-stream pixel coordinates.
class CvPointI {
  const CvPointI(this.x, this.y);

  final int x;
  final int y;

  @override
  bool operator ==(Object other) =>
      other is CvPointI && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => '($x, $y)';
}

/// Integer size (width, height).
class CvSizeI {
  const CvSizeI(this.width, this.height);

  final int width;
  final int height;

  @override
  String toString() => '${width}x$height';
}

/// Integer rectangle (x, y, w, h) — a quadrant search window, a bubble ROI,
/// or a crop box.
class CvRectI {
  const CvRectI(this.x, this.y, this.width, this.height);

  final int x;
  final int y;
  final int width;
  final int height;

  @override
  String toString() => '[$x,$y ${width}x$height]';
}

/// Where a template matched, and how well (TM_CCOEFF_NORMED, −1..1).
class CvMatch {
  const CvMatch(this.score, this.at);

  final double score;
  final CvPointI at;

  @override
  String toString() => '$score @ $at';
}

/// A suppression disk for [OpencvService.matchTemplate]: matches whose
/// patch CENTRE lands within [r] of `(x, y)` are ignored. The fallback
/// ladder re-searches a rejected corner over the whole frame — three of
/// the four anchors are identical squares, so without suppression that
/// search can return a NEIGHBOUR's anchor at full score and the warp
/// built from it would be a silent inside-out disaster.
class CvExclude {
  const CvExclude({required this.x, required this.y, required this.r});

  final double x;
  final double y;
  final double r;
}

/// A captured still, decoded to the form [OmrPipeline.evaluateGray]
/// consumes: single-channel, row-major, EXIF orientation already applied.
class DecodedStill {
  const DecodedStill({
    required this.width,
    required this.height,
    required this.gray,
  });

  final int width;
  final int height;
  final Uint8List gray;
}

/// The contract every CV-touching stage codes against.
abstract class OpencvService {
  /// Wraps pixels already decoded in host memory.
  ///
  /// [bytes] is row-major, 1 byte/pixel for gray, 3 (BGR) for color. The
  /// service copies the buffer, so the caller may reuse it immediately.
  CvMat grayFromBytes(int width, int height, Uint8List bytes);
  CvMat bgrFromBytes(int width, int height, Uint8List bytes);

  /// Stage 1 (plan §3) — decode captured still bytes (JPEG from
  /// `takePicture`) to an EXIF-oriented grayscale buffer. Throws when the
  /// bytes are not a decodable image: a capture the codec cannot read is an
  /// operator-visible failure, not a zero-fill.
  DecodedStill decodeStill(Uint8List bytes);

  /// Encodes a grayscale buffer as JPEG — the inverse of [decodeStill], so
  /// tests and the golden harness can feed the still pipeline synthetic
  /// captures through the same bytes the camera produces.
  Uint8List encodeGrayJpeg(int width, int height, Uint8List gray);

  /// Releases native memory. Handles are unusable afterwards.
  void dispose(CvMat m);

  /// Sub-image copy (a quadrant to search, a fiducial template to extract).
  CvMat crop(CvMat src, CvRectI roi);

  /// Row-major copy of a single-channel 8-bit mat's pixels — the inverse of
  /// [grayFromBytes]. The copy outlives [dispose] (persisting the warped
  /// grayscale is a product requirement, so the escape hatch is product
  /// surface, not test scaffolding).
  Uint8List grayBytes(CvMat m);

  /// Stage 1/5 conversions and smoothing.
  CvMat toGray(CvMat bgr);
  CvMat gaussianBlur(CvMat src, int ksize);

  /// Stage 2 — best [CvRectI]-restricted match of [templ] inside [roi] of
  /// [image], normalised cross-correlation. Matches centred inside an
  /// [CvExclude] disk are suppressed (fallback-ladder re-search only).
  CvMatch matchTemplate(
    CvMat image,
    CvRectI roi,
    CvMat templ, {
    List<CvExclude>? exclude,
  });

  /// Stage 3 — 4-point homography from [corners] (any rotation order; the
  /// caller resolves orientation) onto a fixed [canvas] rectangle, warps,
  /// and returns the warped canvas.
  CvMat warpToCanvas(CvMat src, List<CvPointI> corners, CvSizeI canvas);

  /// Stage 3 (fiducial path) — homography from four ARBITRARY
  /// correspondences [srcPoints]→[dstPoints] (both ordered, 4 entries)
  /// rather than to the canvas corners: the registered anchors map to
  /// their template positions, inset from the corners as printed.
  CvMat warp(
    CvMat src,
    List<CvPointI> srcPoints,
    List<CvPointI> dstPoints,
    CvSizeI canvas,
  );

  /// Stage 6 — mean intensity (0..255) of the single channel over [roi].
  double roiMean(CvMat gray, CvRectI roi);

  /// Stage 4 — sub-pixel centroid of the dark mass inside [roi], in the
  /// source image's coordinates, or null when the ROI holds no meaningful
  /// dark area (below [threshold] everywhere). Binarised inverted at
  /// [threshold], then image moments — the timing-bar position measurement
  /// the curvature gate consumes on the warped canvas.
  ({double x, double y})? darkCentroid(
    CvMat gray,
    CvRectI roi, {
    int threshold = 100,
  });

  /// Stage 0 / blur gate — variance of the Laplacian over [roi]; higher is
  /// sharper. ROI null means the whole image.
  double laplacianVariance(CvMat gray, CvRectI? roi);

  /// Capture loop — the largest 4-corner convex quad in a 640×480 analysis
  /// frame, corners ordered tl, tr, br, bl, or null when none qualifies
  /// (area below the gate's minimum). This is the call with the per-frame
  /// budget; a Kotlin implementation must reproduce its exact contract.
  List<CvPointI>? detectQuad(CvMat gray);
}
