import 'package:flutter/material.dart';
import 'package:omr_data/omr_data.dart';
import 'package:provider/provider.dart';

import '../../src/app_state.dart';

/// Plan §6 screen 12: identity, capture strictness preset, image retention
/// policy, storage. The strictness choice here is what the still pipeline
/// reads on the next capture ([SettingsDao] → [ThresholdConfig]).
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
                  subtitle: Text(
                    '${state.instituteName} (id ${state.instituteId})',
                  ),
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
                _StrictnessTile(version: state.version),
                _RetentionTile(version: state.version),
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
                  subtitle: Text(
                    'OMR Evaluator · on-device, offline-first · '
                    'reports reproduce from stored reads',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Strict / Normal / Relaxed — shifts the capture quality gates (blur floor
/// especially); takes effect from the next sheet scanned.
class _StrictnessTile extends StatelessWidget {
  const _StrictnessTile({required this.version});

  final int version;

  static const _labels = {
    'strict': 'Strict — highest blur floor, more retakes',
    'normal': 'Normal — the default preset',
    'relaxed': 'Relaxed — accepts fainter sheets, review more often',
  };

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return FutureBuilder<TenantSettings>(
      key: ValueKey('strictness-$version'),
      future: SettingsDao(state.db).settingsFor(state.tenantId),
      builder: (context, snapshot) {
        final current = snapshot.data?.strictness ?? 'normal';
        return ListTile(
          leading: const Icon(Icons.tune),
          title: const Text('Threshold preset'),
          subtitle: Text(_labels[current] ?? current),
          enabled: snapshot.hasData,
          onTap: () => _choose(context, state, current),
        );
      },
    );
  }

  Future<void> _choose(
    BuildContext context,
    AppState state,
    String current,
  ) async {
    final picked = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Threshold preset'),
        children: [
          for (final entry in _labels.entries)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, entry.key),
              child: Row(
                children: [
                  Icon(
                    entry.key == current
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(entry.value)),
                ],
              ),
            ),
        ],
      ),
    );
    if (picked == null || picked == current) return;
    await SettingsDao(
      state.db,
    ).write(tenantId: state.tenantId, strictness: picked);
    state.refresh();
  }
}

/// How long captured 12MP originals are kept before the boot sweep deletes
/// them (warped grayscale + annotated thumbnails are kept forever — they are
/// the review substrate).
class _RetentionTile extends StatelessWidget {
  const _RetentionTile({required this.version});

  final int version;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return FutureBuilder<TenantSettings>(
      key: ValueKey('retention-$version'),
      future: SettingsDao(state.db).settingsFor(state.tenantId),
      builder: (context, snapshot) {
        final days = snapshot.data?.retentionGraceDays ?? 7;
        return ListTile(
          leading: const Icon(Icons.auto_delete_outlined),
          title: const Text('Image retention'),
          subtitle: Text(
            '12MP originals dropped $days day'
            '${days == 1 ? '' : 's'} after capture; warped + thumbnails '
            'kept',
          ),
          enabled: snapshot.hasData,
          onTap: () => _choose(context, state, days),
        );
      },
    );
  }

  Future<void> _choose(BuildContext context, AppState state, int days) async {
    final controller = TextEditingController(text: '$days');
    final picked = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Originals grace window (days)'),
        content: TextField(
          key: const Key('retention-days-field'),
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (picked == null || picked <= 0) return;
    await SettingsDao(
      state.db,
    ).write(tenantId: state.tenantId, retentionGraceDays: picked);
    state.refresh();
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
        return <ScanStatus, int>{ScanStatus.needsReview: rows.length};
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
