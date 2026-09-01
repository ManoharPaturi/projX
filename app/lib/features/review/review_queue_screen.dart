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
                  '${row.reasonCode}'
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

class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({required this.severity});

  final ReviewSeverity severity;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (severity) {
      ReviewSeverity.mandatory => (Colors.red, 'MUST'),
      ReviewSeverity.high => (Colors.orange, 'HIGH'),
      ReviewSeverity.medium => (Colors.amber, 'MED'),
      ReviewSeverity.low => (Colors.blueGrey, 'LOW'),
    };
    return CircleAvatar(
      backgroundColor: color,
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }
}
