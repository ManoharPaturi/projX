import 'package:flutter_test/flutter_test.dart';
import 'package:omr_app/features/students/roster_screen.dart';

/// What a pasted student list becomes. Spreadsheet copies are
/// tab-separated; typed lists are CSV; header rows come in many spellings.
void main() {
  List<(String, String?, String?)> parse(String text) => [
    for (final e in parseRosterPaste(text)) (e.rollNo, e.name, e.batch),
  ];

  test('header rows in any spelling are skipped, not imported', () {
    for (final header in ['roll', 'Roll No', 'Roll Number', 'ROLL,NAME']) {
      expect(parse('$header\n1001,Aarav'), [
        ('1001', 'Aarav', null),
      ], reason: header);
    }
  });

  test('a list without a header keeps its first student', () {
    expect(parse('1001,Aarav\n1002,Diya,B'), [
      ('1001', 'Aarav', null),
      ('1002', 'Diya', 'B'),
    ]);
  });

  test('tab-separated spreadsheet rows keep commas inside names', () {
    expect(parse('Roll No\tName\tBatch\n1001\tSharma, Aarav\tA'), [
      ('1001', 'Sharma, Aarav', 'A'),
    ]);
  });

  test('quoted CSV names keep their commas; blank lines are ignored', () {
    expect(parse('1001,"Sharma, Aarav"\n\n  \n1002'), [
      ('1001', 'Sharma, Aarav', null),
      ('1002', null, null),
    ]);
  });

  test('Devanagari names survive', () {
    expect(parse('1001\tआरव शर्मा'), [('1001', 'आरव शर्मा', null)]);
  });
}
