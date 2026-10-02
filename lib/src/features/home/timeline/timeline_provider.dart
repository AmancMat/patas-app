import 'package:flutter/material.dart';
import 'package:patas_web_app/src/features/home/timeline/models/post_model.dart';
import 'package:patas_web_app/src/features/home/timeline/models/story_model.dart';
import 'package:patas_web_app/src/features/home/timeline/services/post_service.dart';
import 'package:patas_web_app/src/features/home/timeline/services/story_service.dart';

class TimelineProvider extends ChangeNotifier {
  final PostService _postService = PostService();
  final StoryService _storyService = StoryService();

  List<Post> _posts = [];
  List<Story> _stories = [];
  bool _isLoading = false;
  String? _error;

  List<Post> get posts => _posts;
  List<Story> get stories => _stories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTimeline({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final results = await Future.wait([
        _postService.getPosts(),
        _storyService.getStories(),
      ]);

      _posts = results[0] as List<Post>;
      _stories = results[1] as List<Story>;
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('TimelineProvider: Erro ao carregar: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adiciona um post novo diretamente no topo da lista local
  void addPostLocally(Post post) {
    _posts.insert(0, post);
    notifyListeners();
  }

  /// Adiciona um story novo diretamente na lista local
  void addStoryLocally(Story story) {
    _stories.insert(0, story);
    notifyListeners();
  }

  /// Limpa erros
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
