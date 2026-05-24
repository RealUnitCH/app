// Unit tests for the heap-probe detector. Pin the false-positive /
// false-negative behaviour so a future refactor of `findBip39Sequence`
// can't quietly weaken the contract.

import 'package:flutter_test/flutter_test.dart';

import 'heap_probe.dart';

void main() {
  group('findBip39Sequence', () {
    test('returns null for an empty input', () {
      expect(findBip39Sequence(''), isNull);
    });

    test('returns null for fewer than 12 tokens (regardless of dictionary match)',
        () {
      expect(
        findBip39Sequence('abandon ability able about above absent'),
        isNull,
        reason: 'a partial sequence under 12 words is not a mnemonic',
      );
    });

    test('detects 12 contiguous BIP39 words', () {
      const seed =
          'abandon ability able about above absent absorb abstract absurd abuse access accident';
      expect(findBip39Sequence(seed), seed,
          reason: 'any 12 contiguous dictionary words trip the probe — '
              'this is the failure case the probe exists to catch');
    });

    test('detects a BIP39 sequence embedded in surrounding garbage', () {
      const noise =
          'this is some prefix junk abandon ability able about above absent absorb abstract absurd abuse access accident and trailing noise here';
      expect(findBip39Sequence(noise), contains('abandon ability able'));
    });

    test('ignores 11 dictionary words + 1 non-dictionary word', () {
      const broken =
          'abandon ability able about above absent absorb abstract absurd abuse access NOTAWORD';
      expect(findBip39Sequence(broken), isNull,
          reason: 'a single non-dictionary token breaks the sliding window — '
              'the probe must not flag a near-miss as a hit');
    });

    test('walks across multiple windows to find the first hit', () {
      const multi =
          'one two three four five six seven eight nine ten eleven twelve '
          'abandon ability able about above absent absorb abstract absurd abuse access accident';
      expect(findBip39Sequence(multi), contains('abandon ability able'));
    });

    test('tokenises on non-letter chars so url-encoded payloads still split',
        () {
      // Pin the tokenisation: a base64-blob containing slashes and
      // colons must not glue dictionary words together. The probe
      // splits on every non-letter run.
      const url =
          'https://api.dfx.swiss/abandon/ability:able-about|above_absent.absorb~abstract+absurd*abuse=access?accident';
      expect(findBip39Sequence(url), isNotNull,
          reason: 'tokenisation must aggressively split non-letter glue');
    });

    test('lowercases input so capitalised mnemonics are detected', () {
      const cased =
          'Abandon Ability Able About Above Absent Absorb Abstract Absurd Abuse Access Accident';
      expect(findBip39Sequence(cased), isNotNull,
          reason: 'the detector must be case-insensitive — a UI label that '
              'capitalises the first letter of every word is still a leak');
    });
  });
}
