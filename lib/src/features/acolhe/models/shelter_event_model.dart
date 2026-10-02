import 'package:flutter/material.dart';

enum ShelterEventType {
  adocao,
  vacinacao,
  bazar,
  encontro,
  outro,
}

enum ShelterEventStatus {
  agendado,
  emAndamento,
  concluido,
  cancelado,
}

class ShelterEvent {
  final String id;
  final String ongId;
  final String? createdBy;
  final String title;
  final String description;
  final ShelterEventType eventType;
  final String? bannerUrl;
  final String locationName;
  final String address;
  final String? city;
  final DateTime startDate;
  final DateTime? endDate;
  final String? contactWhatsapp;
  final String? contactPhone;
  final int attendeesCount;
  final bool isPublishedFeed;
  final ShelterEventStatus status;
  final List<String> participatingAnimalsIds;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isUserAttending;

  const ShelterEvent({
    required this.id,
    required this.ongId,
    this.createdBy,
    required this.title,
    required this.description,
    required this.eventType,
    this.bannerUrl,
    required this.locationName,
    required this.address,
    this.city,
    required this.startDate,
    this.endDate,
    this.contactWhatsapp,
    this.contactPhone,
    this.attendeesCount = 0,
    this.isPublishedFeed = true,
    this.status = ShelterEventStatus.agendado,
    this.participatingAnimalsIds = const [],
    required this.createdAt,
    this.updatedAt,
    this.isUserAttending = false,
  });

  factory ShelterEvent.fromMap(Map<String, dynamic> map, {bool isUserAttending = false}) {
    return ShelterEvent(
      id: map['id'] as String,
      ongId: map['ong_id'] as String,
      createdBy: map['created_by'] as String?,
      title: map['title'] as String? ?? 'Evento sem título',
      description: map['description'] as String? ?? '',
      eventType: _parseEventType(map['event_type'] as String?),
      bannerUrl: map['banner_url'] as String?,
      locationName: map['location_name'] as String? ?? 'Local a definir',
      address: map['address'] as String? ?? '',
      city: map['city'] as String?,
      startDate: map['start_date'] != null
          ? DateTime.parse(map['start_date'] as String).toLocal()
          : DateTime.now(),
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String).toLocal()
          : null,
      contactWhatsapp: map['contact_whatsapp'] as String?,
      contactPhone: map['contact_phone'] as String?,
      attendeesCount: (map['attendees_count'] as num?)?.toInt() ?? 0,
      isPublishedFeed: map['is_published_feed'] as bool? ?? true,
      status: _parseStatus(map['status'] as String?),
      participatingAnimalsIds: (map['participating_animals_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String).toLocal()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String).toLocal()
          : null,
      isUserAttending: isUserAttending,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ong_id': ongId,
      if (createdBy != null) 'created_by': createdBy,
      'title': title,
      'description': description,
      'event_type': eventTypeDbString(eventType),
      'banner_url': bannerUrl,
      'location_name': locationName,
      'address': address,
      'city': city,
      'start_date': startDate.toUtc().toIso8601String(),
      'end_date': endDate?.toUtc().toIso8601String(),
      'contact_whatsapp': contactWhatsapp,
      'contact_phone': contactPhone,
      'attendees_count': attendeesCount,
      'is_published_feed': isPublishedFeed,
      'status': statusDbString(status),
      'participating_animals_ids': participatingAnimalsIds,
    };
  }

  ShelterEvent copyWith({
    String? id,
    String? ongId,
    String? createdBy,
    String? title,
    String? description,
    ShelterEventType? eventType,
    String? bannerUrl,
    String? locationName,
    String? address,
    String? city,
    DateTime? startDate,
    DateTime? endDate,
    String? contactWhatsapp,
    String? contactPhone,
    int? attendeesCount,
    bool? isPublishedFeed,
    ShelterEventStatus? status,
    List<String>? participatingAnimalsIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isUserAttending,
  }) {
    return ShelterEvent(
      id: id ?? this.id,
      ongId: ongId ?? this.ongId,
      createdBy: createdBy ?? this.createdBy,
      title: title ?? this.title,
      description: description ?? this.description,
      eventType: eventType ?? this.eventType,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      locationName: locationName ?? this.locationName,
      address: address ?? this.address,
      city: city ?? this.city,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      contactWhatsapp: contactWhatsapp ?? this.contactWhatsapp,
      contactPhone: contactPhone ?? this.contactPhone,
      attendeesCount: attendeesCount ?? this.attendeesCount,
      isPublishedFeed: isPublishedFeed ?? this.isPublishedFeed,
      status: status ?? this.status,
      participatingAnimalsIds: participatingAnimalsIds ?? this.participatingAnimalsIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isUserAttending: isUserAttending ?? this.isUserAttending,
    );
  }

  // --- HELPERS VISUAIS E DE FORMATAÇÃO ---

  String get eventTypeLabel {
    switch (eventType) {
      case ShelterEventType.adocao:
        return 'Feira de Adoção';
      case ShelterEventType.vacinacao:
        return 'Mutirão Sanitário';
      case ShelterEventType.bazar:
        return 'Bazar Beneficente';
      case ShelterEventType.encontro:
        return 'Encontro de Tutores';
      case ShelterEventType.outro:
        return 'Evento Especial';
    }
  }

  Color get eventTypeColor {
    switch (eventType) {
      case ShelterEventType.adocao:
        return const Color(0xFF7C3AED); // Roxo adoção
      case ShelterEventType.vacinacao:
        return const Color(0xFF059669); // Verde saúde
      case ShelterEventType.bazar:
        return const Color(0xFFD97706); // Âmbar bazar
      case ShelterEventType.encontro:
        return const Color(0xFF2563EB); // Azul social
      case ShelterEventType.outro:
        return const Color(0xFFDB2777); // Rosa especial
    }
  }

  IconData get eventTypeIcon {
    switch (eventType) {
      case ShelterEventType.adocao:
        return Icons.volunteer_activism_rounded;
      case ShelterEventType.vacinacao:
        return Icons.vaccines_rounded;
      case ShelterEventType.bazar:
        return Icons.storefront_rounded;
      case ShelterEventType.encontro:
        return Icons.groups_rounded;
      case ShelterEventType.outro:
        return Icons.celebration_rounded;
    }
  }

  String get statusLabel {
    switch (status) {
      case ShelterEventStatus.agendado:
        return 'Agendado';
      case ShelterEventStatus.emAndamento:
        return 'Acontecendo Agora!';
      case ShelterEventStatus.concluido:
        return 'Concluído';
      case ShelterEventStatus.cancelado:
        return 'Cancelado';
    }
  }

  Color get statusColor {
    switch (status) {
      case ShelterEventStatus.agendado:
        return Colors.blueAccent;
      case ShelterEventStatus.emAndamento:
        return Colors.green;
      case ShelterEventStatus.concluido:
        return Colors.grey;
      case ShelterEventStatus.cancelado:
        return Colors.redAccent;
    }
  }

  bool get isPast => DateTime.now().isAfter(endDate ?? startDate);

  static ShelterEventType _parseEventType(String? type) {
    switch (type?.toLowerCase()) {
      case 'adocao':
        return ShelterEventType.adocao;
      case 'vacinacao':
        return ShelterEventType.vacinacao;
      case 'bazar':
        return ShelterEventType.bazar;
      case 'encontro':
        return ShelterEventType.encontro;
      default:
        return ShelterEventType.outro;
    }
  }

  static String eventTypeDbString(ShelterEventType type) {
    switch (type) {
      case ShelterEventType.adocao:
        return 'adocao';
      case ShelterEventType.vacinacao:
        return 'vacinacao';
      case ShelterEventType.bazar:
        return 'bazar';
      case ShelterEventType.encontro:
        return 'encontro';
      case ShelterEventType.outro:
        return 'outro';
    }
  }

  static ShelterEventStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'agendado':
        return ShelterEventStatus.agendado;
      case 'em_andamento':
        return ShelterEventStatus.emAndamento;
      case 'concluido':
        return ShelterEventStatus.concluido;
      case 'cancelado':
        return ShelterEventStatus.cancelado;
      default:
        return ShelterEventStatus.agendado;
    }
  }

  static String statusDbString(ShelterEventStatus status) {
    switch (status) {
      case ShelterEventStatus.agendado:
        return 'agendado';
      case ShelterEventStatus.emAndamento:
        return 'em_andamento';
      case ShelterEventStatus.concluido:
        return 'concluido';
      case ShelterEventStatus.cancelado:
        return 'cancelado';
    }
  }
}
