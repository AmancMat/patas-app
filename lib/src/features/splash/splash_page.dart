import 'package:flutter/material.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'splash_controller.dart';
import 'splash_state.dart';
import 'no_internet_page.dart';

import '../../constants/routes.dart';
import '../../localization/locator.dart';
import '../home/timeline/screens/public_post_page.dart';
import '../encontra/screens/localizador_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final _splashController = locator.get<SplashController>();
  late VideoPlayerController _videoController;
  bool _videoInitialized = false;

  @override
  void initState() {
    super.initState();

    // Inicializa o controlador de vídeo
    _videoController =
        VideoPlayerController.asset('assets/anime/animepatas.mp4')
          ..initialize().then((_) {
            // Garante que o vídeo comece a tocar assim que carregado
            _videoController.setVolume(1.0); // Audio ativado
            _videoController.play();
            setState(() {
              _videoInitialized = true;
            });
          });

    _splashController.isUserLogged();
    _splashController.addListener(() {
      final state = _splashController.state;

      // Na Web, a transição para usuários autenticados deve ser instantânea (sem esperar os 4s do vídeo)
      final minSplashDuration = kIsWeb ? Duration.zero : const Duration(seconds: 4);

      Timer(minSplashDuration, () {
        if (!mounted) return;

        // 1. Interceptação de Deep Link na Web (evita que a Splash atropela o link do post)
        if (kIsWeb) {
          final uri = Uri.base;
          final uriStr = uri.toString();

          // Caso seja rota de Post: /post?id=xyz ou /post/xyz ou /#/post?id=xyz
          if (uriStr.contains('/post')) {
            String? postId = uri.queryParameters['id'];
            if (postId == null || postId.isEmpty) {
              final match = RegExp(r'[?&]id=([^&#]+)').firstMatch(uriStr);
              postId = match?.group(1);
            }
            if (postId == null || postId.isEmpty) {
              if (uri.pathSegments.isNotEmpty && uri.pathSegments.last != 'post') {
                postId = uri.pathSegments.last;
              }
            }
            if (postId != null && postId.isNotEmpty) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => PublicPostPage(postId: postId!)),
                (route) => false,
              );
              return;
            }
          }

          // Caso seja rota de Encontra Tag: /encontra/t/uuid
          if (uriStr.contains('/encontra/t/')) {
            final uuid = uri.pathSegments.last;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => LocalizadorPage(uuid: uuid)),
              (route) => false,
            );
            return;
          }
        }

        if (state is AuthenticatedVetUser) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            NamedRoute.saudeVet,
            (route) => false,
          );
        } else if (state is AuthenticatedUser) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            NamedRoute.home,
            (route) => false,
          );
        } else if (state is AuthenticatedUserNoPets) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            NamedRoute.firstProfile,
            (route) => false,
          );
        } else if (state is UnauthenticatedUser) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            NamedRoute.initial,
            (route) => false,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _splashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _splashController,
      builder: (context, child) {
        final state = _splashController.state;

        if (state is NoInternet) {
          return NoInternetPage(
            onRetry: () {
              _splashController.isUserLogged();
            },
          );
        }

        return Scaffold(
          body: Container(
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Colors.white),
            child: _videoInitialized
                ? AspectRatio(
                    aspectRatio: _videoController.value.aspectRatio,
                    child: VideoPlayer(_videoController),
                  )
                : const SizedBox(), // Mostra nada (branco) enquanto inicializa
          ),
        );
      },
    );
  }
}
