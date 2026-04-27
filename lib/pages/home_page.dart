import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:preset/providers/connectivity_provider.dart';
import 'package:preset/providers/http_post_provider.dart';
import 'package:preset/providers/shared_prefs_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  static const _counterKey = 'shared_prefs_counter';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityProvider);
    final httpPostState = ref.watch(httpPostNotifierProvider);
    final prefs = ref.watch(sharedPreferencesProvider);

    final androidDeviceInfo = useState<AndroidDeviceInfo?>(null);
    final packageInfo = useState<PackageInfo?>(null);
    final counter = useState<int>(prefs.getInt(_counterKey) ?? 0);

    final webViewController = useMemoized(() {
      return WebViewController()
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
    });

    useEffect(() {
      final deviceInfo = DeviceInfoPlugin();
      deviceInfo.androidInfo.then((info) {
        androidDeviceInfo.value = info;
      });

      PackageInfo.fromPlatform().then((info) {
        packageInfo.value = info;
      });

      return null;
    }, []);

    String connectivityText(List<ConnectivityResult> result) {
      if (result.contains(ConnectivityResult.wifi)) {
        return 'WiFi';
      } else if (result.contains(ConnectivityResult.mobile)) {
        return 'Mobile';
      } else if (result.contains(ConnectivityResult.none)) {
        return 'None';
      } else {
        return 'Other';
      }
    }

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
            flex: 7,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'connectivity_plus@6.0.5: ${connectivityAsync.when(
                      data: (data) => connectivityText(data),
                      loading: () => 'Checking...',
                      error: (e, _) => 'Error: $e',
                    )}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'device_info_plus@11.5.0: ${androidDeviceInfo.value?.brand ?? "-"} ${androidDeviceInfo.value?.model ?? "-"}',
                  ),
                  Text(
                    'Android: ${androidDeviceInfo.value?.version.release ?? "-"}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'package_info_plus@8.3.1: ${packageInfo.value?.appName ?? "-"} v${packageInfo.value?.version ?? "-"}',
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed:
                        httpPostState.isLoading
                            ? null
                            : () {
                              ref
                                  .read(httpPostNotifierProvider.notifier)
                                  .sendPost({
                                'message': 'Hello from Flutter!',
                                'timestamp':
                                    DateTime.now().toIso8601String(),
                                'platform': 'Android',
                              });
                            },
                    child:
                        httpPostState.isLoading
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text(
                              'HTTP POST Test (dio@5.9.2 + retrofit@4.6.0)',
                            ),
                  ),
                  if (httpPostState.response.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        httpPostState.response,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'shared_preferences@2.5.3: ${counter.value}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () async {
                          final newVal = counter.value - 1;
                          await prefs.setInt(_counterKey, newVal);
                          counter.value = newVal;
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () async {
                          final newVal = counter.value + 1;
                          await prefs.setInt(_counterKey, newVal);
                          counter.value = newVal;
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await prefs.remove(_counterKey);
                          counter.value = 0;
                        },
                      ),
                    ],
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
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
              child: WebViewWidget(controller: webViewController),
            ),
          ),
        ],
      ),
    );
  }
}