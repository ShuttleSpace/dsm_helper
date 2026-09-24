import 'package:garden/stores/connection_store.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/extensions/context.dart';
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
  final bool horizontal;

  const PackageCard(
      {super.key,
      required this.package,
      required this.installed,
      this.isBeta = false,
      required this.getCategoryName,
      required this.onTap,
      required this.onUpdate,
      required this.onInstall,
      required this.onStart,
      required this.onStop,
      this.horizontal = false});

  @override
  Widget build(BuildContext context) {
    String thumbnailUrl = "";
    if (package['thumbnail'].length > 0) {
      thumbnailUrl = package['thumbnail'].last;
      if (!thumbnailUrl.startsWith("http")) {
        thumbnailUrl = connectionStore.baseUri.watch(context) + thumbnailUrl;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: context.roundRectShapeBorder,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingSmall),
          child: horizontal
              ? Row(
                  spacing: 20,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _children(thumbnailUrl),
                )
              : Column(
                  spacing: 20,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: _children(thumbnailUrl)),
        ),
      ),
    );
  }

  List<Widget> _children(String thumbnailUrl) {
    return [
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
              (package['additional'] != null && package['additional']['beta']))
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
      SizedBox(
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
      PackageButton(
        package: package,
        beta: isBeta,
        onUpdate: onUpdate,
        onInstall: onInstall,
        onStart: onStart,
        onStop: onStop,
      ),
    ];
  }

  String _getDisplayText() {
    if (installed &&
        package['additional'] != null &&
        package['additional']['updated_at'] != null) {
      return package['additional']['updated_at'];
    }
    if (package['category'] is! List) {
      return package['maintainer'];
    }

    final catoryNames = getCategoryName(package['category']);
    return catoryNames.join(",");
  }
}
