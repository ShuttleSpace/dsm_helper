import 'package:flutter/material.dart';
import 'package:garden/util/ui_util.dart';

/// 通用的「输入名称」对话框。
///
/// 文件页重命名/新建文件夹、收藏重命名、选择文件夹新建等场景共用；
/// 业务动作通过 [onConfirm] 回传，对话框本身只负责输入与基本校验。
class NameInputDialog extends StatefulWidget {
  final String title;
  final String labelText;
  final String hintText;
  final String initialText;
  final String emptyMessage;
  final Future<void> Function(String name) onConfirm;
  final double cardHorizontalMargin;

  const NameInputDialog({
    super.key,
    required this.title,
    required this.onConfirm,
    this.labelText = "文件名",
    this.hintText = "请输入新的名称",
    this.initialText = "",
    this.emptyMessage = "请输入新文件名",
    this.cardHorizontalMargin = 50,
  });

  @override
  State<NameInputDialog> createState() => _NameInputDialogState();
}

class _NameInputDialogState extends State<NameInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController.fromValue(
      TextEditingValue(text: widget.initialText),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final name = _controller.text;
    if (name.trim().isEmpty) {
      UiUtil.toast(widget.emptyMessage);
      return;
    }
    Navigator.of(context).pop();
    await widget.onConfirm(name);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(5),
              ),
              margin: EdgeInsets.symmetric(
                horizontal: widget.cardHorizontalMargin,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: widget.hintText,
                            labelText: widget.labelText,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _confirm,
                            child: const Text(
                              "确定",
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              "取消",
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
