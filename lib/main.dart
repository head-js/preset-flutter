import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plugin Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<ConnectivityResult> _connectivityResult = [ConnectivityResult.none];
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  AndroidDeviceInfo? _androidDeviceInfo;
  PackageInfo? _packageInfo;
  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _getDeviceInfo();
    _getPackageInfo();
    _initWebView();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _initConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      _connectivityResult = result;
    });
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) {
      setState(() {
        _connectivityResult = result;
      });
    });
  }

  Future<void> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    setState(() {
      _androidDeviceInfo = androidInfo;
    });
  }

  Future<void> _getPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = packageInfo;
    });
  }

  void _initWebView() {
    _webViewController =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (int progress) {
                debugPrint('WebView loading: $progress%');
              },
              onPageStarted: (String url) {
                debugPrint('Page started: $url');
              },
              onPageFinished: (String url) {
                debugPrint('Page finished: $url');
              },
              onWebResourceError: (WebResourceError error) {
                debugPrint(
                  'WebView error: ${error.description} (code: ${error.errorCode})',
                );
              },
            ),
          )
          ..loadRequest(Uri.parse('https://www.baidu.com'));
  }

  String _connectivityText() {
    if (_connectivityResult.contains(ConnectivityResult.wifi)) {
      return 'WiFi';
    } else if (_connectivityResult.contains(ConnectivityResult.mobile)) {
      return 'Mobile';
    } else if (_connectivityResult.contains(ConnectivityResult.none)) {
      return 'None';
    } else {
      return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Plugin Integration Demo'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('connectivity_plus@6.0.5: ${_connectivityText()}'),
                  const SizedBox(height: 8),
                  Text(
                    'device_info_plus@11.5.0: ${_androidDeviceInfo?.brand ?? "-"} ${_androidDeviceInfo?.model ?? "-"}',
                  ),
                  Text(
                    'Android: ${_androidDeviceInfo?.version.release ?? "-"}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'package_info_plus@8.3.1: ${_packageInfo?.appName ?? "-"} v${_packageInfo?.version ?? "-"}',
                  ),
                  const Spacer(),
                  Text(
                    'webview_flutter@4.10.0',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
              child: WebViewWidget(controller: _webViewController),
            ),
          ),
        ],
      ),
    );
  }
}
