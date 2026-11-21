import 'package:garden/util/log.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Browser extends HookWidget {
  final String url;
  final String? title;
  const Browser({super.key, required this.url, this.title});

  @override
  Widget build(BuildContext context) {
    final refresh = useSignal(0);
    final webviewController = useMemoized(() {
      return WebViewController()
        ..loadRequest(Uri.parse(url))
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) {
              //TODO 检查是否需要授权
              Log.info("onPageStarted");
            },
            onPageFinished: (_) {
              Log.info("onPageFinished");
              refresh.value++;
            },
            onWebResourceError: (WebResourceError error) {
              Log.info('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
          ''');
            },
          ),
        );
    }, const []);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: FutureBuilder<String?>(
          future: webviewController.platform.getTitle(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(snapshot.data ?? title ?? "加载中……");
            } else {
              return const SizedBox();
            }
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
            child: OutlinedButton(
              onPressed: () {
                launchUrlString(url, mode: LaunchMode.externalApplication);
              },
              child: Image.asset(
                "assets/icons/browser.png",
                width: 20,
                height: 20,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: WebViewWidget(
              controller: webviewController,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Row(
                children: <Widget>[
                  FutureBuilder<bool>(
                    future: webviewController.canGoBack(),
                    builder: (context, shot) {
                      bool canGoBack = shot.data ?? false;
                      return OutlinedButton(
                        onPressed: canGoBack
                            ? () async {
                                await webviewController.goBack();
                                refresh.value++;
                              }
                            : null,
                        child: Icon(
                          Icons.arrow_back_ios_outlined,
                          color: canGoBack ? Colors.black : Colors.grey,
                          size: 22,
                        ),
                      );
                    },
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  FutureBuilder<bool>(
                    future: webviewController.canGoForward(),
                    builder: (context, shot) {
                      bool canGoForward = shot.data ?? false;
                      return OutlinedButton(
                        onPressed: canGoForward
                            ? () async {
                                await webviewController.goForward();
                                refresh.value++;
                              }
                            : null,
                        child: Icon(
                          Icons.arrow_forward_ios,
                          size: 22,
                          color: canGoForward ? Colors.black : Colors.grey,
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Icon(
                      Icons.close,
                      size: 22,
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  OutlinedButton(
                    onPressed: () {
                      webviewController.reload();
                    },
                    child: const Icon(
                      Icons.replay,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
