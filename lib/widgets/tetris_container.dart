import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TetrisContainer extends StatefulWidget {
  const TetrisContainer({super.key});

  @override
  State<TetrisContainer> createState() => _TetrisContainerState();
}

class _TetrisContainerState extends State<TetrisContainer> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(
        'https://www.geo.de/geolino/spiele/13349-rtkl-onlinespiel-tetris',
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: WebViewWidget(controller: _controller),
    );
  }
}
