import 'package:flutter/material.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:patas_web_app/src/common_widgets/mobile_scroll_padding.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/features/pets/active_pet_provider.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:provider/provider.dart';
import '../../../app.dart';

import 'package:patas_web_app/src/features/health/screens/tutor_vet_map_screen.dart';
import 'package:patas_web_app/src/features/health/vacinas/vacinas_page.dart';
import 'package:patas_web_app/src/features/health/screens/tutor_appointments_screen.dart';
import 'package:patas_web_app/src/features/health/screens/tutor_health_history_screen.dart';
import 'package:patas_web_app/src/features/health/exames/exams_list_page.dart';
import 'package:patas_web_app/src/features/health/dicas/dicas_page.dart';

import 'package:patas_web_app/src/features/health/services/pet_health_pdf_report_service.dart';
import 'package:patas_web_app/src/features/health/widgets/pet_weight_chart_widget.dart';
import 'package:patas_web_app/src/features/health/widgets/preventive_care_card.dart';
import 'package:patas_web_app/src/features/solana/widgets/pet_passport_hero_card.dart';

class PetHealthPage extends StatefulWidget {
  const PetHealthPage({super.key});

  @override
  State<PetHealthPage> createState() => _PetHealthPageState();
}

class _PetHealthPageState extends State<PetHealthPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final petProvider = Provider.of<ActivePetProvider>(
        context,
        listen: false,
      );
      if (petProvider.activePet == null && !petProvider.isLoading) {
        petProvider.initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: const ValueKey('main'),
      child: ResponsiveLayout(
        mobile: _buildMobileLayout(context),
        tablet: _buildTabletLayout(context),
        desktop: _buildDesktopLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final petProvider = Provider.of<ActivePetProvider>(context);
    final activePet = petProvider.activePet;

    return Scaffold(
      backgroundColor: thmode.darkMode
          ? AppColors.bodygray
          : const Color(0xFFF5F7FA),
      appBar: const PatasEssencialAppBar(
        title: 'Patas Saúde',
        subtitle: 'Consultas, exames, vacinas e mapa de clínicas',
        showBackButton: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 15,
          bottom: MobileScrollPadding.bottomInset(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pet Header e cards de saúde preventiva e peso
            if (activePet != null) ...[
              _buildPetHeader(context, activePet, isDesktop: false),
              const SizedBox(height: 16),
              PetPassportHeroCard(pet: activePet, isDesktop: false),
              const SizedBox(height: 16),
              PreventiveCareCard(activePet: activePet),
              const SizedBox(height: 16),
              PetWeightChartWidget(activePet: activePet),
              const SizedBox(height: 20),
            ] else if (petProvider.isLoading) ...[
              _buildPetLoadingPlaceholder(context, isDesktop: false),
              const SizedBox(height: 20),
            ] else ...[
              _buildNoPetCard(context, isDesktop: false),
              const SizedBox(height: 20),
            ],

            Text(
              'Serviços de Saúde',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: thmode.darkMode ? Colors.white : AppColors.darkBG,
              ),
            ),
            const SizedBox(height: 12),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.12,
              children: _buildGridCards(context, isDesktop: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final petProvider = Provider.of<ActivePetProvider>(context);
    final activePet = petProvider.activePet;

    return Scaffold(
      backgroundColor: thmode.darkMode
          ? AppColors.bodygray
          : const Color(0xFFF5F7FA),
      appBar: const PatasEssencialAppBar(
        title: 'Patas Saúde',
        subtitle: 'Consultas, exames, vacinas e mapa de clínicas',
        showBackButton: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pet Header e cards de saúde preventiva e peso
                if (activePet != null) ...[
                  _buildPetHeader(context, activePet, isDesktop: true),
                  const SizedBox(height: 18),
                  PetPassportHeroCard(pet: activePet, isDesktop: true),
                  const SizedBox(height: 18),
                  PreventiveCareCard(activePet: activePet),
                  const SizedBox(height: 18),
                  PetWeightChartWidget(activePet: activePet),
                  const SizedBox(height: 24),
                ] else if (petProvider.isLoading) ...[
                  _buildPetLoadingPlaceholder(context, isDesktop: true),
                  const SizedBox(height: 24),
                ] else ...[
                  _buildNoPetCard(context, isDesktop: true),
                  const SizedBox(height: 24),
                ],

                Text(
                  'Serviços de Saúde',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                  ),
                ),
                const SizedBox(height: 16),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount =
                        constraints.maxWidth >= 800 ? 4 : 3;
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.15,
                      children: _buildGridCards(context, isDesktop: true),
                    );
                  },
                ),

                const SizedBox(height: 20),
                const MobileScrollPadding(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final petProvider = Provider.of<ActivePetProvider>(context);
    final activePet = petProvider.activePet;
    final bgColor = thmode.darkMode
        ? AppColors.bodygray
        : const Color(0xFFF0F2F5);

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(40, 40, 40, 20),
                  child: Text(
                    'Patas Saúde',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      color: AppColors.patasColor,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Pet Header e cards de saúde (Desktop)
                if (activePet != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: _buildPetHeader(context, activePet, isDesktop: true),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: PetPassportHeroCard(pet: activePet, isDesktop: true),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: PreventiveCareCard(activePet: activePet),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: PetWeightChartWidget(activePet: activePet),
                        ),
                      ],
                    ),
                  ),
                ] else if (petProvider.isLoading) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: _buildPetLoadingPlaceholder(
                      context,
                      isDesktop: true,
                    ),
                  ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: _buildNoPetCard(context, isDesktop: true),
                  ),
                ],

                const SizedBox(height: 32),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Serviços de Saúde',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 900 ? 5 : 4;
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 10,
                      ),
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.25,
                      children: _buildGridCards(context, isDesktop: true),
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPetHeader(
    BuildContext context,
    dynamic activePet, {
    bool isDesktop = false,
  }) {
    final thmode = Provider.of<DarkMode>(context);

    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        color: thmode.darkMode ? AppColors.darkBG : AppColors.bodyLight,
        borderRadius: BorderRadius.circular(isDesktop ? 24 : 20),
        border: isDesktop
            ? Border.all(
                color: (thmode.darkMode ? Colors.white : Colors.black)
                    .withValues(alpha: 0.05),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: thmode.darkMode ? 0.15 : 0.03,
            ),
            blurRadius: isDesktop ? 30 : 20,
            spreadRadius: -2,
            offset: Offset(0, isDesktop ? 8 : 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isDesktop ? 40 : 30,
            backgroundImage: activePet.photoUrl != null
                ? NetworkImage(activePet.photoUrl!)
                : null,
            child: activePet.photoUrl == null
                ? Icon(
                    Icons.pets,
                    color: AppColors.patasColor,
                    size: isDesktop ? 34 : 24,
                  )
                : null,
          ),
          SizedBox(width: isDesktop ? 24 : 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saúde de ${activePet.name}',
                  style: TextStyle(
                    fontFamily: isDesktop ? 'Fredoka' : null,
                    fontSize: isDesktop ? 24 : 18,
                    fontWeight: FontWeight.bold,
                    color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                SizedBox(height: isDesktop ? 8 : 4),
                Text(
                  'Acompanhe tudo sobre seu pet',
                  style: TextStyle(
                    fontSize: isDesktop ? 14 : 12,
                    color: thmode.darkMode ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              PetHealthPdfReportService().generateAndExportPdfReport(activePet);
            },
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
            label: Text(
              isDesktop ? 'Exportar Relatório PDF' : 'PDF',
              style: const TextStyle(fontFamily: 'Fredoka', fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.patasColor,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 16 : 10,
                vertical: isDesktop ? 12 : 8,
              ),
            ),
          ),
          if (isDesktop) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.patasColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.monitor_heart_rounded,
                color: AppColors.patasColor,
                size: 28,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPetLoadingPlaceholder(
    BuildContext context, {
    bool isDesktop = false,
  }) {
    final isDark = Provider.of<DarkMode>(context).darkMode;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBG : Colors.white,
        borderRadius: BorderRadius.circular(isDesktop ? 24 : 20),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.patasColor,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Carregando dados de saúde do pet...',
            style: TextStyle(
              fontSize: isDesktop ? 15 : 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPetCard(BuildContext context, {bool isDesktop = false}) {
    final isDark = Provider.of<DarkMode>(context).darkMode;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 20 : 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBG : Colors.white,
        borderRadius: BorderRadius.circular(isDesktop ? 24 : 20),
        border: Border.all(
          color: AppColors.patasColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.patasColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: AppColors.patasColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nenhum pet selecionado',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: isDesktop ? 16 : 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.darkBG,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sincronizando perfil e histórico de saúde...',
                  style: TextStyle(
                    fontSize: isDesktop ? 13 : 11,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () {
              Provider.of<ActivePetProvider>(
                context,
                listen: false,
              ).initialize();
            },
            icon: const Icon(
              Icons.refresh_rounded,
              size: 16,
              color: AppColors.patasColor,
            ),
            label: const Text(
              'Atualizar',
              style: TextStyle(
                color: AppColors.patasColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGridCards(BuildContext context, {bool isDesktop = false}) {
    return [
      _HealthGridCard(
        title: 'Mapa de Vets',
        subtitle: 'Clínicas e 24h',
        icon: Icons.map_rounded,
        color: const Color(0xFF00897B),
        isDesktop: isDesktop,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TutorVetMapScreen()),
          );
        },
      ),
      _HealthGridCard(
        title: 'Vacinas',
        subtitle: 'Doses e reforços',
        icon: Icons.vaccines_rounded,
        color: const Color(0xFFFF6D00),
        isDesktop: isDesktop,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VacinasPage()),
          );
        },
      ),
      _HealthGridCard(
        title: 'Agendamentos',
        subtitle: 'Consultas e retornos',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFF1E88E5),
        isDesktop: isDesktop,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TutorAppointmentsScreen(),
            ),
          );
        },
      ),
      _HealthGridCard(
        title: 'Prontuários & Receitas',
        subtitle: 'Histórico e remédios',
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFF8E24AA),
        isDesktop: isDesktop,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const TutorHealthHistoryScreen(initialIndex: 0),
            ),
          );
        },
      ),
      _HealthGridCard(
        title: 'Exames & Laudos',
        subtitle: 'Resultados e laudos',
        icon: Icons.biotech_rounded,
        color: const Color(0xFF3949AB),
        isDesktop: isDesktop,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ExamsListPage()),
          );
        },
      ),
      _HealthGridCard(
        title: 'Dicas de Saúde',
        subtitle: 'Cuidados e bem-estar',
        icon: Icons.lightbulb_rounded,
        color: const Color(0xFFFFB300),
        isDesktop: isDesktop,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DicasPage()),
          );
        },
      ),
    ];
  }
}

class _HealthGridCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isDesktop;

  const _HealthGridCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isDesktop = false,
  });

  @override
  State<_HealthGridCard> createState() => _HealthGridCardState();
}

class _HealthGridCardState extends State<_HealthGridCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    // Fundo premium com gradiente sutil para criar profundidade
    final backgroundGradient = isDark
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _isHovered ? const Color(0xFF26262E) : const Color(0xFF1E1E24),
              _isHovered ? const Color(0xFF1D1D23) : const Color(0xFF17171B),
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              _isHovered ? const Color(0xFFF8FAFC) : const Color(0xFFF3F5F9),
            ],
          );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            gradient: backgroundGradient,
            borderRadius: BorderRadius.circular(widget.isDesktop ? 22 : 18),
            border: Border.all(
              color: widget.color.withValues(
                alpha: isDark
                    ? (_isHovered ? 0.38 : 0.16)
                    : (_isHovered ? 0.35 : 0.14),
              ),
              width: 1.2,
            ),
            boxShadow: [
              // Glow sutil na cor tema do serviço
              BoxShadow(
                color: widget.color.withValues(
                  alpha: _isHovered ? (isDark ? 0.18 : 0.12) : 0.04,
                ),
                blurRadius: _isHovered ? 18 : 8,
                spreadRadius: 0,
                offset: Offset(0, _isHovered ? 6 : 3),
              ),
              // Sombra de elevação natural
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isDark
                      ? (_isHovered ? 0.35 : 0.22)
                      : (_isHovered ? 0.08 : 0.03),
                ),
                blurRadius: _isHovered ? 14 : 8,
                spreadRadius: -2,
                offset: Offset(0, _isHovered ? 6 : 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(widget.isDesktop ? 22 : 18),
              onTap: widget.onTap,
              splashColor: widget.color.withValues(alpha: 0.12),
              highlightColor: widget.color.withValues(alpha: 0.06),
              child: Padding(
                padding: EdgeInsets.all(widget.isDesktop ? 15 : 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Topo: Ícone estilizado com micro-gradiente e mini-seta translúcida
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Container do Ícone com micro gradiente e leve contorno
                        Container(
                          width: widget.isDesktop ? 44 : 38,
                          height: widget.isDesktop ? 44 : 38,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                widget.color.withValues(alpha: 0.22),
                                widget.color.withValues(alpha: 0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              widget.isDesktop ? 13 : 11,
                            ),
                            border: Border.all(
                              color: widget.color.withValues(alpha: 0.28),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            widget.icon,
                            color: widget.color,
                            size: widget.isDesktop ? 24 : 20,
                          ),
                        ),
                        // Mini seta elegante com micro-animação
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: widget.isDesktop ? 28 : 24,
                          height: widget.isDesktop ? 28 : 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: _isHovered ? 0.08 : 0.03),
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: widget.isDesktop ? 14 : 12,
                            color: (isDark ? Colors.white70 : Colors.black45)
                                .withValues(alpha: _isHovered ? 0.9 : 0.5),
                          ),
                        ),
                      ],
                    ),

                    // Base: Título em destaque e subtítulo de apoio
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: widget.isDesktop ? 15 : 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.darkBG,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: widget.isDesktop ? 12 : 11,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white54
                                : Colors.black.withValues(alpha: 0.52),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
