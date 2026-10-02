import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ShelterMedicalRecord {
  final String id;
  final String ongId;
  final String animalId;
  final String? createdBy;
  final String recordType; // 'vacina', 'vermifugo', 'castracao', 'tratamento', 'exame', 'anotacao'
  final String title;
  final String? description;
  final DateTime appliedAt;
  final DateTime? nextDueDate;
  final String? veterinarianName;
  final String? batchId;
  final DateTime createdAt;

  ShelterMedicalRecord({
    required this.id,
    required this.ongId,
    required this.animalId,
    this.createdBy,
    required this.recordType,
    required this.title,
    this.description,
    required this.appliedAt,
    this.nextDueDate,
    this.veterinarianName,
    this.batchId,
    required this.createdAt,
  });

  factory ShelterMedicalRecord.fromJson(Map<String, dynamic> json) {
    return ShelterMedicalRecord(
      id: json['id'] as String,
      ongId: json['ong_id'] as String,
      animalId: json['animal_id'] as String,
      createdBy: json['created_by'] as String?,
      recordType: json['record_type'] as String? ?? 'anotacao',
      title: json['title'] as String? ?? 'Procedimento Clínico',
      description: json['description'] as String?,
      appliedAt: json['applied_at'] != null
          ? DateTime.parse(json['applied_at'] as String)
          : DateTime.now(),
      nextDueDate: json['next_due_date'] != null
          ? DateTime.parse(json['next_due_date'] as String)
          : null,
      veterinarianName: json['veterinarian_name'] as String?,
      batchId: json['batch_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ong_id': ongId,
      'animal_id': animalId,
      if (createdBy != null) 'created_by': createdBy,
      'record_type': recordType,
      'title': title,
      'description': description,
      'applied_at': appliedAt.toIso8601String(),
      'next_due_date': nextDueDate?.toIso8601String(),
      'veterinarian_name': veterinarianName,
      'batch_id': batchId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get formattedAppliedDate =>
      DateFormat('dd/MM/yyyy', 'pt_BR').format(appliedAt);

  String? get formattedNextDueDate => nextDueDate != null
      ? DateFormat('dd/MM/yyyy', 'pt_BR').format(nextDueDate!)
      : null;

  Color get typeColor {
    switch (recordType) {
      case 'vacina':
        return Colors.teal;
      case 'vermifugo':
        return Colors.orangeAccent;
      case 'castracao':
        return Colors.purpleAccent;
      case 'tratamento':
        return Colors.redAccent;
      case 'exame':
        return Colors.blueAccent;
      case 'anotacao':
      default:
        return Colors.indigoAccent;
    }
  }

  IconData get typeIcon {
    switch (recordType) {
      case 'vacina':
        return Icons.vaccines_rounded;
      case 'vermifugo':
        return Icons.medication_rounded;
      case 'castracao':
        return Icons.medical_services_rounded;
      case 'tratamento':
        return Icons.healing_rounded;
      case 'exame':
        return Icons.science_rounded;
      case 'anotacao':
      default:
        return Icons.assignment_outlined;
    }
  }

  String get typeLabel {
    switch (recordType) {
      case 'vacina':
        return 'Vacina';
      case 'vermifugo':
        return 'Vermífugo';
      case 'castracao':
        return 'Castração';
      case 'tratamento':
        return 'Tratamento';
      case 'exame':
        return 'Exame';
      case 'anotacao':
      default:
        return 'Anotação';
    }
  }
}
