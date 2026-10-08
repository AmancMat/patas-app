import 'package:flutter/material.dart';
import 'package:patas_web_app/src/utils/date_utils.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/features/home/timeline/models/comment_model.dart';
import 'package:patas_web_app/src/features/home/timeline/models/post_model.dart';
import 'package:patas_web_app/src/features/home/timeline/services/comment_service.dart';
import 'package:patas_web_app/src/features/pets/active_pet_provider.dart';
import 'package:patas_web_app/src/providers/active_account_provider.dart';
import 'package:patas_web_app/src/models/active_account_model.dart';
import 'package:provider/provider.dart';
import '../../../../../app.dart';
import 'package:patas_web_app/src/localization/localizations_ext.dart';

class CommentsSheet extends StatefulWidget {
  final Post post;
  final bool isStory;

  const CommentsSheet({super.key, required this.post, this.isStory = false});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final CommentService _commentService = CommentService();
  final TextEditingController _commentController = TextEditingController();
  List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    final comments =
        await _commentService.getComments(widget.post.id, isStory: widget.isStory);
    if (mounted) {
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    }
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    // Verificar qual tipo de perfil está ativo
    final activeAccountProvider =
        Provider.of<ActiveAccountProvider>(context, listen: false);
    final activePetProvider =
        Provider.of<ActivePetProvider>(context, listen: false);

    // Se for perfil de usuário, petId deve ser null
    // Se for perfil de pet, usar o petId do ActivePetProvider
    final petId = activeAccountProvider.activeAccount?.type == AccountType.user
        ? null
        : activePetProvider.activePet?.id;

    if (mounted) {
      setState(() => _isSending = true);
      // Fecha teclado
      FocusScope.of(context).unfocus();
    }

    try {
      final newComment = await _commentService.addComment(
        widget.post.id,
        content,
        petId,
        isStory: widget.isStory,
      );
      if (newComment != null && mounted) {
        setState(() {
          _comments.add(newComment);
          _commentController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('feed.comment_error', {'error': e.toString()}))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    final systemBottomPadding = MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.75,
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.90,
        minHeight: 320,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBG : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              context.tr('feed.comments'),
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.darkBG,
              ),
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),

          // Lista de Comentários com Rolagem Nativa Fluida
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.patasColor,
                      strokeWidth: 2.5,
                    ),
                  )
                : _comments.isEmpty
                    ? Center(
                        child: Text(
                          context.tr('feed.no_comments'),
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 14,
                            color: isDark ? Colors.white54 : Colors.grey[600],
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFF1F5F9),
                                  backgroundImage: comment.senderPhoto !=
                                              null &&
                                          comment.senderPhoto!.isNotEmpty
                                      ? NetworkImage(comment.senderPhoto!)
                                      : const AssetImage(
                                              'assets/image_placeholder.png')
                                          as ImageProvider,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              comment.senderName ?? 'Usuário',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontFamily: 'Fredoka',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: isDark
                                                    ? Colors.white
                                                    : AppColors.darkBG,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            PatasDateUtils.formatFriendlyDate(
                                                comment.createdAt),
                                            style: TextStyle(
                                              fontFamily: 'Fredoka',
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.white54
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        comment.content,
                                        style: TextStyle(
                                          fontFamily: 'Fredoka',
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black87,
                                          fontSize: 14,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),

          // Campo de Entrada com Blindagem de Altura contra a Barra Inferior e Teclado
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 10,
              bottom: viewInsetsBottom > 0
                  ? (viewInsetsBottom + 10)
                  : (systemBottomPadding > 0 ? systemBottomPadding + 8 : 16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 14,
                      color: isDark ? Colors.white : AppColors.darkBG,
                    ),
                    decoration: InputDecoration(
                      hintText: context.tr('feed.write_comment'),
                      hintStyle: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 14,
                        color: isDark ? Colors.white54 : Colors.grey[500],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                _isSending
                    ? const SizedBox(
                        width: 48,
                        child: Center(
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.patasColor,
                            ),
                          ),
                        ),
                      )
                    : IconButton(
                        tooltip: context.tr('feed.send_comment_tooltip'),
                        onPressed: _addComment,
                        icon: const Icon(
                          Icons.send_rounded,
                          color: AppColors.patasColor,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
