---
name: synology_doc_api_to_dart
descriptioni: "将一个 synology http api github 文档转为可读性更高、可维护、非常专业的 dart 代码"
---

### 学习当前项目代码风格，掌握 synology http api 规范

1、在本项目 lib/api 目录下，我已经完成了部分 api 的转换，学习这些代码风格和规范，按照我的代码风格和规范进行转换。比如，整个 api 以 dsm_api.dart 对外开放。每个模块建立单独的 dsm_api.module.dart 文件，有子模块的再建立子模块 dsm_api.module.submodule.dart 文件。子模块使用 part of / part 集中导出到 dsm_api.dart

2、synology http api 文档本地路径为 [synology-dsm-api](/Users/humphrey/Downloads/synology-dsm-api/docs/api-reference). 需要注意必选请求参数、可选请求参数、请求参数具体类型，最终如何调用 dsm_api.util.dart 中已经定义好的 get/post/download/upload 方法。
