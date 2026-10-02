import 'package:patas_web_app/src/features/pets/models/pet_model.dart';
import 'package:patas_web_app/src/features/ongs_corp/models/ong_profile_model.dart';
import 'package:patas_web_app/src/features/ongs_corp/models/corp_profile_model.dart';

class Post {
  final String id;
  final String userId;
  final String? petId;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;

  // Campos para vídeo
  final bool isVideo;
  final String? videoUrl;
  final String? videoThumbnailUrl;
  final int? videoDurationSeconds;

  final String? ongId;
  final String? companyId;
  final String? profileType; // 'pet', 'ong', 'company'

  // Dados extras vindos de joins
  final String? userName;
  final String? userPhoto;
  final Pet? pet;
  final OngProfile? ong;
  final CorpProfile? corp;

  Post({
    required this.id,
    required this.userId,
    this.petId,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    this.userName,
    this.userPhoto,
    this.pet,
    this.ong,
    this.corp,
    this.ongId,
    this.companyId,
    this.profileType = 'pet',
    this.isVideo = false,
    this.videoUrl,
    this.videoThumbnailUrl,
    this.videoDurationSeconds,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      userId: json['user_id'],
      petId: json['pet_id'],
      content: json['content'] ?? '',
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      userName: (json['tutor_profiles'] ?? json['users'])?['name'],
      userPhoto: (json['tutor_profiles'] ?? json['users'])?['photo_url'],
      pet: json['pets'] != null ? Pet.fromJson(json['pets']) : null,
      ong: json['ong_profiles'] != null
          ? OngProfile.fromJson(json['ong_profiles'])
          : null,
      corp: json['company_profiles'] != null
          ? CorpProfile.fromJson(json['company_profiles'])
          : null,
      ongId: json['ong_id'],
      companyId: json['company_id'],
      profileType: json['profile_type'] ?? 'pet',
      isVideo: json['is_video'] ?? false,
      videoUrl: json['video_url'],
      videoThumbnailUrl: json['video_thumbnail_url'],
      videoDurationSeconds: json['video_duration'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'pet_id': petId,
      'ong_id': ongId,
      'company_id': companyId,
      'profile_type': profileType,
      'content': content,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'is_video': isVideo,
      'video_url': videoUrl,
      'video_thumbnail_url': videoThumbnailUrl,
      'video_duration': videoDurationSeconds,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Post && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
