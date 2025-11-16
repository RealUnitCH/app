import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/styles.dart';
import 'package:flutter/material.dart';

class StandardSlideButton extends StatefulWidget {
  const StandardSlideButton({
    super.key,
    required this.onSlideComplete,
    this.buttonText = '',
    this.height = 55.0,
  });

  final VoidCallback onSlideComplete;
  final String buttonText;
  final double height;

  @override
  State<StandardSlideButton> createState() => _StandardSlideButtonState();
}

class _StandardSlideButtonState extends State<StandardSlideButton> {
  double _dragPosition = 0.0;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        const double sideMargin = 4.0;
        final double effectiveMaxWidth = maxWidth - 2 * sideMargin;
        const double sliderWidth = 70.0;

        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            color: DEuroColors.neutralGrey93,
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Center(
                child: Text(
                  widget.buttonText,
                  style: kPageTitleTextStyle.copyWith(
                    fontWeight: FontWeight.w600,
                    color: DEuroColors.dEuroBlue,
                  ),
                ),
              ),
              Positioned(
                left: sideMargin + _dragPosition,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _dragPosition += details.delta.dx;
                      if (_dragPosition < 0) _dragPosition = 0;
                      if (_dragPosition > effectiveMaxWidth - sliderWidth) {
                        _dragPosition = effectiveMaxWidth - sliderWidth;
                      }
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_dragPosition >= effectiveMaxWidth - sliderWidth - 10) {
                      widget.onSlideComplete();
                    }
                    setState(() => _dragPosition = 0);
                  },
                  child: Container(
                    width: sliderWidth,
                    height: widget.height - 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      color: DEuroColors.dEuroBlue,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            ],
          ),
        );
      });
}
