import 'package:flutter/material.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:provider/provider.dart';
import '../../../app.dart';

class HelpSupportPage extends StatelessWidget {
  final bool isDialog;
  const HelpSupportPage({super.key, this.isDialog = false});

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final textColor = isDark ? Colors.white : AppColors.darkBG;
    final cardColor = isDark ? AppColors.darkBG : AppColors.bodyLight;

    return Scaffold(
      backgroundColor: isDialog ? Colors.transparent : (isDark ? AppColors.bodygray : Colors.grey.shade300),
      appBar: isDialog
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              centerTitle: true,
              title: const Text(
                'Ajuda e Suporte',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  color: AppColors.patasColor,
                  fontSize: 24,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: textColor),
                ),
                const SizedBox(width: 8),
              ],
            )
          : AppBar(
              backgroundColor: isDark ? AppColors.bodygray : Colors.grey.shade300,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.patasColor,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Ajuda e Suporte',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  color: AppColors.patasColor,
                  fontSize: 24,
                ),
              ),
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Perguntas Frequentes (FAQ)', textColor),
            const SizedBox(height: 16),
            _buildFAQItem(
              'Como adiciono um novo pet?',
              'Vá para a tela inicial, clique no botão "+" ou "Adicionar Pet" e preencha as informações básicas como nome, espécie e data de nascimento.',
              cardColor,
              textColor,
            ),
            _buildFAQItem(
              'Como funcionam os lembretes de vacina?',
              'Ao cadastrar uma vacina para o seu pet, você pode definir a data da próxima dose. O app enviará uma notificação automática para você não esquecer.',
              cardColor,
              textColor,
            ),
            _buildFAQItem(
              'Minhas informações estão seguras?',
              'Sim! Seus dados e os dados dos seus pets são armazenados de forma segura e não são compartilhados com terceiros sem sua permissão.',
              cardColor,
              textColor,
            ),
            _buildFAQItem(
              'Esqueci minha senha, o que fazer?',
              'Na tela de login, utilize a opção "Esqueci minha senha" para receber um link de redefinição no seu e-mail cadastrado.',
              cardColor,
              textColor,
            ),
            _buildFAQItem(
              'Posso gerenciar mais de um pet?',
              'Com certeza! O Patas permite que você tenha perfis individuais para todos os seus animais, de forma ilimitada.',
              cardColor,
              textColor,
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('Ainda precisa de ajuda?', textColor),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(50),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.support_agent_rounded,
                    size: 50,
                    color: AppColors.patasColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Fale com nosso Suporte',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Estamos disponíveis para tirar dúvidas específicas via WhatsApp.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'O suporte via WhatsApp está em desenvolvimento. Em breve você poderá falar conosco!'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: const Text('Abrir WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.patasColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        color: color,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'Fredoka',
      ),
    );
  }

  Widget _buildFAQItem(
      String question, String answer, Color cardColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          question,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        iconColor: AppColors.patasColor,
        collapsedIconColor: AppColors.patasColor,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Text(
              answer,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.8),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
