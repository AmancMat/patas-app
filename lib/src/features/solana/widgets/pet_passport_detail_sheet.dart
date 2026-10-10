import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/localization/localizations_ext.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/features/health/models/vaccine_model.dart';
import 'package:patas_web_app/src/features/health/services/health_service.dart';
import '../models/pet_passport_model.dart';
import '../services/pet_passport_service.dart';
import '../services/solana_pay_service.dart';

class PetPassportDetailSheet extends StatefulWidget {
  final PetPassport passport;
  final bool isOwner;

  const PetPassportDetailSheet({
    super.key,
    required this.passport,
    this.isOwner = true,
  });

  static Future<void> show(BuildContext context, {required PetPassport passport, bool isOwner = true}) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    if (isDesktop) {
      return showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: PetPassportDetailSheet(passport: passport, isOwner: isOwner),
            ),
          ),
        ),
      );
    } else {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        enableDrag: true,
        builder: (context) => PetPassportDetailSheet(passport: passport, isOwner: isOwner),
      );
    }
  }

  @override
  State<PetPassportDetailSheet> createState() => _PetPassportDetailSheetState();
}

class _PetPassportDetailSheetState extends State<PetPassportDetailSheet> {
  bool _isClosing = false;
  String? _copiedLabel;
  Timer? _copiedTimer;
  late Future<List<PetVaccine>> _vaccinesFuture;
  final HealthService _healthService = HealthService();

  @override
  void initState() {
    super.initState();
    _vaccinesFuture = _healthService.getVaccines(widget.passport.petId);
  }

  @override
  void dispose() {
    _copiedTimer?.cancel();
    super.dispose();
  }

  void _dismiss() {
    if (_isClosing || !mounted) return;
    _isClosing = true;
    Navigator.of(context).pop();
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _copiedTimer?.cancel();
    setState(() {
      _copiedLabel = label;
    });
    _copiedTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _copiedLabel = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final passport = widget.passport;

    return DefaultTabController(
      length: 3,
      child: Container(
        constraints: isDesktop
            ? const BoxConstraints(maxHeight: 740)
            : BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: isDesktop
              ? BorderRadius.circular(28)
              : const BorderRadius.vertical(top: Radius.circular(28)),
          border: isDesktop
              ? Border.all(
                  color: const Color(0xFF14F195).withValues(alpha: 0.35),
                  width: 1.5,
                )
              : null,
          boxShadow: isDesktop
              ? [
                  BoxShadow(
                    color: const Color(0xFF14F195).withValues(alpha: 0.12),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle interativo (Mobile)
            if (!isDesktop)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) {
                  if (details.primaryDelta != null && details.primaryDelta! > 3) {
                    _dismiss();
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 14, bottom: 6),
                  color: Colors.transparent,
                  child: Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white30 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),

            // Cabeçalho Fixo do Passaporte Oficial
            Padding(
              padding: EdgeInsets.fromLTRB(20, isDesktop ? 18 : 6, 20, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF9945FF).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF9945FF), Color(0xFF14F195)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.t('passport.sheet_header_system'),
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: 10,
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF14F195),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.t('passport.sheet_header_sovereign', args: {'name': passport.petName}),
                            style: const TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14F195).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF14F195).withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Text(
                        'DEVNET',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF14F195),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Seletor de Abas Oficial do Patas (Conforme AGENTS.md)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  indicator: BoxDecoration(
                    color: const Color(0xFF9945FF),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF9945FF).withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
                  labelStyle: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.badge_rounded, size: 16),
                          const SizedBox(width: 6),
                          Text(context.t('passport.tab_identity')),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.vaccines_rounded, size: 16),
                          const SizedBox(width: 6),
                          Text(context.t('passport.tab_vaccines')),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.hub_rounded, size: 16),
                          const SizedBox(width: 6),
                          Text(context.t('passport.tab_blockchain')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Banner Animado de Confirmação de Cópia (Visível em toda a tela)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              height: _copiedLabel != null ? 36 : 0,
              margin: EdgeInsets.only(
                left: 20,
                right: 20,
                top: _copiedLabel != null ? 4 : 0,
                bottom: _copiedLabel != null ? 4 : 0,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _copiedLabel != null
                  ? Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.t('passport.copied_to_clipboard', args: {'label': _copiedLabel ?? ''}),
                            style: const TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),

            // Conteúdo Rolável das 3 Abas
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is OverscrollNotification) {
                    if (notification.overscroll < -12) {
                      _dismiss();
                      return true;
                    }
                  } else if (notification is ScrollUpdateNotification) {
                    if (notification.metrics.pixels <= 0 &&
                        (notification.scrollDelta ?? 0) < -12) {
                      _dismiss();
                      return true;
                    }
                  }
                  return false;
                },
                child: TabBarView(
                  children: [
                    _buildIdentityTab(context, passport, isDark, isDesktop),
                    _buildVaccinesTab(context, passport, isDark, isDesktop),
                    _buildBlockchainTab(context, passport, isDark, isDesktop),
                  ],
                ),
              ),
            ),

            // Rodapé Fixo com Botão Fechar
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                isDesktop ? 16 : (MediaQuery.of(context).viewInsets.bottom + 12),
              ),
              child: Center(
                child: TextButton.icon(
                  onPressed: _dismiss,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                  label: Text(
                    context.t('passport.close_passport'),
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🪪 ABA 1: Identificação Oficial do Pet
  Widget _buildIdentityTab(
    BuildContext context,
    PetPassport passport,
    bool isDark,
    bool isDesktop,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cartão Biométrico
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto do animal com moldura holográfica
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF14F195), width: 2.5),
                    image: passport.photoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(passport.photoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: passport.photoUrl == null
                      ? const Icon(Icons.pets_rounded, size: 36, color: Color(0xFF14F195))
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        passport.petName,
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.darkBG,
                        ),
                      ),
                      Text(
                        '${_formatSpecies(context, passport.species)} • ${_formatBreed(context, passport.breed)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (passport.gender != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.white12 : Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _formatGender(context, passport.gender),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              context.t('passport.status_active'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Microchip ISO 11784
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: passport.isPhysicalMicrochip
                    ? const Color(0xFF14F195).withValues(alpha: 0.35)
                    : const Color(0xFFF59E0B).withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: passport.isPhysicalMicrochip
                            ? const Color(0xFF14F195).withValues(alpha: 0.15)
                            : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.memory_rounded,
                        color: passport.isPhysicalMicrochip
                            ? const Color(0xFF14F195)
                            : const Color(0xFFF59E0B),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  context.t('passport.chip_title'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: passport.isPhysicalMicrochip
                                      ? const Color(0xFF14F195).withValues(alpha: 0.15)
                                      : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: passport.isPhysicalMicrochip
                                        ? const Color(0xFF14F195).withValues(alpha: 0.3)
                                        : const Color(0xFFF59E0B).withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Text(
                                  passport.isPhysicalMicrochip ? context.t('passport.chip_physical_badge') : context.t('passport.chip_provisional_badge'),
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: passport.isPhysicalMicrochip
                                        ? const Color(0xFF14F195)
                                        : const Color(0xFFF59E0B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          SelectableText(
                            passport.microchipNumber,
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: passport.isPhysicalMicrochip
                                  ? const Color(0xFF14F195)
                                  : const Color(0xFFF59E0B),
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _copiedLabel == 'Microchip'
                            ? Icons.check_circle_rounded
                            : Icons.copy_rounded,
                        size: 18,
                        color: _copiedLabel == 'Microchip'
                            ? const Color(0xFF14F195)
                            : (passport.isPhysicalMicrochip
                                ? const Color(0xFF14F195)
                                : const Color(0xFFF59E0B)),
                      ),
                      tooltip: context.t('passport.copy_microchip_tooltip'),
                      onPressed: () => _copyToClipboard(context, passport.microchipNumber, 'Microchip'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _showMicrochipExplanationDialog(context, isDark, passport.petName),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: isDark ? Colors.amber.shade300 : Colors.amber.shade800,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            passport.isPhysicalMicrochip
                                ? context.t('passport.chip_implanted_hint')
                                : context.t('passport.chip_provisional_hint'),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                              decoration: TextDecoration.underline,
                              decorationStyle: TextDecorationStyle.dotted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // QR Code Fiscalizatório Oficial
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code_2_rounded, size: 18, color: Color(0xFF9945FF)),
                    const SizedBox(width: 6),
                    Text(
                      context.t('passport.qr_title'),
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.darkBG,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF14F195), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF14F195).withValues(alpha: 0.15),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: passport.explorerTxUrl,
                    version: QrVersions.auto,
                    size: 130.0,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF0F172A),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.t('passport.qr_hint'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Dados do Tutor Custodiante
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildDataRow(context.t('passport.custodian_tutor'), passport.ownerName, isDark),
                const SizedBox(height: 8),
                _buildDataRow(
                  context.t('passport.solana_wallet_label'),
                  '${passport.ownerWallet.substring(0, 6)}...${passport.ownerWallet.substring(passport.ownerWallet.length - 6)}',
                  isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// 💉 ABA 2: Caderneta de Vacinas On-Chain (Integrada ao Patas Saúde)
  Widget _buildVaccinesTab(
    BuildContext context,
    PetPassport passport,
    bool isDark,
    bool isDesktop,
  ) {
    return FutureBuilder<List<PetVaccine>>(
      future: _vaccinesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF14F195),
              ),
            ),
          );
        }

        final vaccines = snapshot.data ?? [];

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner de Certificação Sanitária
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF064E3B), const Color(0xFF022C22)]
                        : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_rounded, color: Color(0xFF10B981), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.t('passport.vaccines_status_compliant'),
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF065F46),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.t('passport.vaccines_status_desc'),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white70 : const Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Text(
                context.t('passport.vaccines_onchain_title'),
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.darkBG,
                ),
              ),
              const SizedBox(height: 10),

              if (vaccines.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.vaccines_outlined,
                        size: 38,
                        color: isDark ? Colors.white38 : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.t('passport.vaccines_none_title'),
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.t('passport.vaccines_none_desc'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14F195).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          passport.vaccineStatus,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF14F195),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: vaccines.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final vax = vaccines[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9945FF).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.vaccines_rounded,
                              color: Color(0xFF9945FF),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vax.name,
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : AppColors.darkBG,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  context.t('passport.applied_at', args: {'date': DateFormat('dd/MM/yyyy').format(vax.applicationDate)}),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF14F195).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF14F195)),
                                const SizedBox(width: 4),
                                Text(
                                  context.t('passport.onchain_badge'),
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF14F195),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              const SizedBox(height: 12),

              // Nota de Atualização On-Chain
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sync_rounded, color: Color(0xFF10B981), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.t('passport.vaccines_auto_sync_note'),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.black87,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// ⛓️ ABA 3: Blockchain & Auditoria (Solana State Compression / Metaplex Bubblegum)
  Widget _buildBlockchainTab(
    BuildContext context,
    PetPassport passport,
    bool isDark,
    bool isDesktop,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card de Protocolo Web3
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E1065), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF9945FF).withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14F195).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.hub_rounded, color: Color(0xFF14F195), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Solana State Compression',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.t('passport.protocol_bubblegum'),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14F195).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield_rounded, size: 12, color: Color(0xFF14F195)),
                      const SizedBox(width: 4),
                      Text(
                        context.t('passport.auditable_badge'),
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF14F195),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Tabela de Dados Criptográficos
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                _buildCopyableRow(
                  context,
                  label: context.t('passport.asset_id_label'),
                  value: passport.cNftAssetId,
                  isDark: isDark,
                ),
                const Divider(height: 18),
                _buildCopyableRow(
                  context,
                  label: context.t('passport.merkle_tree_label'),
                  value: passport.merkleTreeAddress,
                  isDark: isDark,
                ),
                if (passport.txSignature != null) ...[
                  const Divider(height: 18),
                  _buildCopyableRow(
                    context,
                    label: context.t('passport.tx_sig_label'),
                    value: passport.txSignature!,
                    isDark: isDark,
                  ),
                ],
                const Divider(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.t('passport.leaf_index_label'),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    Text(
                      '#${passport.leafIndex}',
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF14F195),
                      ),
                    ),
                  ],
                ),
                if (passport.blockSlot != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.t('passport.block_slot_label'),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      Text(
                        'Slot ${passport.blockSlot}',
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.darkBG,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Botão Principal: Abrir no Solana Explorer
          ElevatedButton.icon(
            onPressed: () => SolanaPayService.openExplorer(address: passport.merkleTreeAddress),
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: Text(
              context.t('passport.audit_explorer_btn'),
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

          // Botão Secundário: Prova de Merkle
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: Color(0xFF14F195), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          context.t('passport.merkle_proof_valid'),
                          style: TextStyle(fontFamily: 'Fredoka', fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFF0F172A),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            icon: const Icon(Icons.fact_check_rounded, size: 16, color: Color(0xFF14F195)),
            label: Text(
              context.t('passport.verify_proof_btn'),
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF14F195),
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF14F195)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),

          if (widget.isOwner) ...[
            const SizedBox(height: 12),

            // Botão Secundário: Revogar / Queimar Passaporte (Burn cNFT / Controle Soberano - Apenas Tutor Dono)
            Center(
              child: TextButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: Row(
                      children: [
                        const Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          context.t('passport.burn_dialog_title'),
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.darkBG,
                          ),
                        ),
                      ],
                    ),
                    content: Text(
                      context.t('passport.burn_dialog_content', args: {'name': passport.petName}),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(
                          context.t('passport.burn_dialog_cancel'),
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          context.t('passport.burn_dialog_confirm'),
                          style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await PetPassportService.burnPassport(passport.petId, petName: passport.petName);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.t('passport.burn_success_snackbar')),
                        backgroundColor: Colors.orangeAccent,
                      ),
                    );
                    _dismiss();
                  }
                }
              },
              icon: const Icon(Icons.local_fire_department_rounded, size: 16, color: Colors.orangeAccent),
              label: Text(
                context.t('passport.burn_button_label'),
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 12,
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatSpecies(BuildContext context, String species) {
    final lower = species.toLowerCase().trim();
    if (lower.contains('felin') || lower.contains('gato') || lower.contains('cat')) {
      return context.t('species.feline');
    }
    if (lower.contains('canin') || lower.contains('cão') || lower.contains('cao') || lower.contains('cachorro') || lower.contains('dog')) {
      return context.t('species.canine');
    }
    return species;
  }

  String _formatGender(BuildContext context, String? gender) {
    if (gender == null || gender.trim().isEmpty) return '';
    final lower = gender.toLowerCase().trim();
    if (lower.contains('fêm') || lower.contains('fem') || lower == 'f') {
      return context.t('gender.female');
    }
    if (lower.contains('mach') || lower.contains('masc') || lower.contains('male') || lower == 'm') {
      return context.t('gender.male');
    }
    return gender;
  }

  String _formatBreed(BuildContext context, String breed) {
    final lower = breed.toLowerCase().trim();
    if (lower == 'srd' || lower.contains('sem raça') || lower.contains('sem raca') || lower.contains('mixed')) {
      return context.t('breed.srd');
    }
    return breed;
  }

  Widget _buildCopyableRow(
    BuildContext context, {
    required String label,
    required String value,
    required bool isDark,
  }) {
    final displayValue = value.length > 24
        ? '${value.substring(0, 10)}...${value.substring(value.length - 8)}'
        : value;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 2),
              SelectableText(
                displayValue,
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.darkBG,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            _copiedLabel == label
                ? Icons.check_circle_rounded
                : Icons.copy_rounded,
            size: 16,
            color: const Color(0xFF14F195),
          ),
          tooltip: 'Copiar $label',
          onPressed: () => _copyToClipboard(context, value, label),
        ),
      ],
    );
  }

  Widget _buildDataRow(String label, String value, bool isDark, {bool highlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
              color: highlight
                  ? const Color(0xFF10B981)
                  : (isDark ? Colors.white : AppColors.darkBG),
            ),
          ),
        ),
      ],
    );
  }

  void _showMicrochipExplanationDialog(
    BuildContext context,
    bool isDark,
    String petName,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.memory_rounded, color: Color(0xFFF59E0B), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.t('passport.microchip_dialog_title'),
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.darkBG,
                            ),
                          ),
                          Text(
                            context.t('passport.microchip_dialog_subtitle'),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  context.t('passport.microchip_dialog_desc1', args: {'name': petName}),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.t('passport.microchip_dialog_warning'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.t('passport.microchip_dialog_steps'),
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: Text(
                      context.t('passport.microchip_dialog_understood'),
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
}

