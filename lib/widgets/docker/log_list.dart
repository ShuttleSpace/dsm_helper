import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:garden/widgets/label.dart';

class LogList extends StatelessWidget {
  final List logs;
  final ScrollController scrollController;

  const LogList({
    super.key,
    required this.logs,
    required this.scrollController,
  });

  Widget _buildLogItem(log) {
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Label("${log['stream']}", Colors.lightGreen),
                const Spacer(),
                Text(
                  "${log['created']}",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(log['text']),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: DraggableScrollbar.semicircle(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        scrollbarTimeToFade: const Duration(seconds: 1),
        controller: scrollController,
        child: ListView.separated(
          controller: scrollController,
          padding: const EdgeInsets.only(left: 10, right: 20, top: 20),
          itemBuilder: (context, i) {
            return _buildLogItem(logs.reversed.toList()[i]);
          },
          separatorBuilder: (context, i) {
            return const SizedBox(height: 20);
          },
          itemCount: logs.length,
        ),
      ),
    );
  }
}
