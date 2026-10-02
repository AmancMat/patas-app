class TrainerService {
  final String id;
  final String trainerId;
  final String title;
  final String? description;
  final String modality; // 'presencial', 'online', 'hibrido'
  final int durationMinutes;
  final double price;
  final bool isActive;
  final DateTime createdAt;

  TrainerService({
    required this.id,
    required this.trainerId,
    required this.title,
    this.description,
    this.modality = 'presencial',
    this.durationMinutes = 60,
    this.price = 0.0,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trainer_id': trainerId,
      'title': title,
      'description': description,
      'modality': modality,
      'duration_minutes': durationMinutes,
      'price': price,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TrainerService.fromJson(Map<String, dynamic> json) {
    return TrainerService(
      id: json['id'] as String,
      trainerId: json['trainer_id'] as String,
      title: json['title'] as String? ?? 'Sessão de Treino',
      description: json['description'] as String?,
      modality: json['modality'] as String? ?? 'presencial',
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 60,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

class TrainingRequest {
  final String id;
  final String trainerId;
  final String userId;
  final String petId;
  final String? serviceId;
  final DateTime? scheduledDate;
  final String? scheduledTime;
  final String modality; // 'domicilio', 'online', 'centro'
  final String? address;
  final String? behavioralNotes;
  final String status; // 'pending', 'confirmed', 'rejected', 'completed', 'cancelled'
  final double? price;
  final String paymentStatus; // 'pending', 'paid', 'refunded'
  final DateTime createdAt;

  TrainingRequest({
    required this.id,
    required this.trainerId,
    required this.userId,
    required this.petId,
    this.serviceId,
    this.scheduledDate,
    this.scheduledTime,
    this.modality = 'domicilio',
    this.address,
    this.behavioralNotes,
    this.status = 'pending',
    this.price,
    this.paymentStatus = 'pending',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trainer_id': trainerId,
      'user_id': userId,
      'pet_id': petId,
      'service_id': serviceId,
      'scheduled_date': scheduledDate?.toIso8601String(),
      'scheduled_time': scheduledTime,
      'modality': modality,
      'address': address,
      'behavioral_notes': behavioralNotes,
      'status': status,
      'price': price,
      'payment_status': paymentStatus,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TrainingRequest.fromJson(Map<String, dynamic> json) {
    return TrainingRequest(
      id: json['id'] as String,
      trainerId: json['trainer_id'] as String,
      userId: json['user_id'] as String,
      petId: json['pet_id'] as String,
      serviceId: json['service_id'] as String?,
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.tryParse(json['scheduled_date'] as String)
          : null,
      scheduledTime: json['scheduled_time'] as String?,
      modality: json['modality'] as String? ?? 'domicilio',
      address: json['address'] as String?,
      behavioralNotes: json['behavioral_notes'] as String?,
      status: json['status'] as String? ?? 'pending',
      price: (json['price'] as num?)?.toDouble(),
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

class TrainingLog {
  final String id;
  final String? requestId;
  final String trainerId;
  final String petId;
  final int sessionNumber;
  final DateTime sessionDate;
  final List<String> commandsWorked;
  final String progressNotes;
  final String? homeworkForTutor;
  final List<String> mediaUrls;
  final DateTime createdAt;

  TrainingLog({
    required this.id,
    this.requestId,
    required this.trainerId,
    required this.petId,
    this.sessionNumber = 1,
    required this.sessionDate,
    this.commandsWorked = const [],
    required this.progressNotes,
    this.homeworkForTutor,
    this.mediaUrls = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_id': requestId,
      'trainer_id': trainerId,
      'pet_id': petId,
      'session_number': sessionNumber,
      'session_date': sessionDate.toIso8601String(),
      'commands_worked': commandsWorked,
      'progress_notes': progressNotes,
      'homework_for_tutor': homeworkForTutor,
      'media_urls': mediaUrls,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TrainingLog.fromJson(Map<String, dynamic> json) {
    return TrainingLog(
      id: json['id'] as String,
      requestId: json['request_id'] as String?,
      trainerId: json['trainer_id'] as String,
      petId: json['pet_id'] as String,
      sessionNumber: (json['session_number'] as num?)?.toInt() ?? 1,
      sessionDate: json['session_date'] != null
          ? DateTime.parse(json['session_date'] as String)
          : DateTime.now(),
      commandsWorked: json['commands_worked'] != null
          ? List<String>.from(json['commands_worked'] as List)
          : const [],
      progressNotes: json['progress_notes'] as String? ?? '',
      homeworkForTutor: json['homework_for_tutor'] as String?,
      mediaUrls: json['media_urls'] != null
          ? List<String>.from(json['media_urls'] as List)
          : const [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

class TrainerReview {
  final String id;
  final String trainerId;
  final String userId;
  final String? petId;
  final int rating;
  final String? comment;
  final String? tutorName;
  final String? tutorPhoto;
  final DateTime createdAt;

  TrainerReview({
    required this.id,
    required this.trainerId,
    required this.userId,
    this.petId,
    required this.rating,
    this.comment,
    this.tutorName,
    this.tutorPhoto,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trainer_id': trainerId,
      'user_id': userId,
      'pet_id': petId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TrainerReview.fromJson(Map<String, dynamic> json) {
    return TrainerReview(
      id: json['id'] as String,
      trainerId: json['trainer_id'] as String,
      userId: json['user_id'] as String,
      petId: json['pet_id'] as String?,
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      comment: json['comment'] as String?,
      tutorName: json['users']?['name'] as String? ?? 'Tutor Patas',
      tutorPhoto: json['users']?['photo_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
