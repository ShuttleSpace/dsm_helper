import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/extensions/int.dart';

class ContainerProcesses extends StatelessWidget {
  final List processes;

  const ContainerProcesses({
    super.key,
    required this.processes,
  });

  Widget _buildProcessItem(process) {
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "进程：${process['pid']}",
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    "CPU：${process['cpu']}%",
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    "RAM：${(int.parse(process['memory'])).formatSize(fixed: 0)}",
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(process['command']),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemBuilder: (context, i) {
        return _buildProcessItem(processes[i]);
      },
      separatorBuilder: (context, i) {
        return const SizedBox(height: 20);
      },
      itemCount: processes.length,
    );
  }
}
