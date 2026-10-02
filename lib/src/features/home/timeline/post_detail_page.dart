import 'package:flutter/material.dart';
import 'package:patas_web_app/src/features/home/timeline/models/post_model.dart';
import 'package:patas_web_app/src/features/home/timeline/services/post_service.dart';
import 'package:patas_web_app/src/features/home/profile/publish_widget.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:provider/provider.dart';
import '../../../../app.dart';

class PostDetailPage extends StatefulWidget {
  final String? postId;
  final Post? post;

  const PostDetailPage({
    super.key,
    this.postId,
    this.post,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final PostService _postService = PostService();
  late Future<Post?> _postFuture;

  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      _postFuture = Future.value(widget.post);
    } else if (widget.postId != null) {
      _postFuture = _postService.getPostById(widget.postId!);
    } else {
      _postFuture = Future.value(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBG : Colors.white,
      appBar: const PatasEssencialAppBar(
        title: 'Postagem',
        subtitle: 'Detalhes da publicação',
        leadingIcon: Icon(
          Icons.article_rounded,
          color: AppColors.patasColor,
          size: 22,
        ),
        showBackButton: true,
      ),
      body: FutureBuilder<Post?>(
        future: _postFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.patasColor),
            );
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('Postagem não encontrada ou removida.'),
                ],
              ),
            );
          }

          final post = snapshot.data!;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Breakpoints.feedMaxWidth),
              child: SingleChildScrollView(
                child: PublishWidget(
                  posts: [post],
                  onActionComplete: () {
                    // Se o post for deletado ou algo mudar, podemos recarregar
                    setState(() {
                      _postFuture = _postService.getPostById(post.id);
                    });
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
