import 'package:omr_spec/omr_spec.dart' show DetectionTemplate;

import '../cv/opencv_service.dart' show CvMat, CvPointI, CvSizeI, OpencvService;
import 'fiducial_registrar.dart'
    show FiducialSearch, RegistrationReport;

/// Stage 3: flattens the registered still onto the canonical canvas.
///
/// The four accepted anchor CENTRES map to their printed template
/// positions — not to the canvas corners, because the anchors sit inset
/// from the page corners (12 mm on preset A). A centre-to-corner mapping
/// would stretch the sheet by that inset on every side and every bubble ROI
/// would drift off its mark by millimetres.
///
/// Ordering discipline: correspondences are paired by plan index, so a
/// rotated capture is handled upstream (the registrar searches named
/// corners) and never by permuting points here.
class HomographyWarper {
  const HomographyWarper();

  /// Warps [gray] by the accepted anchors in [registration].
  ///
  /// Throws [StateError] unless exactly four anchors were accepted — the
  /// pipeline consults [RegistrationReport.ok] FIRST and routes anything
  /// less to the fallback ladder (plan §3); reaching this method with a
  /// partial registration is a pipeline bug, not a capture problem.
  CvMat warp(
    OpencvService cv,
    CvMat gray,
    RegistrationReport registration,
    List<FiducialSearch> plan,
    DetectionTemplate template,
  ) {
    if (!registration.ok) {
      throw StateError(
        'warp called with ${registration.accepted.length}/4 anchors — '
        'the fallback ladder owns partial registrations',
      );
    }
    final srcPoints = <CvPointI>[];
    final dstPoints = <CvPointI>[];
    for (final i in registration.accepted) {
      final match = registration.matches[i]!;
      final search = plan[i];
      srcPoints.add(match.center);
      // Plan coordinates are canvas-space doubles from the template; the
      // homography consumes integer points, so round once, here.
      dstPoints.add(
        CvPointI(search.canvasX.round(), search.canvasY.round()),
      );
    }
    return cv.warp(
      gray,
      srcPoints,
      dstPoints,
      CvSizeI(template.canvasWidth, template.canvasHeight),
    );
  }
}
