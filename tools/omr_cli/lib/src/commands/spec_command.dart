import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:omr_spec/omr_spec.dart';

import '../presets.dart';

/// `omr_cli spec --preset A` — print the canonical spec JSON, its hash and
/// the layout identity. What you diff when reviewing a layout change.
final class SpecCommand extends Command<int> {
  SpecCommand() {
    argParser
      ..addOption(
        'preset',
        abbr: 'p',
        allowed: ['A', 'B', 'a', 'b'],
        defaultsTo: 'A',
        help: 'Sheet preset: A = Standard-90, B = NEET-180',
      )
      ..addFlag('hash', negatable: false, help: 'Print only the spec hash');
  }

  @override
  String get name => 'spec';

  @override
  String get description => 'Print a preset sheet spec (canonical JSON + hash).';

  @override
  Future<int> run() async {
    final preset =
        SheetPreset.parse(argResults!['preset'] as String?) ?? SheetPreset.a;
    final spec = preset.build();

    if (argResults!['hash'] as bool) {
      stdout.writeln(specSha256(spec));
      return 0;
    }

    stdout.writeln('# ${preset.label} — ${preset.description}');
    stdout.writeln('# layoutId=${spec.layoutId} '
        'layoutVersion=${spec.layoutVersion} '
        'qr=${spec.qrPayload}');
    stdout.writeln('# specHash=${specSha256(spec)}');
    stdout.writeln('# fields: '
        '${spec.questionFieldKeysFor()} questions, '
        'roll ${spec.rollDigits}+${spec.rollChecksum ? 1 : 0}, '
        'set ${spec.setValues.join('/')}');
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(spec.toJson()));
    return 0;
  }
}

extension on SheetSpec {
  int questionFieldKeysFor() => fieldBlocks
      .where((b) => b.blockType == BlockType.mcq)
      .fold(0, (n, b) => n + b.fields.length);
}
