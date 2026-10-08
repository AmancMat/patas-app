import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/core/localization/app_localizations.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/services/supabase_notification_service.dart';
import '../utils/web_notification_prompt_helper.dart'
    if (dart.library.html) '../utils/web_notification_prompt_helper_web.dart';

class WebNotificationPromptDialog extends StatefulWidget {
  const WebNotificationPromptDialog({super.key});

  static const String _dismissedPrefKey = 'web_notification_prompt_dismissed_v1';

  /// Exibe o diálogo educativo na Web caso a permissão ainda não tenha sido concedida nem dispensada
  static Future<void> checkAndShow(BuildContext context) async {
    if (!kIsWeb) return;

    try {
      final supported = isWebNotificationSupported();
      if (!supported) return;

      final currentPermission = getWebNotificationPermission();
      if (currentPermission == 'granted' || currentPermission == 'denied') {
        return; // Já decidiu
      }

      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getBool(_dismissedPrefKey) ?? false;
      if (dismissed) return;

      if (!context.mounted) return;

      final isDesktop = MediaQuery.of(context).size.width >= 1024;

      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 24 : 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: const WebNotificationPromptDialog(),
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('[WebNotificationPromptDialog] Erro na verificação: $e');
    }
  }

  @override
  State<WebNotificationPromptDialog> createState() => _WebNotificationPromptDialogState();
}

class _WebNotificationPromptDialogState extends State<WebNotificationPromptDialog> {
  bool _isLoading = false;

  Future<void> _handleAccept() async {
    setState(() => _isLoading = true);

    try {
      final result = await requestWebNotificationPermission();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(WebNotificationPromptDialog._dismissedPrefKey, true);

      if (!mounted) return;

      Navigator.of(context).pop();

      if (result == 'granted') {
        SupabaseNotificationService().initWebRealtimeListener();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr('notifications.web_success'),
                    style: const TextStyle(fontFamily: 'Fredoka', fontSize: 13),
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
    } catch (e) {
      debugPrint('[WebNotificationPromptDialog] Erro ao solicitar permissão: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(WebNotificationPromptDialog._dismissedPrefKey, true);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.patasColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho com Ícone e Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.patasColor, Color(0xFFF97316)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.patasColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
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
                        color: AppColors.patasColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        context.tr('notifications.web_badge'),
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.patasColor,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('notifications.web_title'),
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

          const SizedBox(height: 18),

          // Texto Explicativo
          Text(
            context.tr('notifications.web_desc'),
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 14),

          // Lista de Motivos com Ícones
          _buildFeatureRow(
            icon: Icons.volunteer_activism_rounded,
            color: const Color(0xFF10B981),
            title: context.tr('notifications.web_donations_title'),
            description: context.tr('notifications.web_donations_desc'),
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildFeatureRow(
            icon: Icons.security_rounded,
            color: const Color(0xFF38BDF8),
            title: context.tr('notifications.web_payments_title'),
            description: context.tr('notifications.web_payments_desc'),
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildFeatureRow(
            icon: Icons.pets_rounded,
            color: const Color(0xFF9945FF),
            title: context.tr('notifications.web_health_title'),
            description: context.tr('notifications.web_health_desc'),
            isDark: isDark,
          ),

          const SizedBox(height: 16),

          // Alerta sobre a janelinha do navegador
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFF97316).withValues(alpha: isDark ? 0.3 : 0.4),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: Color(0xFFF97316),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('notifications.web_browser_tip'),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.orange.shade200 : const Color(0xFF9A3412),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Botões de Ação
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(color: AppColors.patasColor),
              ),
            )
          else ...[
            ElevatedButton.icon(
              onPressed: _handleAccept,
              icon: const Icon(Icons.notifications_active_rounded, size: 18),
              label: Text(
                context.tr('notifications.web_enable_button'),
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.patasColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _handleDismiss,
              child: Text(
                context.tr('notifications.web_not_now'),
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

  Widget _buildFeatureRow({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.darkBG,
                ),
              ),
              const SizedBox(height: 1),
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
    );
  }
}
