// Verifies the tag → versionCode mapping in tool/generate_release_info.dart.
// We invoke the script as a subprocess (the same way Fastlane does) and read
// the canonical artefact `lib/generated/release_info.dart` back — stdout is
// not the authoritative output channel because `dart run` prepends "Running
// build hooks..." with no trailing newline.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _script = 'tool/generate_release_info.dart';
const _generated = 'lib/generated/release_info.dart';

class _ReleaseInfo {
  _ReleaseInfo(this.tag, this.marketing, this.versionCode, this.isStable);
  final String tag;
  final String marketing;
  final int versionCode;
  final bool isStable;
}

Future<_ReleaseInfo> _run({String? tag}) async {
  // Invoke the script directly (not via `dart run`) — the tool has no
  // package dependencies, so this skips the pub-resolve overhead and keeps
  // the suite fast.
  final args = <String>[_script, if (tag != null) '--tag=$tag'];
  final result = await Process.run('dart', args);
  expect(
    result.exitCode,
    0,
    reason: 'dart run failed (exit=${result.exitCode}): ${result.stderr}',
  );
  final contents = await File(_generated).readAsString();
  return _ReleaseInfo(
    RegExp(r"releaseTag = '([^']+)'").firstMatch(contents)!.group(1)!,
    RegExp(r"releaseMarketingVersion = '([^']+)'").firstMatch(contents)!.group(1)!,
    int.parse(RegExp(r'releaseVersionCode = (\d+)').firstMatch(contents)!.group(1)!),
    RegExp(r'releaseIsStable = (true|false)').firstMatch(contents)!.group(1) == 'true',
  );
}

void main() {
  // Restore the local-dev sentinel after each test so the working tree stays
  // build-able for whoever runs `flutter analyze` after the test suite.
  tearDownAll(() async {
    await _run();
  });

  group('generate_release_info: stable tags', () {
    test('v1.0.0 → versionCode 10_000_999, BETA_N = 999 (stable sentinel)',
        () async {
      final info = await _run(tag: 'v1.0.0');
      expect(info.tag, '1.0.0');
      expect(info.marketing, '1.0.0');
      expect(info.versionCode, 10000999);
      expect(info.isStable, isTrue);
    });

    test('v2.5.7 → versionCode 20_507_999', () async {
      final info = await _run(tag: 'v2.5.7');
      expect(info.versionCode, 20507999);
      expect(info.isStable, isTrue);
    });
  });

  group('generate_release_info: beta tags', () {
    test('v1.0.0-beta.2 → versionCode 10_000_002', () async {
      final info = await _run(tag: 'v1.0.0-beta.2');
      expect(info.tag, '1.0.0-beta.2');
      expect(info.marketing, '1.0.0');
      expect(info.versionCode, 10000002);
      expect(info.isStable, isFalse);
    });

    test('v0.0.42-beta.130 (old beta train) → 42130', () async {
      final info = await _run(tag: 'v0.0.42-beta.130');
      expect(info.versionCode, 42130);
    });

    test('stable strictly outranks every beta in the same X.Y.Z train',
        () async {
      final beta = (await _run(tag: 'v1.0.0-beta.998')).versionCode;
      final stable = (await _run(tag: 'v1.0.0')).versionCode;
      expect(stable, greaterThan(beta));
    });

    test('v1.0.1-beta.1 outranks v1.0.0 stable (next train)', () async {
      final stable100 = (await _run(tag: 'v1.0.0')).versionCode;
      final beta101 = (await _run(tag: 'v1.0.1-beta.1')).versionCode;
      expect(beta101, greaterThan(stable100));
    });
  });

  group('generate_release_info: dev sentinel', () {
    test('no --tag → dev sentinel, versionCode 0', () async {
      final info = await _run();
      expect(info.tag, 'dev');
      expect(info.marketing, '0.0.0');
      expect(info.versionCode, 0);
      expect(info.isStable, isFalse);
    });

    test('--tag=dev → same as no --tag', () async {
      final info = await _run(tag: 'dev');
      expect(info.tag, 'dev');
      expect(info.versionCode, 0);
    });
  });

  group('generate_release_info: error cases', () {
    test('malformed tag → non-zero exit', () async {
      final result = await Process.run('dart', [_script, '--tag=garbage']);
      expect(result.exitCode, isNot(0));
    });

    test('beta number > 998 → non-zero exit', () async {
      final result = await Process.run('dart', [_script, '--tag=v1.0.0-beta.999']);
      expect(result.exitCode, isNot(0));
    });

    test('major > 99 → non-zero exit', () async {
      final result = await Process.run('dart', [_script, '--tag=v100.0.0']);
      expect(result.exitCode, isNot(0));
    });

    test('release-candidate suffix is not supported → non-zero exit', () async {
      final result = await Process.run('dart', [_script, '--tag=v1.0.0-rc.1']);
      expect(result.exitCode, isNot(0));
    });
  });

  group('generate_release_info: platform-prefixed tags', () {
    test('android/v1.0.0-beta.4 strips the prefix and computes 10000004',
        () async {
      final info = await _run(tag: 'android/v1.0.0-beta.4');
      expect(info.tag, '1.0.0-beta.4');
      expect(info.versionCode, 10000004);
    });

    test('ios/v1.0.0 strips the prefix and computes 10000999', () async {
      final info = await _run(tag: 'ios/v1.0.0');
      expect(info.tag, '1.0.0');
      expect(info.versionCode, 10000999);
      expect(info.isStable, isTrue);
    });
  });
}
