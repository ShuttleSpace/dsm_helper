import 'package:flutter/material.dart';
import 'package:garden/widgets/button_style.dart';
import 'package:garden/widgets/label.dart';

/// 用户权限项
class PermissionItem extends StatelessWidget {
  final Map permission;
  final VoidCallback? onTap;

  const PermissionItem({
    super.key,
    required this.permission,
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
                    Row(
                      children: [
                        Text(
                          "${permission['name']}",
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        _buildPermissionStatus(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionStatus() {
    if (permission['is_custom'] ||
        permission['is_deny'] ||
        permission['is_readonly'] ||
        permission['is_writable']) {
      return permission['is_readonly']
          ? const Label("只读", Colors.lightBlueAccent)
          : permission['is_writable']
              ? const Label("可读写", Colors.green)
              : permission['is_custom']
                  ? const Label("自定义", Colors.orangeAccent)
                  : permission['is_deny']
                      ? const Label("禁止访问", Colors.red)
                      : Label(
                          permission['inherit'] ?? "未知", Colors.orangeAccent);
    } else {
      return permission['inherit'] == "ro"
          ? const Label("只读", Colors.lightBlueAccent)
          : permission['inherit'] == "rw"
              ? const Label("可读写", Colors.green)
              : permission['inherit'] == "cu"
                  ? const Label("自定义", Colors.orangeAccent)
                  : permission['inherit'] == "-"
                      ? const Label("禁止访问", Colors.red)
                      : Label(
                          permission['inherit'] ?? "未知", Colors.orangeAccent);
    }
  }
}
