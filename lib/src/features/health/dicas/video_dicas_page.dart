import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app.dart';
import '../../../constants/app_colors.dart';

class VideoDicasPage extends StatelessWidget {
  final VoidCallback? onBack;
  const VideoDicasPage({super.key, this.onBack});

  Future<void> _launchVideo(String videoId) async {
    final Uri url = Uri.parse('https://www.youtube.com/watch?v=$videoId');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Não foi possível abrir o link: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    return Scaffold(
      backgroundColor:
          thmode.darkMode ? AppColors.bodygray : const Color(0xFFF5F7FA),
      appBar: PatasEssencialAppBar(
        title: 'Dicas em Vídeo',
        subtitle: 'Canais e tutoriais recomendados',
        onBack: onBack,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildChannelCard(
                  context,
                  thmode,
                  title: 'Perito Animal',
                  description:
                      'Aprenda tudo sobre o mundo animal com especialistas: veterinários, biólogos e adestradores. Conteúdo de qualidade para garantir a melhor vida para seu pet.',
                  avatarUrl:
                      'https://images.unsplash.com/photo-1544568100-847a948585b9?auto=format&fit=crop&w=150&q=80',
                  videoIds: ['uLUrzUUyPJM', 'i8hBN8wApLY', '7I2wATeRVKM', 'So047JrtfO4'],
                ),
                _buildChannelCard(
                  context,
                  thmode,
                  title: 'Luís Zuccolo',
                  description:
                      'Dicas de adestramento, comportamento canino e resolução de problemas comuns como ansiedade de separação e socialização para um convívio perfeito.',
                  avatarUrl:
                      'https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&w=150&q=80',
                  videoIds: ['Bz9VB5d6QZA', 'dmAMxkfFDuU', 'bd2o0Ue9vRI', 'bOroOreGl7w'],
                ),
                _buildChannelCard(
                  context,
                  thmode,
                  title: 'Blog do Focinho',
                  description:
                      'Dicas super práticas para o cotidiano! Descubra os melhores truques para cuidar de gatos e cachorros sem complicação e com muito amor.',
                  avatarUrl:
                      'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&w=150&q=80',
                  videoIds: ['mfIBgULmZgI', 'xfkNMJJlJbI', '3SS6OB18w2I', 'YOB-Bvsu9XU'],
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChannelCard(
      BuildContext context,
      DarkMode thmode,
      {required String title,
      required String description,
      required String avatarUrl,
      required List<String> videoIds}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: thmode.darkMode ? AppColors.darkBG : AppColors.bodyLight,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 4),
            blurRadius: 15.0,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: ExpansionTile(
          collapsedBackgroundColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          textColor: AppColors.patasColor,
          iconColor: AppColors.patasColor,
          collapsedIconColor: thmode.darkMode ? Colors.white70 : Colors.black54,
          title: Text(
            title,
            style: TextStyle(
              color: thmode.darkMode ? Colors.white : AppColors.darkBG,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          leading: CircleAvatar(
            radius: 25,
            backgroundImage: NetworkImage(avatarUrl),
            backgroundColor: Colors.transparent,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                description,
                style: TextStyle(
                  color: thmode.darkMode ? Colors.white70 : Colors.black87,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
            const Divider(indent: 16, endIndent: 16),
            ...videoIds.map((videoId) {
              final thumbnailUrl = 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: GestureDetector(
                  onTap: () => _launchVideo(videoId),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.network(
                            thumbnailUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: 200,
                                color: Colors.black12,
                                child: const Icon(Icons.video_library, size: 50, color: Colors.grey),
                              );
                            },
                          ),
                          Container(
                            width: 65,
                            height: 65,
                            decoration: BoxDecoration(
                              color: AppColors.patasColor.withValues(alpha: 0.95),
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black45,
                                  blurRadius: 15,
                                  offset: Offset(0, 4),
                                )
                              ],
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
