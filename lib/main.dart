import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  List<ConnectivityResult> _connectivityResult = [ConnectivityResult.none];
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  AndroidDeviceInfo? _androidDeviceInfo;
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _updateConnectivity,
    );
    _getDeviceInfo();
    _getPackageInfo();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      _connectivityResult = result;
    });
    debugPrint('Connectivity: ${_connectivityResultText(result)}');
  }

  void _updateConnectivity(List<ConnectivityResult> result) {
    setState(() {
      _connectivityResult = result;
    });
    debugPrint('Connectivity changed: ${_connectivityResultText(result)}');
  }

  Future<void> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    setState(() {
      _androidDeviceInfo = androidInfo;
    });
    debugPrint('Device Info - Brand: ${androidInfo.brand}');
    debugPrint('Device Info - Model: ${androidInfo.model}');
    debugPrint('Device Info - Android Version: ${androidInfo.version.release}');
    debugPrint('Device Info - SDK Int: ${androidInfo.version.sdkInt}');
    debugPrint('Device Info - Manufacturer: ${androidInfo.manufacturer}');
    debugPrint('Device Info - Device: ${androidInfo.device}');
  }

  Future<void> _getPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = packageInfo;
    });
    debugPrint('Package Info - App Name: ${packageInfo.appName}');
    debugPrint('Package Info - Package Name: ${packageInfo.packageName}');
    debugPrint('Package Info - Version: ${packageInfo.version}');
    debugPrint('Package Info - Build Number: ${packageInfo.buildNumber}');
  }

  String _connectivityResultText(List<ConnectivityResult> result) {
    if (result.contains(ConnectivityResult.wifi)) return 'WiFi';
    if (result.contains(ConnectivityResult.mobile)) return 'Mobile';
    if (result.contains(ConnectivityResult.ethernet)) return 'Ethernet';
    if (result.contains(ConnectivityResult.bluetooth)) return 'Bluetooth';
    if (result.contains(ConnectivityResult.vpn)) return 'VPN';
    if (result.contains(ConnectivityResult.none)) return 'None';
    return 'Other';
  }

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Network Connectivity Test - connectivity_plus@6.0.5'),
            Text(
              'Connectivity: ${_connectivityResultText(_connectivityResult)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 32),
            const Text('Device Info Test - device_info_plus@10.1.2'),
            Text(
              'Brand: ${_androidDeviceInfo?.brand ?? "Loading..."}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'Model: ${_androidDeviceInfo?.model ?? "Loading..."}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'Android Version: ${_androidDeviceInfo?.version.release ?? "Loading..."}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 32),
            const Text('Package Info Test - package_info_plus@8.3.1'),
            Text(
              'App Name: ${_packageInfo?.appName ?? "Loading..."}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'Package Name: ${_packageInfo?.packageName ?? "Loading..."}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'Version: ${_packageInfo?.version ?? "Loading..."}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'Build Number: ${_packageInfo?.buildNumber ?? "Loading..."}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 32),
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
