import 'package:flutter/material.dart';
import 'package:omr_data/omr_data.dart';
import 'package:omr_reports/omr_reports.dart';
import 'package:provider/provider.dart';

import '../../src/app_drawer.dart';
import '../../src/app_state.dart';
import '../capture/capture_screen.dart';
import '../exams/exam_create_screen.dart';
import '../exams/exam_detail_screen.dart';

/// Plan §6 screen 1 — recent exams, capture CTA, pending-review badge.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const String routeName = '/';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: Text(state.instituteName),
        actions: [
          IconButton(
            icon: const Icon(Icons.document_scanner),
            tooltip: 'Scan sheets',
            onPressed: () =>
                Navigator.pushNamed(context, CaptureScreen.routeName),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New exam'),
        onPressed: () =>
            Navigator.pushNamed(context, ExamCreateScreen.routeName),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            children: [
              Expanded(child: _PendingReviewCard(version: state.version)),
              const SizedBox(width: 12),
              Expanded(child: _RosterCard(version: state.version)),
            ],
          ),
          const SizedBox(height: 12),
          Text('Recent exams', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          _ExamList(version: state.version),
        ],
      ),
    );
  }
}

class _PendingReviewCard extends StatelessWidget {
  const _PendingReviewCard({required this.version});

  final int version;

  @override
  Widget build(BuildContext context) {
    final db = context.read<AppState>().db;
    return FutureBuilder<List<PendingReviewRow>>(
      key: ValueKey('review-$version'),
      future: db.scansDao.pendingReview(),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return Card(
          child: ListTile(
            leading: Icon(
              Icons.fact_check_outlined,
              color: count > 0 ? Colors.orange : Colors.green,
            ),
            title: Text('$count'),
            subtitle: const Text('pending review'),
            onTap: () => Navigator.pushNamed(
              context,
              '/review',
            ), // ReviewQueueScreen.routeName
          ),
        );
      },
    );
  }
}

class _RosterCard extends StatelessWidget {
  const _RosterCard({required this.version});

  final int version;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return FutureBuilder<int>(
      key: ValueKey('students-$version'),
      future: state.db.studentsDao.count(state.instituteId),
      builder: (context, snapshot) {
        return Card(
          child: ListTile(
            leading: const Icon(Icons.people_outline),
            title: Text('${snapshot.data ?? 0}'),
            subtitle: const Text('students'),
            onTap: () => Navigator.pushNamed(context, '/roster'),
          ),
        );
      },
    );
  }
}

class _ExamList extends StatelessWidget {
  const _ExamList({required this.version});

  final int version;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return FutureBuilder<List<Exam>>(
      key: ValueKey('exams-$version'),
      future: state.db.examsDao.forInstitute(
        state.tenantId,
        state.instituteId,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final exams = snapshot.data!;
        if (exams.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No exams yet. Create one, import the roster, then scan.',
              ),
            ),
          );
        }
        return Card(
          child: Column(
            children: [
              for (final exam in exams)
                ListTile(
                  title: Text(exam.name),
                  subtitle: Text(
                    '${exam.status.name} · ${exam.totalQuestions} questions'
                    '${exam.heldAt == null ? '' : ' · ${formatExamDate(exam.heldAt)}'}',
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
      },
    );
  }
}
