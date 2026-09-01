import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
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
      appBar: AppBar(title: const Text('Students')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.paste),
        label: const Text('Import CSV'),
        onPressed: _showImportDialog,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search by roll number',
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
                  return const Center(
                    child: Text(
                      'No students yet.\nImport a roster: roll,name,batch per line.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: roster.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final student = roster[index];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text(
                        student.rollNo,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: student.name == null && student.batch == null
                          ? null
                          : Text([
                              if (student.name != null) student.name!,
                              if (student.batch != null) student.batch!,
                          ].join(' · ')),
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
    _pasteController.text = 'roll,name,batch\nR001,Aarav,Batch-A';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Paste roster CSV'),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: _pasteController,
            maxLines: 10,
            decoration: const InputDecoration(
              hintText: 'roll,name,batch\nR001,Aarav,Batch-A',
            ),
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

  Future<RosterImportResult?> _import(
    AppState state,
    String text,
  ) async {
    final rows = Csv().decoder.convert(text);
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
}
