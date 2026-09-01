import 'package:flutter/material.dart';
import 'package:omr_data/omr_data.dart';
import 'package:provider/provider.dart';

import '../../src/app_state.dart';

/// Plan §6 screen 12. Honest MVP: identity + storage are real, the threshold
/// presets / retention policy surfaces are stubbed until the calibration
/// flow (M4) lands.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const String routeName = '/settings';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.school_outlined),
                  title: const Text('Institute'),
                  subtitle: Text('${state.instituteName} (id ${state.instituteId})'),
                ),
                ListTile(
                  leading: const Icon(Icons.business_outlined),
                  title: const Text('Tenant'),
                  subtitle: Text('${state.tenantId} · single-tenant MVP'),
                ),
              ],
            ),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.tune),
                  title: const Text('Threshold preset'),
                  subtitle: const Text('Normal (Strict / Relaxed arrive with '
                      'calibration, M4)'),
                  enabled: false,
                ),
                ListTile(
                  leading: const Icon(Icons.auto_delete_outlined),
                  title: const Text('Image retention'),
                  subtitle: const Text('Warped grayscale + thumbnails kept; '
                      '12MP originals dropped after the grace window (M4)'),
                  enabled: false,
                ),
              ],
            ),
          ),
          Card(
            child: Column(
              children: [
                _StorageTile(version: state.version),
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('About'),
                  subtitle: Text('OMR Evaluator · on-device, offline-first · '
                      'reports reproduce from stored reads'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StorageTile extends StatelessWidget {
  const _StorageTile({required this.version});

  final int version;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return FutureBuilder<Map<ScanStatus, int>>(
      key: ValueKey('storage-$version'),
      future: () async {
        final rows = await state.db.scansDao.pendingReview();
        return <ScanStatus, int>{
          ScanStatus.needsReview: rows.length,
        };
      }(),
      builder: (context, snapshot) {
        return ListTile(
          leading: const Icon(Icons.storage_outlined),
          title: const Text('Local database'),
          subtitle: Text(
            'SQLite, on this device only. '
            '${snapshot.data?[ScanStatus.needsReview] ?? 0} sheets awaiting '
            'review.',
          ),
        );
      },
    );
  }
}
