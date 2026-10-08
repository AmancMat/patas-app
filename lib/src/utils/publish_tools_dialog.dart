import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/features/home/timeline/models/post_model.dart';
import 'package:patas_web_app/src/features/home/timeline/services/post_service.dart';
import 'package:patas_web_app/src/features/home/timeline/services/story_service.dart';
import 'package:patas_web_app/src/features/home/timeline/services/share_service.dart';
import '../../main.dart';
import '../constants/app_colors.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:patas_web_app/src/localization/localizations_ext.dart';

class PublishToolsDialog extends StatelessWidget {
  final Post post;
  final bool isStory;
  final VoidCallback? onActionComplete;

  const PublishToolsDialog({
    super.key,
    required this.post,
    this.isStory = false,
    this.onActionComplete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Provider.of<DarkMode>(context).darkMode;
    final currentUser = supabase.auth.currentUser;
    final bool isOwner = post.userId == currentUser?.id;
    final PostService postService = PostService();
    final StoryService storyService = StoryService();

    final Color bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color dividerColor = isDark ? const Color(0xFF334155) : (Colors.grey[200] ?? const Color(0xFFEEEEEE));
    final double bottomPadding = MediaQuery.paddingOf(context).bottom > 0
        ? MediaQuery.paddingOf(context).bottom + 16
        : 24.h;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: context.isWide
            ? BorderRadius.circular(24)
            : BorderRadius.only(
                topLeft: Radius.circular(24.r),
                topRight: Radius.circular(24.r),
              ),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar (escondido no Desktop)
              if (!context.isWide)
                Container(
                  margin: EdgeInsets.only(top: 12.h),
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),

              SizedBox(height: context.isWide ? 15 : 18.h),

              // Opção: Compartilhar publicação
              _buildOption(
                context: context,
                isDark: isDark,
                icon: Icons.share_rounded,
                iconColor: AppColors.patasColor,
                title: context.tr('feed.share_post'),
                subtitle: context.tr('feed.share_post_subtitle'),
                onTap: () {
                  Navigator.pop(context);
                  ShareService().showShareModal(context, post);
                },
              ),

              Divider(height: 1.h, thickness: 1, color: dividerColor),

              // Opção: Copiar link
              _buildOption(
                context: context,
                isDark: isDark,
                icon: Icons.link_rounded,
                iconColor: const Color(0xFF3B82F6),
                title: context.tr('feed.copy_link'),
                subtitle: context.tr('feed.copy_link_subtitle'),
                onTap: () {
                  Navigator.pop(context);
                  ShareService().copyPostLink(context, post.id);
                },
              ),

              Divider(height: 1.h, thickness: 1, color: dividerColor),

              // Opção 1: Por que estou vendo
              _buildOption(
                context: context,
                isDark: isDark,
                icon: Icons.info_outline_rounded,
                iconColor: AppColors.patasColor,
                title: context.tr('feed.why_seeing'),
                subtitle: context.tr('feed.why_seeing_subtitle'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              Divider(height: 1.h, thickness: 1, color: dividerColor),

              // Opção 2: Denunciar
              _buildOption(
                context: context,
                isDark: isDark,
                icon: Icons.flag_outlined,
                iconColor: Colors.orange[700]!,
                title: context.tr('feed.report_post'),
                subtitle: context.tr('feed.report_subtitle'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              Divider(height: 1.h, thickness: 1, color: dividerColor),

              // Opção 3: Excluir ou Ocultar
              _buildOption(
                context: context,
                isDark: isDark,
                icon: isOwner ? Icons.delete_outline_rounded : Icons.visibility_off_outlined,
                iconColor: Colors.red[600]!,
                title: isOwner
                    ? (isStory ? context.tr('feed.delete_story') : context.tr('feed.delete_post'))
                    : context.tr('feed.hide_post'),
                subtitle: isOwner
                    ? context.tr('feed.delete_subtitle')
                    : context.tr('feed.hide_subtitle'),
                onTap: () async {
                  final navigator = Navigator.of(context);

                  if (isOwner) {
                    // Confirmação para exclusão
                    final bool? confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            context.isWide ? 20 : 20.r,
                          ),
                        ),
                        title: Text(
                          isStory
                              ? context.tr('feed.delete_dialog_title_story')
                              : context.tr('feed.delete_dialog_title_post'),
                          style: TextStyle(
                            fontSize: context.isWide ? 20 : 20.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.darkBG,
                          ),
                        ),
                        content: Text(
                          isStory
                              ? context.tr('feed.delete_confirm_story')
                              : context.tr('feed.delete_confirm'),
                          style: TextStyle(
                            fontSize: context.isWide ? 15 : 15.sp,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(
                              context.tr('common.cancel'),
                              style: TextStyle(
                                color: isDark ? Colors.white60 : Colors.grey[600],
                                fontSize: context.isWide ? 15 : 15.sp,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.red.withValues(alpha: 0.12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  context.isWide ? 8 : 8.r,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.isWide ? 12 : 12.w,
                                vertical: context.isWide ? 4 : 4.h,
                              ),
                              child: Text(
                                context.tr('common.delete'),
                                style: TextStyle(
                                  color: Colors.red[600],
                                  fontSize: context.isWide ? 15 : 15.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm != true) return;
                  }

                  try {
                    debugPrint(
                        'PublishToolsDialog: isStory=$isStory, isOwner=$isOwner, itemId=${post.id}');
                    if (isOwner) {
                      if (isStory) {
                        await storyService.deleteStory(post.id);
                      } else {
                        await postService.deletePost(post.id);
                      }
                    } else {
                      await postService.hidePost(post.id);
                    }
                    if (onActionComplete != null) onActionComplete!();
                    navigator.pop();
                  } catch (e) {
                    debugPrint('Erro ao processar ação no item: $e');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final Color titleColor = isDark ? Colors.white : (Colors.grey[900] ?? Colors.black);
    final Color subtitleColor = isDark ? Colors.white60 : (Colors.grey[600] ?? Colors.black54);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.isWide ? 16 : 20.w,
          vertical: context.isWide ? 12 : 14.h,
        ),
        child: Row(
          children: [
            // Ícone
            Container(
              width: context.isWide ? 38 : 44.r,
              height: context.isWide ? 38 : 44.r,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: context.isWide ? 20 : 22.r,
              ),
            ),

            SizedBox(width: context.isWide ? 12 : 16.w),

            // Textos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: context.isWide ? 15 : 15.sp,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: context.isWide ? 12 : 12.5.sp,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),

            // Seta
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white30 : Colors.grey[400],
              size: 20.r,
            ),
          ],
        ),
      ),
    );
  }
}

