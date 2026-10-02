import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/common_widgets/mobile_scroll_padding.dart';
import '../../solana/widgets/solana_pay_donation_tab.dart';
import '../models/donation_campaign_model.dart';

class PixDonationSheet extends StatefulWidget {
  final DonationCampaign campaign;
  final VoidCallback? onDonationCompleted;

  const PixDonationSheet({
    super.key,
    required this.campaign,
    this.onDonationCompleted,
  });

  static Future<bool?> show(
    BuildContext context, {
    required DonationCampaign campaign,
    VoidCallback? onDonationCompleted,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PixDonationSheet(
        campaign: campaign,
        onDonationCompleted: onDonationCompleted,
      ),
    );
  }

  @override
  State<PixDonationSheet> createState() => _PixDonationSheetState();
}

class _PixDonationSheetState extends State<PixDonationSheet> {
  int _activeTabIndex = 0; // 0 = Pix (Brasil), 1 = Solana Pay (Global)
  bool _donationMade = false;

  void _copyPixKey(BuildContext context, String key) {
    Clipboard.setData(ClipboardData(text: key));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Chave PIX copiada! Cole no app do seu banco para doar.',
                style: TextStyle(fontFamily: 'Fredoka', fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.teal.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final campaign = widget.campaign;
    final pix = campaign.pixKey ?? 'contato@ongpatas.org.br';

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (_donationMade) {
          widget.onDonationCompleted?.call();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
      padding: EdgeInsets.fromLTRB(
        24,
        14,
        24,
        MediaQuery.of(context).viewInsets.bottom +
            MobileScrollPadding.bottomInset(context),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Topo: Ícone e Título com Botão Fechar
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _activeTabIndex == 0
                        ? Colors.teal.withValues(alpha: isDark ? 0.25 : 0.12)
                        : const Color(0xFF9945FF).withValues(alpha: isDark ? 0.25 : 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _activeTabIndex == 0 ? Icons.pix_rounded : Icons.flash_on_rounded,
                    color: _activeTabIndex == 0 ? Colors.teal : const Color(0xFF9945FF),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _activeTabIndex == 0 ? 'Apoiar via PIX' : 'Apoiar via Solana Pay',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.darkBG,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        campaign.ongName ?? 'ONG Parceira Patas Acolhe',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Seletor de Método de Pagamento (Pix Brasil vs Solana Pay Global)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMethodTab(
                      index: 0,
                      label: 'PIX (Brasil)',
                      icon: Icons.pix_rounded,
                      activeColor: Colors.teal,
                      isDark: isDark,
                    ),
                  ),
                  Expanded(
                    child: _buildMethodTab(
                      index: 1,
                      label: 'Solana Pay (Global)',
                      icon: Icons.flash_on_rounded,
                      activeColor: const Color(0xFF9945FF),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 24),

            // Resumo da Campanha e Progresso
            Text(
              campaign.title,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 10),

            // Barra de Progresso
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: campaign.progressPercentage,
                minHeight: 10,
                backgroundColor:
                    isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  campaign.isGoalReached ? Colors.green : Colors.pinkAccent,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Arrecadado: ${campaign.formattedCurrent}',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: campaign.isGoalExceeded
                        ? const Color(0xFF10B981)
                        : (campaign.isGoalReached ? Colors.green : Colors.pinkAccent),
                  ),
                ),
                Text(
                  'Meta: ${campaign.formattedTarget}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
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
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: campaign.isGoalExceeded
                      ? const Color(0xFF10B981)
                      : (campaign.isGoalReached
                          ? Colors.green
                          : (isDark ? Colors.white70 : Colors.black54)),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Conteúdo Alternável (Pix vs Solana Pay)
            if (_activeTabIndex == 0) ...[
              // ABA 0: PIX TRADICIONAL
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.teal.withValues(alpha: isDark ? 0.3 : 0.4),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.vpn_key_rounded,
                            size: 16, color: Colors.teal),
                        const SizedBox(width: 6),
                        Text(
                          'Chave PIX (${campaign.pixKeyType?.toUpperCase() ?? 'DIRETA'}):',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.tealAccent : Colors.teal.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SelectableText(
                      pix,
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: () => _copyPixKey(context, pix),
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text(
                          'Copiar Chave PIX',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155).withValues(alpha: 0.3)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 18, color: AppColors.patasColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '100% do valor vai direto para a conta oficial da ONG. Você pode doar qualquer quantia — cada real faz a diferença!',
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.35,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // ABA 1: SOLANA PAY (GLOBAL & CRIPTO)
              SolanaPayDonationTab(
                campaignId: campaign.id,
                campaignTitle: campaign.title,
                ongName: campaign.ongName,
                solanaWallet: campaign.solanaWallet,
                isDark: isDark,
                onDonationConfirmed: (amountBrl) {
                  _donationMade = true;
                  widget.onDonationCompleted?.call();
                },
              ),
            ],

            const SizedBox(height: 14),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildMethodTab({
    required int index,
    required String label,
    required IconData icon,
    required Color activeColor,
    required bool isDark,
  }) {
    final isSelected = _activeTabIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _activeTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1E293B) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected
                  ? activeColor
                  : (isDark ? Colors.white54 : Colors.black45),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : AppColors.darkBG)
                    : (isDark ? Colors.white54 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
