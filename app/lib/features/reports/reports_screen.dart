import 'package:flutter/material.dart';
import 'package:omr_data/omr_data.dart';
import 'package:omr_reports/omr_reports.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../src/app_state.dart';
import '../../src/data_version.dart';
import '../../src/labels.dart';
import '../../src/db/open_db.dart' show reportsDirectory;
import '../../src/report_fonts_loader.dart';
import '../../src/report_render.dart';

/// Plan §6 screen 10 + §7 — every output goes through [ReportRunner] so a
/// `report_jobs` row records what was generated, from which key version, and
/// where it landed.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.examId});

  final String examId;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<AnswerKeyVersion>? _versions;
  String? _keyVersionId;
  String _examName = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = context.read<AppState>().db;
    final versions = await db.keysDao.versionsFor(widget.examId);
    final exam = await db.examsDao.byId(widget.examId);
    if (!mounted) {
      return;
    }
    setState(() {
      _versions = versions;
      _examName = exam?.name ?? '';
      _keyVersionId ??= versions.isNotEmpty ? versions.first.id : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dataVersion = context.watchDataVersion();
    if (_versions == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_versions!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Enter the answer key (Answer key tab) before making reports.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Use answer key'),
          items: [
            for (final version in _versions!)
              DropdownMenuItem(
                value: version.id,
                child: Text(keyVersionLabel(version.version, version.status)),
              ),
          ],
          initialValue: _keyVersionId,
          onChanged: (id) => setState(() => _keyVersionId = id),
        ),
        const SizedBox(height: 16),
        _ReportCard(
          icon: Icons.picture_as_pdf,
          title: 'Class result list (PDF)',
          subtitle:
              'Every student with marks and rank — ready to print or send '
              'on WhatsApp',
          onGenerate: () => _generate(
            type: ReportJobType.consolidated,
            format: 'pdf',
            builder: (query) async => renderClassPdf(
              await query.snapshot(),
              await loadReportFontBytes(),
            ),
          ),
        ),
        _ReportCard(
          icon: Icons.grid_on,
          title: 'Excel workbook',
          subtitle:
              'Marks, ranks and percentiles, plus every student\'s answer '
              'to every question',
          onGenerate: () => _generate(
            type: ReportJobType.excel,
            format: 'xlsx',
            builder: (query) async =>
                renderWorkbook(await query.snapshot(withOutcomes: true)),
          ),
        ),
        _ReportCard(
          icon: Icons.table_chart,
          title: 'Spreadsheet (CSV)',
          subtitle:
              'Opens in any spreadsheet app; Hindi and other '
              'Indian-language names are kept',
          onGenerate: () => _generate(
            type: ReportJobType.csv,
            format: 'csv',
            builder: (query) async => renderCsv(await query.snapshot()),
          ),
        ),
        const SizedBox(height: 8),
        const SizedBox(height: 8),
        Text(
          'Each report opens the share screen when ready. Single-student '
          'marksheets are on the Results tab — tap a student.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Text('Made earlier', style: Theme.of(context).textTheme.titleMedium),
        _JobsList(
          examId: widget.examId,
          refreshKey: dataVersion,
          onShare: _share,
        ),
      ],
    );
  }

  Future<void> _generate({
    required ReportJobType type,
    required String format,
    required Future<List<int>> Function(ResultsQuery query) builder,
  }) async {
    final state = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final runner = ReportRunner(state.db);
    final query = ResultsQuery(
      state.db,
      examId: widget.examId,
      keyVersionId: _keyVersionId!,
    );
    final version = _versions!.firstWhere((v) => v.id == _keyVersionId!);
    final fileName = reportFileName(
      examName: _examName,
      type: type,
      keyVersion: version.version,
      format: format,
    );
    try {
      final path = await runner.run(
        tenantId: state.tenantId,
        examId: widget.examId,
        type: type,
        format: format,
        directory: await reportsDirectory(widget.examId),
        fileName: fileName,
        params: <String, Object?>{
          'keyVersionId': _keyVersionId,
          'keyVersionNumber': version.version,
        },
        build: () => builder(query),
      );
      state.refresh();
      await _share(path);
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not make the report: $error')),
      );
    }
  }

  Future<void> _share(String path) async {
    await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
  }
}

/// The name the recipient sees on WhatsApp or email, e.g.
/// `Mock 1 - Class results (key 1).pdf`. Characters that file systems or
/// share targets reject are dropped.
String reportFileName({
  required String examName,
  required ReportJobType type,
  required int keyVersion,
  required String format,
}) {
  final what = switch (type) {
    ReportJobType.consolidated => 'Class results',
    ReportJobType.excel => 'Marks workbook',
    ReportJobType.csv => 'Marks',
    _ => reportTypeLabel(type),
  };
  final exam = examName
      .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final base = exam.isEmpty ? what : '$exam - $what';
  return '$base (key $keyVersion).$format';
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onGenerate,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Future<void> Function() onGenerate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: FilledButton.tonal(
          onPressed: onGenerate,
          child: const Text('Make'),
        ),
      ),
    );
  }
}

class _JobsList extends StatelessWidget {
  const _JobsList({
    required this.examId,
    required this.refreshKey,
    required this.onShare,
  });

  final String examId;
  final int refreshKey;
  final Future<void> Function(String path) onShare;

  @override
  Widget build(BuildContext context) {
    final db = context.read<AppState>().db;
    return FutureBuilder<List<ReportJob>>(
      key: ValueKey('jobs-$examId-$refreshKey'),
      future: db.reportJobsDao.recentFor(examId),
      builder: (context, snapshot) {
        final jobs = snapshot.data ?? const <ReportJob>[];
        if (jobs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: Text('No reports made yet.'),
          );
        }
        return Card(
          child: Column(
            children: [
              for (final job in jobs)
                ListTile(
                  dense: true,
                  leading: Icon(
                    job.status == ReportJobStatus.done
                        ? Icons.check_circle_outline
                        : job.status == ReportJobStatus.failed
                        ? Icons.error_outline
                        : Icons.hourglass_empty,
                    // 800/900 shades: the status icon must hold 3:1 on a
                    // light card (500 green/orange did not).
                    color: job.status == ReportJobStatus.done
                        ? const Color(0xFF1B5E20)
                        : job.status == ReportJobStatus.failed
                        ? const Color(0xFFB3261E)
                        : const Color(0xFF8B4000),
                  ),
                  title: Text(reportTypeLabel(job.type)),
                  subtitle: Text(
                    job.status == ReportJobStatus.failed
                        ? 'Failed: ${job.errorText ?? 'unknown error'}'
                        : job.generatedAt == null
                        ? 'Making…'
                        : formatDateTime(job.generatedAt!),
                  ),
                  trailing: job.filePath == null
                      ? null
                      : IconButton(
                          tooltip: 'Share',
                          icon: const Icon(Icons.share),
                          onPressed: () => onShare(job.filePath!),
                        ),
                ),
            ],
          ),
        );
      },
    );
  }
}
