# Android 构建失败排查记录（Flutter 3.47.2 + 国内网络）

> 起因：升级 Flutter SDK 到 3.47.2 后 `flutter build apk` 连续失败，
> 表面症状每次都不同（NDK 下载超时 / Gradle 版本过低 / AGP 版本过低 /
> `Cannot invoke "java.util.List.get(int)" because "path" is null`）。
> 本文记录最终定位到的**单一根因**与修复。

## 根因：JDK 的 JSSE TLS 客户端指纹被中间设备干扰

现象对照（同一台机器、同一个时刻）：

| 客户端 | `repo.maven.apache.org` | `jitpack.io` | `maven.aliyun.com` |
|---|---|---|---|
| macOS curl（SecureTransport） | 200 | 200 | 200 |
| JDK 21 / JDK 25 的 JSSE | **握手中断** | **握手中断** | 200 |

- 断开发生在 **ClientHello 发出之后、ServerHello 之前**，表现为
  `SSLHandshakeException: Remote host terminated the handshake: SSL peer shut down incorrectly`。
- 与 TLS 版本无关：禁用 TLSv1.3、只留单 cipher、换 JDK 25 的 JBR，**全部一样失败**。
- 中间设备对 `dl.google.com` / `storage.flutter-io.cn` 放行，对
  `repo.maven.apache.org` / `jitpack.io` 掐断。

### 误导性症状

Gradle 在**格式化解析失败消息**时会二次崩溃：

```
java.lang.NullPointerException: Cannot invoke "java.util.List.get(int)" because "path" is null
    at org.gradle.internal.resolve.ModuleVersionResolveException.getMessage(ModuleVersionResolveException.java:124)
```

真正的错误（依赖解析失败）被这个 NPE **整个吞掉**。必须用
`./gradlew :app:dependencyInsight --configuration debugRuntimeClasspath --dependency <name>`
才能看到真实依赖链。

## 修复：仓库优先级改用国内镜像

`android/build.gradle` 的 `allprojects.repositories` 与 `buildscript.repositories`
改为「国内镜像优先，官方源兜底」：

```groovy
google()
maven { url 'https://maven.aliyun.com/repository/google' }
maven { url 'https://maven.aliyun.com/repository/public' }
maven { url 'https://maven.aliyun.com/repository/central' }
maven { url 'https://mirrors.cloud.tencent.com/nexus/repository/maven-public' }
mavenCentral()
```

镜像选择依据：

- 阿里云 `public`/`central`：Central 的完整代理，JSSE 可直连。
- **腾讯云 `maven-public`：聚合仓库，除 Central 外还覆盖 JitPack 内容**。
  `image_cropper` 依赖的 `com.github.Yalantis:ucrop:2.2.11` 仅 JitPack 有，
  阿里云镜像 404，腾讯云 200。

## 顺带修复的版本对齐（Flutter 3.47.2 硬性下限）

| 文件 | 改动 |
|---|---|
| `android/gradle/wrapper/gradle-wrapper.properties` | Gradle 8.11.1 → 8.14（Flutter 要求 ≥ 8.14.0） |
| `android/settings.gradle` | AGP 8.9.1 → 8.11.1；Kotlin 2.1.0 → 2.4.0 |
| `android/build.gradle` | `ext.kotlin_version` → 2.4.0；buildscript classpath AGP 8.3.1 → 8.11.1 |
| `android/build.gradle` | `subprojects` 统一 `ndkVersion "27.0.12077973"`、`buildToolsVersion "36.0.0"` |
| `android/.gitignore` | 忽略 `/build`（根 `.gitignore` 的 `/build/` 只匹配仓库根） |

`android/gradle.properties` 中 `android.builtInKotlin=false` / `android.newDsl=false`
由 Flutter migrator 自动添加，与 SDK 模板 `gradle.properties.tmpl` 一致，予以保留。

## 另一个独立问题：Dart 3.13 移除 `dart:ffi` 的分配器

依赖全部解析成功后，构建在 Dart 编译阶段失败：

```
jni-1.1.2/lib/src/jarray.dart:147: Error: The getter 'nativeFree' isn't defined for the type 'Allocator'
```

### 事实

- Flutter 3.47.2 打包 **Dart 3.13.2**，其中 `dart:ffi` 移除了
  `malloc` / `calloc` / `Arena` 顶层符号，只保留 `Allocator` 抽象接口
  （`allocate()` + `free()`）。新定义在 `sdk/lib/ffi/allocation.dart`。
- 已用**官方 Dart 3.13.2 SDK**（从 `storage.flutter-io.cn` 下载）独立复现，
  排除「Flutter 快照不完整」的可能。
- `jni 1.1.2`（dart-lang/native，发布于 2026-11-03）仍在使用
  `malloc.nativeFree` / `calloc.nativeFree`，**上游 main 分支同样未修复**。
- `jni` 由 `path_provider_android 2.3.0+` / `shared_preferences_android 2.5.0+`
  的内部实现引入（两者 CHANGELOG 明确写的是 internal implementation 改动，
  **无公开 API 变更**）。
- `flutter analyze` 不会报这个错 —— 它不编译依赖包的 Dart 代码。

### 采取的修复

`pubspec.yaml` 的 `dependency_overrides` 里固定到最后一个不依赖 `jni` 的版本：

```yaml
path_provider_android: 2.2.23
shared_preferences_android: 2.4.28
```

`flutter pub get` 后 `jni` / `jni_flutter` / `jni_util` 已从依赖树中消失。

### 备选路径（若上游修复后想改回新版）

`package:ffi 2.2.0`（sdk `>=3.7.0 <4.0.0`）重新提供了 `malloc` / `calloc`
（用 `@Native` 注解实现，见 `lib/src/allocation.dart`）和 `Arena`。
因此把 `jni` 的 `import 'dart:ffi'` 改为 `import 'package:ffi/ffi.dart'`
理论上即可适配 Dart 3.13 —— 但需要维护 fork。

注意：本项目已有 `ffi: 2.0.1` 的 override（`open_file 3.2.1` 需要），
其 sdk 约束是 `>=2.17.0 <3.0.0`，**不含 Dart 3**，在新 SDK 下不可用；
若走上面的 fork 路线，需一并把该 override 提到 2.2.0 并验证 `open_file`。

## 用户级（不进仓库）的配置

- `~/.gradle/init.gradle`：`pluginManagement` 与 `buildscript` 仓库加阿里云镜像。
  **不要**在这里注入项目级 `repositories` —— Flutter SDK 自带的
  `packages/flutter_tools/gradle/settings.gradle.kts` 设有
  `RepositoriesMode.FAIL_ON_PROJECT_REPOS`，会报
  `repository 'maven' was added by settings file 'settings.gradle'`。
- Flutter SDK 的 `packages/flutter_tools/gradle/settings.gradle.kts`：
  在其 `dependencyResolutionManagement.repositories` 里加阿里云镜像
  （该 included build 无法用 init script 注入项目级仓库）。
  原文件已备份到 `/tmp/flutter_tools_settings.gradle.kts.bak`，**Flutter 升级会覆盖，需重打**。

## 排查用命令

```bash
# 复现并看到被 NPE 吞掉的真实错误
./gradlew :app:dependencyInsight --configuration debugRuntimeClasspath --dependency <name>

# 确认 JDK 的 TLS 能否访问某个仓库
java -Djavax.net.debug=ssl,handshake ...   # 或写个最小 HttpURLConnection 测试
curl -s -o /dev/null -w "%{http_code}" <url>   # 对比：curl 能通 ≠ JDK 能通
```
