import 'package:flutter/material.dart';
import 'package:omr_data/omr_data.dart';
import 'package:provider/provider.dart';

import '../../src/app_state.dart';
import '../../src/labels.dart';
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
      appBar: AppBar(title: const Text('Sheets to check')),
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
                  SizedBox(height: 4),
                  Text('Every scanned sheet has been checked.'),
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
                  row.rollNoRead == null
                      ? 'Roll number not read'
                      : 'Roll ${row.rollNoRead}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${reviewReasonLabel(row.reasonCode)}'
                  '${row.setCodeRead == null ? '' : ' · Set ${row.setCodeRead}'}',
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

class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({required this.severity});

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
