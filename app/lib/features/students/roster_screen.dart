import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:omr_core/omr_core.dart'
    show isScannableRoll, kSheetRollDigits, rollCheckDigit;
import 'package:omr_data/omr_data.dart';
import 'package:provider/provider.dart';

import '../../src/app_state.dart';

/// Plan §6 screen 4 — roster with duplicate-detecting CSV import.
///
/// Roll number is the student key (DPDP); names/batches are optional. Import
/// is additive and never rewrites an enrolled row — the DAO reports every
/// skip and this screen shows the full accounting.
class RosterScreen extends StatefulWidget {
  const RosterScreen({super.key});

  static const String routeName = '/roster';

  @override
  State<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends State<RosterScreen> {
  final TextEditingController _pasteController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.paste),
            label: const Text('Paste a list'),
            onPressed: _showImportDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add student'),
        onPressed: _showAddDialog,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Find by roll number',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Student>>(
              key: ValueKey('roster-${state.version}-$_query'),
              future: state.db.studentsDao.rosterFor(
                state.instituteId,
                query: _query.isEmpty ? null : _query,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final roster = snapshot.data!;
                if (roster.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No students yet.\n\nTap "Add student" to add one, or '
                      '"Paste a list" to add many from a spreadsheet.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: roster.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final student = roster[index];
                    final check = rollCheckDigit(student.rollNo);
                    return ListTile(
                      trailing: PopupMenuButton<String>(
                        tooltip: 'More for roll ${student.rollNo}',
                        onSelected: (_) => _confirmDelete(student),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Remove student'),
                          ),
                        ],
                      ),
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text(
                        student.rollNo,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        [
                          if (student.name != null) student.name!,
                          if (student.batch != null) student.batch!,
                          check == null
                              ? 'Cannot be bubbled: use digits only, up to '
                                    '$kSheetRollDigits'
                              : 'Check digit $check',
                        ].join(' · '),
                        style: check == null
                            ? TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showImportDialog() async {
    // A tiny starter so the format is discoverable on first use.
    _pasteController.text = 'roll,name,batch\n1001,Aarav,Batch-A';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Paste a student list'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'One student per line: roll number, name, batch. Copy the '
                'columns straight from Excel or Google Sheets.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pasteController,
                maxLines: 10,
                decoration: const InputDecoration(
                  hintText: 'roll,name,batch\n1001,Aarav,Batch-A',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final state = context.read<AppState>();
              final result = await _import(state, _pasteController.text);
              if (!mounted || !dialogContext.mounted) {
                return;
              }
              Navigator.pop(dialogContext);
              if (result != null) {
                state.refresh();
                await _showResult(result);
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  Future<RosterImportResult?> _import(AppState state, String text) async {
    // Spreadsheet copies arrive tab-separated; treat tabs as commas.
    final rows = Csv().decoder.convert(text.replaceAll('\t', ','));
    final entries = <RosterEntry>[];
    for (final row in rows) {
      if (row.isEmpty) {
        continue;
      }
      final cells = [for (final cell in row) '$cell'.trim()];
      // Skip a header row: anything whose first cell is not roll-like.
      if (entries.isEmpty &&
          cells.isNotEmpty &&
          cells.first.toLowerCase() == 'roll') {
        continue;
      }
      if (cells.every((cell) => cell.isEmpty)) {
        continue;
      }
      entries.add(
        RosterEntry(
          rollNo: cells.isNotEmpty ? cells[0] : '',
          name: cells.length > 1 && cells[1].isNotEmpty ? cells[1] : null,
          batch: cells.length > 2 && cells[2].isNotEmpty ? cells[2] : null,
        ),
      );
    }
    if (entries.isEmpty) {
      return null;
    }
    return state.db.studentsDao.importRoster(
      state.tenantId,
      state.instituteId,
      entries,
    );
  }

  Future<void> _showResult(RosterImportResult result) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          result.clean ? 'Imported ${result.imported}' : 'Import finished',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Imported: ${result.imported}'),
            if (result.duplicatesInFile.isNotEmpty)
              Text(
                'Repeated in file (first copy kept): '
                '${result.duplicatesInFile.join(', ')}',
              ),
            if (result.existingRolls.isNotEmpty)
              Text(
                'Already on roster (not changed): '
                '${result.existingRolls.join(', ')}',
              ),
            if (result.invalidRolls.isNotEmpty)
              Text('Invalid rows: ${result.invalidRolls.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddDialog() async {
    final state = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final entry = await showDialog<RosterEntry>(
      context: context,
      builder: (_) => const _AddStudentDialog(),
    );
    if (entry == null) return;
    final result = await state.db.studentsDao.addStudent(
      state.tenantId,
      state.instituteId,
      entry,
    );
    state.refresh();
    messenger.showSnackBar(
      SnackBar(
        content: Text(switch (result) {
          AddStudentResult.added => 'Added roll ${entry.rollNo}',
          AddStudentResult.duplicate =>
            'Roll ${entry.rollNo} is already on the list',
          AddStudentResult.invalid => 'Enter a roll number',
        }),
      ),
    );
  }

  Future<void> _confirmDelete(Student student) async {
    final state = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove roll ${student.rollNo}?'),
        content: const Text(
          'Students who already have scanned sheets cannot be removed, so '
          'their results stay correct.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final removed = await state.db.studentsDao.deleteStudent(student.id);
    state.refresh();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          removed
              ? 'Removed roll ${student.rollNo}'
              : 'Roll ${student.rollNo} has scanned sheets and was kept',
        ),
      ),
    );
  }
}

class _AddStudentDialog extends StatefulWidget {
  const _AddStudentDialog();

  @override
  State<_AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<_AddStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _roll = TextEditingController();
  final _name = TextEditingController();
  final _batch = TextEditingController();

  @override
  void dispose() {
    _roll.dispose();
    _name.dispose();
    _batch.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    String? optional(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    Navigator.pop(
      context,
      RosterEntry(
        rollNo: _roll.text.trim(),
        name: optional(_name),
        batch: optional(_batch),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final check = rollCheckDigit(_roll.text);
    return AlertDialog(
      title: const Text('Add student'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('add-roll-field'),
              controller: _roll,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Roll number',
                helperText: check == null
                    ? 'Digits only, up to $kSheetRollDigits'
                    : 'Check digit for the sheet: $check',
              ),
              onChanged: (_) => setState(() {}),
              validator: (value) {
                final roll = value?.trim() ?? '';
                if (roll.isEmpty) return 'Enter the roll number';
                if (!isScannableRoll(roll)) {
                  return 'Use digits only, up to $kSheetRollDigits';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('add-name-field'),
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name (optional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _batch,
              decoration: const InputDecoration(labelText: 'Batch (optional)'),
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
