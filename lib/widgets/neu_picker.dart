import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

typedef CallBack = Function(int);

class NeuPicker extends HookWidget {
  final int value;
  final List<String> data;
  final CallBack? onConfirm;
  const NeuPicker(this.data, {super.key, this.value = 0, this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final selected = useSignal(value);
    final controller = useFixedExtentScrollController(initialItem: value);

    return SizedBox(

      width: double.infinity,

      child: Material(
      child: Card(
        shape: RoundedRectangleBorder(
            side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
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
                      onConfirm?.call(selected.value);
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
                      data[i],
                    ),
                  );
                },
                childCount: data.length,
                scrollController: controller,
                itemExtent: 40,
                onSelectedItemChanged: (v) => selected.value = v,
              ),
            ),
          ],
        ),
      ),
    ),

    );
  }
}
