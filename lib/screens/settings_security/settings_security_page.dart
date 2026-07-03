import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/biometric_service.dart';
import 'package:realunit_wallet/screens/pin/verify_pin_page.dart';
import 'package:realunit_wallet/screens/settings/widgets/settings_section.dart';
import 'package:realunit_wallet/screens/settings_security/cubits/settings_security_cubit.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/setup/routing/routes/pin_routes.dart';
import 'package:realunit_wallet/setup/routing/routes/settings_routes.dart';
import 'package:realunit_wallet/styles/colors.dart';

/// Route arguments for the PIN-change route. Carries the follow-up the Security
/// page runs once a new PIN is stored (pop back + success feedback), so the
/// router builder stays declarative and owns no navigation logic.
class ChangePinParams {
  final VoidCallback onCompleted;

  const ChangePinParams({required this.onCompleted});
}

class SettingsSecurityPage extends StatelessWidget {
  const SettingsSecurityPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => SettingsSecurityCubit(getIt<BiometricService>())..init(),
    child: const SettingsSecurityView(),
  );
}

class SettingsSecurityView extends StatelessWidget {
  const SettingsSecurityView({super.key});

  static const _forwardIcon = Icon(
    Icons.arrow_forward_ios,
    size: 20,
    color: RealUnitColors.realUnitBlack,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(S.of(context).settingsSecurity),
    ),
    body: SingleChildScrollView(
      child: BlocConsumer<SettingsSecurityCubit, SettingsSecurityState>(
        listenWhen: (_, state) => state.error != null,
        listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).settingsBiometricUnlockFailed),
            backgroundColor: RealUnitColors.status.red600,
          ),
        ),
        builder: (context, state) => SettingsSections(
          settings: [
            SettingOption(
              title: S.of(context).settingsChangePin,
              trailing: _forwardIcon,
              onTap: () => _onChangePinTap(context),
            ),
            if (state.biometricSupported)
              SettingOption(
                title: S.of(context).settingsBiometricUnlock,
                trailing: _BiometricTrailing(
                  enabled: state.biometricEnabled,
                  isBusy: state.isBusy,
                ),
                onTap: () => context.read<SettingsSecurityCubit>().toggleBiometrics(
                  enabled: !state.biometricEnabled,
                ),
              ),
          ],
        ),
      ),
    ),
  );

  void _onChangePinTap(BuildContext context) => context.pushNamed(
    PinRoutes.gate,
    extra: VerifyPinParams(
      description: S.of(context).settingsChangePinVerifyDescription,
      // The verify gate also offers biometric re-auth, so a user who forgot
      // their PIN but has working biometrics can still reach the change flow.
      onAuthenticated: () => context.pushReplacementNamed(
        SettingsRoutes.changePin,
        extra: ChangePinParams(onCompleted: () => _onPinChanged(context)),
      ),
    ),
  );

  void _onPinChanged(BuildContext context) {
    context.pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(S.of(context).pinChangeSuccess),
        backgroundColor: RealUnitColors.green,
      ),
    );
  }
}

/// Trailing control for the biometric-unlock tile. The tile row owns the tap
/// (toggling via the cubit), so the switch is presentation-only; while a
/// round-trip is in flight it is replaced by a spinner.
class _BiometricTrailing extends StatelessWidget {
  final bool enabled;
  final bool isBusy;

  const _BiometricTrailing({required this.enabled, required this.isBusy});

  @override
  Widget build(BuildContext context) {
    if (isBusy) {
      return const SizedBox(
        width: 40,
        height: 24,
        child: Center(child: CupertinoActivityIndicator()),
      );
    }
    return IgnorePointer(
      child: Switch(
        value: enabled,
        onChanged: (_) {},
        activeTrackColor: RealUnitColors.realUnitBlue,
      ),
    );
  }
}
