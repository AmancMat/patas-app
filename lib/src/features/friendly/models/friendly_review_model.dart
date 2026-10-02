class FriendlyReview {
  final String id;
  final String placeId;
  final String userId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String userName;
  final String? userPhotoUrl;

  FriendlyReview({
    required this.id,
    required this.placeId,
    required this.userId,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.userName,
    this.userPhotoUrl,
  });

  factory FriendlyReview.fromJson(Map<String, dynamic> json) {
    // Join with users table is parsed here
    final user = json['users'] as Map<String, dynamic>?;
    final name = user?['name'] ?? 'Tutor';
    final photo = user?['photo_url'];

    return FriendlyReview(
      id: json['id'],
      placeId: json['place_id'],
      userId: json['user_id'],
      rating: json['rating'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      userName: name,
      userPhotoUrl: photo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'place_id': placeId,
      'user_id': userId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
