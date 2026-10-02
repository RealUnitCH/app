import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'holding_amount_catalog.dart';

const _holdingAmounts = ['77994', '85194', '78094', '85094'];

const _widgetRegressionPaths = <String, String>{
  'test/screens/dashboard/dashboard_portfolio_holding_update_test.dart':
      'BalanceCubit(',
  'test/screens/send/send_amount_holding_update_test.dart': 'SellBalanceCubit(',
  'test/screens/sell/sell_holding_update_test.dart': 'SellBalanceCubit(',
};

const _realCubitById = <String, String>{
  'dashboard_balance': 'BalanceCubit(',
  'sell_and_send_balance': 'SellBalanceCubit(',
};

void main() {
  test('every catalogued production and regression path exists on disk', () {
    for (final surface in kHoldingAmountCatalog) {
      expect(
        File(surface.productionPath).existsSync(),
        isTrue,
        reason:
            'Surface "${surface.id}" lists production file '
            '${surface.productionPath} but the file is missing',
      );
      expect(
        File(surface.regressionTestPath).existsSync(),
        isTrue,
        reason:
            'Surface "${surface.id}" lists regression test '
            '${surface.regressionTestPath} but the file is missing',
      );
    }
  });

  test(
    'every catalogued production file extends Cubit<Balance>',
    () {
      for (final surface in kHoldingAmountCatalog) {
        final contents = File(surface.productionPath).readAsStringSync();
        expect(
          contents.contains('extends Cubit<Balance>'),
          isTrue,
          reason:
              'Surface "${surface.id}" (${surface.productionPath}) no longer '
              'extends Cubit<Balance> — remove it from the catalog or restore '
              'the cubit',
        );
      }
    },
  );

  test(
    'every catalogued regression test constructs the real cubit and pushes a second amount',
    () {
      for (final surface in kHoldingAmountCatalog) {
        final contents = File(surface.regressionTestPath).readAsStringSync();
        final realCubit = _realCubitById[surface.id];
        expect(
          realCubit,
          isNotNull,
          reason:
              'Surface "${surface.id}" has no real-cubit constructor mapping '
              'in the catalog self-test — add it next to the catalog row',
        );
        expect(
          contents.contains(realCubit!),
          isTrue,
          reason:
              'Surface "${surface.id}" regression test '
              '(${surface.regressionTestPath}) must construct $realCubit',
        );
        expect(
          contents.contains('controller.add'),
          isTrue,
          reason:
              'Surface "${surface.id}" regression test '
              '(${surface.regressionTestPath}) must push via controller.add',
        );
        expect(
          contents.contains('BigInt.from'),
          isTrue,
          reason:
              'Surface "${surface.id}" regression test '
              '(${surface.regressionTestPath}) must use BigInt.from amounts',
        );
        expect(
          contents.contains('77994'),
          isTrue,
          reason:
              'Surface "${surface.id}" regression test '
              '(${surface.regressionTestPath}) must lock the incident first '
              'amount 77994',
        );
        expect(
          contents.contains('85194'),
          isTrue,
          reason:
              'Surface "${surface.id}" regression test '
              '(${surface.regressionTestPath}) must lock the incident Kauf '
              'amount 85194',
        );
        expect(
          contents.contains('BigInt.from(85194)'),
          isTrue,
          reason:
              'Surface "${surface.id}" regression test '
              '(${surface.regressionTestPath}) must push BigInt.from(85194) '
              'as the Kauf second amount (a mock/whenListen single-state test '
              'cannot satisfy this)',
        );
        final found = {
          for (final amount in _holdingAmounts)
            if (contents.contains(amount)) amount,
        };
        expect(
          found.length,
          greaterThan(1),
          reason:
              'Surface "${surface.id}" regression test '
              '(${surface.regressionTestPath}) must push more than one of '
              '{${_holdingAmounts.join(', ')}} so a first-emit-only test '
              'cannot satisfy the catalog',
        );
      }
    },
  );

  test('catalog is non-empty (holding-amount gate is active)', () {
    expect(kHoldingAmountCatalog, isNotEmpty);
  });

  test(
    'every extends Cubit<Balance> under lib/ is catalogued (discovery)',
    () {
      final catalogued = {
        for (final surface in kHoldingAmountCatalog) surface.productionPath,
      };
      final unlisted = <String>[];

      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) {
          continue;
        }
        // Normalize to forward-slash repo-relative path (macOS/Linux cwd =
        // package root under `flutter test`).
        final path = entity.path.replaceAll(r'\', '/');
        final contents = entity.readAsStringSync();
        if (!contents.contains('extends Cubit<Balance>')) {
          continue;
        }
        if (!catalogued.contains(path)) {
          unlisted.add(path);
        }
      }

      expect(
        unlisted,
        isEmpty,
        reason:
            'extends Cubit<Balance> types under lib/ missing from '
            'kHoldingAmountCatalog:\n${unlisted.join('\n')}\n'
            'Add a catalog entry and a real-cubit two-amount regression test',
      );
    },
  );

  test(
    'widget holding-update specs exist, use a real cubit, and push a second amount',
    () {
      for (final entry in _widgetRegressionPaths.entries) {
        final path = entry.key;
        final realCubit = entry.value;
        expect(
          File(path).existsSync(),
          isTrue,
          reason: 'Required widget holding-update spec $path is missing',
        );
        final contents = File(path).readAsStringSync();
        expect(
          contents.contains('controller.add') ||
              contents.contains('StreamController'),
          isTrue,
          reason:
              '$path must push a second amount via controller.add or a '
              'StreamController (a mock/whenListen single-state test cannot '
              'catch this bug class)',
        );
        final found = {
          for (final amount in _holdingAmounts)
            if (contents.contains(amount)) amount,
        };
        expect(
          found.length,
          greaterThan(1),
          reason:
              '$path must show a first amount then a different second amount '
              'among {${_holdingAmounts.join(', ')}}',
        );
        expect(
          contents.contains('MockCubit<Balance>'),
          isFalse,
          reason: '$path must not use MockCubit<Balance> as the cubit under test',
        );
        expect(
          contents.contains('MockBalanceCubit'),
          isFalse,
          reason: '$path must not use MockBalanceCubit as the cubit under test',
        );
        expect(
          contents.contains('MockSellBalanceCubit'),
          isFalse,
          reason:
              '$path must not use MockSellBalanceCubit as the cubit under test',
        );
        expect(
          contents.contains(realCubit),
          isTrue,
          reason: '$path must construct the real cubit $realCubit',
        );
      }
    },
  );

  test(
    'every holding-amount golden fileName is declared under test/goldens/',
    () {
      final declared = <String>{};
      for (final entity in Directory('test/goldens').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) {
          continue;
        }
        final contents = entity.readAsStringSync();
        for (final name in kHoldingAmountGoldenFileNames) {
          if (contents.contains("fileName: '$name'") ||
              contents.contains('fileName: "$name"')) {
            declared.add(name);
          }
        }
      }
      expect(
        declared,
        unorderedEquals(kHoldingAmountGoldenFileNames),
        reason:
            'Holding-amount golden fileNames missing from test/goldens:\n'
            '${kHoldingAmountGoldenFileNames.where((n) => !declared.contains(n)).join('\n')}',
      );
    },
  );
}
