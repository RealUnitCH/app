import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/styles.dart';
import 'package:flutter/material.dart';

class SettingOption {
  final String title;
  final Widget? leading;
  final Widget? trailing;
  final String? selectedOption;
  final GestureTapCallback? onTap;

  SettingOption({
    required this.title,
    this.leading,
    this.trailing,
    this.selectedOption,
    this.onTap,
  });
}

class SettingsSections extends StatelessWidget {
  final String? title;
  final List<SettingOption> settings;

  const SettingsSections(
      {super.key, this.title, required this.settings});

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
                )
              ]),
            Container(
              margin: const EdgeInsets.only(top: 8),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  final setting = settings[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    child: InkWell(
                      enableFeedback: false,
                      onTap: setting.onTap,
                      child: Row(children: [
                        if (setting.leading != null) setting.leading!,
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            setting.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: DEuroColors.anthracite,
                              fontSize: 16,
                            ),
                          ),
                        ),
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
