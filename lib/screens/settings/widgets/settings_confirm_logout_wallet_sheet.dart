import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';
import 'package:realunit_wallet/widgets/handlebars.dart';

class SettingsConfirmLogoutWalletSheet extends StatefulWidget {
  const SettingsConfirmLogoutWalletSheet({super.key});

  @override
  State<SettingsConfirmLogoutWalletSheet> createState() => _SettingsConfirmLogoutWalletSheetState();
}

class _SettingsConfirmLogoutWalletSheetState extends State<SettingsConfirmLogoutWalletSheet> {
  bool isChecked = false;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Handlebars.horizontal(context, margin: const EdgeInsets.only(top: 5), width: 36),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 30.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.privacy_tip_rounded,
                  color: RealUnitColors.realUnitBlue,
                  size: 64,
                ),
                const SizedBox(height: 28),
                Text(
                  S.of(context).realunitWalletLogout,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    height: 30 / 26,
                    letterSpacing: 26 * -0.02,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  S.of(context).realunitWalletLogoutSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: RealUnitColors.neutral500,
                    fontSize: 14,
                    height: 18 / 14,
                    letterSpacing: 0.0,
                  ),
                ),
                const SizedBox(height: 28),
                // The whole checkbox row is wrapped in a single Semantics node
                // with a stable `identifier` so Maestro can target it via
                // `tapOn: id:` on iOS (handbook flow 25). `toggled` mirrors
                // the checkbox state so the tap-target is treated as a
                // checkbox in the a11y tree. The opaque GestureDetector
                // enlarges the tap surface to the full row — same UX as
                // the native iOS pattern — which means a missed-by-a-pixel
                // coordinate tap (XCUITest tap-loss on Apple Silicon +
                // iOS 26, mobile-dev-inc/maestro#3137) still toggles the
                // box. AbsorbPointer on the inner Checkbox lets the outer
                // GestureDetector own every hit-test, so we don't run the
                // toggle twice when the tap happens directly on the box.
                Semantics(
                  identifier: 'wallet-logout-confirm-checkbox',
                  toggled: isChecked,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => isChecked = !isChecked),
                    child: Row(
                      spacing: 12,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: AbsorbPointer(
                            child: Checkbox(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              checkColor: RealUnitColors.basic.white,
                              activeColor: RealUnitColors.green,
                              value: isChecked,
                              onChanged: (value) => setState(() => isChecked = value ?? false),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            S.of(context).realunitWalletLogoutCheck,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                              height: 16 / 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                Row(
                  spacing: 12.0,
                  children: [
                    Expanded(
                      child: AppFilledButton(
                        variant: .secondary,
                        onPressed: () => context.pop(),
                        label: S.of(context).close,
                      ),
                    ),
                    Expanded(
                      child: AppFilledButton(
                        onPressed: isChecked ? () => context.pop(true) : null,
                        label: S.of(context).logout,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
