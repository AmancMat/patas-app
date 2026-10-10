import 'package:flutter/material.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/localization/localizations_ext.dart';
import 'package:patas_web_app/src/common_widgets/mobile_scroll_padding.dart';
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

    final dialogTitle = context.tr('info_perm.delete_dialog_title');
    final dialogContent = context.tr('info_perm.delete_dialog_content');
    final requestSentMsg = context.tr('info_perm.delete_request_sent');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(dialogTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text(dialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(context.tr('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(context.tr('common.delete'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isDeleting = true);
      try {
        await locator.get<AuthService>().requestAccountDeletion();

        if (mounted) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil(NamedRoute.signIn, (route) => false);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(requestSentMsg),
              duration: const Duration(seconds: 5),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('info_perm.delete_request_error', {'error': '$e'}))),
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(context.tr('info_perm.open_settings_error'))),
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
              context.tr('info_perm.title'),
              style: const TextStyle(
                color: AppColors.patasColor,
                fontSize: 22,
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
              context.tr('info_perm.title'),
              style: const TextStyle(
                color: AppColors.patasColor,
                fontSize: 22,
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionHeader(context.tr('info_perm.data_management'), textColor),
          _buildCard(
            cardColor: cardColor,
            children: [
              _buildListTile(
                icon: Icons.download_outlined,
                title: context.tr('info_perm.download_data_title'),
                subtitle: context.tr('info_perm.download_data_desc'),
                textColor: textColor,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(context.tr('info_perm.download_data_notice'))),
                  );
                },
              ),
              _buildListTile(
                icon: Icons.history,
                title: context.tr('info_perm.activity_history_title'),
                subtitle: context.tr('info_perm.activity_history_desc'),
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
          _buildSectionHeader(context.tr('info_perm.device_permissions'), textColor),
          _buildCard(
            cardColor: cardColor,
            children: [
              _buildPermissionTile(
                icon: Icons.camera_alt_outlined,
                title: context.tr('info_perm.camera_title'),
                description: context.tr('info_perm.camera_desc'),
                textColor: textColor,
              ),
              _buildPermissionTile(
                icon: Icons.photo_library_outlined,
                title: context.tr('info_perm.gallery_title'),
                description: context.tr('info_perm.gallery_desc'),
                textColor: textColor,
              ),
              _buildPermissionTile(
                icon: Icons.notifications_none_outlined,
                title: context.tr('info_perm.notifications_title'),
                description: context.tr('info_perm.notifications_desc'),
                textColor: textColor,
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextButton(
                  onPressed: _openAppSettings,
                  child: Text(context.tr('info_perm.open_system_settings'),
                      style: const TextStyle(
                          color: AppColors.patasColor,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSectionHeader(context.tr('info_perm.account_management'), textColor),
          _buildCard(
            cardColor: cardColor,
            children: [
              _buildListTile(
                icon: Icons.delete_forever_outlined,
                title: context.tr('info_perm.delete_account_title'),
                subtitle: context.tr('info_perm.delete_account_desc'),
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
          const SizedBox(height: 40),
          const MobileScrollPadding(),
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
