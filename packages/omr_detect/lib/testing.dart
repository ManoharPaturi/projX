/// Synthetic-sheet rendering for tests and the golden harness (plan §9).
///
/// Separate entry point so production code cannot reach the fixture
/// renderer while tests (`package:omr_detect/testing.dart`) and the future
/// `tools/omr_cli` golden harness can.
library;

export 'src/testing/exif_orientation.dart'
    show exifOrientationOf, withExifOrientation;
export 'src/testing/synthetic_sheet.dart' show InkMark, inkAt, renderSheetPhoto;
