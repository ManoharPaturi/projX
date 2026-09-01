import 'package:flutter/material.dart';
import 'package:omr_data/omr_data.dart';
import 'package:provider/provider.dart';

import '../../src/app_state.dart';

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
      _flaggedFields = decodeJsonList(item.fieldRefsJson)
          .map((e) => '$e')
          .toList(growable: false);
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
        for (final read in _detail!.reads
            .where((r) => r.fieldKey == entry.key))
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
    await state.db.reviewDao.resolve(
      widget.reviewId,
      resolvedBy: 'app-operator',
      outcome: outcome,
      corrections: outcome == ReviewOutcome.corrected ? _corrections() : const [],
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
      appBar: AppBar(title: Text(scan.rollNoRead ?? 'Review sheet')),
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
                    _item!.reasonCode,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Set ${scan.setCodeRead ?? '—'} · confidence '
                    '${(scan.sheetConfidence ?? 0).toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the bubble the student actually marked. '
                    'Saving writes a human correction that supersedes the '
                    'machine read on every re-grade.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // The zoomed warped crop lives here in production; fixtures carry
          // no image bytes, so the read values stand alone.
          for (final fieldKey in _flaggedFields) _fieldEditor(fieldKey),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _chosen.isNotEmpty
                ? () => _resolve(ReviewOutcome.corrected)
                : null,
            icon: const Icon(Icons.check),
            label: Text(
              'Save correction${_chosen.length == 1 ? '' : 's'}'
              '${_chosen.isEmpty ? '' : ' (${_chosen.length})'}',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _resolve(ReviewOutcome.retaken),
                  child: const Text('Ask for retake'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _resolve(ReviewOutcome.unresolvable),
                  child: const Text('Reject sheet'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fieldEditor(String fieldKey) {
    final reads =
        _detail!.reads.where((r) => r.fieldKey == fieldKey).toList()
          ..sort((a, b) => a.optionIndex.compareTo(b.optionIndex));
    if (reads.isEmpty) {
      return Card(
        child: ListTile(
          title: Text(fieldKey),
          subtitle: const Text('No reads stored for this field'),
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
            Text(fieldKey, style: const TextStyle(fontWeight: FontWeight.w600)),
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
    final machineFilled = read.markClass == MarkClass.filled ||
        read.markClass == MarkClass.multiple;
    final chosen = _chosen[fieldKey] == option;
    final letter = String.fromCharCode(65 + option);
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() {
              if (chosen) {
                _chosen.remove(fieldKey);
              } else {
                _chosen[fieldKey] = option;
              }
            }),
            customBorder: const CircleBorder(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: chosen
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                  width: chosen ? 3 : 1.5,
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
          const SizedBox(height: 4),
          Text(
            machineFilled ? 'machine' : 'empty',
            style: TextStyle(
              fontSize: 10,
              color: machineFilled ? Colors.orange : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
