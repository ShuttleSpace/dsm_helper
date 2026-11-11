import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:extended_image/extended_image.dart';

/// make hero better when slide out
class HeroWidget extends HookWidget {
  const HeroWidget({
    super.key,
    required this.child,
    required this.tag,
    required this.slidePagekey,
    this.slideType = SlideType.onlyImage,
  });
  final Widget child;
  final SlideType slideType;
  final Object tag;
  final GlobalKey<ExtendedImageSlidePageState> slidePagekey;

  @override
  Widget build(BuildContext context) {
    final rectTween = useRef<RectTween?>(null);
    return Hero(
      tag: tag,
      createRectTween: (Rect? begin, Rect? end) {
        rectTween.value = RectTween(begin: begin, end: end);
        return rectTween.value as Tween<Rect?>;
      },
      // make hero better when slide out
      flightShuttleBuilder: (BuildContext flightContext,
          Animation<double> animation,
          HeroFlightDirection flightDirection,
          BuildContext fromHeroContext,
          BuildContext toHeroContext) {
        // make hero more smoothly
        final Hero hero = (flightDirection == HeroFlightDirection.pop
            ? fromHeroContext.widget
            : toHeroContext.widget) as Hero;
        if (flightDirection == HeroFlightDirection.pop) {
          final bool fixTransform = slideType == SlideType.onlyImage &&
              (slidePagekey.currentState?.offset != Offset.zero ||
                  slidePagekey.currentState?.scale != 1.0);

          final Widget toHeroWidget = (toHeroContext.widget as Hero).child;
          return AnimatedBuilder(
            animation: animation,
            builder: (BuildContext buildContext, Widget? child) {
              Widget animatedBuilderChild = hero.child;

              // make hero more smoothly
              animatedBuilderChild = Stack(
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                children: <Widget>[
                  Opacity(
                    opacity: 1 - animation.value,
                    child: UnconstrainedBox(
                      child: SizedBox(
                        width: rectTween.value?.begin?.width,
                        height: rectTween.value?.begin?.height,
                        child: toHeroWidget,
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: animation.value,
                    child: animatedBuilderChild,
                  )
                ],
              );

              // fix transform when slide out
              if (fixTransform) {
                final Tween<Offset> offsetTween = Tween<Offset>(
                    begin: Offset.zero,
                    end: slidePagekey.currentState?.offset);

                final Tween<double> scaleTween = Tween<double>(
                    begin: 1.0, end: slidePagekey.currentState?.scale);
                animatedBuilderChild = Transform.translate(
                  offset: offsetTween.evaluate(animation),
                  child: Transform.scale(
                    scale: scaleTween.evaluate(animation),
                    child: animatedBuilderChild,
                  ),
                );
              }

              return animatedBuilderChild;
            },
          );
        }
        return hero.child;
      },
      child: child,
    );
  }
}
