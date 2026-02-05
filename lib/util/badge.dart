import 'package:flutter/material.dart';
import 'package:garden/theme/app_theme.dart';

class Badge extends StatelessWidget {
  final dynamic badge;
  final double size;
  const Badge(this.badge, {super.key, this.size = 44});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppTheme>();

    if ((badge is num && badge > 0) || (badge is String && badge != "")) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: size / 44 * 14),
        alignment: Alignment.center,
        height: size,
        decoration: BoxDecoration(
            color: appTheme?.errorColor ?? Colors.red,
            borderRadius: BorderRadius.circular(size / 44 * 30),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  offset: const Offset(1, 2)),
            ]),
        child: Text(
          "$badge",
          style: TextStyle(color: Colors.white, fontSize: size / 44 * 28),
        ),
      );
    } else {
      return Container();
    }
  }
}
