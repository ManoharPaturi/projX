import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:omr_spec/omr_spec.dart';

import '../presets.dart';

/// `omr_cli template --preset A --out t.json` — emit the detection template
/// the pipeline consumes. The file is self-describing (specHash inside), and
/// loading code re-verifies the hash against the stored layout row.
final class TemplateCommand extends Command<int> {
  TemplateCommand() {
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
        help: 'Output path (defaults to stdout when omitted)',
      )
      ..addFlag(
        'summary',
        negatable: false,
        help: 'Print a one-line geometry summary instead of full JSON',
      );
  }

  @override
  String get name => 'template';

  @override
  String get description => 'Emit the compiled detection template JSON.';

  @override
  Future<int> run() async {
    final preset =
        SheetPreset.parse(argResults!['preset'] as String?) ?? SheetPreset.a;
    final out = argResults!['out'] as String?;
    final template = compileDetectionTemplate(preset.build());

    if (argResults!['summary'] as bool) {
      stdout.writeln('${template.layoutId} v${template.layoutVersion}: '
          'canvas ${template.canvasWidth}x${template.canvasHeight}px, '
          '${template.bubbles.length} bubbles, '
          '${template.fiducials.length} anchors, '
          '${template.timingBars.length} timing bars, '
          'capture floor ${template.minPxPerMmOnCapture.toStringAsFixed(1)} px/mm');
      return 0;
    }

    final json = template.toJsonString();
    if (out == null) {
      stdout.writeln(json);
    } else {
      final file = File(out);
      await file.parent.create(recursive: true);
      await file.writeAsString(json, flush: true);
      stdout.writeln('wrote $out (${template.bubbles.length} bubbles, '
          'specHash ${template.specHash.substring(0, 12)}…)');
    }
    // Touch the decoder so a template that cannot round-trip fails loudly at
    // emit time, not on a phone.
    final reloaded = DetectionTemplate.fromJsonString(json);
    if (reloaded.bubbles.length != template.bubbles.length) {
      stderr.writeln('template round-trip mismatch');
      return 1;
    }
    return 0;
  }
}
