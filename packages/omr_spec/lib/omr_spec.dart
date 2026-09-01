/// OMR sheet specification — the single source of truth for sheet layouts.
///
/// A declarative mm-based [SheetSpec] compiles to BOTH the printable PDF and
/// the detection template; neither representation is authored independently.
/// Layouts are immutable and versioned; the printed QR resolves the exact
/// version, so old sheets keep grading correctly forever.
library;

export 'src/builders/jee_style_sheet.dart';
export 'src/compile/detection_template.dart'
    show
        BubbleRect,
        DetectionTemplate,
        FiducialRect,
        compileDetectionTemplate,
        pxPerMm,
        specSha256;
export 'src/compile/pdf_sheet_compiler.dart'
    show compileSheetPdf, kDropoutColor, textWidthMm;
export 'src/models/bubble_style.dart';
export 'src/models/fiducial.dart';
export 'src/models/field_block.dart';
export 'src/models/qr_zone.dart';
export 'src/models/section.dart';
export 'src/models/sheet_spec.dart';
export 'src/models/timing_track.dart';
export 'src/models/units.dart';
export 'src/schema/sheet_spec_schema.dart';
