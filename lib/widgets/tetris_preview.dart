import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TetrisPreview extends StatefulWidget {
  final VoidCallback onCancel;
  final VoidCallback onSend;

  const TetrisPreview({
    super.key,
    required this.onCancel,
    required this.onSend,
  });

  @override
  State<TetrisPreview> createState() => _TetrisPreviewState();
}

class _TetrisPreviewState extends State<TetrisPreview> {
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      color: Colors.grey[100],
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          SizedBox(
            height: 300,
            child: WebViewWidget(controller: _controller),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  onPressed: widget.onCancel, child: const Text('Cancel')),
              const SizedBox(width: 4),
              ElevatedButton(
                  onPressed: widget.onSend, child: const Text('Send')),
            ],
          ),
        ],
      ),
    );
  }
}
