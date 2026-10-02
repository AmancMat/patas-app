import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:patas_web_app/src/common_widgets/mobile_scroll_padding.dart';
import 'package:patas_web_app/src/providers/active_account_provider.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import '../models/donation_campaign_model.dart';
import '../services/shelter_service.dart';
import 'ong_create_campaign_sheet.dart';
import 'campaign_donation_page.dart';

class OngDonationsDashboardScreen extends StatefulWidget {
  const OngDonationsDashboardScreen({super.key});

  @override
  State<OngDonationsDashboardScreen> createState() =>
      _OngDonationsDashboardScreenState();
}

class _OngDonationsDashboardScreenState
    extends State<OngDonationsDashboardScreen> {
  final ShelterService _service = ShelterService();

  List<DonationCampaign> _campaigns = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final activeAccount =
        Provider.of<ActiveAccountProvider>(context, listen: false).activeAccount;
    final ongId = activeAccount?.id ?? 'demo-ong-1';

    try {
      final results = await _service.getDonationCampaigns(ongId: ongId);
      if (mounted) {
        setState(() {
          _campaigns = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar campanhas da ONG: $e');
      if (mounted) {
        setState(() {
          _campaigns = [];
          _isLoading = false;
        });
      }
    }
  }

  void _openCreateCampaign([DonationCampaign? campaign]) async {
    final activeAccount =
        Provider.of<ActiveAccountProvider>(context, listen: false).activeAccount;
    final ongId = activeAccount?.id ?? 'demo-ong-1';
    final ongName = activeAccount?.name ?? 'ONG Parceira';

    final result = await OngCreateCampaignSheet.show(
      context,
      ongId: ongId,
      ongName: ongName,
      existingCampaign: campaign,
    );

    if (result == true && mounted) {
      _loadCampaigns();
    }
  }

  void _openUpdateProgressDialog(DonationCampaign campaign, bool isDark) {
    final controller = TextEditingController(
      text: campaign.currentAmount.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Atualizar Arrecadação',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.darkBG,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informe o novo total arrecadado para "${campaign.title}":',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                prefixText: campaign.goalType == 'money' ? 'R\$ ' : null,
                suffixText: campaign.goalType == 'items' ? campaign.unitLabel : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newAmount = double.tryParse(controller.text.trim()) ??
                  campaign.currentAmount;
              Navigator.pop(ctx);
              await _service.updateCampaignProgress(
                campaignId: campaign.id,
                newCurrentAmount: newAmount,
              );
              _loadCampaigns();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(DonationCampaign campaign) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Campanha?',
            style: TextStyle(fontFamily: 'Fredoka')),
        content: Text('Deseja realmente remover a campanha "${campaign.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _service.deleteDonationCampaign(campaign.id);
              _loadCampaigns();
            },
            child: const Text('Excluir',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
      appBar: PatasEssencialAppBar(
        title: 'Mural de Doações & PIX',
        subtitle: 'Campanhas comunitárias e arrecadação do abrigo',
        leadingIcon: const Icon(
          Icons.volunteer_activism_rounded,
          color: Colors.pinkAccent,
          size: 22,
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: Colors.pinkAccent,
              size: 24,
            ),
            tooltip: 'Nova Campanha',
            onPressed: () => _openCreateCampaign(),
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
                  // 1. Resumo Métrico
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: _buildMetricSummary(isDark),
                    ),
                  ),

                  // 2. Lista de Campanhas
                  if (_isLoading)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.pinkAccent),
                      ),
                    )
                  else if (_campaigns.isEmpty)
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
                                mainAxisSpacing: 18,
                                crossAxisSpacing: 18,
                                childAspectRatio: 0.72,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (ctx, i) => _buildCampaignCard(_campaigns[i], isDark, isGrid: true),
                                childCount: _campaigns.length,
                              ),
                            )
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (ctx, i) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _buildCampaignCard(_campaigns[i], isDark, isGrid: false),
                                ),
                                childCount: _campaigns.length,
                              ),
                            ),
                    ),

                  // Padding dinâmico inferior
                  if (context.isMobile)
                    const SliverToBoxAdapter(child: MobileScrollPadding()),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: context.isDesktop
              ? 20
              : (MediaQuery.paddingOf(context).bottom + 76),
        ),
        child: FloatingActionButton.extended(
          heroTag: null,
          onPressed: () => _openCreateCampaign(),
          backgroundColor: Colors.pinkAccent,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'Nova Campanha',
            style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricSummary(bool isDark) {
    final activeCount = _campaigns.where((c) => c.isActive).length;
    final totalMoney = _campaigns
        .where((c) => c.goalType == 'money')
        .fold(0.0, (sum, c) => sum + c.currentAmount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.pinkAccent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.savings_outlined,
                      color: Colors.pinkAccent, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Arrecadado',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        'R\$ ${totalMoney.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.darkBG,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 36,
            width: 1,
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
          Expanded(
            child: Row(
              children: [
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.campaign_rounded,
                      color: Colors.purpleAccent, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Campanhas Ativas',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '$activeCount no ar',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.darkBG,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(DonationCampaign campaign, bool isDark,
      {bool isGrid = false}) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagem proporcional (16:9) + Badge de Categoria + Menu de Ações
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
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
                              size: 44,
                              color: Colors.pinkAccent,
                            ),
                          ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
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
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded,
                        color: Colors.white, size: 20),
                    onSelected: (val) {
                      if (val == 'progress') {
                        _openUpdateProgressDialog(campaign, isDark);
                      }
                      if (val == 'edit') {
                        _openCreateCampaign(campaign);
                      }
                      if (val == 'delete') {
                        _confirmDelete(campaign);
                      }
                      if (val == 'pix') {
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
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'progress',
                        child: Row(
                          children: [
                            Icon(Icons.edit_note_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Atualizar Valor Arrecadado'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'pix',
                        child: Row(
                          children: [
                            Icon(Icons.pix_rounded,
                                size: 18, color: Colors.teal),
                            SizedBox(width: 8),
                            Text('Ver Chave PIX'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Editar Campanha'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                size: 18, color: Colors.redAccent),
                            SizedBox(width: 8),
                            Text('Excluir',
                                style: TextStyle(color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Informações da Campanha (Expanded apenas quando está no Grid)
          if (isGrid)
            Expanded(
              child: _buildCampaignInfo(campaign, isDark, isGrid: true),
            )
          else
            _buildCampaignInfo(campaign, isDark, isGrid: false),
        ],
      ),
    );
  }

  Widget _buildCampaignInfo(DonationCampaign campaign, bool isDark,
      {required bool isGrid}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isGrid ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
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
                const SizedBox(height: 2),
                Text(
                  campaign.description!,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
          if (!isGrid) const SizedBox(height: 8),

          // Barra de Progresso + Rodapé
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
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    campaign.goalStatusBadgeText,
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 11,
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
                      '${campaign.formattedCurrent} / ${campaign.formattedTarget}',
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
              const SizedBox(height: 6),
              const Divider(height: 8),
              Row(
                children: [
                  const Icon(Icons.pix_rounded, size: 16, color: Colors.teal),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      campaign.pixKey ?? 'PIX Cadastrado',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () => _openUpdateProgressDialog(campaign, isDark),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.pinkAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_note_rounded,
                              size: 14, color: Colors.pinkAccent),
                          SizedBox(width: 4),
                          Text(
                            'Atualizar',
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.pinkAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
        padding: const EdgeInsets.all(28),
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
              'Nenhuma campanha ativa no momento',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.darkBG,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Text(
                'Crie campanhas de arrecadação de ração, cirurgias ou reformas com chave PIX direta para os tutores apoiarem seu abrigo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _openCreateCampaign(),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Criar Primeira Campanha',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
