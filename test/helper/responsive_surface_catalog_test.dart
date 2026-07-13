import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'responsive_surface_catalog.dart';

void main() {
  test('every catalogued responsive surface has a matrix test file on disk', () {
    for (final surface in kResponsiveSurfaceCatalog) {
      final file = File(surface.matrixTestPath);
      expect(
        file.existsSync(),
        isTrue,
        reason:
            'Surface "${surface.id}" lists matrix test '
            '${surface.matrixTestPath} but the file is missing',
      );
    }
  });

  test('every catalogued surface has a production file on disk', () {
    for (final surface in kResponsiveSurfaceCatalog) {
      final file = File(surface.productionPath);
      expect(
        file.existsSync(),
        isTrue,
        reason:
            'Surface "${surface.id}" lists production file '
            '${surface.productionPath} but the file is missing',
      );
    }
  });

  test('every catalogued surface actually uses ScrollableActionsLayout', () {
    for (final surface in kResponsiveSurfaceCatalog) {
      final contents = File(surface.productionPath).readAsStringSync();
      expect(
        RegExp(r'ScrollableActionsLayout\s*\(').hasMatch(contents),
        isTrue,
        reason:
            'Surface "${surface.id}" (${surface.productionPath}) no longer '
            'references ScrollableActionsLayout — the responsive-layout '
            'contract regressed',
      );
    }
  });

  test('catalog is non-empty (responsive gate is active)', () {
    expect(kResponsiveSurfaceCatalog, isNotEmpty);
  });
}
