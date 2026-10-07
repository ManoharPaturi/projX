import 'package:flutter/material.dart';

/// Plain-language how-to, reachable from the menu at any time. Written for
/// an operator who has never used OMR software: short steps, no jargon.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const String routeName = '/help';

  static const List<(String, String)> _steps = [
    (
      'Add your students',
      'Menu → Students → "Add student", or "Paste a list" to copy roll '
          'numbers and names from Excel. Each student gets a check digit — '
          'they write it in the last roll-number column of the sheet.',
    ),
    (
      'Create an exam',
      'Home → "New exam". Pick the answer sheet type and the marking '
          'scheme (for example +4 right, −1 wrong).',
    ),
    (
      'Enter the answer key',
      'Tap the correct option for every question — or "Type answers" to '
          'type the key as letters (ABDC…) — then "Save answer key". Using '
          'several question paper sets? Fill a tab for each set.',
    ),
    (
      'Print the answer sheets',
      'Open the exam → "Print answer sheets". Use A4 paper at actual size '
          '(100%). Students fill bubbles fully with a dark pen or pencil.',
    ),
    (
      'Scan the sheets',
      'Home → "Scan answer sheets". Lay each sheet flat in good light and '
          'hold the phone above it. When the green frame appears and the '
          'ring fills, the photo is taken by itself. Marks appear at once.',
    ),
    (
      'Check flagged sheets',
      'Some sheets need a quick human look (a faint mark, two marks, an '
          'unclear roll number). Open "Sheets to check", look at the paper '
          'sheet, and tap what the student really marked.',
    ),
    (
      'Share results',
      'Open the exam → Results to see ranks, or Reports to make a class '
          'list PDF or Excel file and share it on WhatsApp or email.',
    ),
  ];

  static const List<(String, String)> _faq = [
    (
      'The scanner keeps saying "move closer" or "hold still"',
      'Fill the frame with the whole sheet, keep all four black corner '
          'squares visible, and rest your elbows on the table.',
    ),
    (
      'A mark is wrong because the answer key had a mistake',
      'Fix the key and save it again. Every sheet is re-marked '
          'automatically — nobody needs to be scanned again.',
    ),
    (
      'Sheets from a new printer or photocopier read poorly',
      'Menu → Printer check. It tells you whether that printer\'s sheets '
          'are safe to use and suggests a setting if not.',
    ),
    (
      'Do I need internet?',
      'No. Everything — scanning, marking and reports — works offline. '
          'Data stays on this phone.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('How to use')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('The whole job in 7 steps', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          for (var i = 0; i < _steps.length; i++)
            Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(
                  _steps[i].$1,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_steps[i].$2),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text('Common questions', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final (question, answer) in _faq)
            Card(
              child: ExpansionTile(
                title: Text(question),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedAlignment: Alignment.centerLeft,
                children: [Text(answer)],
              ),
            ),
        ],
      ),
    );
  }
}
