import 'dart:math' as math;
import 'dart:typed_data';

import 'package:omr_spec/omr_spec.dart' show DetectionTemplate;

import '../cv/opencv_service.dart' show OpencvService;
import '../pipeline/pipeline.dart' show OmrPipeline, StillEvaluation;
import 'synthetic_sheet.dart' show InkMark, inkAt, renderSheetPhoto;

/// One capture size's benchmark outcome: how long a still took from JPEG
/// bytes to a read, and whether every bubbled field read back right.
class PipelineBenchResult {
  const PipelineBenchResult({
    required this.width,
    required this.height,
    required this.jpegBytes,
    required this.decodeMs,
    required this.pipelineMs,
    required this.stageMsMean,
    required this.fieldsChecked,
    required this.fieldsWrong,
  });

  final int width;
  final int height;
  final int jpegBytes;

  /// Per timed run, in run order.
  final List<double> decodeMs;
  final List<double> pipelineMs;

  /// Mean per-run time of each pipeline trace stage.
  final Map<String, double> stageMsMean;

  /// Over all runs: answers + roll + set.
  final int fieldsChecked;
  final int fieldsWrong;

  List<double> get totalMs => [
    for (var i = 0; i < decodeMs.length; i++) decodeMs[i] + pipelineMs[i],
  ];

  double get accuracy =>
      fieldsChecked == 0 ? 0 : (fieldsChecked - fieldsWrong) / fieldsChecked;

  String get slowestStage {
    if (stageMsMean.isEmpty) return '-';
    return (stageMsMean.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .first
        .key;
  }

  Map<String, Object?> toJson() => {
    'width': width,
    'height': height,
    'jpegBytes': jpegBytes,
    'decodeMsMedian': percentile(decodeMs, 0.5),
    'pipelineMsMedian': percentile(pipelineMs, 0.5),
    'totalMsMedian': percentile(totalMs, 0.5),
    'totalMsP95': percentile(totalMs, 0.95),
    'stageMsMean': stageMsMean,
    'fieldsChecked': fieldsChecked,
    'fieldsWrong': fieldsWrong,
  };
}

/// Nearest-rank percentile; [p] in 0..1.
double percentile(List<double> xs, double p) {
  if (xs.isEmpty) return 0;
  final s = [...xs]..sort();
  return s[((s.length - 1) * p).round()];
}

/// Times JPEG decode + [OmrPipeline] over a synthetic sheet with a random
/// answer on every question, a valid roll and a set, photographed at
/// [width]×[height] with ±[noise] grey levels of sensor-like noise.
///
/// The one untimed warm-up run absorbs first-call costs (native library
/// load, JIT), which are per-process, not per-sheet. Shared by
/// `omr_cli bench` and the CI accuracy test so both measure the same thing.
PipelineBenchResult runPipelineBench(
  OpencvService cv,
  DetectionTemplate template, {
  required int width,
  required int height,
  int runs = 5,
  int noise = 6,
  int seed = 7,
  int registrationWidth = 640,
}) {
  final sheet = _BenchSheet.random(template, math.Random(seed));
  final gray = renderSheetPhoto(
    cv,
    template,
    imageWidth: width,
    imageHeight: height,
    marks: sheet.marks,
  );
  _addNoise(gray, noise, math.Random(seed + width));
  final jpeg = cv.encodeGrayJpeg(width, height, gray);
  final pipeline = OmrPipeline(
    cv: cv,
    template: template,
    registrationWidth: registrationWidth,
  );

  pipeline.evaluateStill(jpeg);

  final decodeMs = <double>[];
  final pipelineMs = <double>[];
  final stageMicros = <String, int>{};
  var wrong = 0, checked = 0;
  for (var i = 0; i < runs; i++) {
    final watch = Stopwatch()..start();
    final result = pipeline.evaluateStill(jpeg);
    watch.stop();
    var decodeMicros = 0;
    for (final t in result.trace) {
      if (t.stage == 'decode') {
        decodeMicros += t.elapsedMicros;
      } else {
        stageMicros[t.stage] = (stageMicros[t.stage] ?? 0) + t.elapsedMicros;
      }
    }
    decodeMs.add(decodeMicros / 1000);
    pipelineMs.add((watch.elapsedMicroseconds - decodeMicros) / 1000);
    final score = sheet.score(result);
    wrong += score.wrong;
    checked += score.checked;
  }
  return PipelineBenchResult(
    width: width,
    height: height,
    jpegBytes: jpeg.length,
    decodeMs: decodeMs,
    pipelineMs: pipelineMs,
    stageMsMean: {
      for (final e in stageMicros.entries)
        e.key: runs == 0 ? 0 : e.value / runs / 1000,
    },
    fieldsChecked: checked,
    fieldsWrong: wrong,
  );
}

/// One random marked sheet: an option per question, plus a fixed valid
/// roll and set, so every field has a known right answer.
class _BenchSheet {
  _BenchSheet(this.marks, this.answers, this.roll, this.set);

  factory _BenchSheet.random(DetectionTemplate template, math.Random rng) {
    final marks = <InkMark>[];
    final answers = <String, String>{};
    for (final key in template.questionFieldKeys) {
      final options = [
        for (final b in template.bubbles)
          if (b.fieldKey == key) b.optionValue,
      ];
      final pick = options[rng.nextInt(options.length)];
      answers[key] = pick;
      marks.add(inkAt(template, key, pick));
    }
    // 0000073 + check digit 6 — pipeline_test's happy-path roll.
    const roll = '00000736';
    final rollKeys = template.rollFieldKeys;
    final usable = rollKeys.length == roll.length;
    if (usable) {
      for (var i = 0; i < rollKeys.length; i++) {
        marks.add(inkAt(template, rollKeys[i], roll[i]));
      }
    }
    String? set;
    if (template.setFieldKey.isNotEmpty) {
      set = 'B';
      marks.add(inkAt(template, template.setFieldKey, set));
    }
    return _BenchSheet(marks, answers, usable ? '0000073' : null, set);
  }

  final List<InkMark> marks;
  final Map<String, String> answers;
  final String? roll;
  final String? set;

  ({int checked, int wrong}) score(StillEvaluation result) {
    var checked = 0, wrong = 0;
    for (final e in answers.entries) {
      checked++;
      final chosen = result.read.responses[e.key]?.chosen;
      if (chosen == null || chosen.length != 1 || chosen.first != e.value) {
        wrong++;
      }
    }
    if (roll != null) {
      checked++;
      if (result.read.rollNoRead != roll) wrong++;
    }
    if (set != null) {
      checked++;
      if (result.read.setCodeRead != set) wrong++;
    }
    return (checked: checked, wrong: wrong);
  }
}

void _addNoise(Uint8List gray, int amplitude, math.Random rng) {
  if (amplitude <= 0) return;
  final span = amplitude * 2 + 1;
  for (var i = 0; i < gray.length; i++) {
    final v = gray[i] + rng.nextInt(span) - amplitude;
    gray[i] = v < 0 ? 0 : (v > 255 ? 255 : v);
  }
}
