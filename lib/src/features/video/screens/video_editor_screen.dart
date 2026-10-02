import 'package:flutter/material.dart';

class VideoEditorScreen extends StatelessWidget {
  final String videoPath;
  final int maxDurationSeconds;

  const VideoEditorScreen({
    super.key,
    required this.videoPath,
    required this.maxDurationSeconds,
  });

  @override
  Widget build(BuildContext context) {
    // Na Web a edição nativa C++ falha. Retornamos o vídeo original
    // para ser manipulado via backend ou UI alternativa
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.pop(context, videoPath);
      }
    });

    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
