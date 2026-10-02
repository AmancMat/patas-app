import 'package:flutter/material.dart';

enum RescueUrgency {
  critico,
  alta,
  media,
  baixa,
}

enum RescueAlertType {
  ferido,
  atropelado,
  abandonadoFilhotes,
  mausTratos,
  perdido,
  outro,
}

enum RescueAlertStatus {
  aberto,
  emAtendimento,
  resgatado,
  cancelado,
}

class RescueAlert {
  final String id;
  final String? reporterUserId;
  final String reporterName;
  final String reporterPhone;
  final String title;
  final String description;
  final RescueUrgency urgency;
  final RescueAlertType alertType;
  final List<String> photos;
  final String address;
  final String? city;
  final String? neighborhood;
  final String? referencePoint;
  final double? latitude;
  final double? longitude;
  final RescueAlertStatus status;
  final String? assignedOngId;
  final DateTime? assignedAt;
  final String? convertedAnimalId;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const RescueAlert({
    required this.id,
    this.reporterUserId,
    required this.reporterName,
    required this.reporterPhone,
    required this.title,
    required this.description,
    required this.urgency,
    required this.alertType,
    this.photos = const [],
    required this.address,
    this.city,
    this.neighborhood,
    this.referencePoint,
    this.latitude,
    this.longitude,
    this.status = RescueAlertStatus.aberto,
    this.assignedOngId,
    this.assignedAt,
    this.convertedAnimalId,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory RescueAlert.fromMap(Map<String, dynamic> map) {
    return RescueAlert(
      id: map['id'] as String,
      reporterUserId: map['reporter_user_id'] as String?,
      reporterName: map['reporter_name'] as String? ?? 'Cidadão Anônimo',
      reporterPhone: map['reporter_phone'] as String? ?? '',
      title: map['title'] as String? ?? 'Alerta de Animal em Risco',
      description: map['description'] as String? ?? '',
      urgency: _parseUrgency(map['urgency'] as String?),
      alertType: _parseType(map['alert_type'] as String?),
      photos: (map['photos'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      address: map['address'] as String? ?? '',
      city: map['city'] as String?,
      neighborhood: map['neighborhood'] as String?,
      referencePoint: map['reference_point'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      status: _parseStatus(map['status'] as String?),
      assignedOngId: map['assigned_ong_id'] as String?,
      assignedAt: map['assigned_at'] != null
          ? DateTime.parse(map['assigned_at'] as String).toLocal()
          : null,
      convertedAnimalId: map['converted_animal_id'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String).toLocal()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String).toLocal()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (reporterUserId != null) 'reporter_user_id': reporterUserId,
      'reporter_name': reporterName,
      'reporter_phone': reporterPhone,
      'title': title,
      'description': description,
      'urgency': urgencyDbString(urgency),
      'alert_type': typeDbString(alertType),
      'photos': photos,
      'address': address,
      'city': city,
      'neighborhood': neighborhood,
      'reference_point': referencePoint,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'status': statusDbString(status),
      'assigned_ong_id': assignedOngId,
      'assigned_at': assignedAt?.toUtc().toIso8601String(),
      'converted_animal_id': convertedAnimalId,
      'notes': notes,
    };
  }

  RescueAlert copyWith({
    String? id,
    String? reporterUserId,
    String? reporterName,
    String? reporterPhone,
    String? title,
    String? description,
    RescueUrgency? urgency,
    RescueAlertType? alertType,
    List<String>? photos,
    String? address,
    String? city,
    String? neighborhood,
    String? referencePoint,
    double? latitude,
    double? longitude,
    RescueAlertStatus? status,
    String? assignedOngId,
    DateTime? assignedAt,
    String? convertedAnimalId,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RescueAlert(
      id: id ?? this.id,
      reporterUserId: reporterUserId ?? this.reporterUserId,
      reporterName: reporterName ?? this.reporterName,
      reporterPhone: reporterPhone ?? this.reporterPhone,
      title: title ?? this.title,
      description: description ?? this.description,
      urgency: urgency ?? this.urgency,
      alertType: alertType ?? this.alertType,
      photos: photos ?? this.photos,
      address: address ?? this.address,
      city: city ?? this.city,
      neighborhood: neighborhood ?? this.neighborhood,
      referencePoint: referencePoint ?? this.referencePoint,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      assignedOngId: assignedOngId ?? this.assignedOngId,
      assignedAt: assignedAt ?? this.assignedAt,
      convertedAnimalId: convertedAnimalId ?? this.convertedAnimalId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // --- HELPERS VISUAIS E DE STATUS ---

  String get urgencyLabel {
    switch (urgency) {
      case RescueUrgency.critico:
        return 'Urgência Crítica';
      case RescueUrgency.alta:
        return 'Alta Prioridade';
      case RescueUrgency.media:
        return 'Média Urgência';
      case RescueUrgency.baixa:
        return 'Baixa Urgência';
    }
  }

  Color get urgencyColor {
    switch (urgency) {
      case RescueUrgency.critico:
        return const Color(0xFFDC2626); // Vermelho sangue
      case RescueUrgency.alta:
        return const Color(0xFFEA580C); // Laranja queimado
      case RescueUrgency.media:
        return const Color(0xFFD97706); // Âmbar
      case RescueUrgency.baixa:
        return const Color(0xFF2563EB); // Azul calmo
    }
  }

  IconData get urgencyIcon {
    switch (urgency) {
      case RescueUrgency.critico:
        return Icons.emergency_rounded;
      case RescueUrgency.alta:
        return Icons.warning_rounded;
      case RescueUrgency.media:
        return Icons.info_outline_rounded;
      case RescueUrgency.baixa:
        return Icons.schedule_rounded;
    }
  }

  String get typeLabel {
    switch (alertType) {
      case RescueAlertType.ferido:
        return 'Animal Ferido';
      case RescueAlertType.atropelado:
        return 'Atropelamento';
      case RescueAlertType.abandonadoFilhotes:
        return 'Filhotes Abandonados';
      case RescueAlertType.mausTratos:
        return 'Denúncia de Maus-Tratos';
      case RescueAlertType.perdido:
        return 'Animal Desorientado / Perdido';
      case RescueAlertType.outro:
        return 'Outro Risco';
    }
  }

  IconData get typeIcon {
    switch (alertType) {
      case RescueAlertType.ferido:
        return Icons.healing_rounded;
      case RescueAlertType.atropelado:
        return Icons.car_crash_rounded;
      case RescueAlertType.abandonadoFilhotes:
        return Icons.pets_rounded;
      case RescueAlertType.mausTratos:
        return Icons.shield_rounded;
      case RescueAlertType.perdido:
        return Icons.explore_rounded;
      case RescueAlertType.outro:
        return Icons.warning_amber_rounded;
    }
  }

  Color get typeColor {
    switch (alertType) {
      case RescueAlertType.ferido:
        return Colors.orangeAccent;
      case RescueAlertType.atropelado:
        return Colors.redAccent;
      case RescueAlertType.abandonadoFilhotes:
        return Colors.amber;
      case RescueAlertType.mausTratos:
        return Colors.deepOrange;
      case RescueAlertType.perdido:
        return Colors.blueAccent;
      case RescueAlertType.outro:
        return Colors.purpleAccent;
    }
  }

  String get statusLabel {
    switch (status) {
      case RescueAlertStatus.aberto:
        return 'Aguardando Socorro';
      case RescueAlertStatus.emAtendimento:
        return 'ONG a Caminho / Em Atendimento';
      case RescueAlertStatus.resgatado:
        return 'Resgate Concluído 🎉';
      case RescueAlertStatus.cancelado:
        return 'Chamado Encerrado';
    }
  }

  Color get statusColor {
    switch (status) {
      case RescueAlertStatus.aberto:
        return const Color(0xFFDC2626);
      case RescueAlertStatus.emAtendimento:
        return const Color(0xFFD97706);
      case RescueAlertStatus.resgatado:
        return const Color(0xFF059669);
      case RescueAlertStatus.cancelado:
        return Colors.grey;
    }
  }

  static RescueUrgency _parseUrgency(String? val) {
    switch (val?.toLowerCase()) {
      case 'critico':
        return RescueUrgency.critico;
      case 'alta':
        return RescueUrgency.alta;
      case 'media':
        return RescueUrgency.media;
      case 'baixa':
        return RescueUrgency.baixa;
      default:
        return RescueUrgency.media;
    }
  }

  static String urgencyDbString(RescueUrgency val) {
    switch (val) {
      case RescueUrgency.critico:
        return 'critico';
      case RescueUrgency.alta:
        return 'alta';
      case RescueUrgency.media:
        return 'media';
      case RescueUrgency.baixa:
        return 'baixa';
    }
  }

  static RescueAlertType _parseType(String? val) {
    switch (val?.toLowerCase()) {
      case 'ferido':
        return RescueAlertType.ferido;
      case 'atropelado':
        return RescueAlertType.atropelado;
      case 'abandonado_filhotes':
        return RescueAlertType.abandonadoFilhotes;
      case 'maus_tratos':
        return RescueAlertType.mausTratos;
      case 'perdido':
        return RescueAlertType.perdido;
      default:
        return RescueAlertType.outro;
    }
  }

  static String typeDbString(RescueAlertType val) {
    switch (val) {
      case RescueAlertType.ferido:
        return 'ferido';
      case RescueAlertType.atropelado:
        return 'atropelado';
      case RescueAlertType.abandonadoFilhotes:
        return 'abandonado_filhotes';
      case RescueAlertType.mausTratos:
        return 'maus_tratos';
      case RescueAlertType.perdido:
        return 'perdido';
      case RescueAlertType.outro:
        return 'outro';
    }
  }

  static RescueAlertStatus _parseStatus(String? val) {
    switch (val?.toLowerCase()) {
      case 'aberto':
        return RescueAlertStatus.aberto;
      case 'em_atendimento':
        return RescueAlertStatus.emAtendimento;
      case 'resgatado':
        return RescueAlertStatus.resgatado;
      case 'cancelado':
        return RescueAlertStatus.cancelado;
      default:
        return RescueAlertStatus.aberto;
    }
  }

  static String statusDbString(RescueAlertStatus val) {
    switch (val) {
      case RescueAlertStatus.aberto:
        return 'aberto';
      case RescueAlertStatus.emAtendimento:
        return 'em_atendimento';
      case RescueAlertStatus.resgatado:
        return 'resgatado';
      case RescueAlertStatus.cancelado:
        return 'cancelado';
    }
  }
}
