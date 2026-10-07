import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:omr_app/src/version.dart';

void main() {
  test('About shows the version pubspec.yaml ships', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version:\s*([0-9.]+)',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1);
    expect(kAppVersion, version);
  });
}
