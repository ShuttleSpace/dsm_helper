import 'package:flutter/widgets.dart';

class TransparentPageRoute<T> extends PageRouteBuilder<T> {
  TransparentPageRoute({
    super.settings,
    required super.pageBuilder,
    super.transitionsBuilder = _defaultTransitionsBuilder,
    super.transitionDuration = const Duration(milliseconds: 150),
    super.barrierDismissible,
    super.barrierColor,
    super.barrierLabel,
    super.maintainState,
  }) : super(
          opaque: false,
        );
}

Widget _defaultTransitionsBuilder(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(
    opacity: CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
    ),
    child: child,
  );
}
