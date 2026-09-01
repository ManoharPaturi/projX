import 'package:flutter/material.dart';
import 'package:omr_core/omr_core.dart' as core;
import 'package:omr_data/omr_data.dart';
import 'package:provider/provider.dart';

import '../../src/app_state.dart';

/// Plan §6 screen 3 — per-set tabs (A–D), grid entry, publish final.
///
/// A key edit is always a NEW immutable version (plan §5): publishing here
/// inserts an `answer_key_versions` row that supersedes the active one and
/// freezes it. Re-grading from the corrected key never rescans a sheet.
class KeyEditorScreen extends StatefulWidget {
  const KeyEditorScreen({super.key, required this.examId, this.embedded});

  final String examId;

  /// True when hosted inside ExamDetailScreen's tab (no Scaffold of our own).
  final bool? embedded;

  @override
  State<KeyEditorScreen> createState() => _KeyEditorScreenState();
}

class _KeyEditorScreenState extends State<KeyEditorScreen>
    with SingleTickerProviderStateMixin {
  static const List<String> _sets = ['A', 'B', 'C', 'D'];

  late final TabController _setTabs;
  bool _loading = true;

  /// setCode → questionId → selected option index (the in-progress grid).
  final Map<String, Map<String, int>> _draft = {
    for (final set in _sets) set: <String, int>{},
  };

  List<core.QuestionId> _questionOrder = const [];
  Map<String, List<core.OptionId>> _optionsByField = const {};
  List<core.SectionSpec> _sections = const [];
  List<AnswerKeyVersion> _versions = const [];

  @override
  void initState() {
    super.initState();
    _setTabs = TabController(length: _sets.length, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _setTabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final db = context.read<AppState>().db;
    final layout = await GradingService(db).layoutContextFor(widget.examId);
    final versions = await db.keysDao.versionsFor(widget.examId);

    // Prefill from the newest version so a correction starts from reality.
    if (versions.isNotEmpty) {
      final entries = await db.keysDao.entriesFor(versions.first.id);
      for (final entry in entries) {
        final options = decodeJsonList(entry.correctOptionsJson)
            .cast<int>()
            .toList(growable: false);
        if (options.isNotEmpty) {
          _draft[entry.setCode]?[entry.questionId] = options.first;
        }
      }
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _questionOrder = layout.questionOrder;
      _optionsByField = layout.optionValuesByField;
      _sections = layout.sections;
      _versions = versions;
      _loading = false;
    });
  }

  int get _keyedCount => _draft[_sets[_setTabs.index]]?.length ?? 0;

  Future<void> _publish() async {
    final state = context.read<AppState>();
    final db = state.db;
    final active = await db.keysDao.activeVersion(widget.examId);
    final nextVersion = (active?.version ?? 0) + 1;

    final entries = <KeyEntryInput>[
      for (final set in _sets)
        for (final entry in _draft[set]!.entries)
          KeyEntryInput(
            setCode: set,
            questionId: entry.key,
            correctOptions: [entry.value],
          ),
    ];

    final keyVersionId = await db.keysDao.createVersion(
      tenantId: state.tenantId,
      examId: widget.examId,
      version: nextVersion,
      createdBy: 'app',
      supersedesId: active?.id,
    );
    await db.keysDao.addEntries(keyVersionId, tenantId: state.tenantId, entries: entries);
    await db.keysDao.finalizeVersion(keyVersionId);
    await _load();
    state.refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Key version $nextVersion published')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final body = Column(
      children: [
        if (_versions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Text(
                  'Active: v${_versions.first.version}'
                  ' (${_versions.first.status.name})'
                  '${_versions.length > 1 ? ' · ${_versions.length} versions' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        Expanded(
          child: _setGrid(_sets[_setTabs.index]),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Text('$_keyedCount/${_questionOrder.length} keyed'),
                const Spacer(),
                FilledButton(
                  onPressed: _keyedCount == _questionOrder.length
                      ? _publish
                      : null,
                  child: const Text('Publish as final'),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (widget.embedded == true) {
      return Column(
        children: [
          TabBar(
            controller: _setTabs,
            isScrollable: true,
            tabs: [for (final set in _sets) Tab(text: 'Set $set')],
          ),
          Expanded(child: body),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Answer key'),
        bottom: TabBar(
          controller: _setTabs,
          isScrollable: true,
          tabs: [for (final set in _sets) Tab(text: 'Set $set')],
        ),
      ),
      body: body,
    );
  }

  /// The questions of one set: section headers + one row per question with
  /// option bubbles. Tapping a bubble sets the key; the set A tab is the one
  /// most institutes fill first.
  Widget _setGrid(String set) {
    return ListView.builder(
      key: ValueKey('set-$set'),
      itemCount: _questionOrder.length,
      itemBuilder: (context, index) {
        final questionId = _questionOrder[index];
        final section = _sectionOf(questionId);
        final previous = index > 0 ? _questionOrder[index - 1] : null;
        final showHeader =
            section != null && (previous == null || _sectionOf(previous) != section);
        final optionCount = _optionsByField[questionId]?.length ?? 4;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  section.name ?? section.subjectKey,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    child: Text(
                      questionId,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  for (var option = 0; option < optionCount; option++)
                    _optionBubble(set, questionId, option),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _optionBubble(String set, String questionId, int option) {
    final selected = _draft[set]?[questionId] == option;
    final letter = String.fromCharCode(65 + option);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() {
          if (selected) {
            _draft[set]?.remove(questionId);
          } else {
            _draft[set]?[questionId] = option;
          }
        }),
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
              width: selected ? 3 : 1.5,
            ),
            color: selected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            letter,
            style: TextStyle(
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  core.SectionSpec? _sectionOf(String questionId) {
    for (final section in _sections) {
      if (section.questionIds.contains(questionId)) {
        return section;
      }
    }
    return null;
  }
}
