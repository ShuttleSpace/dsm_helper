import 'package:garden/stores/connection_store.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/widgets/cupertino_image.dart';
import 'package:garden/widgets/label.dart';
import 'package:garden/widgets/packages/package_button.dart';
import 'package:signals/signals_flutter.dart';

/// 套件卡片组件
class PackageCard extends StatelessWidget {
  final Map package;
  final bool installed;
  final bool isBeta;
  final List<String> Function(List) getCategoryName;
  final VoidCallback onTap;
  final VoidCallback onUpdate;
  final VoidCallback onInstall;
  final Future<void> Function() onStart;
  final Future<void> Function() onStop;

  const PackageCard({
    super.key,
    required this.package,
    required this.installed,
    this.isBeta = false,
    required this.getCategoryName,
    required this.onTap,
    required this.onUpdate,
    required this.onInstall,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    String thumbnailUrl = "";
    if (package['thumbnail'].length > 0) {
      thumbnailUrl = package['thumbnail'].last;
      if (!thumbnailUrl.startsWith("http")) {
        thumbnailUrl = connectionStore.baseUrl.watch(context) + thumbnailUrl;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
            side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingSmall),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingLarge),
                child: Column(
                  children: [
                    const SizedBox(
                      height: 20,
                    ),
                    Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: SizedBox(
                            height: 80,
                            child: CupertinoExtendedImage(
                              thumbnailUrl,
                              width: 80,
                            ),
                          ),
                        ),
                        if (isBeta ||
                            (package['additional'] != null &&
                                package['additional']['beta']))
                          const Align(
                            alignment: Alignment.topRight,
                            child: Label(
                              "Beta",
                              Colors.lightBlueAccent,
                              fill: true,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    SizedBox(
                      height: 40,
                      child: Text(
                        "${package['dname']}",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Text(
                      _getDisplayText(),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Padding(
                  padding: const EdgeInsets.all(20),
                  child: PackageButton(
                    package: package,
                    beta: isBeta,
                    onUpdate: onUpdate,
                    onInstall: onInstall,
                    onStart: onStart,
                    onStop: onStop,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  String _getDisplayText() {
    if (installed &&
        package['additional'] != null &&
        package['additional']['updated_at'] != null) {
      return package['additional']['updated_at'];
    } else if (package['category'] is List &&
        getCategoryName(package['category']).isNotEmpty) {
      return getCategoryName(package['category']).join(",");
    } else {
      return package['maintainer'];
    }
  }
}
