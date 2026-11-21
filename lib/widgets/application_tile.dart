import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';

/// 应用抽屉中的应用图标卡片。
///
/// 原页面为每个应用重复了 `GestureDetector + Card + Column(icon, label)`，
/// 这里收敛为数据驱动的组件，角标通过 [badge] 传入。
class ApplicationTile extends StatelessWidget {
  final String iconAsset;
  final String label;
  final VoidCallback onTap;
  final Widget? badge;
  final bool centerContent;
  final bool listLayout;

  const ApplicationTile({
    super.key,
    required this.iconAsset,
    required this.label,
    required this.onTap,
    this.badge,
    this.centerContent = true,
    this.listLayout = false,
  });

  ApplicationTile copyWith({bool? listLayout}) {
    return ApplicationTile(
      key: key,
      iconAsset: iconAsset,
      label: label,
      onTap: onTap,
      badge: badge,
      centerContent: centerContent,
      listLayout: listLayout ?? this.listLayout,
    );
  }

  @override
  Widget build(BuildContext context) {
    final icon = Image.asset(
      iconAsset,
      height: 36,
      width: 36,
      fit: BoxFit.contain,
    );

    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          side: const BorderSide(),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingSmall),
          child: Stack(
            children: [
              Align(
                alignment:
                    centerContent ? Alignment.center : Alignment.topCenter,
                child: listLayout
                    ? Row(
                        children: [
                          icon,
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          icon,
                          const SizedBox(height: 5),
                          Text(
                            label,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
              ),
              if (badge != null)
                Positioned(
                  right: listLayout ? 12 : 30,
                  child: badge!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
