import 'package:flutter/material.dart';
import 'package:omr_data/omr_data.dart';
import 'package:provider/provider.dart';

import '../../src/app_state.dart';
import 'review_detail_screen.dart';

/// Plan §6 screen 7 — the worklist that turns ~90% machine reads into ~99%+
/// published accuracy. Sorted by severity then wait time (the DAO's order).
class ReviewQueueScreen extends StatelessWidget {
  const ReviewQueueScreen({super.key});

  static const String routeName = '/review';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Review queue')),
      body: FutureBuilder<List<PendingReviewRow>>(
        key: ValueKey('pending-${state.version}'),
        future: state.db.scansDao.pendingReview(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rows = snapshot.data!;
          if (rows.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_outlined, size: 48, color: Colors.green),
                  SizedBox(height: 8),
                  Text('Nothing waiting for review'),
                ],
              ),
            );
          }
          return ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
              final row = rows[index];
              return ListTile(
                leading: _SeverityBadge(severity: row.severity),
                title: Text(
                  row.rollNoRead ?? '(roll not read)',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${_reasonLabel(row.reasonCode)}'
                  '${row.setCodeRead == null ? '' : ' · set ${row.setCodeRead}'}'
                  ' · ${(row.sheetConfidence ?? 0).toStringAsFixed(2)}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ReviewDetailScreen(reviewId: row.reviewId),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// The intake's machine reason code, said the way an operator would. Kept
/// beside the queue because the code itself stays the storage key — only
/// the display is human.
String _reasonLabel(String code) => switch (code) {
      'NO_MARKER_ERR' => 'sheet not detected',
      'ROLL_CHECKSUM_ERR' => 'roll number failed its check digit',
      'ROLL_NOT_ON_ROSTER' => 'roll number not on the roster',
      'ROLL_AMBIGUOUS' => 'a roll digit was ambiguous',
      'SET_BLANK' => 'set code left blank',
      'SET_MULTI' => 'set code marked twice',
      'MULTI_BUBBLE_WARN' => 'a question has two marks',
      'PROBABLE_BUBBLE' => 'some bubbles read faintly',
      'CURL_WARN' => 'sheet looked curved',
      _ => code,
    };

class _SeverityBadge extends StatelessWidget {  const _SeverityBadge({required this.severity});

  final ReviewSeverity severity;

  @override
  Widget build(BuildContext context) {
    // Dark-filled badges with white bold text: every pair clears WCAG AA
    // (the Material 500 amber/orange shades were under 3:1). The severity
    // is never conveyed by color alone — the label is right there.
    final (color, label) = switch (severity) {
      ReviewSeverity.mandatory => (const Color(0xFFB3261E), 'MUST'),
      ReviewSeverity.high => (const Color(0xFF8B4000), 'HIGH'),
      ReviewSeverity.medium => (const Color(0xFF7A5900), 'MED'),
      ReviewSeverity.low => (const Color(0xFF44474E), 'LOW'),
    };
    return Semantics(
      label: 'Severity: ${severity.name}',
      child: CircleAvatar(
        backgroundColor: color,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
