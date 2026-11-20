---
name: synology_doc_api_to_dart
descriptioni: "将一个 synology http api github 文档转为可读性更高、可维护、非常专业的 dart 代码"
---

### 学习当前项目代码风格，掌握 synology http api 规范

1、synology http api 文档在 lib/api/synology-dsm-api/docs/api-reference 目录.

1.1 需要注意必选请求参数、可选请求参数、请求参数具体类型，最终如何调用 dsm_api.util.dart 中已经定义好的 get/post/download/upload 方法。
1.2 没有的参数、没有的注释不要自行添加，忠于原文档！

2、在本项目 lib/api 目录下，我已经完成了部分 api 的转换，学习这些代码风格和规范，按照我的代码风格和规范进行转换。

2.1、比如，整个 api 以 dsm_api.dart 对外开放。每个子模块建立单独的 dsm_api.module.dart 文件，有子模块的再建立子模块 dsm_api.module.submodule.dart 文件。子模块使用 part of / part 集中导出到 dsm_api.dart
2.2、dsm_api.util.dart 已经封装了通用的 http get/post/download/upload 方法，直接调用即可。
2.3、注意我的注释风格，注释要详细，方便他人阅读和后期维护。但是注释要忠于原文档，原文档没有的注释不要私自添加。原文档有的注释，不要漏了。（比如参数的注释说明， 函数或者模块的 notes 说明 **Notes:**）
2.4、注意，我并没有将所有 api 都转换完成，只是转换了部分 api（synolog core 全部， filestation 中的 favorites、file-operations、search、sharing、upload-download ），所以你只需要转换你需要的 api 即可。
2.5 注意函数参数要忠于原文档，不要想当然自行添加参数。函数、参数命名风格要统一。
2.6 进行迁移时，注意不要漏了文档。要按照规范将 api-reference 目录下的所有文档（包括子目录下）的都进行迁移。
2.7 要注意迁移符合 dart 语法规范。比如文档中标注 required 的函数参数，在 dart 函数中就是必须参数，不能省略，不能为可空，调用者必须传入。文档中标注为 optional 的参数，在 dart 函数中就是可选参数，可以为可空，调用者可以不传入。
