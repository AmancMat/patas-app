import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/features/home/timeline/models/post_model.dart';

class ShareService {
  static const String baseWebUrl = 'https://patas.online/post';
  static const String patasHomeUrl = 'https://patas.online';

  /// Retorna o link web público do post
  String getPostUrl(String postId) {
    return '$baseWebUrl?id=$postId';
  }

  /// Compartilha o post (abre diálogo ou folha de compartilhamento nativa)
  Future<void> sharePost(Post post, {BuildContext? context}) async {
    final String shareText = _buildShareText(post);

    try {
      if (!kIsWeb && post.imageUrl != null && post.imageUrl!.isNotEmpty) {
        await _shareImageAndText(post.imageUrl!, shareText);
      } else {
        await SharePlus.instance.share(ShareParams(text: shareText));
      }
    } catch (e) {
      debugPrint('ShareService: Erro ao compartilhar post: $e');
      // Fallback para texto puro
      try {
        await SharePlus.instance.share(ShareParams(text: shareText));
      } catch (err) {
        debugPrint('ShareService: Fallback falhou: $err');
        if (context != null && context.mounted) {
          copyPostLink(context, post.id);
        }
      }
    }
  }

  /// Constrói mensagem rica contendo autor, citação e link público oficial do Patas
  String _buildShareText(Post post) {
    final String authorName = post.pet?.name ?? post.userName ?? 'Amigo Pet';
    final String excerpt = post.content.trim().isNotEmpty
        ? '\n\n"${post.content.trim()}"'
        : '';
    final String postUrl = getPostUrl(post.id);

    return '🐾 Olha só essa publicação de $authorName no Patas!$excerpt\n\n'
        '👉 Veja a publicação completa no Patas:\n$postUrl\n\n'
        '🌐 Conecte-se à maior comunidade pet do Brasil!';
  }

  /// Copia o link público do post para a área de transferência com SnackBar visual
  void copyPostLink(BuildContext context, String postId) {
    final String url = getPostUrl(postId);
    Clipboard.setData(ClipboardData(text: url));

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Link da publicação copiado com sucesso!',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.patasColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Exibe um modal inferior moderno para compartilhar ou copiar o link
  void showShareModal(BuildContext context, Post post, {bool isDark = false}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final cardBg = isDark ? const Color(0xFF1E1E22) : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF1E1E24);
        final subtextColor = isDark ? const Color(0xFFA0A0AB) : const Color(0xFF6B7280);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                // Título
                Row(
                  children: [
                    const Icon(Icons.share_rounded, color: AppColors.patasColor, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Compartilhar Publicação',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Opção 1: Compartilhar via apps (WhatsApp, Redes)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.patasColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: AppColors.patasColor, size: 20),
                  ),
                  title: Text(
                    'Compartilhar em outros apps',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: textColor,
                    ),
                  ),
                  subtitle: Text(
                    'WhatsApp, Instagram, Telegram ou Mensagens',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 12,
                      color: subtextColor,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    sharePost(post, context: context);
                  },
                ),

                const Divider(height: 16),

                // Opção 2: Copiar Link Direto
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.link_rounded, color: Colors.blue, size: 20),
                  ),
                  title: Text(
                    'Copiar link da publicação',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: textColor,
                    ),
                  ),
                  subtitle: Text(
                    'Cole o link em qualquer lugar',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 12,
                      color: subtextColor,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    copyPostLink(context, post.id);
                  },
                ),

                const Divider(height: 16),

                // Opção 3: Acessar Patas Web
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.patasColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.public_rounded, color: AppColors.patasColor, size: 20),
                  ),
                  title: Text(
                    'Acessar Patas Web',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: textColor,
                    ),
                  ),
                  subtitle: Text(
                    'patas.online • Rede social completa no navegador',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 12,
                      color: subtextColor,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final uri = Uri.parse(patasHomeUrl);
                    try {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } catch (_) {
                      await launchUrl(uri);
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _shareImageAndText(String imageUrl, String text) async {
    final uri = Uri.parse(imageUrl);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final tempDir = await getTemporaryDirectory();
      final String fileName =
          'share_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File file = File('${tempDir.path}/$fileName');

      await file.writeAsBytes(response.bodyBytes);

      final xFile = XFile(file.path);
      // ignore: deprecated_member_use
      await Share.shareXFiles([xFile], text: text);
    } else {
      throw Exception('Falha ao baixar imagem para compartilhamento');
    }
  }
}
