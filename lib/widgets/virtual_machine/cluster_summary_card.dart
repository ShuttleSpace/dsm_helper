import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/extensions/context.dart';

class ClusterSummaryCard extends StatelessWidget {
  final String title;
  final int totalCount;
  final int errorCount;
  final int warningCount;
  final int healthyCount;
  final VoidCallback onTap;

  const ClusterSummaryCard({
    super.key,
    required this.title,
    required this.totalCount,
    required this.errorCount,
    required this.warningCount,
    required this.healthyCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: context.stadiumShapeBorder,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingSmall),
          child: Column(
            children: [
              Row(
                children: [
                  Text(title),
                  const Spacer(),
                  Text("$totalCount"),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              if (errorCount > 0)
                Text(
                  "$errorCount",
                  style: const TextStyle(fontSize: 40, color: Colors.red),
                )
              else if (warningCount > 0)
                Text(
                  "$warningCount",
                  style: const TextStyle(fontSize: 40, color: Colors.orange),
                )
              else
                Text(
                  "$healthyCount",
                  style: const TextStyle(fontSize: 40, color: Colors.green),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
