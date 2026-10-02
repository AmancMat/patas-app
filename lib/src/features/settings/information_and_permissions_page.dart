import 'package:flutter/material.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:patas_web_app/src/features/settings/activity_history_page.dart';
import 'package:patas_web_app/src/constants/routes.dart';
import 'package:patas_web_app/src/features/auth/services/auth_services.dart';
import 'package:patas_web_app/src/localization/locator.dart';
import '../../../../app.dart';
import '../../../../main.dart';

class InformationAndPermissionsPage extends StatefulWidget {
  final bool isDialog;
  const InformationAndPermissionsPage({super.key, this.isDialog = false});

  @override
  State<InformationAndPermissionsPage> createState() =>
      _InformationAndPermissionsPageState();
}

class _InformationAndPermissionsPageState
    extends State<InformationAndPermissionsPage> {
  bool _isDeleting = false;

  Future<void> _deleteAccount() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Conta',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: const Text(
            'Sua conta será desativada imediatamente e todos os dados serão excluídos permanentemente após 30 dias.\n\nDurante este período, você pode cancelar a exclusão fazendo login novamente.\n\nTem certeza que deseja continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isDeleting = true);
      try {
        // Chama o método real de solicitação de exclusão
        await locator.get<AuthService>().requestAccountDeletion();

        // O método já faz logout, então só precisamos navegar
        if (mounted) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil(NamedRoute.signIn, (route) => false);

          // Mostra mensagem de confirmação
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Solicitação de exclusão enviada. Você tem 30 dias para cancelar fazendo login novamente.'),
              duration: Duration(seconds: 5),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao solicitar exclusão: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  Future<void> _openAppSettings() async {
    final Uri url = Uri.parse('app-settings:');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      // Fallback para Android se necessário
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Não foi possível abrir as configurações. Vá manualmente em Ajustes > Patas.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final bgColor = thmode.darkMode ? AppColors.bodygray : Colors.grey.shade100;
    final cardColor = thmode.darkMode ? AppColors.darkBG : Colors.white;
    final textColor = thmode.darkMode ? Colors.white : AppColors.darkBG;

    return Scaffold(
      backgroundColor: widget.isDialog ? Colors.transparent : bgColor,
      appBar: widget.isDialog
        ? AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            centerTitle: true,
            title: Text(
              'Suas Informações',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.bold,
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
            backgroundColor: bgColor,
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
            title: Text(
              'Suas Informações',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionHeader('GESTÃO DE DADOS', textColor),
          _buildCard(
            cardColor: cardColor,
            children: [
              _buildListTile(
                icon: Icons.download_outlined,
                title: 'Baixar suas informações',
                subtitle: 'Obtenha uma cópia de todos os seus dados e pets.',
                textColor: textColor,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Preparando arquivo de dados... você receberá um link no seu e-mail em breve.')),
                  );
                },
              ),
              _buildListTile(
                icon: Icons.history,
                title: 'Histórico de atividade',
                subtitle: 'Veja o que você fez recentemente no app.',
                textColor: textColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ActivityHistoryPage()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSectionHeader('PERMISSÕES DO DISPOSITIVO', textColor),
          _buildCard(
            cardColor: cardColor,
            children: [
              _buildPermissionTile(
                icon: Icons.camera_alt_outlined,
                title: 'Câmera',
                description: 'Usada para tirar fotos dos seus pets e postar.',
                textColor: textColor,
              ),
              _buildPermissionTile(
                icon: Icons.photo_library_outlined,
                title: 'Galeria',
                description: 'Usada para selecionar fotos já existentes.',
                textColor: textColor,
              ),
              _buildPermissionTile(
                icon: Icons.notifications_none_outlined,
                title: 'Notificações',
                description: 'Avisos sobre lembretes de vacinas e consultas.',
                textColor: textColor,
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextButton(
                  onPressed: _openAppSettings,
                  child: const Text('Abrir Configurações do Sistema',
                      style: TextStyle(
                          color: AppColors.patasColor,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSectionHeader('GESTÃO DE CONTA', textColor),
          _buildCard(
            cardColor: cardColor,
            children: [
              _buildListTile(
                icon: Icons.delete_forever_outlined,
                title: 'Excluir minha conta',
                subtitle:
                    'Esta ação apagará permanentemente todos os seus dados.',
                textColor: Colors.red,
                onTap: _isDeleting ? null : _deleteAccount,
                trailing: _isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.red))
                    : const Icon(Icons.arrow_forward_ios,
                        size: 14, color: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
            color: textColor.withValues(alpha: 0.5),
            fontSize: 12,
            letterSpacing: 1.2,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCard(
      {required Color cardColor, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color textColor,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (textColor == Colors.red ? Colors.red : AppColors.patasColor)
              .withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            size: 20,
            color: textColor == Colors.red ? Colors.red : AppColors.patasColor),
      ),
      title: Text(
        title,
        style: TextStyle(
            color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 12),
      ),
      trailing: trailing ??
          Icon(Icons.arrow_forward_ios,
              size: 14, color: textColor.withValues(alpha: 0.3)),
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required String description,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.patasColor, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                      color: textColor.withValues(alpha: 0.6), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
