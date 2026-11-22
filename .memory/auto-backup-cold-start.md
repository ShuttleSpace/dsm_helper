---
name: auto-backup-cold-start
description: How 自动备份 works (cold-start auto-continue) and its one-shot guard
type: project
---

`自动备份` 是冷启动自动续传，不是系统后台调度：开关存在 `StorageUtil` 键 `auto_backup`（默认 false，备份页卡片切换），`runAutoBackup()` 由 `lib/pages/home.dart` 首次构建的 `useEffect` 调用一次，读 `backup_folder` / `backup_album`（相册 id 列表 JSON）/ `last_backup_time`，再走 `startAutoBackup()` → `startBackup()`，生成一条父任务 + 每张照片一个子步骤。

**Why:** 首页只在登录成功后可达（`login.dart` / `accounts.dart` 都 `pushNamedAndRemoveUntil("/home")`），此时 NAS 会话已就绪；用户先要 C（workmanager/BGTaskScheduler）后改选 A，因为 iOS/Android 后台调度不保证执行时间。

**How to apply:** 想加“app 常驻期间也自动备份”时，只需在 `runAutoBackup()` 外再挂一个触发器；进程内去重靠文件级 `_autoBackupRan`（同一进程登出再登录不会重新触发，`paused` 父任务也算 pending）。跳过条件：未开启 / 无目的地 / 无相册 / 权限非 authorized / 已有未完成备份父任务 / 无新文件；全部静默，只有 `Log.info` 记录原因。

**Related:** `lib/pages/backup/backup.dart`, `lib/pages/home.dart`, `docs/superpowers/specs/2026-11-21-auto-backup-design.md`
