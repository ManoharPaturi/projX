import 'package:flutter/material.dart';
import 'package:omr_data/omr_data.dart';
import 'package:omr_reports/omr_reports.dart';
import 'package:provider/provider.dart';

import '../../src/app_state.dart';
import 'student_result_screen.dart';

/// Plan §6 screen 8 — the ranked result list for one exam, fed by the ONE
/// canonical [ResultsQuery] every renderer consumes.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.examId});

  final String examId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return FutureBuilder<AnswerKeyVersion?>(
      key: ValueKey('keyversion-$examId-${state.version}'),
      future: state.db.keysDao.activeVersion(examId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final keyVersion = snapshot.data;
        if (keyVersion == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Publish an answer key to see results.'),
            ),
          );
        }
        return _Body(
          examId: examId,
          keyVersionId: keyVersion.id,
          refreshKey: state.version,
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.examId,
    required this.keyVersionId,
    required this.refreshKey,
  });

  final String examId;
  final String keyVersionId;
  final int refreshKey;

  @override
  Widget build(BuildContext context) {
    final db = context.read<AppState>().db;
    final query = ResultsQuery(db, examId: examId, keyVersionId: keyVersionId);
    return FutureBuilder<(ExamHeader, List<ReportRow>)>(
      key: ValueKey('results-$examId-$keyVersionId-$refreshKey'),
      future: () async {
        final header = await query.header();
        final rows = await query.rows();
        return (header, rows);
      }(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final (header, rows) = snapshot.data!;
        if (rows.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No graded sheets yet. Scan sheets (or insert fixtures), '
                'then press Grade now.',
              ),
            ),
          );
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '${header.studentCount} students · top ${formatMarks(header.maxTotal)}'
                ' · key v${header.keyVersionNumber}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  return ListTile(
                    dense: true,
                    leading: SizedBox(
                      width: 36,
                      child: Center(
                        child: row.rank == null
                            ? const Text('—')
                            : Text(
                                '${row.rank}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    title: Text(
                      '${row.rollNo}${row.name == null ? '' : ' · ${row.name}'}',
                    ),
                    subtitle: Text(
                      'C ${row.correct} · W ${row.wrong} · U ${row.unattempted}',
                    ),
                    trailing: Text(
                      formatMarks(row.total),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => StudentResultScreen(
                          examId: examId,
                          keyVersionId: keyVersionId,
                          row: row,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
