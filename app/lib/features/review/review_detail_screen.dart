import 'package:flutter/material.dart';
import 'package:omr_data/omr_data.dart';
import 'package:provider/provider.dart';

import '../../src/app_state.dart';
import '../../src/labels.dart';

/// Plan §6 screen 7's tap-through: the flagged fields' machine reads beside
/// tap-to-correct bubbles. Saving writes `bubble_reads.isHumanCorrection=1`
/// — the corrected value then supersedes the machine read on every re-grade,
/// which is the whole ~90% → ~99%+ mechanism.
class ReviewDetailScreen extends StatefulWidget {
  const ReviewDetailScreen({super.key, required this.reviewId});

  final String reviewId;

  @override
  State<ReviewDetailScreen> createState() => _ReviewDetailScreenState();
}

class _ReviewDetailScreenState extends State<ReviewDetailScreen> {
  bool _loading = true;
  ReviewQueueItem? _item;
  ScanDetail? _detail;
  List<String> _flaggedFields = const [];

  /// fieldKey → the option the operator marked as the real one.
  final Map<String, int> _chosen = {};

  /// The roster student the operator confirmed this sheet belongs to, when
  /// it differs from (or replaces a missing) machine attribution.
  Student? _assigned;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = context.read<AppState>().db;
    final item = await (db.select(
      db.reviewQueue,
    )..where((ReviewQueue r) => r.id.equals(widget.reviewId))).getSingle();
    final detail = await db.scansDao.fetchWithReads(item.scanId);
    if (!mounted) {
      return;
    }
    setState(() {
      _item = item;
      _detail = detail;
      _flaggedFields = decodeJsonList(
        item.fieldRefsJson,
      ).map((e) => '$e').toList(growable: false);
      _loading = false;
    });
  }

  /// The corrections payload: chosen option filled, every other option of the
  /// field emptied — both rows written in place, so the read is left
  /// internally consistent (exactly one mark per question).
  List<BubbleCorrection> _corrections() {
    if (_detail == null) {
      return const <BubbleCorrection>[];
    }
    return <BubbleCorrection>[
      for (final entry in _chosen.entries)
        for (final read in _detail!.reads.where((r) => r.fieldKey == entry.key))
          BubbleCorrection(
            fieldKey: entry.key,
            optionIndex: read.optionIndex,
            markClass: read.optionIndex == entry.value
                ? MarkClass.filled
                : MarkClass.empty,
          ),
    ];
  }

  Future<void> _resolve(ReviewOutcome outcome) async {
    final state = context.read<AppState>();
    final assigned = _assigned;
    if (outcome == ReviewOutcome.corrected && assigned != null) {
      await state.db.scansDao.assignStudent(
        _detail!.scan.id,
        studentId: assigned.id,
        rollNo: assigned.rollNo,
        byUser: 'app-operator',
      );
    }
    await state.db.reviewDao.resolve(
      widget.reviewId,
      resolvedBy: 'app-operator',
      outcome: outcome,
      corrections: outcome == ReviewOutcome.corrected
          ? _corrections()
          : const [],
    );
    // A correction changes marks: re-grade so results/reports follow.
    if (outcome == ReviewOutcome.corrected && _detail != null) {
      final keyVersion = await state.db.keysDao.activeVersion(
        _detail!.scan.examId,
      );
      if (keyVersion != null) {
        await state.grade(_detail!.scan.examId, keyVersion.id);
      }
    }
    state.refresh();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final scan = _detail!.scan;
    return Scaffold(
      appBar: AppBar(title: const Text('Check this sheet')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reviewReasonLabel(_item!.reasonCode),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reviewReasonHelp(_item!.reasonCode),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set ${scan.setCodeRead ?? 'not marked'} · your fix is '
                    'kept even if the answer key changes later.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // The zoomed warped crop lives here in production; fixtures carry
          // no image bytes, so the read values stand alone.
          _AssignStudentCard(
            currentStudentId: scan.studentId,
            machineRoll: scan.rollNoRead,
            assigned: _assigned,
            onAssigned: (student) => setState(() => _assigned = student),
          ),
          for (final fieldKey in _flaggedFields)
            if (!fieldKey.startsWith('roll')) _fieldEditor(fieldKey),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _chosen.isNotEmpty || _assigned != null
                ? () => _resolve(ReviewOutcome.corrected)
                : null,
            icon: const Icon(Icons.check),
            label: Text(
              _chosen.isEmpty && _assigned != null
                  ? 'Save and grade this sheet'
                  : 'Save correction${_chosen.length == 1 ? '' : 's'}'
                        '${_chosen.isEmpty ? '' : ' (${_chosen.length})'}',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _resolve(ReviewOutcome.retaken),
                  child: const Text('Retake photo'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _resolve(ReviewOutcome.unresolvable),
                  child: const Text('Can\'t fix — reject'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fieldEditor(String fieldKey) {
    final reads = _detail!.reads.where((r) => r.fieldKey == fieldKey).toList()
      ..sort((a, b) => a.optionIndex.compareTo(b.optionIndex));
    if (reads.isEmpty) {
      return Card(
        child: ListTile(
          title: Text(fieldLabel(fieldKey)),
          subtitle: const Text('Nothing was read here'),
        ),
      );
    }
    final optionCount = reads.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fieldLabel(fieldKey),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var option = 0; option < optionCount; option++)
                  _bubble(fieldKey, option, reads[option]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(String fieldKey, int option, BubbleRead read) {
    final machineFilled =
        read.markClass == MarkClass.filled ||
        read.markClass == MarkClass.multiple;
    final chosen = _chosen[fieldKey] == option;
    final letter = String.fromCharCode(65 + option);
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Semantics(
            button: true,
            selected: chosen,
            label:
                'Option $letter'
                '${machineFilled ? ', machine read as marked' : ''}',
            child: InkWell(
              onTap: () => setState(() {
                if (chosen) {
                  _chosen.remove(fieldKey);
                } else {
                  _chosen[fieldKey] = option;
                }
              }),
              customBorder: const CircleBorder(),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: chosen
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade700,
                    width: chosen ? 3 : 2,
                  ),
                  color: chosen
                      ? Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.25)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(letter),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            machineFilled ? 'read as marked' : 'blank',
            style: TextStyle(
              fontSize: 11,
              color: machineFilled
                  ? const Color(0xFF8B4000)
                  : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Whose sheet is this?" — the human answer for an unreadable roll, a roll
/// that is not on the roster, or a failed check digit. A sheet with no
/// student is never graded, so this card is what rescues it.
class _AssignStudentCard extends StatefulWidget {
  const _AssignStudentCard({
    required this.currentStudentId,
    required this.machineRoll,
    required this.assigned,
    required this.onAssigned,
  });

  /// The scan's current student id (null = nobody yet).
  final String? currentStudentId;
  final String? machineRoll;
  final Student? assigned;
  final ValueChanged<Student?> onAssigned;

  @override
  State<_AssignStudentCard> createState() => _AssignStudentCardState();
}

class _AssignStudentCardState extends State<_AssignStudentCard> {
  final _controller = TextEditingController();
  String? _message;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final roll = _controller.text.trim();
    if (roll.isEmpty) return;
    final state = context.read<AppState>();
    final student = await state.db.studentsDao.findByRoll(
      state.instituteId,
      roll,
    );
    if (!mounted) return;
    setState(() {
      _message = student == null
          ? 'No student with roll $roll. Add them on the Students screen '
                'first, then come back.'
          : null;
    });
    widget.onAssigned(student);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unattributed = widget.currentStudentId == null;
    final assigned = widget.assigned;
    return Card(
      key: const Key('assign-student-card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Whose sheet is this?', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              unattributed
                  ? 'The roll number could not be matched to a student'
                        '${widget.machineRoll == null ? '' : ' (read as ${widget.machineRoll})'}. '
                        'Type the roll number written on the sheet.'
                  : 'Matched to roll ${widget.machineRoll ?? '?'}. '
                        'Change it only if that is wrong.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('assign-roll-field'),
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Roll number'),
                    onSubmitted: (_) => _lookup(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: _lookup,
                  child: const Text('Find'),
                ),
              ],
            ),
            if (assigned != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF1B5E20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Roll ${assigned.rollNo}'
                      '${assigned.name == null ? '' : ' · ${assigned.name}'}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
            if (_message != null) ...[
              const SizedBox(height: 8),
              Text(_message!, style: TextStyle(color: theme.colorScheme.error)),
            ],
          ],
        ),
      ),
    );
  }
}
