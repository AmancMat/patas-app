import 'package:patas_web_app/src/features/pets/models/pet_model.dart';
import 'package:patas_web_app/src/features/ongs_corp/models/ong_profile_model.dart';
import 'package:patas_web_app/src/features/ongs_corp/models/corp_profile_model.dart';

class Story {
  final String id;
  final String userId;
  final String? petId;
  final String mediaUrl;
  final DateTime createdAt;
  final DateTime expiresAt;

  // Campos para vídeo
  final bool isVideo;
  final String? videoUrl;
  final String? videoThumbnailUrl;
  final int? videoDurationSeconds;

  final String? ongId;
  final String? companyId;
  final String? profileType; // 'pet', 'ong', 'company'

  // Joined fields for display
  final String? userName;
  final String? userPhoto;
  final Pet? pet;
  final OngProfile? ong;
  final CorpProfile? corp;

  Story({
    required this.id,
    required this.userId,
    this.petId,
    required this.mediaUrl,
    required this.createdAt,
    required this.expiresAt,
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

  factory Story.fromJson(Map<String, dynamic> json) {
    Pet? petData;
    if (json['pets'] != null) {
      petData = Pet.fromJson(json['pets']);
    }

    String? name;
    String? photo;

    final authorData = json['tutor_profiles'] ?? json['users'];
    if (authorData != null) {
      name = authorData['name'];
      photo = authorData['photo_url'];
    }

    return Story(
      id: json['id'],
      userId: json['user_id'],
      petId: json['pet_id'],
      mediaUrl: json['media_url'],
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      expiresAt: DateTime.parse(json['expires_at']).toLocal(),
      userName: name,
      userPhoto: photo,
      pet: petData,
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
}
