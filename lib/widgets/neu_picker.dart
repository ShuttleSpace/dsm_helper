import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/extensions/context.dart';

typedef CallBack = Function(int);

class NeuPicker extends StatefulWidget {
  final int value;
  final List<String> data;
  final CallBack? onConfirm;
  const NeuPicker(this.data, {super.key, this.value = 0, this.onConfirm});
  @override
  NeuPickerState createState() => NeuPickerState();
}

class NeuPickerState extends State<NeuPicker> {
  late FixedExtentScrollController _controller;
  int value = 0;
  @override
  void initState() {
    value = widget.value;
    _controller = FixedExtentScrollController(initialItem: value);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Card(
        shape: context.stadiumShapeBorder,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("取消"),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () {
                      widget.onConfirm?.call(value);
                      Navigator.of(context).pop();
                    },
                    child: const Text("确定"),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker.builder(
                itemBuilder: (context, i) {
                  return Center(
                    child: Text(
                      widget.data[i],
                    ),
                  );
                },
                childCount: widget.data.length,
                scrollController: _controller,
                itemExtent: 40,
                onSelectedItemChanged: (v) => value = v,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
