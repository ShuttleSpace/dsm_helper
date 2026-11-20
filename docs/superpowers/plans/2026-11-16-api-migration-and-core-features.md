# API 迁移与三大核心功能 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 通过 compat 桥接层将 49 个文件 / 136 个调用点从 `lib/util/api.dart` 的 `DsmApi` 迁移到 `lib/api/dsm_api.dart`，删除旧实现；并在新层上把 NAS 文件预览、文件上传/下载（多文件、**上传与下载均字节级断点续传**）与同步备份做到可用。

**Architecture:** S0 修正新层 3 个 method bug、补 4 个缺失 API 与 17 个 quirk 的兼容实现，并让 `DSMException` 保留原始 error payload；S1 新增 `dsm_api_compat.dart`（`class DsmApi` 静态方法返回旧 `{success,data,error}` 信封，内部调用新层/底层 `_http*`），改 `http_util.dart` export 并删 `api.dart`，页面零改；S2 在 transfer/preview/backup 链路上做功能硬化（上传续传前置验证 API 能力，不支持则实现分片/追加或显式降级并标注），S3（可选）逐模块直迁后删 compat。

**Tech Stack:** Flutter/Dart、`dio`、`signals`/`signals_flutter`/`flutter_hooks`、`background_downloader`、`sp_util`/`SharedPreferences`（测试）、`flutter_test`。

**Spec:** `docs/superpowers/specs/2026-11-16-api-migration-and-core-features-design.md`（本计划与 spec 同读；执行者须遵守 spec 的阶段、边界与验收）

## Global Constraints

- **契约不变**：S1 期间 124 处检查 `res['success']`/`res['error']`、46 处读取 `res['error']['code']` 的调用点必须无需修改即可工作；compat 返回形状兼容旧信封（含 compound 方法的 `result[]` 结构与嵌套 `error.errors` 等字段）。
- **新层语义**：`lib/api/dsm_api*.dart` 成功返回 `res['data']`，失败抛 `DSMException`；`DSMException` 必须携带可还原原始 `error` 的信息，兼容层据此重建信封。
- **旧文件边界**：S1 完成后仓库无 `lib/util/api.dart` 与旧 `class DsmApi` 定义；`lib/util/http_util.dart` **保留**（含 `HttpUtil` 单例、extensions re-export、`file_types.dart` 导出），仅替换对 `api.dart` 的导出。
- **不破坏核心链路**：预览/下载/上传现有行为优先保留再扩展；备份 `lib/pages/backup/backup.dart` 在 S2 前行为不退化。S2 仅在可控目录/小文件验证。
- **断点续传（已拍板）**：上传、下载都做字节级断点续传。S2 首要子步**前置验证** `SYNO.FileStation.Upload`（及现有下载端点）对分片/偏移/追加与半成品续传的支持；不支持则计划内明确替代方案（如客户端分片+合并）或显式降级并在 UI/文档标注限制，**不得静默承诺**。
- **范围**：不为 217 个生成函数逐一建页；不重写 `HttpUtil`/整体 transfer 架构；不接入非 `SYNO.*` 套件；不触碰用户并发未提交改动。
- **验证门禁**：每阶段/任务完成 `flutter analyze` + `flutter test` 全绿（或注明范围）；S1 grep 无 `util/api.dart` 引用；S2 三大功能手工回归（多文件、暂停续传、备份上传）。
- **环境**：`/Users/humphrey/Project/Flutter/dsm_helper`；DSM `http://192.168.8.40:5000`（humphrey，2FA）；测试命令 `flutter test` / `flutter test <path>` / `flutter analyze`。

## Review Focus

- **compat 信封丢字段**：`error.errors`（如 `power` 的 `runningTasks`、文件操作的 `errors[0].code==414`、`public_access/edit_ddns`）若未从原始响应透传，46+ 处页面逻辑静默错判。→ S0 为 `DSMException` 增加 raw error 携带并在 compat 单测断言嵌套字段透传。
- **compound 结构错配**：`systemInfo`/`downloadStationInfo`/`docker*Info`/`powerStatus` 等 15 个方法旧返回整包或 `data.result[]` 子项含 `success/api/data`；compat 若只包一层会破坏页面解析。→ S1 对每个 compound 方法写契约样例/映射并在单测固定结构。
- **上传字节级续传不可用却未降级标注**：DSM Upload API 可能不支持 offset/append，若直接宣称续传会在大文件/断网场景丢数据或假进度。→ S2 任务 1 强制真机/接口探测并记录结论，后续任务按结论分支实现且 UI 明示限制。
- **备份上传回归**：`backup.dart` 当前 `DsmApi.upload(uploadPath, filePath, cancelToken, onSendProgress)` 依赖 size/mtime/overwrite 行为与进度回调；迁移后若 Multipart/参数/进度语义变了会导致重复上传或无进度。→ S2 备份任务保留等价参数并做手工回归。
- **删除/修 method 后行为漂移**：修 `dsmCoreShareCreate`(`get`→`create`)、`dsmFileStationDeleteStatus`(`start`→`status`)、`dsmCoreCurrentConnectionGet`(`list`→`get`) 会改变真实请求；若有调用方依赖旧错行为会回归。→ S0 逐个加/改单测锁定 method 字符串与请求形状，并 grep 调用点确认预期。

---

## File Structure

- `lib/util/api.dart` — **删除**（S1）：旧 `DsmApi` 137 方法。
- `lib/util/http_util.dart` — **修改**：仅将 `export 'package:garden/util/api.dart';` 替换为 compat 导出；保留 `HttpUtil`、extensions、`file_types` 导出。
- `lib/api/dsm_api.base.dart` — **修改**：`DSMException` 增加原始 `error`/响应承载（如 `rawError`、`rawResponse`）并在 `fromMap` 填充；保持现有字段/`toString` 兼容。
- `lib/api/dsm_api.core.dart`、`dsm_api.core.shares.dart`、`dsm_api.filestation.fileoperations.dart` — **修改**：修 3 个 method bug。
- `lib/api/dsm_api.gaps.dart`（新建）或分散到对应 part — **创建/修改**：补 `logHistory`/`reward`/`downloadFileList`/`downloadCreate` 等价 `dsmXxx`（及必要的 DownloadStation2.Task.List* 支持）。
- `lib/api/dsm_api.dart` — **修改**：`part` 声明包含 compat/gaps 新文件（若采用 part）。
- `lib/api/dsm_api_compat.dart` — **创建**：`class DsmApi` 兼容层，136 个旧调用名的静态方法，返回旧信封；compound/quirk/GAP 特殊处理集中于此。
- `lib/pages/backup/backup.dart` — **修改**（S2）：上传改走新层/兼容语义，保持参数与进度行为。
- `lib/stores/transfer_store.dart`、`lib/pages/download/*`、`lib/pages/file/upload.dart`、`lib/services/transfer_*`、`lib/api/dsm_api.filestation.{uploaddownload,transfer_url,transfer_contract}.dart` — **修改**（S2）：多文件与上传/下载字节级断点续传、任务持久化/恢复、UI 状态。
- `lib/pages/common/{image_preview,office_preview,video_player,pdf_viewer,text_editor}.dart`、`lib/pages/file/file.dart` — **修改**（S2）：预览取流/URL 统一新层，失败态。
- `test/api/dsm_api_compat_test.dart`、`test/api/dsm_api_gaps_test.dart`（新建）及既有 transfer/backup 相关测试 — **创建/修改**：锁契约与回归。

---

## Task 1: S0 — 修 3 个新层 method bug 并锁定请求

**Files:**
- Modify: `lib/api/dsm_api.core.shares.dart:76-120` (`dsmCoreShareCreate`)
- Modify: `lib/api/dsm_api.core.dart:367-399` (`dsmCoreCurrentConnectionGet`)
- Modify: `lib/api/dsm_api.filestation.fileoperations.dart:195-210` (`dsmFileStationDeleteStatus`)
- Test: `test/api/dsm_api_core_method_fixes_test.dart` (Create)

**Interfaces:**
- Produces: `dsmCoreShareCreate` 发送 `api:SYNO.Core.Share, method:create, version:1`；`dsmFileStationDeleteStatus` 发送 `api:SYNO.FileStation.Delete, method:status, version:2` + `taskid`；`dsmCoreCurrentConnectionGet` 发送 `api:SYNO.Core.CurrentConnection, method:get`（保留 `action/sort/start/limit/offset` 参数语义，对齐旧 `currentConnect`）。
- Consumes: `_dsmApiRequestData`, `_httpPost/_httpGet`。

- [ ] **Step 1: Write failing tests for method strings**

```dart
// test/api/dsm_api_core_method_fixes_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dsmCoreShareCreate builds method=create', () {
    // arrange request data the same way impl does and assert method == 'create'
    // (extract helper or mirror: api SYNO.Core.Share, version 1)
    final data = {'api': 'SYNO.Core.Share', 'method': 'create', 'version': 1};
    expect(data['method'], 'create');
  });
  test('dsmFileStationDeleteStatus builds method=status', () {
    final data = {'api': 'SYNO.FileStation.Delete', 'method': 'status', 'version': 2};
    expect(data['method'], 'status');
  });
  test('dsmCoreCurrentConnectionGet builds method=get', () {
    final data = {'api': 'SYNO.Core.CurrentConnection', 'method': 'get', 'version': 1};
    expect(data['method'], 'get');
  });
}
```
（占位断言；实现时改为对实际函数可测的 request 构造/注入方式——若无注入点，改为源码断言测试或暴露 `_buildXxxRequest` 小 helper，择一使失败可观测。）

- [ ] **Step 2: Run test to verify it fails (or captures current wrong value)**

Run: `flutter test test/api/dsm_api_core_method_fixes_test.dart -v`
Expected: FAIL（当前 create/get/status 实际为 get/list/start）或按所选策略失败。

- [ ] **Step 3: Implement minimal fixes**

`lib/api/dsm_api.core.shares.dart`：`dsmCoreShareCreate` 中 `_dsmApiRequestData(... method: 'get', ...)` → `method: 'create'`。
`lib/api/dsm_api.filestation.fileoperations.dart`：`dsmFileStationDeleteStatus` 中 `method: 'start'` → `method: 'status'`（保留 GET + taskid）。
`lib/api/dsm_api.core.dart`：`dsmCoreCurrentConnectionGet` 中 `method: 'list'` → `method: 'get'`；核对旧 `currentConnect` 参数（`action`, `start/offset/limit`, `sort_by/sort_direction`）并对齐。

- [ ] **Step 4: Run tests**

Run: `flutter test test/api/dsm_api_core_method_fixes_test.dart -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/api/dsm_api.core.shares.dart lib/api/dsm_api.core.dart lib/api/dsm_api.filestation.fileoperations.dart test/api/dsm_api_core_method_fixes_test.dart
git commit -m "fix(api): correct create/status/get method strings for share delete-status current-connection"
```

## Task 2: S0 — `DSMException` 保留原始 error payload

**Files:**
- Modify: `lib/api/dsm_api.base.dart` (`DSMException`, `fromMap`)
- Test: `test/api/dsm_exception_raw_error_test.dart` (Create)

**Interfaces:**
- Produces: `DSMException.rawError`（或等价名，`Map?`）保存 `res['error']` 原对象；`DSMException.rawResponse`（可选）保存原 `res`；`fromMap` 填充；现有 `message/code/descriptionOrSolution/toString` 行为不回归。
- Consumes: compat（Task 4）用 `e.rawError ?? {'code': e.code}` 重建信封。

- [ ] **Step 1: Write failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/api/dsm_api.dart';

void main() {
  test('DSMException.fromMap preserves nested error payload', () {
    final res = {
      'success': false,
      'error': {
        'code': 117,
        'errors': {'runningTasks': [{'name': 't'}]}
      }
    };
    final e = DSMException.fromMap(res);
    expect(e.code, 117);
    expect(e.rawError, isA<Map>());
    expect((e.rawError!['errors'] as Map)['runningTasks'], isNotNull);
  });
}
```

- [ ] **Step 2: Run to verify fail**

Run: `flutter test test/api/dsm_exception_raw_error_test.dart -v`
Expected: FAIL（`rawError` 不存在或为空）

- [ ] **Step 3: Implement**

在 `DSMException` 增加字段（如 `final Map? rawError; final Map? rawResponse;`）并在 `fromMap` 赋值：`rawError: error is Map ? Map<String,dynamic>.from(error) : null`，`rawResponse: Map<String,dynamic>.from(res)`；所有返回路径带上。

- [ ] **Step 4: Run to verify pass**

Run: `flutter test test/api/dsm_exception_raw_error_test.dart -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/api/dsm_api.base.dart test/api/dsm_exception_raw_error_test.dart
git commit -m "fix(api): preserve raw error payload in DSMException for compat envelope"
```

## Task 3: S0 — 补 4 个 GAP 的新层函数

**Files:**
- Modify/Create: `lib/api/dsm_api.systemservices.logcenter.dart` 或新建 `lib/api/dsm_api.gaps.dart`（并在 `lib/api/dsm_api.dart` 加 `part`）
- Modify: `lib/api/dsm_api.downloadstation.tasks.dart` 或 gaps（`Task.List`/`Task.List.Polling`）
- Modify: `lib/api/dsm_api.util.dart` 或 gaps（`reward` 需 GET 绝对路径 `${connectionStore.baseUri}/reward`，行为同旧 `HttpUtil.instance.get`）
- Test: `test/api/dsm_api_gaps_test.dart` (Create)

**Interfaces:**
- Produces: `dsmLogCenterHistoryList(...)` → `SYNO.LogCenter.History|list`；`dsmDownloadStation2TaskListGet(String listId, ...)` → `SYNO.DownloadStation2.Task.List|get`；`dsmDownloadStation2TaskListPollingDownload(...)` → `SYNO.DownloadStation2.Task.List.Polling|download`（签名/参数对齐旧 `downloadFileList`/`downloadCreate`）；`dsmReward()`（或 `dsmAppReward`）→ GET `/reward` 返回解码 Map/原值（对齐旧 `reward`）。
- Consumes: `_httpGet/_httpPost/_httpRequest`, `_dsmApiRequestData`, `connectionStore.baseUri`。

- [ ] **Step 1: Read legacy signatures**

Run: `sed -n '1430,1475p;1545,1595p' lib/util/api.dart` 确认参数与请求体（`logHistory`、`downloadFileList(listId)`、`downloadCreate(...)`、`reward`）。

- [ ] **Step 2: Write failing tests**

```dart
// test/api/dsm_api_gaps_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/api/dsm_api.dart';

void main() {
  test('gap functions exist with expected signatures', () {
    // compile-time presence checks via tear-offs where possible
    expect(dsmLogCenterHistoryList, isA<Function>());
    expect(dsmDownloadStation2TaskListGet, isA<Function>());
    expect(dsmDownloadStation2TaskListPollingDownload, isA<Function>());
    expect(dsmReward, isA<Function>());
  });
}
```

- [ ] **Step 3: Run to verify fail**

Run: `flutter test test/api/dsm_api_gaps_test.dart -v`
Expected: FAIL（符号不存在）

- [ ] **Step 4: Implement minimal gap functions**

按旧方法参数构造请求：History 用 `_entryCGI` + `SYNO.LogCenter.History` `list`；Task.List 用 `SYNO.DownloadStation2.Task.List` `get` + `list_id`；Polling download 对齐旧参数；reward 用 `_dio`/`_httpRequest` GET 绝对 URL（保留 decode 行为）。注册 `part`。

- [ ] **Step 5: Run to verify pass**

Run: `flutter test test/api/dsm_api_gaps_test.dart -v`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/api test/api/dsm_api_gaps_test.dart
git commit -m "feat(api): add gap functions for log history, download task list/polling, reward"
```

## Task 4: S1 — Compat 桥接层（核心映射与信封）

**Files:**
- Create: `lib/api/dsm_api_compat.dart`
- Modify: `lib/api/dsm_api.dart`（如需 part/export）
- Test: `test/api/dsm_api_compat_test.dart` (Create)

**Interfaces:**
- Produces: `class DsmApi`（static methods，旧签名）→ `Future<Map>` 旧信封：成功 `{'success':true,'data':<data>}`，失败 `{'success':false,'error': <rawError|{'code':code}>, 'data':null,...}`；覆盖 137 方法名（含 30 未被调用但存在于类中的方法，保持二进制/反射层面安全可选，至少覆盖 136 调用点）。
- Consumes: 新层 `dsmXxx`、`_httpGet/_httpPost/_httpRequest/_dsmApiCall`、`DSMException`、`DsmApiInfo`/`MultipartFile`/`CancelToken` 等类型；旧用法依赖的参数默认值。
- Notes: 对嵌套 `error.errors` 必须透传原始 map；compound 方法返回值必须与旧实现同构（见 Task 5）。

- [ ] **Step 1: Build method inventory and mapping table**

Run: `python3 - <<'PY'\n# 从 lib/util/api.dart 提取 static Future 方法签名与 api/method，输出 mapping 草表\n...\nPY` 生成内部对照（可存为测试 fixture 或注释）；将 116 精确等价映射到对应 `dsmXxx`，17 quirk/4 gap 标记特殊处理。

- [ ] **Step 2: Write failing compat contract tests**

```dart
// test/api/dsm_api_compat_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:garden/api/dsm_api.dart'; // 通过 compat 暴露 DsmApi

void main() {
  group('compat envelope', () {
    test('wraps success data', () async {
      // 使用可注入/伪造路径或对纯映射 helper 断言：
      // expect(await DsmApi.<pureMappedCall>(), containsPair('success', true));
    });
    test('wraps DSMException with nested raw error', () {
      final e = DSMException.fromMap({'success':false,'error':{'code':117,'errors':{'runningTasks':[]}}});
      final wrapped = {'success': false, 'error': e.rawError ?? {'code': e.code}, 'data': null};
      expect((wrapped['error'] as Map)['errors'], isNotNull);
    });
  });
}
```
（将“可断言的纯逻辑”如 wrapper 函数抽为 `compatWrapSuccess/compatWrapError` 以便不依赖网络即可 TDD。）

- [ ] **Step 3: Run to verify fail**

Run: `flutter test test/api/dsm_api_compat_test.dart -v`
Expected: FAIL（`DsmApi`/wrapper 不存在）

- [ ] **Step 4: Implement compat skeleton + wrappers + non-compound methods**

创建 `dsm_api_compat.dart`：
```dart
part of 'dsm_api.dart';

Map<String,dynamic> _compatOk(dynamic data) => {'success': true, 'data': data};
Map<String,dynamic> _compatErr(Object e) {
  if (e is DSMException) return {'success': false, 'error': e.rawError ?? {'code': e.code}, 'data': null};
  return {'success': false, 'error': {'code': -1, 'message': e.toString()}, 'data': null};
}

class DsmApi { /* 先实现精确等价的简单方法，逐批补齐 */ }
```
对 116 精确等价逐个委托：`static Future<Map> xxx(...) async { try { return _compatOk(await dsmYyy(...)); } catch(e){ return _compatErr(e); } }`。对签名差异（参数名/可选参数/默认值）严格对齐旧 `api.dart`。`quickConnect/quickConnectCn/pingpong/reward` 等特殊方法按旧行为实现（保留原 endpoint/响应形状）。

- [ ] **Step 5: Run to verify pass**

Run: `flutter test test/api/dsm_api_compat_test.dart -v`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/api/dsm_api_compat.dart lib/api/dsm_api.dart test/api/dsm_api_compat_test.dart
git commit -m "feat(api): add DsmApi compat layer with envelope wrapping for migrated methods"
```

## Task 5: S1 — Compound / quirk 方法兼容与契约固定

**Files:**
- Modify: `lib/api/dsm_api_compat.dart`
- Modify: `lib/api/dsm_api.dart` / gaps（如需公开 compound helper）
- Test: `test/api/dsm_api_compat_compound_test.dart` (Create)

**Interfaces:**
- Produces: 15 个 compound 旧方法（`systemInfo,dockerContainerInfo,dockerImageInfo,downloadStationInfo,externalDevice,fileService,fileServiceSave,mediaIndexStatus,mediaIndexSet,powerStatus,powerSet,userDetail,userSave,publicAccessInfo,networkStatus`）返回与旧实现一致的结构；17 个 quirk（含 `installPackageStatus/Queue`、`eventRun`、`taskRecord`、`downloadTask*` DownloadStation vs DownloadStation2、`fileServiceLog/Save`、`mediaReindex`、`uninstallPackageTask` api 串差异）行为对齐旧方法。
- Consumes: `_dsmApiCall`（可在 compat 内直接构造 compound JSON 复刻旧逻辑）、底层 `_http*`。

- [ ] **Step 1: Capture legacy behavior for each compound/quirk**

对每个方法阅读 `lib/util/api.dart` 对应实现，记录：请求 compound 数组内容/顺序/mod、返回是原始响应还是 `res['data']`、子项字段。将关键样例写入测试 fixture。

- [ ] **Step 2: Write failing contract tests**

```dart
test('powerStatus returns result array envelope as legacy', () {
  // 断言 compat 构造的 compound payload / 解析后的结构含 data.result[*].api/data
});
test('fileServiceLog uses get_level method', () { /* request shape */ });
```
（对纯构造逻辑抽 helper；对需网络的用 fake/跳过并以 request-builder 单测覆盖。）

- [ ] **Step 3: Run to verify fail**

Run: `flutter test test/api/dsm_api_compat_compound_test.dart -v`
Expected: FAIL

- [ ] **Step 4: Implement**

在 compat 内为 compound 方法直接组装与旧版一致的 compound 请求并返回旧版期望的响应形状（多数旧实现直接 `return await HttpUtil.instance.post(...)` → 返回整包 Map；照此复刻）。quirk 方法：能映射新函数则映射并修正 method/api/version；不能则直调 `_httpGet/_httpPost` 精确复刻旧请求。**禁止静默改 api/method/version。**

- [ ] **Step 5: Run to verify pass**

Run: `flutter test test/api/dsm_api_compat_compound_test.dart -v`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/api/dsm_api_compat.dart test/api/dsm_api_compat_compound_test.dart
git commit -m "feat(api): compat handling for compound and quirk legacy methods"
```

## Task 6: S1 — 切换导出、删除旧实现、全量验证

**Files:**
- Modify: `lib/util/http_util.dart:17`（export）
- Delete: `lib/util/api.dart`
- Modify (如有): 直接 import `util/api.dart` 的文件（预期仅 http_util 自身；以 grep 确认）

**Interfaces:**
- Produces: `http_util.dart` 导出 `package:garden/api/dsm_api.dart` 或 `dsm_api_compat.dart`（确保 `DsmApi` 符号对 83 个 import 可见且类型一致）；`lib/util/api.dart` 不存在。

- [ ] **Step 1: Write/adjust a smoke test that imports via http_util path**

```dart
// e.g. extend test/api/dsm_api_compat_test.dart
import 'package:garden/util/http_util.dart'; // transitive
test('DsmApi available via http_util export', () { expect(DsmApi, isNotNull); });
```

- [ ] **Step 2: Run to verify current state**

Run: `flutter test test/api/dsm_api_compat_test.dart -v`
Expected: PASS/FAIL 取决于 export；记录。

- [ ] **Step 3: Switch export and delete legacy**

`lib/util/http_util.dart`：`export 'package:garden/util/api.dart';` → `export 'package:garden/api/dsm_api.dart';`（或确保 compat 随 dsm_api 导出）。
删除 `lib/util/api.dart`。运行 `grep -rn "util/api.dart" lib test` 确认无残留引用。

- [ ] **Step 4: Verify**

Run: `flutter analyze`  
Run: `flutter test`  
Run: `grep -rn "util/api.dart" lib test`（期望空）  
Expected: analyze/test 全绿；无旧文件引用。

- [ ] **Step 5: Commit**

```bash
git add -u lib/util/http_util.dart lib/util/api.dart lib test
git commit -m "refactor(api): switch to dsm_api compat export and remove legacy DsmApi"
```

## Task 7: S2 — 备份上传迁移（`backup.dart`）

**Files:**
- Modify: `lib/pages/backup/backup.dart`（`onStartBackup` 中 `DsmApi.upload`）
- Modify: `lib/api/dsm_api.filestation.uploaddownload.dart` / compat（如需进度回调签名对齐）
- Test: 相关现有/新增测试（如 `test/services/transfer_upload_test.dart` 扩展或新增 `test/pages/backup_upload_contract_test.dart`）

**Interfaces:**
- Consumes: 旧 `DsmApi.upload(String uploadPath, String filePath, CancelToken? cancelToken, Function(int,int) onSendProgress)`；需保持 `create_parents:true, size, mtime, overwrite:false, version<=3` 语义与进度回调。
- Produces: 备份通过新层/compat 完成上传，`UploadItem` 状态流转与 UI 进度不变。

- [ ] **Step 1: Write failing test for upload contract**

锁定：给定 path/file/回调，构造的请求含 `SYNO.FileStation.Upload` upload v2/<=3、`create_parents/size/mtime/overwrite` 字段；回调被转发。

- [ ] **Step 2: Run to verify fail**

Run: `flutter test <test_path> -v`

- [ ] **Step 3: Implement**

方案：在 compat 的 `DsmApi.upload` 内按旧实现语义调 `_httpUpload`/`_httpRequest`（FormData + `onSendProgress`）或扩展 `dsmFileStationUpload` 支持 `onSendProgress`；`backup.dart` 保持调用点不变（已由 compat 满足）或最小改为直接新函数——优先保持 compat 契约避免触碰 UI 逻辑。

- [ ] **Step 4: Verify**

Run: `flutter test`（相关子集） + `flutter analyze`  
手工：小文件备份上传、进度显示、失败 toast、完成记录 `last_backup_time`。

- [ ] **Step 5: Commit**

```bash
git add lib/pages/backup/backup.dart lib/api test
git commit -m "refactor(backup): migrate album backup upload to new API path with progress parity"
```

## Task 8: S2 — 上传/下载字节级断点续传（前置验证 + 实现）

**Files:**
- Modify: `lib/api/dsm_api.filestation.uploaddownload.dart`, `lib/api/dsm_api.filestation.transfer_url.dart`, `lib/api/dsm_api.filestation.transfer_contract.dart`
- Modify: `lib/services/transfer_download.dart`, `lib/services/transfer_engine.dart`, `lib/services/transfer_upload.dart`（按需创建）
- Modify: `lib/stores/transfer_store.dart`, `lib/pages/download/*`, `lib/pages/file/upload.dart`
- Test: `test/services/transfer_download_test.dart`, `test/services/transfer_upload_test.dart`, `test/services/transfer_engine_test.dart`, `test/stores/transfer_store_test.dart`（扩展）

**Interfaces:**
- Produces: 下载通过 Range/续写 + `background_downloader` `allowPause/resume` 实现字节级续传（单文件与多文件队列）；上传实现字节级续传——若 Upload API 支持 offset/append/分片则使用之，否则实现客户端分片上传+持久化偏移并在 UI 标注能力边界；任务可暂停/继续/重试，进度与状态持久化可恢复。
- Consumes: `fbDownloadUrl`/`uploadEntryUrl`、`connectionStore` 凭据、`FileDownloader`、本地文件系统。

- [ ] **Step 1: 前置验证（必须先完成并记录）**

探测：对下载端点发带 `Range: bytes=0-0` 请求确认 206/Accept-Ranges；对 `SYNO.FileStation.Upload` 检查是否存在 `offset`/`size`/分片参数或可追加语义（查现有实现、抓包/API 文档痕迹、必要时真机最小实验）。将结论写入 `docs/superpowers/plans/2026-11-16-api-migration-and-core-features.md` 本任务备注或单独 `docs/` 记录。

- [ ] **Step 2: Write failing tests per capability**

下载：给定部分文件/已传字节，构造 Range 头与续写偏移正确；任务恢复后从断点继续。上传：按验证结论写测试——支持分片则断言分片序号/offset；不支持则断言降级路径与明确状态/提示。

Run: `flutter test test/services/transfer_download_test.dart test/services/transfer_upload_test.dart test/stores/transfer_store_test.dart -v`
Expected: FAIL

- [ ] **Step 3: Implement download resumable**

确保 `buildDownloadTask`/引擎配置支持 pause/resume；对自管下载路径增加 Range + 断点文件续写；多文件队列逐项可独立暂停继续；持久化 `transferredBytes/chunks/localPath/remotePath/state` 并在启动恢复。

- [ ] **Step 4: Implement upload resumable (按 Step 1 结论分支)**

- 若支持 offset/append：实现分片/偏移续传与持久化。
- 若不支持：实现可行替代（如切片上传并记录已完成片）或任务级重试降级；在 `download.dart`/上传 UI 显示“上传断点续传受 DSM 限制：…”等明确信息。**禁止无提示假续传。**

- [ ] **Step 5: Wire UI (DS file 体验)**

`lib/pages/download/download.dart`、`file/upload.dart`、状态页：多选入队、每任务进度条/暂停/继续/重试/取消、失败原因展示；复用现有卡片/列表风格（`Card` 圆角 18、`CupertinoActivityIndicator`、中文文案）。

- [ ] **Step 6: Verify**

Run: `flutter test`（transfer 相关 + 全量）  
手工：多文件下载暂停后继续（杀进程/重启后恢复如引擎支持）、大文件中断续传；上传同等场景；对照 Step 1 结论核对行为。

- [ ] **Step 7: Commit**

```bash
git add lib/api lib/services lib/stores lib/pages/download lib/pages/file/upload.dart test docs
git commit -m "feat(transfer): add resumable multi-file upload/download with persisted task state"
```

## Task 9: S2 — 文件预览统一新层与失败态

**Files:**
- Modify: `lib/pages/common/image_preview.dart`, `office_preview.dart`, `video_player.dart`, `pdf_viewer.dart`, `text_editor.dart`
- Modify: `lib/pages/file/file.dart`（预览入口/取链）
- Modify: `lib/api/dsm_api.filestation.*`（如需直链/流 helper）
- Test: `test/services/office_preview_test.dart`（扩展）及必要的 widget/单测

**Interfaces:**
- Produces: 预览数据源经新层（`dsmFileStationDownload`/直链/鉴权 URL）获取；失败展示可读错误（`DSMException` message/code），不崩溃；沿用现有支持格式。
- Consumes: `connectionStore` 凭据、`HttpUtil`（如仍用于流媒体）与新 `dsmXxx`。

- [ ] **Step 1: Write failing tests for error surfacing / URL construction**

覆盖：鉴权头/URL 构造正确；失败时返回/展示错误态而非静默空白（按可测层选择 unit 或 widget）。

- [ ] **Step 2: Run to verify fail**

Run: `flutter test <paths> -v`

- [ ] **Step 3: Implement**

替换预览路径上的旧式/直拼请求为新层封装；统一 `try/catch (DSMException)` 提示；保持现有页面视觉与入口。

- [ ] **Step 4: Verify**

Run: `flutter test` + `flutter analyze`  
手工：图/视频/Office/PDF/文本预览与失败场景（无权限/不存在）。

- [ ] **Step 5: Commit**

```bash
git add lib/pages/common lib/pages/file/file.dart lib/api test
git commit -m "refactor(preview): source previews via new API layer with user-visible errors"
```

## Task 10: 收尾验证与 S3 规划备注（不实施直迁）

**Files:**
- Modify: `docs/superpowers/plans/2026-11-16-api-migration-and-core-features.md`（记录 S2 验证结论与 S3 候选）

- [ ] **Step 1: 全量门禁**

Run: `flutter analyze`  
Run: `flutter test`  
Run: `grep -rn "lib/util/api.dart" .`（应仅可能出现在历史文档/计划文字，代码与 import 不存在）

- [ ] **Step 2: 三大功能手工回归清单**

逐项勾选：文件预览（各格式）、多文件上传/下载暂停继续与（按 Step 8 结论的）断点续传、同步备份；记录环境与结果。

- [ ] **Step 3: 记录 S3 直迁候选**

列出可按模块从 compat 直迁到 `dsmXxx()+try/catch` 的页面组与优先级（不在本计划执行）。

- [x] **Step 4: Commit**

```bash
git add docs/superpowers/plans/2026-11-16-api-migration-and-core-features.md
git commit -m "docs: record migration verification and S3 follow-up candidates"
```

## 执行结果（2026-11-16 收尾）

### 全量门禁（已跑）
- `flutter analyze`：No issues found。
- `flutter test`：**111/111 全绿**。
- `grep -rn "util/api.dart" lib test`：仅 `lib/api/dsm_api_compat.dart` 一行文档注释（非代码引用）；`class DsmApi` 仅 compat 一处定义。旧 `lib/util/api.dart` 已删除。

### 提交链（S0→S2，逐任务审查通过）
S0：`a95eccd`(method bug) → `e4dddb2`(DSMException rawError) → `7b6e93e`+`b6cbcdf`(4 GAP，含 1 轮修复)。  
S1：`bbec769`(compat) → `247b447`(compound/quirk) → `1f133ab`(切 export + 删 api.dart)。  
S2：`cb199d3`(备份契约) → `a2f378a`+`0cfcaa9`(断点续传，含 206 校验修复) → `e1d12ba`(预览)。

### 三大功能验收状态
| 功能 | 状态 | 备注 |
|---|---|---|
| NAS 文件预览 | ✅ 代码完成，⚠️ 待真机 | 取链统一新层 + 失败态；外部「打开方式」经 `_sid` 直链给第三方 App 需真机验（旧 `/fbdownload` 在 DSM 7.3.2 已失效） |
| 上传/下载 | ✅ 代码完成，⚠️ 上传降级 | 下载字节级续传（background_downloader pause/resume + 自管 Range 助手，仅确认 206 才追加）；**上传为任务级重试，非字节级**——见下 |
| 同步备份 | ✅ 契约锁定 | `backup.dart` 零改，经 compat 走新层；上传请求形状/进度/版本上限已单测锁定 |

### 偏离用户原话（须用户知情确认）
- 用户拍板「上传下载都要字节级断点续传」，但**上传实际降级为任务级重试**。依据 spec §7 授权分支：真机探测无有效 FileStation SID（2FA + 浏览器离线）无法实测 v3 分片；抓包证据显示 DSM 官方客户端传 238MB 仍用 v2 单请求、`all_api.json5` 无分片参数、v3 字段未实测。已在 UI + `docs/superpowers/specs/2026-11-16-transfer-capability-probe.md` 明示限制，无假续传。详见 §"仍需真机补验"。

### 仍需真机补验（本环境无法完成，非阻塞）
1. 有效 SID 下对下载端点发 `Range` → 确认 206；确认后可开 `downloadConcurrency=4` 并行下载并比对校验和。
2. 有效 SID 下 2 分片 `v3` 上传实测字段名/`upload_id` 握手/拼合时机；**仅实测通过后才置 `kUploadV3Supported=true`**，届时才可宣称上传字节级续传。
3. 外部「打开方式」（`use_file_click.dart` → `AndroidIntent`）经 `_sid` webapi 直链能否被第三方 App（WPS/VLC/下载器）取到文件。
4. 图/视频/Office/PDF/文本预览与各失败态；`await player.open` 无卡顿/黑屏回归。

### S3 直迁候选（未在本计划执行）
compat 117+ 方法为保持零漂移直接复刻旧请求体。后续可按模块把页面从 `DsmApi.xxx` 直迁到 `dsmXxx()+try/catch` 并最终删 compat。建议优先级（按页面调用密度 / 风险）：
1. **低风险先做**：控制面板只读页（info、network、hardware、users list）——多为 get/list，直接映射新函数。
2. **中风险**：`file.dart`（19 处）、`packages/detail.dart`（6）、`virtual_machine.dart`（7）——先直迁读方法，写方法随后。
3. **高风险最后**：`file_service`(18 子 api compound)、`power`/`userSave`(compound)、`upload`/`downloadTask*`(multipart/ dynamic method)——保持复刻或专项验证后再迁。
每模块直迁后跑 `analyze`+`test`；全部完成后删除 compat 与 http_util 的 `show DsmApi` 导出。

---

## Self-Review Notes

- **Spec 覆盖**：T1→S1(Task4-6)；T4 备份→Task7；T3 上传下载/断点续传→Task8（含前置验证与分支）；T2 预览→Task9；4 GAP+3 bug+17 quirk→Task1,3,4,5；`DSMException` raw error→Task2。§7 决议（S1 纯 compat、上传下载都续传、预览范围不扩）已写入约束与 Task8。
- **粒度**：每 Task 自带测试/验证与提交；S2 中上传续传依赖 Step 1 结论属有意分支，已明确不可静默承诺。
- **待实现期细化**：各 compat 方法的逐一签名表、15 个 compound 的精确 payload/返回样例、DownloadStation vs DownloadStation2 的参数差异，需在 Task4/5 Step 1 从 `lib/util/api.dart` 与调用点落盘为映射/fixture 后再编码；Task8 的上传 API 能力结论决定分支实现细节。
- **类型/一致性**：计划引用的函数/文件均为仓库现存或明确新建；`_compatOk/_compatErr` 与 `DSMException.rawError` 为 Task2/4 定义的接口。
- **Review Focus**：已列 5 项并映射到对应任务测试点；S2 手工回归为必要补充（网络/真机能力无法全由单测覆盖）。