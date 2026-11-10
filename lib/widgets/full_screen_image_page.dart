import 'dart:typed_data';

import 'package:flutter/material.dart';

class FullScreenImagePage extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? imageBytes;

  const FullScreenImagePage({super.key, this.imageUrl, this.imageBytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          clipBehavior: Clip.none,
          maxScale: 5.0,
          child: imageBytes != null
              ? Image.memory(imageBytes!)
              : Image.network(
                  imageUrl!,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const CircularProgressIndicator(color: Colors.white);
                  },
                ),
        ),
      ),
    );
  }
}