import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:patas_web_app/src/features/pets/active_pet_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:patas_web_app/src/features/home/rewards/services/gamification_service.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import '../../../../app.dart';
import 'package:patas_web_app/src/localization/localizations_ext.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoading = true;
  int _userRank = 0;
  int _userPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final service = GamificationService();

      final results = await Future.wait([
        service.getLeaderboard(),
        user != null
            ? service.getUserStats(user.id)
            : Future.value({'points': 0, 'rank': 0}),
      ]);

      if (mounted) {
        setState(() {
          _leaderboard = results[0] as List<Map<String, dynamic>>;
          final userStats = results[1] as Map<String, dynamic>;
          _userPoints = userStats['points'] ?? 0;
          _userRank = userStats['rank'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('LeaderboardPage: Erro ao carregar dados: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileContent(context),
      desktop: _buildDesktopOverlay(context),
    );
  }

  Widget _buildDesktopOverlay(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Semantics(
              button: true,
              label: context.tr('leaderboard.close_tooltip'),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.black.withValues(alpha: 0.25)),
                ),
              ),
            ),
          ),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 500,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                child: _buildMobileContent(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileContent(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final petProvider = Provider.of<ActivePetProvider>(context);
    final activePet = petProvider.activePet;

    final bgColor = thmode.darkMode
        ? AppColors.bodygray
        : const Color(0xffF5F5F5);
    final textColor = thmode.darkMode ? Colors.white : AppColors.darkBG;
    final cardColor = thmode.darkMode ? const Color(0xff1a1a1a) : Colors.white;

    // Separação dos líderes (Top 3) e o restante do ranking (4-15)
    final top3 = _leaderboard.take(3).toList();
    final remainingList = _leaderboard.skip(3).toList();

    // Organização das posições do pódio: [2º colocado, 1º colocado, 3º colocado] para a renderização visual clássica
    Map<String, dynamic>? firstPlace;
    Map<String, dynamic>? secondPlace;
    Map<String, dynamic>? thirdPlace;

    for (var item in top3) {
      final rank = int.tryParse(item['rank'].toString()) ?? 0;
      if (rank == 1) firstPlace = item;
      if (rank == 2) secondPlace = item;
      if (rank == 3) thirdPlace = item;
    }

    // Se o pódio de 1º lugar estiver vazio e o usuário ativo tiver pontos, coloca-o em 1º lugar para fins visuais e de teste
    if (firstPlace == null && _userPoints > 0) {
      firstPlace = {
        'user_id': Supabase.instance.client.auth.currentUser?.id,
        'pet_name': activePet?.name ?? context.tr('rewards.my_pet'),
        'pet_photo_url': activePet?.photoUrl,
        'total_points': _userPoints,
        'rank': 1,
      };
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: PatasEssencialAppBar(
        title: context.tr('leaderboard.title'),
        subtitle: context.tr('leaderboard.subtitle'),
        leadingIcon: Icon(
          Icons.military_tech_rounded,
          color: Colors.amber,
          size: 22,
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.patasColor),
            )
          : Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          // 1. Pódio do Top 3
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                24,
                                16,
                                16,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  // 2º Colocado
                                  Expanded(
                                    child: _buildPodiumItem(
                                      place: 2,
                                      data: secondPlace,
                                      cardColor: cardColor,
                                      textColor: textColor,
                                      avatarRadius: 30,
                                      height: 130,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // 1º Colocado (Maior destaque)
                                  Expanded(
                                    child: _buildPodiumItem(
                                      place: 1,
                                      data: firstPlace,
                                      cardColor: cardColor,
                                      textColor: textColor,
                                      avatarRadius: 40,
                                      height: 160,
                                      hasCrown: true,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // 3º Colocado
                                  Expanded(
                                    child: _buildPodiumItem(
                                      place: 3,
                                      data: thirdPlace,
                                      cardColor: cardColor,
                                      textColor: textColor,
                                      avatarRadius: 28,
                                      height: 115,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 2. Lista Geral (posições 4 a 15)
                          if (remainingList.isNotEmpty)
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final item = remainingList[index];
                                  return _buildRankRow(
                                    item: item,
                                    cardColor: cardColor,
                                    textColor: textColor,
                                  );
                                }, childCount: remainingList.length),
                              ),
                            )
                          else
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                  vertical: 32.0,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.patasColor.withValues(
                                        alpha: 0.15,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        '🚀',
                                        style: TextStyle(fontSize: 32),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'O ranking está apenas começando!',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: textColor,
                                          fontFamily: 'Fredoka',
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Ainda há espaço de sobra para alcançar o pódio! Convide seus amigos com o seu código de convite exclusivo e garanta +500 pontos por indicação para disparar na frente!',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: textColor.withValues(
                                            alpha: 0.6,
                                          ),
                                          height: 1.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          const SliverToBoxAdapter(
                            child: SizedBox(
                              height: 110,
                            ), // Espaço para não tampar pelo card fixo inferior
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // 3. Card Sticky Inferior (Posição do Usuário Logado)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildUserStickyCard(
                    activePet: activePet,
                    cardColor: cardColor,
                    textColor: textColor,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPodiumItem({
    required int place,
    required Map<String, dynamic>? data,
    required Color cardColor,
    required Color textColor,
    required double avatarRadius,
    required double height,
    bool hasCrown = false,
  }) {
    final user = Supabase.instance.client.auth.currentUser;
    final petProvider = Provider.of<ActivePetProvider>(context, listen: false);
    final activePet = petProvider.activePet;

    String petName = data?['pet_name'] ?? context.tr('leaderboard.no_data');
    String? photoUrl = data?['pet_photo_url'] as String?;
    final totalPoints = data != null
        ? (int.tryParse(data['total_points'].toString()) ?? 0)
        : 0;

    // Resiliência local: se o item for do usuário logado e os dados da view estiverem nulos/vazios, complementa com o pet ativo
    if (data != null &&
        user != null &&
        data['user_id'] == user.id &&
        activePet != null) {
      if (petName == 'Sem dados' || petName == context.tr('leaderboard.no_data') || petName.trim().isEmpty) {
        petName = activePet.name;
      }
      if (photoUrl == null || photoUrl.trim().isEmpty) {
        photoUrl = activePet.photoUrl;
      }
    }

    Color placeColor;
    String medalEmoji;
    switch (place) {
      case 1:
        placeColor = const Color(0xffFFD700); // Dourado
        medalEmoji = '🥇';
        break;
      case 2:
        placeColor = const Color(0xffC0C0C0); // Prata
        medalEmoji = '🥈';
        break;
      case 3:
        placeColor = const Color(0xffCD7F32); // Bronze
        medalEmoji = '🥉';
        break;
      default:
        placeColor = Colors.grey;
        medalEmoji = '🎖️';
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            if (hasCrown)
              Positioned(
                top: -30,
                child: RotationTransition(
                  turns: const AlwaysStoppedAnimation(12 / 360),
                  child: const Text('👑', style: TextStyle(fontSize: 32)),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: placeColor, width: 3.5),
                boxShadow: [
                  BoxShadow(
                    color: placeColor.withValues(alpha: 0.25),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: cardColor,
                backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl == null || photoUrl.isEmpty
                    ? Icon(Icons.pets, size: avatarRadius, color: Colors.grey)
                    : null,
              ),
            ),
            Positioned(
              bottom: -10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: placeColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4),
                  ],
                ),
                child: Text(
                  medalEmoji,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(
              color: placeColor.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: placeColor.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 3,
                width: 32,
                decoration: BoxDecoration(
                  color: placeColor,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                petName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: place == 1 ? 14 : 12,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '$totalPoints pts',
                style: TextStyle(
                  color: AppColors.patasColor,
                  fontWeight: FontWeight.bold,
                  fontSize: place == 1 ? 13 : 11,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: placeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  context.tr('leaderboard.place_suffix', {'place': '$place'}),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: placeColor == const Color(0xffFFD700)
                        ? AppColors.patasColor
                        : placeColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRankRow({
    required Map<String, dynamic> item,
    required Color cardColor,
    required Color textColor,
  }) {
    final rank = int.tryParse(item['rank'].toString()) ?? 0;
    final user = Supabase.instance.client.auth.currentUser;
    final petProvider = Provider.of<ActivePetProvider>(context, listen: false);
    final activePet = petProvider.activePet;

    String petName = item['pet_name'] ?? context.tr('leaderboard.no_data');
    String? photoUrl = item['pet_photo_url'] as String?;
    final totalPoints = int.tryParse(item['total_points'].toString()) ?? 0;

    // Resiliência local: se o item for do usuário logado e os dados da view estiverem nulos/vazios, complementa com o pet ativo
    if (user != null && item['user_id'] == user.id && activePet != null) {
      if (petName == 'Sem dados' || petName.trim().isEmpty) {
        petName = activePet.name;
      }
      if (photoUrl == null || photoUrl.trim().isEmpty) {
        photoUrl = activePet.photoUrl;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          // Rank pos
          SizedBox(
            width: 32,
            child: Text(
              '$rankº',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          // Pet Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.patasColor.withValues(alpha: 0.1),
            backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : null,
            child: photoUrl == null || photoUrl.isEmpty
                ? const Icon(Icons.pets, size: 20, color: AppColors.patasColor)
                : null,
          ),
          const SizedBox(width: 16),
          // Pet Name
          Expanded(
            child: Text(
              petName,
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
            ),
          ),
          // Points
          Text(
            '$totalPoints pts',
            style: const TextStyle(
              color: AppColors.patasColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStickyCard({
    required dynamic activePet,
    required Color cardColor,
    required Color textColor,
  }) {
    final petName = activePet?.name ?? context.tr('rewards.my_pet');
    final photoUrl = activePet?.photoUrl as String?;

    final isUserInTop3 = _userRank > 0 && _userRank <= 3;
    final inRanking = _userRank > 0;

    String subtitleText;
    if (isUserInTop3) {
      subtitleText = context.tr('leaderboard.user_top3');
    } else if (inRanking) {
      // Calcula quantos pontos faltam para o top 3 se houver líder
      int pointsToPodium = 0;
      if (_leaderboard.isNotEmpty) {
        final thirdPlacePoints =
            (_leaderboard.length >= 3
                    ? _leaderboard[2]['total_points']
                    : _leaderboard.last['total_points'])
                as int;
        if (thirdPlacePoints > _userPoints) {
          pointsToPodium = thirdPlacePoints - _userPoints;
        }
      }
      subtitleText = pointsToPodium > 0
          ? context.tr('leaderboard.points_to_podium', {'points': '$pointsToPodium'})
          : context.tr('leaderboard.top15');
    } else {
      subtitleText = context.tr('leaderboard.start_engaging');
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: AppColors.patasColor.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.patasColor.withValues(alpha: 0.2),
              backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : null,
              child: photoUrl == null || photoUrl.isEmpty
                  ? const Icon(
                      Icons.pets,
                      size: 22,
                      color: AppColors.patasColor,
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        petName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.patasColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          inRanking ? context.tr('leaderboard.place_suffix', {'place': '$_userRank'}) : context.tr('leaderboard.no_rank'),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.patasColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitleText,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_userPoints',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Fredoka',
                    color: textColor,
                  ),
                ),
                Text(
                  context.tr('leaderboard.my_points'),
                  style: TextStyle(fontSize: 9, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
