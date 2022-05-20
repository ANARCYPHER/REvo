import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nyoba/utils/utility.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewScreen extends StatefulWidget {
  final url;
  final String? title;

  WebViewScreen({Key? key, this.url, this.title}) : super(key: key);
  @override
  WebViewScreenState createState() => WebViewScreenState();
}

class WebViewScreenState extends State<WebViewScreen> {
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();

  late WebViewController _webViewController;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            widget.title!,
            style: TextStyle(color: Colors.black),
          ),
          leading: IconButton(
            color: Colors.black,
            onPressed: () => Navigator.pop(context),
            icon: Platform.isIOS
                ? Icon(Icons.arrow_back_ios)
                : Icon(Icons.arrow_back),
          ),
        ),
        body: Stack(
          children: [
            WebView(
              initialUrl: widget.url,
              javascriptMode: JavascriptMode.unrestricted,
              onProgress: (int progress) {
                print("WebView is loading (progress : $progress%)");

                _webViewController.runJavascript(
                    "document.getElementById('headerwrap').style.display= 'none';");
                _webViewController.runJavascript(
                    "document.getElementById('footerwrap').style.display= 'none';");
                _webViewController.runJavascript(
                    "document.getElementsByTagName('header')[0].style.display= 'none';");
                _webViewController.runJavascript(
                    "document.getElementsByTagName('footer')[0].style.display= 'none';");
                _webViewController.runJavascript(
                    "document.getElementsByClassName('return-to-shop')[0].style.display= 'none';");
                _webViewController.runJavascript(
                    "document.getElementsByClassName('page-title')[0].style.display= 'none';");
                _webViewController.runJavascript(
                    "document.getElementsByClassName('woocommerce-error')[0].style.display= 'none';");
                _webViewController.runJavascript(
                    "document.getElementsByClassName('woocommerce-breadcrumb')[0].style.display= 'none';");
                _webViewController.runJavascript(
                    "document.getElementsByClassName('useful-links')[0].style.display= 'none';");
                _webViewController.runJavascript(
                    "document.getElementsByClassName('widget woocommerce widget_product_search')[1].style.display= 'none';");
              },
              onWebViewCreated: (WebViewController webViewController) {
                _webViewController = webViewController;
                _controller.complete(webViewController);
              },
              onPageStarted: (String url) {
                print('Page started loading: $url');
              },
              onPageFinished: (String url) {
                print('Page finished loading: $url');
                setState(() {
                  isLoading = false;
                });
                _webViewController.runJavascript(
                    "document.getElementById('headerwrap').style.display= 'none';");
                _webViewController.runJavascript(
                    "document.getElementById('footerwrap').style.display= 'none';");
                _webViewController.runJavascript(
                    "document.getElementsByTagName('header')[0].style.display= 'none';");
                _webViewController.runJavascript(
                    "document.getElementsByTagName('footer')[0].style.display= 'none';");
                _webViewController.runJavascript(
                    "document.getElementsByClassName('return-to-shop')[0].style.display= 'none';");
                _webViewController.runJavascript(
                    "document.getElementsByClassName('page-title')[0].style.display= 'none';");
                _webViewController.runJavascript(
                    "document.getElementsByClassName('woocommerce-error')[0].style.display= 'none';");
                _webViewController.runJavascript(
                    "document.getElementsByClassName('woocommerce-breadcrumb')[0].style.display= 'none';");
                _webViewController.runJavascript(
                    "document.getElementsByClassName('useful-links')[0].style.display= 'none';");
                _webViewController.runJavascript(
                    "document.getElementsByClassName('widget woocommerce widget_product_search')[1].style.display= 'none';");
              },
              gestureNavigationEnabled: true,
            ),
            isLoading
                ? Center(
                    child: customLoading(),
                  )
                : Stack(),
          ],
        ));
  }
}
