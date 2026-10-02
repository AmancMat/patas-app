import 'package:patas_web_app/src/features/pets/models/pet_model.dart';

enum NotificationType {
  like,
  comment,
  follow,
  vaccine,
  system,
  donation,
  rescueAlert;

  static NotificationType fromString(String value) {
    if (value == 'rescue_alert') return NotificationType.rescueAlert;
    return NotificationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationType.system,
    );
  }
}

class NotificationModel {
  final String id;
  final String userId;
  final String? senderPetId;
  final NotificationType type;
  final String title;
  final String content;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  // Joined data
  final Pet? senderPet;

  NotificationModel({
    required this.id,
    required this.userId,
    this.senderPetId,
    required this.type,
    required this.title,
    required this.content,
    this.data = const {},
    required this.isRead,
    required this.createdAt,
    this.senderPet,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['user_id'],
      senderPetId: json['sender_pet_id'],
      type: NotificationType.fromString(json['type']),
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : {},
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      senderPet: json['pets'] != null ? Pet.fromJson(json['pets']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'sender_pet_id': senderPetId,
      'type': type == NotificationType.rescueAlert ? 'rescue_alert' : type.name,
      'title': title,
      'content': content,
      'data': data,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
