import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/app.dart';
import '../../pets/models/pet_model.dart';
import '../models/pet_passport_model.dart';
import '../services/pet_passport_service.dart';
import 'pet_passport_detail_sheet.dart';
import 'pet_passport_onboarding_dialog.dart';

class PetPassportHeroCard extends StatefulWidget {
  final Pet pet;
  final bool isDesktop;

  const PetPassportHeroCard({
    super.key,
    required this.pet,
    this.isDesktop = false,
  });

  @override
  State<PetPassportHeroCard> createState() => _PetPassportHeroCardState();
}

class _PetPassportHeroCardState extends State<PetPassportHeroCard> {
  bool _isHovered = false;
  PetPassport? _passport;

  @override
  void initState() {
    super.initState();
    _loadPassport();
  }

  @override
  void didUpdateWidget(covariant PetPassportHeroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pet.id != widget.pet.id) {
      _loadPassport();
    }
  }

  void _loadPassport() async {
    final existing = await PetPassportService.getExistingPassport(widget.pet.id);
    if (mounted) {
      setState(() => _passport = existing);
    }
  }

  void _handleTap() async {
    if (_passport != null) {
      // Já emitido: abre o passaporte oficial com as 3 abas
      PetPassportDetailSheet.show(context, passport: _passport!);
    } else {
      // Ainda não emitido: abre o onboarding explicativo para adesão
      PetPassportOnboardingDialog.show(
        context,
        pet: widget.pet,
        onMintCompleted: (newPassport) {
          if (mounted) {
            setState(() => _passport = newPassport);
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0.0, _isHovered ? -2.0 : 0.0, 0.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                  : [const Color(0xFF2E1065), const Color(0xFF1E1B4B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(widget.isDesktop ? 22 : 18),
            border: Border.all(
              color: _isHovered
                  ? const Color(0xFF14F195)
                  : const Color(0xFF9945FF).withValues(alpha: 0.5),
              width: _isHovered ? 2.0 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (_isHovered ? const Color(0xFF14F195) : const Color(0xFF9945FF))
                    .withValues(alpha: isDark ? 0.22 : 0.16),
                blurRadius: _isHovered ? 20 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.all(widget.isDesktop ? 18 : 14),
          child: Row(
            children: [
              // Ícone Holográfico Solana cNFT
              Container(
                width: widget.isDesktop ? 54 : 46,
                height: widget.isDesktop ? 54 : 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9945FF), Color(0xFF14F195)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(widget.isDesktop ? 16 : 14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF14F195).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _passport != null ? Icons.verified_user_rounded : Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),

              // Textos e Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _passport != null
                                ? 'Passaporte Imutável Solana'
                                : 'Passaporte Digital Soberano',
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: widget.isDesktop ? 16 : 14.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF14F195).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _passport != null ? 'cNFT ON-CHAIN' : 'cNFT DEVNET',
                            style: const TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF14F195),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _passport != null
                          ? 'Microchip: ${_passport!.microchipNumber} • Verificado'
                          : 'Crie a identidade oficial de ${widget.pet.name} na blockchain',
                      style: TextStyle(
                        fontSize: widget.isDesktop ? 12 : 11,
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF14F195).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF14F195).withValues(alpha: 0.4),
                  ),
                ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _passport != null ? 'Abrir' : 'Emitir',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: widget.isDesktop ? 12 : 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF14F195),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: Color(0xFF14F195),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
