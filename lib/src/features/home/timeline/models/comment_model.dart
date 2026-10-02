class Comment {
  final String id;
  final String userId;
  final String? petId;
  final String? postId;
  final String? storyId;
  final String content;
  final DateTime createdAt;
  final String? senderName; // Nome do Pet (prioridade) ou Usuário
  final String? senderPhoto; // Foto do Pet (prioridade) ou Usuário

  Comment({
    required this.id,
    required this.userId,
    this.petId,
    this.postId,
    this.storyId,
    required this.content,
    required this.createdAt,
    this.senderName,
    this.senderPhoto,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    // Tenta pegar dados do Pet primeiro
    final petData = json['pets'];
    final userData = json['tutor_profiles'] ?? json['users'];

    String? name;
    String? photo;

    if (petData != null) {
      name = petData['name'];
      photo = petData['photo_url'];
    } else if (userData != null) {
      // Fallback para o usuário se não tiver pet vinculado (legado ou erro)
      name = userData['name'];
      photo = userData['photo_url'];
    }

    return Comment(
      id: json['id'],
      userId: json['user_id'],
      petId: json['pet_id'],
      postId: json['post_id'],
      storyId: json['story_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      senderName: name,
      senderPhoto: photo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'pet_id': petId,
      'post_id': postId,
      'story_id': storyId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
