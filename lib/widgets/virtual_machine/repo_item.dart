import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/extensions/int.dart';
import 'package:garden/widgets/animation_progress_bar.dart';
import 'package:garden/widgets/label.dart';

class RepoItem extends StatelessWidget {
  final Map<String, dynamic> repo;

  const RepoItem({
    super.key,
    required this.repo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  repo['name'],
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                repo['type'] == "healthy"
                    ? const Label("正常", Colors.green)
                    : repo['type'] == "warning"
                        ? Label(
                            repo['status'] == "provision_warning"
                                ? "空间不足"
                                : repo['status'],
                            Colors.orange)
                        : Label("${repo['status']}", Colors.red),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Text(
                    int.parse(repo['used']).formatSize(),
                    style: const TextStyle(color: Colors.blue),
                  ),
                  const Text(
                    " / ",
                    style: TextStyle(color: Colors.grey),
                  ),
                  Text(
                    int.parse(repo['size']).formatSize(),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              children: [
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(
                        side: const BorderSide(),
                        borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingSmall),
                      child: FAProgressBar(
                        backgroundColor: Colors.transparent,
                        changeColorValue: 90,
                        changeProgressColor: Colors.red,
                        progressColor: Colors.blue,
                        currentValue: ((int.parse(repo['used']) /
                                    int.parse(repo['size'])) *
                                100)
                            .floor(),
                        displayText: '%',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
