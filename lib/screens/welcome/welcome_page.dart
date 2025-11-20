import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: PopScope(
          canPop: false,
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/splash_screen.png"),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 20, bottom: 10, left: 10, right: 10),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 5),
                                child: TextButton(
                                  onPressed: () =>
                                      context.go('/wallet/restore'),
                                  style: TextButton.styleFrom(
                                    fixedSize: Size(double.infinity, 55),
                                    backgroundColor: Colors.transparent,
                                  ),
                                  child: Text(
                                    S.of(context).import_wallet,
                                    style: kPrimaryButtonTextStyle.copyWith(color: RealUnitColors.realUnitBlue),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 5),
                                child: TextButton(
                                  onPressed: () => context.go('/wallet/create'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: RealUnitColors.realUnitBlue,
                                    fixedSize: Size(double.infinity, 55),
                                    elevation: 0.0,
                                  ),
                                  child: Text(
                                    S.of(context).create_wallet,
                                    textAlign: TextAlign.center,
                                    style: kPrimaryButtonTextStyle,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  )),
            ),
          ),
        ),
      );
}
