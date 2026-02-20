import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/di.dart';
import 'package:realunit_wallet/models/blockchain.dart';
import 'package:realunit_wallet/packages/open_crypto_pay/models.dart';
import 'package:realunit_wallet/screens/buy/buy_page.dart';
import 'package:realunit_wallet/screens/create_wallet/create_wallet_page.dart';
import 'package:realunit_wallet/screens/dashboard/dashboard_page.dart';
import 'package:realunit_wallet/screens/home/home.dart';
import 'package:realunit_wallet/screens/kyc/kyc_page_manager.dart';
import 'package:realunit_wallet/screens/legal/legal_disclaimer_page.dart';
import 'package:realunit_wallet/screens/legal/subpages/legal_document_page.dart';
import 'package:realunit_wallet/screens/onboarding/onboarding_completed_page.dart';
import 'package:realunit_wallet/screens/pin/setup_pin_page.dart';
import 'package:realunit_wallet/screens/pin/verify_pin_page.dart';
import 'package:realunit_wallet/screens/receive/receive_page.dart';
import 'package:realunit_wallet/screens/restore_wallet/restore_wallet_page.dart';
import 'package:realunit_wallet/screens/sell/sell_page.dart';
import 'package:realunit_wallet/screens/send/send_page.dart';
import 'package:realunit_wallet/screens/send_invoice/send_invoice_page.dart';
import 'package:realunit_wallet/screens/settings/settings_page.dart';
import 'package:realunit_wallet/screens/settings_contact/settings_contact_page.dart';
import 'package:realunit_wallet/screens/settings_currencies/settings_currencies_page.dart';
import 'package:realunit_wallet/screens/settings_edit_node/settings_edit_node_page.dart';
import 'package:realunit_wallet/screens/settings_languages/settings_languages_page.dart';
import 'package:realunit_wallet/screens/settings_network/settings_network_page.dart';
import 'package:realunit_wallet/screens/settings_nodes/settings_nodes_page.dart';
import 'package:realunit_wallet/screens/settings_seed/settings_seed_page.dart';
import 'package:realunit_wallet/screens/settings_tax_report/settings_tax_report_page.dart';
import 'package:realunit_wallet/screens/terms/terms_page.dart';
import 'package:realunit_wallet/screens/transaction_history/transaction_history_page.dart';
import 'package:realunit_wallet/screens/transaction_sent/transaction_sent_page.dart';
import 'package:realunit_wallet/screens/web_view/web_view_page.dart';
import 'package:realunit_wallet/screens/welcome/welcome_page.dart';

import 'generated/i18n.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void setupRouter() {
  getIt.registerSingleton(
    GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: '/',
      // observers: [GoRouterObserver()],
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: TermsPage.route,
          builder: (context, state) => const TermsPage(),
        ),
        GoRoute(
          path: '/welcome',
          builder: (context, state) => const WelcomePage(),
        ),
        GoRoute(
          path: '/wallet/create',
          builder: (context, state) => const CreateWalletPage(),
        ),
        GoRoute(
          path: '/wallet/restore',
          builder: (context, state) => const RestoreWalletPage(),
        ),
        GoRoute(
          path: OnboardingCompletedPage.route,
          builder: (context, state) => const OnboardingCompletedPage(),
        ),
        GoRoute(
          path: SetupPinPage.route,
          builder: (context, state) => const SetupPinPage(),
        ),
        GoRoute(
          path: VerifyPinPage.route,
          builder: (context, state) => const VerifyPinPage(),
        ),
        GoRoute(
          path: DashboardPage.routeName,
          builder: (context, state) => const DashboardPage(),
          routes: [
            GoRoute(
              path: '/transactionHistory',
              builder: (context, state) => const TransactionHistoryPage(),
            ),
          ],
        ),
        GoRoute(
          path: BuyPage.routeName,
          builder: (context, state) => const BuyPage(),
        ),
        GoRoute(
          path: LegalDisclaimerPage.routeName,
          builder: (context, state) => const LegalDisclaimerPage(),
        ),
        GoRoute(
          path: SellPage.routeName,
          builder: (context, state) => const SellPage(),
        ),
        GoRoute(
          path: KycPageManager.routeName,
          builder: (context, state) => const KycPageManager(),
        ),
        GoRoute(
          path: '/receive',
          builder: (context, state) => const ReceivePage(isBottomSheet: false),
        ),
        GoRoute(
          path: '/send',
          builder: (context, state) => SendPage(
            params: (state.extra as SendRouteParams?) ?? const SendRouteParams(),
          ),
          routes: [
            GoRoute(
              path: '/openCryptoPay',
              builder: (context, state) =>
                  SendInvoicePage(request: state.extra as OpenCryptoPayRequest),
            ),
            GoRoute(
              path: '/success/:txId',
              builder: (context, state) => TransactionSentPage(
                title: S.of(context).transactionSent,
                transactionId: state.pathParameters['txId']!,
                blockchain: Blockchain.ethereum,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/settings',
          routes: [
            GoRoute(
              path: '/languages',
              builder: (context, state) => const SettingsLanguagePage(),
            ),
            GoRoute(
              path: '/contact',
              builder: (context, state) => const SettingsContactPage(),
            ),
            GoRoute(
              path: '/currencies',
              builder: (context, state) => const SettingsCurrenciesPage(),
            ),
            GoRoute(
              path: '/network',
              builder: (context, state) => SettingsNetworkPage(),
            ),
            GoRoute(
              path: '/taxReport',
              builder: (context, state) => const SettingsTaxReportPage(),
            ),
            GoRoute(
              path: '/seed',
              builder: (context, state) => const SettingsSeedPage(),
            ),
            GoRoute(
              path: '/nodes',
              builder: (context, state) => const SettingsNodesPage(),
              routes: [
                GoRoute(
                  path: '/:chainId',
                  builder: (context, state) => SettingsEditNodePage(
                    blockchain: Blockchain.getFromChainId(
                      int.parse(state.pathParameters['chainId']!),
                    ),
                  ),
                ),
              ],
            ),
            GoRoute(
              path: '/termsOfUse',
              builder: (context, state) => LegalDocumentPage(
                params: LegalDocumentParams(
                  title: S.of(context).termsOfUse,
                  assetBaseName: 'terms_of_use',
                ),
              ),
            ),
          ],
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: '/webView',
          builder: (context, state) => WebViewPage(state.extra as WebViewRouteParams),
        ),
      ],
    ),
  );
}
