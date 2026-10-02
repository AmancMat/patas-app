import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:patas_web_app/src/models/active_account_model.dart';
import 'package:patas_web_app/src/features/pets/active_pet_provider.dart';
import 'package:patas_web_app/src/features/pets/services/pet_service.dart';
import 'package:patas_web_app/src/providers/user_role_provider.dart';

class ActiveAccountProvider extends ChangeNotifier {
  ActiveAccount? _activeAccount;
  ActiveAccount? _previousAccount;
  bool _isLoading = false;

  ActiveAccount? get activeAccount => _activeAccount;
  ActiveAccount? get previousAccount => _previousAccount;
  bool get isLoading => _isLoading;

  static const String _storageKey = 'active_account_v2';
  static const String _previousStorageKey = 'previous_account_v2';

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> setActiveAccount(ActiveAccount account,
      {ActivePetProvider? petProvider}) async {
    // Se a conta for a mesma, não faz nada
    if (_activeAccount?.id == account.id &&
        _activeAccount?.type == account.type) {
      return;
    }

    _previousAccount = _activeAccount;
    _activeAccount = account;

    // 1. Persistir no SharedPreferences imediatamente para evitar condições de corrida
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(account.toJson()));
      if (_previousAccount != null) {
        await prefs.setString(
            _previousStorageKey, jsonEncode(_previousAccount!.toJson()));
      }
    } catch (e) {
      debugPrint('Erro ao persistir conta ativa no SharedPreferences: $e');
    }

    // 2. Sincronizar com ActivePetProvider se for um pet
    if (account.type == AccountType.pet && petProvider != null) {
      final petService = PetService();
      try {
        final pet = await petService.getPetById(account.id);
        if (pet != null) {
          petProvider.setActivePet(pet);
        }
      } catch (e) {
        debugPrint('Erro ao sincronizar pet no ActiveAccountProvider: $e');
      }
    }

    // 3. Notificar ouvintes após a persistência e sincronização concluídas
    notifyListeners();
  }

  Future<void> initialize({UserRoleProvider? roleProvider}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString(_storageKey);
      final savedPreviousData = prefs.getString(_previousStorageKey);

      final petService = PetService();

      if (savedData != null) {
        final account = ActiveAccount.fromJson(jsonDecode(savedData));

        if (account.type == AccountType.user) {
          final userData = await Supabase.instance.client
              .from('users')
              .select()
              .eq('id', user.id)
              .single();
          _activeAccount = ActiveAccount(
            id: user.id,
            name: userData['name'] ?? 'Meu Perfil',
            photoUrl: userData['photo_url'],
            type: AccountType.user,
          );
        } else {
          _activeAccount = account;
        }

        // Carregar conta anterior salva ou aplicar o primeiro fallback
        if (savedPreviousData != null) {
          _previousAccount =
              ActiveAccount.fromJson(jsonDecode(savedPreviousData));
        } else {
          // Se não houver conta anterior salva, vamos definir uma
          if (_activeAccount?.type != AccountType.user) {
            // Se o ativo for Pet/ONG/Corp, o pessoal é o anterior
            final userData = await Supabase.instance.client
                .from('users')
                .select()
                .eq('id', user.id)
                .maybeSingle();
            if (userData != null) {
              _previousAccount = ActiveAccount(
                id: user.id,
                name: userData['name'] ?? 'Meu Perfil',
                photoUrl: userData['photo_url'],
                type: AccountType.user,
              );
            }
          } else {
            // Se o ativo for Usuário, buscamos um pet para ser o anterior
            final pets = await petService.getPetsByUserId(user.id);
            if (pets.isNotEmpty) {
              final firstPet = pets.first;
              _previousAccount = ActiveAccount(
                id: firstPet.id,
                name: firstPet.name,
                photoUrl: firstPet.photoUrl,
                type: AccountType.pet,
              );
            }
          }
        }
      } else {
        // Primeira execução ou sem dados salvos
        final userData = await Supabase.instance.client
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        final pets = await petService.getPetsByUserId(user.id);

        if (pets.isNotEmpty) {
          final firstPet = pets.first;
          _activeAccount = ActiveAccount(
            id: firstPet.id,
            name: firstPet.name,
            photoUrl: firstPet.photoUrl,
            type: AccountType.pet,
          );
          // O anterior nesse caso seria o usuário
          _previousAccount = ActiveAccount(
            id: user.id,
            name: userData?['name'] ?? 'Meu Perfil',
            photoUrl: userData?['photo_url'],
            type: AccountType.user,
          );
        } else {
          _activeAccount = ActiveAccount(
            id: user.id,
            name: userData?['name'] ?? 'Meu Perfil',
            photoUrl: userData?['photo_url'],
            type: AccountType.user,
          );
          // Aqui não há conta anterior (usuário sem pets)
          _previousAccount = null;
        }
      }
    } catch (e) {
      debugPrint('Erro ao inicializar conta ativa: $e');
    } finally {
      setLoading(false);
      // Busca a role do usuário após carregar a conta
      await roleProvider?.fetchRole();
    }
  }

  Future<void> updateAccountDetails({
    required String id,
    String? name,
    String? photoUrl,
  }) async {
    bool changed = false;
    final prefs = await SharedPreferences.getInstance();

    if (_activeAccount != null && _activeAccount!.id == id) {
      _activeAccount = _activeAccount!.copyWith(
        name: name ?? _activeAccount!.name,
        photoUrl: photoUrl ?? _activeAccount!.photoUrl,
      );
      await prefs.setString(_storageKey, jsonEncode(_activeAccount!.toJson()));
      changed = true;
    }

    if (_previousAccount != null && _previousAccount!.id == id) {
      _previousAccount = _previousAccount!.copyWith(
        name: name ?? _previousAccount!.name,
        photoUrl: photoUrl ?? _previousAccount!.photoUrl,
      );
      await prefs.setString(
          _previousStorageKey, jsonEncode(_previousAccount!.toJson()));
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  Future<void> clearData() async {
    _activeAccount = null;
    _previousAccount = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove(_previousStorageKey);
    notifyListeners();
  }
}
