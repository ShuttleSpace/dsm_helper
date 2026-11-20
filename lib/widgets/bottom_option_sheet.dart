import 'package:flutter/material.dart';
import 'package:garden/widgets/bottom_sheet_card.dart';

/// 底部选项面板中的一行选项。
class BottomOption {
  final String title;
  final String? subtitle;
  final VoidCallback onPressed;

  const BottomOption({
    required this.title,
    required this.onPressed,
    this.subtitle,
  });
}

/// 通用「从列表中选择一项」底部面板。
///
/// 套件安装位置选择等场景原先内联了整套 `Card + Column + OutlinedButton`，
/// 收敛为数据驱动的选项列表，业务侧只提供选项与回调。
class BottomOptionSheet extends StatelessWidget {
  final String title;
  final List<BottomOption> options;
  final String cancelText;
  final double padding;
  final bool popBeforeOnPressed;
  final double borderRadius;
  final TextAlign optionTextAlign;

  const BottomOptionSheet({
    super.key,
    required this.title,
    required this.options,
    this.cancelText = "取消",
    this.padding = 20,
    this.popBeforeOnPressed = true,
    this.borderRadius = 18,
    this.optionTextAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return BottomSheetCard(
      padding: EdgeInsets.all(padding),
      borderRadius: borderRadius,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          for (final option in options)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: OutlinedButton(
                onPressed: () {
                  if (popBeforeOnPressed) {
                    Navigator.of(context).pop();
                  }
                  option.onPressed();
                },
                child: Container(
                  padding: const EdgeInsets.only(left: 20),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.title,
                        textAlign: optionTextAlign,
                      ),
                      if (option.subtitle != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          option.subtitle!,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              cancelText,
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
