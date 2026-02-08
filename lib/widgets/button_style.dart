import 'package:flutter/material.dart';

extension StadiumButtonStyleExtension on BuildContext {
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
        side: BorderSide(color: Theme.of(this).colorScheme.primary),
      );
}
