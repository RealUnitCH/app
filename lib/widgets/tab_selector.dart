import 'package:flutter/material.dart';
import 'package:realunit_wallet/styles/colors.dart';

class TabSelector extends StatelessWidget {
  const TabSelector({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final tabCount = tabs.length;
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
                final isSelected = index == selectedIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTabSelected(index),
                    behavior: .opaque,
                    child: Padding(
                      padding: const .symmetric(vertical: 8.0),
                      child: Text(
                        tabs.elementAt(index),
                        textAlign: .center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: isSelected ? .w600 : .normal,
                          color: isSelected
                              ? RealUnitColors.realUnitBlue
                              : RealUnitColors.neutral500,
                        ),
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
