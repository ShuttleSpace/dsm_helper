import 'package:flutter/material.dart';

class Label extends StatelessWidget {
  const Label(this.name, this.color,
      {super.key, this.fill = false, this.fontSize = 12, this.height = 24});
  final String name;
  final Color color;
  final bool fill;
  final double fontSize;
  final double height;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: color),
        color: fill ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      child: Text(
        name,
        style: TextStyle(
            color: fill ? Theme.of(context).colorScheme.surface : color,
            fontSize: fontSize),
      ),
    );
  }
}
