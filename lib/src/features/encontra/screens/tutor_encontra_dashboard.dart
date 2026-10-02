import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/features/encontra/screens/ativar_tag_screen.dart';
import 'package:patas_web_app/src/features/encontra/screens/historico_avistamentos_screen.dart';
import 'package:patas_web_app/src/features/encontra/screens/subscription_dashboard_page.dart';
import 'package:patas_web_app/src/features/encontra/services/encontra_service.dart';
import 'package:patas_web_app/src/providers/user_role_provider.dart';
import 'package:patas_web_app/src/constants/routes.dart';

import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/common_widgets/mobile_scroll_padding.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:patas_web_app/src/features/encontra/screens/subscription_plans_page.dart';
import 'package:patas_web_app/src/features/pets/models/pet_model.dart';
import 'package:patas_web_app/src/features/pets/services/pet_service.dart';
import 'package:patas_web_app/src/features/pets/active_pet_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TutorEncontraDashboard extends StatefulWidget {
  const TutorEncontraDashboard({super.key});

  @override
  State<TutorEncontraDashboard> createState() => _TutorEncontraDashboardState();
}

class _TutorEncontraDashboardState extends State<TutorEncontraDashboard> {
  final _encontraService = EncontraService();
  final _petService = PetService();

  List<Pet> _pets = [];
  List<Map<String, dynamic>> _tags = [];
  List<Map<String, dynamic>> _subscriptions = [];
  List<Map<String, dynamic>> _sightings = [];
  bool _isLoading = true;
  bool _isReloading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool showGlobalLoader = false}) async {
    if (showGlobalLoader || _pets.isEmpty) {
      setState(() => _isLoading = true);
    } else {
      setState(() => _isReloading = true);
    }
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final pets = await _petService.getPetsByUserId(user.id);
        final tags = await _encontraService.getMyTags();
        final subscriptions = await _encontraService.getMySubscriptions();
        final sightings = await _encontraService.getMySightings();
 
        debugPrint('🔔 [DEBUG DASHBOARD] Carregados dados do Supabase:');
        debugPrint('   - Pets: ${pets.map((p) => '${p.name} (id: ${p.id})').toList()}');
        debugPrint('   - Tags: ${tags.map((t) => 'id: ${t['id']}, pet_id: ${t['pet_id']}, status: ${t['status']}').toList()}');
        debugPrint('   - Subscriptions: ${subscriptions.map((s) => 'id: ${s['id']}, pet_id: ${s['pet_id']}, status: ${s['status']}').toList()}');
 
        if (mounted) {
          setState(() {
            _pets = pets;
            _tags = tags;
            _subscriptions = subscriptions;
            _sightings = sightings;
            _isLoading = false;
            _isReloading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isReloading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados no dashboard do tutor: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isReloading = false;
        });
      }
    }
  }

  void _goToAtivarTag({Pet? targetPet}) async {
    if (targetPet != null && mounted) {
      Provider.of<ActivePetProvider>(context, listen: false).setActivePet(targetPet);
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AtivarTagScreen(lockedPet: targetPet)),
    );
    // Recarrega após possível ativação de nova tag
    _loadData();
  }

  void _goToHistoricoAvistamentos() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HistoricoAvistamentosScreen()),
    );
  }

  void _confirmarDesvinculacao(Pet pet, String tagId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Desvincular Tag?',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Tem certeza de que deseja desvincular a tag inteligente do pet ${pet.name}?\n\n'
          '• A tag física atual deixará de funcionar para este pet.\n'
          '• A sua assinatura de proteção continuará ativa.\n'
          '• Você poderá vincular uma nova tag a este pet quando quiser.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop(); // Fecha dialog
              _executarDesvinculacao(pet.id, tagId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Desvincular',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _executarDesvinculacao(String petId, String tagId) async {
    setState(() => _isLoading = true);
    
    final result = await _encontraService.deactivateTag(tagId: tagId, petId: petId);
    
    if (mounted) {
      setState(() => _isLoading = false);
      
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Tag desvinculada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData(); // Recarrega os dados do dashboard
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erro ao desvincular a tag.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    Widget mainContent = Scaffold(
      backgroundColor: isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
      appBar: PatasEssencialAppBar(
        title: 'Patas Encontra',
        subtitle: 'Proteção, medalha QR e geolocalização',
        showBackButton: true,
        leadingIcon: const Icon(
          Icons.radar_rounded,
          color: AppColors.patasColor,
          size: 22,
        ),
        actions: [
          if (Provider.of<UserRoleProvider>(context, listen: true).role == UserRole.admin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.patasColor),
              tooltip: 'Gerador de Lotes QR',
              onPressed: () {
                Navigator.pushNamed(context, NamedRoute.adminQrGenerator);
              },
            ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: AppColors.patasColor),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: context.isDesktop ? 24.0 : 16.0,
                vertical: 20.0,
              ),
              child: isDesktop
                  ? _buildDesktopLayout(isDark)
                  : _buildMobileLayout(isDark),
            ),
          ),
        ),
      ),
    );

    return mainContent;
  }


  Widget _buildMobileLayout(bool isDark) {
    if (_isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildIntroBanner(isDark),
        const SizedBox(height: 24),
        _buildSectionTitle(isDark, 'Meus Pets e Tags'),
        const SizedBox(height: 12),
        if (_pets.isEmpty)
          _buildEmptyPetsState(isDark)
        else
          ..._pets.map((pet) => _buildPetItemCard(isDark, pet)),
        if (!context.isDesktop) const MobileScrollPadding(),
      ],
    );
  }

  Widget _buildDesktopLayout(bool isDark) {
    if (_isLoading) {
      return const SizedBox(
        height: 400,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Coluna da Esquerda: Controle de Tags
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildIntroBanner(isDark),
              const SizedBox(height: 24),
              _buildSectionTitle(isDark, 'Meus Pets e Tags'),
              const SizedBox(height: 12),
              if (_pets.isEmpty)
                _buildEmptyPetsState(isDark)
              else
                ..._pets.map((pet) => _buildPetItemCard(isDark, pet)),
            ],
          ),
        ),

        const SizedBox(width: 32),

        // Coluna da Direita: Status de Segurança Estático
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle(isDark, 'Status da Busca'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_outlined, color: Colors.green, size: 40),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Monitoramento Ativo',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : AppColors.darkBG,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Suas tags inteligentes estão monitorando seus pets de forma passiva. Ative o "Modo Perdido" no card do animal se ele se perder.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIntroBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.patasColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.radar, color: AppColors.patasColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Como funciona?',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.darkBG,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ative o "Modo Perdido" caso seu pet fuja. Quem escanear a tag enviará a localização dele de volta para você.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(bool isDark, String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Fredoka',
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white70 : AppColors.darkBG,
      ),
    );
  }

  Widget _buildEmptyPetsState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.pets_rounded, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            'Nenhum pet cadastrado',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Você precisa cadastrar seu cão ou gato no menu de perfil para poder ativá-lo nas tags inteligentes.',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPetItemCard(bool isDark, Pet pet) {
    // 1. Busca dados da tag e assinatura do pet
    final tag = _tags.firstWhere(
      (t) => t['pet_id'] == pet.id,
      orElse: () => <String, dynamic>{},
    );
    final hasTag = tag.isNotEmpty;

    final subscription = _subscriptions.firstWhere(
      (s) => s['pet_id'] == pet.id,
      orElse: () => <String, dynamic>{},
    );
    final hasSubscription = subscription.isNotEmpty;
    final hasActiveProtection = hasTag && hasSubscription && ['trial', 'active', 'grace_period'].contains(subscription['status']);
    
    debugPrint('🐾 [DEBUG CARD] Processando card do pet: ${pet.name} (id: ${pet.id})');
    debugPrint('   - Tag vinculada? $hasTag (is_lost: ${tag['is_lost']})');
    debugPrint('   - Assinatura vinculada? $hasSubscription (status: ${subscription['status']}, ativa: $hasActiveProtection)');

    // O modo perdido só é considerado ativo visualmente se o pet tiver cobertura ativa e o flag no banco for verdadeiro
    final bool isLost = hasActiveProtection && tag['is_lost'] == true;

    // 2. Definir o status da Tag
    String tagText = 'Sem Tag QR';
    Color tagBgColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100;
    Color tagTextColor = isDark ? Colors.white60 : Colors.grey.shade600;
    IconData tagIcon = Icons.qr_code_2_outlined;

    if (hasTag) {
      final status = tag['status'] ?? 'active';
      if (status == 'active') {
        tagText = 'Tag Ativa';
        tagBgColor = Colors.green.withValues(alpha: 0.12);
        tagTextColor = Colors.green;
        tagIcon = Icons.verified_outlined;
      } else {
        tagText = 'Tag Suspensa';
        tagBgColor = Colors.red.withValues(alpha: 0.12);
        tagTextColor = Colors.red;
        tagIcon = Icons.block_outlined;
      }
    }

    // 3. Definir o status da Proteção/Assinatura
    String subText = 'Sem Cobertura';
    Color subBgColor = Colors.red.withValues(alpha: 0.12);
    Color subTextColor = Colors.red;
    IconData subIcon = Icons.shield_outlined;

    if (hasSubscription) {
      final status = subscription['status'] ?? 'inactive';
      if (status == 'trial') {
        final trialEndsStr = subscription['trial_ends_at'];
        final trialEnds = trialEndsStr != null ? DateTime.tryParse(trialEndsStr) : null;
        final daysLeft = trialEnds != null ? trialEnds.difference(DateTime.now()).inDays : 0;
        subText = 'Testes ($daysLeft dias)';
        subBgColor = Colors.orange.withValues(alpha: 0.12);
        subTextColor = Colors.orange;
        subIcon = Icons.timer_outlined;
      } else if (status == 'active') {
        subText = 'Proteção Ativa';
        subBgColor = AppColors.patasColor.withValues(alpha: 0.12);
        subTextColor = AppColors.patasColor;
        subIcon = Icons.shield_rounded;
      } else if (status == 'grace_period') {
        final graceEndsStr = subscription['grace_period_ends_at'];
        final graceEnds = graceEndsStr != null ? DateTime.tryParse(graceEndsStr) : null;
        final daysLeft = graceEnds != null ? graceEnds.difference(DateTime.now()).inDays : 0;
        subText = 'Aguardando Pix ($daysLeft dias)';
        subBgColor = Colors.orange.withValues(alpha: 0.12);
        subTextColor = Colors.orange;
        subIcon = Icons.warning_amber_rounded;
      } else if (status == 'past_due' || status == 'inactive') {
        subText = 'Proteção Suspensa';
        subBgColor = Colors.red.withValues(alpha: 0.12);
        subTextColor = Colors.red;
        subIcon = Icons.error_outline_rounded;
      } else if (status == 'canceled') {
        subText = 'Proteção Cancelada';
        subBgColor = Colors.red.withValues(alpha: 0.12);
        subTextColor = Colors.red;
        subIcon = Icons.cancel_outlined;
      }
    }


    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.transparent,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isLost ? Colors.redAccent : (isDark ? Colors.white10 : Colors.grey.shade200),
              width: isLost ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Informações Principais do Pet
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Avatar do Pet
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: pet.photoUrl != null && pet.photoUrl!.isNotEmpty
                          ? NetworkImage(pet.photoUrl!)
                          : null,
                      backgroundColor: AppColors.patasColor.withValues(alpha: 0.1),
                      child: pet.photoUrl == null || pet.photoUrl!.isEmpty
                          ? const Icon(Icons.pets, color: AppColors.patasColor, size: 24)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    // Nome, raça e badges
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pet.name,
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.darkBG,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Badges em coluna (Tag em cima, Assinatura embaixo)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Badge da Tag
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: tagBgColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(tagIcon, size: 12, color: tagTextColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      tagText,
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: tagTextColor),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Badge da Assinatura
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: subBgColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(subIcon, size: 12, color: subTextColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      subText,
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: subTextColor),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Coluna direita: Modo Perdido ou Carregamento Silencioso em background
                    if (_isReloading)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.patasColor),
                          ),
                        ),
                      )
                    else if (hasTag && hasActiveProtection)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Modo Perdido',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isLost ? Colors.redAccent : (isDark ? Colors.white30 : Colors.black38),
                            ),
                          ),
                          Switch(
                            value: isLost,
                            activeThumbColor: Colors.redAccent,
                            onChanged: (val) async {
                              final success = await _encontraService.toggleLostMode(
                                tagId: tag['id'] as String,
                                isLost: val,
                              );
                              if (success) {
                                setState(() => tag['is_lost'] = val);
                                _notifyModeChange(pet.name, val);
                                _loadData();
                              }
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Divider entre os badges e os botões de ação
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                child: Divider(
                  thickness: 3,
                  height: 3,
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                ),
              ),

              // Botões de Ação na parte inferior do Card (evita overflow lateral de botões grandes no topo)
              if (!hasActiveProtection)
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!hasTag) ...[
                        // 1. Botão de Vincular Tag (Ativo)
                        ElevatedButton.icon(
                          onPressed: () => _goToAtivarTag(targetPet: pet),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.withValues(alpha: 0.12),
                            foregroundColor: Colors.orange,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.qr_code_scanner, size: 16),
                          label: const Text(
                            'Vincular Tag Inteligente',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      // 2. Botão de Ativar Proteção do Pet (Desativado se !hasTag)
                      ElevatedButton.icon(
                        onPressed: hasTag
                            ? () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => SubscriptionPlansPage(petId: pet.id),
                                  ),
                                ).then((_) => _loadData());
                              }
                            : null, // Desativado se não tiver tag!
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasTag ? AppColors.patasColor : Colors.grey.shade300,
                          foregroundColor: hasTag ? Colors.white : Colors.grey.shade500,
                          disabledBackgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                          disabledForegroundColor: isDark ? Colors.white30 : Colors.grey.shade400,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.shield_outlined, size: 16),
                        label: const Text(
                          'Ativar Proteção do Pet',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (hasTag) ...[
                        const SizedBox(height: 8),
                        // Botão discreto para desvincular caso queira
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _confirmarDesvinculacao(pet, tag['id'] as String),
                            icon: const Icon(Icons.link_off, size: 13, color: Colors.redAccent),
                            label: const Text(
                              'Desvincular Tag',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.redAccent),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              else
                // Botões de Ação para pets com tag e assinatura ativa
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Coluna da esquerda: botões com a mesma largura
                      IntrinsicWidth(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Gerenciar Assinatura (topo)
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => SubscriptionDashboardPage(petId: pet.id),
                                  ),
                                ).then((_) => _loadData());
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark ? Colors.white70 : Colors.black87,
                                side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: const Icon(Icons.receipt_long_outlined, size: 13),
                              label: const Text(
                                'Gerenciar Assinatura',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // 2. Visualizar no Mapa (embaixo)
                            ElevatedButton.icon(
                              onPressed: _goToHistoricoAvistamentos,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.withValues(alpha: 0.12),
                                foregroundColor: Colors.orange,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: const Icon(Icons.map_outlined, size: 13),
                              label: const Text(
                                'Visualizar no Mapa',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // 3. Desvincular Tag — alinhado à direita e na base (ao lado de Visualizar no Mapa)
                      Tooltip(
                        message: isLost ? 'Desative o Modo Perdido antes de desvincular' : '',
                        child: TextButton.icon(
                          onPressed: isLost ? null : () => _confirmarDesvinculacao(pet, tag['id'] as String),
                          icon: Icon(
                            Icons.link_off,
                            size: 13,
                            color: isLost ? Colors.grey.shade400 : Colors.redAccent,
                          ),
                          label: Text(
                            'Desvincular Tag',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isLost ? Colors.grey.shade400 : Colors.redAccent,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Seção de Expansão de Avistamentos (mostrada apenas em Modo Perdido)
              if (hasTag && isLost) ...[
                const Divider(height: 1, thickness: 1),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Avistamentos Recentes',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : AppColors.darkBG,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Lista de avistamentos deste pet
                      _buildPetSightingsSection(isDark, tag['id']),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPetSightingsSection(bool isDark, String tagId) {
    final petSightings = _sightings.where((s) => s['tag_id'] == tagId).toList();
    if (petSightings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Nenhum avistamento registrado para este pet ainda. As tags inteligentes estão aguardando leitura.',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white38 : Colors.black38,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: petSightings.take(3).map((s) {
        final address = s['address'] as String?;
        final lat = s['latitude'] as num?;
        final lng = s['longitude'] as num?;
        final locationStr = address != null && address.isNotEmpty
            ? address
            : (lat != null && lng != null
                ? 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}'
                : 'Localização desconhecida');
        final seenAt = s['seen_at'] as String?;
        final message = s['message'] as String?;
        final finderName = s['finder_name'] as String?;

        String timeAgo = '';
        String timeStr = '';
        if (seenAt != null) {
          final seen = DateTime.tryParse(seenAt);
          if (seen != null) {
            final diff = DateTime.now().difference(seen);
            if (diff.inMinutes < 60) {
              timeAgo = 'Há ${diff.inMinutes}min';
            } else if (diff.inHours < 24) {
              timeAgo = 'Há ${diff.inHours}h';
            } else {
              timeAgo = 'Há ${diff.inDays}d';
            }

            final hour = seen.hour.toString().padLeft(2, '0');
            final minute = seen.minute.toString().padLeft(2, '0');
            final day = seen.day.toString().padLeft(2, '0');
            final month = seen.month.toString().padLeft(2, '0');
            timeStr = '$day/$month às $hour:$minute';
          }
        }

        final displayMessage = message != null && message.isNotEmpty
            ? '"$message"'
            : '"Sem comentário do avistador"';

        final displayFinder = finderName != null && finderName.isNotEmpty
            ? finderName
            : 'Avistador desconhecido';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF3A1C1C) : const Color(0xFFFFECEC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.red.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.my_location, color: Colors.redAccent, size: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locationStr,
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayMessage,
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Por: $displayFinder · $timeStr ($timeAgo)',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white30 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }


  void _notifyModeChange(String petName, bool isLost) {
    final snackBar = SnackBar(
      content: Text(
        isLost
            ? '🚨 Alerta: Modo Perdido ATIVADO para $petName!'
            : '✅ Modo Perdido desativado para $petName.',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: isLost ? Colors.redAccent : Colors.green,
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sobre o Patas Encontra'),
        content: const Text(
          'As tags físicas do Patas possuem um QR Code exclusivo. Quando alguém escaneia a tag, o sistema pode enviar a geolocalização do localizador diretamente para você caso seu pet esteja marcado no "Modo Perdido".\n\nQualquer dúvida, entre em contato com o suporte do app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}

// ─── Botão Animado com Gradiente Pulsante (padrão Patas Rewards) ─────────────

class _AnimatedMapButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _AnimatedMapButton({required this.onPressed});

  @override
  State<_AnimatedMapButton> createState() => _AnimatedMapButtonState();
}

class _AnimatedMapButtonState extends State<_AnimatedMapButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _colorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final color1 = Color.lerp(
          const Color(0xFFE53935),
          AppColors.patasColor,
          _colorAnimation.value,
        )!;
        final color2 = Color.lerp(
          const Color(0xFFB71C1C),
          const Color(0xFFFF8A00),
          _colorAnimation.value,
        )!;

        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [color1, color2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: color1.withValues(alpha: 0.3 * _scaleAnimation.value),
                  blurRadius: 12 * _scaleAnimation.value,
                  spreadRadius: 2 * _scaleAnimation.value,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: widget.onPressed,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map_outlined, size: 20, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        'VISUALIZAR TODOS NO MAPA',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Colors.white,
                          fontFamily: 'Fredoka',
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white70),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
