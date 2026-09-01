import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:omr_core/omr_core.dart' as core;
import 'package:omr_data/omr_data.dart';
import 'package:omr_reports/omr_reports.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../src/app_state.dart';

/// Plan §6 screen 8's student detail: summary, per-question outcomes rebuilt
/// from the stored substrate, and the marksheet PDF (print or share).
class StudentResultScreen extends StatelessWidget {
  const StudentResultScreen({
    super.key,
    required this.examId,
    required this.keyVersionId,
    required this.row,
  });

  final String examId;
  final String keyVersionId;
  final ReportRow row;

  ResultsQuery _query(AppDb db) =>
      ResultsQuery(db, examId: examId, keyVersionId: keyVersionId);

  @override
  Widget build(BuildContext context) {
    final db = context.read<AppState>().db;
    return Scaffold(
      appBar: AppBar(title: Text(row.rollNo)),
      body: FutureBuilder<List<core.QuestionOutcome>>(
        future: _query(db).outcomesFor(row),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final outcomes = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _summaryCard(context),
              const SizedBox(height: 8),
              Text('Per question', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final outcome in outcomes) _outcomeChip(outcome),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _print(context, db),
                icon: const Icon(Icons.print),
                label: const Text('Print marksheet'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _share(context, db),
                icon: const Icon(Icons.share),
                label: const Text('Share marksheet PDF'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    row.name ?? 'Roll ${row.rollNo}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  row.rank == null ? '' : 'Rank ${row.rank}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat(formatMarks(row.total), 'total'),
                _stat('${row.correct}', 'correct'),
                _stat('${row.wrong}', 'wrong'),
                _stat('${row.unattempted}', 'skipped'),
              ],
            ),
            if (row.subjectTotals.isNotEmpty) ...[
              const Divider(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  for (final subject in row.subjectTotals.entries)
                    Text(
                      '${subject.key}: ${formatMarks(subject.value)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _outcomeChip(core.QuestionOutcome outcome) {
    final (color, glyph) = switch (outcome.kind) {
      core.QuestionOutcomeKind.correct => (Colors.green, '✓'),
      core.QuestionOutcomeKind.wrong => (Colors.red, '✗'),
      core.QuestionOutcomeKind.unattempted => (Colors.grey, '–'),
      core.QuestionOutcomeKind.partial => (Colors.teal, '±'),
      core.QuestionOutcomeKind.invalidated => (Colors.blueGrey, '×'),
      core.QuestionOutcomeKind.bonus => (Colors.purple, '+'),
    };
    return Container(
      width: 44,
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        '${outcome.questionId.replaceAll(RegExp(r'^q'), '')} $glyph',
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _print(BuildContext context, AppDb db) async {
    await Printing.layoutPdf(
      name: 'marksheet-${row.rollNo}',
      onLayout: (PdfPageFormat format) async => Uint8List.fromList(
        await MarksheetPdf(pageFormat: format).build(_query(db), row),
      ),
    );
  }

  Future<void> _share(BuildContext context, AppDb db) async {
    final messenger = ScaffoldMessenger.of(context);
    final bytes = await MarksheetPdf().build(_query(db), row);
    final docs = await getApplicationDocumentsDirectory();
    final file = File(
      p.joinAll([docs.path, 'reports', examId, 'marksheet-${row.rollNo}.pdf']),
    );
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'Marksheet ${row.rollNo}'),
    );
    messenger.showSnackBar(
      SnackBar(content: Text('Shared ${p.basename(file.path)}')),
    );
  }
}
