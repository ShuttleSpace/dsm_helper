import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:garden/stores/app_store_v2.dart';

/// Signals 使用示例
///
/// 展示如何在 UI 组件中使用 Signals 进行状态管理
class SignalsUsageExample extends StatelessWidget {
  const SignalsUsageExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Signals 使用示例'),
      ),
      body: ListView(
        children: [
          // 示例 1: 基本的状态显示
          _buildAccountInfo(),

          // 示例 2: 状态切换
          _buildVibrateSettings(),

          // 示例 3: 条件渲染
          _buildConditionalWidget(),

          // 示例 4: 列表状态
          _buildDashboardSettings(),

          // 示例 5: 表单输入
          _buildDownloadSettings(),
        ],
      ),
    );
  }

  /// 示例 1: 基本的状态显示
  Widget _buildAccountInfo() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '账户信息',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 使用 Watch 包裹需要响应式更新的部分
            Watch((context) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('账户: ${appStoreV2.account}'),
                  Text('主机名: ${appStoreV2.hostname}'),
                  Text('会话 ID: ${appStoreV2.sid.substring(0, 8)}...'),
                  Text('非审查账户: ${appStoreV2.notReviewAccount}'),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  /// 示例 2: 状态切换
  Widget _buildVibrateSettings() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '震动设置',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Switch 组件
            Watch((context) {
              return SwitchListTile(
                title: const Text('震动开关'),
                subtitle: const Text('启用或禁用震动反馈'),
                value: appStoreV2.vibrateOn,
                onChanged: (value) {
                  appStoreV2.setVibrateOn(value);
                  // 不需要调用 setState()
                },
              );
            }),

            Watch((context) {
              return SwitchListTile(
                title: const Text('警告震动'),
                subtitle: const Text('警告时震动'),
                value: appStoreV2.vibrateWarning,
                onChanged: (value) {
                  appStoreV2.setVibrateWarning(value);
                },
              );
            }),

            Watch((context) {
              return SwitchListTile(
                title: const Text('普通震动'),
                subtitle: const Text('普通操作时震动'),
                value: appStoreV2.vibrateNormal,
                onChanged: (value) {
                  appStoreV2.setVibrateNormal(value);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  /// 示例 3: 条件渲染
  Widget _buildConditionalWidget() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '条件渲染示例',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Watch((context) {
              // 根据状态显示不同的 Widget
              if (appStoreV2.notReviewAccount) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Premium 账户', style: TextStyle(color: Colors.green)),
                    ],
                  ),
                );
              } else {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('标准账户', style: TextStyle(color: Colors.orange)),
                    ],
                  ),
                );
              }
            }),
          ],
        ),
      ),
    );
  }

  /// 示例 4: 列表状态
  Widget _buildDashboardSettings() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard 设置',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Watch((context) {
              return Column(
                children: [
                  SwitchListTile(
                    title: const Text('卡片折叠开关'),
                    value: appStoreV2.dashboardCardCollapseSwitch,
                    onChanged: (value) {
                      appStoreV2.setDashboardCardCollapseSwitch(value);
                    },
                  ),

                  const Divider(),

                  // 显示卡片折叠状态
                  const Text('卡片状态:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  ...appStoreV2.dashboardCardCollapseState.entries.map((entry) {
                    return ListTile(
                      title: Text(entry.key),
                      trailing: Text(entry.value ? '已折叠' : '已展开'),
                      onTap: () {
                        appStoreV2.toggleCardItemCollapse(entry.key);
                      },
                    );
                  }),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  /// 示例 5: 表单输入
  Widget _buildDownloadSettings() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '下载设置',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 下载路径输入
            Watch((context) {
              return TextField(
                decoration: InputDecoration(
                  labelText: '下载保存路径',
                  hintText: '输入下载路径',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: () {
                      // 保存当前输入的路径
                      // 这里需要添加 TextEditingController 来获取输入值
                    },
                  ),
                ),
                // initialValue: appStoreV2.downloadSavePath,
                onChanged: (value) {
                  // 可以在输入时更新状态
                  // 或者只在保存时更新
                },
              );
            }),

            const SizedBox(height: 16),

            // WiFi 下载开关
            Watch((context) {
              return SwitchListTile(
                title: const Text('仅 WiFi 下载'),
                subtitle: const Text('仅在 WiFi 网络下下载'),
                value: appStoreV2.downloadWifiOnly,
                onChanged: (value) {
                  appStoreV2.setDownloadWifiOnly(value);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// 深度嵌套状态使用示例
class NestedSignalsExample extends StatelessWidget {
  const NestedSignalsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      // 可以在 Watch 中访问多个状态
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('账户: ${appStoreV2.account}'),
              Text('震动: ${appStoreV2.vibrateOn ? "开启" : "关闭"}'),
              Text(
                  'WiFi 下载: ${appStoreV2.downloadWifiOnly ? "仅 WiFi" : "任意网络"}'),

              // 条件组合
              if (appStoreV2.account.isNotEmpty && appStoreV2.notReviewAccount)
                const Text(
                  '✅ 高级账户已激活',
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
      );
    });
  }
}

/// 迁移前后对比示例
class MigrationComparison extends StatelessWidget {
  const MigrationComparison({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '迁移前 vs 迁移后',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // 迁移前
        _buildMigrationBefore(),
        const SizedBox(height: 32),

        // 迁移后
        _buildMigrationAfter(),
      ],
    );
  }

  Widget _buildMigrationBefore() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: .1),
        border: Border.all(color: Colors.red),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '❌ 迁移前（传统方式）',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          SizedBox(height: 8),
          Text('''
class SettingWidget extends StatefulWidget {
  @override
  _SettingWidgetState createState() => _SettingWidgetState();
}

class _SettingWidgetState extends State<SettingWidget> {
  @override
  Widget build(BuildContext context) {
    return Switch(
      value: settingsStore.vibrateOn,
      onChanged: (value) {
        setState(() {  // 需要手动调用 setState
          settingsStore.setVibrateOn( value;
        });
      },
    );
  }
}
          '''),
        ],
      ),
    );
  }

  Widget _buildMigrationAfter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: .1),
        border: Border.all(color: Colors.green),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✅ 迁移后（Signals 方式）',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
          ),
          SizedBox(height: 8),
          Text('''
class SettingWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      return Switch(
        value: appStoreV2.vibrateOn,
        onChanged: (value) {
          appStoreV2.setVibrateOn(value);
          // 不需要 setState，自动更新 UI
        },
      );
    });
  }
}
          '''),
        ],
      ),
    );
  }
}
