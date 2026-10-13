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
}
