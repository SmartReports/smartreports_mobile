import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'LocalNotificationService.dart';

var started = false;
var response = '';
Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotificationService().init();
  if (Platform.isAndroid) {
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  }
  runApp(MaterialApp(
      home: new MyApp()
  ));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}
class _MyAppState extends State<MyApp> {

  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
        verticalScrollBarEnabled: false,
        horizontalScrollBarEnabled: false,
        disableHorizontalScroll: true,
        supportZoom: false,
      ),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
        builtInZoomControls: false,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,

      )
  );

  late PullToRefreshController pullToRefreshController;
  String url = "";
  double progress = 0;
  final urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.blue,
      ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          webViewController?.reload();
        } else if (Platform.isIOS) {
          webViewController?.loadUrl(
              urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
  late Color color = Color(0xff202020);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(-10.0),
        child: FutureBuilder<bool>(
          // Use FutureBuilder to dynamically get the system's brightness
          future: _getSystemUP(),
          builder: (context, snapshot) {
            return AppBar(
              title: Text(''), // You can set your title here
              toolbarHeight: -10,
              backgroundColor: color,
            );
          },
        ),
      ),
      body: SafeArea(
        child: WillPopScope(
          onWillPop: () async {
            final controller = webViewController;
            if(controller != null) {
              if (await controller.canGoBack()) {
                var history = await controller.getCopyBackForwardList();
                var first_page = history?.list?.first;
                if (first_page != null){
                  await controller.goTo(historyItem: first_page);
                } else {
                  await controller.goBack();
                }
                // controller.loadUrl(urlRequest: URLRequest(url: Uri.parse("https://smartreports.it/dashboard")));
                return false;
              }
            }
            return true;
        },
          child: InAppWebView(
          key: webViewKey,
          initialUrlRequest:
          URLRequest(url: Uri.parse("https://smartreports.it/")),
          initialOptions: options,
          pullToRefreshController: pullToRefreshController,
          onWebViewCreated: (controller) {
            webViewController = controller;
          },
          onLoadStart: (controller, url) {
            setState(() {
              this.url = url.toString();
              urlController.text = this.url;
            });
          },
          androidOnPermissionRequest: (controller, origin, resources) async {
            return PermissionRequestResponse(
                resources: resources,
                action: PermissionRequestResponseAction.GRANT);
          },
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            var uri = navigationAction.request.url!;

            if (![ "http", "https", "file", "chrome",
              "data", "javascript", "about"].contains(uri.scheme)) {
              if (await canLaunch(url)) {
                // Launch the App
                await launch(
                  url,
                );
                // and cancel the request
                return NavigationActionPolicy.CANCEL;
              }
            }

            return NavigationActionPolicy.ALLOW;
          },
          onLoadStop: (controller, url) async {
            pullToRefreshController.endRefreshing();
            setState(() {
              this.url = url.toString();
              urlController.text = this.url;
            });
          },
          onLoadError: (controller, url, code, message) {
            pullToRefreshController.endRefreshing();
          },
          onProgressChanged: (controller, progress) {
            if (progress == 100) {
              pullToRefreshController.endRefreshing();
            }
            setState(() {
              this.progress = progress / 100;
              urlController.text = this.url;
            });
          },
          onUpdateVisitedHistory: (controller, url, androidIsReload) {
            setState(() {
              this.url = url.toString();
              urlController.text = this.url;
            });
          },
          onConsoleMessage: (controller, consoleMessage) {
            LocalNotificationService().showLocalNotification("DataX", "Dear Paul, The OEE today is out of your range");
            print(consoleMessage);
          },
        ),
        ),
        ),
      bottomNavigationBar: FutureBuilder<bool>(
        // Use FutureBuilder to dynamically get the system's brightness
        future: _getSystemBrightness(),
        builder: (context, snapshot) {
          return Container(
            height: 30.0,
            color: color,
          );
        },
      ),
    );
  }
Future<bool> _getSystemUP() async {
  // Retrieve the brightness of the system theme
  var brightness = MediaQuery.platformBrightnessOf(context);
  setState(() {
    color = brightness == Brightness.dark ? Color(0xff202020) : Colors.white;
  });
  return brightness == Brightness.dark;
}

Future<bool> _getSystemBrightness() async {
  // Retrieve the brightness of the system theme
  var brightness = MediaQuery.platformBrightnessOf(context);
  if (( webViewController?.evaluateJavascript(
      source: 'document.getElementById("dark-mode-switch").outerHTML.includes(\'model-value="'+ (brightness == Brightness.dark).toString() +'"\')'))
      .toString()!='null')
  _setBackgroundColor(brightness == Brightness.dark);
  return brightness == Brightness.dark;
}

Future<void> _setBackgroundColor(bool system_dark) async {
  print("System: " + system_dark.toString());
  print("Site: " + response);
  if (response != system_dark.toString()){
    response = (webViewController?.evaluateJavascript(
        source: 'document.getElementById("dark-mode-switch").outerHTML.includes(\'model-value="'+ system_dark.toString() +'"\')'))
        .toString();
      webViewController?.evaluateJavascript(
          source: "document.getElementById('dark-mode-switch').click()");
      };
      // sleep 1 sec
      await Future.delayed(Duration(seconds: 1));
      print(response != system_dark.toString());
    }
}
