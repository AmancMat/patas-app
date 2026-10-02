import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/external_services/secure_storage.dart';
import 'package:patas_web_app/src/features/auth/services/auth_services.dart';
import 'package:patas_web_app/src/features/settings/accounts_and_profiles.dart';
import 'package:patas_web_app/src/localization/locator.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/features/settings/edit_profile_page.dart';
import 'package:patas_web_app/src/features/settings/information_and_permissions_page.dart';
import 'package:patas_web_app/src/features/settings/change_password_page.dart';
import 'package:patas_web_app/src/features/settings/widgets/settings_dialog_wrapper.dart';
import 'package:patas_web_app/src/features/settings/help_support_page.dart';
import 'package:patas_web_app/src/features/notifications/services/notification_service.dart';
import 'package:patas_web_app/src/providers/active_account_provider.dart';
import 'package:patas_web_app/src/features/pets/active_pet_provider.dart';
import 'package:patas_web_app/src/constants/routes.dart';
import 'package:patas_web_app/src/features/settings/accessibility_settings_page.dart';
import 'package:patas_web_app/src/features/settings/blocked_users_page.dart';
import 'package:patas_web_app/src/features/legal/legal_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isExpanded1 = false;
  bool _isExpanded2 = false;
  bool _isExpanded3 = false;
  bool _isExpanded4 = false;
  bool _isExpanded5 = false;
  bool _isExpanded6 = false;
  bool _isExpanded7 = false;
  bool _isExpandedAccessibility = false;
  bool _isExpandedLegal = false;

  // Novos estados para configurações
  bool _loginAlerts = false;
  bool _notifyPosts = true;
  bool _notifyFollowers = true;
  bool _notifyEmail = false;

  String _selectedSound = 'Padrão';
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    const storage = SecureStorage();
    final alerts = await storage.readOne(key: 'security_alerts');
    final pPosts = await storage.readOne(key: 'notify_posts');
    final pFollowers = await storage.readOne(key: 'notify_followers');
    final pEmail = await storage.readOne(key: 'notify_email');

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final version = packageInfo.version;
    final buildNumber = packageInfo.buildNumber;

    // Load sound preference
    String soundKey = 'Padrão';
    try {
      final soundRes =
          await locator.get<NotificationService>().getPreferredSound();
      for (var entry in NotificationService.notificationSounds.entries) {
        if (entry.value == soundRes) {
          soundKey = entry.key;
          break;
        }
      }
    } catch (e) {
      debugPrint('Error loading sound pref: $e');
    }

    if (mounted) {
      setState(() {
        _loginAlerts = alerts == 'true';
        _notifyPosts = pPosts != 'false'; // Default true
        _notifyFollowers = pFollowers != 'false'; // Default true
        _notifyEmail = pEmail == 'true';
        _selectedSound = soundKey;
        _appVersion = '$version ($buildNumber)';
      });
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    const storage = SecureStorage();
    await storage.write(key: key, value: value.toString());
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    return Scaffold(
      backgroundColor:
          thmode.darkMode ? AppColors.bodygray : Colors.grey.shade300,
      appBar: AppBar(
        backgroundColor:
            thmode.darkMode ? AppColors.bodygray : Colors.grey.shade300,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Configurações',
          style: TextStyle(
            fontFamily: 'Fredoka',
            color: AppColors.patasColor,
            fontSize: 30,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 100, top: 16),
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(
                    top: 30, bottom: 16, left: 16, right: 32),
                decoration: BoxDecoration(
                    color: thmode.darkMode
                        ? AppColors.darkBG
                        : AppColors.bodyLight,
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withAlpha(70),
                          offset: const Offset(3.0, 10.0),
                          blurRadius: 15.0)
                    ]),
                child: ExpansionTile(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    side: BorderSide.none,
                  ),
                  collapsedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    side: BorderSide.none,
                  ),
                  textColor: AppColors.patasColor,
                  trailing: AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _isExpanded1 ? 0.25 : 0,
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                    ),
                  ),
                  onExpansionChanged: (value) {
                    setState(() {
                      _isExpanded1 = value;
                    });
                  },
                  title: Text(
                    'Controle de Tema',
                    style: TextStyle(
                        color:
                            thmode.darkMode ? Colors.white : AppColors.darkBG,
                        fontSize: 16),
                  ),
                  leading: Icon(
                    Icons.light,
                    color: thmode.darkMode
                        ? AppColors.patasColor
                        : AppColors.patasColor,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 210,
                                margin:
                                    const EdgeInsets.only(bottom: 8, left: 16),
                                child: Text(
                                  'Escolha o tema que melhor se adapta ao seu gosto pessoal e estilo. ',
                                  style: TextStyle(
                                      color: thmode.darkMode
                                          ? Colors.white
                                          : AppColors.darkBG,
                                      fontSize: 14),
                                ),
                              ),
                              CupertinoSwitch(
                                  activeTrackColor: AppColors.patasColor,
                                  value: thmode.darkMode,
                                  onChanged: (bool val) {
                                    thmode.changemode();
                                  })
                            ],
                          ),
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Som de Notificação',
                                  style: TextStyle(
                                    color: thmode.darkMode
                                        ? Colors.white
                                        : AppColors.darkBG,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14, // Consistent font size
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: thmode.darkMode
                                              ? Colors.grey[800]
                                              : Colors.grey[200],
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _selectedSound,
                                            isExpanded: true,
                                            dropdownColor: thmode.darkMode
                                                ? AppColors.darkBG
                                                : Colors.white,
                                            icon: Icon(Icons.arrow_drop_down,
                                                color: thmode.darkMode
                                                    ? Colors.white
                                                    : AppColors.darkBG),
                                            items: NotificationService
                                                .notificationSounds.keys
                                                .map((String key) {
                                              return DropdownMenuItem<String>(
                                                value: key,
                                                child: Text(
                                                  key,
                                                  style: TextStyle(
                                                    color: thmode.darkMode
                                                        ? Colors.white
                                                        : AppColors.darkBG,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                            onChanged:
                                                (String? newValue) async {
                                              if (newValue != null) {
                                                setState(() {
                                                  _selectedSound = newValue;
                                                });
                                                final soundRes =
                                                    NotificationService
                                                            .notificationSounds[
                                                        newValue]!;
                                                await locator
                                                    .get<NotificationService>()
                                                    .updatePreferredSound(
                                                        soundRes);
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: () async {
                                        final soundRes = NotificationService
                                                .notificationSounds[
                                            _selectedSound]!;

                                        String channelId = 'notes_default';
                                        if (soundRes != 'default') {
                                          channelId = 'notes_$soundRes';
                                        }

                                        await locator
                                            .get<NotificationService>()
                                            .showLocalNotificationTest(
                                                channelId, _selectedSound);
                                      },
                                      child: const Text('Testar'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(
                    top: 16, bottom: 16, left: 16, right: 32),
                decoration: BoxDecoration(
                    color: thmode.darkMode
                        ? AppColors.darkBG
                        : AppColors.bodyLight,
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withAlpha(70),
                          offset: const Offset(3.0, 10.0),
                          blurRadius: 15.0)
                    ]),
                child: ExpansionTile(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    side: BorderSide.none,
                  ),
                  collapsedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    side: BorderSide.none,
                  ),
                  textColor: AppColors.patasColor,
                  trailing: AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _isExpandedAccessibility ? 0.25 : 0,
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                    ),
                  ),
                  onExpansionChanged: (value) {
                    setState(() {
                      _isExpandedAccessibility = value;
                    });
                  },
                  title: Text(
                    'Acessibilidade',
                    style: TextStyle(
                        color:
                            thmode.darkMode ? Colors.white : AppColors.darkBG,
                        fontSize: 16),
                  ),
                  leading: const Icon(
                    Icons.accessibility_new,
                    color: AppColors.patasColor,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8, left: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AccessibilitySettingsPanel(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(
                    top: 16, bottom: 16, left: 16, right: 32),
                decoration: BoxDecoration(
                    color: thmode.darkMode
                        ? AppColors.darkBG
                        : AppColors.bodyLight,
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withAlpha(70),
                          offset: const Offset(3.0, 10.0),
                          blurRadius: 15.0)
                    ]),
                child: ExpansionTile(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    side: BorderSide.none,
                  ),
                  collapsedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    side: BorderSide.none,
                  ),
                  textColor: AppColors.patasColor,
                  trailing: AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _isExpanded2 ? 0.25 : 0,
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                    ),
                  ),
                  onExpansionChanged: (value) {
                    setState(() {
                      _isExpanded2 = value;
                    });
                  },
                  title: Text(
                    'Configurações de Privacidade',
                    style: TextStyle(
                        color:
                            thmode.darkMode ? Colors.white : AppColors.darkBG,
                        fontSize: 16),
                  ),
                  leading: Icon(
                    Icons.privacy_tip_outlined,
                    color: thmode.darkMode
                        ? AppColors.patasColor
                        : AppColors.patasColor,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8, left: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextButton(
                              onPressed: () {
                                SettingsDialogWrapper.show(
                                  context: context,
                                  content: const AccountsAndProfile(isDialog: true),
                                );
                              },
                              child: SizedBox(
                                width: double.infinity,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Contas e perfils',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: thmode.darkMode
                                              ? Colors.white
                                              : AppColors.darkBG,
                                          fontSize: 14),
                                    ),
                                    Icon(
                                      Icons.keyboard_arrow_right_outlined,
                                      color: thmode.darkMode
                                          ? Colors.white
                                          : AppColors.darkBG,
                                    )
                                  ],
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                SettingsDialogWrapper.show(
                                  context: context,
                                  content: const EditProfilePage(isDialog: true),
                                );
                              },
                              child: SizedBox(
                                width: double.infinity,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Dados pessoais',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: thmode.darkMode
                                              ? Colors.white
                                              : AppColors.darkBG,
                                          fontSize: 14),
                                    ),
                                    Icon(
                                      Icons.keyboard_arrow_right_outlined,
                                      color: thmode.darkMode
                                          ? Colors.white
                                          : AppColors.darkBG,
                                    )
                                  ],
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                SettingsDialogWrapper.show(
                                  context: context,
                                  content: const InformationAndPermissionsPage(isDialog: true),
                                );
                              },
                              child: SizedBox(
                                width: double.infinity,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Suas informações e permissões',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: thmode.darkMode
                                              ? Colors.white
                                              : AppColors.darkBG,
                                          fontSize: 14),
                                    ),
                                    Icon(
                                      Icons.keyboard_arrow_right_outlined,
                                      color: thmode.darkMode
                                          ? Colors.white
                                          : AppColors.darkBG,
                                    )
                                  ],
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                SettingsDialogWrapper.show(
                                  context: context,
                                  content: const BlockedUsersPage(isDialog: true),
                                );
                              },
                              child: SizedBox(
                                width: double.infinity,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Usuários bloqueados',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: thmode.darkMode
                                              ? Colors.white
                                              : AppColors.darkBG,
                                          fontSize: 14),
                                    ),
                                    Icon(
                                      Icons.keyboard_arrow_right_outlined,
                                      color: thmode.darkMode
                                          ? Colors.white
                                          : AppColors.darkBG,
                                    )
                                  ],
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
              Container(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(
                    top: 16, bottom: 16, left: 16, right: 32),
                decoration: BoxDecoration(
                    color: thmode.darkMode
                        ? AppColors.darkBG
                        : AppColors.bodyLight,
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withAlpha(70),
                          offset: const Offset(3.0, 10.0),
                          blurRadius: 15.0)
                    ]),
                child: ExpansionTile(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    side: BorderSide.none,
                  ),
                  collapsedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    side: BorderSide.none,
                  ),
                  textColor: AppColors.patasColor,
                  trailing: AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _isExpanded3 ? 0.25 : 0,
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                    ),
                  ),
                  onExpansionChanged: (value) {
                    setState(() {
                      _isExpanded3 = value;
                    });
                  },
                  title: Text(
                    'Segurança',
                    style: TextStyle(
                        color:
                            thmode.darkMode ? Colors.white : AppColors.darkBG,
                        fontSize: 16),
                  ),
                  leading: Icon(
                    Icons.security_outlined,
                    color: thmode.darkMode
                        ? AppColors.patasColor
                        : AppColors.patasColor,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8, left: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextButton(
                              onPressed: () {
                                SettingsDialogWrapper.show(
                                  context: context,
                                  content: const ChangePasswordPage(isDialog: true),
                                );
                              },
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    flex: 90,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Senha',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: thmode.darkMode
                                                  ? Colors.white
                                                  : AppColors.darkBG,
                                              fontSize: 18),
                                        ),
                                        Text(
                                          'Permite que você altere a senha da sua conta e escolha uma que seja forte e segura.',
                                          style: TextStyle(
                                              color: thmode.darkMode
                                                  ? Colors.white
                                                  : AppColors.darkBG,
                                              fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 10,
                                    child: Icon(
                                      Icons.keyboard_arrow_right_outlined,
                                      color: thmode.darkMode
                                          ? Colors.white
                                          : AppColors.darkBG,
                                    ),
                                  )
                                ],
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    flex: 80,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Alertas de login',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: thmode.darkMode
                                                  ? Colors.white
                                                  : AppColors.darkBG,
                                              fontSize: 18),
                                        ),
                                        Text(
                                          'Permite que você receba notificações quando alguém tentar acessar sua conta de um dispositivo ou navegador desconhecido.',
                                          style: TextStyle(
                                              color: thmode.darkMode
                                                  ? Colors.white
                                                  : AppColors.darkBG,
                                              fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  CupertinoSwitch(
                                    activeTrackColor: AppColors.patasColor,
                                    value: _loginAlerts,
                                    onChanged: (val) {
                                      setState(() => _loginAlerts = val);
                                      _saveSetting('security_alerts', val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Funcionalidade em desenvolvimento. Em breve você poderá adicionar contatos de confiança!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    flex: 90,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Contatos confiáveis',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: thmode.darkMode
                                                  ? Colors.white
                                                  : AppColors.darkBG,
                                              fontSize: 18),
                                        ),
                                        Text(
                                          'Permitem que você escolha amigos que possam te ajudar a recuperar o acesso à sua conta se você esquecer a senha ou for bloqueado.',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: thmode.darkMode
                                                  ? Colors.white
                                                  : AppColors.darkBG,
                                              fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 10,
                                    child: Icon(
                                      Icons.keyboard_arrow_right_outlined,
                                      color: thmode.darkMode
                                          ? Colors.white
                                          : AppColors.darkBG,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(
                    top: 16, bottom: 16, left: 16, right: 32),
                decoration: BoxDecoration(
                    color: thmode.darkMode
                        ? AppColors.darkBG
                        : AppColors.bodyLight,
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withAlpha(70),
                          offset: const Offset(3.0, 10.0),
                          blurRadius: 15.0)
                    ]),
                child: ExpansionTile(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    side: BorderSide.none,
                  ),
                  collapsedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    side: BorderSide.none,
                  ),
                  textColor: AppColors.patasColor,
                  trailing: AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _isExpanded4 ? 0.25 : 0,
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                    ),
                  ),
                  onExpansionChanged: (value) {
                    setState(() {
                      _isExpanded4 = value;
                    });
                  },
                  title: Text(
                    'Notificações',
                    style: TextStyle(
                        color:
                            thmode.darkMode ? Colors.white : AppColors.darkBG,
                        fontSize: 16),
                  ),
                  leading: Icon(
                    Icons.notifications_none_outlined,
                    color: thmode.darkMode
                        ? AppColors.patasColor
                        : AppColors.patasColor,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8, left: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    flex: 80,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Publicações, stories e comentários',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: thmode.darkMode
                                                  ? Colors.white
                                                  : AppColors.darkBG,
                                              fontSize: 18),
                                        ),
                                        Text(
                                          'Permitem que você escolha se quer receber notificações quando alguém publicar algo, compartilhar um story ou comentar em suas publicações ou stories',
                                          style: TextStyle(
                                              color: thmode.darkMode
                                                  ? Colors.white
                                                  : AppColors.darkBG,
                                              fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  CupertinoSwitch(
                                    activeTrackColor: AppColors.patasColor,
                                    value: _notifyPosts,
                                    onChanged: (val) {
                                      setState(() => _notifyPosts = val);
                                      _saveSetting('notify_posts', val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    flex: 80,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Seguindo e seguidores',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: thmode.darkMode
                                                  ? Colors.white
                                                  : AppColors.darkBG,
                                              fontSize: 18),
                                        ),
                                        Text(
                                          'Permitem que você escolha se quer receber notificações quando alguém começar a te seguir, deixar de te seguir ou seguir outras pessoas',
                                          style: TextStyle(
                                              color: thmode.darkMode
                                                  ? Colors.white
                                                  : AppColors.darkBG,
                                              fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  CupertinoSwitch(
                                    activeTrackColor: AppColors.patasColor,
                                    value: _notifyFollowers,
                                    onChanged: (val) {
                                      setState(() => _notifyFollowers = val);
                                      _saveSetting('notify_followers', val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    flex: 80,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'E-mail e SMS',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: thmode.darkMode
                                                  ? Colors.white
                                                  : AppColors.darkBG,
                                              fontSize: 18),
                                        ),
                                        Text(
                                          'Permitem que você escolha se quer receber notificações por e-mail ou SMS sobre as novidades do Patas, dicas para melhorar seu perfil ou lembretes de atividades',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: thmode.darkMode
                                                  ? Colors.white
                                                  : AppColors.darkBG,
                                              fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  CupertinoSwitch(
                                    activeTrackColor: AppColors.patasColor,
                                    value: _notifyEmail,
                                    onChanged: (val) {
                                      setState(() => _notifyEmail = val);
                                      _saveSetting('notify_email', val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(
                    top: 16, bottom: 16, left: 16, right: 32),
                decoration: BoxDecoration(
                    color: thmode.darkMode
                        ? AppColors.darkBG
                        : AppColors.bodyLight,
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withAlpha(70),
                          offset: const Offset(3.0, 10.0),
                          blurRadius: 15.0)
                    ]),
                child: ExpansionTile(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    side: BorderSide.none,
                  ),
                  collapsedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    side: BorderSide.none,
                  ),
                  textColor: AppColors.patasColor,
                  trailing: AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _isExpanded5 ? 0.25 : 0,
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                    ),
                  ),
                  onExpansionChanged: (value) {
                    setState(() {
                      _isExpanded5 = value;
                    });
                  },
                  title: Text(
                    'Ajuda e Suporte',
                    style: TextStyle(
                        color:
                            thmode.darkMode ? Colors.white : AppColors.darkBG,
                        fontSize: 16),
                  ),
                  leading: Icon(
                    Icons.help,
                    color: thmode.darkMode
                        ? AppColors.patasColor
                        : AppColors.patasColor,
                  ),
                  children: [
                    InkWell(
                      onTap: () {
                        SettingsDialogWrapper.show(
                          context: context,
                          content: const HelpSupportPage(isDialog: true),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              flex: 90,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(
                                        bottom: 8, left: 16),
                                    child: Text(
                                      'Acesse nossos canais de suporte e ajuda.',
                                      style: TextStyle(
                                          color: thmode.darkMode
                                              ? Colors.white
                                              : AppColors.darkBG,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(
                                        bottom: 8, left: 16),
                                    child: Text(
                                      'Suas dúvidas a respeito de funcionalidades você encontra na seção (Ajuda). Mas se precisar esclarecer algo específico, acesse a seção (Suporte).',
                                      style: TextStyle(
                                        color: thmode.darkMode
                                            ? Colors.white
                                            : AppColors.darkBG,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 10,
                              child: Icon(
                                Icons.keyboard_arrow_right_outlined,
                                color: thmode.darkMode
                                    ? Colors.white
                                    : AppColors.darkBG,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ─── Legal e Privacidade ─────────────────────────────────
              Container(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(
                    top: 16, bottom: 16, left: 16, right: 32),
                decoration: BoxDecoration(
                    color: thmode.darkMode
                        ? AppColors.darkBG
                        : AppColors.bodyLight,
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withAlpha(70),
                          offset: const Offset(3.0, 10.0),
                          blurRadius: 15.0)
                    ]),
                child: ExpansionTile(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    side: BorderSide.none,
                  ),
                  collapsedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    side: BorderSide.none,
                  ),
                  textColor: AppColors.patasColor,
                  trailing: AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _isExpandedLegal ? 0.25 : 0,
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                    ),
                  ),
                  onExpansionChanged: (value) {
                    setState(() {
                      _isExpandedLegal = value;
                    });
                  },
                  title: Text(
                    'Legal e Privacidade',
                    style: TextStyle(
                        color:
                            thmode.darkMode ? Colors.white : AppColors.darkBG,
                        fontSize: 16),
                  ),
                  leading: const Icon(
                    Icons.shield_outlined,
                    color: AppColors.patasColor,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          TextButton(
                            onPressed: () {
                              SettingsDialogWrapper.show(
                                context: context,
                                content: const LegalPage(
                                  type: LegalDocumentType.terms,
                                ),
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.description_outlined,
                                        color: AppColors.patasColor, size: 20),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Termos de Uso',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: thmode.darkMode
                                            ? Colors.white
                                            : AppColors.darkBG,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  Icons.keyboard_arrow_right_outlined,
                                  color: thmode.darkMode
                                      ? Colors.white
                                      : AppColors.darkBG,
                                ),
                              ],
                            ),
                          ),
                          const Divider(),
                          TextButton(
                            onPressed: () {
                              SettingsDialogWrapper.show(
                                context: context,
                                content: const LegalPage(
                                  type: LegalDocumentType.privacy,
                                ),
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.privacy_tip_outlined,
                                        color: AppColors.patasColor, size: 20),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Política de Privacidade',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: thmode.darkMode
                                            ? Colors.white
                                            : AppColors.darkBG,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  Icons.keyboard_arrow_right_outlined,
                                  color: thmode.darkMode
                                      ? Colors.white
                                      : AppColors.darkBG,
                                ),
                              ],
                            ),
                          ),
                          const Divider(),
                          TextButton(
                            onPressed: () => _showAccountDeletionDialog(context, thmode),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.delete_forever_outlined,
                                        color: Colors.redAccent, size: 20),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Solicitar Exclusão de Conta (LGPD)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.redAccent,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_right_outlined,
                                  color: Colors.redAccent,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(
                    top: 16, bottom: 16, left: 16, right: 32),
                decoration: BoxDecoration(
                    color: thmode.darkMode
                        ? AppColors.darkBG
                        : AppColors.bodyLight,
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withAlpha(70),
                          offset: const Offset(3.0, 10.0),
                          blurRadius: 15.0)
                    ]),
                child: ExpansionTile(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    side: BorderSide.none,
                  ),
                  collapsedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    side: BorderSide.none,
                  ),
                  textColor: AppColors.patasColor,
                  trailing: AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _isExpanded6 ? 0.25 : 0,
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                    ),
                  ),
                  onExpansionChanged: (value) {
                    setState(() {
                      _isExpanded6 = value;
                    });
                  },
                  title: Text(
                    'Sobre o Aplicativo',
                    style: TextStyle(
                        color:
                            thmode.darkMode ? Colors.white : AppColors.darkBG,
                        fontSize: 16),
                  ),
                  leading: Icon(
                    Icons.ac_unit,
                    color: thmode.darkMode
                        ? AppColors.patasColor
                        : AppColors.patasColor,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            height: 180,
                            width: 180,
                            margin: const EdgeInsets.only(top: 6),
                            child: Card(
                                elevation: 0,
                                color: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(8)),
                                  child: Image.asset(
                                    'assets/logo.png',
                                    fit: BoxFit.cover,
                                  ),
                                )),
                          ),
                          SizedBox(
                              width: 210,
                              child: Center(
                                child: RichText(
                                  text: TextSpan(children: [
                                    TextSpan(
                                      text: 'Patas',
                                      style: TextStyle(
                                        color: AppColors.patasColor,
                                        fontSize: 60,
                                        fontFamily: 'Fredoka',
                                        shadows: [
                                          Shadow(
                                            blurRadius: 5,
                                            color: Colors.black
                                                .withValues(alpha: 0.5),
                                            offset: const Offset(2, 2),
                                          ),
                                        ],
                                      ),
                                    )
                                  ]),
                                ),
                              )),
                          Container(
                            width: 210,
                            margin: const EdgeInsets.only(bottom: 40),
                            child: Text(
                              'Versão: $_appVersion',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: thmode.darkMode
                                    ? Colors.white
                                    : AppColors.darkBG,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 210,
                            child: Text(
                              'Desenvolvido por:',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: thmode.darkMode
                                    ? Colors.white
                                    : AppColors.darkBG,
                              ),
                            ),
                          ),
                          Container(
                            height: 110,
                            width: 180,
                            margin: const EdgeInsets.only(top: 6),
                            child: SizedBox(
                                child: ClipRRect(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(8)),
                              child: Image.asset(
                                'assets/anime/origem2026.png',
                                height: 93.5,
                                width: 153,
                                fit: BoxFit.contain,
                              ),
                            )),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(
                    top: 16, bottom: 16, left: 16, right: 32),
                decoration: BoxDecoration(
                    color: thmode.darkMode
                        ? AppColors.darkBG
                        : AppColors.bodyLight,
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withAlpha(70),
                          offset: const Offset(3.0, 10.0),
                          blurRadius: 15.0)
                    ]),
                child: ExpansionTile(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    side: BorderSide.none,
                  ),
                  collapsedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    side: BorderSide.none,
                  ),
                  textColor: AppColors.patasColor,
                  trailing: AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _isExpanded7 ? 0.25 : 0,
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                    ),
                  ),
                  onExpansionChanged: (value) {
                    setState(() {
                      _isExpanded7 = value;
                    });
                  },
                  title: Text(
                    'Sair',
                    style: TextStyle(
                        color:
                            thmode.darkMode ? Colors.white : AppColors.darkBG,
                        fontSize: 16),
                  ),
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.patasColor,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 200,
                            margin: const EdgeInsets.only(bottom: 8, left: 16),
                            child: Text(
                              'Sair da sua conta?',
                              style: TextStyle(
                                  color: thmode.darkMode
                                      ? Colors.white
                                      : AppColors.darkBG,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          ElevatedButton(
                              onPressed: () async {
                                // Limpeza de estado PROFUNDA e deslogar de forma garantida
                                final activeAccountProvider =
                                    Provider.of<ActiveAccountProvider>(context, listen: false);
                                final activePetProvider =
                                    Provider.of<ActivePetProvider>(context, listen: false);

                                await activeAccountProvider.clearData();
                                activePetProvider.clearData();

                                // 1. Limpa SharedPreferences e SecureStorage locais
                                try {
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.clear();
                                } catch (_) {}

                                try {
                                  await const SecureStorage().deleteAll();
                                } catch (_) {}

                                // 2. Efetua o SignOut no Supabase (desloga local e globalmente)
                                try {
                                  await Supabase.instance.client.auth.signOut(scope: SignOutScope.global);
                                } catch (_) {
                                  try {
                                    await locator.get<AuthService>().signOut();
                                  } catch (_) {}
                                }

                                // 3. Reseta tab de navegação e redireciona obrigatoriamente para a tela de Login via Root NavigatorKey
                                bottomNavIndexNotifier.value = 2;
                                navigatorKey.currentState?.pushNamedAndRemoveUntil(
                                  NamedRoute.signIn,
                                  (route) => false,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.lightBG,
                              ),
                              child: const Text(
                                'Sair',
                                style: TextStyle(
                                    color: AppColors.patasColor, fontSize: 16),
                              ))
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                  height: 100), // Espaço extra para o BottomNavigationBar
            ],
          ),
        ),
      ),
    ),
  ),
);
  }

  void _showAccountDeletionDialog(BuildContext context, DarkMode thmode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: thmode.darkMode ? AppColors.darkBG : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text(
              'Exclusão de Conta',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Em conformidade com a LGPD, ao solicitar a exclusão de sua conta, seus dados pessoais, fotos e perfis de pets serão desativados permanentemente de nossa plataforma ativa.\n\nTem certeza de que deseja prosseguir com a solicitação?',
          style: TextStyle(
            color: thmode.darkMode ? Colors.white70 : Colors.black87,
            fontSize: 13.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Solicitação enviada. Nossa equipe processará a exclusão de seus dados em até 48h conforme a LGPD.',
                  ),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            child: const Text('Confirmar Exclusão'),
          ),
        ],
      ),
    );
  }
}
