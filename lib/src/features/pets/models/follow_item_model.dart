import 'package:patas_web_app/src/features/pets/models/pet_model.dart';
import 'package:patas_web_app/src/features/ongs_corp/models/ong_profile_model.dart';
import 'package:patas_web_app/src/features/ongs_corp/models/corp_profile_model.dart';

enum FollowItemType { pet, ong, corp, tutor }

class FollowItem {
  final String id;
  final String name;
  final String? photoUrl;
  final String subtitle;
  final FollowItemType type;
  final Pet? pet;
  final OngProfile? ong;
  final CorpProfile? corp;
  final String? userId;

  FollowItem({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.subtitle,
    required this.type,
    this.pet,
    this.ong,
    this.corp,
    this.userId,
  });
}
