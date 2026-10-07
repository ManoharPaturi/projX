import 'package:flutter/material.dart';
import 'package:omr_data/omr_data.dart';
import 'package:provider/provider.dart';

import '../../src/app_state.dart';
import '../../src/version.dart';

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
            child: ListTile(
              leading: const Icon(Icons.school_outlined),
              title: const Text('Institute name'),
              subtitle: Text(state.instituteName),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => editInstituteName(context),
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
                  title: Text('About OMR Evaluator'),
                  subtitle: Text(
                    'Version $kAppVersion · works fully offline · all data '
                    'stays on this phone',
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
    'strict': 'Strict — asks for sharper photos, more retakes',
    'normal': 'Normal — recommended for most institutes',
    'relaxed': 'Relaxed — accepts softer photos, more sheets to check',
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
          title: const Text('Photo quality check'),
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
        title: const Text('Photo quality check'),
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
          title: const Text('Keep full-size photos for'),
          subtitle: Text(
            '$days day${days == 1 ? '' : 's'} — then deleted to save space. '
            'Answer data and small previews are always kept.',
          ),
          enabled: snapshot.hasData,
          onTap: () => _choose(context, state, days),
        );
      },
    );
  }

  Future<void> _choose(BuildContext context, AppState state, int days) async {
    final picked = await showDialog<int>(
      context: context,
      builder: (_) => _RetentionDialog(initial: days),
    );
    if (picked == null) return;
    await SettingsDao(
      state.db,
    ).write(tenantId: state.tenantId, retentionGraceDays: picked);
    state.refresh();
  }
}

/// Owns its controller (disposed after the close animation) and refuses
/// values outside 1–365 days with a message instead of silently ignoring.
class _RetentionDialog extends StatefulWidget {
  const _RetentionDialog({required this.initial});

  final int initial;

  @override
  State<_RetentionDialog> createState() => _RetentionDialogState();
}

class _RetentionDialogState extends State<_RetentionDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: '${widget.initial}',
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final days = int.tryParse(_controller.text.trim());
    if (days == null || days < 1 || days > 365) {
      setState(() => _error = 'Enter a number of days from 1 to 365');
      return;
    }
    Navigator.pop(context, days);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Keep full-size photos for (days)'),
      content: TextField(
        key: const Key('retention-days-field'),
        controller: _controller,
        keyboardType: TextInputType.number,
        autofocus: true,
        decoration: InputDecoration(errorText: _error),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
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
        return <ScanStatus, int>{ScanStatus.needsReview: rows.length};
      }(),
      builder: (context, snapshot) {
        return ListTile(
          leading: const Icon(Icons.storage_outlined),
          title: const Text('Data on this phone'),
          subtitle: Text(
            'Stored only on this device. '
            '${snapshot.data?[ScanStatus.needsReview] ?? 0} sheet(s) waiting '
            'to be checked.',
          ),
        );
      },
    );
  }
}

/// Shown from Settings and the getting-started checklist.
Future<void> editInstituteName(BuildContext context) async {
  final state = context.read<AppState>();
  final name = await showDialog<String>(
    context: context,
    builder: (_) => _InstituteNameDialog(
      initial: state.instituteNamed ? state.instituteName : '',
    ),
  );
  if (name != null) await state.renameInstitute(name);
}

/// Owns its controller, so it is disposed only after the closing
/// animation stops using it.
class _InstituteNameDialog extends StatefulWidget {
  const _InstituteNameDialog({required this.initial});

  final String initial;

  @override
  State<_InstituteNameDialog> createState() => _InstituteNameDialogState();
}

class _InstituteNameDialogState extends State<_InstituteNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Institute name'),
      content: TextField(
        key: const Key('institute-name-field'),
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          hintText: 'e.g. Sunrise Coaching Centre',
          helperText: 'Printed on every marksheet and report',
        ),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
