import 'package:flutter/material.dart';
import 'package:omr_data/omr_data.dart';
import 'package:provider/provider.dart';

import '../../src/app_state.dart';
import '../../src/labels.dart';
import '../analytics/analytics_screen.dart';
import 'print_sheets.dart';
import '../keys/key_editor_screen.dart';
import '../reports/reports_screen.dart';
import '../results/results_screen.dart';

/// The exam hub: overview / answer key / results / reports (plan §6 screens
/// 3, 8 and 10 hang off here so navigation stays one level deep).
class ExamDetailScreen extends StatefulWidget {
  const ExamDetailScreen({
    super.key,
    required this.examId,
    this.initialTab = 0,
  });

  final String examId;

  /// Tab to open on: 0 overview, 1 answer key, 2 results, 3 analysis,
  /// 4 reports.
  final int initialTab;

  static const int answerKeyTab = 1;

  @override
  State<ExamDetailScreen> createState() => _ExamDetailScreenState();
}

class _ExamDetailScreenState extends State<ExamDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTab,
    );
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
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Answer key'),
                Tab(text: 'Results'),
                Tab(text: 'Analysis'),
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
              AnalyticsScreen(examId: widget.examId),
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
                if (exam.heldAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Exam date: ${formatDate(exam.heldAt!)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
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
    // Dark ink on the 15% tint of itself — 500-shade blue/green/purple
    // text on a near-white chip fell under WCAG AA.
    final color = switch (status) {
      ExamStatus.draft => const Color(0xFF5F6368),
      ExamStatus.active => const Color(0xFF1565C0),
      ExamStatus.graded => const Color(0xFF1B5E20),
      ExamStatus.published => const Color(0xFF4A148C),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        examStatusLabel(status),
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
                Text(
                  'Scanned sheets',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _countChip('total', counts.values.fold(0, (a, b) => a + b)),
                    _countChip('marked', of(ScanStatus.graded)),
                    _countChip(
                      'to check',
                      of(ScanStatus.needsReview),
                      color:
                          counts[ScanStatus.needsReview] != null &&
                              counts[ScanStatus.needsReview]! > 0
                          ? const Color(0xFF8B4000)
                          : null,
                    ),
                    _countChip('checked', of(ScanStatus.reviewed)),
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
        // White-on-dark counts: grey/orange 500 failed contrast.
        backgroundColor: color ?? const Color(0xFF5F6368),
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
          ListTile(
            leading: const Icon(Icons.print_outlined),
            title: const Text('Print answer sheets'),
            subtitle: const Text(
              'Print one blank sheet per student — on any printer, A4 paper',
            ),
            onTap: () => printAnswerSheets(context, exam),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.calculate_outlined),
            title: const Text('Calculate marks'),
            subtitle: const Text(
              'Marks every scanned sheet that does not need checking',
            ),
            onTap: () => _grade(context, state),
          ),
          if (exam.status == ExamStatus.graded) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.verified_outlined),
              title: const Text('Mark results as final'),
              subtitle: const Text('Do this once results are shared'),
              onTap: () async {
                final ok = await _confirm(
                  context,
                  title: 'Mark results as final?',
                  body:
                      'You can still fix the answer key later; the marks '
                      'will be recalculated.',
                  action: 'Mark final',
                );
                if (!ok) return;
                await state.db.examsDao.setStatus(
                  exam.id,
                  ExamStatus.published,
                );
                state.refresh();
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String action,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _grade(BuildContext context, AppState state) async {
    final messenger = ScaffoldMessenger.of(context);
    final keyVersion = await state.db.keysDao.activeVersion(exam.id);
    if (keyVersion == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Enter the answer key first (Answer key tab)'),
        ),
      );
      return;
    }
    if (exam.status == ExamStatus.draft) {
      // Scanning or grading an exam is what starts it; no separate step.
      await state.db.examsDao.setStatus(exam.id, ExamStatus.active);
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
          'Marks ready for ${report.resultsByStudent.length} '
          'student${report.resultsByStudent.length == 1 ? '' : 's'} — see the '
          'Results tab',
        ),
      ),
    );
  }
}
