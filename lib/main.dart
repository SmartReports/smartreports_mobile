

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

var site_mode = false;
var started = false;
void main() {
  runApp(
    MaterialApp(
      home: WebViewApp(),
    ),
  );
}
class WebViewApp extends StatefulWidget {
  const WebViewApp({super.key});

  @override
  State<WebViewApp> createState() => _WebViewAppState();
}

class _WebViewAppState extends State<WebViewApp> {
  late final WebViewController controller;
  late Color color = Colors.white;
  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(
        Uri.parse('https://smartreports.it'),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        toolbarHeight: -10,
        backgroundColor: color==Colors.white? Color(0xff202020) : Colors.white,
      ),
      body: WebViewWidget(
        controller: controller,
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


  Future<bool> _getSystemBrightness() async {
    // Retrieve the brightness of the system theme
    var brightness = MediaQuery.platformBrightnessOf(context);
    _setBackgroundColor(brightness != Brightness.dark);
    setState(() {
      color = brightness == Brightness.dark ? Color(0xff202020) : Colors.white;
    });
    return brightness == Brightness.dark;
  }

  Future<void> _setBackgroundColor(bool system_dark) async {
    print("System Mode: " + system_dark.toString());
    print("Site Mode: " + site_mode.toString());
    if (!started){
      print("Site Mode: null");
      final response = await controller.runJavaScriptReturningResult("document.getElementById('dark-mode-switch').outerHTML");
      if (response.toString().contains("model-value==false")){
        site_mode = false;
      } else {
        site_mode = true;
      }
      started = true;
    }
    if (system_dark && site_mode==false){
      controller.runJavaScript("document.getElementById('dark-mode-switch').click()");
      site_mode = true;
      return;

    }
    if (!system_dark && site_mode==true){
      controller.runJavaScript("document.getElementById('dark-mode-switch').click()");
      site_mode = false;
      return;
    }
  }
}
