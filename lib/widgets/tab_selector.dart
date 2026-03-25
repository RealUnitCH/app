import 'package:flutter/material.dart';
import 'package:realunit_wallet/styles/colors.dart';

class TabSelector<T> extends StatelessWidget {
  const TabSelector({
    super.key,
    required this.tabs,
    required this.selectedTab,
    required this.onTabSelected,
    required this.labelBuilder,
  });

  final List<T> tabs;
  final T selectedTab;
  final ValueChanged<T> onTabSelected;
  final Widget Function(BuildContext context, T item, bool isSelected) labelBuilder;

  @override
  Widget build(BuildContext context) {
    final tabCount = tabs.length;
    final selectedIndex = tabs.indexOf(selectedTab);
    final alignmentX = tabCount > 1 ? -1.0 + (2.0 * selectedIndex / (tabCount - 1)) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: RealUnitColors.neutral100,
        borderRadius: .circular(8.0),
      ),
      padding: const .all(4.0),
      child: IntrinsicHeight(
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment(alignmentX, 0),
              child: FractionallySizedBox(
                widthFactor: 1 / tabCount,
                child: Container(
                  decoration: BoxDecoration(
                    color: RealUnitColors.basic.white,
                    borderRadius: .circular(8.0),
                  ),
                ),
              ),
            ),
            Row(
              children: List.generate(tabCount, (index) {
                final item = tabs.elementAt(index);
                final isSelected = item == selectedTab;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTabSelected(item),
                    behavior: .opaque,
                    child: Padding(
                      padding: const .symmetric(vertical: 8.0),
                      child: Center(
                        child: labelBuilder(context, item, isSelected),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
