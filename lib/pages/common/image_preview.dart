import 'dart:async';
import 'package:garden/stores/settings_store.dart';
import 'package:garden/util/misc.dart';
import 'package:garden/util/ui_util.dart';
import 'dart:io';
import 'dart:math';

import 'package:garden/api/dsm_api.dart';
import 'package:garden/widgets/hero_widget.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:signals_hooks/signals_hooks.dart';

class ImagePreview extends HookWidget {
  final List<String> images;
  final List<String> thumbs;
  final List<String> names;
  final List<String> paths;
  final int index;
  final bool network;
  final Object? tag;
  final Function? onDelete;

  const ImagePreview(this.images, this.index,
      {super.key,
      this.network = true,
      this.tag,
      this.thumbs = const [],
      this.names = const [],
      this.paths = const [],
      this.onDelete});

  @override
  Widget build(BuildContext context) {
    final animationController = useAnimationController(
        duration: const Duration(milliseconds: 150));
    final animation = useRef<Animation<double>?>(null);
    final animationListener = useRef<VoidFunction?>(null);
    final rebuildIndex =
        useMemoized(() => StreamController<int>.broadcast(), const []);
    final rebuildSwiper =
        useMemoized(() => StreamController<bool>.broadcast(), const []);
    final showSwiper = useRef(true);
    const doubleTapScales = <double>[1.0, 2.0];
    final currentIndex = useSignal(index);
    final rebuild = useSignal(0);
    final slidePageKey = useMemoized(
        () => GlobalKey<ExtendedImageSlidePageState>(), const []);
    final isWechatInstalled = useSignalValue(settingsStore.isWechatInstalled);

    double initScale(
        {required Size imageSize,
        required Size size,
        required double initialScale}) {
      var n1 = imageSize.height / imageSize.width;
      var n2 = size.height / size.width;
      if (n1 > n2) {
        final FittedSizes fittedSizes =
            applyBoxFit(BoxFit.contain, imageSize, size);
        //final Size sourceSize = fittedSizes.source;
        Size destinationSize = fittedSizes.destination;
        return size.width / destinationSize.width;
      } else if (n1 / n2 < 1 / 10) {
        final FittedSizes fittedSizes =
            applyBoxFit(BoxFit.contain, imageSize, size);
        //final Size sourceSize = fittedSizes.source;
        Size destinationSize = fittedSizes.destination;
        return size.height / destinationSize.height;
      }

      return initialScale;
    }

    deleteFile(int index) {
      UiUtil.vibrate(FeedbackType.warning);
      showCupertinoModalPopup(
        context: context,
        builder: (context) {
          return Material(
            color: Colors.transparent,
            child: Card(
              shape: RoundedRectangleBorder(
                  side: const BorderSide(),
                  borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text(
                        "确认删除",
                        style:
                            TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      const Text(
                        "确认要删除文件？",
                        style:
                            TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(
                        height: 22,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                try {
                                  await dsmFileStationDeleteStartForPage(
                                      <String>[paths[index]]);
                                  UiUtil.toast("文件删除成功");
                                  if (thumbs.length > index) {
                                    thumbs.removeAt(index);
                                  }
                                  if (images.length > index) {
                                    images.removeAt(index);
                                  }
                                  if (paths.length > index) {
                                    paths.removeAt(index);
                                  }
                                  if (names.length > index) {
                                    names.removeAt(index);
                                  }
                                  rebuild.value++;
                                  onDelete?.call();
                                } catch (e) {
                                  UiUtil.toast("文件删除失败");
                                }
                              },
                              child: const Text(
                                "确认删除",
                                style: TextStyle(
                                    fontSize: 18, color: Colors.redAccent),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                              },
                              child: const Text(
                                "取消",
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    useEffect(() {
      return () {
        rebuildIndex.close();
        rebuildSwiper.close();
        clearGestureDetailsCache();
        //cancelToken?.cancel();
      };
    }, const []);

    var size = MediaQuery.sizeOf(context);
    Widget result = Material(
      color: Theme.brightnessOf(context) == Brightness.dark
          ? Colors.black
          : Colors.transparent,
      shadowColor: Theme.brightnessOf(context) == Brightness.dark
          ? Colors.black
          : Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ExtendedImageGesturePageView.builder(
            itemBuilder: (BuildContext context, int index) {
              var item = images[index];
              Widget image;
              if (network) {
                image = ExtendedImage.network(
                  item,
                  fit: BoxFit.contain,
                  enableSlideOutPage: true,
                  mode: ExtendedImageMode.gesture,
                  loadStateChanged: (ExtendedImageState state) {
                    switch (state.extendedImageLoadState) {
                      case LoadState.loading:
                        final ImageChunkEvent? loadingProgress =
                            state.loadingProgress;
                        final double progress =
                            loadingProgress?.expectedTotalBytes != null
                                ? (loadingProgress?.cumulativeBytesLoaded ??
                                        0) /
                                    (loadingProgress?.expectedTotalBytes ?? 1)
                                : 0;
                        if (thumbs.length > index + 1) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              ExtendedImage.network(
                                thumbs[index],
                                width: double.infinity,
                                fit: BoxFit.contain,
                              ),
                              CircularProgressIndicator(
                                value: progress,
                              ),
                            ],
                          );
                        } else {
                          return Center(
                            child: CircularProgressIndicator(
                              value: progress,
                            ),
                          );
                        }
                      case LoadState.completed:
                        return null;
                      case LoadState.failed:
                        //remove memory cached
                        state.imageProvider.evict();
                        final detail = state.lastException;
                        return Center(
                          child: Text(
                            detail == null ? "图片加载失败" : "图片加载失败：$detail",
                            textAlign: TextAlign.center,
                          ),
                        );
                    }
                  },
                  // heroBuilderForSlidingPage: (Widget result) {
                  //   return Hero(
                  //     tag: tag ?? item,
                  //     child: result,
                  //     flightShuttleBuilder: (BuildContext flightContext, Animation<double> animation, HeroFlightDirection flightDirection, BuildContext fromHeroContext, BuildContext toHeroContext) {
                  //       final Hero hero = (flightDirection == HeroFlightDirection.pop ? fromHeroContext.widget : toHeroContext.widget) as Hero;
                  //       return hero.child;
                  //     },
                  //   );
                  // },
                  initGestureConfigHandler: (state) {
                    double initialScale = 1.0;
                    if (state.extendedImageInfo != null) {
                      initialScale = initScale(
                          size: size,
                          initialScale: initialScale,
                          imageSize: Size(
                              state.extendedImageInfo?.image.width.toDouble() ??
                                  0,
                              state.extendedImageInfo?.image.height
                                      .toDouble() ??
                                  0));
                    }
                    return GestureConfig(
                        inPageView: true,
                        initialScale: initialScale,
                        maxScale: max(initialScale, 5.0),
                        animationMaxScale: max(initialScale, 5.0),
                        //you can cache gesture state even though page view page change.
                        //remember call clearGestureDetailsCache() method at the right time.(for example,this page dispose)
                        cacheGesture: false);
                  },
                  onDoubleTap: (ExtendedImageGestureState state) {
                    ///you can use define pointerDownPosition as you can,
                    ///default value is double tap pointer down postion.
                    var pointerDownPosition = state.pointerDownPosition;
                    double begin = state.gestureDetails?.totalScale ?? 1.0;
                    double end;
                    if (animationListener.value != null) {
                      animation.value?.removeListener(animationListener.value!);
                    }
                    animationController.stop();
                    animationController.reset();
                    if (begin == doubleTapScales[0]) {
                      end = doubleTapScales[1];
                    } else {
                      end = doubleTapScales[0];
                    }
                    animationListener.value = () {
                      state.handleDoubleTap(
                          scale: animation.value?.value,
                          doubleTapPosition: pointerDownPosition);
                    };
                    animation.value = animationController
                        .drive(Tween<double>(begin: begin, end: end));
                    if (animationListener.value != null) {
                      animation.value?.addListener(animationListener.value!);
                    }
                    animationController.forward();
                  },
                );
              } else {
                image = ExtendedImage.file(
                  File(images[index]),
                  fit: BoxFit.contain,
                  enableSlideOutPage: true,
                  mode: ExtendedImageMode.gesture,
                  // heroBuilderForSlidingPage: (Widget result) {
                  //   return Hero(
                  //     tag: tag ?? item,
                  //     child: result,
                  //     flightShuttleBuilder: (BuildContext flightContext, Animation<double> animation, HeroFlightDirection flightDirection, BuildContext fromHeroContext, BuildContext toHeroContext) {
                  //       final Hero hero = flightDirection == HeroFlightDirection.pop ? fromHeroContext.widget : toHeroContext.widget;
                  //       return hero.child;
                  //     },
                  //   );
                  // },
                  initGestureConfigHandler: (state) {
                    double initialScale = 1.0;
                    if (state.extendedImageInfo != null) {
                      initialScale = initScale(
                          size: size,
                          initialScale: initialScale,
                          imageSize: Size(
                              state.extendedImageInfo?.image.width.toDouble() ??
                                  0,
                              state.extendedImageInfo?.image.height
                                      .toDouble() ??
                                  0));
                    }
                    return GestureConfig(
                        inPageView: true,
                        initialScale: initialScale,
                        maxScale: max(initialScale, 5.0),
                        animationMaxScale: max(initialScale, 5.0),
                        //you can cache gesture state even though page view page change.
                        //remember call clearGestureDetailsCache() method at the right time.(for example,this page dispose)
                        cacheGesture: false);
                  },
                  onDoubleTap: (ExtendedImageGestureState state) {
                    ///you can use define pointerDownPosition as you can,
                    ///default value is double tap pointer down postion.
                    var pointerDownPosition = state.pointerDownPosition;
                    double begin = state.gestureDetails?.totalScale ?? 1.0;
                    double end;
                    if (animationListener.value != null) {
                      animation.value?.removeListener(animationListener.value!);
                    }
                    animationController.stop();
                    animationController.reset();
                    if (begin == doubleTapScales[0]) {
                      end = doubleTapScales[1];
                    } else {
                      end = doubleTapScales[0];
                    }
                    animationListener.value = () {
                      state.handleDoubleTap(
                          scale: animation.value?.value,
                          doubleTapPosition: pointerDownPosition);
                    };
                    animation.value = animationController
                        .drive(Tween<double>(begin: begin, end: end));
                    if (animationListener.value != null) {
                      animation.value?.addListener(animationListener.value!);
                    }
                    animationController.forward();
                  },
                );
              }

              image = GestureDetector(
                child: HeroWidget(
                  tag: tag ?? item,
                  slidePagekey: slidePageKey,
                  child: image,
                  // flightShuttleBuilder: (BuildContext flightContext, Animation<double> animation, HeroFlightDirection flightDirection, BuildContext fromHeroContext, BuildContext toHeroContext) {
                  //   final Hero hero = (flightDirection == HeroFlightDirection.pop ? fromHeroContext.widget : toHeroContext.widget) as Hero;
                  //   return hero.child;
                  // },
                ),
                onTap: () {
                  slidePageKey.currentState?.popPage();
                  Navigator.pop(context);
                },
              );

              return image;
            },
            itemCount: images.length,
            onPageChanged: (int index) {
              currentIndex.value = index;
              rebuildIndex.add(index);
            },
            controller: ExtendedPageController(
              initialPage: currentIndex.value,
            ),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
          ),
          StreamBuilder<bool>(
            builder: (c, d) {
              if (d.data == null || d.data == false) return Container();

              return Column(
                children: [
                  if (isWechatInstalled)
                    SafeArea(
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingLarge),
                        alignment: Alignment.centerRight,
                        child: Row(
                          children: [
                            Expanded(
                              child: names.isEmpty
                                  ? FileName(
                                      names, currentIndex.value, rebuildIndex)
                                  : Container(),
                            ),
                            GestureDetector(
                              onTap: () {
                                if (images[currentIndex.value]
                                    .startsWith("http")) {
                                } else if (images[currentIndex.value]
                                    .startsWith("/")) {
                                } else {
                                  UiUtil.toast("暂不支持分享此图片");
                                  return;
                                }
                              },
                              child: Image.asset(
                                "assets/icons/wechat.png",
                                width: 30,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  const Spacer(),
                  MySwiperPlugin(
                    images,
                    currentIndex.value,
                    rebuildIndex,
                    onDelete: paths.length > currentIndex.value
                        ? (index) {
                            deleteFile(index);
                          }
                        : (_) {},
                  ),
                ],
              );
            },
            initialData: true,
            stream: rebuildSwiper.stream,
          )
        ],
      ),
    );

    result = ExtendedImageSlidePage(
      key: slidePageKey,
      slideAxis: SlideAxis.both,
      slideType: SlideType.onlyImage,
      onSlidingPage: (state) {
        ///you can change other widgets' state on page as you want
        ///base on offset/isSliding etc
        //var offset= state.offset;
        var newShowSwiper = !state.isSliding;
        if (newShowSwiper != showSwiper.value) {
          // do not setState directly here, the image state will change,
          // you should only notify the widgets which are needed to change
          // updateState(() {
          // showSwiper.value = newShowSwiper;
          // });

          showSwiper.value = newShowSwiper;
          rebuildSwiper.add(showSwiper.value);
        }
      },
      child: result,
    );

    return result;
  }
}

class FileName extends StatelessWidget {
  final List names;
  final int index;
  final StreamController<int> reBuild;
  const FileName(this.names, this.index, this.reBuild, {super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      builder: (BuildContext context, data) {
        return Text(data.data != null && data.data! < names.length
            ? names[data.data!]
            : "");
      },
      initialData: index,
      stream: reBuild.stream,
    );
  }
}

class MySwiperPlugin extends StatelessWidget {
  final List pics;
  final int index;
  final StreamController<int> reBuild;
  final Function(int)? onDelete;
  const MySwiperPlugin(this.pics, this.index, this.reBuild,
      {super.key, this.onDelete});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      builder: (BuildContext context, data) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: <Widget>[
                OutlinedButton(
                  onPressed: () {
                    if (data.data == null) {
                      UiUtil.toast('图片下载失败');
                      return;
                    }
                    saveImage(pics[data.data!], context: context).then((res) {
                      if (res['code'] == 1) {
                        UiUtil.toast("已保存到相册");
                      } else {
                        UiUtil.toast("图片下载失败");
                      }
                    });
                  },
                  child: const Row(
                    children: <Widget>[
                      Icon(
                        Icons.file_download,
                        size: 13,
                      ),
                      Text(
                        " 保存图片",
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () {
                    if (data.data == null) {
                      UiUtil.toast('图片下载失败,请重试!');
                      return;
                    }
                    onDelete?.call(data.data!);
                  },
                  child: const Icon(
                    Icons.delete_forever,
                    size: 13,
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Card(
                  shape: RoundedRectangleBorder(
                      side: const BorderSide(),
                      borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingSmall),
                    child: Text(
                      "${data.data ?? 0 + 1} / ${pics.length}",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      initialData: index,
      stream: reBuild.stream,
    );
  }
}
