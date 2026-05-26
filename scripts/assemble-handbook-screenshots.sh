#!/usr/bin/env bash
#
# Assemble the 52 handbook screenshots from the visual-regression Golden
# baselines. The flat `NN-name.png` output layout matches what
# docs/handbook/de/index.html links to (`<img src="../screenshots/NN-name.png">`
# — the relative path resolves to `docs/handbook/screenshots/NN-name.png`).
#
# Usage:
#   scripts/assemble-handbook-screenshots.sh <output-dir>
#
# Used by:
#   - Dockerfile.handbook (multi-stage build → /usr/share/nginx/html/screenshots/)
#   - local previews (`scripts/assemble-handbook-screenshots.sh docs/handbook/screenshots`
#     before opening docs/handbook/de/index.html; the target dir is git-ignored)
#
# Source of truth for every handbook page is one Golden PNG under
# `test/goldens/screens/<screen>/goldens/macos/<file>.png`. The mapping
# table below was established in the gap-audit on PR #568. When a new
# handbook page is added, append a row here AND add the corresponding
# Golden test — never source a screenshot from anywhere else.

set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <output-dir>" >&2
  exit 2
fi

OUT="$1"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GOLDENS_ROOT="$REPO_ROOT/test/goldens/screens"

mkdir -p "$OUT"

# handbook-name → relative golden path (under test/goldens/screens/)
# Keep this list in sync with .maestro/handbook/*.yaml (one entry per flow).
MAPPING=(
  "01-welcome=home/goldens/macos/home_page_default.png"
  "02-create-vs-restore=welcome/goldens/macos/welcome_page_ios.png"
  "03-software-wallet-terms=welcome/goldens/macos/welcome_page_second_step.png"
  "04-seed-hidden=create_wallet/goldens/macos/create_wallet_page_default.png"
  "05-seed-revealed=create_wallet/goldens/macos/create_wallet_page_revealed.png"
  "06-verify-seed=verify_seed/goldens/macos/verify_seed_page_default.png"
  "07-onboarding-completed=onboarding/goldens/macos/onboarding_completed_page_default.png"
  "08-pin-setup=pin/goldens/macos/setup_pin_page_default.png"
  "09-pin-confirm=pin/goldens/macos/setup_pin_page_confirming.png"
  "10-biometric-prompt=pin/goldens/macos/biometric_prompt_sheet_default.png"
  "11-dashboard=home/goldens/macos/home_page_loaded.png"
  "12-settings=settings/goldens/macos/settings_page_default.png"
  "13-settings-languages=settings_languages/goldens/macos/settings_languages_page_default.png"
  "14-settings-currency=settings_currencies/goldens/macos/settings_currencies_page_default.png"
  "15-settings-network=settings_network/goldens/macos/settings_network_page_default.png"
  "16-settings-wallet-address=settings_wallet_address/goldens/macos/settings_wallet_address_page_default.png"
  "17-settings-backup-pin=pin/goldens/macos/verify_pin_page_seed_backup.png"
  "18-settings-seed-hidden=settings_seed/goldens/macos/settings_seed_page_default.png"
  "19-settings-seed-revealed=settings_seed/goldens/macos/settings_seed_page_revealed.png"
  "20-settings-legal-documents=settings_legal_documents/goldens/macos/settings_legal_documents_page_default.png"
  "21-settings-aktionariat-documents=settings_legal_documents/goldens/macos/settings_aktionariat_documents_page_default.png"
  "22-settings-dfx-documents=settings_legal_documents/goldens/macos/settings_dfx_documents_page_default.png"
  "23-settings-contact=settings_contact/goldens/macos/settings_contact_page_default.png"
  "24-settings-delete-wallet=settings/goldens/macos/settings_confirm_logout_wallet_sheet_default.png"
  "25-restore-wallet=restore_wallet/goldens/macos/restore_wallet_page_default.png"
  "26-terms=legal/goldens/macos/legal_document_page_terms_loaded.png"
  "27-software-wallet-disclaimer-step-0=legal/goldens/macos/legal_disclaimer_step_0.png"
  "28-software-wallet-disclaimer-step-1=legal/goldens/macos/legal_disclaimer_step_1.png"
  "29-legal-documents-step=legal/goldens/macos/legal_documents_step_default.png"
  "30-legal-aktionariat-step=legal/goldens/macos/legal_aktionariat_step_default.png"
  "31-legal-dfx-step=legal/goldens/macos/legal_dfx_step_default.png"
  "32-restore-wallet-valid=restore_wallet/goldens/macos/restore_wallet_page_valid.png"
  "33-restore-wallet-invalid=restore_wallet/goldens/macos/restore_wallet_page_invalid.png"
  "34-verify-seed-completed=verify_seed/goldens/macos/verify_seed_page_all_entered.png"
  "35-dashboard-with-balance=dashboard/goldens/macos/dashboard_with_balance.png"
  "36-transaction-history=transaction_history/goldens/macos/transaction_history_page_with_transactions.png"
  "37-kyc-email-loading=kyc/goldens/macos/kyc_email_page_loading.png"
  "38-kyc-email-mismatch=kyc/goldens/macos/kyc_email_page_does_not_match.png"
  "39-kyc-email-error=kyc/goldens/macos/kyc_email_page_unknown_error.png"
  "40-kyc-registration-personal=kyc/goldens/macos/kyc_registration_personal_step_default.png"
  "41-kyc-registration-address=kyc/goldens/macos/kyc_registration_address_step_default.png"
  "42-settings-tax-report-loading=settings_tax_report/goldens/macos/settings_tax_report_page_loading.png"
  "43-settings-tax-report-failure=settings_tax_report/goldens/macos/settings_tax_report_page_failure.png"
  "44-buy-loading=buy/goldens/macos/buy_payment_info_loading.png"
  "45-buy-registration-required=buy/goldens/macos/buy_registration_required.png"
  "46-buy-kyc-required=buy/goldens/macos/buy_kyc_required.png"
  "47-buy-min-amount=buy/goldens/macos/buy_min_amount_not_met.png"
  "48-buy-unknown-error=buy/goldens/macos/buy_unknown_error.png"
  "49-sell-loading=sell/goldens/macos/sell_payment_info_loading.png"
  "50-sell-kyc-required=sell/goldens/macos/sell_kyc_required.png"
  "51-sell-min-amount=sell/goldens/macos/sell_min_amount_not_met.png"
  "52-sell-unknown-error=sell/goldens/macos/sell_unknown_error.png"
)

missing=()
for entry in "${MAPPING[@]}"; do
  name="${entry%%=*}"
  src_rel="${entry#*=}"
  src="$GOLDENS_ROOT/$src_rel"
  if [ ! -f "$src" ]; then
    missing+=("$name → $src_rel")
    continue
  fi
  cp "$src" "$OUT/$name.png"
done

if [ "${#missing[@]}" -gt 0 ]; then
  echo "error: handbook-screenshot sources missing from Goldens:" >&2
  printf '  %s\n' "${missing[@]}" >&2
  echo >&2
  echo "Run the visual-regression suite + commit baselines, or update the" >&2
  echo "mapping in $0 to point at an existing Golden." >&2
  exit 1
fi

count=$(ls -1 "$OUT"/*.png | wc -l | tr -d ' ')
echo "assembled $count handbook screenshots into $OUT"
