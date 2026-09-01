import 'package:flutter/material.dart';
import 'package:omr_data/omr_data.dart';
import 'package:omr_reports/omr_reports.dart';
import 'package:provider/provider.dart';

import '../../src/app_state.dart';
import '../keys/key_editor_screen.dart';
import '../reports/reports_screen.dart';
import '../results/results_screen.dart';

/// The exam hub: overview / answer key / results / reports (plan §6 screens
/// 3, 8 and 10 hang off here so navigation stays one level deep).
class ExamDetailScreen extends StatefulWidget {
  const ExamDetailScreen({super.key, required this.examId});

  final String examId;

  @override
  State<ExamDetailScreen> createState() => _ExamDetailScreenState();
}

class _ExamDetailScreenState extends State<ExamDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return FutureBuilder<Exam?>(
      key: ValueKey('exam-${widget.examId}-${state.version}'),
      future: state.db.examsDao.byId(widget.examId),
      builder: (context, snapshot) {
        final exam = snapshot.data;
        if (exam == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(exam.name),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Answer key'),
                Tab(text: 'Results'),
                Tab(text: 'Reports'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(exam: exam),
              KeyEditorScreen(examId: widget.examId, embedded: true),
              ResultsScreen(examId: widget.examId),
              ReportsScreen(examId: widget.examId),
            ],
          ),
        );
      },
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.exam});

  final Exam exam;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatusChip(status: exam.status),
                    const Spacer(),
                    Text('${exam.totalQuestions} questions'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Held ${formatExamDate(exam.heldAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _ScanCountsCard(examId: exam.id, version: state.version),
        const SizedBox(height: 8),
        _ActionsCard(exam: exam),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ExamStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ExamStatus.draft => Colors.grey,
      ExamStatus.active => Colors.blue,
      ExamStatus.graded => Colors.green,
      ExamStatus.published => Colors.deepPurple,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.name,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ScanCountsCard extends StatelessWidget {
  const _ScanCountsCard({required this.examId, required this.version});

  final String examId;
  final int version;

  @override
  Widget build(BuildContext context) {
    final db = context.read<AppState>().db;
    return FutureBuilder<Map<ScanStatus, int>>(
      key: ValueKey('counts-$examId-$version'),
      future: db.scansDao.countsByStatus(examId),
      builder: (context, snapshot) {
        final counts = snapshot.data ?? const <ScanStatus, int>{};
        int of(ScanStatus s) => counts[s] ?? 0;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sheets', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _countChip('scanned', counts.values.fold(0, (a, b) => a + b)),
                    _countChip('graded', of(ScanStatus.graded)),
                    _countChip(
                      'needs review',
                      of(ScanStatus.needsReview),
                      color: counts[ScanStatus.needsReview] != null &&
                              counts[ScanStatus.needsReview]! > 0
                          ? Colors.orange
                          : null,
                    ),
                    _countChip('reviewed', of(ScanStatus.reviewed)),
                    _countChip('rejected', of(ScanStatus.rejected)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _countChip(String label, int count, {Color? color}) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color ?? Colors.grey,
        child: Text(
          '$count',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ActionsCard extends StatelessWidget {
  const _ActionsCard({required this.exam});

  final Exam exam;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Card(
      child: Column(
        children: [
          if (exam.status == ExamStatus.draft)
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Activate exam'),
              subtitle: const Text('Unlock scanning for this exam'),
              onTap: () async {
                await state.db.examsDao.setStatus(
                  exam.id,
                  ExamStatus.active,
                );
                state.refresh();
              },
            ),
          ListTile(
            leading: const Icon(Icons.calculate_outlined),
            title: const Text('Grade now'),
            subtitle: const Text(
              'Grade every review-cleared scan against the active key',
            ),
            onTap: () => _grade(context, state),
          ),
          if (exam.status == ExamStatus.graded)
            ListTile(
              leading: const Icon(Icons.publish),
              title: const Text('Publish results'),
              onTap: () async {
                await state.db.examsDao.setStatus(
                  exam.id,
                  ExamStatus.published,
                );
                state.refresh();
              },
            ),
        ],
      ),
    );
  }

  Future<void> _grade(BuildContext context, AppState state) async {
    final messenger = ScaffoldMessenger.of(context);
    final keyVersion = await state.db.keysDao.activeVersion(exam.id);
    if (keyVersion == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Publish an answer key first')),
      );
      return;
    }
    final report = await GradingService(state.db).gradeExam(
      tenantId: state.tenantId,
      examId: exam.id,
      keyVersionId: keyVersion.id,
    );
    await state.db.examsDao.setStatus(exam.id, ExamStatus.graded);
    state.refresh();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Graded ${report.resultsByStudent.length} students '
          '(${report.resultsByStudent.values.fold<double>(0, (a, r) => a + r.totalMarks).toStringAsFixed(0)} marks total)',
        ),
      ),
    );
  }
}
