import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import '../../../../app.dart';
import '../../../common_widgets/mobile_scroll_padding.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/responsive_layout.dart';
import '../../pets/active_pet_provider.dart';
import '../../pets/models/pet_model.dart';
import '../../pets/services/pet_service.dart';
import '../services/patas_love_service.dart';
import 'love_chat_screen.dart';

class PatasLoveMainScreen extends StatefulWidget {
  const PatasLoveMainScreen({super.key});

  @override
  State<PatasLoveMainScreen> createState() => _PatasLoveMainScreenState();
}

class _PatasLoveMainScreenState extends State<PatasLoveMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PatasLoveService _loveService = PatasLoveService();

  List<Pet> _compatiblePets = [];
  List<Map<String, dynamic>> _chats = [];
  bool _isLoadingPets = true;
  bool _isLoadingChats = true;

  String? _loadedPetId;
  bool? _loadedIsLoveActive;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadData();
      }
    });
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final activePet = Provider.of<ActivePetProvider>(context).activePet;
    if (activePet?.id != _loadedPetId || activePet?.isLoveActive != _loadedIsLoveActive) {
      _loadedPetId = activePet?.id;
      _loadedIsLoveActive = activePet?.isLoveActive;
      _loadData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final activePet =
        Provider.of<ActivePetProvider>(context, listen: false).activePet;
    if (activePet == null) return;

    setState(() {
      _isLoadingPets = true;
      _isLoadingChats = true;
    });

    final pets = await _loveService.getCompatiblePets(activePet: activePet);
    final chats = await _loveService.getChatsForPet(activePet.id);

    if (mounted) {
      setState(() {
        _compatiblePets = pets;
        _chats = chats;
        _isLoadingPets = false;
        _isLoadingChats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final activePet = Provider.of<ActivePetProvider>(context).activePet;
    final bgColor =
        thmode.darkMode ? AppColors.bodygray : const Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: PatasEssencialAppBar(
        title: 'Patas Love',
        subtitle: 'Conexões e encontros para seu pet',
        leadingIcon: const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 22),
        bottomHeight: 52.0,
        bottomWidget: Center(
          child: SizedBox(
            width: 450,
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: thmode.darkMode
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFE8EDF2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.patasColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 13,
                ),
                labelColor: Colors.white,
                unselectedLabelColor:
                    thmode.darkMode ? Colors.white54 : Colors.black54,
                tabs: const [
                  Tab(text: 'Feed de Encontros'),
                  Tab(text: 'Mensagens'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeedTab(context, activePet, thmode),
          _buildMessagesTab(context, activePet, thmode),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ABA 1 — FEED DE PETS COMPATÍVEIS
  // ─────────────────────────────────────────────
  Widget _buildFeedTab(
      BuildContext context, Pet? activePet, DarkMode thmode) {
    if (_isLoadingPets) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.pinkAccent),
      );
    }

    if (_compatiblePets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.pink.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_border_rounded,
                  size: 60,
                  color: Colors.pinkAccent,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Nenhum parceiro encontrado no momento',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Assim que novos tutores ativarem o Patas Love para pets da mesma espécie de ${activePet?.name ?? 'seu pet'}, eles aparecerão aqui!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: thmode.darkMode ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MobileScrollPadding.bottomInset(context),
      ),
      itemCount: _compatiblePets.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildActivePetLoveToggleBanner(context, activePet, thmode);
        }
        if (index == _compatiblePets.length + 1) {
          return const MobileScrollPadding();
        }

        final targetPet = _compatiblePets[index - 1];
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: _LovePetCard(
              pet: targetPet,
              activePet: activePet,
              onMessageTap: () => _openChat(activePet, targetPet),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivePetLoveToggleBanner(
      BuildContext context, Pet? activePet, DarkMode thmode) {
    if (activePet == null) return const SizedBox.shrink();

    final isDark = thmode.darkMode;
    final isLoveActive = activePet.isLoveActive;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isLoveActive
                ? Colors.pink.withValues(alpha: isDark ? 0.18 : 0.08)
                : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLoveActive
                  ? Colors.pinkAccent.withValues(alpha: 0.4)
                  : (isDark ? Colors.white24 : Colors.black12),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.pinkAccent,
                backgroundImage: activePet.photoUrl != null && activePet.photoUrl!.isNotEmpty
                    ? NetworkImage(activePet.photoUrl!)
                    : null,
                child: activePet.photoUrl == null || activePet.photoUrl!.isEmpty
                    ? const Icon(Icons.pets, color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patas Love: ${activePet.name}',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.darkBG,
                      ),
                    ),
                    Text(
                      isLoveActive
                          ? 'Perfil ativado para novos encontros 💖'
                          : 'Perfil desativado para encontros',
                      style: TextStyle(
                        fontSize: 11,
                        color: isLoveActive
                            ? Colors.pinkAccent
                            : (isDark ? Colors.white60 : Colors.black54),
                        fontWeight: isLoveActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isLoveActive,
                activeThumbColor: Colors.pinkAccent,
                onChanged: (val) async {
                  final updatedPet = Pet(
                    id: activePet.id,
                    userId: activePet.userId,
                    name: activePet.name,
                    species: activePet.species,
                    breed: activePet.breed,
                    birthDate: activePet.birthDate,
                    photoUrl: activePet.photoUrl,
                    createdAt: activePet.createdAt,
                    gender: activePet.gender,
                    size: activePet.size,
                    color: activePet.color,
                    birthPlace: activePet.birthPlace,
                    currentCity: activePet.currentCity,
                    coverUrl: activePet.coverUrl,
                    bloodType: activePet.bloodType,
                    weight: activePet.weight,
                    isLoveActive: val,
                  );

                  await PetService().updatePet(updatedPet);
                  if (context.mounted) {
                    Provider.of<ActivePetProvider>(context, listen: false)
                        .setActivePet(updatedPet);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ABA 2 — CENTRAL DE MENSAGENS / CHATS
  // ─────────────────────────────────────────────
  Widget _buildMessagesTab(
      BuildContext context, Pet? activePet, DarkMode thmode) {
    if (_isLoadingChats) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.pinkAccent),
      );
    }

    if (_chats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mark_chat_read_outlined,
                size: 60,
                color: thmode.darkMode ? Colors.white38 : Colors.black26,
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhuma conversa iniciada',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Navegue pela aba Feed e clique em "Enviar Mensagem" no perfil de um pet para iniciar uma conversa.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: thmode.darkMode ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.pinkAccent,
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MobileScrollPadding.bottomInset(context),
        ),
        itemCount: _chats.length + 1,
        itemBuilder: (context, index) {
          if (index == _chats.length) {
            return const MobileScrollPadding();
          }

          final chat = _chats[index];
          final petA = chat['pet_a'];
          final petB = chat['pet_b'];

          // Identifica qual dos pets do chat é o parceiro com fallback defensivo
          dynamic partnerMap;
          if (petA != null && petA['id'] != activePet?.id) {
            partnerMap = petA;
          } else if (petB != null && petB['id'] != activePet?.id) {
            partnerMap = petB;
          } else {
            partnerMap = petA ?? petB;
          }

          final partnerId = partnerMap?['id'] ??
              (chat['pet_a_id'] != activePet?.id ? chat['pet_a_id'] : chat['pet_b_id']) ??
              '';

          final partnerPet = Pet(
            id: partnerId,
            userId: partnerMap?['user_id'] ?? '',
            name: partnerMap?['name'] ?? 'Amigo Pet',
            species: partnerMap?['species'] ?? 'Pet',
            breed: partnerMap?['breed'],
            photoUrl: partnerMap?['photo_url'],
            createdAt: DateTime.now(),
          );

          return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: thmode.darkMode ? AppColors.darkBG : Colors.white,
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  radius: 26,
                  backgroundImage: partnerPet.photoUrl != null
                      ? NetworkImage(partnerPet.photoUrl!)
                      : null,
                  child: partnerPet.photoUrl == null
                      ? const Icon(Icons.pets, color: Colors.pinkAccent)
                      : null,
                ),
                title: Text(
                  partnerPet.name,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                  ),
                ),
                subtitle: Text(
                  partnerPet.breed ?? partnerPet.species,
                  style: TextStyle(
                    fontSize: 12,
                    color: thmode.darkMode ? Colors.white60 : Colors.black54,
                  ),
                ),
                trailing: _buildChatStatusBadge(chat['status'] as String?),
                onTap: () => _openChat(activePet, partnerPet, chatId: chat['id']),
              ),
            ),
          ),
        );
      },
    ),
  );
}

  Widget _buildChatStatusBadge(String? status) {
    if (status == 'met_in_person') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6FA3), Color(0xFFFF4081)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_rounded, color: Colors.white, size: 12),
            SizedBox(width: 4),
            Text(
              'Encontro!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    if (status == 'pending_meet') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.amber.shade100,
          border: Border.all(color: Colors.amber.shade400),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_top_rounded,
                color: Colors.amber, size: 12),
            SizedBox(width: 4),
            Text(
              'Pendente',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    return const Icon(Icons.chevron_right_rounded, color: Colors.pinkAccent);
  }

  Future<void> _openChat(Pet? activePet, Pet targetPet,
      {String? chatId}) async {
    if (activePet == null) return;

    final targetChatId = chatId ??
        await _loveService.getOrCreateChat(
          petAId: activePet.id,
          petBId: targetPet.id,
        );

    if (targetChatId == null || !mounted) return;

    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => LoveChatScreen(
          chatId: targetChatId,
          activePet: activePet,
          targetPet: targetPet,
        ),
      ),
    );

    // Recarrega lista ao voltar
    _loadData();
  }
}

// ─────────────────────────────────────────────
// CARD DE PET NO FEED
// ─────────────────────────────────────────────
class _LovePetCard extends StatefulWidget {
  final Pet pet;
  final Pet? activePet;
  final VoidCallback onMessageTap;

  const _LovePetCard({
    required this.pet,
    required this.activePet,
    required this.onMessageTap,
  });

  @override
  State<_LovePetCard> createState() => _LovePetCardState();
}

class _LovePetCardState extends State<_LovePetCard> {
  bool _isFollowing = false;
  bool _hasExpressedInterest = false;

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final cardColor =
        thmode.darkMode ? AppColors.darkBG : Colors.white;
    final imageHeight = context.isWide ? 280.0 : 230.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: thmode.darkMode
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: thmode.darkMode ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto do Pet com Borda Gradiente
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            child: widget.pet.photoUrl != null
                ? Stack(
                    children: [
                      Image.network(
                        widget.pet.photoUrl!,
                        height: imageHeight,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.35),
                              ],
                              stops: const [0.7, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(
                    height: imageHeight,
                    color: Colors.pink.withValues(alpha: 0.1),
                    child: const Center(
                      child: Icon(Icons.pets,
                          size: 60, color: Colors.pinkAccent),
                    ),
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome e Raça
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.pet.name,
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color:
                              thmode.darkMode ? Colors.white : AppColors.darkBG,
                        ),
                      ),
                    ),
                    if (widget.pet.gender != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.pet.gender?.toLowerCase() == 'macho'
                              ? Colors.blue.withValues(alpha: 0.15)
                              : Colors.pink.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.pet.gender!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: widget.pet.gender?.toLowerCase() == 'macho'
                                ? Colors.blue
                                : Colors.pinkAccent,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.pet.breed ?? widget.pet.species} ${widget.pet.currentCity != null ? "• ${widget.pet.currentCity}" : ""}',
                  style: TextStyle(
                    fontSize: 13,
                    color: thmode.darkMode ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),

                // Selos de Vacina & Pedigree
                Row(
                  children: [
                    _buildBadge(
                      icon: Icons.verified_user_rounded,
                      label: 'Vacinação OK',
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _buildBadge(
                      icon: Icons.workspace_premium_rounded,
                      label: 'Pedigree',
                      color: Colors.amber.shade700,
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // 3 Botões de Ação Principais
                Row(
                  children: [
                    // Botão 1: Seguir
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _isFollowing
                              ? Colors.grey
                              : AppColors.patasColor,
                          side: BorderSide(
                              color: _isFollowing
                                  ? Colors.grey
                                  : AppColors.patasColor),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          setState(() {
                            _isFollowing = !_isFollowing;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_isFollowing
                                  ? 'Você começou a seguir ${widget.pet.name}!'
                                  : 'Você deixou de seguir ${widget.pet.name}.'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: Icon(_isFollowing
                            ? Icons.check
                            : Icons.person_add_rounded),
                        label: Text(_isFollowing ? 'Seguindo' : 'Seguir'),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Botão 2: Demonstrar Interesse (Push Notification)
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: _hasExpressedInterest
                            ? Colors.pinkAccent
                            : Colors.pink.withValues(alpha: 0.15),
                        foregroundColor: _hasExpressedInterest
                            ? Colors.white
                            : Colors.pinkAccent,
                      ),
                      icon: Icon(_hasExpressedInterest
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded),
                      onPressed: () {
                        setState(() {
                          _hasExpressedInterest = !_hasExpressedInterest;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.pinkAccent,
                            content: Text(
                              _hasExpressedInterest
                                  ? 'Notificação enviada ao tutor de ${widget.pet.name}!'
                                  : 'Interesse removido.',
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),

                    // Botão 3: Enviar Mensagem
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: widget.onMessageTap,
                      icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                      label: const Text('Conversar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(
      {required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
