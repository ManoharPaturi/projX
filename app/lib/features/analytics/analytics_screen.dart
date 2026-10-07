import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:omr_data/omr_data.dart';
import 'package:omr_reports/omr_reports.dart';
import 'package:provider/provider.dart';

import '../../src/app_state.dart';
import '../../src/labels.dart';

/// Plan §6 screen 9 — how the class did, said for a teacher: the headline
/// numbers, how scores spread, subject averages, questions worth a second
/// look (a likely answer-key mistake), and the hardest questions with how
/// students' answers split across the options.
///
/// Every number comes from SQL in [AnalyticsDao] / [ResultsQuery] over the
/// active key version — the same data the reports print.
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key, required this.examId});

  final String examId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return FutureBuilder<_Analysis?>(
      key: ValueKey('analytics-$examId-${state.version}'),
      future: _Analysis.load(state.db, examId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final analysis = snapshot.data;
        if (analysis == null || analysis.rows.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Analysis appears once sheets are scanned and marked.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _SummaryCard(analysis: analysis),
            _DistributionCard(analysis: analysis),
            if (analysis.subjects.length > 1)
              _SubjectsCard(subjects: analysis.subjects),
            if (analysis.suspicious.isNotEmpty)
              _SuspiciousCard(questions: analysis.suspicious),
            _HardestCard(analysis: analysis),
          ],
        );
      },
    );
  }
}

class _Analysis {
  _Analysis({
    required this.rows,
    required this.subjects,
    required this.questions,
    required this.optionsByQuestion,
  });

  final List<ReportRow> rows;
  final List<SubjectAggregateRow> subjects;
  final List<QuestionStatsRow> questions;
  final Map<String, List<DistractorRow>> optionsByQuestion;

  double get average =>
      rows.fold<double>(0, (sum, r) => sum + r.total) / rows.length;
  double get highest => rows.map((r) => r.total).reduce(math.max);
  double get lowest => rows.map((r) => r.total).reduce(math.min);

  /// Questions whose numbers point at the key rather than the students:
  /// stronger students did clearly worse than weaker ones, or almost
  /// nobody got it right. Advisory only — the teacher decides.
  List<QuestionStatsRow> get suspicious => [
    for (final q in questions)
      if (q.students >= 4 &&
          ((q.discrimination != null && q.discrimination! < -0.1) ||
              q.difficulty < 0.1))
        q,
  ];

  static Future<_Analysis?> load(AppDb db, String examId) async {
    final key = await db.keysDao.activeVersion(examId);
    if (key == null) return null;
    final query = ResultsQuery(db, examId: examId, keyVersionId: key.id);
    final distractors = await db.analyticsDao.distractorDistribution(
      examId,
      key.id,
    );
    final byQuestion = <String, List<DistractorRow>>{};
    for (final d in distractors) {
      byQuestion.putIfAbsent(d.questionId, () => []).add(d);
    }
    return _Analysis(
      rows: await query.rows(),
      subjects: await db.analyticsDao.subjectAggregates(examId, key.id),
      questions: await db.analyticsDao.questionStats(examId, key.id),
      optionsByQuestion: byQuestion,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.help});

  final String title;
  final String? help;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            if (help != null) ...[
              const SizedBox(height: 4),
              Text(help!, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.analysis});

  final _Analysis analysis;

  @override
  Widget build(BuildContext context) {
    Widget stat(String label, String value) => Expanded(
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
    return _SectionCard(
      title: 'Class at a glance',
      child: Row(
        children: [
          stat('students', '${analysis.rows.length}'),
          stat('average', formatMarks(analysis.average)),
          stat('highest', formatMarks(analysis.highest)),
          stat('lowest', formatMarks(analysis.lowest)),
        ],
      ),
    );
  }
}

/// Five equal score bands from the lowest to the highest total.
class _DistributionCard extends StatelessWidget {
  const _DistributionCard({required this.analysis});

  final _Analysis analysis;

  @override
  Widget build(BuildContext context) {
    const bands = 5;
    final low = math.min(0.0, analysis.lowest);
    final high = math.max(analysis.highest, low + 1);
    final width = (high - low) / bands;
    final counts = List<int>.filled(bands, 0);
    for (final row in analysis.rows) {
      final band = ((row.total - low) / width).floor().clamp(0, bands - 1);
      counts[band]++;
    }
    final most = counts.reduce(math.max);
    return _SectionCard(
      title: 'How scores spread',
      help: 'Number of students in each marks range.',
      child: Column(
        children: [
          for (var i = bands - 1; i >= 0; i--)
            _BarRow(
              label:
                  '${formatMarks(low + width * i)}–'
                  '${formatMarks(low + width * (i + 1))}',
              fraction: most == 0 ? 0 : counts[i] / most,
              trailing: '${counts[i]}',
            ),
        ],
      ),
    );
  }
}

class _SubjectsCard extends StatelessWidget {
  const _SubjectsCard({required this.subjects});

  final List<SubjectAggregateRow> subjects;

  @override
  Widget build(BuildContext context) {
    final top = subjects.map((s) => s.maxTotal).fold<double>(1, math.max);
    return _SectionCard(
      title: 'Subject averages',
      help: 'Bar = class average; highest and lowest shown on the right.',
      child: Column(
        children: [
          for (final s in subjects)
            _BarRow(
              label: s.subject,
              fraction: top <= 0 ? 0 : (s.avgTotal / top).clamp(0, 1),
              trailing:
                  '${formatMarks(s.avgTotal)}  '
                  '(${formatMarks(s.minTotal)} to ${formatMarks(s.maxTotal)})',
            ),
        ],
      ),
    );
  }
}

class _SuspiciousCard extends StatelessWidget {
  const _SuspiciousCard({required this.questions});

  final List<QuestionStatsRow> questions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: const Key('suspicious-questions'),
      color: theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Check these questions in the answer key',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Almost nobody got them right, or stronger students got them '
              'wrong more often than weaker ones. That often means a '
              'mistake in the key. If you fix the key, every sheet is '
              're-marked automatically.',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final q in questions)
                  Chip(
                    label: Text(
                      '${fieldLabel(q.questionId)} · '
                      '${(q.difficulty * 100).round()}% right',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HardestCard extends StatelessWidget {
  const _HardestCard({required this.analysis});

  final _Analysis analysis;

  @override
  Widget build(BuildContext context) {
    final hardest = [...analysis.questions]
      ..sort((a, b) => a.difficulty.compareTo(b.difficulty));
    final shown = hardest.take(10).toList();
    return _SectionCard(
      title: 'Hardest questions',
      help: 'Tap a question to see which options students picked.',
      child: Column(
        children: [
          for (final q in shown)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(fieldLabel(q.questionId)),
              subtitle: Text(
                '${(q.difficulty * 100).round()}% got it right · '
                '${q.students - q.attempted} left it blank',
              ),
              children: [
                for (final option
                    in analysis.optionsByQuestion[q.questionId] ??
                        const <DistractorRow>[])
                  _BarRow(
                    label:
                        'Option ${String.fromCharCode(65 + option.optionIndex)}'
                        '${option.isCorrectOption ? ' ✓' : ''}',
                    fraction: q.students == 0
                        ? 0
                        : option.chosenCount / q.students,
                    trailing: '${option.chosenCount}',
                    highlight: option.isCorrectOption,
                  ),
                const SizedBox(height: 8),
              ],
            ),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.fraction,
    required this.trailing,
    this.highlight = false,
  });

  final String label;
  final double fraction;
  final String trailing;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: '$label: $trailing',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(width: 96, child: Text(label)),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fraction.clamp(0, 1),
                  minHeight: 14,
                  backgroundColor: scheme.surfaceContainerHighest,
                  color: highlight ? const Color(0xFF1B5E20) : scheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(trailing),
          ],
        ),
      ),
    );
  }
}
