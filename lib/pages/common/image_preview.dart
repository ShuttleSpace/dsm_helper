import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:humphrey_garden/providers/flux_provider.dart';
import 'package:humphrey_garden/util/function.dart';
import 'package:humphrey_garden/widgets/hero_widget.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluwx/fluwx.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:provider/provider.dart';

class ImagePreview extends StatefulWidget {
  final List<String> images;
  final List<String> thumbs;
  final List<String> names;
  final List<String> paths;
  final int index;
  final bool network;
  final Object? tag;
  final Function? onDelete;
  final PageController pageController;

  ImagePreview(this.images, this.index,
      {this.network = true,
      this.tag,
      this.thumbs = const [],
      this.names = const [],
      this.paths = const [],
      this.onDelete})
      : this.pageController = PageController(initialPage: index);

  @override
  _ImagePreviewState createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<ImagePreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Animation<double>? _animation;
  var rebuildIndex = StreamController<int>.broadcast();
  var rebuildSwiper = StreamController<bool>.broadcast();
  VoidFunction? animationListener;
  bool _showSwiper = true;
  List<double> doubleTapScales = <double>[1.0, 2.0];
  int currentIndex = 0;
  bool blackBackground = false;
  GlobalKey<ExtendedImageSlidePageState> slidePageKey =
      GlobalKey<ExtendedImageSlidePageState>();
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
    Util.instance.vibrate(FeedbackType.warning);
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return Material(
          color: Colors.transparent,
          child: Card(
            shape: RoundedRectangleBorder(
                side: BorderSide(), borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      "确认删除",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    Text(
                      "确认要删除文件？",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                    ),
                    SizedBox(
                      height: 22,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              var res =
                                  await Api.deleteTask([widget.paths[index]]);
                              if (res['success']) {
                                Util.instance.toast("文件删除成功");
                                if (widget.thumbs.length > index) {
                                  widget.thumbs.removeAt(index);
                                }

                                if (widget.images.length > index) {
                                  widget.images.removeAt(index);
                                }
                                if (widget.paths.length > index) {
                                  widget.paths.removeAt(index);
                                }
                                if (widget.names.length > index) {
                                  widget.names.removeAt(index);
                                }
                                setState(() {});
                                widget.onDelete?.call();
                              }
                            },
                            child: Text(
                              "确认删除",
                              style: TextStyle(
                                  fontSize: 18, color: Colors.redAccent),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              "取消",
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
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

  @override
  void initState() {
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 150), vsync: this);
    setState(() {
      currentIndex = widget.index;
    });
    super.initState();
  }

  void onPageChanged(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  void dispose() {
    rebuildIndex.close();
    rebuildSwiper.close();
    _animationController.dispose();
    clearGestureDetailsCache();
    //cancelToken?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    Widget result = Material(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.transparent,
      shadowColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ExtendedImageGesturePageView.builder(
            itemBuilder: (BuildContext context, int index) {
              var item = widget.images[index];
              Widget image;
              if (widget.network) {
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
                        if (widget.thumbs.length > index + 1) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              ExtendedImage.network(
                                widget.thumbs[index],
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
                        return Center(
                          child: Text("图片加载失败"),
                        );
                    }
                  },
                  // heroBuilderForSlidingPage: (Widget result) {
                  //   return Hero(
                  //     tag: widget.tag ?? item,
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
                    if (animationListener != null) {
                      _animation?.removeListener(animationListener!);
                    }
                    _animationController.stop();
                    _animationController.reset();
                    if (begin == doubleTapScales[0]) {
                      end = doubleTapScales[1];
                    } else {
                      end = doubleTapScales[0];
                    }
                    animationListener = () {
                      state.handleDoubleTap(
                          scale: _animation?.value,
                          doubleTapPosition: pointerDownPosition);
                    };
                    _animation = _animationController
                        .drive(Tween<double>(begin: begin, end: end));
                    if (animationListener != null) {
                      _animation?.addListener(animationListener!);
                    }
                    _animationController.forward();
                  },
                );
              } else {
                image = ExtendedImage.file(
                  File(widget.images[index]),
                  fit: BoxFit.contain,
                  enableSlideOutPage: true,
                  mode: ExtendedImageMode.gesture,
                  // heroBuilderForSlidingPage: (Widget result) {
                  //   return Hero(
                  //     tag: widget.tag ?? item,
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
                    if (animationListener != null) {
                      _animation?.removeListener(animationListener!);
                    }
                    _animationController.stop();
                    _animationController.reset();
                    if (begin == doubleTapScales[0]) {
                      end = doubleTapScales[1];
                    } else {
                      end = doubleTapScales[0];
                    }
                    animationListener = () {
                      state.handleDoubleTap(
                          scale: _animation?.value,
                          doubleTapPosition: pointerDownPosition);
                    };
                    _animation = _animationController
                        .drive(Tween<double>(begin: begin, end: end));
                    if (animationListener != null) {
                      _animation?.addListener(animationListener!);
                    }
                    _animationController.forward();
                  },
                );
              }

              image = GestureDetector(
                child: HeroWidget(
                  tag: widget.tag ?? item,
                  child: image,
                  slidePagekey: slidePageKey,
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
            itemCount: widget.images.length,
            onPageChanged: (int index) {
              currentIndex = index;
              rebuildIndex.add(index);
            },
            controller: ExtendedPageController(
              initialPage: currentIndex,
            ),
            scrollDirection: Axis.horizontal,
            physics: BouncingScrollPhysics(),
          ),
          StreamBuilder<bool>(
            builder: (c, d) {
              if (d.data == null || d.data == false) return Container();

              return Column(
                children: [
                  if (Util.instance.isWechatInstalled)
                    SafeArea(
                      child: Container(
                        height: 56,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.centerRight,
                        child: Row(
                          children: [
                            Expanded(
                              child: widget.names.isEmpty
                                  ? FileName(
                                      widget.names, currentIndex, rebuildIndex)
                                  : Container(),
                            ),
                            GestureDetector(
                              onTap: () {
                                WeChatImageToShare wechatImage;
                                if (widget.images[currentIndex]
                                    .startsWith("http")) {
                                  wechatImage = WeChatImageToShare(
                                      localImagePath:
                                          widget.images[currentIndex]);
                                } else if (widget.images[currentIndex]
                                    .startsWith("/")) {
                                  wechatImage = WeChatImageToShare(
                                      uint8List:
                                          File(widget.images[currentIndex])
                                              .readAsBytesSync());
                                } else {
                                  Util.instance.toast("暂不支持分享此图片");
                                  return;
                                }
                                c.read<FluwxProvider>().wx.share(
                                      WeChatShareImageModel(wechatImage,
                                          scene: WeChatScene.session),
                                    );
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
                  Spacer(),
                  MySwiperPlugin(
                    widget.images,
                    currentIndex,
                    rebuildIndex,
                    onDelete: widget.paths.length > currentIndex
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
      child: result,
      slideAxis: SlideAxis.both,
      slideType: SlideType.onlyImage,
      onSlidingPage: (state) {
        ///you can change other widgets' state on page as you want
        ///base on offset/isSliding etc
        //var offset= state.offset;
        var showSwiper = !state.isSliding;
        if (showSwiper != _showSwiper) {
          // do not setState directly here, the image state will change,
          // you should only notify the widgets which are needed to change
          // setState(() {
          // _showSwiper = showSwiper;
          // });

          _showSwiper = showSwiper;
          rebuildSwiper.add(_showSwiper);
        }
      },
    );

    return result;
  }
}

class FileName extends StatelessWidget {
  final List names;
  final int index;
  final StreamController<int> reBuild;
  FileName(this.names, this.index, this.reBuild);
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
  MySwiperPlugin(this.pics, this.index, this.reBuild, {this.onDelete});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      builder: (BuildContext context, data) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: <Widget>[
                OutlinedButton(
                  onPressed: () {
                    if (data.data == null) {
                      Util.instance.toast('图片下载失败');
                      return;
                    }
                    Util.instance
                        .saveImage(pics[data.data!], context: context)
                        .then((res) {
                      if (res['code'] == 1) {
                        Util.instance.toast("已保存到相册");
                      } else {
                        Util.instance.toast("图片下载失败");
                      }
                    });
                  },
                  child: Row(
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
                Spacer(),
                OutlinedButton(
                  onPressed: () {
                    if (data.data == null) {
                      Util.instance.toast('图片下载失败,请重试!');
                      return;
                    }
                    onDelete?.call(data.data!);
                  },
                  child: Icon(
                    Icons.delete_forever,
                    size: 13,
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Card(
                  shape: RoundedRectangleBorder(
                      side: BorderSide(),
                      borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "${data.data ?? 0 + 1} / ${pics.length}",
                      style: TextStyle(fontSize: 12),
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
