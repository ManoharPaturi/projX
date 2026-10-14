import 'package:flutter_test/flutter_test.dart';
import 'package:omr_app/features/reports/reports_screen.dart';
import 'package:omr_data/omr_data.dart';

void main() {
  test('shared report files carry the exam name and say what they are', () {
    expect(
      reportFileName(
        examName: 'Mock 1',
        type: ReportJobType.consolidated,
        keyVersion: 2,
        format: 'pdf',
      ),
      'Mock 1 - Class results (key 2).pdf',
    );
    expect(
      reportFileName(
        examName: ' JEE  Mains: 12/10 ',
        type: ReportJobType.excel,
        keyVersion: 1,
        format: 'xlsx',
      ),
      'JEE Mains 1210 - Marks workbook (key 1).xlsx',
      reason: 'path separators and colons would break the file write',
    );
    expect(
      reportFileName(
        examName: '//',
        type: ReportJobType.csv,
        keyVersion: 1,
        format: 'csv',
      ),
      'Marks (key 1).csv',
    );
  });

  test('marksheets are named after the exam and the roll', () {
    expect(
      marksheetFileName(examName: 'Mock 1', rollNo: '1234'),
      'Mock 1 - Marksheet 1234.pdf',
    );
    expect(
      marksheetFileName(examName: 'JEE: 12/10', rollNo: '0042'),
      'JEE 1210 - Marksheet 0042.pdf',
    );
    expect(marksheetFileName(examName: '', rollNo: '7'), 'Marksheet 7.pdf');
  });
}
