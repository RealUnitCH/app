import 'package:flutter/material.dart';
import 'package:realunit_wallet/styles/colors.dart';

class SettingOption {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final String? selectedOption;
  final GestureTapCallback? onTap;
  final bool isSectionHeader;

  const SettingOption({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.selectedOption,
    this.onTap,
    this.isSectionHeader = false,
  });
}

class SettingsSections extends StatelessWidget {
  final List<SettingOption> settings;

  const SettingsSections({
    super.key,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: settings.length,
        itemBuilder: (context, index) {
          final setting = settings.elementAt(index);
          if (setting.isSectionHeader) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                setting.title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: RealUnitColors.neutral500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }
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
                  vertical: 16,
                  horizontal: 20,
                ),
                child: Row(
                  spacing: 8.0,
                  children: [
                    if (setting.leading != null) setting.leading!,
                    Expanded(
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
                    if (setting.trailing != null) ...[
                      if (setting.selectedOption != null)
                        Text(
                          setting.selectedOption!,
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            color: subtitleColor,
                            fontSize: 14,
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
