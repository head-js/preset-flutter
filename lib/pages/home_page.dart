import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:preset/api/api_client.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  late final Dio _dio;
  late final ApiClient _apiClient;
  String _httpResponse = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _getDeviceInfo();
    _getPackageInfo();
    _initWebView();
    _initApiClient();
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

  void _initApiClient() {
    _dio = Dio();
    _dio.options.headers['Content-Type'] = 'application/json';
    _apiClient = ApiClient(_dio);
  }

  Future<void> _sendPostRequest() async {
    setState(() {
      _isLoading = true;
      _httpResponse = '';
    });

    try {
      final response = await _apiClient.postTest({
        'message': 'Hello from Flutter!',
        'timestamp': DateTime.now().toIso8601String(),
        'platform': 'Android',
      });

      setState(() {
        _isLoading = false;
        _httpResponse =
            'Success!\n'
            'URL: ${response.data.url}\n'
            'Origin: ${response.data.origin}\n'
            'Data: ${response.data.json}';
      });

      debugPrint('HTTP POST Response: ${response.data.toJson()}');
    } on DioException catch (e) {
      setState(() {
        _isLoading = false;
        _httpResponse =
            'Error: ${e.type.toString()}\n'
            'Message: ${e.message}\n'
            'StatusCode: ${e.response?.statusCode ?? "-"}';
      });
      debugPrint('DioException: ${e.toString()}');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _httpResponse = 'Error: ${e.toString()}';
      });
      debugPrint('Exception: ${e.toString()}');
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.go('/settings');
            },
          ),
        ],
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
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _sendPostRequest,
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text(
                              'HTTP POST Test (dio@5.9.2 + retrofit@4.6.0)',
                            ),
                  ),
                  if (_httpResponse.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _httpResponse,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        'webview_flutter@4.10.0',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        'go_router@15.1.2',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
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
