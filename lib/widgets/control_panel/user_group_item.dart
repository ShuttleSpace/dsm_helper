import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/extensions/context.dart';

/// 用户群组项
class UserGroupItem extends StatelessWidget {
  final Map group;
  final VoidCallback? onTap;

  const UserGroupItem({
    super.key,
    required this.group,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: context.stadiumShapeBorder,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${group['name']}",
                      style: const TextStyle(fontSize: 16),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        "${group['description']}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
              if (group['is_member'])
                Icon(
                  CupertinoIcons.checkmark_alt,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
