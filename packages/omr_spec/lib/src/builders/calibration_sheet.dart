import '../models/bubble_style.dart';
import '../models/field_block.dart';
import '../models/fiducial.dart';
import '../models/qr_zone.dart';
import '../models/section.dart';
import '../models/sheet_spec.dart';
import '../models/timing_track.dart';
import '../models/units.dart';
import '../schema/sheet_spec_schema.dart';
import '../compile/pdf_sheet_compiler.dart' show BubbleFill;

/// Printer-calibration sheet (plan §9, M4): the SAME frame as Standard-90 —
/// identical fiducials, timing track, QR zone, roll grid, bubble style — so
/// calibration exercises exactly the geometry production sheets print. The
/// exam columns are replaced by reference bubble rows at known ink levels.
///
/// Three columns (Standard-90's own x positions) × 12 rows at 18mm pitch —
/// a coarser pitch than production 7.8mm, which the shared-row-grid
/// validator is happy with and which changes nothing the reader measures:
/// bubbles are the same 5.0×3.5mm ovals at the same 8 px/mm canvas scale;
/// only the spacing between rows differs.
///
/// Rows group into three bands down the page — `t` (rows 1–4, y 42–96),
/// `m` (rows 5–8, y 114–168), `b` (rows 9–12, y 186–240) — and each band's
/// four rows print one level each:
///
/// | row    | printed fill                      | measures                    |
/// |--------|-----------------------------------|-----------------------------|
/// | `full` | all 4 options, near-black (30)    | the FILLED population       |
/// | `faint`| all 4 options, pencil-faint (150) | the review band's faint end |
/// | `mid`  | 3 options, mid gray (105)         | a deliberate in-band mark   |
/// | `empty`| none                              | the EMPTY population        |
///
/// The analyzer pools all three columns per band, so each (band, level)
/// cell carries 9–12 bubble samples. Field keys follow
/// `cal_<col>_<band>_<level>`; builder and analyzer share these constants so
/// the naming cannot drift.
const List<String> calibrationBands = ['t', 'm', 'b'];
const List<String> calibrationLevels = ['full', 'faint', 'mid', 'empty'];

/// Printed gray (0=black..255=white) per reference level. `faint` simulates a
/// light pencil pass, `mid` a deliberate half-pressure mark — the analyzer
/// does NOT assume these values, it measures; they exist so a margin report
/// can say "your printer's faint end landed at X".
const Map<String, int> calibrationLevelGrays = {
  'full': 30,
  'mid': 105,
  'faint': 150,
};

/// The calibration sheet: the validated spec (print + detection geometry) and
/// the print-only fills the PDF compiler paints inside the reference bubbles.
/// Fills are NOT part of the spec JSON — they are ink, not geometry, so they
/// neither enter `specHash` nor bump `layoutVersion`.
class CalibrationSheet {
  const CalibrationSheet({required this.spec, required this.fills});

  final SheetSpec spec;

  /// fieldKey → which options get interior gray fill, at what level.
  final Map<String, BubbleFill> fills;
}

/// Builds the calibration sheet on the Standard-90 frame.
SheetSpec buildCalibrationSpec({
  String layoutId = 'calib',
  int layoutVersion = 1,
}) {
  const bubble = BubbleStyle(wMm: 5.0, hMm: 3.5, strokeMm: 0.25, pitchMm: 7.6);
  const x1 = 24.0, x2 = 57.8, x3 = 91.6;

  // 18mm row pitch × 12 rows spans y 42..240 (bottom edge 241.75), sampling
  // the full page height; bands are contiguous row groups of four.
  const originY = 42.0;
  const rowPitch = 18.0;

  String label(int col, int row) =>
      'cal_c${col}_${calibrationBands[row ~/ 4]}_'
      '${calibrationLevels[row % 4]}';

  final blocks = <FieldBlock>[
    for (var c = 0; c < 3; c++)
      FieldBlock(
        blockId: 'cal_c${c + 1}',
        blockType: BlockType.mcq,
        originMm: MmPoint(
          c == 0
              ? x1
              : c == 1
              ? x2
              : x3,
          originY,
        ),
        bubblePitchMm: 7.6,
        rowPitchMm: rowPitch,
        direction: BlockDirection.vertical,
        options: 4,
        fieldLabels: [for (var r = 0; r < 12; r++) label(c + 1, r)],
      ),
  ];

  // Roll + set blocks cloned from Standard-90: the validator requires them,
  // and printing them keeps the calibration capture exercising the exact
  // production geometry (a calibration verdict then covers the roll grid's
  // detection too, at no extra cost).
  final roll = FieldBlock(
    blockId: 'roll',
    blockType: BlockType.rollDigits,
    originMm: const MmPoint(132.0, 42.0),
    bubblePitchMm: 7.4,
    rowPitchMm: 8.5,
    direction: BlockDirection.horizontal,
    options: 10,
    fieldLabels: const ['roll1..roll8'],
  );
  final set = FieldBlock(
    blockId: 'set',
    blockType: BlockType.setCode,
    originMm: const MmPoint(147.9, 132.0),
    bubblePitchMm: 7.6,
    rowPitchMm: 7.8,
    direction: BlockDirection.vertical,
    options: 4,
    bubbleValues: const ['A', 'B', 'C', 'D'],
    fieldLabels: const ['set'],
  );

  return validateOrThrow(
    SheetSpec(
      specVersion: 1,
      layoutId: layoutId,
      layoutVersion: layoutVersion,
      paperSizeMm: (a4WidthMm, a4HeightMm),
      marginMm: 10,
      headerHeightMm: 30,
      bubbleStyle: bubble,
      fiducials: const FiducialLayout(
        sizeMm: 9,
        insetMm: 12,
        whiteSurroundMm: 3.5,
      ),
      timingTrack: const TimingTrack(
        edge: 'left',
        barWMm: 5.5,
        barHMm: 2.5,
        clearanceMm: 5.0,
      ),
      qrZone: const QrZone(sizeMm: 16, position: 'tr'),
      fieldBlocks: [...blocks, roll, set],
      sections: [
        SectionSpec(
          id: 'cal',
          name: 'Calibration',
          subject: 'Calibration',
          questionLabels: [
            for (var c = 1; c <= 3; c++)
              for (final band in calibrationBands)
                for (final level in calibrationLevels)
                  'cal_c${c}_${band}_$level',
          ],
        ),
      ],
      rollDigits: 7,
      rollChecksum: true,
      setValues: const ['A', 'B', 'C', 'D'],
      serialText: 'CALIBRATION - print at 100% scale, no fit-to-page',
      instructionText:
          'Printer calibration reference sheet (plan §9). '
          'Do not distribute; see docs/calibration-sop.md.',
    ),
  );
}

/// The sheet plus its reference fills, ready for `compileSheetPdf`.
CalibrationSheet buildCalibrationSheet({
  String layoutId = 'calib',
  int layoutVersion = 1,
}) {
  final spec = buildCalibrationSpec(
    layoutId: layoutId,
    layoutVersion: layoutVersion,
  );
  return CalibrationSheet(spec: spec, fills: calibrationFills());
}

/// The fills, derived from the level table — `mid` leaves one option empty so
/// every printed row band also carries an in-row empty sample.
Map<String, BubbleFill> calibrationFills() => {
  for (var c = 1; c <= 3; c++)
    for (final band in calibrationBands) ...{
      'cal_c${c}_${band}_full': BubbleFill(
        optionIndexes: const [0, 1, 2, 3],
        gray: calibrationLevelGrays['full']!,
      ),
      'cal_c${c}_${band}_faint': BubbleFill(
        optionIndexes: const [0, 1, 2, 3],
        gray: calibrationLevelGrays['faint']!,
      ),
      'cal_c${c}_${band}_mid': BubbleFill(
        optionIndexes: const [0, 1, 2],
        gray: calibrationLevelGrays['mid']!,
      ),
    },
};
