import 'package:flutter/material.dart';

/// 通用列表项组件
/// 
/// 提供统一的列表项样式和行为
/// 
/// 用法示例：
/// ```dart
/// ListItem(
///   leading: Icon(Icons.folder),
///   title: "文件夹",
///   subtitle: "包含 10 个文件",
///   trailing: Icon(Icons.chevron_right),
///   onTap: () {
///     // 处理点击事件
///   },
/// )
/// ```
class ListItem extends StatelessWidget {
  /// 左侧图标或组件
  final Widget? leading;
  
  /// 标题
  final String title;
  
  /// 副标题
  final String? subtitle;
  
  /// 右侧组件
  final Widget? trailing;
  
  /// 点击回调
  final VoidCallback? onTap;
  
  /// 长按回调
  final VoidCallback? onLongPress;
  
  /// 是否显示分隔线
  final bool showDivider;
  
  /// 内边距
  final EdgeInsetsGeometry? padding;
  
  /// 是否启用
  final bool enabled;

  const ListItem({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.showDivider = true,
    this.padding,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final itemPadding = padding ?? 
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    
    final textColor = enabled 
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withValues(alpha: 0.38);
    
    final subtitleColor = enabled 
        ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
        : theme.colorScheme.onSurface.withValues(alpha: 0.38);

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: itemPadding,
          child: Row(
            children: [
              if (leading != null) ...[
                Opacity(
                  opacity: enabled ? 1.0 : 0.38,
                  child: leading!,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 14,
                          color: subtitleColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                Opacity(
                  opacity: enabled ? 1.0 : 0.38,
                  child: trailing!,
                ),
              ],
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: leading != null ? 56 : 16,
          ),
      ],
    );

    if (onTap != null || onLongPress != null) {
      content = InkWell(
        onTap: enabled ? onTap : null,
        onLongPress: enabled ? onLongPress : null,
        child: content,
      );
    }

    return content;
  }
}

/// 带开关的列表项
/// 
/// 用法示例：
/// ```dart
/// ListItemSwitch(
///   title: "启用通知",
///   subtitle: "接收推送通知",
///   value: _enabled,
///   onChanged: (value) {
///     updateState(() {
///       _enabled = value;
///     });
///   },
/// )
/// ```
class ListItemSwitch extends StatelessWidget {
  /// 标题
  final String title;
  
  /// 副标题
  final String? subtitle;
  
  /// 开关状态
  final bool value;
  
  /// 状态变化回调
  final ValueChanged<bool>? onChanged;
  
  /// 左侧图标
  final Widget? leading;
  
  /// 是否显示分隔线
  final bool showDivider;

  const ListItemSwitch({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.leading,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListItem(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: Switch(
        value: value,
        onChanged: onChanged != null ? (value) => onChanged!(value) : null,
      ),
      showDivider: showDivider,
    );
  }
}

/// 带复选框的列表项
/// 
/// 用法示例：
/// ```dart
/// ListItemCheckbox(
///   title: "选择此项",
///   value: _selected,
///   onChanged: (value) {
///     updateState(() {
///       _selected = value;
///     });
///   },
/// )
/// ```
class ListItemCheckbox extends StatelessWidget {
  /// 标题
  final String title;
  
  /// 副标题
  final String? subtitle;
  
  /// 选中状态
  final bool value;
  
  /// 状态变化回调
  final ValueChanged<bool>? onChanged;
  
  /// 左侧图标
  final Widget? leading;
  
  /// 是否显示分隔线
  final bool showDivider;

  const ListItemCheckbox({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.leading,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListItem(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: Checkbox(
        value: value,
        onChanged: onChanged != null ? (value) => onChanged!(value ?? false) : null,
      ),
      showDivider: showDivider,
    );
  }
}