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
      expect(
        surface.usesScrollableActionsLayout,
        isTrue,
        reason:
            'Surface "${surface.id}" must use ScrollableActionsLayout '
            '(or be explicitly re-reviewed before setting false)',
      );
    }
  });

  test('catalog is non-empty (responsive gate is active)', () {
    expect(kResponsiveSurfaceCatalog, isNotEmpty);
  });
}
