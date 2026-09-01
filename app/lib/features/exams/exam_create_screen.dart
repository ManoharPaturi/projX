import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:omr_data/omr_data.dart';
import 'package:omr_spec/omr_spec.dart';
import 'package:provider/provider.dart';

import '../../src/app_state.dart';
import '../keys/key_editor_screen.dart';

/// Grading presets offered at exam setup (ids from `ScoringPresets`; the
/// engine resolves params from its registry — marking is data, not code).
const List<({String id, String label})> kGradingPresets = [
  (id: 'neet-jee-main-4n1p', label: 'NEET / JEE Main — +4 / −1 / 0'),
  (
    id: 'jee-adv-multi-2026',
    label: 'JEE Adv multi-correct 2026 — partial, −1',
  ),
  (
    id: 'jee-adv-multi-legacy',
    label: 'JEE Adv multi-correct (legacy) — −2',
  ),
];

/// Plan §6 screen 2 — pick a layout from the generated spec library, bind a
/// grading preset, land a draft exam, then go straight to key entry.
class ExamCreateScreen extends StatefulWidget {
  const ExamCreateScreen({super.key});

  static const String routeName = '/exam/new';

  @override
  State<ExamCreateScreen> createState() => _ExamCreateScreenState();
}

class _ExamCreateScreenState extends State<ExamCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  List<SheetLayout>? _layouts;
  SheetLayout? _layout;
  String _preset = kGradingPresets.first.id;
  DateTime? _heldAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    state.db.layoutsDao
        .activeForTenant(state.tenantId)
        .then((rows) {
            if (!mounted) {
              return;
            }
            setState(() {
              _layouts = rows;
              _layout = rows.isNotEmpty ? rows.first : null;
            });
          });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<int> _questionCount(SheetLayout row) async {
    final spec = SheetSpec.fromJson(
      jsonDecode(row.specJson) as Map<String, dynamic>,
    );
    return spec.sections.fold<int>(
      0,
      (sum, section) => sum + expandLabels(section.questionLabels).length,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _layout == null) {
      return;
    }
    setState(() => _saving = true);
    final state = context.read<AppState>();
    try {
      final totalQuestions = await _questionCount(_layout!);
      final examId = await state.db.examsDao.createExam(
        tenantId: state.tenantId,
        instituteId: state.instituteId,
        name: _nameController.text.trim(),
        sheetLayoutId: _layout!.id,
        totalQuestions: totalQuestions,
        heldAt: _heldAt,
        gradingConfigJson: jsonEncode(<String, Object?>{
          'preset': _preset,
        }),
      );
      state.refresh();
      if (!mounted) {
        return;
      }
      // Key entry is the immediate next step for a fresh exam.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => KeyEditorScreen(examId: examId),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New exam')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Exam name',
                hintText: 'JEE Mock 1',
              ),
              textInputAction: TextInputAction.done,
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Held on'),
              subtitle: Text(
                _heldAt == null
                    ? 'Not set'
                    : '${_heldAt!.day}/${_heldAt!.month}/${_heldAt!.year}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => _heldAt = picked);
                }
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<SheetLayout>(
              decoration: const InputDecoration(labelText: 'Sheet layout'),
              items: [
                for (final row in _layouts ?? <SheetLayout>[])
                  DropdownMenuItem(
                    value: row,
                    child: Text(
                      '${row.layoutId} v${row.layoutVersion}',
                    ),
                  ),
              ],
              initialValue: _layout,
              onChanged: (row) => setState(() => _layout = row),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Marking scheme'),
              items: [
                for (final preset in kGradingPresets)
                  DropdownMenuItem(value: preset.id, child: Text(preset.label)),
              ],
              initialValue: _preset,
              onChanged: (id) => setState(() => _preset = id!),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create and enter answer key'),
            ),
          ],
        ),
      ),
    );
  }
}
