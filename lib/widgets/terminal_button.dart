import 'package:dsm_helper/util/function.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

typedef OnPressed = Function();

class TerminalButton extends StatelessWidget {
  final OnPressed? onPressed;
  final Widget child;
  final bool active;
  const TerminalButton(
      {this.onPressed, required this.child, this.active = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Util.instance.vibrate(FeedbackType.light);
        onPressed?.call();
      },
      child: Container(
        color: active ? Colors.blue.withOpacity(0.4) : null,
        width: 40,
        height: 30,
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
