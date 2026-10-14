import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:omr_detect/omr_detect.dart';
import 'package:omr_detect/testing.dart';
import 'package:omr_spec/omr_spec.dart';

import '../presets.dart';

/// `omr_cli bench` — times the still pipeline (JPEG decode + stages 2–10)
/// over synthetic marked sheets at several capture sizes, and checks every
/// answer, the roll and the set decode correctly.
///
/// ```
///   omr_cli bench --sizes 1200x1600,3000x4000 --runs 5
///   omr_cli bench --json            # machine-readable, one object per size
/// ```
///
/// Exit code 1 when any read is wrong, or when `--max-ms` is given and a
/// size's median total exceeds it. Numbers are host numbers: compare runs
/// on the same machine, and read phone timings from `[scan-timing]` logs.
final class BenchCommand extends Command<int> {
  BenchCommand() {
    argParser
      ..addOption(
        'preset',
        abbr: 'p',
        allowed: ['A', 'B', 'a', 'b'],
        defaultsTo: 'A',
      )
      ..addOption(
        'sizes',
        help: 'Comma-separated WxH photo sizes (portrait).',
        defaultsTo: '1080x1440,1200x1600,1536x2048,2250x3000,3000x4000',
      )
      ..addOption('runs', defaultsTo: '5', help: 'Timed runs per size.')
      ..addOption(
        'noise',
        defaultsTo: '6',
        help: 'Uniform pixel noise amplitude (0 = clean render).',
      )
      ..addOption('seed', defaultsTo: '7')
      ..addOption(
        'max-ms',
        help: "Fail when a size's median decode+pipeline exceeds this.",
      )
      ..addFlag('json', negatable: false, help: 'Print JSON lines.');
  }

  @override
  String get name => 'bench';

  @override
  String get description =>
      'Time decode + pipeline on synthetic sheets and check accuracy.';

  @override
  Future<int> run() async {
    final args = argResults!;
    final preset =
        SheetPreset.parse(args['preset'] as String?) ?? SheetPreset.a;
    final template = compileDetectionTemplate(preset.build());
    final runs = int.parse(args['runs'] as String);
    final noise = int.parse(args['noise'] as String);
    final seed = int.parse(args['seed'] as String);
    final maxMs = switch (args['max-ms'] as String?) {
      null => null,
      final s => double.parse(s),
    };
    final json = args['json'] as bool;
    final sizes = [
      for (final s in (args['sizes'] as String).split(','))
        if (s.trim().isNotEmpty) _parseSize(s.trim()),
    ];

    final cv = OpencvDartImpl();
    var failed = false;
    if (!json) {
      stdout.writeln(
        '${template.layoutId}: ${template.questionFieldKeys.length} questions, '
        '$runs runs per size, noise ±$noise',
      );
      stdout.writeln(
        '${'size'.padRight(11)} ${'MP'.padLeft(5)} ${'jpeg KB'.padLeft(8)} '
        '${'decode'.padLeft(8)} ${'pipeline'.padLeft(9)} '
        '${'total'.padLeft(8)} ${'p95'.padLeft(8)}  accuracy  slowest stage',
      );
    }

    for (final (w, h) in sizes) {
      final r = runPipelineBench(
        cv,
        template,
        width: w,
        height: h,
        runs: runs,
        noise: noise,
        seed: seed,
      );
      final median = percentile(r.totalMs, 0.5);
      if (r.fieldsWrong > 0 || (maxMs != null && median > maxMs)) {
        failed = true;
      }
      if (json) {
        stdout.writeln(jsonEncode(r.toJson()));
      } else {
        stdout.writeln(
          '${'${w}x$h'.padRight(11)} '
          '${(w * h / 1e6).toStringAsFixed(1).padLeft(5)} '
          '${(r.jpegBytes / 1024).round().toString().padLeft(8)} '
          '${_ms(percentile(r.decodeMs, 0.5)).padLeft(8)} '
          '${_ms(percentile(r.pipelineMs, 0.5)).padLeft(9)} '
          '${_ms(median).padLeft(8)} '
          '${_ms(percentile(r.totalMs, 0.95)).padLeft(8)}  '
          '${(r.accuracy * 100).toStringAsFixed(1).padLeft(7)}%  '
          '${r.slowestStage}',
        );
      }
    }
    return failed ? 1 : 0;
  }
}

(int, int) _parseSize(String s) {
  final parts = s.toLowerCase().split('x');
  if (parts.length != 2) {
    throw UsageException('size "$s" is not WxH', '');
  }
  return (int.parse(parts[0]), int.parse(parts[1]));
}

String _ms(double ms) => '${ms.toStringAsFixed(0)} ms';
