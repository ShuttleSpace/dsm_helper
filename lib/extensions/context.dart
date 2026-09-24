import 'package:flutter/material.dart';
import 'package:garden/theme/app_theme.dart';

extension StadiumStyleExtension on BuildContext {
  ButtonStyle get stadiumButtonStyle => OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        side: BorderSide(color: Theme.of(this).colorScheme.primary, width: 1.0),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      );
  MenuStyle get stadiumMenuStyle => MenuStyle(
        shape: WidgetStateProperty.all<StadiumBorder>(
          StadiumBorder(
              side: BorderSide(
                  color: Theme.of(this).colorScheme.primary, width: 3.0)),
        ),
      );
  ShapeBorder get stadiumShapeBorder => StadiumBorder(
        side: BorderSide(
            color: Theme.of(this).colorScheme.primary.withValues(alpha: 0.2)),
      );

  ShapeBorder get roundRectShapeBorder => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Theme.of(this).colorScheme.primary.withValues(alpha: 0.6),
        ),
      );
}

extension ColorExtension on BuildContext {
  Color get errorColor =>
      Theme.of(this).extension<AppTheme>()?.errorColor ?? Colors.redAccent;
  Color get successColor =>
      Theme.of(this).extension<AppTheme>()?.successColor ?? Colors.teal;
  Color get infoColor =>
      Theme.of(this).extension<AppTheme>()?.infoColor ?? Colors.limeAccent;
  Color get uploadColor => Colors.blueAccent;
  Color get downloadColor => successColor;
  Color get chartTextColor =>
      Theme.of(this).colorScheme.onSurface.withAlpha(153);
}
