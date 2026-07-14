/// Catalog of interactive surfaces that **must** pass the responsive matrix
/// (device × text scale × real tap). Adding a new bottom sheet / sticky-CTA
/// flow without a matrix gate is a review-blocking gap.
///
/// This is a living list, not a proof of completeness: the self-test in
/// `responsive_surface_catalog_test.dart` verifies that every listed surface's
/// matrix test file exists, its production file exists, and that production
/// file actually references [ScrollableActionsLayout]. It cannot verify that
/// every sticky-CTA surface in the app has been listed here — that is a
/// review responsibility for every new sticky-CTA surface.
///
/// Line coverage % of the repo is a different metric — see docs/testing.md.
library;

/// One surface under the responsive layout contract.
class ResponsiveSurface {
  const ResponsiveSurface({
    required this.id,
    required this.description,
    required this.matrixTestPath,
    required this.productionPath,
  });

  final String id;
  final String description;

  /// Path under `test/` that runs [kFullResponsiveMatrix] (or a documented
  /// subset) with [expectFullyTappable] on primary CTAs.
  final String matrixTestPath;

  /// Path under `lib/` of the production widget that must use
  /// [ScrollableActionsLayout] (or equivalent Expanded + scroll + sticky
  /// actions).
  final String productionPath;
}

/// Living catalog — extend when adding sticky-CTA sheets/pages.
const kResponsiveSurfaceCatalog = <ResponsiveSurface>[
  ResponsiveSurface(
    id: 'bitbox_connect_sheet',
    description: 'BitBox pairing bottom sheet (all button-bearing states)',
    matrixTestPath:
        'test/screens/hardware_connect_bitbox/connect_bitbox_responsive_matrix_test.dart',
    productionPath: 'lib/screens/hardware_connect_bitbox/widgets/connect_content.dart',
  ),
  // Next rollouts (tracked — add matrix tests when migrating layouts):
  // - welcome_page BitBox entry sheet (shares ConnectBitboxView — covered above)
  // - kyc link-wallet / registration BitBox sheet (shares ConnectBitboxView)
  // - sell confirm sheets
  // - pin setup / biometric sheets
  // - support create ticket
];
