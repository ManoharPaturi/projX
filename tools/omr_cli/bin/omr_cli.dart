import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:omr_cli/src/commands/pdf_command.dart';
import 'package:omr_cli/src/commands/spec_command.dart';
import 'package:omr_cli/src/commands/template_command.dart';

/// Headless OMR tooling.
///
/// ```
///   omr_cli spec     --preset A                     # spec JSON + hash
///   omr_cli pdf      --preset A --out sheet.pdf
///   omr_cli template --preset A --out std90.template.json
/// ```
Future<void> main(List<String> arguments) async {
  final runner = CommandRunner<int>(
    'omr_cli',
    'Render OMR sheet PDFs and detection templates; golden-corpus harness.',
  )
    ..addCommand(SpecCommand())
    ..addCommand(PdfCommand())
    ..addCommand(TemplateCommand());

  try {
    final code = await runner.run(arguments) ?? 0;
    exit(code);
  } on UsageException catch (e) {
    stderr.writeln('$e');
    exit(64);
  }
}
