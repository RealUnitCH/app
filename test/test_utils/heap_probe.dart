// Heap-probe harness — flutter_test extension snapshots the "reachable
// strings" portion of the Dart heap by walking a caller-supplied set
// of roots (and their `toString` projection), then pattern-matches
// against the BIP39 EN wordlist for any 12-word contiguous sequence.
// A real VM-level heap walk requires the VM service protocol and
// pulls a non-trivial dependency stack; the pragmatic harness here
// covers the realistic exposure surface — the cubits, app store,
// wallet handles, and rendered widget tree — without that ceremony.
//
// Usage:
//
//   await pumpEventQueue();
//   await expectNoBip39SequenceInHeap([appStore, walletService, ...]);
//
// The probe defines "BIP39 sequence" as: 12 contiguous tokens (split
// on whitespace) that are all present in the bip39 EN wordlist. This
// is intentionally generous — any 12 dictionary words side by side
// trips the probe, even if they don't validate as a checksummed
// mnemonic. The hostile case is "we found the actual user's seed in a
// place we didn't expect"; false positives there are tolerable, false
// negatives are not.

// ignore: implementation_imports
import 'package:bip39/src/wordlists/english.dart' as wordlist;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

/// Set form of the BIP39 EN wordlist for O(1) lookups during the
/// sequence scan.
final Set<String> _bip39Words = wordlist.WORDLIST.toSet();

/// Walks the caller-supplied [roots] (and their `toString()`
/// projection) and asserts no 12-word contiguous BIP39 sequence is
/// reachable. Awaits `WidgetsBinding.instance.endOfFrame` first so
/// any pending build / rebuild has settled — without this the probe
/// can race a still-rendering widget tree and miss seed text that is
/// about to be cleared.
Future<void> expectNoBip39SequenceInHeap(
  Iterable<Object?> roots, {
  String? reason,
}) async {
  // Give the frame loop a chance to settle. The mandate's failure-mode
  // notes call this out explicitly as a flake-mitigation.
  if (WidgetsBinding.instance.hasScheduledFrame) {
    await WidgetsBinding.instance.endOfFrame;
  }

  final buffer = StringBuffer();
  for (final root in roots) {
    if (root == null) continue;
    buffer.write(root.toString());
    buffer.write(' ');
  }

  final hit = findBip39Sequence(buffer.toString());
  expect(hit, isNull,
      reason: reason ??
          'BL-018: a 12-word BIP39 sequence reached the main-isolate heap '
              'via one of the inspected roots — hit: $hit');
}

/// Returns the first 12-word BIP39 sequence found in [text], or
/// `null` if none. Exposed so callers can use it inline (e.g. a
/// non-test assertion path) and so unit tests can exercise the
/// detector directly.
String? findBip39Sequence(String text) {
  // Split on any non-letter character. The bip39 EN wordlist is
  // pure lowercase a-z so this is the most permissive tokenisation
  // that still excludes obvious garbage like ":base64=stuff/...".
  final tokens = text
      .toLowerCase()
      .split(RegExp(r'[^a-z]+'))
      .where((t) => t.isNotEmpty)
      .toList();

  if (tokens.length < 12) return null;

  // Sliding window of 12.
  for (var i = 0; i + 12 <= tokens.length; i++) {
    var allBip39 = true;
    for (var j = 0; j < 12; j++) {
      if (!_bip39Words.contains(tokens[i + j])) {
        allBip39 = false;
        break;
      }
    }
    if (allBip39) {
      return tokens.sublist(i, i + 12).join(' ');
    }
  }
  return null;
}
