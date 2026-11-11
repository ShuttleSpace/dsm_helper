import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class TextEditor extends HookWidget {
  final String fileName;
  final String content;
  const TextEditor({super.key, required this.fileName, required this.content});

  String detectLanguage() {
    String ext = fileName.split(".").last;
    switch (ext) {
      case "py":
        return "python";
      case "php":
        return "php";
      case "html":
        return "html";
      case "xml":
        return "xml";
      case "txt":
        return "plaintext";
      case "sql":
        return "sql";
      case "sh":
        return "shell";
      case "json":
        return "json";
      case "css":
        return "css";
      case "scss":
        return "scss";
      case "java":
        return "java";
      case "js":
        return "javascript";
      case "kt":
        return "kotlin";
      case "md":
        return "markdown";
      default:
        return "plaintext";
    }
  }

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();
    final language = useMemoized(detectLanguage, const []);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("查看文件"),
      ),
      body: DraggableScrollbar.semicircle(
        controller: scrollController,
        child: ListView(
          controller: scrollController,
          children: [
            HighlightView(
              // The original code to be highlighted
              content,

              // Specify language
              // It is recommended to give it a value for performance
              language: language,
              // Specify highlight theme
              // All available themes are listed in `themes` folder
              theme: githubTheme,

              // Specify padding
              padding: const EdgeInsets.all(12),
            )
          ],
        ),
      ),
    );
  }
}
