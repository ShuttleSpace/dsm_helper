import 'package:garden/theme/app_theme.dart';
import 'package:garden/util/ui_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

typedef OnPressed = Function();

class TerminalButton extends StatelessWidget {
  final OnPressed? onPressed;
  final Widget child;
  final bool active;
  const TerminalButton(
      {super.key, this.onPressed, required this.child, this.active = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppTheme>();
    
    return GestureDetector(
      onTap: () {
        UiUtil.vibrate(FeedbackType.light);
        onPressed?.call();
      },
      child: Container(
        color: active 
            ? (appTheme?.infoColor ?? Colors.blue).withValues(alpha: 0.4) 
            : null,
        width: 40,
        height: 30,
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
