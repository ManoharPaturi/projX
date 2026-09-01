library;

import 'ids.dart';
import 'marked_response.dart';

/// Why a sheet was routed to (or deserves) human review.
///
/// Grading consumes these only to mark a result `doubtful`; they never change
/// marks. Enum rather than free text so the review queue can sort and count by
/// reason reliably.
enum SheetReadFlag {
  rollChecksumMismatch,
  rollNotOnRoster,
  rollColumnAmbiguous,
  setCodeBlank,
  setCodeMulti,
  curlDetected,
  probableBubblesPresent,
  lowConfidence,

  /// A field carried two clear marks, or one saturating (overfilled) mark —
  /// the intent may be obvious but the ROI reading is not trustworthy, so a
  /// human confirms before the mark counts.
  multiMarkedField,
}

/// Everything detection produces for one physical sheet — a dumb data bag.
///
/// The detection package constructs these; the grading engine only reads them.
/// Human-review overlays are already merged into [responses] (with
/// `humanCorrected` set) by the time a [SheetRead] reaches grading, so the same
/// read re-grades deterministically without touching pixels again.
final class SheetRead {
  /// Creates a sheet read.
  const SheetRead({
    required this.responses,
    required this.sheetConfidence,
    this.rollNoRead,
    this.rollConfidence = 1,
    this.setCodeRead,
    this.flags = const <SheetReadFlag>{},
  });

  /// Per-question reads keyed by canonical question id.
  final Map<QuestionId, MarkedResponse> responses;

  /// Roll number as decoded from the roll-digit bubbles, `null` if unreadable.
  final String? rollNoRead;

  /// Confidence of the weakest roll digit, 0..1.
  final double rollConfidence;

  /// Answer-set code bubbled on the sheet (`'A'`..`'D'`), `null` if unreadable.
  final String? setCodeRead;

  /// Overall sheet confidence, 0..1 — the minimum of the registration and
  /// field confidences, capped as described in the detection plan.
  final double sheetConfidence;

  /// Review-routing flags raised while reading this sheet.
  final Set<SheetReadFlag> flags;

  /// The read for [questionId], or an unattempted placeholder when the sheet
  /// spec has the question but nothing was read (missing rows must not crash
  /// grading — an absent field is simply an unattempted field).
  MarkedResponse responseFor(QuestionId questionId) =>
      responses[questionId] ?? unattemptedResponse;

  /// Shared unattempted placeholder used for questions absent from a read.
  static const MarkedResponse unattemptedResponse = MarkedResponse(
    chosen: <OptionId>{},
  );
}
