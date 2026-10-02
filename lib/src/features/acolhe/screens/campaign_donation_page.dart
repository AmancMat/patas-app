import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../../../../app.dart';
import '../../../common_widgets/mobile_scroll_padding.dart';
import '../../../common_widgets/patas_essencial_app_bar.dart';
import '../../../constants/app_colors.dart';
import '../../pets/active_pet_provider.dart';
import '../../solana/widgets/solana_pay_donation_tab.dart';
import '../../solana/services/solana_pay_service.dart';
import '../models/donation_campaign_model.dart';
import '../models/shelter_donation_receipt_model.dart';
import '../services/shelter_service.dart';

class CampaignDonationPage extends StatefulWidget {
  final DonationCampaign campaign;
  final VoidCallback? onDonationUpdated;

  const CampaignDonationPage({
    super.key,
    required this.campaign,
    this.onDonationUpdated,
  });

  @override
  State<CampaignDonationPage> createState() => _CampaignDonationPageState();
}

class _CampaignDonationPageState extends State<CampaignDonationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ShelterService _shelterService = ShelterService();

  late DonationCampaign _campaign;
  int _selectedPaymentMethodIndex = 0; // 0: PIX, 1: Solana Pay
  bool _isRegisteringPix = false;

  late Future<List<ShelterDonationReceiptModel>> _receiptsFuture;

  @override
  void initState() {
    super.initState();
    _campaign = widget.campaign;
    _tabController = TabController(length: 2, vsync: this);
    _loadReceipts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadReceipts() {
    setState(() {
      _receiptsFuture = _shelterService.getUserCampaignDonations(_campaign.id).then((list) async {
        if (list.isEmpty) {
          String? petId;
          String? petName;
          String? petPhoto;
          if (mounted) {
            try {
              final petProvider = Provider.of<ActivePetProvider>(context, listen: false);
              final pet = petProvider.activePet;
              petId = pet?.id;
              petName = pet?.name;
              petPhoto = pet?.photoUrl;
            } catch (_) {}
          }
          final effectiveWallet = (_campaign.solanaWallet != null && _campaign.solanaWallet!.trim().isNotEmpty)
              ? _campaign.solanaWallet!.trim()
              : SolanaPayService.defaultTreasuryWallet;

          final imported = await _shelterService.syncBlockchainDonations(
            campaignId: _campaign.id,
            walletAddress: effectiveWallet,
            donorPetId: petId,
            donorName: petName,
            donorPhoto: petPhoto,
          );

          if (imported > 0) {
            return await _shelterService.getUserCampaignDonations(_campaign.id);
          }
        }
        return list;
      });
    });
  }

  void _onDonationConfirmed(double addedBrl) async {
    setState(() {
      _campaign = _campaign.copyWith(
        currentAmount: _campaign.currentAmount + addedBrl,
      );
    });
    _loadReceipts();
    widget.onDonationUpdated?.call();
  }

  void _confirmPixDonation(BuildContext context, bool isDark) async {
    final petProvider = Provider.of<ActivePetProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final TextEditingController amountController = TextEditingController(text: '20,00');

    final confirmedAmount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.pix_rounded, color: Color(0xFF00BDAE), size: 24),
            const SizedBox(width: 10),
            Text(
              'Confirmar Doação PIX',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.darkBG,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Digite o valor em R\$ que você acabou de transferir via PIX para computar seu recibo:',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark ? Colors.white : AppColors.darkBG,
              ),
              decoration: InputDecoration(
                prefixText: 'R\$ ',
                prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00BDAE)),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF00BDAE), width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(
              'Cancelar',
              style: TextStyle(
                fontFamily: 'Fredoka',
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BDAE),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () {
              final raw = amountController.text.replaceAll('.', '').replaceAll(',', '.').trim();
              final parsed = double.tryParse(raw) ?? 0.0;
              Navigator.pop(ctx, parsed > 0 ? parsed : null);
            },
            child: const Text(
              'Registrar Doação',
              style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmedAmount == null || confirmedAmount <= 0) return;

    setState(() => _isRegisteringPix = true);

    try {
      final activePet = petProvider.activePet;
      final petId = activePet?.id;
      final petName = activePet?.name;
      final petPhoto = activePet?.photoUrl;

      final success = await _shelterService.registerDonationProgress(
        campaignId: _campaign.id,
        addedAmount: confirmedAmount,
        paymentMethod: 'pix',
        donorPetId: petId,
        donorName: petName,
        donorPhoto: petPhoto,
      );

      if (success && mounted) {
        _onDonationConfirmed(confirmedAmount);
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '🎉 Doação PIX de R\$ ${confirmedAmount.toStringAsFixed(2).replaceAll('.', ',')} registrada com sucesso!',
                    style: const TextStyle(fontFamily: 'Fredoka', fontSize: 13, color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRegisteringPix = false);
    }
  }

  void _copyPixKey(BuildContext context, String key) {
    Clipboard.setData(ClipboardData(text: key));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.copy_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Chave PIX copiada para a área de transferência!',
                style: TextStyle(fontFamily: 'Fredoka', fontSize: 13, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF00BDAE),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<DarkMode>(context).darkMode;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBG : const Color(0xFFF8FAFC),
      appBar: PatasEssencialAppBar(
        title: _campaign.title,
        subtitle: _campaign.ongName ?? 'Campanha de Arrecadação',
        leadingIcon: const Icon(Icons.volunteer_activism_rounded, color: AppColors.patasColor),
        showBackButton: true,
        maxWidth: 800,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              // Header da Campanha e TabBar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    _buildCampaignHeader(isDark),
                    const SizedBox(height: 12),
                    _buildCustomTabBar(isDark),
                  ],
                ),
              ),

              // Conteúdo das Abas
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSupportTab(isDark),
                    _buildReceiptsTab(isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampaignHeader(bool isDark) {
    final progress = _campaign.rawProgressRatio.clamp(0.0, 1.0);
    final isExceeded = _campaign.isGoalExceeded;
    final isReached = _campaign.isGoalReached;

    final badgeColor = (isExceeded || isReached)
        ? const Color(0xFF10B981)
        : AppColors.patasColor;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isExceeded || isReached)
              ? const Color(0xFF10B981).withValues(alpha: 0.35)
              : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Miniatura da Campanha
              if (_campaign.imageUrl != null && _campaign.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _campaign.imageUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
                  ),
                )
              else
                _buildPlaceholderIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _campaign.title,
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.darkBG,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _campaign.ongName ?? 'ONG Responsável',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 12.5,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Badge de Status da Meta
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  _campaign.goalStatusBadgeText,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Barra de Progresso
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                isExceeded || isReached ? const Color(0xFF10B981) : AppColors.patasColor,
              ),
              minHeight: 7,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Arrecadado: R\$ ${_campaign.currentAmount.toStringAsFixed(2).replaceAll('.', ',')}',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              Text(
                'Meta: R\$ ${_campaign.targetAmount.toStringAsFixed(2).replaceAll('.', ',')}',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.patasColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.volunteer_activism_rounded, color: AppColors.patasColor, size: 28),
    );
  }

  Widget _buildCustomTabBar(bool isDark) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        labelColor: isDark ? Colors.white : AppColors.darkBG,
        unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
        labelStyle: const TextStyle(
          fontFamily: 'Fredoka',
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Fredoka',
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_rounded, size: 16, color: Color(0xFFEF4444)),
                SizedBox(width: 8),
                Text('Apoiar Agora'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_rounded, size: 16, color: Color(0xFF10B981)),
                SizedBox(width: 8),
                Text('Minhas Doações'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportTab(bool isDark) {
    final hasPix = _campaign.pixKey != null && _campaign.pixKey!.isNotEmpty;
    final solanaWallet = (_campaign.solanaWallet != null && _campaign.solanaWallet!.trim().isNotEmpty)
        ? _campaign.solanaWallet!.trim()
        : SolanaPayService.defaultTreasuryWallet;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Seletor de Método de Doação
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildMethodButton(
                    title: 'PIX Direto',
                    icon: Icons.pix_rounded,
                    color: const Color(0xFF00BDAE),
                    isSelected: _selectedPaymentMethodIndex == 0,
                    isDark: isDark,
                    onTap: () => setState(() => _selectedPaymentMethodIndex = 0),
                  ),
                ),
                Expanded(
                  child: _buildMethodButton(
                    title: 'Solana Pay ⚡',
                    icon: Icons.bolt_rounded,
                    color: const Color(0xFF14F195),
                    isSelected: _selectedPaymentMethodIndex == 1,
                    isDark: isDark,
                    onTap: () => setState(() => _selectedPaymentMethodIndex = 1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Renderização do Método Selecionado
          if (_selectedPaymentMethodIndex == 0)
            _buildPixSection(hasPix, isDark)
          else
            SolanaPayDonationTab(
              campaignId: _campaign.id,
              campaignTitle: _campaign.title,
              ongName: _campaign.ongName,
              solanaWallet: solanaWallet,
              isDark: isDark,
              onDonationConfirmed: _onDonationConfirmed,
            ),

          const MobileScrollPadding(),
        ],
      ),
    );
  }

  Widget _buildMethodButton({
    required String title,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF0F172A) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: color, width: 1.5) : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? color : (isDark ? Colors.white60 : Colors.black54)),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : AppColors.darkBG)
                    : (isDark ? Colors.white60 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPixSection(bool hasPix, bool isDark) {
    if (!hasPix) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Icon(Icons.info_outline_rounded, size: 40, color: Colors.amber),
            const SizedBox(height: 12),
            Text(
              'Chave PIX em Configuração',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.darkBG,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Esta ONG ainda não cadastrou sua chave PIX direta. Você pode doar instantaneamente usando a aba Solana Pay ao lado!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      );
    }

    final pixKey = _campaign.pixKey!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00BDAE).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BDAE).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pix_rounded, color: Color(0xFF00BDAE), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PIX Direto para a ONG',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.darkBG,
                      ),
                    ),
                    Text(
                      '100% do valor vai para a conta oficial do abrigo',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Campo com a chave PIX e botão copiar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    pixKey,
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.darkBG,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _copyPixKey(context, pixKey),
                  icon: const Icon(Icons.copy_rounded, color: Color(0xFF00BDAE), size: 20),
                  tooltip: 'Copiar Chave PIX',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Botão Já Fiz o PIX
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BDAE),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: _isRegisteringPix ? null : () => _confirmPixDonation(context, isDark),
            icon: _isRegisteringPix
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_circle_outline_rounded, size: 20),
            label: Text(
              _isRegisteringPix ? 'Registrando...' : 'Já realizei o PIX (Emitir Recibo)',
              style: const TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptsTab(bool isDark) {
    return FutureBuilder<List<ShelterDonationReceiptModel>>(
      future: _receiptsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final receipts = snapshot.data ?? [];

        if (receipts.isEmpty) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.pets_rounded,
                    size: 56,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Nenhuma doação registrada ainda',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.darkBG,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Você ainda não realizou doações para esta campanha.\nQualquer valor faz a diferença na vida dos nossos resgatados! 🐾',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => _tabController.animateTo(0),
                  icon: const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
                  label: const Text(
                    'Fazer Primeira Doação',
                    style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: _loadReceipts,
                  icon: const Icon(Icons.sync_rounded, size: 18, color: Color(0xFF10B981)),
                  label: const Text(
                    'Sincronizar transações da Blockchain',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: receipts.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Seus Comprovantes (${receipts.length})',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.darkBG,
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _loadReceipts,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.sync_rounded, size: 16, color: Color(0xFF10B981)),
                            const SizedBox(width: 4),
                            Text(
                              'Sincronizar',
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            if (index == receipts.length + 1) {
              return const MobileScrollPadding();
            }
            final receipt = receipts[index - 1];
            return _buildReceiptCard(receipt, isDark);
          },
        );
      },
    );
  }

  Widget _buildReceiptCard(ShelterDonationReceiptModel receipt, bool isDark) {
    final dateFormat = DateFormat("dd/MM/yyyy 'às' HH:mm");
    final dateStr = dateFormat.format(receipt.createdAt);

    final isSolana = receipt.paymentMethod == 'solana_pay';
    final methodColor = isSolana ? const Color(0xFF14F195) : const Color(0xFF00BDAE);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topo do Card: Data e Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 14, color: isDark ? Colors.white60 : Colors.black54),
                  const SizedBox(width: 6),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 13),
                    SizedBox(width: 4),
                    Text(
                      'Confirmado',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Linha de Valor e Método
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'R\$ ${receipt.amount.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.darkBG,
                    ),
                  ),
                  if (receipt.originalAmount != null && receipt.tokenSymbol != 'BRL') ...[
                    const SizedBox(height: 2),
                    Text(
                      '${receipt.originalAmount} ${receipt.tokenSymbol}',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 12,
                        color: methodColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              // Badge do Método
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: methodColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: methodColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSolana ? Icons.bolt_rounded : Icons.pix_rounded,
                      size: 14,
                      color: methodColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      receipt.paymentMethodLabel,
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: methodColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Informações do Doador / Pet
          if (receipt.donorName != null && receipt.donorName!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  if (receipt.donorPhoto != null && receipt.donorPhoto!.isNotEmpty)
                    ClipOval(
                      child: Image.network(
                        receipt.donorPhoto!,
                        width: 22,
                        height: 22,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.pets, size: 16),
                      ),
                    )
                  else
                    const Icon(Icons.pets, size: 16, color: AppColors.patasColor),
                  const SizedBox(width: 8),
                  Text(
                    'Doado em nome de: ',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  Text(
                    receipt.donorName!,
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.darkBG,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Link para Explorer (se for Solana)
          if (receipt.txSignature != null && receipt.txSignature!.isNotEmpty) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () {
                final sig = receipt.txSignature!;
                if (!sig.startsWith('simulated_')) {
                  final url = Uri.parse('https://explorer.solana.com/tx/$sig?cluster=devnet');
                  launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              child: Row(
                children: [
                  const Icon(Icons.link_rounded, size: 14, color: Color(0xFF9945FF)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Hash: ${receipt.txSignature}',
                      style: const TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 11,
                        color: Color(0xFF9945FF),
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
