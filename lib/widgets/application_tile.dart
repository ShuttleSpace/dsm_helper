import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
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
                            child: _MarqueeText(
                              label: label,
                              textAlign: TextAlign.start,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          icon,
                          const SizedBox(height: 5),
                          _MarqueeText(
                            label: label,
                            textAlign: TextAlign.center,
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

class _MarqueeText extends StatelessWidget {
  const _MarqueeText({
    super.key,
    required this.label,
    required this.textAlign,
  });

  final String label;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(
            text: label,
            style: DefaultTextStyle.of(context).style,
          ),
          textScaler: MediaQuery.textScalerOf(context),
          textDirection: Directionality.of(context),
          maxLines: 1,
        )..layout();
        final overflow = painter.width - constraints.maxWidth;
        if (overflow <= 1) {
          return Text(
            label,
            maxLines: 1,
            textAlign: textAlign,
            overflow: TextOverflow.ellipsis,
          );
        }
        return _ScrollingText(label: label, overflow: overflow);
      },
    );
  }
}

class _ScrollingText extends HookWidget {
  const _ScrollingText({
    required this.label,
    required this.overflow,
  });

  final String label;
  final double overflow;

  @override
  Widget build(BuildContext context) {
    final ticker = useSingleTickerProvider();
    final controller = useMemoized(
      () => AnimationController(
        vsync: ticker,
        duration: const Duration(seconds: 4),
      ),
      [ticker],
    );
    useEffect(() {
      controller.repeat(reverse: true);
      return controller.dispose;
    }, [controller]);

    return ClipRect(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) => Transform.translate(
          offset: Offset(-controller.value * overflow, 0),
          child: child,
        ),
        child: Text(label, maxLines: 1, softWrap: false),
      ),
    );
  }
}
