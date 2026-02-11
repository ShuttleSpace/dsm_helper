import 'dart:convert';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';

import 'package:flutter/material.dart';
import 'package:garden/extensions/context.dart';
import 'package:webview_flutter/webview_flutter.dart';

class DeviceFinder extends StatefulWidget {
  final String url;
  final String? title;
  const DeviceFinder({super.key, required this.url, this.title = "设备发现"});
  @override
  DeviceFinderState createState() => DeviceFinderState();
}

class DeviceFinderState extends State<DeviceFinder> {
  final WebViewController _webviewController = WebViewController();
  bool _isSearching = false;
  List<Map<String, String>> _devices = [];
  bool _showDeviceList = false;

  @override
  void initState() {
    _webviewController
      ..loadRequest(Uri.parse(widget.url))
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            Log.debug("onPageStarted: $url");
            setState(() {
              _isSearching = true;
              _showDeviceList = false;
              _devices = [];
            });
          },
          onPageFinished: (_) {
            Log.debug("onPageFinished");
            setState(() {});
            // 等待页面完全加载后再注入 JavaScript
            Future.delayed(const Duration(milliseconds: 500), () {
              // 允许混合内容
              _webviewController.runJavaScript('''
                console.log("Setting up CSP...");
                // 允许混合内容
                if (window.location.protocol === 'https:') {
                  const meta = document.createElement('meta');
                  meta.httpEquiv = 'Content-Security-Policy';
                  meta.content = 'upgrade-insecure-requests';
                  document.head.appendChild(meta);
                  console.log("CSP meta tag added");
                }
              ''').then((_) {
                Log.debug("CSP setup complete");
                _injectJavaScript();
              }).catchError((e) {
                Log.debug("Error setting up CSP: $e");
                _injectJavaScript();
              });
            });
          },
          onWebResourceError: (WebResourceError error) {
            Log.debug('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
            ''');
          },
        ),
      )
      ..addJavaScriptChannel(
        'DeviceFinder',
        onMessageReceived: _handleMessageReceived,
      );
    super.initState();
  }

  void _injectJavaScript() {
    // 注入JavaScript代码来监听设备发现
    const jsCode = '''
(function() {
  console.log("DeviceFinder script injected");
  
  // 检查 DeviceFinder 是否已定义
  if (typeof DeviceFinder === 'undefined') {
    console.log("DeviceFinder not defined, waiting for channel registration...");
    
    // 等待 Flutter 注入 DeviceFinder 对象
    let checkCount = 0;
    const checkInterval = setInterval(function() {
      checkCount++;
      console.log("Checking for DeviceFinder... attempt " + checkCount);
      
      if (typeof DeviceFinder !== 'undefined') {
        console.log("DeviceFinder is now defined!");
        clearInterval(checkInterval);
        
        // 测试通道
        try {
          DeviceFinder.postMessage(JSON.stringify({type: 'channelTest', message: 'Channel working'}));
          console.log("Channel test successful");
        } catch (e) {
          console.error("Channel test failed:", e);
        }
      } else if (checkCount > 10) {
        console.error("DeviceFinder channel not found after 10 attempts");
        clearInterval(checkInterval);
      }
    }, 500);
  } else {
    console.log("DeviceFinder already defined");
  }
  
  // 创建本地版本的 extractDevices 函数（如果需要手动调用）
  window.extractDevices = extractDevices;
  
  // 提取设备信息的函数
  function extractDevices() {
    const devices = [];
    
    try {
      // 查找设备表格行 - 使用多种选择器
      const rows = document.querySelectorAll('tbody tr[role="row"], .v-table-tbody tr, table tbody tr');
      
      rows.forEach(function(row) {
        try {
          const cells = row.querySelectorAll('td[role="cell"], td');
          if (cells.length >= 2) {
            let name = '';
            let ipAddress = '';
            let macAddress = '';
            let osVersion = '';
            let model = '';
            let status = '';
            
            // 提取各个列的信息
            cells.forEach(function(cell, index) {
              const cellContent = cell.textContent || cell.innerText || '';
              
              if (index === 0) {
                // 服务器名称
                name = cellContent.trim();
              } else if (index === 1) {
                // IP 地址 - 查找 web-ip 类
                const ipSpan = cell.querySelector('.web-ip span, span');
                if (ipSpan) {
                  ipAddress = ipSpan.textContent.trim();
                } else {
                  // 尝试从文本中提取IP地址
                  const ipMatch = cellContent.match(/\\b(?:\\d{1,3}\\.){3}\\d{1,3}\\b/);
                  if (ipMatch) {
                    ipAddress = ipMatch[0];
                  }
                }
              } else if (index === 2) {
                // MAC 地址
                macAddress = cellContent.trim();
              } else if (index === 3) {
                // OS 版本
                osVersion = cellContent.trim();
              } else if (index === 4) {
                // 产品型号
                model = cellContent.trim();
              } else if (index === 5) {
                // 状态
                status = cellContent.trim();
              }
            });
            
            // 如果找到了有效的IP地址，添加到设备列表
            if (ipAddress) {
              devices.push({
                name: name,
                host: ipAddress,
                mac: macAddress,
                osVersion: osVersion,
                model: model,
                status: status,
                port: '5000'
              });
            }
          }
        } catch (e) {
          console.error("Error processing row:", e);
        }
      });
    } catch (e) {
      console.error("Error extracting devices:", e);
    }
    
    // 如果找到了设备，发送给Flutter
    if (devices.length > 0) {
      try {
        DeviceFinder.postMessage(JSON.stringify({
          type: 'devicesFound',
          devices: devices
        }));
      } catch (e) {
        console.error("Error sending devices to Flutter:", e);
      }
    }
    
    return devices.length;
  }
  
  // 监听页面变化
  const observer = new MutationObserver(function(mutations) {
    let shouldExtract = false;
    mutations.forEach(function(mutation) {
      if (mutation.addedNodes && mutation.addedNodes.length > 0) {
        mutation.addedNodes.forEach(function(node) {
          if (node.nodeType === 1) {
            // 检查是否添加了表格行
            if (node.tagName === 'TR' || node.querySelector && node.querySelector('tr')) {
              shouldExtract = true;
            }
          }
        });
      }
    });
    
    if (shouldExtract) {
      setTimeout(extractDevices, 500);
    }
  });
  
  observer.observe(document.body, { childList: true, subtree: true });
  
  // 定期检查设备列表
  let lastDeviceCount = -1;
  setInterval(function() {
    try {
      const count = extractDevices();
      if (count > 0 && count !== lastDeviceCount) {
        console.log("Found " + count + " devices");
        lastDeviceCount = count;
      }
    } catch (e) {
      console.error("Error in interval check:", e);
    }
  }, 3000);
  
  // 初始检查
  setTimeout(function() {
    try {
      extractDevices();
    } catch (e) {
      console.error("Error in initial check:", e);
    }
  }, 5000);
  
  // 监听URL变化
  let lastUrl = window.location.href;
  new MutationObserver(function() {
    const currentUrl = window.location.href;
    if (currentUrl !== lastUrl) {
      lastUrl = currentUrl;
      console.log("URL changed to: " + currentUrl);
      setTimeout(extractDevices, 1000);
    }
  }).observe(document, { subtree: true, childList: true });
  
  console.log("DeviceFinder script loaded successfully");
})();
    ''';
    _webviewController.runJavaScript(jsCode).then((_) {
      Log.debug("JavaScript injected successfully");
    }).catchError((e) {
      Log.debug("Error injecting JavaScript: $e");
    });
  }

  void _handleMessageReceived(JavaScriptMessage message) {
    Log.debug("Received message: ${message.message}");
    try {
      final data = message.message;
      if (data.isNotEmpty) {
        final json = jsonDecode(data) as Map<String, dynamic>;
        if (json['type'] == 'devicesFound') {
          final List<dynamic> devicesList = json['devices'] as List<dynamic>;
          final List<Map<String, String>> devices =
              devicesList.map((d) => Map<String, String>.from(d)).toList();

          setState(() {
            _devices = devices;
            _showDeviceList = devices.isNotEmpty;
            _isSearching = false;
          });

          UiUtil.toast("找到 ${devices.length} 个设备");
        }
      }
    } catch (e) {
      Log.debug("Error parsing message: $e");
    }
  }

  void _selectDevice(Map<String, String> device) {
    Navigator.of(context).pop(jsonEncode(device));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () async {
            if (await _webviewController.canGoBack()) {
              await _webviewController.goBack();
              setState(() {});
            } else {
              if (context.mounted) {
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop();
              }
            }
          },
          icon: Icon(
            Icons.arrow_back_ios_outlined,
            size: 22,
            color: Theme.brightnessOf(context) == Brightness.light
                ? Colors.black
                : Colors.white,
          ),
        ),
        title: FutureBuilder<String?>(
          future: _webviewController.platform.getTitle(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(snapshot.data ?? widget.title ?? "加载中……",
                  style: TextStyle(
                      color: Theme.brightnessOf(context) == Brightness.light
                          ? Colors.black
                          : Colors.white));
            } else {
              return Text(
                widget.title ?? "设备发现",
                style: TextStyle(
                    color: Theme.brightnessOf(context) == Brightness.light
                        ? Colors.black
                        : Colors.white),
              );
            }
          },
        ),
        actions: [
          const SizedBox(
            width: 72,
          ),
          FutureBuilder<bool>(
            future: _webviewController.canGoForward(),
            builder: (context, shot) {
              bool canGoForward = shot.data ?? false;
              return OutlinedButton(
                style: context.stadiumButtonStyle,
                onPressed: canGoForward
                    ? () async {
                        await _webviewController.goForward();
                        setState(() {});
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Icon(
                Icons.close,
                size: 22,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: OutlinedButton(
              onPressed: _isSearching
                  ? null
                  : () {
                      _webviewController.reload();
                      setState(() {
                        _isSearching = true;
                        _showDeviceList = false;
                        _devices = [];
                      });
                    },
              child: Icon(
                Icons.refresh,
                size: 20,
                color: _isSearching ? Colors.grey : null,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(
                  controller: _webviewController,
                ),
                // 设备列表遮罩层
                if (_showDeviceList && _devices.isNotEmpty)
                  Container(
                    color: Colors.black.withValues(alpha: .5),
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        constraints: BoxConstraints(
                          maxWidth: 500,
                          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 标题栏
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.withValues(alpha: .3),
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '找到 ${_devices.length} 个设备',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      setState(() {
                                        _showDeviceList = false;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            // 设备列表
                            Flexible(
                              child: ListView.separated(
                                shrinkWrap: true,
                                padding: const EdgeInsets.all(16),
                                itemCount: _devices.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(),
                                itemBuilder: (context, index) {
                                  final device = _devices[index];
                                  return InkWell(
                                    onTap: () => _selectDevice(device),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            device['name'] ?? '未知设备',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'IP: ${device['host'] ?? ''}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          if (device['model'] != null &&
                                              device['model']!.isNotEmpty)
                                            Text(
                                              '型号: ${device['model']}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
