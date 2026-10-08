import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/repository/settings_repository.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/pay/pay_info_page.dart';
import 'package:realunit_wallet/screens/pay/pay_scan_page.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The software-wallet disclosure stays up when pay is not allowed, even if
/// some other install already stored [alreadySeen]. The unavailable notice
/// is not that disclosure.
bool showPayIntro({required bool payAllowed, required bool alreadySeen}) {
  if (!payAllowed) return true;
  return !alreadySeen;
}

bool readPayIntroSeen() {
  if (!getIt.isRegistered<SharedPreferences>() || !getIt.isRegistered<SettingsRepository>()) {
    return false;
  }
  return getIt<SettingsRepository>().payIntroSeen;
}

void markPayIntroSeen() {
  if (!getIt.isRegistered<SharedPreferences>() || !getIt.isRegistered<SettingsRepository>()) {
    return;
  }
  getIt<SettingsRepository>().payIntroSeen = true;
}

/// Chooses the pay screen once per visit. The stored flag is written after
/// this frame, so a rebuild while the disclosure is open does not replace it
/// with the scanner.
class PayIntroGate extends StatefulWidget {
  final String? initialPayload;

  const PayIntroGate({super.key, this.initialPayload});

  @override
  State<PayIntroGate> createState() => _PayIntroGateState();
}

class _PayIntroGateState extends State<PayIntroGate> {
  late final bool _showIntro;

  @override
  void initState() {
    super.initState();
    final payAllowed = context.read<HomeBloc>().state.openWallet?.walletType == WalletType.software;
    _showIntro = showPayIntro(
      payAllowed: payAllowed,
      alreadySeen: payAllowed && readPayIntroSeen(),
    );
    if (payAllowed && _showIntro) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        markPayIntroSeen();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_showIntro) {
      return PayScanPage(initialPayload: widget.initialPayload);
    }
    return PayInfoPage(initialPayload: widget.initialPayload);
  }
}
