import '../models/bubble_style.dart';
import '../models/field_block.dart';
import '../models/fiducial.dart';
import '../models/qr_zone.dart';
import '../models/section.dart';
import '../models/sheet_spec.dart';
import '../models/timing_track.dart';
import '../models/units.dart';
import '../schema/sheet_spec_schema.dart';

/// Parametric JEE/NEET-style sheet builders.
///
/// Every number below is the layout arithmetic, not a magic constant — the
/// comments show the sum. Both presets pass [validateSheetSpec]; if you edit
/// geometry, run the tests: the validator is the guard that turns a layout
/// typo into a loud error instead of a mis-printed sheet.

/// **Preset A — Standard-90** (MVP default).
///
/// Comfortable geometry: 3 columns x 30 questions, 5.0x3.5mm ovals.
///
/// ```
///   width : c1 21.5..49.3 | c2 55.3..83.1 | c3 89.1..116.9
///           roll 129.5..194.0                                (all mm)
///   height: MCQ  rows 40.25..269.95 (30 x 7.8 pitch)
///           roll digits 40.25..110.35 (10 x 7.4 pitch)
///           set  130.25..133.75 under the roll grid
/// ```
SheetSpec buildStandard90({
  String layoutId = 'std90',
  int layoutVersion = 1,
  String instructionText = 'Use a blue/black ball point pen. '
      'Fill the bubble completely. To change, fully erase the old mark.',
  String serialText = '',
}) {
  const bubble = BubbleStyle(wMm: 5.0, hMm: 3.5, strokeMm: 0.25, pitchMm: 7.6);

  // Question columns: first bubble centre x = 24 (left edge 21.5 clears the
  // timing-track zone which ends at 20.5). Column advance = option span
  // Column origins; a const list INDEX is not a constant expression in Dart,
  // so the x's are spelled out as literals. Keep them in sync:
  // col1 24.0, +33.8 gutter → col2 57.8, +33.8 → col3 91.6.
  const x1 = 24.0, x2 = 57.8, x3 = 91.6;
  const originY = 42.0; // row 1 centre; rows run to 42 + 29*7.8 = 268.2
  const rowPitch = 7.8;

  final mcq = <FieldBlock>[
    FieldBlock(
      blockId: 'mcq_c1',
      blockType: BlockType.mcq,
      originMm: const MmPoint(x1, originY),
      bubblePitchMm: 7.6,
      rowPitchMm: rowPitch,
      direction: BlockDirection.vertical,
      options: 4,
      fieldLabels: const ['q1..q30'],
    ),
    FieldBlock(
      blockId: 'mcq_c2',
      blockType: BlockType.mcq,
      originMm: const MmPoint(x2, originY),
      bubblePitchMm: 7.6,
      rowPitchMm: rowPitch,
      direction: BlockDirection.vertical,
      options: 4,
      fieldLabels: const ['q31..q60'],
    ),
    FieldBlock(
      blockId: 'mcq_c3',
      blockType: BlockType.mcq,
      originMm: const MmPoint(x3, originY),
      bubblePitchMm: 7.6,
      rowPitchMm: rowPitch,
      direction: BlockDirection.vertical,
      options: 4,
      fieldLabels: const ['q61..q90'],
    ),
  ];

  // Roll: 7 digits + checksum column; 0-9 stacked vertically. Vertical pitch
  // 7.4 >= 1.4 x 5.0 major axis; grid 7 x 8.5 wide = 64.5mm at x 129.5..194.
  final roll = FieldBlock(
    blockId: 'roll',
    blockType: BlockType.rollDigits,
    originMm: const MmPoint(132.0, originY),
    bubblePitchMm: 7.4,
    rowPitchMm: 8.5,
    direction: BlockDirection.horizontal,
    options: 10,
    fieldLabels: const ['roll1..roll8'],
  );

  // Set code under the roll grid, centred beneath it.
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

  return validateOrThrow(SheetSpec(
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
    fieldBlocks: [...mcq, roll, set],
    sections: const [
      SectionSpec(
          id: 'phy', name: 'Physics', subject: 'Physics',
          questionLabels: ['q1..q30']),
      SectionSpec(
          id: 'chem', name: 'Chemistry', subject: 'Chemistry',
          questionLabels: ['q31..q60']),
      SectionSpec(
          id: 'math', name: 'Mathematics', subject: 'Mathematics',
          questionLabels: ['q61..q90']),
    ],
    rollDigits: 7,
    rollChecksum: true,
    setValues: const ['A', 'B', 'C', 'D'],
    serialText: serialText,
    instructionText: instructionText,
  ));
}

/// **Preset B — NEET-180** (dense).
///
/// 4 columns x 45 questions at 4.0x3.0mm ovals / 5.7mm pitch — the vendors'
/// dense-but-valid zone (real NEET sheets sit exactly here). The smaller
/// bubble raises the capture-resolution floor, which the capture gate reads
/// from the compiled template (`minPxPerMmOnCapture`).
///
/// ```
///   width : c1 22..43.1 | c2 48.1..69.2 | c3 74.2..95.3 | c4 100.3..121.4
///           roll 130..183                                                (mm)
///   height: MCQ 30.0..283.8 (45 x 5.7 pitch), header shrunk to 28mm
/// ```
SheetSpec buildNeet180({
  String layoutId = 'neet180',
  int layoutVersion = 1,
  String instructionText = 'Use a blue/black ball point pen. '
      'Fill the bubble completely. To change, fully erase the old mark.',
  String serialText = '',
}) {
  const bubble = BubbleStyle(wMm: 4.0, hMm: 3.0, strokeMm: 0.25, pitchMm: 5.7);

  // Pitch 5.7 >= 1.4 x 4.0 = 5.6 major-axis floor. Column advance = option
  // span (3 x 5.7 + 4.0 = 21.1) + 5.0 gutter.
  const colX = [24.0, 50.1, 76.2, 102.3];
  // 45 rows x 5.7 = 250.8mm of pitch — needs the slimmer 28mm header.
  const originY = 31.5; // rows run to 31.5 + 44*5.7 = 282.3
  const rowPitch = 5.7;

  final mcq = <FieldBlock>[
    for (var c = 0; c < 4; c++)
      FieldBlock(
        blockId: 'mcq_c${c + 1}',
        blockType: BlockType.mcq,
        originMm: MmPoint(colX[c], originY),
        bubblePitchMm: 5.7,
        rowPitchMm: rowPitch,
        direction: BlockDirection.vertical,
        options: 4,
        fieldLabels: ['q${c * 45 + 1}..q${(c + 1) * 45}'],
      ),
  ];

  // Roll: 8 columns x 7.0 advance = 53mm wide at x 130..183; 0-9 stacked at
  // 5.7 vertical pitch (grid 54.3mm tall).
  final roll = FieldBlock(
    blockId: 'roll',
    blockType: BlockType.rollDigits,
    originMm: const MmPoint(132.0, 40.0),
    bubblePitchMm: 5.7,
    rowPitchMm: 7.0,
    direction: BlockDirection.horizontal,
    options: 10,
    fieldLabels: const ['roll1..roll8'],
  );

  final set = FieldBlock(
    blockId: 'set',
    blockType: BlockType.setCode,
    originMm: const MmPoint(147.0, 105.0),
    bubblePitchMm: 5.7,
    rowPitchMm: 5.7,
    direction: BlockDirection.vertical,
    options: 4,
    bubbleValues: const ['A', 'B', 'C', 'D'],
    fieldLabels: const ['set'],
  );

  return validateOrThrow(SheetSpec(
    specVersion: 1,
    layoutId: layoutId,
    layoutVersion: layoutVersion,
    paperSizeMm: (a4WidthMm, a4HeightMm),
    marginMm: 10,
    headerHeightMm: 28,
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
    fieldBlocks: [...mcq, roll, set],
    sections: const [
      SectionSpec(
          id: 'phy', name: 'Physics', subject: 'Physics',
          questionLabels: ['q1..q45']),
      SectionSpec(
          id: 'chem', name: 'Chemistry', subject: 'Chemistry',
          questionLabels: ['q46..q90']),
      SectionSpec(
          id: 'bot', name: 'Botany', subject: 'Biology',
          questionLabels: ['q91..q135']),
      SectionSpec(
          id: 'zoo', name: 'Zoology', subject: 'Biology',
          questionLabels: ['q136..q180']),
    ],
    rollDigits: 7,
    rollChecksum: true,
    setValues: const ['A', 'B', 'C', 'D'],
    serialText: serialText,
    instructionText: instructionText,
  ));
}
