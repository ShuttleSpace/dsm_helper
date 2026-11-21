// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

const Duration _kExpand = Duration(milliseconds: 200);

final Animatable<double> _easeOutTween = CurveTween(curve: Curves.easeOut);
final Animatable<double> _easeInTween = CurveTween(curve: Curves.easeIn);
final Animatable<double> _halfTween = Tween<double>(begin: 0.0, end: 0.5);

/// A single-line [ListTile] with an expansion arrow icon that expands or
/// collapses the tile to reveal or hide the [children].
class ExpansionContainer extends HookWidget {
  const ExpansionContainer({
    super.key,
    this.leading,
    required this.title,
    this.showFirst = false,
    this.first,
    this.subtitle,
    this.onExpansionChanged,
    this.children = const <Widget>[],
    this.trailing,
    this.initiallyExpanded = false,
    this.maintainState = false,
    this.tilePadding,
    this.expandedCrossAxisAlignment,
    this.expandedAlignment,
    this.childrenPadding,
    this.backgroundColor,
    this.collapsedBackgroundColor,
    this.textColor,
    this.collapsedTextColor,
    this.iconColor,
    this.collapsedIconColor,
    this.controlAffinity,
    this.bottomTitle = false,
  }) : assert(
          expandedCrossAxisAlignment != CrossAxisAlignment.baseline,
          'CrossAxisAlignment.baseline is not supported since the expanded children '
          'are aligned in a column, not a row. Try to use another constant.',
        );

  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? first;
  final bool? showFirst;
  final ValueChanged<bool>? onExpansionChanged;
  final List<Widget>? children;
  final Color? backgroundColor;
  final Color? collapsedBackgroundColor;
  final Widget? trailing;
  final bool? initiallyExpanded;
  final bool? maintainState;
  final EdgeInsetsGeometry? tilePadding;
  final Alignment? expandedAlignment;
  final CrossAxisAlignment? expandedCrossAxisAlignment;
  final EdgeInsetsGeometry? childrenPadding;
  final Color? iconColor;
  final Color? collapsedIconColor;
  final Color? textColor;
  final Color? collapsedTextColor;
  final ListTileControlAffinity? controlAffinity;
  final bool bottomTitle;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(duration: _kExpand);
    final backgroundColorTween = useRef(ColorTween());
    final rebuild = useSignal(0);
    final initialExpanded = useMemoized(() {
      dynamic v = PageStorage.of(context).readState(context);
      return v is bool ? v : false;
    }, const []);
    final isExpanded = useSignal(initialExpanded);

    backgroundColorTween.value
      ..begin = collapsedBackgroundColor
      ..end = backgroundColor;

    final heightFactor = controller.drive(_easeInTween);
    final iconTurns = controller.drive(_halfTween.chain(_easeInTween));
    final backgroundColorAnim =
        controller.drive(backgroundColorTween.value.chain(_easeOutTween));

    useEffect(() {
      if (initialExpanded) controller.value = 1.0;
      return null;
    }, const []);

    void handleTap() {
      isExpanded.value = !isExpanded.value;
      if (isExpanded.value) {
        controller.forward();
      } else {
        controller.reverse().then<void>((void value) {
          if (!context.mounted) return;
          rebuild.value++;
        });
      }
      PageStorage.of(context).writeState(context, isExpanded.value);
      onExpansionChanged?.call(isExpanded.value);
    }

    // Platform or null affinity defaults to trailing.
    ListTileControlAffinity effectiveAffinity(ListTileControlAffinity? affinity) {
      switch (affinity) {
        case ListTileControlAffinity.leading:
          return ListTileControlAffinity.leading;
        case ListTileControlAffinity.trailing:
        case ListTileControlAffinity.platform:
          return ListTileControlAffinity.trailing;
        default:
          return ListTileControlAffinity.leading;
      }
    }

    Widget buildIcon(BuildContext context) {
      return RotationTransition(
        turns: iconTurns,
        child: const Icon(Icons.expand_more),
      );
    }

    Widget? buildTrailingIcon(BuildContext context) {
      if (effectiveAffinity(controlAffinity) !=
          ListTileControlAffinity.trailing) {
        return null;
      }
      return buildIcon(context);
    }

    Widget buildChildren(BuildContext context, Widget? child) {
      Widget children = ClipRect(
        child: Align(
          alignment: expandedAlignment ?? Alignment.center,
          heightFactor: heightFactor.value,
          child: child,
        ),
      );
      return Container(
        decoration: BoxDecoration(
          color: backgroundColorAnim.value ?? Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (bottomTitle) children,
            Column(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: handleTap,
                  child: Container(
                    padding: tilePadding ??
                        const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(child: title),
                        const SizedBox(
                          width: 5,
                        ),
                        trailing ?? buildTrailingIcon(context) ?? Container()
                      ],
                    ),
                  ),
                ),
                if (showFirst == true) first ?? Container(),
              ],
            ),
            if (!bottomTitle) children,
          ],
        ),
      );
    }

    final bool closed = !isExpanded.value && controller.isDismissed;
    final bool shouldRemoveChildren = closed && (maintainState == false);

    final Widget result = Offstage(
      offstage: closed,
      child: TickerMode(
        enabled: !closed,
        child: Padding(
          padding: childrenPadding ?? EdgeInsets.zero,
          child: Column(
            crossAxisAlignment:
                expandedCrossAxisAlignment ?? CrossAxisAlignment.center,
            children: children?.sublist(showFirst == true ? 1 : 0) ?? [],
          ),
        ),
      ),
    );

    return AnimatedBuilder(
      animation: controller.view,
      builder: buildChildren,
      child: shouldRemoveChildren ? null : result,
    );
  }
}
