import 'package:flutter/material.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/styles.dart';

class SettingOption {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final String? selectedOption;
  final GestureTapCallback? onTap;

  SettingOption({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.selectedOption,
    this.onTap,
  });
}

class SettingsSections extends StatelessWidget {
  final String? title;
  final List<SettingOption> settings;

  const SettingsSections({super.key, this.title, required this.settings});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            if (title != null)
              Row(children: [
                Text(
                  title!,
                  style: kSubtitleTextStyle,
                ),
              ]),
            Container(
              margin: const EdgeInsets.only(top: 8),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  final setting = settings[index];
                  return GestureDetector(
                    onTap: setting.onTap,
                    child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(children: [
                        if (setting.leading != null) setting.leading!,
                        Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  setting.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: RealUnitColors.realUnitBlack,
                                    fontSize: 16,
                                  ),
                                ),
                                if (setting.subtitle != null)
                                  Text(
                                    setting.subtitle!,
                                    style: TextStyle(
                                      color: RealUnitColors.neutral500,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  )
                              ],
                            )),
                        if (setting.trailing != null) ...[
                          Spacer(),
                          if (setting.selectedOption != null) ...[
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Text(
                                setting.selectedOption!,
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  color: DEuroColors.neutralGrey,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                          setting.trailing!
                        ],
                      ]),
                    ),
                  );
                },
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: DEuroColors.neutralGrey98,
                ),
                itemCount: settings.length,
              ),
            ),
          ],
        ),
      );
}
