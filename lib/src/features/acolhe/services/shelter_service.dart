import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shelter_animal_model.dart';
import '../models/adoption_application_model.dart';
import '../models/donation_campaign_model.dart';
import '../models/shelter_medical_record_model.dart';
import '../models/temporary_home_model.dart';
import '../models/shelter_event_model.dart';
import '../models/rescue_alert_model.dart';
import '../models/shelter_donation_receipt_model.dart';
import '../../solana/services/solana_pay_service.dart';
import 'package:patas_web_app/src/services/supabase_notification_service.dart';
import 'package:patas_web_app/src/models/notification_model.dart';

class ShelterService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ─────────────────────────────────────────────
  // 🐶 ANIMAIS DA ONG (GESTÃO PATAS ACOLHE)
  // ─────────────────────────────────────────────

  Future<List<ShelterAnimal>> getShelterAnimals(
    String ongId, {
    String? status,
  }) async {
    try {
      var filter = _supabase.from('shelter_animals').select().eq('ong_id', ongId);

      if (status != null && status != 'todos') {
        filter = filter.eq('status', status);
      }

      final response = await filter.order('created_at', ascending: false);
      final list = (response as List)
          .map((json) => ShelterAnimal.fromJson(json as Map<String, dynamic>))
          .toList();

      return list;
    } catch (e) {
      debugPrint('Erro ao buscar animais da ONG: $e');
      return [];
    }
  }

  Future<ShelterAnimal?> createShelterAnimal(ShelterAnimal animal) async {
    try {
      final user = _supabase.auth.currentUser;
      final data = animal.toJson();
      if (user != null) {
        data['created_by'] = user.id;
      }

      final response = await _supabase
          .from('shelter_animals')
          .insert(data)
          .select()
          .single();

      return ShelterAnimal.fromJson(response);
    } catch (e) {
      debugPrint('Erro ao cadastrar animal acolhido: $e');
      return null;
    }
  }

  Future<bool> updateShelterAnimal(ShelterAnimal animal) async {
    try {
      await _supabase
          .from('shelter_animals')
          .update(animal.toJson())
          .eq('id', animal.id);
      return true;
    } catch (e) {
      debugPrint('Erro ao atualizar animal: $e');
      return false;
    }
  }

  Future<bool> deleteShelterAnimal(String animalId) async {
    try {
      await _supabase.from('shelter_animals').delete().eq('id', animalId);
      return true;
    } catch (e) {
      debugPrint('Erro ao deletar animal: $e');
      return false;
    }
  }

  Future<String?> uploadAnimalPhoto(File imageFile, String ongId) async {
    try {
      final String fileName =
          'animal_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = 'public/shelter_animals/$ongId/$fileName';

      if (kIsWeb) {
        final bytes = await XFile(imageFile.path).readAsBytes();
        await _supabase.storage.from('pet_avatars').uploadBinary(
              filePath,
              bytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
      } else {
        await _supabase.storage.from('pet_avatars').upload(
              filePath,
              imageFile,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
      }

      return _supabase.storage.from('pet_avatars').getPublicUrl(filePath);
    } catch (e) {
      debugPrint('Erro no upload da foto do animal acolhido: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // 🐾 FEED PÚBLICO DE ADOÇÃO (PATAS ESSENCIAL)
  // ─────────────────────────────────────────────

  Future<List<ShelterAnimal>> getPublicAdoptionAnimals({
    String? species,
    String? size,
    String? query,
  }) async {
    try {
      var filter = _supabase
          .from('shelter_animals')
          .select('*, ong_profiles:ong_id(name, address, phone)')
          .eq('is_public_adoption', true)
          .eq('status', 'disponivel');

      if (species != null && species != 'todos') {
        filter = filter.eq('species', species.toLowerCase());
      }
      if (size != null && size != 'todos') {
        filter = filter.eq('size', size.toLowerCase());
      }
      if (query != null && query.trim().isNotEmpty) {
        filter = filter.ilike('name', '%${query.trim()}%');
      }

      final response = await filter.order('created_at', ascending: false);
      final list = (response as List)
          .map((json) => ShelterAnimal.fromJson(json as Map<String, dynamic>))
          .toList();

      if (list.isEmpty) {
        return _getDemoPublicAdoptionAnimals(
          species: species,
          size: size,
          query: query,
        );
      }

      return list;
    } catch (e) {
      debugPrint('Erro ao buscar animais públicos para adoção: $e');
      return _getDemoPublicAdoptionAnimals(
        species: species,
        size: size,
        query: query,
      );
    }
  }

  // ─────────────────────────────────────────────
  // 📝 PROPOSTAS / FICHAS DE ADOÇÃO
  // ─────────────────────────────────────────────

  Future<bool> submitAdoptionApplication(AdoptionApplication app) async {
    try {
      await _supabase.from('adoption_applications').insert(app.toJson());
      return true;
    } catch (e) {
      debugPrint('Erro ao enviar proposta de adoção: $e');
      return false;
    }
  }

  Future<List<AdoptionApplication>> getOngAdoptionApplications(
      String ongId) async {
    try {
      final response = await _supabase
          .from('adoption_applications')
          .select('*, shelter_animals(*)')
          .eq('ong_id', ongId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) =>
              AdoptionApplication.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Erro ao buscar fichas de adoção da ONG: $e');
      return [];
    }
  }

  Future<bool> updateApplicationStatus(
    String applicationId,
    String status, {
    String? notes,
  }) async {
    try {
      final data = {'status': status};
      if (notes != null) data['notes_ong'] = notes;

      await _supabase
          .from('adoption_applications')
          .update(data)
          .eq('id', applicationId);
      return true;
    } catch (e) {
      debugPrint('Erro ao atualizar status da proposta de adoção: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // 🎭 DADOS DEMONSTRATIVOS (CATÁLOGO PÚBLICO)
  // ─────────────────────────────────────────────

  List<ShelterAnimal> _getDemoPublicAdoptionAnimals({
    String? species,
    String? size,
    String? query,
  }) {
    final all = [
      ShelterAnimal(
        id: 'pub-animal-1',
        ongId: 'ong-1',
        name: 'Paçoca',
        species: 'canino',
        breed: 'Caramelo SRD',
        gender: 'macho',
        size: 'medio',
        ageEstimate: '1 ano e meio',
        rescueStory:
            'Resgatado das ruas, Paçoca adora brincar, é super amigável e só quer um sofá quentinho para descansar.',
        behaviorNotes: 'Sociável com cães e crianças. Super dócil.',
        photoUrl:
            'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=800',
        isCastrated: true,
        isVaccinated: true,
        isDewormed: true,
        status: 'disponivel',
        isPublicAdoption: true,
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        updatedAt: DateTime.now(),
        ongName: 'Instituto Patas do Bem',
        ongCity: 'São Paulo, SP',
        ongPhone: '(11) 98765-4321',
      ),
      ShelterAnimal(
        id: 'pub-animal-2',
        ongId: 'ong-2',
        name: 'Luna',
        species: 'felino',
        breed: 'Mestiça Siamês',
        gender: 'femea',
        size: 'pequeno',
        ageEstimate: '8 meses',
        rescueStory:
            'Luna foi resgatada junto com sua mãe. É dócil, companheira e adora dormir no colo.',
        behaviorNotes: 'Calma e carinhosa. Ideal para apê telado.',
        photoUrl:
            'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=800',
        isCastrated: true,
        isVaccinated: true,
        isDewormed: true,
        status: 'disponivel',
        isPublicAdoption: true,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now(),
        ongName: 'Gatinhos da Vila',
        ongCity: 'Campinas, SP',
        ongPhone: '(19) 99876-1234',
      ),
      ShelterAnimal(
        id: 'pub-animal-3',
        ongId: 'ong-1',
        name: 'Pipoca',
        species: 'canino',
        breed: 'Mestiça Poodle',
        gender: 'femea',
        size: 'pequeno',
        ageEstimate: '2 anos',
        rescueStory:
            'Abandonada após mudança dos antigos donos. É extremamente carinhosa e adora passear de coleira.',
        behaviorNotes: 'Muito dócil, aprende comandos rápido e adora carinho na barriga.',
        photoUrl:
            'https://images.unsplash.com/photo-1537151625747-768eb6cf92b2?w=800',
        isCastrated: true,
        isVaccinated: true,
        isDewormed: true,
        status: 'disponivel',
        isPublicAdoption: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now(),
        ongName: 'Instituto Patas do Bem',
        ongCity: 'São Paulo, SP',
        ongPhone: '(11) 98765-4321',
      ),
      ShelterAnimal(
        id: 'pub-animal-4',
        ongId: 'ong-3',
        name: 'Thor',
        species: 'canino',
        breed: 'Mestiço Labrador',
        gender: 'macho',
        size: 'grande',
        ageEstimate: '1 ano',
        rescueStory:
            'Resgatado filhotinho magro de um ferro-velho. Hoje é um gigante cheio de energia e amor pra dar.',
        behaviorNotes: 'Energético, amoroso, ótimo parceiro de corrida.',
        photoUrl:
            'https://images.unsplash.com/photo-1552053831-71594a27632d?w=800',
        isCastrated: true,
        isVaccinated: true,
        isDewormed: true,
        status: 'disponivel',
        isPublicAdoption: true,
        createdAt: DateTime.now().subtract(const Duration(days: 6)),
        updatedAt: DateTime.now(),
        ongName: 'Abrigo Esperança Pet',
        ongCity: 'Santos, SP',
        ongPhone: '(13) 98877-6655',
      ),
    ];

    return all.where((a) {
      if (species != null && species != 'todos' && a.species != species.toLowerCase()) {
        return false;
      }
      if (size != null && size != 'todos' && a.size != size.toLowerCase()) {
        return false;
      }
      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        return a.name.toLowerCase().contains(q) ||
            a.breed.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  // ─────────────────────────────────────────────
  // 💖 MURAL DE DOAÇÕES & CAMPANHAS (PATAS ACOLHE)
  // ─────────────────────────────────────────────

  Future<List<DonationCampaign>> getDonationCampaigns({
    String? ongId,
    String? category,
    bool activeOnly = true,
  }) async {
    try {
      var filter = _supabase.from('shelter_donation_campaigns').select();

      if (ongId != null && ongId.isNotEmpty) {
        filter = filter.eq('ong_id', ongId);
      }
      if (activeOnly) {
        filter = filter.eq('is_active', true);
      }
      if (category != null && category != 'Todos') {
        filter = filter.eq('category', category);
      }

      final response = await filter
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 4));

      final list = (response as List)
          .map((json) => DonationCampaign.fromJson(json as Map<String, dynamic>))
          .toList();

      return list;
    } catch (e) {
      debugPrint('[ShelterService] Erro ao buscar campanhas de doação: $e');
      return [];
    }
  }

  Future<DonationCampaign?> createDonationCampaign(DonationCampaign campaign) async {
    return saveDonationCampaign(campaign);
  }

  /// Salva ou atualiza uma campanha existente (evitando duplicações)
  Future<DonationCampaign?> saveDonationCampaign(DonationCampaign campaign) async {
    try {
      final isUpdating = campaign.id.trim().isNotEmpty;
      final data = campaign.toJson();
      data.remove('id'); // Nunca envia 'id' no body para evitar conflitos de PK

      if (isUpdating) {
        data.remove('created_at'); // Preserva a data original de criação
        debugPrint('[ShelterService] Atualizando campanha existente no Supabase: ${campaign.id}');
      } else {
        debugPrint('[ShelterService] Criando nova campanha no Supabase...');
      }

      try {
        if (isUpdating) {
          final response = await _supabase
              .from('shelter_donation_campaigns')
              .update(data)
              .eq('id', campaign.id)
              .select()
              .single()
              .timeout(const Duration(seconds: 8));
          return DonationCampaign.fromJson(response);
        } else {
          final response = await _supabase
              .from('shelter_donation_campaigns')
              .insert(data)
              .select()
              .single()
              .timeout(const Duration(seconds: 8));
          return DonationCampaign.fromJson(response);
        }
      } catch (dbError) {
        // Se a coluna solana_wallet ainda não foi criada no banco, faz fallback gracioso
        if (dbError.toString().contains('solana_wallet')) {
          debugPrint('[ShelterService] Coluna solana_wallet ausente no banco. Executando sem solana_wallet...');
          data.remove('solana_wallet');
          if (isUpdating) {
            final fallbackResponse = await _supabase
                .from('shelter_donation_campaigns')
                .update(data)
                .eq('id', campaign.id)
                .select()
                .single()
                .timeout(const Duration(seconds: 8));
            return DonationCampaign.fromJson(fallbackResponse);
          } else {
            final fallbackResponse = await _supabase
                .from('shelter_donation_campaigns')
                .insert(data)
                .select()
                .single()
                .timeout(const Duration(seconds: 8));
            return DonationCampaign.fromJson(fallbackResponse);
          }
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('[ShelterService] Erro ao salvar campanha de doação: $e');
      rethrow;
    }
  }

  Future<bool> updateCampaignProgress({
    required String campaignId,
    required double newCurrentAmount,
  }) async {
    try {
      await _supabase
          .from('shelter_donation_campaigns')
          .update({'current_amount': newCurrentAmount})
          .eq('id', campaignId)
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (e) {
      debugPrint('[ShelterService] Erro ao atualizar progresso da campanha: $e');
      return false;
    }
  }

  /// Registra uma nova doação arrecadada e incrementa o progresso da campanha em tempo real
  /// Dispara notificação push e in-app para a ONG / gestor responsável
  Future<bool> registerDonationProgress({
    required String campaignId,
    required double addedAmount,
    String paymentMethod = 'solana_pay', // 'solana_pay', 'pix', 'cartao', etc.
    String? txSignature,
    String? donorName,
    String? donorPetId,
    String? donorPhoto,
    double? originalAmount,
    String? tokenSymbol,
  }) async {
    try {
      final res = await _supabase
          .from('shelter_donation_campaigns')
          .select('title, target_amount, current_amount, ong_id, created_by')
          .eq('id', campaignId)
          .single()
          .timeout(const Duration(seconds: 6));

      final title = res['title'] as String? ?? 'Campanha de Doação';
      final targetAmount = (res['target_amount'] as num?)?.toDouble() ?? 0.0;
      final current = (res['current_amount'] as num?)?.toDouble() ?? 0.0;
      final newCurrent = current + addedAmount;
      final ongId = res['ong_id'] as String?;
      final createdBy = res['created_by'] as String?;

      await _supabase
          .from('shelter_donation_campaigns')
          .update({'current_amount': newCurrent})
          .eq('id', campaignId)
          .timeout(const Duration(seconds: 6));

      debugPrint('[ShelterService] Doação computada! Campanha $campaignId: R\$ $current -> R\$ $newCurrent (+ R\$ $addedAmount)');

      // Registra o recibo individual na tabela shelter_campaign_donations
      try {
        final currentUser = _supabase.auth.currentUser;
        await _supabase.from('shelter_campaign_donations').insert({
          'campaign_id': campaignId,
          'donor_user_id': currentUser?.id,
          'donor_pet_id': donorPetId,
          'donor_name': donorName ?? currentUser?.userMetadata?['name'] ?? 'Apoiador Patas',
          'donor_photo': donorPhoto,
          'amount': addedAmount,
          'currency': 'BRL',
          'original_amount': originalAmount,
          'token_symbol': tokenSymbol ?? 'BRL',
          'payment_method': paymentMethod,
          'tx_signature': txSignature,
          'status': 'confirmed',
        });
        debugPrint('[ShelterService] Recibo de doação registrado na tabela shelter_campaign_donations!');
      } catch (e) {
        debugPrint('[ShelterService] Aviso: Falha ao inserir recibo de doação (tabela pode estar sendo criada): $e');
      }

      // Notifica o gestor da ONG responsável e o doador em tempo real
      _notifyOngNewDonation(
        ongId: ongId ?? '',
        createdBy: createdBy,
        campaignId: campaignId,
        campaignTitle: title,
        addedAmount: addedAmount,
        newTotal: newCurrent,
        targetAmount: targetAmount,
        paymentMethod: paymentMethod,
        txSignature: txSignature,
        donorName: donorName,
      );

      return true;
    } catch (e) {
      debugPrint('[ShelterService] Erro ao registrar progresso de doação: $e');
      return false;
    }
  }

  /// Verifica se uma assinatura da Solana já foi processada no banco de dados
  Future<bool> isTxSignatureAlreadyProcessed(String txSignature) async {
    try {
      final res = await _supabase
          .from('shelter_campaign_donations')
          .select('id')
          .eq('tx_signature', txSignature)
          .maybeSingle();
      return res != null;
    } catch (_) {
      return false;
    }
  }

  /// Busca as doações/recibos que o usuário atual fez para a campanha
  Future<List<ShelterDonationReceiptModel>> getUserCampaignDonations(String campaignId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final res = await _supabase
          .from('shelter_campaign_donations')
          .select()
          .eq('campaign_id', campaignId)
          .eq('donor_user_id', user.id)
          .order('created_at', ascending: false);

      return (res as List)
          .map((item) => ShelterDonationReceiptModel.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('[ShelterService] Erro ao buscar doações do usuário: $e');
      return [];
    }
  }

  /// Sincroniza transações retroativas da blockchain da Solana para a tabela de recibos
  Future<int> syncBlockchainDonations({
    required String campaignId,
    required String walletAddress,
    String? donorPetId,
    String? donorName,
    String? donorPhoto,
  }) async {
    try {
      final recentTxs = await SolanaPayService.getRecentSignatures(walletAddress, limit: 10);
      if (recentTxs.isEmpty) return 0;

      final currentUser = _supabase.auth.currentUser;
      int imported = 0;

      for (final tx in recentTxs) {
        final sig = tx['signature'] as String?;
        if (sig == null || sig.isEmpty) continue;

        // Checa se já existe
        final exists = await isTxSignatureAlreadyProcessed(sig);
        if (!exists) {
          final blockTime = tx['blockTime'] as int?;
          final createdAt = blockTime != null
              ? DateTime.fromMillisecondsSinceEpoch(blockTime * 1000)
              : DateTime.now();

          await _supabase.from('shelter_campaign_donations').insert({
            'campaign_id': campaignId,
            'donor_user_id': currentUser?.id,
            'donor_pet_id': donorPetId,
            'donor_name': donorName ?? currentUser?.userMetadata?['name'] ?? 'Apoiador Patas',
            'donor_photo': donorPhoto,
            'amount': 27.50, // Conversão padrão devnet (~R$ 27,50 / $5 USDC)
            'currency': 'BRL',
            'original_amount': 5.0,
            'token_symbol': 'USDC',
            'payment_method': 'solana_pay',
            'tx_signature': sig,
            'status': 'confirmed',
            'created_at': createdAt.toIso8601String(),
          });
          imported++;
        }
      }
      debugPrint('[ShelterService] Sincronização Solana: $imported doações importadas da blockchain!');
      return imported;
    } catch (e) {
      debugPrint('[ShelterService] Erro ao sincronizar blockchain: $e');
      return 0;
    }
  }


  /// Dispara a notificação in-app e push para o gestor responsável pela ONG e para o doador
  void _notifyOngNewDonation({
    required String ongId,
    String? createdBy,
    required String campaignId,
    required String campaignTitle,
    required double addedAmount,
    required double newTotal,
    required double targetAmount,
    required String paymentMethod,
    String? txSignature,
    String? donorName,
  }) async {
    try {
      final formattedAmount = 'R\$ ${addedAmount.toStringAsFixed(2).replaceAll('.', ',')}';
      final formattedTotal = 'R\$ ${newTotal.toStringAsFixed(2).replaceAll('.', ',')}';

      String methodLabel = 'Doação';
      if (paymentMethod == 'solana_pay') {
        methodLabel = 'Solana Pay (Devnet)';
      } else if (paymentMethod == 'pix') {
        methodLabel = 'PIX';
      } else if (paymentMethod == 'cartao') {
        methodLabel = 'Cartão';
      }

      int progressPercent = 0;
      if (targetAmount > 0) {
        progressPercent = ((newTotal / targetAmount) * 100).round();
      }

      String notifTitle;
      String notifContent;

      if (progressPercent > 100) {
        final exceeded = progressPercent - 100;
        notifTitle = '🚀 META SUPERADA (+$exceeded%): $formattedAmount recebidos!';
        notifContent =
            'Incrível! Sua campanha "$campaignTitle" superou a meta oficial em $exceeded% ($progressPercent% total)! '
            'Total acumulado: $formattedTotal via $methodLabel.';
      } else if (progressPercent == 100) {
        notifTitle = '🎉 META 100% BATIDA: $formattedAmount recebidos!';
        notifContent =
            'Parabéns! Sua campanha "$campaignTitle" atingiu 100% da meta oficial com esta doação de $formattedAmount via $methodLabel! '
            'Total acumulado: $formattedTotal.';
      } else {
        notifTitle = '💖 Nova doação recebida: $formattedAmount!';
        notifContent =
            'Sua campanha "$campaignTitle" recebeu $formattedAmount via $methodLabel. '
            'Total acumulado: $formattedTotal ($progressPercent% da meta).';
      }

      final notifPayload = {
        'campaign_id': campaignId,
        'amount': addedAmount.toString(),
        'method': paymentMethod,
        'tx_signature': txSignature ?? '',
        'progress_percent': progressPercent.toString(),
        'donor_name': donorName ?? 'Apoiador Patas',
      };

      // ─────────────────────────────────────────────────────────────
      // Resolve o gestor da ONG responsável
      // ─────────────────────────────────────────────────────────────
      final currentUser = _supabase.auth.currentUser;
      String? targetUserId = createdBy;

      if (targetUserId == null || targetUserId.isEmpty) {
        try {
          if (ongId.isNotEmpty) {
            final ongProfile = await _supabase
                .from('ong_profiles')
                .select('user_id')
                .eq('id', ongId)
                .maybeSingle();
            if (ongProfile != null && ongProfile['user_id'] != null) {
              targetUserId = ongProfile['user_id'] as String;
            }
          }
        } catch (err) {
          debugPrint('[ShelterService] Fallback de targetUserId para ongId direto: $err');
        }
      }

      // Se ainda não encontrou, usa o próprio ongId se preenchido
      if (targetUserId == null || targetUserId.isEmpty) {
        targetUserId = ongId.isNotEmpty ? ongId : null;
      }

      // ─────────────────────────────────────────────────────────────
      // Disparo de Notificações sem Duplicação
      // Observação: SupabaseNotificationService.sendNotification possui trava
      // de idempotência e já dispara showInstantNotification internamente
      // quando receiverUserId == currentUser.id.
      // ─────────────────────────────────────────────────────────────
      final bool isSelfDonation = currentUser != null &&
          (targetUserId == null || targetUserId == currentUser.id || targetUserId == ongId);

      if (isSelfDonation) {
        // Cenário 1: O doador é o próprio gestor/criador da campanha (testes ou autodoação).
        // Envia uma única notificação consolidada de sucesso e progresso da meta.
        await SupabaseNotificationService().sendNotification(
          receiverUserId: currentUser.id,
          type: NotificationType.donation,
          title: notifTitle,
          content: notifContent,
          data: notifPayload,
        );
      } else {
        // Cenário 2: Usuários distintos (apoiador externo ajudando a campanha).
        // A) Notifica o doador com seu recibo de confirmação
        if (currentUser != null) {
          final donorTitle = '🎉 Doação confirmada com sucesso!';
          final donorContent =
              'Você apoiou a campanha "$campaignTitle" com $formattedAmount via $methodLabel. Seu apoio salva vidas!';

          await SupabaseNotificationService().sendNotification(
            receiverUserId: currentUser.id,
            type: NotificationType.donation,
            title: donorTitle,
            content: donorContent,
            data: notifPayload,
          );
        }

        // B) Notifica o gestor da ONG com a nova doação recebida
        if (targetUserId != null && targetUserId.isNotEmpty && targetUserId != currentUser?.id) {
          await SupabaseNotificationService().sendNotification(
            receiverUserId: targetUserId,
            type: NotificationType.donation,
            title: notifTitle,
            content: notifContent,
            data: notifPayload,
          );
        }
      }
    } catch (e) {
      debugPrint('[ShelterService] Erro ao disparar notificação de doação: $e');
    }
  }

  Future<bool> deleteDonationCampaign(String campaignId) async {
    try {
      await _supabase
          .from('shelter_donation_campaigns')
          .delete()
          .eq('id', campaignId)
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (e) {
      debugPrint('[ShelterService] Erro ao excluir campanha: $e');
      return false;
    }
  }

  Future<String?> uploadCampaignPhoto(File imageFile, String ongId) async {
    try {
      final String fileName =
          'campaign_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = 'public/campaigns/$ongId/$fileName';

      if (kIsWeb) {
        final bytes = await XFile(imageFile.path).readAsBytes();
        await _supabase.storage.from('pet_avatars').uploadBinary(
              filePath,
              bytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
      } else {
        await _supabase.storage.from('pet_avatars').upload(
              filePath,
              imageFile,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
      }

      return _supabase.storage.from('pet_avatars').getPublicUrl(filePath);
    } catch (e) {
      debugPrint('[ShelterService] Erro no upload da foto da campanha: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // 📋 PRONTUÁRIO COLETIVO & AÇÕES EM LOTE
  // ─────────────────────────────────────────────

  Future<List<ShelterMedicalRecord>> getMedicalRecords(
    String ongId, {
    String? animalId,
    String? recordType,
  }) async {
    try {
      var query = _supabase
          .from('shelter_medical_records')
          .select()
          .eq('ong_id', ongId);

      if (animalId != null && animalId.isNotEmpty) {
        query = query.eq('animal_id', animalId);
      }
      if (recordType != null && recordType != 'todos') {
        query = query.eq('record_type', recordType);
      }

      final response = await query.order('applied_at', ascending: false);
      return (response as List)
          .map((e) => ShelterMedicalRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[ShelterService] Erro ao buscar prontuários: $e');
      return [];
    }
  }

  Future<ShelterMedicalRecord?> createMedicalRecord(
    ShelterMedicalRecord record,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      final data = record.toJson();
      if (user != null) {
        data['created_by'] = user.id;
      }

      final response = await _supabase
          .from('shelter_medical_records')
          .insert(data)
          .select()
          .single();

      // Sincroniza flags sanitárias no cadastro do animal acolhido
      Map<String, dynamic> updateFields = {};
      if (record.recordType == 'vacina') {
        updateFields['is_vaccinated'] = true;
      } else if (record.recordType == 'vermifugo') {
        updateFields['is_dewormed'] = true;
      } else if (record.recordType == 'castracao') {
        updateFields['is_castrated'] = true;
      }

      if (updateFields.isNotEmpty) {
        await _supabase
            .from('shelter_animals')
            .update(updateFields)
            .eq('id', record.animalId);
      }

      return ShelterMedicalRecord.fromJson(response);
    } catch (e) {
      debugPrint('[ShelterService] Erro ao criar prontuário médico: $e');
      return null;
    }
  }

  Future<bool> applyBatchHealthAction({
    required String ongId,
    required List<String> animalIds,
    required String recordType,
    required String title,
    String? description,
    required DateTime appliedAt,
    DateTime? nextDueDate,
    String? veterinarianName,
  }) async {
    if (animalIds.isEmpty) return false;

    try {
      final user = _supabase.auth.currentUser;
      final batchId = 'BATCH_${DateTime.now().millisecondsSinceEpoch}';

      final recordsData = animalIds.map((animalId) {
        return {
          'ong_id': ongId,
          'animal_id': animalId,
          if (user != null) 'created_by': user.id,
          'record_type': recordType,
          'title': title,
          'description': description,
          'applied_at': appliedAt.toIso8601String(),
          'next_due_date': nextDueDate?.toIso8601String(),
          'veterinarian_name': veterinarianName,
          'batch_id': batchId,
        };
      }).toList();

      // 1. Inserção em lote dos registros médicos
      await _supabase.from('shelter_medical_records').insert(recordsData);

      // 2. Atualização coletiva nas propriedades sanitárias dos animais
      Map<String, dynamic> updateFields = {};
      if (recordType == 'vacina') {
        updateFields['is_vaccinated'] = true;
      } else if (recordType == 'vermifugo') {
        updateFields['is_dewormed'] = true;
      } else if (recordType == 'castracao') {
        updateFields['is_castrated'] = true;
      }

      if (updateFields.isNotEmpty) {
        await _supabase
            .from('shelter_animals')
            .update(updateFields)
            .inFilter('id', animalIds);
      }

      return true;
    } catch (e) {
      debugPrint('[ShelterService] Erro na aplicação em lote de saúde: $e');
      return false;
    }
  }

  Future<bool> deleteMedicalRecord(String recordId) async {
    try {
      await _supabase
          .from('shelter_medical_records')
          .delete()
          .eq('id', recordId);
      return true;
    } catch (e) {
      debugPrint('[ShelterService] Erro ao excluir prontuário: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // 🤝 REDE DE LARES TEMPORÁRIOS (LTs)
  // ─────────────────────────────────────────────

  Future<List<TemporaryHome>> getTemporaryHomes(
    String ongId, {
    String? status,
  }) async {
    try {
      var query = _supabase
          .from('shelter_temporary_homes')
          .select()
          .eq('ong_id', ongId);

      if (status != null && status != 'todos') {
        query = query.eq('status', status);
      }

      final homesResponse =
          await query.order('created_at', ascending: false);

      // Busca os acolhidos vinculados aos lares desta ONG
      final animalsResponse = await _supabase
          .from('shelter_animals')
          .select()
          .eq('ong_id', ongId)
          .not('temporary_home_id', 'is', null);

      final allAnimalsInHomes = (animalsResponse as List)
          .map((a) => ShelterAnimal.fromJson(a as Map<String, dynamic>))
          .toList();

      final list = (homesResponse as List).map((homeJson) {
        final homeId = homeJson['id'] as String;
        final assignedAnimals = allAnimalsInHomes
            .where((animal) => animal.temporaryHomeId == homeId)
            .toList();

        return TemporaryHome.fromJson(
          homeJson as Map<String, dynamic>,
          animals: assignedAnimals,
        );
      }).toList();

      return list;
    } catch (e) {
      debugPrint('[ShelterService] Erro ao buscar lares temporários: $e');
      return [];
    }
  }

  Future<TemporaryHome?> createTemporaryHome(TemporaryHome home) async {
    try {
      final user = _supabase.auth.currentUser;
      final data = home.toJson();
      if (user != null) {
        data['created_by'] = user.id;
      }

      final response = await _supabase
          .from('shelter_temporary_homes')
          .insert(data)
          .select()
          .single();

      return TemporaryHome.fromJson(response);
    } catch (e) {
      debugPrint('[ShelterService] Erro ao cadastrar lar temporário: $e');
      return null;
    }
  }

  Future<bool> updateTemporaryHome(TemporaryHome home) async {
    try {
      await _supabase
          .from('shelter_temporary_homes')
          .update(home.toJson())
          .eq('id', home.id);
      return true;
    } catch (e) {
      debugPrint('[ShelterService] Erro ao atualizar lar temporário: $e');
      return false;
    }
  }

  Future<bool> deleteTemporaryHome(String homeId) async {
    try {
      // 1. Remove o vínculo dos animais antes de excluir o lar
      await _supabase
          .from('shelter_animals')
          .update({
            'temporary_home_id': null,
            'status': 'disponivel',
          })
          .eq('temporary_home_id', homeId);

      // 2. Deleta o registro do lar
      await _supabase
          .from('shelter_temporary_homes')
          .delete()
          .eq('id', homeId);

      return true;
    } catch (e) {
      debugPrint('[ShelterService] Erro ao excluir lar temporário: $e');
      return false;
    }
  }

  Future<bool> assignAnimalToTemporaryHome({
    required String animalId,
    required String homeId,
  }) async {
    try {
      await _supabase.from('shelter_animals').update({
        'temporary_home_id': homeId,
        'status': 'lar_temporario',
      }).eq('id', animalId);

      return true;
    } catch (e) {
      debugPrint('[ShelterService] Erro ao hospedar animal no lar: $e');
      return false;
    }
  }

  Future<bool> removeAnimalFromTemporaryHome(String animalId) async {
    try {
      await _supabase.from('shelter_animals').update({
        'temporary_home_id': null,
        'status': 'disponivel',
      }).eq('id', animalId);

      return true;
    } catch (e) {
      debugPrint('[ShelterService] Erro ao desocupar animal do lar: $e');
      return false;
    }
  }

  /// Candidatura de TUTOR COMUM como voluntário de Lar Temporário para uma ONG
  Future<bool> volunteerAsTemporaryHome({
    required String targetOngId,
    required String name,
    required String phone,
    String? email,
    String? city,
    String? neighborhood,
    required String housingType,
    required bool hasYard,
    required bool hasOtherPets,
    String? otherPetsDetails,
    required String allowedSpecies,
    required List<String> allowedSizes,
    required bool canAdministerMedication,
    required int maxCapacity,
    String? notes,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      final data = {
        'ong_id': targetOngId,
        if (user != null) 'volunteer_user_id': user.id,
        if (user != null) 'created_by': user.id,
        'name': name,
        'phone': phone,
        if (email != null) 'email': email,
        if (city != null) 'city': city,
        if (neighborhood != null) 'neighborhood': neighborhood,
        'housing_type': housingType,
        'has_yard': hasYard,
        'has_other_pets': hasOtherPets,
        if (otherPetsDetails != null) 'other_pets_details': otherPetsDetails,
        'allowed_species': allowedSpecies,
        'allowed_sizes': allowedSizes,
        'can_administer_medication': canAdministerMedication,
        'max_capacity': maxCapacity,
        'status': 'candidatura_pendente',
        'is_community_volunteer': true,
        if (notes != null) 'notes': notes,
      };

      await _supabase.from('shelter_temporary_homes').insert(data);
      return true;
    } catch (e) {
      debugPrint('[ShelterService] Erro ao enviar candidatura de voluntário: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // 🎪 EVENTOS, FEIRAS DE ADOÇÃO E BAZARES
  // ─────────────────────────────────────────────

  Future<List<ShelterEvent>> getEvents({
    String? ongId,
    bool onlyUpcoming = false,
    String? eventType,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      var query = _supabase.from('shelter_events').select();

      if (ongId != null && ongId.isNotEmpty) {
        query = query.eq('ong_id', ongId);
      }

      if (eventType != null && eventType != 'todos') {
        query = query.eq('event_type', eventType);
      }

      if (onlyUpcoming) {
        final nowIso = DateTime.now().toUtc().toIso8601String();
        query = query.gte('start_date', nowIso);
      }

      final response = await query.order('start_date', ascending: true);
      final eventsData = response as List;

      // Se usuário autenticado, busca eventos em que ele confirmou presença
      Set<String> userAttendingEventIds = {};
      if (user != null && eventsData.isNotEmpty) {
        try {
          final attendances = await _supabase
              .from('shelter_event_attendees')
              .select('event_id')
              .eq('user_id', user.id);
          userAttendingEventIds = (attendances as List)
              .map((a) => a['event_id'] as String)
              .toSet();
        } catch (_) {}
      }

      return eventsData.map((e) {
        final eventMap = e as Map<String, dynamic>;
        final eventId = eventMap['id'] as String;
        return ShelterEvent.fromMap(
          eventMap,
          isUserAttending: userAttendingEventIds.contains(eventId),
        );
      }).toList();
    } catch (e) {
      debugPrint('[ShelterService] Erro ao buscar eventos: $e');
      return [];
    }
  }

  Future<ShelterEvent?> createEvent(ShelterEvent event) async {
    try {
      final user = _supabase.auth.currentUser;
      final data = event.toMap();
      if (user != null) {
        data['created_by'] = user.id;
      }

      final response = await _supabase
          .from('shelter_events')
          .insert(data)
          .select()
          .single();

      return ShelterEvent.fromMap(response);
    } catch (e) {
      debugPrint('[ShelterService] Erro ao criar evento: $e');
      return null;
    }
  }

  Future<bool> updateEvent(ShelterEvent event) async {
    try {
      final data = event.toMap();
      data['updated_at'] = DateTime.now().toUtc().toIso8601String();

      await _supabase
          .from('shelter_events')
          .update(data)
          .eq('id', event.id);

      return true;
    } catch (e) {
      debugPrint('[ShelterService] Erro ao atualizar evento: $e');
      return false;
    }
  }

  Future<bool> deleteEvent(String eventId) async {
    try {
      await _supabase
          .from('shelter_events')
          .delete()
          .eq('id', eventId);
      return true;
    } catch (e) {
      debugPrint('[ShelterService] Erro ao excluir evento: $e');
      return false;
    }
  }

  Future<bool> toggleEventAttendance({
    required String eventId,
    required bool currentlyAttending,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      if (currentlyAttending) {
        // Cancelar presença
        await _supabase
            .from('shelter_event_attendees')
            .delete()
            .eq('event_id', eventId)
            .eq('user_id', user.id);
      } else {
        // Confirmar presença
        await _supabase.from('shelter_event_attendees').insert({
          'event_id': eventId,
          'user_id': user.id,
        });
      }

      return true;
    } catch (e) {
      debugPrint('[ShelterService] Erro ao alternar presença no evento: $e');
      return false;
    }
  }

  Future<String?> uploadEventBanner(XFile file, String ongId) async {
    try {
      final String fileName =
          'event_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = 'public/events/$ongId/$fileName';

      final bytes = await file.readAsBytes();
      await _supabase.storage.from('pet_avatars').uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      return _supabase.storage.from('pet_avatars').getPublicUrl(filePath);
    } catch (e) {
      debugPrint('[ShelterService] Erro no upload do banner do evento: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // 🚨 PATAS RESGATE & ALERTAS REGIONAIS
  // ─────────────────────────────────────────────

  Future<List<RescueAlert>> getRescueAlerts({
    String? status,
    String? urgency,
    String? ongId,
  }) async {
    try {
      var query = _supabase.from('rescue_alerts').select();

      if (status != null && status != 'todos') {
        query = query.eq('status', status);
      }

      if (urgency != null && urgency != 'todas') {
        query = query.eq('urgency', urgency);
      }

      if (ongId != null && ongId.isNotEmpty) {
        query = query.eq('assigned_ong_id', ongId);
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map((e) => RescueAlert.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[ShelterService] Erro ao buscar alertas de resgate: $e');
      return [];
    }
  }

  Future<RescueAlert?> createRescueAlert(
    RescueAlert alert, {
    List<XFile>? photoFiles,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      List<String> uploadedPhotos = List.from(alert.photos);

      if (photoFiles != null && photoFiles.isNotEmpty) {
        for (final file in photoFiles) {
          final photoUrl = await uploadRescuePhoto(file);
          if (photoUrl != null) {
            uploadedPhotos.add(photoUrl);
          }
        }
      }

      final data = alert.copyWith(photos: uploadedPhotos).toMap();
      if (user != null) {
        data['reporter_user_id'] = user.id;
      }

      final response = await _supabase
          .from('rescue_alerts')
          .insert(data)
          .select()
          .single();

      return RescueAlert.fromMap(response);
    } catch (e) {
      debugPrint('[ShelterService] Erro ao criar alerta de resgate: $e');
      return null;
    }
  }

  Future<bool> updateRescueAlert(RescueAlert alert) async {
    try {
      final data = alert.toMap();
      data['updated_at'] = DateTime.now().toUtc().toIso8601String();

      await _supabase
          .from('rescue_alerts')
          .update(data)
          .eq('id', alert.id);

      return true;
    } catch (e) {
      debugPrint('[ShelterService] Erro ao atualizar alerta: $e');
      return false;
    }
  }

  Future<bool> assignRescueAlertToOng({
    required String alertId,
    required String ongId,
  }) async {
    try {
      await _supabase.from('rescue_alerts').update({
        'status': 'em_atendimento',
        'assigned_ong_id': ongId,
        'assigned_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', alertId);

      return true;
    } catch (e) {
      debugPrint('[ShelterService] Erro ao assumir resgate: $e');
      return false;
    }
  }

  Future<bool> markRescueAlertCompleted({
    required String alertId,
    String? convertedAnimalId,
    String? notes,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'status': 'resgatado',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (convertedAnimalId != null) {
        updateData['converted_animal_id'] = convertedAnimalId;
      }
      if (notes != null) {
        updateData['notes'] = notes;
      }

      await _supabase
          .from('rescue_alerts')
          .update(updateData)
          .eq('id', alertId);

      return true;
    } catch (e) {
      debugPrint('[ShelterService] Erro ao concluir resgate: $e');
      return false;
    }
  }

  Future<bool> deleteRescueAlert(String alertId) async {
    try {
      await _supabase.from('rescue_alerts').delete().eq('id', alertId);
      return true;
    } catch (e) {
      debugPrint('[ShelterService] Erro ao excluir alerta: $e');
      return false;
    }
  }

  Future<String?> uploadRescuePhoto(XFile file) async {
    try {
      final String fileName =
          'rescue_${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final String filePath = 'public/rescues/$fileName';

      final bytes = await file.readAsBytes();
      await _supabase.storage.from('pet_avatars').uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      return _supabase.storage.from('pet_avatars').getPublicUrl(filePath);
    } catch (e) {
      debugPrint('[ShelterService] Erro no upload da foto de resgate: $e');
      return null;
    }
  }
}

