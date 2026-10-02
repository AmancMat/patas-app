import 'package:flutter/material.dart';
import 'package:patas_web_app/src/features/pets/models/pet_model.dart';
import 'package:patas_web_app/src/features/pets/services/pet_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ActivePetProvider extends ChangeNotifier {
  final PetService _petService = PetService();
  Pet? _activePet;
  bool _isLoading = false;

  Pet? get activePet => _activePet;
  bool get isLoading => _isLoading;

  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void setActivePet(Pet? pet) {
    final isDifferentId = _activePet?.id != pet?.id;
    _activePet = pet;
    notifyListeners();

    // Sincroniza a seleção do novo pet ativo com o Supabase em background
    if (pet != null && isDifferentId) {
      _syncActivePetToDatabase(pet.id);
    }
  }

  void updateActivePet(Pet pet) {
    _activePet = pet;
    notifyListeners();
  }

  Future<void> _syncActivePetToDatabase(String petId) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // 1. Define todos os pets do usuário como inativos
      await Supabase.instance.client
          .from('pets')
          .update({'is_active': false})
          .eq('user_id', user.id);

      // 2. Define apenas o pet selecionado como ativo
      await Supabase.instance.client
          .from('pets')
          .update({'is_active': true})
          .eq('id', petId);

      debugPrint('ActivePetProvider: Pet $petId definido como ativo no banco de dados.');
    } catch (e) {
      debugPrint('ActivePetProvider: Erro ao sincronizar pet ativo no banco: $e');
    }
  }

  Future<void> initialize() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setLoading(true);
    try {
      final pets = await _petService.getPetsByUserId(user.id);
      if (pets.isNotEmpty) {
        // Se já tiver um pet ativo (ex: de uma sessão anterior/navegação), tenta mantê-lo
        if (_activePet == null || !pets.any((p) => p.id == _activePet!.id)) {
          _activePet = pets.first;
        } else {
          // Atualiza a instância
          _activePet = pets.firstWhere((p) => p.id == _activePet!.id);
        }
        
        // Garante que o pet ativo inicial está sincronizado no banco de dados
        _syncActivePetToDatabase(_activePet!.id);
      } else {
        _activePet = null;
      }
    } catch (e) {
      debugPrint('Erro ao inicializar pet ativo: $e');
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  void clearData() {
    _activePet = null;
    notifyListeners();
  }
}
