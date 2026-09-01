import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:omr_spec/omr_spec.dart';

import '../presets.dart';

/// `omr_cli pdf --preset A --out sheet.pdf` — render the printable sheet.
/// Always ends with the validator, so a broken preset cannot reach a printer.
final class PdfCommand extends Command<int> {
  PdfCommand() {
    argParser
      ..addOption(
        'preset',
        abbr: 'p',
        allowed: ['A', 'B', 'a', 'b'],
        defaultsTo: 'A',
      )
      ..addOption(
        'out',
        abbr: 'o',
        mandatory: true,
        help: 'Output .pdf path',
      )
      ..addOption('title', help: 'Exam title printed in the header band');
  }

  @override
  String get name => 'pdf';

  @override
  String get description => 'Render a preset sheet to a print-ready PDF.';

  @override
  Future<int> run() async {
    final preset =
        SheetPreset.parse(argResults!['preset'] as String?) ?? SheetPreset.a;
    final out = argResults!['out'] as String;
    final title = argResults!['title'] as String?;

    final spec = preset.build();
    final bytes = await compileSheetPdf(spec, examTitle: title);
    final file = File(out);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);

    final kb = (bytes.lengthInBytes / 1024).toStringAsFixed(1);
    stdout.writeln('wrote $out ($kb KB) — ${spec.layoutId} v'
        '${spec.layoutVersion}, specHash ${specSha256(spec).substring(0, 12)}…');
    return 0;
  }
}
