import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class FAProgressBar extends HookWidget {
  FAProgressBar({
    super.key,
    this.currentValue = 0,
    this.maxValue = 95,
    this.size = 30,
    this.animatedDuration = const Duration(milliseconds: 300),
    this.direction = Axis.horizontal,
    this.verticalDirection = VerticalDirection.down,
    BorderRadiusGeometry? borderRadius,
    this.border,
    Color? backgroundColor,
    Color? progressColor,
    this.changeColorValue,
    Color? changeProgressColor,
    this.displayText = '',
    TextStyle? displayTextStyle,
  })  : _borderRadius = borderRadius ?? BorderRadius.circular(8),
        backgroundColor = backgroundColor ?? const Color(0x00FFFFFF),
        progressColor = progressColor ?? const Color(0xFFFA7268),
        changeProgressColor = changeProgressColor ?? const Color(0xFF5F4B8B),
        displayTextStyle = displayTextStyle ??
            const TextStyle(color: Color(0xFFFFFFFF), fontSize: 12);
  final int currentValue;
  final int maxValue;
  final double size;
  final Duration animatedDuration;
  final Axis direction;
  final VerticalDirection verticalDirection;
  final BorderRadiusGeometry _borderRadius;
  final BoxBorder? border;
  final Color backgroundColor;
  final Color progressColor;
  final int? changeColorValue;
  final Color? changeProgressColor;
  final String displayText;
  final TextStyle displayTextStyle;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(duration: animatedDuration);
    final currentBegin = useRef(0.0);
    final currentEnd = useRef(0.0);
    final animation = useRef<Animation<double>>(
        Tween<double>(begin: 0, end: 0).animate(controller));

    void triggerAnimation() {
      currentBegin.value = animation.value.value;
      if (currentValue == 0 || maxValue == 0) {
        currentEnd.value = 0;
      } else {
        currentEnd.value = 0.05 + currentValue / maxValue;
      }
      animation.value = Tween<double>(
              begin: currentBegin.value, end: currentEnd.value)
          .animate(controller);
      controller.reset();
      controller.forward();
    }

    useEffect(() {
      triggerAnimation();
      return null;
    }, [currentValue, maxValue]);

    return AnimatedProgressBar(
      animation: animation.value,
      widget: this,
    );
  }
}

class AnimatedProgressBar extends AnimatedWidget {
  const AnimatedProgressBar({
    super.key,
    required Animation<double> animation,
    required this.widget,
  }) : super(listenable: animation);

  final FAProgressBar widget;

  double transformValue(x, begin, end, before) {
    double y = (end * x - (begin - before)) * (1 / before);
    return y < 0 ? 0 : ((y > 1) ? 1 : y);
  }

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    Color? progressColor = widget.progressColor;

    final colorTween = ColorTween(
      begin: widget.progressColor,
      end: widget.changeProgressColor,
    );

    progressColor = colorTween.transform(transformValue(
      animation.value,
      widget.changeColorValue,
      widget.maxValue,
      5,
    ));

    List<Widget> progressWidgets = [];
    Widget progressWidget = Container(
      decoration: BoxDecoration(
        color: progressColor,
        borderRadius: widget._borderRadius,
        border: widget.border,
      ),
    );
    progressWidgets.add(progressWidget);
    Widget textProgress;
    double position = max(-1, (animation.value * 2) - 1.2);
    textProgress = Container(
      alignment: widget.direction == Axis.horizontal
          ? Alignment(position, 0)
          : (widget.verticalDirection == VerticalDirection.up
              ? const FractionalOffset(0.5, 0.05)
              : const FractionalOffset(0.5, 0.95)),
      child: Text(
        (widget.currentValue).toInt().toString() + widget.displayText,
        softWrap: false,
        style: widget.displayTextStyle,
      ),
    );
    progressWidgets.add(textProgress);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        width: widget.direction == Axis.vertical ? widget.size : null,
        height: widget.direction == Axis.horizontal ? widget.size : null,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: widget._borderRadius,
          border: widget.border,
        ),
        child: Stack(
          children: [
            Flex(
              direction: widget.direction,
              verticalDirection: widget.verticalDirection,
              children: <Widget>[
                Expanded(
                  flex: (animation.value * 100).toInt(),
                  child: progressWidget,
                ),
                Expanded(
                  flex: 100 - (animation.value * 100).toInt(),
                  child: Container(),
                )
              ],
            ),
            textProgress,
          ],
        ),
      ),
    );
  }
}
