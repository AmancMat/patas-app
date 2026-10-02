import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app.dart';
import '../../constants/app_colors.dart';
import '../../constants/legal_texts.dart';
import '../../common_widgets/patas_essencial_app_bar.dart';

enum LegalDocumentType { terms, privacy }

class LegalPage extends StatelessWidget {
  final LegalDocumentType type;

  const LegalPage({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    final title = type == LegalDocumentType.terms
        ? 'Termos de Uso'
        : 'Política de Privacidade';

    final textContent = type == LegalDocumentType.terms
        ? LegalTexts.termsOfUse
        : LegalTexts.privacyPolicy;

    final bgColor = isDark ? AppColors.darkBG : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final subtitleColor = isDark ? Colors.white70 : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: PatasEssencialAppBar(
        title: title,
        subtitle: type == LegalDocumentType.terms
            ? 'Termos e Condições de Uso da Plataforma'
            : 'Política de Privacidade e Proteção de Dados',
        leadingIcon: Icon(
          type == LegalDocumentType.terms
              ? Icons.description_rounded
              : Icons.shield_rounded,
          color: AppColors.patasColor,
          size: 22,
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                ),
              ),
              child: SelectableText(
                textContent,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: subtitleColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
