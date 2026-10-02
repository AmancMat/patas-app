enum TimelineGranularity {
  years,
  months,
  weeks,
  days;

  String get label {
    switch (this) {
      case TimelineGranularity.years:
        return 'Anos';
      case TimelineGranularity.months:
        return 'Meses';
      case TimelineGranularity.weeks:
        return 'Semanas';
      case TimelineGranularity.days:
        return 'Dias';
    }
  }
}

class TimelineEvent {
  final String id;
  final String petId;
  final DateTime date;
  final String title;
  final String description;
  final List<String> mediaUrls;
  final bool isVideo;
  final List<TimelineComment> comments;
  final bool isLoveMilestone;
  final String? partnerPetId;
  final String? partnerPetName;
  final String? partnerPetPhotoUrl;
  final String? partnerPetBreed;

  const TimelineEvent({
    required this.id,
    required this.petId,
    required this.date,
    required this.title,
    required this.description,
    required this.mediaUrls,
    this.isVideo = false,
    this.comments = const [],
    this.isLoveMilestone = false,
    this.partnerPetId,
    this.partnerPetName,
    this.partnerPetPhotoUrl,
    this.partnerPetBreed,
  });
}

class TimelineComment {
  final String id;
  final String userName;
  final String userAvatar;
  final String commentText;
  final DateTime createdAt;

  const TimelineComment({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.commentText,
    required this.createdAt,
  });
}
