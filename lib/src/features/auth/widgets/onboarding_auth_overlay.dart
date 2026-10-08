import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../../../../app.dart';
import '../../../common_widgets/multi_text_button.dart';
import '../../../common_widgets/particles_background.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../constants/routes.dart';
import '../../../utils/responsive_layout.dart';
import 'onboarding_showcase.dart';
import 'package:patas_web_app/core/localization/app_localizations.dart';

class OnboardingAuthOverlay extends StatelessWidget {
  const OnboardingAuthOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    return Scaffold(
      backgroundColor: Colors.transparent, // Transparente para o Dialog
      body: Stack(
        children: [
          // Background com partículas para esta tela
          Positioned.fill(
            child: ParticlesBackground(
              particleColor: AppColors.patasColor,
              backgroundColor: isDark
                  ? const Color(0xFF0F0F1A).withValues(alpha: 0.95)
                  : const Color(0xFF1C1C3A).withValues(alpha: 0.95),
              backgroundColorEnd: isDark
                  ? const Color(0xFF1A0A0A).withValues(alpha: 0.95)
                  : const Color(0xFF2D1B00).withValues(alpha: 0.95),
              particleCount: 70,
              child: ResponsiveLayout(
                mobile: _buildMobile(thmode, isDark, context),
                tablet: _buildTablet(thmode, isDark, context),
                desktop: _buildDesktop(thmode, isDark, context),
              ),
            ),
          ),

          // Botão de fechar (opcional, bom para overlay)
          Positioned(
            top: 20,
            right: 20,
            child: IconButton(
              icon: Icon(
                Icons.close,
                color: Colors.white.withValues(alpha: 0.7),
                size: 30,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── MOBILE ─────────────────────────────────────────────────────────────────
  Widget _buildMobile(DarkMode thmode, bool isDark, BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth,
              minHeight: constraints.maxHeight,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Showcase imponente com proporção original fluida
                      const SizedBox(height: 290, child: OnboardingShowcase()),
                      const SizedBox(height: 16),
                      // Card de login com proporções harmoniosas e equilibradas
                      _buildLoginCard(thmode, isDark, context, isMobile: true),
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

  // ─── TABLET ─────────────────────────────────────────────────────────────────
  Widget _buildTablet(DarkMode thmode, bool isDark, BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth,
              minHeight: constraints.maxHeight,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Showcase com altura um pouco maior que no mobile
                      const SizedBox(height: 440, child: OnboardingShowcase()),
                      const SizedBox(height: 40),
                      // Card de login centralizado, largura restrita
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: _buildLoginCard(thmode, isDark, context),
                        ),
                      ),
                      const SizedBox(height: 40),
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

  // ─── DESKTOP ────────────────────────────────────────────────────────────────
  Widget _buildDesktop(DarkMode thmode, bool isDark, BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth,
              minHeight: constraints.maxHeight,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Showcase à esquerda (ocupa espaço restante)
                      const Expanded(
                        child: SizedBox(
                          height: 520,
                          child: ExcludeSemantics(child: OnboardingShowcase()),
                        ),
                      ),

                      const SizedBox(width: 80),

                      // Card de login à direita com largura fixa
                      SizedBox(
                        width: 450,
                        child: Center(child: _buildLoginCard(thmode, isDark, context)),
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

  // ─── CARD DE LOGIN (compartilhado) ──────────────────────────────────────────
  Widget _buildLoginCard(DarkMode thmode, bool isDark, BuildContext context, {bool isMobile = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.patasColor.withValues(alpha: 0.18),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14.0, sigmaY: 14.0),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 24 : 40,
              vertical: isMobile ? 24 : 40,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.25),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => thmode.changemode(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      isDark ? Icons.light_mode : Icons.dark_mode,
                      color: AppColors.patasColor,
                      size: isMobile ? 22 : 24,
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 8 : 20),
                SizedBox(
                  height: isMobile ? 80 : 160,
                  width: isMobile ? 80 : 160,
                  child: SvgPicture.asset('assets/icons/patas.svg'),
                ),
                SizedBox(height: isMobile ? 14 : 24),
                Text(
                  context.tr('onboarding.welcome_title'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 24 : 28,
                  ),
                ),
                SizedBox(height: isMobile ? 6 : 10),
                Text(
                  context.tr('onboarding.welcome_tagline'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontFamily: 'Roboto_flex',
                    fontWeight: FontWeight.w500,
                    fontSize: isMobile ? 14 : 15,
                  ),
                ),
                SizedBox(height: isMobile ? 22 : 40),
                SizedBox(
                  height: isMobile ? 50 : 52,
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, NamedRoute.signUp);
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                        AppColors.patasColor,
                      ),
                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32.0),
                        ),
                      ),
                    ),
                    child: Text(
                      context.tr('onboarding.start_action'),
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Fredoka',
                        fontSize: isMobile ? 20 : 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 14 : 20),
                Align(
                  alignment: Alignment.center,
                  child: MultiTextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, NamedRoute.signIn),
                    children: [
                      Text(
                        context.tr('auth.already_have_account'),
                        style: AppTextStyles.smallText.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        context.tr('auth.login'),
                        style: const TextStyle(
                          fontFamily: 'Fredoka',
                          color: AppColors.patasColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
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
