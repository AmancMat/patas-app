import 'package:flutter/material.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../app.dart';
import '../../../../main.dart';

class ActivityHistoryPage extends StatefulWidget {
  const ActivityHistoryPage({super.key});

  @override
  State<ActivityHistoryPage> createState() => _ActivityHistoryPageState();
}

class _ActivityHistoryPageState extends State<ActivityHistoryPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _activities = [];

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  Future<void> _loadActivity() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // 1. Fetch latest posts
      final postsResponse = await supabase
          .from('posts')
          .select('id, content, created_at, photo_url')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(10);

      // 2. Fetch latest comments
      final commentsResponse = await supabase
          .from('comments')
          .select('id, content, created_at, post_id')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(10);

      final List<Map<String, dynamic>> allActivities = [];

      for (var post in postsResponse) {
        allActivities.add({
          'type': 'post',
          'content': post['content'] ?? 'Publicação de imagem',
          'date': DateTime.parse(post['created_at']),
          'media': post['photo_url'],
          'id': post['id'],
        });
      }

      for (var comment in commentsResponse) {
        allActivities.add({
          'type': 'comment',
          'content': comment['content'],
          'date': DateTime.parse(comment['created_at']),
          'id': comment['id'],
          'post_id': comment['post_id'],
        });
      }

      // Sort combined activities by date
      allActivities.sort(
          (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      if (mounted) {
        setState(() {
          _activities = allActivities;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading activity: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final bgColor = thmode.darkMode ? AppColors.bodygray : Colors.grey.shade100;
    final cardColor = thmode.darkMode ? AppColors.darkBG : Colors.white;
    final textColor = thmode.darkMode ? Colors.white : AppColors.darkBG;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.patasColor,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Histórico de Atividade',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Skeletonizer(
        enabled: _isLoading,
        child: RefreshIndicator(
          onRefresh: _loadActivity,
          color: AppColors.patasColor,
          child: _activities.isEmpty && !_isLoading
              ? _buildEmptyState(textColor)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _activities.length,
                  itemBuilder: (context, index) {
                    final activity = _activities[index];
                    return _buildActivityItem(activity, cardColor, textColor);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(
      Map<String, dynamic> activity, Color cardColor, Color textColor) {
    final isPost = activity['type'] == 'post';
    final date = activity['date'] as DateTime;
    final dateStr =
        '${date.day}/${date.month}/${date.year} às ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 5,
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  (isPost ? Colors.blue : Colors.green).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPost ? Icons.post_add : Icons.comment,
              color: isPost ? Colors.blue : Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPost
                      ? 'Você criou uma publicação'
                      : 'Você comentou em um post',
                  style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  activity['content'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: textColor.withValues(alpha: 0.7), fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  dateStr,
                  style: TextStyle(
                      color: textColor.withValues(alpha: 0.4), fontSize: 11),
                ),
              ],
            ),
          ),
          if (activity['media'] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                activity['media'],
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history,
              size: 64, color: textColor.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(
            'Nenhuma atividade recente encontrada.',
            style: TextStyle(color: textColor.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }
}
