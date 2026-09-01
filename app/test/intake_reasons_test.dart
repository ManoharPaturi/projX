import 'package:flutter_test/flutter_test.dart';
import 'package:omr_app/features/capture/sheet_intake.dart';
import 'package:omr_core/omr_core.dart' as core;
import 'package:omr_data/omr_data.dart';
import 'package:omr_detect/omr_detect.dart' as detect;
import 'package:omr_spec/omr_spec.dart' show BlockType;

/// The read-flag → review-reason mapping is the intake's only POLICY: which
/// reads a human must confirm before marks publish. These tests pin it
/// directly — the e2e test covers one flag through the whole screen, this
/// file covers the table.
void main() {
  detect.StillEvaluation evaluation({
    core.SheetRead? read,
    detect.RejectionReason? rejection,
    List<detect.FieldRead> fields = const [],
  }) =>
      detect.StillEvaluation(
        read: read ??
            core.SheetRead(responses: const {}, sheetConfidence: 0.9),
        fields: fields,
        registrationPath: detect.RegistrationPath.fiducialQuadrant,
        trace: const [],
        rejection: rejection,
      );

  test('a clean read routes nowhere', () {
    expect(
      reviewReasonsFor(evaluation(read: core.SheetRead(
        responses: const {},
        sheetConfidence: 0.95,
        rollNoRead: '0000073',
        setCodeRead: 'B',
      ))),
      isEmpty,
    );
  });

  test('rejection is mandatory review', () {
    final reasons = reviewReasonsFor(
      evaluation(rejection: detect.RejectionReason.noRegistration),
    );
    expect(reasons, hasLength(1));
    expect(reasons.single.code, 'NO_MARKER_ERR');
    expect(reasons.single.severity, ReviewSeverity.mandatory);
  });

  test('read flags map to their severities', () {
    final reasons = reviewReasonsFor(evaluation(read: core.SheetRead(
      responses: const {},
      sheetConfidence: 0.9,
      rollNoRead: '0000074',
      flags: const {
        core.SheetReadFlag.rollChecksumMismatch,
        core.SheetReadFlag.setCodeBlank,
        core.SheetReadFlag.curlDetected,
        core.SheetReadFlag.lowConfidence,
      },
    )));

    expect({
      for (final r in reasons) r.code: r.severity,
    }, {
      'ROLL_CHECKSUM_ERR': ReviewSeverity.high,
      'SET_BLANK': ReviewSeverity.medium,
      'CURL_WARN': ReviewSeverity.medium,
      'LOW_CONFIDENCE': ReviewSeverity.medium,
    });
  });

  test('a multi-marked field names the field in the review row', () {
    final reasons = reviewReasonsFor(evaluation(
      read: core.SheetRead(
        responses: const {},
        sheetConfidence: 0.9,
        flags: const {core.SheetReadFlag.multiMarkedField},
      ),
      fields: [
        detect.FieldRead(
          fieldKey: 'q17',
          blockId: 'mcq_col2',
          blockType: BlockType.mcq,
          bubbles: const [],
          markClass: detect.MarkClass.multiple,
        ),
      ],
    ));

    expect(reasons, hasLength(1));
    expect(reasons.single.code, 'MULTI_BUBBLE_WARN');
    expect(reasons.single.fieldRefs, ['q17']);
  });
}
