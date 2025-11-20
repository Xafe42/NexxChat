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
  final ScrollController _scrollCtrl = ScrollController();

  bool _isFullscreen = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(
        Uri.parse(
          'https://www.geo.de/geolino/spiele/13349-rtkl-onlinespiel-tetris',
        ),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            setState(() => _isLoading = false);
          },
        ),
      );
  }

  Future<void> _toggleFullscreen() async {
    setState(() => _isFullscreen = !_isFullscreen);

    await Future.delayed(const Duration(milliseconds: 200));

    if (_isFullscreen) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.minScrollExtent,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double height = _isFullscreen
        ? (MediaQuery.of(context).size.height * 0.8)
        : 400.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      color: Colors.grey[100],
      padding: const EdgeInsets.all(8),
      child: SingleChildScrollView(
        controller: _scrollCtrl,
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.videogame_asset, color: Colors.blueGrey),
                const SizedBox(width: 8),
                const Text(
                  'Tetris Preview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                    color: Colors.blueGrey,
                  ),
                  onPressed: _toggleFullscreen,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.redAccent),
                  onPressed: widget.onCancel,
                ),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              height: height,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: WebViewWidget(controller: _controller),
                  ),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 4),
                ElevatedButton(
                  onPressed: widget.onSend,
                  child: const Text('Send'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
