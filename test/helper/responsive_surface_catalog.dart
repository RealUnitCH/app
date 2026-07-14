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
  ResponsiveSurface(
    id: 'dashboard_page',
    description: 'Dashboard main page',
    matrixTestPath: 'test/screens/dashboard/dashboard_responsive_matrix_test.dart',
    productionPath: 'lib/screens/dashboard/dashboard_page.dart',
  ),
  ResponsiveSurface(
    id: 'create_wallet_view',
    description: 'Create wallet view',
    matrixTestPath: 'test/screens/create_wallet/create_wallet_responsive_matrix_test.dart',
    productionPath: 'lib/screens/create_wallet/create_wallet_view.dart',
  ),
  ResponsiveSurface(
    id: 'verify_pin_page',
    description: 'Verify PIN page',
    matrixTestPath: 'test/screens/pin/verify_pin_responsive_matrix_test.dart',
    productionPath: 'lib/screens/pin/verify_pin_page.dart',
  ),
  ResponsiveSurface(
    id: 'kyc_completed_page',
    description: 'KYC completed status page',
    matrixTestPath:
        'test/screens/kyc/subpages/kyc_status_pages_responsive_matrix_test.dart',
    productionPath: 'lib/screens/kyc/subpages/kyc_completed_page.dart',
  ),
  ResponsiveSurface(
    id: 'kyc_manual_review_page',
    description: 'KYC manual review status page',
    matrixTestPath:
        'test/screens/kyc/subpages/kyc_status_pages_responsive_matrix_test.dart',
    productionPath: 'lib/screens/kyc/subpages/kyc_manual_review_page.dart',
  ),
  ResponsiveSurface(
    id: 'kyc_pending_page',
    description: 'KYC pending status page',
    matrixTestPath:
        'test/screens/kyc/subpages/kyc_status_pages_responsive_matrix_test.dart',
    productionPath: 'lib/screens/kyc/subpages/kyc_pending_page.dart',
  ),
  ResponsiveSurface(
    id: 'kyc_account_merge_page',
    description: 'KYC account merge page',
    matrixTestPath: 'test/screens/kyc/kyc_merge_link_responsive_matrix_test.dart',
    productionPath: 'lib/screens/kyc/subpages/kyc_account_merge_page.dart',
  ),
  ResponsiveSurface(
    id: 'kyc_merge_processing_page',
    description: 'KYC merge processing page',
    matrixTestPath: 'test/screens/kyc/kyc_merge_link_responsive_matrix_test.dart',
    productionPath: 'lib/screens/kyc/subpages/kyc_merge_processing_page.dart',
  ),
  ResponsiveSurface(
    id: 'kyc_link_wallet_page',
    description: 'KYC link wallet page',
    matrixTestPath: 'test/screens/kyc/kyc_merge_link_responsive_matrix_test.dart',
    productionPath: 'lib/screens/kyc/steps/link_wallet/kyc_link_wallet_page.dart',
  ),
  ResponsiveSurface(
    id: 'kyc_financial_data_questions_page',
    description: 'KYC financial data questions page',
    matrixTestPath:
        'test/screens/kyc/steps/financial_data/kyc_financial_data_responsive_matrix_test.dart',
    productionPath:
        'lib/screens/kyc/steps/financial_data/subpages/kyc_financial_data_questions_page.dart',
  ),
  ResponsiveSurface(
    id: 'onboarding_completed_page',
    description: 'Onboarding completed page',
    matrixTestPath:
        'test/screens/onboarding/onboarding_completed_responsive_matrix_test.dart',
    productionPath: 'lib/screens/onboarding/onboarding_completed_page.dart',
  ),
  ResponsiveSurface(
    id: 'support_create_ticket_page',
    description: 'Support create ticket page',
    matrixTestPath:
        'test/screens/support/support_create_ticket_responsive_matrix_test.dart',
    productionPath: 'lib/screens/support/subpages/support_create_ticket_page.dart',
  ),
  ResponsiveSurface(
    id: 'settings_edit_address_page',
    description: 'Settings edit address form',
    matrixTestPath:
        'test/screens/settings_user_data/settings_user_data_responsive_matrix_test.dart',
    productionPath:
        'lib/screens/settings_user_data/subpages/edit_address/settings_edit_address_page.dart',
  ),
  ResponsiveSurface(
    id: 'settings_edit_name_page',
    description: 'Settings edit name form',
    matrixTestPath:
        'test/screens/settings_user_data/settings_user_data_responsive_matrix_test.dart',
    productionPath:
        'lib/screens/settings_user_data/subpages/edit_name/settings_edit_name_page.dart',
  ),
  ResponsiveSurface(
    id: 'settings_edit_phone_number_page',
    description: 'Settings edit phone number form',
    matrixTestPath:
        'test/screens/settings_user_data/settings_user_data_responsive_matrix_test.dart',
    productionPath:
        'lib/screens/settings_user_data/subpages/edit_phone_number/settings_edit_phone_number_page.dart',
  ),
  ResponsiveSurface(
    id: 'settings_edit_pending_page',
    description: 'Settings edit pending status page',
    matrixTestPath:
        'test/screens/settings_user_data/settings_user_data_responsive_matrix_test.dart',
    productionPath:
        'lib/screens/settings_user_data/subpages/others/settings_edit_pending_page.dart',
  ),
  ResponsiveSurface(
    id: 'settings_edit_failure_page',
    description: 'Settings edit failure status page',
    matrixTestPath:
        'test/screens/settings_user_data/settings_user_data_responsive_matrix_test.dart',
    productionPath:
        'lib/screens/settings_user_data/subpages/others/settings_edit_failure_page.dart',
  ),
  // Migration covers 18 surfaces (bitbox_connect_sheet + 17 above). Confirmed
  // still NOT migrated (no ScrollableActionsLayout in these files): welcome_page,
  // sell_confirm_sheet / sell_executed_sheet, setup_pin_page /
  // forgot_pin_bottom_sheet / enable_biometric_bottom_sheet. Not exhaustive.
];
