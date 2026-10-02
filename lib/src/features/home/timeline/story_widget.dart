import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:patas_web_app/src/features/home/timeline/create_story_widget.dart';
import 'package:patas_web_app/src/features/home/timeline/models/story_model.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../constants/app_colors.dart';
import '../../../../app.dart';
import 'package:patas_web_app/src/providers/connectivity_provider.dart';
import 'full_screen_story.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';

class StoryWidget extends StatelessWidget {
  final List<Story> stories;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback onStoryCreated;

  const StoryWidget({
    super.key,
    required this.stories,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    required this.onStoryCreated,
  });

  @override
  Widget build(BuildContext context) {
    // Agrupar stories por pet (ou usuário se pet for nulo)
    final Map<String, List<Story>> groupedStories = {};
    for (var story in stories) {
      final key = story.petId ?? story.ongId ?? story.companyId ?? story.userId;
      if (!groupedStories.containsKey(key)) {
        groupedStories[key] = [];
      }
      groupedStories[key]!.add(story);
    }

    final List<List<Story>> storyGroups = groupedStories.values.toList();

    return Row(
      children: [
        Semantics(
          button: true,
          label: 'Criar novo Story',
          child: GestureDetector(
            onTap: () async {
            final bool? result = await showGeneralDialog<bool>(
              context: context,
              barrierDismissible: true,
              barrierLabel: 'Fechar',
              barrierColor: Colors.black.withValues(alpha: 0.5),
              transitionDuration: const Duration(milliseconds: 300),
              pageBuilder: (context, anim1, anim2) {
                return BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: const CreateStoryWidget(),
                );
              },
              transitionBuilder: (context, anim1, anim2, child) {
                return FadeTransition(
                  opacity: anim1,
                  child: ScaleTransition(
                    scale: CurvedAnimation(
                      parent: anim1,
                      curve: Curves.easeOutBack,
                    ).drive(Tween<double>(begin: 0.8, end: 1.0)),
                    child: child,
                  ),
                );
              },
            );
            if (result == true) {
              onStoryCreated();
            }
          },
          child: Container(
            width: 80,
            height: 146,
            margin: const EdgeInsets.only(
              top: 2,
              left: 4,
              right: 4,
            ),
            decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: AppColors.patasGradient,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(10))),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '+',
                  style: TextStyle(fontSize: 40, color: AppColors.lightBG),
                ),
                Text(
                  'Story',
                  style: TextStyle(fontSize: 18, color: AppColors.lightBG),
                ),
              ],
            ),
          ),
        ),
),
        Expanded(
          flex: 80,
          child: isLoading
              ? _buildSkeletonList(context)
              : (storyGroups.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Center(
                        child: errorMessage != null
                            ? Builder(
                                builder: (context) {
                                  final connectivity = Provider.of<ConnectivityProvider>(context, listen: false);
                                  final bool isRealOffline = connectivity.isOffline ||
                                      errorMessage!.contains('SocketException') ||
                                      errorMessage!.contains('ClientException') ||
                                      errorMessage!.contains('Network is unreachable') ||
                                      errorMessage!.contains('Failed host lookup');
                                  final String storyErrorText = isRealOffline
                                      ? 'Sem conexão com a internet'
                                      : 'Instabilidade no servidor ao carregar stories';

                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        storyErrorText,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Provider.of<DarkMode>(context).darkMode
                                              ? Colors.amber.shade300
                                              : Colors.amber.shade800,
                                        ),
                                      ),
                                      if (onRetry != null) ...[
                                        const SizedBox(height: 6),
                                        InkWell(
                                          onTap: onRetry,
                                          borderRadius: BorderRadius.circular(12),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.refresh_rounded,
                                                  size: 14,
                                                  color: Provider.of<DarkMode>(context).darkMode
                                                      ? Colors.white70
                                                      : Colors.black87,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Tentar novamente',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: Provider.of<DarkMode>(context).darkMode
                                                        ? Colors.white70
                                                        : Colors.black87,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              )
                            : Text(
                                'Stories das pessoas que você segue aparecerão aqui',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Provider.of<DarkMode>(context).darkMode
                                      ? Colors.white54
                                      : Colors.black54,
                                ),
                              ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: storyGroups.length,
                      itemBuilder: (BuildContext ctx, index) {
                        final thmode = Provider.of<DarkMode>(context);
                        return _buildStoryItem(context, storyGroups[index],
                            thmode: thmode);
                      })),
        ),
      ],
    );
  }

  Widget _buildSkeletonList(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    // Mock stories para o skeletonizer
    final mockStories = List.generate(
      5,
      (index) => Story(
        id: 'mock_$index',
        userId: 'mock_user',
        mediaUrl: '',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
        userName: 'Nome do Pet',
        userPhoto: '',
      ),
    );

    return Skeletonizer(
      enabled: true,
      effect: ShimmerEffect(
        baseColor: thmode.darkMode
            ? Colors.grey[800]!
            : AppColors.patasColor.withValues(alpha: 0.1),
        highlightColor: thmode.darkMode
            ? Colors.grey[700]!
            : AppColors.patasColor.withValues(alpha: 0.2),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: mockStories.length,
        itemBuilder: (context, index) {
          return _buildStoryItem(context, [mockStories[index]],
              isSkeleton: true);
        },
      ),
    );
  }

  Widget _buildStoryItem(BuildContext context, List<Story> storiesGroup,
      {bool isSkeleton = false, DarkMode? thmode}) {
    final story = storiesGroup.first;
    String displayPhoto = '';
    String displayName = '';

    if (story.profileType == 'ong' && story.ong != null) {
      displayPhoto = story.ong!.photoUrl ?? '';
      displayName = story.ong!.name;
    } else if (story.profileType == 'company' && story.corp != null) {
      displayPhoto = story.corp!.photoUrl ?? '';
      displayName = story.corp!.name;
    } else {
      displayPhoto = story.pet?.photoUrl ?? story.userPhoto ?? '';
      displayName = story.pet?.name ?? story.userName ?? '';
    }

    final currentThmode =
        thmode ?? Provider.of<DarkMode>(context, listen: false);

    return Semantics(
      button: true,
      label: 'Ver story de $displayName',
      child: GestureDetector(
        onTap: isSkeleton
            ? null
          : () async {
              if (context.isWide) {
                // No Web/Desktop, abre com efeito de Glassmorphism (Blur)
                await showGeneralDialog<void>(
                  context: context,
                  barrierDismissible: true,
                  barrierLabel: 'Fechar',
                  barrierColor: Colors.black.withValues(alpha: 0.4),
                  transitionDuration: const Duration(milliseconds: 300),
                  pageBuilder: (context, anim1, anim2) {
                    return BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: FullScreenStory(
                        stories: storiesGroup,
                      ),
                    );
                  },
                  transitionBuilder: (context, anim1, anim2, child) {
                    return FadeTransition(
                      opacity: anim1,
                      child: ScaleTransition(
                        scale: CurvedAnimation(
                          parent: anim1,
                          curve: Curves.easeOutBack,
                        ).drive(Tween<double>(begin: 0.8, end: 1.0)),
                        child: child,
                      ),
                    );
                  },
                );
              } else {
                // No Mobile, abre com transparência para possibilitar o efeito de minimizar sobre o feed
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    opaque: false,
                    barrierColor: Colors.transparent,
                    transitionDuration: const Duration(milliseconds: 250),
                    reverseTransitionDuration: const Duration(milliseconds: 200),
                    pageBuilder: (context, anim1, anim2) => FullScreenStory(
                      stories: storiesGroup,
                    ),
                    transitionsBuilder: (context, anim1, anim2, child) {
                      return FadeTransition(opacity: anim1, child: child);
                    },
                  ),
                );
              }
            },
      child: Container(
        width: 80,
        height: 146,
        margin: const EdgeInsets.only(
          top: 2,
          left: 4,
          right: 4,
        ),
        decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(10))),
        child: Stack(
          children: [
            Container(
                height: double.infinity,
                width: double.infinity,
                decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(10))),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: isSkeleton
                        ? Container(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white10
                                    : Colors.black12)
                        : story.isVideo
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Thumbnail do vídeo (se existir) ou fundo escuro
                                  story.videoThumbnailUrl != null &&
                                          story.videoThumbnailUrl!.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: story.videoThumbnailUrl!,
                                          fit: BoxFit.cover,
                                          errorWidget: (ctx, url, err) =>
                                              Container(
                                                color: Colors.grey[900],
                                              ),
                                        )
                                      : Container(
                                          color: Colors.grey[900],
                                        ),
                                  // Ícone de play sobreposto
                                  Center(
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                            alpha: 0.55),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : CachedNetworkImage(
                                imageUrl: story.mediaUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Skeletonizer(
                                  enabled: true,
                                  effect: ShimmerEffect(
                                    baseColor: currentThmode.darkMode
                                        ? Colors.grey[800]!
                                        : AppColors.patasColor
                                            .withValues(alpha: 0.1),
                                    highlightColor: currentThmode.darkMode
                                        ? Colors.grey[700]!
                                        : AppColors.patasColor
                                            .withValues(alpha: 0.2),
                                  ),
                                  child: Container(),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.broken_image),
                              ))),
            Container(
              height: 30,
              width: 30,
              decoration: BoxDecoration(
                  color: AppColors.patasColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.patasColor, width: 2.0)),
              margin: const EdgeInsets.only(top: 6, left: 4),
              child: Semantics(
                label: 'Foto de perfil de $displayName',
                child: CircleAvatar(
                  radius: 16,
                  backgroundImage: displayPhoto.isNotEmpty
                      ? NetworkImage(displayPhoto)
                      : const AssetImage('assets/image_placeholder.png')
                          as ImageProvider,
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppColors.patasColor,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 2, left: 6),
                child: Text(
                  displayName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.patasColor,
                      fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    ),
);
  }
}
