import 'package:flutter/material.dart';
import 'package:patas_web_app/src/features/pets/models/pet_model.dart';
import 'package:patas_web_app/src/features/ongs_corp/models/ong_profile_model.dart';
import 'package:patas_web_app/src/features/ongs_corp/models/corp_profile_model.dart';

class ProfileViewProvider extends ChangeNotifier {
  Pet? _targetPet;
  OngProfile? _targetOng;
  CorpProfile? _targetCorp;

  Pet? get targetPet => _targetPet;
  OngProfile? get targetOng => _targetOng;
  CorpProfile? get targetCorp => _targetCorp;

  bool get hasTarget => _targetPet != null || _targetOng != null || _targetCorp != null;

  void setViewProfile({Pet? pet, OngProfile? ong, CorpProfile? corp}) {
    _targetPet = pet;
    _targetOng = ong;
    _targetCorp = corp;
    notifyListeners();
  }

  void clear() {
    if (hasTarget) {
      _targetPet = null;
      _targetOng = null;
      _targetCorp = null;
      notifyListeners();
    }
  }
}
