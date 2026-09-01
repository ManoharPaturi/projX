import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:omr_data/omr_data.dart';
import 'package:omr_reports/omr_reports.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../src/app_state.dart';
import '../../src/db/open_db.dart' show reportsDirectory;

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = context.read<AppState>().db;
    final versions = await db.keysDao.versionsFor(widget.examId);
    if (!mounted) {
      return;
    }
    setState(() {
      _versions = versions;
      _keyVersionId ??= versions.isNotEmpty ? versions.first.id : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (_versions == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_versions!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Publish an answer key before generating reports.'),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Key version'),
          items: [
            for (final version in _versions!)
              DropdownMenuItem(
                value: version.id,
                child: Text(
                  'v${version.version} (${version.status.name})',
                ),
              ),
          ],
          initialValue: _keyVersionId,
          onChanged: (id) => setState(() => _keyVersionId = id),
        ),
        const SizedBox(height: 16),
        _ReportCard(
          icon: Icons.picture_as_pdf,
          title: 'Consolidated class PDF',
          subtitle: 'Every student, ranks, repeating header — paginates to 500 '
              'pages for large cohorts',
          onGenerate: () => _generate(
            type: ReportJobType.consolidated,
            format: 'pdf',
            builder: (query) => ConsolidatedPdf().build(query),
          ),
        ),
        _ReportCard(
          icon: Icons.grid_on,
          title: 'Excel workbook',
          subtitle: 'Summary with live percentile formulas + per-question '
              'matrix sheet',
          onGenerate: () => _generate(
            type: ReportJobType.excel,
            format: 'xlsx',
            builder: (query) => ExcelExporter().build(query),
          ),
        ),
        _ReportCard(
          icon: Icons.table_chart,
          title: 'CSV',
          subtitle: 'UTF-8 BOM so Indian-language names survive Excel',
          onGenerate: () => _generate(
            type: ReportJobType.csv,
            format: 'csv',
            builder: (query) async {
              final header = await query.header();
              final rows = await query.rows();
              // utf8, not codeUnits: Devanagari names must survive the file.
              return utf8.encode(CsvExporter().convert(header, rows));
            },
          ),
        ),
        const SizedBox(height: 8),
        Text('Recent', style: Theme.of(context).textTheme.titleMedium),
        _JobsList(
          examId: widget.examId,
          refreshKey: state.version,
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
    final fileName =
        '${type.name}-v${version.version}.${format == 'xlsx' ? 'xlsx' : format}';
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
        SnackBar(content: Text('Generation failed: $error')),
      );
    }
  }

  Future<void> _share(String path) async {
    await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
  }
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
          child: const Text('Generate'),
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
            child: Text('Nothing generated yet.'),
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
                    color: job.status == ReportJobStatus.done
                        ? Colors.green
                        : job.status == ReportJobStatus.failed
                        ? Colors.red
                        : Colors.orange,
                  ),
                  title: Text('${job.type.name}.${job.format}'),
                  subtitle: Text(
                    job.status == ReportJobStatus.failed
                        ? (job.errorText ?? 'failed')
                        : (job.generatedAt?.toLocal().toString() ?? 'running'),
                  ),
                  trailing: job.filePath == null
                      ? null
                      : IconButton(
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
