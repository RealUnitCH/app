/// Catalog of interactive surfaces that **must** pass the responsive matrix
/// (device × text scale × real tap). Adding a new bottom sheet / sticky-CTA
/// flow without a matrix gate is a review-blocking gap.
///
/// Coverage of *this bug class* (CTA outside hit-test bounds under small
/// viewport / large text) is "100%" when every entry here has a matrix test
/// and every new sticky-CTA surface is added before merge.
///
/// Line coverage % of the repo is a different metric — see docs/testing.md.
library;

/// One surface under the responsive layout contract.
class ResponsiveSurface {
  const ResponsiveSurface({
    required this.id,
    required this.description,
    required this.matrixTestPath,
    required this.usesScrollableActionsLayout,
  });

  final String id;
  final String description;

  /// Path under `test/` that runs [kFullResponsiveMatrix] (or a documented
  /// subset) with [expectFullyTappable] on primary CTAs.
  final String matrixTestPath;

  /// Production layout must use [ScrollableActionsLayout] (or equivalent
  /// Expanded + scroll + sticky actions).
  final bool usesScrollableActionsLayout;
}

/// Living catalog — extend when adding sticky-CTA sheets/pages.
const kResponsiveSurfaceCatalog = <ResponsiveSurface>[
  ResponsiveSurface(
    id: 'bitbox_connect_sheet',
    description: 'BitBox pairing bottom sheet (all button-bearing states)',
    matrixTestPath:
        'test/screens/hardware_connect_bitbox/connect_bitbox_responsive_matrix_test.dart',
    usesScrollableActionsLayout: true,
  ),
  // Next rollouts (tracked — add matrix tests when migrating layouts):
  // - welcome_page BitBox entry sheet (shares ConnectBitboxView — covered above)
  // - kyc link-wallet / registration BitBox sheet (shares ConnectBitboxView)
  // - sell confirm sheets
  // - pin setup / biometric sheets
  // - support create ticket
];
