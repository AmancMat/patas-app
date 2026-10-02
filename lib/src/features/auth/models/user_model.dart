// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class UserModel {
  final String? id;
  final String? name;
  final String? email;
  final String? password;
  final String? photoUrl;
  final DateTime? deletionRequestedAt;

  UserModel({
    this.id,
    this.name,
    this.email,
    this.password,
    this.photoUrl,
    this.deletionRequestedAt,
  });

  /// Verifica se a conta está pendente de exclusão
  bool get isPendingDeletion => deletionRequestedAt != null;

  /// Calcula quantos dias faltam para a exclusão permanente (30 dias após solicitação)
  int? get daysUntilDeletion {
    if (deletionRequestedAt == null) return null;
    final deletionDate = deletionRequestedAt!.add(const Duration(days: 30));
    final daysLeft = deletionDate.difference(DateTime.now()).inDays;
    return daysLeft > 0 ? daysLeft : 0;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'photo_url': photoUrl,
      'deletion_requested_at': deletionRequestedAt?.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] != null ? map['id'] as String : null,
      name: map['name'] != null ? map['name'] as String : null,
      email: map['email'] != null ? map['email'] as String : null,
      password: map['password'] != null ? map['password'] as String : null,
      photoUrl: map['photo_url'] != null ? map['photo_url'] as String : null,
      deletionRequestedAt: map['deletion_requested_at'] != null
          ? DateTime.parse(map['deletion_requested_at'] as String)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
