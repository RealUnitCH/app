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

  const SettingOption({
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

  const SettingsSections({
    super.key,
    this.title,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (title != null)
          Row(
            children: [
              Text(
                title!,
                style: kSubtitleTextStyle,
              ),
            ],
          ),
        ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: settings.length,
          itemBuilder: (context, index) {
            final setting = settings[index];
            final disabled = setting.onTap == null;
            final titleColor = disabled
                ? RealUnitColors.realUnitBlack.withValues(alpha: 0.5)
                : RealUnitColors.realUnitBlack;
            final subtitleColor = disabled
                ? RealUnitColors.neutral500.withValues(alpha: 0.5)
                : RealUnitColors.neutral500;

            return InkWell(
              onTap: disabled ? null : setting.onTap,
              splashColor: disabled ? Colors.transparent : null,
              highlightColor: disabled ? Colors.transparent : null,
              child: Opacity(
                opacity: disabled ? 0.5 : 1.0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 14,
                  ),
                  child: Row(
                    children: [
                      if (setting.leading != null) setting.leading!,
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                setting.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: titleColor,
                                  fontSize: 16,
                                ),
                              ),
                              if (setting.subtitle != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    setting.subtitle!,
                                    style: TextStyle(
                                      color: subtitleColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (setting.trailing != null) ...[
                        if (setting.selectedOption != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Text(
                              setting.selectedOption!,
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                color: subtitleColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        setting.trailing!,
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
