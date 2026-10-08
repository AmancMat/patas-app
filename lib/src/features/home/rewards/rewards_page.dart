import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:patas_web_app/src/features/pets/active_pet_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:patas_web_app/src/features/home/rewards/services/gamification_service.dart';
import 'package:patas_web_app/src/features/home/rewards/leaderboard_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import '../../../../app.dart';
import 'package:patas_web_app/src/localization/localizations_ext.dart';

class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  int _points = 0;
  int _rank = 0;
  bool _isLoadingStats = true;
  List<Map<String, dynamic>> _sponsors = [];
  bool _isLoadingSponsors = true;
  int _currentSponsorPage = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final service = GamificationService();

      final results = await Future.wait([
        user != null ? service.getUserStats(user.id) : Future.value({'points': 0, 'rank': 0}),
        service.getSponsors(),
      ]);

      if (mounted) {
        setState(() {
          final stats = results[0] as Map<String, dynamic>;
          _points = stats['points'] ?? 0;
          _rank = stats['rank'] ?? 0;
          _isLoadingStats = false;

          _sponsors = results[1] as List<Map<String, dynamic>>;
          _isLoadingSponsors = false;
        });
      }
    } catch (e) {
      debugPrint('RewardsPage: Erro ao carregar dados: $e');
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
          _isLoadingSponsors = false;
        });
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
              label: context.tr('rewards.close_tooltip'),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.25),
                  ),
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

    final user = Supabase.instance.client.auth.currentUser;
    final referralCode = user?.id.substring(0, 8).toUpperCase() ?? '------';

    final bgColor = thmode.darkMode ? AppColors.bodygray : const Color(0xffF5F5F5);
    final textColor = thmode.darkMode ? Colors.white : AppColors.darkBG;
    final cardColor = thmode.darkMode ? const Color(0xff1a1a1a) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: PatasEssencialAppBar(
        title: context.tr('rewards.title'),
        subtitle: context.tr('rewards.subtitle'),
        leadingIcon: Icon(
          Icons.emoji_events_rounded,
          color: Colors.amber,
          size: 22,
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Header (Saldo e Perfil)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (activePet?.photoUrl != null && activePet!.photoUrl!.isNotEmpty)
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.patasColor.withValues(alpha: 0.2),
                            backgroundImage: NetworkImage(activePet.photoUrl!),
                          )
                        else
                          const CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.patasColor,
                            child: Icon(Icons.pets, size: 40, color: Colors.white),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          activePet?.name ?? context.tr('rewards.my_pet'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _isLoadingStats
                            ? const SizedBox(
                                height: 50,
                                child: Center(child: CircularProgressIndicator(color: AppColors.patasColor)),
                              )
                            : TweenAnimationBuilder<int>(
                                tween: IntTween(begin: 0, end: _points),
                                duration: const Duration(milliseconds: 1500),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Text(
                                    value.toString(),
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Fredoka',
                                      color: textColor,
                                    ),
                                  );
                                },
                              ),
                        Text(
                          context.tr('rewards.season_points'),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.patasColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _isLoadingStats ? context.tr('rewards.ranking_loading') : (_rank > 0 ? context.tr('rewards.ranking_position', {'rank': '$_rank'}) : context.tr('rewards.not_ranked')),
                            style: const TextStyle(
                              color: AppColors.patasColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _PulseRegulationButton(
                          onTap: () {
                            _showRegulationModal(context, cardColor, textColor);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 1.5 Botão do Placar Global
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              opaque: false,
                              barrierColor: Colors.black.withValues(alpha: 0.2),
                              pageBuilder: (context, _, __) => const LeaderboardPage(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return FadeTransition(opacity: animation, child: child);
                              },
                            ),
                          ).then((_) => _loadStats());
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xffFFD700).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Text('🏆', style: TextStyle(fontSize: 22)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr('rewards.leaderboard_card_title'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Veja a disputa e confira quem está no pódio!',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textColor.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 2. Vitrine (Carrossel Dinâmico de Patrocinadores)
                  if (_isLoadingSponsors) ...[
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(color: AppColors.patasColor),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ] else if (_sponsors.isNotEmpty) ...[
                    Column(
                      children: [
                        SizedBox(
                          height: 220,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _sponsors.length,
                            onPageChanged: (int page) {
                              setState(() {
                                _currentSponsorPage = page;
                              });
                            },
                            itemBuilder: (context, index) {
                              final sponsor = _sponsors[index];
                              final sponsorName = sponsor['name'] ?? context.tr('rewards.sponsor_fallback');
                              final prizeTitle = sponsor['prize_title'] ?? context.tr('rewards.prize_fallback');
                              
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: index % 2 == 0 
                                        ? [AppColors.patasColor, const Color(0xFFFF9B70)]
                                        : [const Color(0xffD4185C), const Color(0xFFFF70A6)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.patasColor.withValues(alpha: 0.25),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        if (sponsor['logo_url'] != null && (sponsor['logo_url'] as String).isNotEmpty)
                                          Container(
                                            width: 24,
                                            height: 24,
                                            margin: const EdgeInsets.only(right: 8),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              image: DecorationImage(
                                                image: NetworkImage(sponsor['logo_url']),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          )
                                        else
                                          const Icon(Icons.stars_rounded, color: Colors.white70, size: 20),
                                        Text(
                                          context.tr('rewards.partnership_prefix', {'name': sponsorName.toUpperCase()}),
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      prizeTitle,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontFamily: 'Fredoka',
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        _showSponsorDetailsModal(context, sponsor, cardColor, textColor);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: index % 2 == 0 ? AppColors.patasColor : const Color(0xffD4185C),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(context.tr('rewards.view_prize_details'), style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        if (_sponsors.length > 1) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _sponsors.length,
                              (index) => Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentSponsorPage == index
                                      ? AppColors.patasColor
                                      : Colors.grey.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],

                  // 3. Banner de Compartilhamento (Código de Convite)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.patasColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.patasColor.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          context.tr('rewards.referral_title'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textColor.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.patasColor),
                              ),
                              child: SelectableText(
                                referralCode,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontFamily: 'Fredoka',
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 4.0,
                                  color: AppColors.patasColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              tooltip: context.tr('rewards.copy_code_tooltip'),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: referralCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(context.tr('rewards.copy_code_success')),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy_rounded, color: AppColors.patasColor),
                              style: IconButton.styleFrom(
                                backgroundColor: cardColor,
                                padding: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                side: const BorderSide(color: AppColors.patasColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.tr('rewards.referral_hint'),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppColors.patasColor),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 4. Bloco de Missões
                  Text(
                    context.tr('rewards.missions_title'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildMissionCard(
                    icon: Icons.person_add_rounded,
                    title: context.tr('rewards.mission_invite_title'),
                    subtitle: context.tr('rewards.mission_invite_sub'),
                    points: '+500 pts',
                    buttonText: context.tr('rewards.mission_invite_btn'),
                    cardColor: cardColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 12),
                  _buildMissionCard(
                    icon: Icons.assignment_turned_in_rounded,
                    title: context.tr('rewards.mission_profile_title'),
                    subtitle: context.tr('rewards.mission_profile_sub'),
                    points: '+100 pts',
                    buttonText: context.tr('rewards.mission_profile_btn'),
                    cardColor: cardColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 12),
                  _buildMissionCard(
                    icon: Icons.favorite_rounded,
                    title: context.tr('rewards.mission_feed_title'),
                    subtitle: context.tr('rewards.mission_feed_sub'),
                    points: '+5 pts',
                    buttonText: context.tr('rewards.mission_feed_btn'),
                    cardColor: cardColor,
                    textColor: textColor,
                  ),                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String points,
    required String buttonText,
    required Color cardColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.patasColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.patasColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                points,
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: AppColors.patasColor.withValues(alpha: 0.1),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.patasColor,
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  void _showRegulationModal(BuildContext context, Color cardColor, Color textColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('rewards.regulation_title'),
              style: TextStyle(
                fontSize: 24,
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  '''${context.tr('rewards.regulation_rule1_title')}
${context.tr('rewards.regulation_rule1_desc')}

${context.tr('rewards.regulation_rule2_title')}
${context.tr('rewards.regulation_rule2_bullet1')}
${context.tr('rewards.regulation_rule2_bullet2')}
${context.tr('rewards.regulation_rule2_bullet3')}

${context.tr('rewards.regulation_rule3_title')}
${context.tr('rewards.regulation_rule3_intro')}
${context.tr('rewards.regulation_rule3_crit1')}
${context.tr('rewards.regulation_rule3_crit2')}
${context.tr('rewards.regulation_rule3_crit3')}''',
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withValues(alpha: 0.8),
                    height: 1.6,
                  ),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.patasColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(context.tr('rewards.understood_btn'), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSponsorDetailsModal(BuildContext context, Map<String, dynamic> sponsor, Color cardColor, Color textColor) {
    final String sponsorName = sponsor['name'] ?? context.tr('rewards.sponsor_fallback');
    final String? logoUrl = sponsor['logo_url'];
    final String prizeTitle = sponsor['prize_title'] ?? context.tr('rewards.prize_fallback');
    final String prizeDescription = sponsor['prize_description'] ?? context.tr('rewards.no_desc');
    final String prizeRules = sponsor['prize_rules'] ?? context.tr('rewards.no_rules');
    final String? targetLink = sponsor['target_link'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (logoUrl != null && logoUrl.isNotEmpty)
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.patasColor.withValues(alpha: 0.1),
                    backgroundImage: NetworkImage(logoUrl),
                  )
                else
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.patasColor,
                    child: Icon(Icons.star_rounded, size: 28, color: Colors.white),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.patasColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          context.tr('rewards.confirmed_partner'),
                          style: TextStyle(
                            color: AppColors.patasColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sponsorName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      prizeTitle,
                      style: TextStyle(
                        fontSize: 22,
                        fontFamily: 'Fredoka',
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('rewards.about_prize'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: textColor.withValues(alpha: 0.5),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      prizeDescription,
                      style: TextStyle(
                        fontSize: 15,
                        color: textColor.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      context.tr('rewards.how_to_claim'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: textColor.withValues(alpha: 0.5),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                      ),
                      child: Text(
                        prizeRules,
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor.withValues(alpha: 0.7),
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      context.tr('rewards.back_btn'),
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (targetLink != null && targetLink.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          final Uri url = Uri.parse(targetLink);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(context.tr('rewards.cant_open_link')),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          debugPrint('Erro ao abrir link: $e');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.patasColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        context.tr('rewards.visit_site_btn'),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseRegulationButton extends StatefulWidget {
  final VoidCallback onTap;

  const _PulseRegulationButton({required this.onTap});

  @override
  State<_PulseRegulationButton> createState() => _PulseRegulationButtonState();
}

class _PulseRegulationButtonState extends State<_PulseRegulationButton>
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
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _colorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
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
          const Color(0xFFFF5A2B), // Laranja Patas
          const Color(0xFFFF007A), // Rosa/Magenta Vibrante
          _colorAnimation.value,
        )!;
        final color2 = Color.lerp(
          const Color(0xFFFF8A00), // Laranja Amarelado
          const Color(0xFFE0245E), // Carmim Vibrante
          _colorAnimation.value,
        )!;

        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
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
                onTap: widget.onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.gavel_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.tr('rewards.regulation_btn'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Colors.white,
                          fontFamily: 'Fredoka',
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: Colors.white70,
                      ),
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
