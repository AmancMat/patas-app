import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:patas_web_app/src/common_widgets/mobile_scroll_padding.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:patas_web_app/src/providers/active_account_provider.dart';
import 'package:patas_web_app/src/models/active_account_model.dart';
import '../models/donation_campaign_model.dart';
import '../services/shelter_service.dart';
import 'campaign_donation_page.dart';
import 'ong_donations_dashboard_screen.dart';

class PublicDonationMuralScreen extends StatefulWidget {
  const PublicDonationMuralScreen({super.key});

  @override
  State<PublicDonationMuralScreen> createState() =>
      _PublicDonationMuralScreenState();
}

class _PublicDonationMuralScreenState extends State<PublicDonationMuralScreen> {
  final ShelterService _service = ShelterService();
  final TextEditingController _searchController = TextEditingController();

  List<DonationCampaign> _campaigns = [];
  bool _isLoading = true;
  String _selectedCategory = 'Todos';

  final List<String> _categoryFilters = [
    'Todos',
    'Ração & Alimento',
    'Saúde & Cirurgia',
    'Reforma & Abrigo',
    'Geral & Manutenção',
  ];

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final results = await _service.getDonationCampaigns(
        category: _selectedCategory,
        activeOnly: true,
      );

      if (mounted) {
        setState(() {
          _campaigns = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao buscar campanhas de doação: $e');
      if (mounted) {
        setState(() {
          _campaigns = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DonationCampaign> get _filteredCampaigns {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _campaigns;

    return _campaigns.where((c) {
      final titleMatch = c.title.toLowerCase().contains(query);
      final ongMatch = (c.ongName ?? '').toLowerCase().contains(query);
      final descMatch = (c.description ?? '').toLowerCase().contains(query);
      return titleMatch || ongMatch || descMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ActiveAccountProvider>(
      builder: (context, activeAccountProvider, child) {
        final activeAccount = activeAccountProvider.activeAccount;
        if (activeAccount != null && activeAccount.type == AccountType.ong) {
          return const OngDonationsDashboardScreen();
        }

        final thmode = Provider.of<DarkMode>(context);
        final isDark = thmode.darkMode;
        final list = _filteredCampaigns;

        return Scaffold(
          backgroundColor:
              isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
          appBar: PatasEssencialAppBar(
            title: 'Mural de Doações',
            subtitle: 'Apoie ONGs parceiras e transforme a vida de resgatados',
            leadingIcon: const Icon(
              Icons.volunteer_activism_rounded,
              color: Colors.pinkAccent,
              size: 22,
            ),
            actions: [
              IconButton(
                tooltip: 'Painel da ONG',
                icon: const Icon(Icons.dashboard_customize_rounded,
                    color: Colors.pinkAccent),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OngDonationsDashboardScreen(),
                    ),
                  ).then((_) {
                    if (mounted) _loadCampaigns();
                  });
                },
              ),
            ],
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadCampaigns,
              color: Colors.pinkAccent,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: CustomScrollView(
                slivers: [
                  // 1. Barra de Busca & Categorias
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Column(
                        children: [
                          // Campo de Busca
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                      alpha: isDark ? 0.2 : 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: 'Buscar por causa, ONG ou alimento...',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white54 : Colors.black45,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  color: Colors.pinkAccent,
                                  size: 22,
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded,
                                            size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {});
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Chips de Categorias
                          SizedBox(
                            height: 38,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _categoryFilters.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final cat = _categoryFilters[index];
                                final isSelected = cat == _selectedCategory;

                                return InkWell(
                                  onTap: () {
                                    setState(() => _selectedCategory = cat);
                                    _loadCampaigns();
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.pinkAccent
                                          : (isDark
                                              ? const Color(0xFF1E293B)
                                              : Colors.white),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.pinkAccent
                                            : (isDark
                                                ? Colors.white10
                                                : Colors.grey.shade300),
                                      ),
                                    ),
                                    child: Text(
                                      cat,
                                      style: TextStyle(
                                        fontFamily: 'Fredoka',
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark
                                                ? Colors.white70
                                                : Colors.black87),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Banner de Transparência
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: isDark ? 0.15 : 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.teal.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shield_outlined,
                                color: Colors.teal, size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '100% Solidário: Doações via PIX caem direto na conta da ONG, sem taxas intermediárias do app.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  height: 1.3,
                                  color: isDark ? Colors.tealAccent : Colors.teal.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 3. Grid / Lista de Campanhas
                  if (_isLoading)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.pinkAccent),
                      ),
                    )
                  else if (list.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(isDark),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      sliver: context.isWide
                          ? SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:
                                    MediaQuery.of(context).size.width >= 950
                                        ? 3
                                        : 2,
                                mainAxisSpacing: 20,
                                crossAxisSpacing: 20,
                                childAspectRatio: 0.68,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (ctx, i) => _buildCampaignCard(list[i], isDark,
                                    isGrid: true),
                                childCount: list.length,
                              ),
                            )
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (ctx, i) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildCampaignCard(list[i], isDark,
                                      isGrid: false),
                                ),
                                childCount: list.length,
                              ),
                            ),
                    ),

                  // Padding dinâmico inferior (mobile e tablet com bottom fluid bar)
                  if (!context.isDesktop)
                    const SliverToBoxAdapter(child: MobileScrollPadding()),
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

  Widget _buildCampaignCard(DonationCampaign campaign, bool isDark,
      {bool isGrid = false}) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CampaignDonationPage(
              campaign: campaign,
              onDonationUpdated: _loadCampaigns,
            ),
          ),
        ).then((_) {
          if (mounted) _loadCampaigns();
        });
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto de Capa da Causa proporcional
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(22)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: SizedBox(
                    width: double.infinity,
                    child: campaign.imageUrl != null &&
                            campaign.imageUrl!.isNotEmpty
                        ? Image.network(campaign.imageUrl!, fit: BoxFit.cover)
                        : Container(
                            color: Colors.pinkAccent.withValues(alpha: 0.1),
                            child: const Icon(
                              Icons.volunteer_activism_rounded,
                              size: 48,
                              color: Colors.pinkAccent,
                            ),
                          ),
                  ),
                ),
              ),

              // Badge Categoria
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    campaign.category,
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Badge Meta Atingida se for o caso
              if (campaign.isGoalReached)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'META ATINGIDA! 🎉',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Badge Pausada / Encerrada
              if (!campaign.isAcceptingDonations)
                Positioned(
                  top: campaign.isGoalReached ? 42 : 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: campaign.isExpired
                          ? Colors.red.shade700
                          : Colors.orange.shade800,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      campaign.isExpired ? 'ENCERRADA' : 'PAUSADA',
                      style: const TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              // Badge Prazo / Vigência
              Positioned(
                bottom: 10,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: campaign.isExpired
                          ? Colors.redAccent.withValues(alpha: 0.5)
                          : Colors.white12,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        campaign.hasDeadline
                            ? Icons.schedule_rounded
                            : Icons.all_inclusive_rounded,
                        size: 11,
                        color: campaign.isExpired
                            ? Colors.redAccent
                            : Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        campaign.deadlineText,
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: campaign.isExpired
                              ? Colors.redAccent
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (isGrid)
            Expanded(
              child: _buildCampaignInfo(campaign, isDark, isGrid: true),
            )
          else
            _buildCampaignInfo(campaign, isDark, isGrid: false),
        ],
      ),
    ),
    );
  }

  Widget _buildCampaignInfo(DonationCampaign campaign, bool isDark,
      {required bool isGrid}) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isGrid ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Identificação da ONG
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.pinkAccent.withValues(alpha: 0.15),
                    backgroundImage: campaign.ongPhotoUrl != null &&
                            campaign.ongPhotoUrl!.isNotEmpty
                        ? NetworkImage(campaign.ongPhotoUrl!)
                        : null,
                    child: campaign.ongPhotoUrl == null
                        ? const Icon(Icons.volunteer_activism,
                            size: 12, color: Colors.pinkAccent)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      campaign.ongName ?? 'ONG Parceira',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Título da Campanha
              Text(
                campaign.title,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.darkBG,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              if (campaign.description != null &&
                  campaign.description!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  campaign.description!,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.25,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
          if (!isGrid) const SizedBox(height: 12),

          // Barra de Progresso + Botão
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: campaign.progressPercentage,
                  minHeight: 8,
                  backgroundColor: isDark
                      ? const Color(0xFF334155)
                      : Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    campaign.isGoalReached ? Colors.green : Colors.pinkAccent,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${campaign.formattedCurrent} arrecadados',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: campaign.isGoalExceeded
                          ? const Color(0xFF10B981)
                          : (campaign.isGoalReached
                              ? Colors.green
                              : Colors.pinkAccent),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      'Meta: ${campaign.formattedTarget}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Badge de Status da Meta (Normal, Batida ou Superada)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: campaign.isGoalExceeded
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : (campaign.isGoalReached
                          ? Colors.green.withValues(alpha: 0.12)
                          : (isDark ? Colors.white10 : Colors.grey.shade100)),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: campaign.isGoalExceeded
                        ? const Color(0xFF10B981).withValues(alpha: 0.35)
                        : (campaign.isGoalReached
                            ? Colors.green.withValues(alpha: 0.3)
                            : Colors.transparent),
                  ),
                ),
                child: Text(
                  campaign.goalStatusBadgeText,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: campaign.isGoalExceeded
                        ? const Color(0xFF10B981)
                        : (campaign.isGoalReached
                            ? Colors.green
                            : (isDark ? Colors.white70 : Colors.black54)),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Botão de Doação
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CampaignDonationPage(
                          campaign: campaign,
                          onDonationUpdated: _loadCampaigns,
                        ),
                      ),
                    ).then((_) {
                      if (mounted) _loadCampaigns();
                    });
                  },
                  icon: Icon(
                    campaign.isAcceptingDonations
                        ? Icons.volunteer_activism_rounded
                        : Icons.visibility_rounded,
                    size: 18,
                  ),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      campaign.isAcceptingDonations
                          ? 'Apoiar Campanha (PIX & Cripto)'
                          : (campaign.isExpired
                              ? 'Campanha Encerrada (Ver Detalhes)'
                              : 'Campanha Pausada (Ver Detalhes)'),
                      style: const TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: campaign.isAcceptingDonations
                        ? Colors.teal
                        : (isDark
                            ? const Color(0xFF334155)
                            : Colors.grey.shade400),
                    foregroundColor: Colors.white,
                    elevation: campaign.isAcceptingDonations ? 2 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.pinkAccent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.volunteer_activism_rounded,
                size: 56,
                color: Colors.pinkAccent,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Nenhuma campanha encontrada',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.darkBG,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tente selecionar outra categoria ou limpe o termo de busca.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() => _selectedCategory = 'Todos');
                _loadCampaigns();
              },
              icon: const Icon(Icons.clear_all_rounded),
              label: const Text(
                'Limpar Filtros',
                style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.pinkAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
