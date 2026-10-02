import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app.dart';
import '../../../constants/app_colors.dart';
import '../../pets/active_pet_provider.dart';
import '../rewards/rewards_page.dart';
import '../rewards/services/gamification_service.dart';
import '../../love/services/patas_love_service.dart';
import '../../love/screens/patas_love_main_screen.dart';
import '../../../utils/responsive_layout.dart';

class PatasHubBottomSheet extends StatefulWidget {
  final bool isRewardsActive;

  const PatasHubBottomSheet({
    super.key,
    this.isRewardsActive = true,
  });

  static Future<void> show(BuildContext context, {bool isRewardsActive = true}) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PatasHubBottomSheet(isRewardsActive: isRewardsActive),
    );
  }

  @override
  State<PatasHubBottomSheet> createState() => _PatasHubBottomSheetState();
}

class _PatasHubBottomSheetState extends State<PatasHubBottomSheet> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GamificationService _gamificationService = GamificationService();
  final PatasLoveService _loveService = PatasLoveService();

  int _userPoints = 0;
  int _userRank = 0;
  int _chatCount = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadHubData();
  }

  Future<void> _loadHubData() async {
    final userId = _supabase.auth.currentUser?.id;
    final activePet =
        Provider.of<ActivePetProvider>(context, listen: false).activePet;

    if (userId != null && widget.isRewardsActive) {
      try {
        final stats = await _gamificationService.getUserStats(userId);
        if (mounted) {
          setState(() {
            _userPoints = stats['points'] ?? 0;
            _userRank = stats['rank'] ?? 0;
          });
        }
      } catch (e) {
        debugPrint('Erro ao carregar stats do hub: $e');
      }
    }

    if (activePet != null) {
      try {
        final chats = await _loveService.getChatsForPet(activePet.id);
        if (mounted) {
          setState(() {
            _chatCount = chats.length;
          });
        }
      } catch (e) {
        debugPrint('Erro ao carregar chats no hub: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final activePet = Provider.of<ActivePetProvider>(context).activePet;
    final isDark = thmode.darkMode;

    final bgColor = isDark ? AppColors.darkBG : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.darkBG;
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Indicador de arrasto superior (Drag handle)
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Cabeçalho da Central Patas
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.patasColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.patasColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Central Patas 🐾',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Acesse seus recursos de acasalamento e recompensas',
                          style: TextStyle(
                            fontSize: 12,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: subtitleColor,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Card 1 — Patas Love (Acasalamento & Chat)
              _buildHubCard(
                context,
                isDark: isDark,
                iconBgColor: Colors.pink.withValues(alpha: 0.15),
                icon: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.pinkAccent,
                  size: 28,
                ),
                title: 'Patas Love 💕',
                subtitle: _chatCount > 0
                    ? '$_chatCount ${_chatCount == 1 ? 'conversa ativa' : 'conversas ativas'}'
                    : 'Encontre o par ideal para ${activePet?.name ?? 'seu pet'}',
                badgeText: 'Chat & Match',
                badgeColor: Colors.pinkAccent,
                buttonText: 'Abrir Encontros & Mensagens',
                onPressed: () {
                  Navigator.pop(context);
                  if (context.isDesktop && desktopContentNavigatorKey.currentState != null) {
                    desktopContentNavigatorKey.currentState!.push(
                      MaterialPageRoute(
                        builder: (context) => const PatasLoveMainScreen(),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PatasLoveMainScreen(),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 14),

              // Card 2 — Patas Rewards (Gamificação)
              if (widget.isRewardsActive)
                _buildHubCard(
                  context,
                  isDark: isDark,
                  iconBgColor: Colors.amber.withValues(alpha: 0.15),
                  icon: const Icon(
                    Icons.card_giftcard_rounded,
                    color: Colors.amber,
                    size: 28,
                  ),
                  title: 'Patas Rewards 🎁',
                  subtitle: _isLoadingStats
                      ? 'Carregando saldo de pontos...'
                      : '$_userPoints Pontos Acumulados${_userRank > 0 ? ' • #$_userRankº no Ranking' : ''}',
                  badgeText: 'Gamificação',
                  badgeColor: Colors.amber.shade800,
                  buttonText: 'Ver Ranking & Prêmios',
                  onPressed: () {
                    Navigator.pop(context);
                    if (context.isDesktop && desktopContentNavigatorKey.currentState != null) {
                      desktopContentNavigatorKey.currentState!.push(
                        PageRouteBuilder(
                          opaque: false,
                          pageBuilder: (context, animation, secondaryAnimation) =>
                              const RewardsPage(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          opaque: false,
                          pageBuilder: (context, animation, secondaryAnimation) =>
                              const RewardsPage(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                        ),
                      );
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHubCard(
    BuildContext context, {
    required bool isDark,
    required Color iconBgColor,
    required Widget icon,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: icon,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.darkBG,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.patasColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onPressed,
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: Text(
                buttonText,
                style: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
