enum AccountType { user, pet, ong, company }

class ActiveAccount {
  final String id;
  final String name;
  final String? photoUrl;
  final AccountType type;

  ActiveAccount({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.type,
  });

  ActiveAccount copyWith({
    String? id,
    String? name,
    String? photoUrl,
    AccountType? type,
  }) {
    return ActiveAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'photoUrl': photoUrl,
      'type': type.name,
    };
  }

  factory ActiveAccount.fromJson(Map<String, dynamic> json) {
    return ActiveAccount(
      id: json['id'],
      name: json['name'],
      photoUrl: json['photoUrl'],
      type: AccountType.values.byName(json['type']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveAccount &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type;

  @override
  int get hashCode => id.hashCode ^ type.hashCode;
}
