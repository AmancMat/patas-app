import 'package:flutter/widgets.dart';
import 'package:patas_web_app/src/localization/localizations_ext.dart';

class FamilyMember {
  final String id;
  final String userId;
  final String name;
  final String relationship;
  final String? photoUrl;
  final DateTime createdAt;

  FamilyMember({
    required this.id,
    required this.userId,
    required this.name,
    required this.relationship,
    this.photoUrl,
    required this.createdAt,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      relationship: json['relationship'],
      photoUrl: json['photo_url'],
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'relationship': relationship,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static String localizedRelationship(BuildContext context, String rel) {
    switch (rel.trim().toLowerCase()) {
      case 'pai':
      case 'father':
        return context.tr('family.father');
      case 'mãe':
      case 'mae':
      case 'mother':
        return context.tr('family.mother');
      case 'irmão':
      case 'irmao':
      case 'brother':
        return context.tr('family.brother');
      case 'irmã':
      case 'irma':
      case 'sister':
        return context.tr('family.sister');
      case 'amigo':
        return context.tr('family.friend_m');
      case 'amiga':
        return context.tr('family.friend_f');
      case 'tio':
      case 'uncle':
        return context.tr('family.uncle');
      case 'tia':
      case 'aunt':
        return context.tr('family.aunt');
      case 'avô':
      case 'avo':
      case 'grandfather':
        return context.tr('family.grandfather');
      case 'avó':
      case 'grandmother':
        return context.tr('family.grandmother');
      case 'primo':
        return context.tr('family.cousin_m');
      case 'prima':
        return context.tr('family.cousin_f');
      case 'outro':
      case 'other':
        return context.tr('family.other');
      default:
        return rel;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FamilyMember &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
