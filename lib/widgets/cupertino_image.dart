import 'package:garden/util/http_util.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// 缩略图 URL 里带着每次登录都会变的 `_sid`，直接拿 URL 当磁盘缓存 key 会永远未命中。
/// 剔掉 `_sid` 后剩下的部分（unitId + cache_key + size）服务器侧就会跟着图片变化。
String thumbnailCacheKey(String url) =>
    keyToMd5(url.replaceAll(RegExp(r'[?&]_sid=[^&]*'), ''));

class CupertinoExtendedImage extends StatelessWidget {
  final String url;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final BoxShape? boxShape;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  const CupertinoExtendedImage(
    this.url, {
    super.key,
    this.fit,
    this.width,
    this.height,
    this.boxShape = BoxShape.rectangle,
    this.borderRadius = BorderRadius.zero,
    this.placeholder,
  });
  @override
  Widget build(BuildContext context) {
    return ExtendedImage.network(
      url,
      cacheKey: thumbnailCacheKey(url),
      // 叠加上磁盘缓存：默认 key 是整条 URL 的 md5，带 _sid，重登后全量重下。
      cacheMaxAge: const Duration(days: 30),
      fit: fit,
      width: width,
      height: height,
      cache: true,
      // enableMemoryCache: false,
      // cacheHeight: height == null ? null : height ~/ 2,
      // cacheWidth: width == null ? null : width ~/ 2,
      shape: boxShape,
      borderRadius: borderRadius,
      loadStateChanged: (ExtendedImageState state) {
        switch (state.extendedImageLoadState) {
          case LoadState.loading:
            return placeholder ??
                Container(
                  width: width,
                  height: height,
                  alignment: Alignment.center,
                  child: Image.asset(
                    "assets/icons/image.png",
                    width: 40,
                    height: 40,
                  ),
                );
          case LoadState.completed:
            return ExtendedRawImage(
              image: state.extendedImageInfo?.image,
              width: width,
              height: height,
              fit: fit,
            );
          case LoadState.failed:
            return placeholder ??
                Container(
                  width: width,
                  height: height,
                  alignment: Alignment.center,
                  child: Image.asset(
                    "assets/icons/image.png",
                    width: 40,
                    height: 40,
                  ),
                );
        }
      },
    );
  }
}

class CupertinoCircleAvatar extends StatelessWidget {
  final String url;
  final String text;
  final Color? backgroundColor;
  final double fontSize;
  final double size;
  final Color? foregroundColor;
  const CupertinoCircleAvatar({
    super.key,
    required this.url,
    Color? backgroundColor,
    this.size = 30,
    this.text = "",
    this.fontSize = 18,
    Color? foregroundColor,
  })  : backgroundColor = backgroundColor ?? Colors.blue,
        foregroundColor = foregroundColor ?? CupertinoColors.white;
  @override
  Widget build(BuildContext context) {
    return url.isBlank
        ? Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            width: size,
            height: size,
            child: Text(
              text,
              style: TextStyle(
                  fontSize: fontSize,
                  color:
                      foregroundColor ?? Theme.of(context).colorScheme.surface),
            ),
          )
        : CupertinoExtendedImage(
            connectionStore.baseUri.watch(context) + url,
            width: size,
            height: size,
            fit: BoxFit.contain,
            boxShape: BoxShape.circle,
          );
  }
}
