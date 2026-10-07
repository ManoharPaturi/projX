import 'package:flutter/material.dart';
import 'package:omr_data/omr_data.dart';
import 'package:omr_spec/omr_spec.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../src/app_state.dart';

/// Opens the system print dialog with the exam's blank answer sheet.
///
/// The PDF comes from the SAME hash-verified spec the scanner reads against
/// (plan §2's single-source-of-truth rule), with the exam name in the
/// header. Copies, printer and paper are chosen in the system dialog.
Future<void> printAnswerSheets(BuildContext context, Exam exam) async {
  final db = context.read<AppState>().db;
  final messenger = ScaffoldMessenger.of(context);
  final go = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Before you print'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• Use A4 paper.'),
          SizedBox(height: 6),
          Text('• Choose "Actual size" or 100% — not "Fit to page".'),
          SizedBox(height: 6),
          Text('• Colour printing reads best.'),
          SizedBox(height: 6),
          Text(
            '• New printer or photocopier? Run the Printer check from the '
            'menu once.',
          ),
          SizedBox(height: 6),
          Text('• Set the number of copies in the print screen.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Continue'),
        ),
      ],
    ),
  );
  if (go != true) return;
  try {
    final spec = await GradingService(db).printableSpecFor(exam.id);
    final bytes = await compileSheetPdf(spec, examTitle: exam.name);
    await Printing.layoutPdf(
      name: 'answer-sheet-${exam.name}',
      // The sheet is drawn at its true paper size; whatever format the
      // dialog proposes, the bytes stay as compiled (no re-layout).
      onLayout: (_) async => bytes,
    );
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text('Could not prepare the sheet: $error')),
    );
  }
}
