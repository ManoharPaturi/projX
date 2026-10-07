import 'package:flutter/material.dart';
import 'package:omr_data/omr_data.dart';
import 'package:provider/provider.dart';

import '../../src/app_drawer.dart';
import '../../src/app_state.dart';
import '../../src/labels.dart';
import '../capture/capture_screen.dart';
import '../exams/exam_create_screen.dart';
import '../exams/exam_detail_screen.dart';
import '../review/review_queue_screen.dart';
import '../settings/settings_screen.dart';
import '../students/roster_screen.dart';

/// Plan §6 screen 1 — the home screen. A first-time operator sees a
/// numbered checklist that walks the whole job (name → students → exam →
/// key → print and scan → check); a returning one sees the big scan button,
/// what is waiting for them, and their exams.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const String routeName = '/';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text(state.instituteName)),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New exam'),
        onPressed: () =>
            Navigator.pushNamed(context, ExamCreateScreen.routeName),
      ),
      body: FutureBuilder<_Overview>(
        key: ValueKey('overview-${state.version}'),
        future: _Overview.load(state),
        builder: (context, snapshot) {
          final overview = snapshot.data;
          if (overview == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            children: [
              if (!overview.setupComplete) ...[
                _GettingStarted(overview: overview),
                const SizedBox(height: 12),
              ],
              if (overview.exams.isNotEmpty) ...[
                _ScanButton(),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.fact_check_outlined,
                      count: overview.pendingReview,
                      label: overview.pendingReview == 1
                          ? 'sheet to check'
                          : 'sheets to check',
                      highlight: overview.pendingReview > 0,
                      onTap: () => Navigator.pushNamed(
                        context,
                        ReviewQueueScreen.routeName,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.people_outline,
                      count: overview.students,
                      label: overview.students == 1 ? 'student' : 'students',
                      onTap: () =>
                          Navigator.pushNamed(context, RosterScreen.routeName),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Your exams', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              _ExamList(exams: overview.exams),
            ],
          );
        },
      ),
    );
  }
}

/// Everything the home screen shows, loaded in one pass.
class _Overview {
  _Overview({
    required this.instituteNamed,
    required this.students,
    required this.exams,
    required this.firstExamWithoutKey,
    required this.anyKey,
    required this.anyScans,
    required this.pendingReview,
  });

  final bool instituteNamed;
  final int students;
  final List<Exam> exams;
  final Exam? firstExamWithoutKey;
  final bool anyKey;
  final bool anyScans;
  final int pendingReview;

  bool get setupComplete =>
      instituteNamed && students > 0 && exams.isNotEmpty && anyKey && anyScans;

  static Future<_Overview> load(AppState state) async {
    final db = state.db;
    final exams = await db.examsDao.forInstitute(
      state.tenantId,
      state.instituteId,
    );
    Exam? withoutKey;
    var anyKey = false;
    var anyScans = false;
    for (final exam in exams) {
      if (await db.keysDao.activeVersion(exam.id) == null) {
        withoutKey ??= exam;
      } else {
        anyKey = true;
      }
      final counts = await db.scansDao.countsByStatus(exam.id);
      if (counts.values.any((n) => n > 0)) anyScans = true;
    }
    return _Overview(
      instituteNamed: state.instituteNamed,
      students: await db.studentsDao.count(state.instituteId),
      exams: exams,
      firstExamWithoutKey: withoutKey,
      anyKey: anyKey,
      anyScans: anyScans,
      pendingReview: (await db.scansDao.pendingReview()).length,
    );
  }
}

class _GettingStarted extends StatelessWidget {
  const _GettingStarted({required this.overview});

  final _Overview overview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyExam = overview.firstExamWithoutKey ?? overview.exams.firstOrNull;
    final steps = <_Step>[
      _Step(
        title: 'Add your institute name',
        detail: 'It is printed on every marksheet.',
        done: overview.instituteNamed,
        onTap: () => editInstituteName(context),
      ),
      _Step(
        title: 'Add your students',
        detail: 'Type them in, or paste a list from Excel.',
        done: overview.students > 0,
        onTap: () => Navigator.pushNamed(context, RosterScreen.routeName),
      ),
      _Step(
        title: 'Create an exam',
        detail: 'Pick the sheet type and marking scheme.',
        done: overview.exams.isNotEmpty,
        onTap: () => Navigator.pushNamed(context, ExamCreateScreen.routeName),
      ),
      _Step(
        title: 'Enter the answer key',
        detail: 'Tap the right option for each question.',
        done: overview.anyKey,
        onTap: keyExam == null
            ? null
            : () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ExamDetailScreen(
                    examId: keyExam.id,
                    initialTab: ExamDetailScreen.answerKeyTab,
                  ),
                ),
              ),
      ),
      _Step(
        title: 'Print sheets, then scan them',
        detail: 'Print from the exam page. Scan with the phone camera.',
        done: overview.anyScans,
        onTap: overview.exams.isEmpty
            ? null
            : () => Navigator.pushNamed(context, CaptureScreen.routeName),
      ),
    ];
    final doneCount = steps.where((s) => s.done).length;
    return Card(
      key: const Key('getting-started'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Getting started', style: theme.textTheme.titleLarge),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                '$doneCount of ${steps.length} done — tap a step to do it.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            for (var i = 0; i < steps.length; i++)
              _StepTile(number: i + 1, step: steps[i]),
          ],
        ),
      ),
    );
  }
}

class _Step {
  const _Step({
    required this.title,
    required this.detail,
    required this.done,
    required this.onTap,
  });

  final String title;
  final String detail;
  final bool done;
  final VoidCallback? onTap;
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.number, required this.step});

  final int number;
  final _Step step;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: step.done
            ? const Color(0xFF1B5E20)
            : scheme.primaryContainer,
        foregroundColor: step.done ? Colors.white : scheme.onPrimaryContainer,
        child: step.done
            ? Icon(Icons.check, semanticLabel: 'Done')
            : Text('$number'),
      ),
      title: Text(
        step.title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          decoration: step.done ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(step.detail),
      trailing: step.done || step.onTap == null
          ? null
          : const Icon(Icons.chevron_right),
      onTap: step.done ? null : step.onTap,
    );
  }
}

class _ScanButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          textStyle: Theme.of(context).textTheme.titleLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.document_scanner_outlined, size: 32),
        label: const Text('Scan answer sheets'),
        onPressed: () => Navigator.pushNamed(context, CaptureScreen.routeName),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.count,
    required this.label,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final int count;
  final String label;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: highlight ? theme.colorScheme.tertiaryContainer : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$count', style: theme.textTheme.headlineSmall),
                    Text(label),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExamList extends StatelessWidget {
  const _ExamList({required this.exams});

  final List<Exam> exams;

  @override
  Widget build(BuildContext context) {
    if (exams.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No exams yet. Tap "New exam" to create one.'),
        ),
      );
    }
    return Card(
      child: Column(
        children: [
          for (final exam in exams)
            ListTile(
              title: Text(
                exam.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${examStatusLabel(exam.status)} · '
                '${exam.totalQuestions} questions'
                '${exam.heldAt == null ? '' : ' · ${formatDate(exam.heldAt!)}'}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ExamDetailScreen(examId: exam.id),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
