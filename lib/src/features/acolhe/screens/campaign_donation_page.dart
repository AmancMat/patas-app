import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../../../../app.dart';
import 'package:patas_web_app/src/localization/localizations_ext.dart';
import '../../../common_widgets/mobile_scroll_padding.dart';
import '../../../common_widgets/patas_essencial_app_bar.dart';
import '../../../utils/responsive_layout.dart';
import '../../../constants/app_colors.dart';
import '../../../models/active_account_model.dart';
import '../../../providers/active_account_provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReceipts());
    _receiptsFuture = Future.value([]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isOngOwner(BuildContext context) {
    try {
      final activeAccount =
          Provider.of<ActiveAccountProvider>(context, listen: false).activeAccount;
      if (activeAccount != null && activeAccount.type == AccountType.ong) {
        if (_campaign.ongId.isEmpty ||
            _campaign.ongId == activeAccount.id ||
            activeAccount.id == 'demo-ong-1') {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  void _loadReceipts() {
    if (!mounted) return;
    setState(() {
      final isOng = _isOngOwner(context);
      if (isOng) {
        _receiptsFuture = _shelterService.getAllCampaignDonations(_campaign.id);
      } else {
        _receiptsFuture =
            _shelterService.getUserCampaignDonations(_campaign.id).then((list) async {
          if (list.isEmpty) {
            String? petId;
            String? petName;
            String? petPhoto;
            if (mounted) {
              try {
                final petProvider =
                    Provider.of<ActivePetProvider>(context, listen: false);
                final pet = petProvider.activePet;
                petId = pet?.id;
                petName = pet?.name;
                petPhoto = pet?.photoUrl;
              } catch (_) {}
            }
            final effectiveWallet = (_campaign.solanaWallet != null &&
                    _campaign.solanaWallet!.trim().isNotEmpty)
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
      }
    });
  }

  void _openEditGoalDialog(BuildContext context, bool isDark) async {
    final messenger = ScaffoldMessenger.of(context);
    final successMsg = context.t('donation.adjust_goal_success');
    final controller = TextEditingController(
      text: _campaign.targetAmount.toStringAsFixed(2).replaceAll('.', ','),
    );

    final newTarget = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.flag_rounded, color: AppColors.patasColor, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.t('donation.adjust_goal_title'),
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.darkBG,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t('donation.adjust_goal_desc'),
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.darkBG,
              ),
              decoration: InputDecoration(
                prefixText: _campaign.goalType == 'money' ? 'R\$ ' : null,
                prefixStyle: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.patasColor),
                filled: true,
                fillColor:
                    isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.patasColor, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(
              context.t('donation.cancel'),
              style: TextStyle(
                fontFamily: 'Fredoka',
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.patasColor,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () {
              final raw = controller.text
                  .replaceAll('.', '')
                  .replaceAll(',', '.')
                  .trim();
              final parsed = double.tryParse(raw) ?? 0.0;
              Navigator.pop(ctx, parsed > 0 ? parsed : null);
            },
            child: const Text(
              'Salvar Meta',
              style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (newTarget != null && newTarget > 0) {
      if (!mounted) return;
      final success = await _shelterService.updateCampaignGoal(
        campaignId: _campaign.id,
        newTargetAmount: newTarget,
      );
      if (!mounted) return;
      if (success) {
        setState(() {
          _campaign = _campaign.copyWith(targetAmount: newTarget);
        });
        widget.onDonationUpdated?.call();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              successMsg,
              style:
                  const TextStyle(fontFamily: 'Fredoka', color: Colors.white),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _openAddExternalDonationDialog(BuildContext context, bool isDark) async {
    final messenger = ScaffoldMessenger.of(context);
    String getSuccessMsg(double a) => context.t('donation.add_external_donation_success',
        args: {'amount': a.toStringAsFixed(2).replaceAll('.', ',')});
    final amountController = TextEditingController();
    final donorController = TextEditingController();
    final noteController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.add_circle_outline_rounded,
                color: Color(0xFF10B981), size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.t('donation.add_external_donation_title'),
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.darkBG,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t('donation.add_external_donation_desc'),
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.darkBG,
                ),
                decoration: InputDecoration(
                  labelText: 'Valor Recebido *',
                  prefixText: 'R\$ ',
                  prefixStyle: const TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                  filled: true,
                  fillColor:
                      isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: donorController,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  color: isDark ? Colors.white : AppColors.darkBG,
                ),
                decoration: InputDecoration(
                  labelText:
                      context.t('donation.add_external_donation_donor_name'),
                  hintText: 'Ex: João Silva, Bazar Beneficente...',
                  filled: true,
                  fillColor:
                      isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 2,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  color: isDark ? Colors.white : AppColors.darkBG,
                ),
                decoration: InputDecoration(
                  labelText: context.t('donation.add_external_donation_note'),
                  hintText: 'Ex: Doação em mãos na feira de adoção...',
                  filled: true,
                  fillColor:
                      isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              context.t('donation.cancel'),
              style: TextStyle(
                fontFamily: 'Fredoka',
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () {
              final raw = amountController.text
                  .replaceAll('.', '')
                  .replaceAll(',', '.')
                  .trim();
              final parsed = double.tryParse(raw) ?? 0.0;
              if (parsed > 0) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text(
              'Lançar Doação',
              style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final raw = amountController.text
          .replaceAll('.', '')
          .replaceAll(',', '.')
          .trim();
      final amount = double.tryParse(raw) ?? 0.0;
      final donorName = donorController.text.trim().isNotEmpty
          ? donorController.text.trim()
          : null;
      final note =
          noteController.text.trim().isNotEmpty ? noteController.text.trim() : null;

      final success = await _shelterService.addExternalDonation(
        campaignId: _campaign.id,
        amount: amount,
        donorName: donorName,
        note: note,
      );

      if (!mounted) return;
      if (success) {
        setState(() {
          _campaign = _campaign.copyWith(
              currentAmount: _campaign.currentAmount + amount);
        });
        _loadReceipts();
        widget.onDonationUpdated?.call();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              getSuccessMsg(amount),
              style:
                  const TextStyle(fontFamily: 'Fredoka', color: Colors.white),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _toggleCampaignStatus(BuildContext ctx) async {
    final nextStatus = !_campaign.isActive;
    final success = await _shelterService.toggleCampaignStatus(
      campaignId: _campaign.id,
      isActive: nextStatus,
    );
    if (success && mounted) {
      setState(() {
        _campaign = _campaign.copyWith(isActive: nextStatus);
      });
      widget.onDonationUpdated?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextStatus
                ? context.t('donation.status_active')
                : context.t('donation.status_paused'),
            style:
                const TextStyle(fontFamily: 'Fredoka', color: Colors.white),
          ),
          backgroundColor:
              nextStatus ? const Color(0xFF10B981) : Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
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
              context.t('donation.confirm_pix_title'),
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
              context.t('donation.confirm_pix_desc'),
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
              context.t('donation.cancel'),
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
            child: Text(
              context.t('donation.register_donation'),
              style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmedAmount == null || confirmedAmount <= 0) return;
    if (!context.mounted) return;

    setState(() => _isRegisteringPix = true);

    final successMsg = context.t('donation.pix_registered_success', args: {'amount': confirmedAmount.toStringAsFixed(2).replaceAll('.', ',')});

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
                    successMsg,
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
        content: Row(
          children: [
            const Icon(Icons.copy_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.t('donation.pix_key_copied'),
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
    final isOng = _isOngOwner(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
      appBar: PatasEssencialAppBar(
        title: _campaign.title,
        subtitle: isOng
            ? 'Painel de Gestão da Campanha'
            : (_campaign.ongName ?? context.t('donation.default_subtitle')),
        leadingIcon: const Icon(Icons.volunteer_activism_rounded, color: AppColors.patasColor),
        showBackButton: true,
        maxWidth: 800,
      ),
      body: Column(
        children: [
          // Header da Campanha e TabBar contidos em 800px no centro da tela
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    _buildCampaignHeader(isDark),
                    const SizedBox(height: 12),
                    _buildCustomTabBar(isDark),
                  ],
                ),
              ),
            ),
          ),

          // Conteúdo das Abas preenchendo 100% da largura para capturar scroll em qualquer ponto da tela
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: isOng
                  ? [
                      _buildOngDashboardTab(isDark),
                      _buildOngDonorsTab(isDark),
                    ]
                  : [
                      _buildSupportTab(isDark),
                      _buildReceiptsTab(isDark),
                    ],
            ),
          ),
        ],
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
                      _campaign.ongName ?? context.t('donation.default_shelter'),
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
              // Badges de Prazo e Status
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  // Badge de Prazo
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _campaign.isExpired
                          ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                          : Colors.purpleAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _campaign.isExpired
                            ? const Color(0xFFEF4444).withValues(alpha: 0.35)
                            : Colors.purpleAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _campaign.isExpired ? Icons.timer_off_rounded : Icons.schedule_rounded,
                          size: 11,
                          color: _campaign.isExpired ? const Color(0xFFEF4444) : Colors.purpleAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _campaign.deadlineText,
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: _campaign.isExpired ? const Color(0xFFEF4444) : Colors.purpleAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge de Status da Meta
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      _campaign.goalStatusBadgeText,
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
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
                context.t('donation.raised_amount', args: {'current': _campaign.currentAmount.toStringAsFixed(2).replaceAll('.', ',')}),
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              Text(
                context.t('donation.goal_amount', args: {'target': _campaign.targetAmount.toStringAsFixed(2).replaceAll('.', ',')}),
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
    final isOng = _isOngOwner(context);

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
        tabs: isOng
            ? [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.insights_rounded,
                          size: 16, color: Colors.pinkAccent),
                      const SizedBox(width: 8),
                      Text(context.t('donation.tab_ong_dashboard')),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_long_rounded,
                          size: 16, color: Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      Text(context.t('donation.tab_ong_donors')),
                    ],
                  ),
                ),
              ]
            : [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite_rounded,
                          size: 16, color: Color(0xFFEF4444)),
                      const SizedBox(width: 8),
                      Text(context.t('donation.tab_support')),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_long_rounded,
                          size: 16, color: Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      Text(context.t('donation.tab_receipts')),
                    ],
                  ),
                ),
              ],
      ),
    );
  }

  Widget _buildCampaignClosedBanner(bool isDark) {
    String title;
    String desc;
    IconData icon;
    Color color;

    if (!_campaign.isActive) {
      title = context.t('donation.closed_banner_paused');
      desc = context.t('donation.closed_banner_paused_desc');
      icon = Icons.pause_circle_filled_rounded;
      color = Colors.orange;
    } else if (_campaign.isExpired) {
      title = context.t('donation.closed_banner_expired');
      desc = context.t('donation.closed_banner_expired_desc');
      icon = Icons.timer_off_rounded;
      color = const Color(0xFFEF4444);
    } else {
      title = context.t('donation.closed_banner_completed');
      desc = context.t('donation.closed_banner_completed_desc');
      icon = Icons.celebration_rounded;
      color = const Color(0xFF10B981);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
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
    final isAccepting = _campaign.isAcceptingDonations;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner se a campanha não estiver aceitando doações
              if (!isAccepting) _buildCampaignClosedBanner(isDark),

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
                        title: context.t('donation.method_pix'),
                        icon: Icons.pix_rounded,
                        color: const Color(0xFF00BDAE),
                        isSelected: _selectedPaymentMethodIndex == 0,
                        isDark: isDark,
                        onTap: () => setState(() => _selectedPaymentMethodIndex = 0),
                      ),
                    ),
                    Expanded(
                      child: _buildMethodButton(
                        title: context.t('donation.method_solana'),
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
                _buildPixSection(hasPix, isDark, isAccepting: isAccepting)
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
        ),
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

  Widget _buildPixSection(bool hasPix, bool isDark, {bool isAccepting = true}) {
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
              context.t('donation.pix_setting_up'),
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.darkBG,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.t('donation.pix_setting_up_desc'),
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
                      context.t('donation.pix_direct_shelter'),
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.darkBG,
                      ),
                    ),
                    Text(
                      context.t('donation.pix_direct_shelter_desc'),
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
                  tooltip: context.t('donation.copy_pix_key_tooltip'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Botão Já Fiz o PIX
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isAccepting ? const Color(0xFF00BDAE) : Colors.grey.shade400,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: (!isAccepting || _isRegisteringPix)
                ? null
                : () => _confirmPixDonation(context, isDark),
            icon: _isRegisteringPix
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Icon(
                    isAccepting ? Icons.check_circle_outline_rounded : Icons.lock_outline_rounded,
                    size: 20,
                  ),
            label: Text(
              _isRegisteringPix
                  ? context.t('donation.registering_pix')
                  : (!isAccepting
                      ? context.t('donation.closed_button_label')
                      : context.t('donation.already_sent_pix')),
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

  // ─────────────────────────────────────────────────────────────
  // 🏢 VISÃO EXCLUSIVA DA ONG: ABA 1 — DESEMPENHO & GRÁFICOS
  // ─────────────────────────────────────────────────────────────
  Widget _buildOngDashboardTab(bool isDark) {
    return FutureBuilder<List<ShelterDonationReceiptModel>>(
      future: _receiptsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: Colors.pinkAccent),
            ),
          );
        }

        final donations = snapshot.data ?? [];
        final now = DateTime.now();

        // Total arrecadado hoje
        final todayTotal = donations
            .where((r) =>
                r.createdAt.year == now.year &&
                r.createdAt.month == now.month &&
                r.createdAt.day == now.day)
            .fold(0.0, (sum, r) => sum + r.amount);

        // Falta arrecadar
        final remaining = (_campaign.targetAmount - _campaign.currentAmount)
            .clamp(0.0, double.infinity);

        // Doadores únicos
        final donorNames = donations
            .map((d) => (d.donorName ?? '').trim())
            .where((n) => n.isNotEmpty)
            .toSet();
        final donorsCount =
            donorNames.isNotEmpty ? donorNames.length : donations.length;

        // Média por doação
        final avgTicket = donations.isNotEmpty
            ? (_campaign.currentAmount / donations.length)
            : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Banner se a campanha não estiver aceitando doações
                  if (!_campaign.isAcceptingDonations) ...[
                    _buildCampaignClosedBanner(isDark),
                    const SizedBox(height: 14),
                  ],

                  // 1. Régua de 4 KPIs (Grade 2x2 no mobile conforme AGENTS.md, ou 1 Row no Desktop)
                  _buildOngKpisGrid(
                    isDark: isDark,
                    todayTotal: todayTotal,
                    remaining: remaining,
                    donorsCount: donorsCount,
                    avgTicket: avgTicket,
                  ),
                  const SizedBox(height: 16),

                  // 2. Gráfico 1: Evolução da Arrecadação nos Últimos 7 Dias
                  _buildWeeklyDonationChart(donations, isDark),
                  const SizedBox(height: 16),

                  // 3. Gráfico 2: Composição por Canal / Método de Doação
                  _buildPaymentMethodBreakdownChart(donations, isDark),
                  const SizedBox(height: 16),

                  // 4. Ações Rápidas de Gestão
                  _buildOngActionButtonsCard(isDark),
                  const SizedBox(height: 16),

                  // 5. Canais de Recebimento da ONG (Chave PIX e Carteira Solana da ONG)
                  _buildOngReceivingChannelsCard(isDark),

                  const MobileScrollPadding(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOngKpisGrid({
    required bool isDark,
    required double todayTotal,
    required double remaining,
    required int donorsCount,
    required double avgTicket,
  }) {
    final kpi1 = _buildKpiCard(
      title: context.t('donation.ong_kpi_total_raised'),
      value:
          'R\$ ${_campaign.currentAmount.toStringAsFixed(2).replaceAll('.', ',')}',
      subtitle: '${_campaign.progressPercentInt}% da meta',
      icon: Icons.savings_rounded,
      color: const Color(0xFF10B981),
      isDark: isDark,
    );

    final kpi2 = _buildKpiCard(
      title: context.t('donation.kpi_remaining'),
      value: remaining <= 0
          ? 'Batida! 🎉'
          : 'R\$ ${remaining.toStringAsFixed(2).replaceAll('.', ',')}',
      subtitle: remaining <= 0 ? 'Meta 100% atingida' : 'Restante para a meta',
      icon: Icons.flag_rounded,
      color: remaining <= 0 ? const Color(0xFF10B981) : Colors.purpleAccent,
      isDark: isDark,
    );

    final kpi3 = _buildKpiCard(
      title: context.t('donation.ong_kpi_raised_today'),
      value: 'R\$ ${todayTotal.toStringAsFixed(2).replaceAll('.', ',')}',
      subtitle: todayTotal > 0 ? 'Entradas hoje' : 'Sem doações hoje',
      icon: Icons.today_rounded,
      color: const Color(0xFF00BDAE),
      isDark: isDark,
    );

    final kpi4 = _buildKpiCard(
      title: context.t('donation.ong_kpi_donors'),
      value: '$donorsCount',
      subtitle: avgTicket > 0
          ? 'Média R\$ ${avgTicket.toStringAsFixed(0)}'
          : 'Apoiadores totais',
      icon: Icons.people_alt_rounded,
      color: Colors.pinkAccent,
      isDark: isDark,
    );

    if (context.isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: kpi1),
              const SizedBox(width: 10),
              Expanded(child: kpi2),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: kpi3),
              const SizedBox(width: 10),
              Expanded(child: kpi4),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: kpi1),
        const SizedBox(width: 12),
        Expanded(child: kpi2),
        const SizedBox(width: 12),
        Expanded(child: kpi3),
        const SizedBox(width: 12),
        Expanded(child: kpi4),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 11.5,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
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
            subtitle,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 📈 GRÁFICO 1: EVOLUÇÃO DOS ÚLTIMOS 7 DIAS
  // ─────────────────────────────────────────────────────────────
  Widget _buildWeeklyDonationChart(
      List<ShelterDonationReceiptModel> donations, bool isDark) {
    final now = DateTime.now();
    final dayNames = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    final List<Map<String, dynamic>> daysData = [];

    double totalWeekly = 0.0;
    double maxAmount = 1.0;

    for (int i = 6; i >= 0; i--) {
      final targetDate =
          DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final dayTotal = donations
          .where((r) =>
              r.createdAt.year == targetDate.year &&
              r.createdAt.month == targetDate.month &&
              r.createdAt.day == targetDate.day)
          .fold(0.0, (sum, r) => sum + r.amount);

      totalWeekly += dayTotal;
      if (dayTotal > maxAmount) maxAmount = dayTotal;

      final isToday = i == 0;
      final weekdayIndex = targetDate.weekday - 1;
      final label = isToday ? 'Hoje' : dayNames[weekdayIndex.clamp(0, 6)];

      daysData.add({
        'date': targetDate,
        'label': label,
        'amount': dayTotal,
        'isToday': isToday,
      });
    }

    final dailyAvg = totalWeekly / 7;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.trending_up_rounded,
                            size: 18, color: Colors.pinkAccent),
                        const SizedBox(width: 8),
                        Text(
                          context.t('donation.chart_weekly_evolution'),
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.darkBG,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${context.t('donation.chart_daily_avg')}: R\$ ${dailyAvg.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.pinkAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.pinkAccent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'R\$ ${totalWeekly.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.pinkAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Área das 7 Barras do Gráfico
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: daysData.map((d) {
                final double amount = d['amount'] as double;
                final bool isToday = d['isToday'] as bool;
                final String label = d['label'] as String;

                final double barHeight = maxAmount > 0
                    ? ((amount / maxAmount) * 96).clamp(8.0, 96.0)
                    : 8.0;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            amount > 0
                                ? 'R\$ ${amount.toStringAsFixed(0)}'
                                : '-',
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: 10,
                              fontWeight: amount > 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isToday
                                  ? Colors.pinkAccent
                                  : (isDark ? Colors.white60 : Colors.black45),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          height: barHeight,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: amount > 0
                                ? LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: isToday
                                        ? [
                                            Colors.pinkAccent,
                                            Colors.purpleAccent
                                          ]
                                        : [
                                            const Color(0xFF00BDAE),
                                            const Color(0xFF10B981)
                                          ],
                                  )
                                : null,
                            color: amount == 0
                                ? (isDark
                                    ? Colors.white10
                                    : Colors.grey.shade200)
                                : null,
                            borderRadius: BorderRadius.circular(8),
                            border: isToday
                                ? Border.all(
                                    color: Colors.pinkAccent, width: 1.5)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 11,
                            fontWeight:
                                isToday ? FontWeight.bold : FontWeight.normal,
                            color: isToday
                                ? Colors.pinkAccent
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 🥧 GRÁFICO 2: COMPOSIÇÃO POR CANAL DE DOAÇÃO
  // ─────────────────────────────────────────────────────────────
  Widget _buildPaymentMethodBreakdownChart(
      List<ShelterDonationReceiptModel> donations, bool isDark) {
    double pixTotal = donations
        .where((d) => d.paymentMethod == 'pix')
        .fold(0.0, (sum, d) => sum + d.amount);
    int pixCount = donations.where((d) => d.paymentMethod == 'pix').length;

    double solanaTotal = donations
        .where((d) => d.paymentMethod == 'solana_pay')
        .fold(0.0, (sum, d) => sum + d.amount);
    int solanaCount =
        donations.where((d) => d.paymentMethod == 'solana_pay').length;

    double presencialTotal = donations
        .where((d) =>
            d.paymentMethod == 'presencial' || d.paymentMethod == 'offline')
        .fold(0.0, (sum, d) => sum + d.amount);
    int presencialCount = donations
        .where((d) =>
            d.paymentMethod == 'presencial' || d.paymentMethod == 'offline')
        .length;

    double total = pixTotal + solanaTotal + presencialTotal;
    if (total == 0 && _campaign.currentAmount > 0) {
      pixTotal = _campaign.currentAmount;
      total = _campaign.currentAmount;
      pixCount = 1;
    }

    final double pixPct = total > 0 ? (pixTotal / total) : 0.0;
    final double solanaPct = total > 0 ? (solanaTotal / total) : 0.0;
    final double presencialPct = total > 0 ? (presencialTotal / total) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.pie_chart_rounded,
                      size: 18, color: Color(0xFF00BDAE)),
                  const SizedBox(width: 8),
                  Text(
                    context.t('donation.chart_payment_methods'),
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.darkBG,
                    ),
                  ),
                ],
              ),
              Text(
                '${donations.length} doações',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Barra Horizontal Segmentada Proporcional
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: total > 0
                  ? Row(
                      children: [
                        if (pixPct > 0)
                          Expanded(
                            flex: (pixPct * 1000).toInt().clamp(1, 1000),
                            child: Container(color: const Color(0xFF00BDAE)),
                          ),
                        if (solanaPct > 0)
                          Expanded(
                            flex: (solanaPct * 1000).toInt().clamp(1, 1000),
                            child: Container(color: const Color(0xFF8B5CF6)),
                          ),
                        if (presencialPct > 0)
                          Expanded(
                            flex: (presencialPct * 1000).toInt().clamp(1, 1000),
                            child: Container(color: const Color(0xFFF59E0B)),
                          ),
                      ],
                    )
                  : Container(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // 3 Cards de Breakdown por Canal
          Row(
            children: [
              Expanded(
                child: _buildMethodStatCard(
                  title: 'PIX Direto',
                  amount: pixTotal,
                  percentage: pixPct * 100,
                  count: pixCount,
                  color: const Color(0xFF00BDAE),
                  icon: Icons.pix_rounded,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMethodStatCard(
                  title: 'Solana (USDC)',
                  amount: solanaTotal,
                  percentage: solanaPct * 100,
                  count: solanaCount,
                  color: const Color(0xFF8B5CF6),
                  icon: Icons.flash_on_rounded,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMethodStatCard(
                  title: 'Presencial',
                  amount: presencialTotal,
                  percentage: presencialPct * 100,
                  count: presencialCount,
                  color: const Color(0xFFF59E0B),
                  icon: Icons.storefront_rounded,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMethodStatCard({
    required String title,
    required double amount,
    required double percentage,
    required int count,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'R\$ ${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.darkBG,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${percentage.toStringAsFixed(0)}% • $count op.',
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ⚙️ AÇÕES DE GESTÃO DA ONG
  // ─────────────────────────────────────────────────────────────
  Widget _buildOngActionButtonsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded,
                  size: 18, color: AppColors.patasColor),
              const SizedBox(width: 8),
              Text(
                context.t('donation.quick_actions_title'),
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.darkBG,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.patasColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () => _openEditGoalDialog(context, isDark),
                  icon: const Icon(Icons.flag_rounded, size: 16),
                  label: Text(
                    context.t('donation.adjust_goal_btn'),
                    style: const TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () =>
                      _openAddExternalDonationDialog(context, isDark),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                  label: Text(
                    context.t('donation.add_external_donation_btn'),
                    style: const TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    side: BorderSide(
                      color: _campaign.isActive
                          ? Colors.orange
                          : const Color(0xFF10B981),
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _toggleCampaignStatus(context),
                  icon: Icon(
                    _campaign.isActive
                        ? Icons.pause_circle_rounded
                        : Icons.play_circle_rounded,
                    size: 16,
                    color: _campaign.isActive
                        ? Colors.orange
                        : const Color(0xFF10B981),
                  ),
                  label: Text(
                    _campaign.isActive
                        ? context.t('donation.pause_campaign')
                        : context.t('donation.resume_campaign'),
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _campaign.isActive
                          ? Colors.orange
                          : const Color(0xFF10B981),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    side: const BorderSide(color: Colors.pinkAccent),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _shareCampaign,
                  icon: const Icon(Icons.share_rounded,
                      size: 16, color: Colors.pinkAccent),
                  label: Text(
                    context.t('donation.share_campaign_btn'),
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.pinkAccent,
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

  // ─────────────────────────────────────────────────────────────
  // 💳 CANAIS DE RECEBIMENTO DA ONG
  // ─────────────────────────────────────────────────────────────
  Widget _buildOngReceivingChannelsCard(bool isDark) {
    final hasPix = _campaign.pixKey != null && _campaign.pixKey!.isNotEmpty;
    final solanaWallet = (_campaign.solanaWallet != null &&
            _campaign.solanaWallet!.trim().isNotEmpty)
        ? _campaign.solanaWallet!.trim()
        : SolanaPayService.defaultTreasuryWallet;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  size: 18, color: Color(0xFF00BDAE)),
              const SizedBox(width: 8),
              Text(
                context.t('donation.receiving_channels_title'),
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.darkBG,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            context.t('donation.receiving_channels_desc'),
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 14),

          // Canal PIX
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF00BDAE)
                  .withValues(alpha: isDark ? 0.12 : 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFF00BDAE).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.pix_rounded,
                    size: 20, color: Color(0xFF00BDAE)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chave PIX Cadastrada',
                        style: TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF00BDAE),
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        hasPix ? _campaign.pixKey! : 'Não informada na criação',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.darkBG,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (hasPix)
                  IconButton(
                    icon: const Icon(Icons.copy_rounded,
                        size: 16, color: Color(0xFF00BDAE)),
                    onPressed: () => _copyPixKey(context, _campaign.pixKey!),
                    tooltip: 'Copiar Chave PIX',
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Canal Solana Pay
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6)
                  .withValues(alpha: isDark ? 0.12 : 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.flash_on_rounded,
                    size: 20, color: Color(0xFF8B5CF6)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Carteira Solana (USDC)',
                        style: TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF8B5CF6),
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${solanaWallet.substring(0, math.min(10, solanaWallet.length))}...${solanaWallet.substring(math.max(0, solanaWallet.length - 8))}',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.darkBG,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded,
                      size: 16, color: Color(0xFF8B5CF6)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: solanaWallet));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Carteira Solana copiada!'),
                        backgroundColor: Color(0xFF8B5CF6),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  tooltip: 'Copiar Endereço',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _shareCampaign() {
    final text =
        'Ajude a causa "${_campaign.title}" da ${_campaign.ongName ?? "nossa ONG"} no Patas! Apoie com PIX ou cripto.';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.t('donation.campaign_link_copied')),
        backgroundColor: Colors.pinkAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 📋 ABA 2 DA ONG: EXTRATO COMPLETO DE DOADORES
  // ─────────────────────────────────────────────────────────────
  Widget _buildOngDonorsTab(bool isDark) {
    return FutureBuilder<List<ShelterDonationReceiptModel>>(
      future: _receiptsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.pinkAccent));
        }

        final receipts = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.t('donation.donations_received_title',
                              args: {'count': receipts.length.toString()}),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.sync_rounded,
                                    size: 16, color: Color(0xFF10B981)),
                                const SizedBox(width: 4),
                                Text(
                                  context.t('donation.sync_btn'),
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (receipts.isEmpty)
                    _buildReceiptsEmptyState(isDark, true)
                  else
                    ...receipts.map((receipt) => _buildReceiptCard(receipt, isDark)),
                  const MobileScrollPadding(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 👤 ABA 2 DO DOADOR COMUM: SEUS COMPROVANTES
  // ─────────────────────────────────────────────────────────────
  Widget _buildReceiptsTab(bool isDark) {
    return FutureBuilder<List<ShelterDonationReceiptModel>>(
      future: _receiptsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final receipts = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.t('donation.your_receipts',
                              args: {'count': receipts.length.toString()}),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.sync_rounded,
                                    size: 16, color: Color(0xFF10B981)),
                                const SizedBox(width: 4),
                                Text(
                                  context.t('donation.sync_btn'),
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (receipts.isEmpty)
                    _buildReceiptsEmptyState(isDark, false)
                  else
                    ...receipts.map((receipt) => _buildReceiptCard(receipt, isDark)),
                  const MobileScrollPadding(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceiptsEmptyState(bool isDark, bool isOng) {
    return Container(
      padding: const EdgeInsets.all(28),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
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
            child: Icon(
              isOng ? Icons.volunteer_activism_rounded : Icons.pets_rounded,
              size: 48,
              color: isOng ? Colors.pinkAccent : const Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isOng
                ? context.t('donation.no_ong_donations_title')
                : context.t('donation.no_receipts_title'),
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.darkBG,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isOng
                ? context.t('donation.no_ong_donations_desc')
                : context.t('donation.no_receipts_desc'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          if (isOng)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => _openAddExternalDonationDialog(context, isDark),
              icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 18),
              label: Text(
                context.t('donation.add_external_donation_btn'),
                style: const TextStyle(
                    fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: Colors.white),
              ),
            )
          else ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => _tabController.animateTo(0),
              icon: const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
              label: Text(
                context.t('donation.make_first_donation'),
                style: const TextStyle(
                    fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _loadReceipts,
              icon: const Icon(Icons.sync_rounded, size: 18, color: Color(0xFF10B981)),
              label: Text(
                context.t('donation.sync_blockchain_txs'),
                style: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReceiptCard(ShelterDonationReceiptModel receipt, bool isDark) {
    final dateFormat = DateFormat("dd/MM/yyyy 'às' HH:mm");
    final dateStr = dateFormat.format(receipt.createdAt);

    final isSolana = receipt.paymentMethod == 'solana_pay';
    final isPresencial = receipt.paymentMethod == 'presencial' || receipt.paymentMethod == 'offline';
    final methodColor = isSolana
        ? const Color(0xFF14F195)
        : (isPresencial ? Colors.purpleAccent : const Color(0xFF00BDAE));
    final methodLabel = isPresencial
        ? context.t('donation.method_presencial')
        : receipt.paymentMethodLabel;
    final methodIcon = isSolana
        ? Icons.bolt_rounded
        : (isPresencial ? Icons.volunteer_activism_rounded : Icons.pix_rounded);

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
                      methodIcon,
                      size: 14,
                      color: methodColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      methodLabel,
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
                    context.t('donation.donated_in_name_of'),
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
