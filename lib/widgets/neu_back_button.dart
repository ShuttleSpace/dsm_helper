import 'package:flutter/material.dart';

class AppBackButton extends StatelessWidget {
  final BuildContext context;
  final Color? color;
  final Color? iconColor;
  final double bevel;
  const AppBackButton(this.context,
      {super.key, this.color, this.iconColor, this.bevel = 5.0});

  @override
  Widget build(BuildContext context) {
    final parentRoute = ModalRoute.of(this.context);
    final canPop = parentRoute?.canPop == true;
    return canPop
        ? Padding(
            padding: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
            child: IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icon(
                Icons.arrow_back_ios_outlined,
                size: 22,
                color: iconColor,
              ),
            ),
          )
        : Container();
  }
}
