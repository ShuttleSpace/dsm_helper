import 'package:garden/stores/connection_store.dart';
import 'package:flutter/material.dart';
import 'package:garden/widgets/button_style.dart';
import 'package:garden/widgets/cupertino_image.dart';
import 'package:garden/widgets/packages/package_button.dart';
import 'package:signals/signals_flutter.dart';

/// 可更新套件列表项组件
class UpdatePackageItem extends StatelessWidget {
  final Map update;
  final VoidCallback onTap;
  final VoidCallback onUpdate;
  final VoidCallback onInstall;
  final Future<void> Function() onStart;
  final Future<void> Function() onStop;

  const UpdatePackageItem({
    super.key,
    required this.update,
    required this.onTap,
    required this.onUpdate,
    required this.onInstall,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    String thumbnailUrl = update['thumbnail'].last;
    if (!thumbnailUrl.startsWith("http")) {
      thumbnailUrl = connectionStore.baseUri.watch(context) + thumbnailUrl;
    }

    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: context.stadiumShapeBorder,
        margin: const EdgeInsets.only(bottom: 20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Container(
                height: 80,
                width: 80,
                alignment: Alignment.center,
                child: CupertinoExtendedImage(
                  thumbnailUrl,
                  width: 80,
                  height: 80,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${update['dname']}",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      update['version'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              PackageButton(
                package: update,
                onUpdate: onUpdate,
                onInstall: onInstall,
                onStart: onStart,
                onStop: onStop,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
