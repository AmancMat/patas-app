import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/localization/localizations_ext.dart';
import '../../pets/models/pet_model.dart';
import '../models/pet_passport_model.dart';
import '../services/pet_passport_service.dart';
import 'pet_passport_detail_sheet.dart';

class PetPassportOnboardingDialog extends StatefulWidget {
  final Pet pet;
  final ValueChanged<PetPassport>? onMintCompleted;

  const PetPassportOnboardingDialog({
    super.key,
    required this.pet,
    this.onMintCompleted,
  });

  static Future<PetPassport?> show(
    BuildContext context, {
    required Pet pet,
    ValueChanged<PetPassport>? onMintCompleted,
  }) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    return showDialog<PetPassport>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 24 : 16,
          vertical: 24,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: PetPassportOnboardingDialog(
              pet: pet,
              onMintCompleted: onMintCompleted,
            ),
          ),
        ),
      ),
    );
  }

  @override
  State<PetPassportOnboardingDialog> createState() => _PetPassportOnboardingDialogState();
}

class _PetPassportOnboardingDialogState extends State<PetPassportOnboardingDialog> {
  bool _isMinting = false;
  String _mintStep = 'Preparando metadados...';
  bool _isStepInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isStepInitialized && !_isMinting) {
      _mintStep = context.t('passport.onboarding_minting_meta');
      _isStepInitialized = true;
    }
  }

  void _startMint() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (widget.pet.userId != currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.t('passport.onboarding_owner_only_error')),
          backgroundColor: Colors.redAccent,
        ),
      );
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isMinting = true;
      _mintStep = context.t('passport.onboarding_minting_query');
    });

    try {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() => _mintStep = context.t('passport.onboarding_minting_bubblegum'));
      }

      final passport = await PetPassportService.mintAndRegisterPassport(
        pet: widget.pet,
      );

      if (mounted) {
        setState(() => _mintStep = context.t('passport.onboarding_minting_merkle'));
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (mounted) {
        widget.onMintCompleted?.call(passport);
        Navigator.of(context).pop(passport);

        // Abre diretamente o passaporte oficial emitido
        PetPassportDetailSheet.show(context, passport: passport);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isMinting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.t('passport.onboarding_error', args: {'error': e.toString()})),
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

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF9945FF).withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9945FF).withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Topo com ícone e badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9945FF), Color(0xFF14F195)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14F195).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        context.t('passport.onboarding_tech_badge'),
                        style: const TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF14F195),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.t('passport.onboarding_title'),
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.darkBG,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Texto explicativo amigável
          Text(
            context.t('passport.onboarding_desc', args: {'name': widget.pet.name}),
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 16),

          // 3 Pilares com Ícones
          _buildPillarItem(
            icon: Icons.memory_rounded,
            color: const Color(0xFF14F195),
            title: context.t('passport.onboarding_pillar1_title'),
            description: context.t('passport.onboarding_pillar1_desc'),
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildPillarItem(
            icon: Icons.vaccines_rounded,
            color: const Color(0xFF9945FF),
            title: context.t('passport.onboarding_pillar2_title'),
            description: context.t('passport.onboarding_pillar2_desc'),
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildPillarItem(
            icon: Icons.energy_savings_leaf_rounded,
            color: const Color(0xFF38BDF8),
            title: context.t('passport.onboarding_pillar3_title'),
            description: context.t('passport.onboarding_pillar3_desc'),
            isDark: isDark,
          ),

          const SizedBox(height: 14),

          // Botão Didático de Tira-Dúvidas / O que é Blockchain
          InkWell(
            onTap: () => _showFaqDialog(context, isDark, widget.pet.name),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF9945FF).withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.help_outline_rounded,
                    color: Color(0xFF9945FF),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.t('passport.onboarding_faq_button'),
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFC084FC) : const Color(0xFF7E22CE),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Botão Principal ou Progresso de Emissão
          if (_isMinting) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF14F195).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF14F195),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _mintStep,
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.darkBG,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: _startMint,
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text(
                context.t('passport.onboarding_mint_button'),
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9945FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                context.t('passport.onboarding_not_now'),
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPillarItem({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.darkBG,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.black54,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFaqDialog(BuildContext context, bool isDark, String petName) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 650),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF9945FF).withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 25,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Topo do Modal
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9945FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.lightbulb_rounded,
                          color: Color(0xFF9945FF),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.t('passport.faq_title'),
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.darkBG,
                              ),
                            ),
                            Text(
                              context.t('passport.faq_subtitle'),
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark ? Colors.white60 : Colors.black54,
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Lista Scrollável de Perguntas e Respostas
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildFaqItem(
                          isDark: isDark,
                          icon: Icons.account_balance_rounded,
                          color: const Color(0xFF9945FF),
                          question: context.t('passport.faq_q1'),
                          answer: context.t('passport.faq_a1', args: {'name': petName}),
                        ),
                        const SizedBox(height: 12),
                        _buildFaqItem(
                          isDark: isDark,
                          icon: Icons.memory_rounded,
                          color: const Color(0xFF14F195),
                          question: context.t('passport.faq_q2'),
                          answer: context.t('passport.faq_a2', args: {'name': petName}),
                        ),
                        const SizedBox(height: 12),
                        _buildFaqItem(
                          isDark: isDark,
                          icon: Icons.vaccines_rounded,
                          color: const Color(0xFF38BDF8),
                          question: context.t('passport.faq_q3', args: {'name': petName}),
                          answer: context.t('passport.faq_a3'),
                        ),
                        const SizedBox(height: 12),
                        _buildFaqItem(
                          isDark: isDark,
                          icon: Icons.price_check_rounded,
                          color: const Color(0xFFF59E0B),
                          question: context.t('passport.faq_q4'),
                          answer: context.t('passport.faq_a4'),
                        ),
                      ],
                    ),
                  ),
                ),

                // Botão Fechar no Rodapé
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9945FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      context.t('passport.faq_back_btn'),
                      style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem({
    required bool isDark,
    required IconData icon,
    required Color color,
    required String question,
    required String answer,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  question,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.darkBG,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
