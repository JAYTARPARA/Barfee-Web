import 'package:android_intent/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location_permissions/location_permissions.dart';
import 'package:url_launcher/url_launcher.dart';

String selectedUrl = 'https://barfeefood.com';

// ignore: prefer_collection_literals
final Set<JavascriptChannel> jsChannels = [
  JavascriptChannel(
      name: 'Print',
      onMessageReceived: (JavascriptMessage message) {
        print(message.message);
      }),
].toSet();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barfee',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routes: {
        '/': (_) => WebApp(),
      },
    );
  }
}

class WebApp extends StatefulWidget {
  @override
  _WebAppState createState() => _WebAppState();
}

class _WebAppState extends State<WebApp> {
  final flutterWebViewPlugin = FlutterWebviewPlugin();
  PermissionStatus permission;
  ServiceStatus serviceStatus;

  @override
  void initState() {
    super.initState();
    checkPermission();
    flutterWebViewPlugin.close();
    flutterWebViewPlugin.launch(
      selectedUrl,
      geolocationEnabled: true,
      javascriptChannels: jsChannels,
      withJavascript: true,
    );
    flutterWebViewPlugin.onUrlChanged.listen((String url) async {
      // print("navigating to...$url");
      if (url.startsWith("mailto") || url.startsWith("tel")) {
        await flutterWebViewPlugin.stopLoading();
        if (await canLaunch(url)) {
          await launch(
            url,
            enableJavaScript: true,
          );
          return;
        }
        // print("couldn't launch $url");
      }
    });
  }

  checkPermission() async {
    permission = await LocationPermissions().checkPermissionStatus();
    print('permission: $permission');
    if (permission == PermissionStatus.denied) {
      permission = await LocationPermissions().requestPermissions();
    }
    if (!(await isLocationServiceEnabled())) {
      final AndroidIntent intent = AndroidIntent(
        action: 'android.settings.LOCATION_SOURCE_SETTINGS',
      );
      intent.launch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WebviewScaffold(
        url: selectedUrl,
        javascriptChannels: jsChannels,
        mediaPlaybackRequiresUserGesture: false,
        withZoom: true,
        withLocalStorage: true,
        hidden: true,
        initialChild: Container(
          color: Colors.black87,
          child: const Center(
            child: SpinKitPulse(
              color: Colors.white,
              size: 50.0,
            ),
          ),
        ),
      ),
    );
  }
}
