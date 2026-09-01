import '../compile/layout_geometry.dart';
import '../models/bubble_style.dart';
import '../models/field_block.dart';
import '../models/sheet_spec.dart';

/// Thrown when a spec violates the layout physics. Every message carries the
/// actual mm numbers so the author can fix the geometry without a debugger.
class SpecValidationException implements Exception {
  SpecValidationException(this.errors) : assert(errors.isNotEmpty);

  final List<String> errors;

  @override
  String toString() => errors.length == 1
      ? 'Invalid sheet spec: ${errors.first}'
      : 'Invalid sheet spec (${errors.length} errors):\n'
          '${errors.map((e) => '  - $e').join('\n')}';
}

/// Tunable layout physics, from the OMR literature + OMRChecker practice.
class SpecLimits {
  const SpecLimits({
    this.minMarginMm = 10.0,
    this.minBubbleMm = 3.0,
    this.maxBubbleMm = 6.0,
    this.minStrokeMm = 0.15,
    this.maxStrokeMm = 0.35,
    this.minPitchRatio = 1.4,
    this.minFiducialMm = 6.0,
    this.maxFiducialMm = 12.0,
    this.minFiducialEdgeMm = 5.0,
    this.minWhiteSurroundMm = 3.0,
    this.minQrMm = 15.0,
    this.minOptions = 2,
    this.maxOptions = 10,
    this.minBubbleEdgeGapMm = 1.5,
  });

  final double minMarginMm;
  final double minBubbleMm;
  final double maxBubbleMm;
  final double minStrokeMm;
  final double maxStrokeMm;

  /// Centre-to-centre pitch must be at least this multiple of the bubble's
  /// MAJOR axis, or filled marks bleed into neighbouring ROIs.
  final double minPitchRatio;

  final double minFiducialMm;
  final double maxFiducialMm;

  /// Closest a fiducial body may come to the paper edge (printability).
  final double minFiducialEdgeMm;
  final double minWhiteSurroundMm;
  final double minQrMm;
  final int minOptions;
  final int maxOptions;

  /// Closest a bubble outline may come to the content-rect border.
  final double minBubbleEdgeGapMm;
}

const defaultSpecLimits = SpecLimits();

/// Validates a [SheetSpec] against the layout physics. Throws
/// [SpecValidationException] listing EVERY violation (not just the first).
///
/// This runs at author time, at compile time, and at load time in the app —
/// the check that rejects a block overflowing the content rect is what makes
/// the additive-geometry format typo-resistant (a wrong pitch or origin
/// produces a loud error, never a silently mis-printed sheet).
void validateSheetSpec(SheetSpec spec, {SpecLimits limits = defaultSpecLimits}) {
  final errors = <String>[];

  // ---- paper / margins -------------------------------------------------
  if (spec.marginMm < limits.minMarginMm) {
    errors.add('marginMm ${spec.marginMm} < ${limits.minMarginMm} '
        '(printable-area safety)');
  }
  final content = spec.contentRect;
  if (content.w <= 0 || content.h <= 0) {
    errors.add('content rect is empty: $content — headerHeightMm '
        '${spec.headerHeightMm} leaves no room on '
        '${spec.paperHeightMm}mm-tall paper');
    // Nothing further is checkable on the content plane.
    _throwIfAny(errors);
    return;
  }
  if (spec.headerHeightMm < spec.marginMm) {
    errors.add('headerHeightMm ${spec.headerHeightMm} < marginMm '
        '${spec.marginMm} — the header band starts above the margin');
  }

  // ---- bubble style ----------------------------------------------------
  final bs = spec.bubbleStyle;
  _validateBubbleStyle(bs, limits, errors);

  // ---- fiducials -------------------------------------------------------
  final fid = spec.fiducials;
  if (fid.sizeMm < limits.minFiducialMm || fid.sizeMm > limits.maxFiducialMm) {
    errors.add('fiducials.sizeMm ${fid.sizeMm} outside '
        '[${limits.minFiducialMm}, ${limits.maxFiducialMm}] — too small to '
        'template-match reliably, too large wastes corner space');
  }
  if (fid.whiteSurroundMm < limits.minWhiteSurroundMm) {
    errors.add('fiducials.whiteSurroundMm ${fid.whiteSurroundMm} < '
        '${limits.minWhiteSurroundMm}');
  }
  if (fid.sizeMm <= spec.bubbleStyle.majorAxisMm * 1.5) {
    errors.add('fiducial ${fid.sizeMm}mm should be ~2.5-3x the bubble major '
        'axis ${spec.bubbleStyle.majorAxisMm}mm for unambiguous matching '
        '(got ${fid.sizeMm / spec.bubbleStyle.majorAxisMm}x)');
  }
  final corners = {'tl', 'tr', 'bl', 'br'};
  if (fid.squareCorners.toSet().intersection(corners).length !=
      fid.squareCorners.length) {
    errors.add('fiducials.squareCorners ${fid.squareCorners} contains an '
        'unknown corner (tl|tr|bl|br)');
  }
  if (corners.difference(fid.squareCorners.toSet()).length != 1 ||
      !corners.contains(fid.altAnchorCorner) ||
      fid.squareCorners.contains(fid.altAnchorCorner)) {
    errors.add('fiducials: exactly one corner must carry the L anchor and it '
        'must not also be a square corner (squares=${fid.squareCorners}, '
        'alt=${fid.altAnchorCorner})');
  }

  // ---- QR zone ---------------------------------------------------------
  if (spec.qrZone.sizeMm < limits.minQrMm) {
    errors.add('qrZone.sizeMm ${spec.qrZone.sizeMm} < ${limits.minQrMm} '
        '(phone cameras need the modules large)');
  }

  final geo = LayoutGeometry.of(spec);

  for (final entry in geo.fiducialCenters.entries) {
    final body = geo.fiducialRect(entry.key);
    if (body.left < limits.minFiducialEdgeMm ||
        body.top < limits.minFiducialEdgeMm ||
        spec.paperWidthMm - body.right < limits.minFiducialEdgeMm ||
        spec.paperHeightMm - body.bottom < limits.minFiducialEdgeMm) {
      errors.add('fiducial "${entry.key}" comes within '
          '${limits.minFiducialEdgeMm}mm of the paper edge — most printers '
          'cannot keep it solid ($body)');
    }
  }

  final qr = geo.qrRect;
  if (qr.x < spec.marginMm - 0.01) {
    errors.add('qr zone does not fit: requested ${spec.qrZone.sizeMm}mm at '
        'the top-right but the TR fiducial surround pushed it left of the '
        'margin ($qr) — reduce qrZone.sizeMm or inset the fiducials');
  }
  for (final entry in geo.fiducialCenters.entries) {
    if (geo.fiducialZone(entry.key).intersects(qr)) {
      errors.add('qr zone $qr overlaps the white surround of fiducial '
          '"${entry.key}"');
    }
  }

  // ---- field blocks ----------------------------------------------------
  if (spec.fieldBlocks.isEmpty) {
    errors.add('fieldBlocks is empty — a sheet needs at least one block');
  }

  final seenFields = <String, String>{};
  FieldBlock? firstMcq;

  for (final block in spec.fieldBlocks) {
    final prefix = 'block "${block.blockId}"';

    if (block.bubblePitchMm <= 0 || block.rowPitchMm <= 0) {
      errors.add('$prefix: pitches must be positive '
          '(bubble ${block.bubblePitchMm}, row ${block.rowPitchMm})');
      continue;
    }
    if (block.options < limits.minOptions || block.options > limits.maxOptions) {
      errors.add('$prefix: options ${block.options} outside '
          '[${limits.minOptions}, ${limits.maxOptions}]');
    }
    if (block.bubbleValues != null &&
        block.bubbleValues!.length != block.options) {
      errors.add('$prefix: ${block.bubbleValues!.length} bubbleValues for '
          '${block.options} options');
    }

    List<String> fields;
    try {
      fields = block.fields;
    } on FormatException catch (e) {
      errors.add('$prefix: bad fieldLabels — ${e.message}');
      continue;
    }
    if (fields.isEmpty) {
      errors.add('$prefix: expands to zero fields (${block.fieldLabels})');
      continue;
    }

    // Global field-key uniqueness — these keys ARE the database join keys.
    for (final f in fields) {
      final owner = seenFields[f];
      if (owner != null) {
        errors.add('field key "$f" appears in both "$owner" and '
            '"${block.blockId}" — field keys must be globally unique');
      } else {
        seenFields[f] = block.blockId;
      }
    }

    // Pitch vs bubble size (major axis on EACH axis).
    final major = bs.majorAxisMm;
    final pitchAlongOptions = block.bubblePitchMm;
    final pitchAlongFields = block.rowPitchMm;
    if (pitchAlongOptions < limits.minPitchRatio * major) {
      errors.add('$prefix: bubblePitchMm $pitchAlongOptions < '
          '${limits.minPitchRatio} x $major (major axis) — filled marks will '
          'bleed between neighbouring options');
    }
    if (pitchAlongFields < limits.minPitchRatio * major) {
      errors.add('$prefix: rowPitchMm $pitchAlongFields < '
          '${limits.minPitchRatio} x $major (major axis) — rows are too tight '
          'to separate');
    }

    // Extent inside the content rect, with a bubble-to-edge gap.
    final extent =
        block.extentMm(bubbleW: bs.wMm, bubbleH: bs.hMm);
    final inner = content.inflate(-limits.minBubbleEdgeGapMm);
    if (extent.left < inner.left ||
        extent.right > inner.right ||
        extent.top < inner.top ||
        extent.bottom > inner.bottom) {
      errors.add('$prefix: extent $extent overflows the content rect '
          '$content (gap >= ${limits.minBubbleEdgeGapMm} required) — reduce '
          'rows, tighten pitch, or shrink the bubble');
    }

    // Fiducial zones must stay clear of every block.
    for (final entry in geo.fiducialCenters.entries) {
      if (geo.fiducialZone(entry.key).intersects(extent)) {
        errors.add('$prefix: extent $extent enters the white surround of '
            'fiducial "${entry.key}"');
      }
    }
    if (geo.qrRect.intersects(extent)) {
      errors.add('$prefix: extent $extent overlaps the QR zone ${geo.qrRect}');
    }

    if (block.blockType == BlockType.mcq) {
      firstMcq ??= block;
    }
  }

  // ---- timing track / shared row grid ----------------------------------
  final mcqBlocks = spec.fieldBlocks
      .where((b) => b.blockType == BlockType.mcq)
      .toList();
  if (mcqBlocks.isNotEmpty) {
    final t = spec.timingTrack;
    if (t.barHMm >= mcqBlocks.first.rowPitchMm) {
      errors.add('timingTrack.barHMm ${t.barHMm} must be smaller than the MCQ '
          'row pitch ${mcqBlocks.first.rowPitchMm} or bars merge');
    }
    if (t.barWMm <= 0 || t.barHMm <= 0) {
      errors.add('timingTrack bar dimensions must be positive');
    }
    if (mcqBlocks.length > 1) {
      final ref = firstMcq!;
      for (final b in mcqBlocks.skip(1)) {
        if ((b.rowPitchMm - ref.rowPitchMm).abs() > 0.01) {
          errors.add('MCQ block "${b.blockId}" rowPitchMm ${b.rowPitchMm} '
              'differs from "${ref.blockId}" ${ref.rowPitchMm} — the timing '
              'track is derived from ONE shared row grid');
        }
        if ((b.originMm.y - ref.originMm.y).abs() > 0.01) {
          errors.add('MCQ block "${b.blockId}" origin y ${b.originMm.y} '
              'differs from "${ref.blockId}" ${ref.originMm.y} — rows must '
              'share the grid so one timing bar covers every column');
        }
      }
    }
    final trackZone = geo.timingTrackZone;
    if (trackZone != null) {
      for (final b in spec.fieldBlocks) {
        final extent =
            b.extentMm(bubbleW: spec.bubbleStyle.wMm, bubbleH: spec.bubbleStyle.hMm);
        if (extent.intersects(trackZone)) {
          errors.add('block "${b.blockId}" extent $extent violates the timing '
              'track clearance (zone $trackZone)');
        }
      }
    }
  } else {
    errors.add('no MCQ block found — the timing track needs a row grid');
  }

  // ---- roll / set consistency -------------------------------------------
  final roll = spec.rollBlock;
  if (roll == null) {
    errors.add('no rollDigits block — every sheet needs a roll-number field');
  } else {
    final expected =
        spec.rollDigits + (spec.rollChecksum ? 1 : 0);
    if (roll.fields.length != expected) {
      errors.add('roll block has ${roll.fields.length} columns; rollDigits '
          '${spec.rollDigits} + checksum ${spec.rollChecksum ? 1 : 0} = '
          '$expected expected');
    }
    if (roll.direction != BlockDirection.horizontal) {
      errors.add('roll block must be horizontal (digit columns advancing '
          'right, 0-9 stacked vertically)');
    }
    if (roll.options != 10) {
      errors.add('roll block must offer digits 0-9 (options=${roll.options})');
    }
    if (roll.originMm.y < content.top) {
      errors.add('roll block origin y ${roll.originMm.y} above content top '
          '${content.top}');
    }
  }

  final setBlock = spec.setBlock;
  if (setBlock == null) {
    errors.add('no setCode block — sheet-to-set binding is required');
  } else {
    if (setBlock.fields.length != 1) {
      errors.add('set block must have exactly one field '
          '(${setBlock.fields.length} given)');
    }
    if (setBlock.bubbleValues == null ||
        !_listsEqual(setBlock.bubbleValues!, spec.setValues)) {
      errors.add('set block bubbleValues ${setBlock.bubbleValues} != '
          'setValues ${spec.setValues}');
    }
  }

  // ---- sections cover exactly the MCQ questions --------------------------
  final mcqFields = <String>{
    for (final b in mcqBlocks) ...b.fields,
  };
  final sectionFields = <String>{};
  for (final s in spec.sections) {
    List<String> labels;
    try {
      labels = expandLabels(s.questionLabels);
    } on FormatException catch (e) {
      errors.add('section "${s.id}": bad questionLabels — ${e.message}');
      continue;
    }
    for (final q in labels) {
      if (sectionFields.contains(q)) {
        errors.add('question "$q" appears in more than one section');
      }
      sectionFields.add(q);
    }
    if (s.maxCounted != null && s.maxCounted! > labels.length) {
      errors.add('section "${s.id}": maxCounted ${s.maxCounted} > '
          '${labels.length} questions');
    }
  }
  final missing = mcqFields.difference(sectionFields).toList()..sort();
  final extra = sectionFields.difference(mcqFields).toList()..sort();
  if (missing.isNotEmpty) {
    errors.add('questions not covered by any section: '
        '${_summarize(missing)}');
  }
  if (extra.isNotEmpty) {
    errors.add('sections reference non-existent questions: '
        '${_summarize(extra)}');
  }

  _throwIfAny(errors);
}

void _validateBubbleStyle(BubbleStyle bs, SpecLimits limits,
    List<String> errors) {
  if (bs.wMm < limits.minBubbleMm || bs.wMm > limits.maxBubbleMm) {
    errors.add('bubbleStyle.wMm ${bs.wMm} outside '
        '[${limits.minBubbleMm}, ${limits.maxBubbleMm}] — below 3mm phone '
        'photos cannot segment, above 6mm sheets get sparse');
  }
  if (bs.hMm < limits.minBubbleMm || bs.hMm > limits.maxBubbleMm) {
    errors.add('bubbleStyle.hMm ${bs.hMm} outside '
        '[${limits.minBubbleMm}, ${limits.maxBubbleMm}]');
  }
  if (bs.hMm > bs.wMm) {
    errors.add('bubbleStyle.hMm ${bs.hMm} > wMm ${bs.wMm} — the oval major '
        'axis must be horizontal for the vertical-strip reader');
  }
  if (bs.strokeMm < limits.minStrokeMm || bs.strokeMm > limits.maxStrokeMm) {
    errors.add('bubbleStyle.strokeMm ${bs.strokeMm} outside '
        '[${limits.minStrokeMm}, ${limits.maxStrokeMm}] — thin enough to '
        'drop out, thick enough to photocopy');
  }
}

bool _listsEqual(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

String _summarize(List<String> labels) {
  if (labels.length <= 8) return labels.join(', ');
  return '${labels.take(8).join(', ')} … (+${labels.length - 8} more)';
}

void _throwIfAny(List<String> errors) {
  if (errors.isNotEmpty) throw SpecValidationException(errors);
}

/// Convenience: validate-and-return for builder chains.
SheetSpec validateOrThrow(SheetSpec spec, {SpecLimits limits = defaultSpecLimits}) {
  validateSheetSpec(spec, limits: limits);
  return spec;
}
