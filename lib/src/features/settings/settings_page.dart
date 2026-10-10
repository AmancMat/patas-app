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
import 'package:patas_web_app/src/providers/locale_provider.dart';
import 'package:patas_web_app/src/localization/localizations_ext.dart';
import 'package:patas_web_app/src/common_widgets/mobile_scroll_padding.dart';

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
  bool _isExpandedLanguage = false;

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
    final localeProvider = Provider.of<LocaleProvider>(context);
    return Scaffold(
      backgroundColor:
          thmode.darkMode ? AppColors.bodygray : Colors.grey.shade300,
      appBar: AppBar(
        backgroundColor:
            thmode.darkMode ? AppColors.bodygray : Colors.grey.shade300,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          context.tr('settings.title'),
          style: const TextStyle(
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
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 7),
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
                    context.tr('settings.theme_title'),
                    style: TextStyle(
                        color:
                            thmode.darkMode ? Colors.white : AppColors.darkBG,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    context.tr('settings.theme_subtitle'),
                    style: TextStyle(
                      fontSize: 12,
                      color: thmode.darkMode ? Colors.white60 : Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  leading: const Icon(
                    Icons.palette_outlined,
                    color: AppColors.patasColor,
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
                                  context.tr('settings.theme_desc'),
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
                                  context.tr('settings.notification_sound_title'),
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
                                      child: Text(context.tr('settings.notification_sound_test')),
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
              // ─── Seção 1.5: Idioma e Região (i18n) ──────────────────────────
              Container(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
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
                    turns: _isExpandedLanguage ? 0.25 : 0,
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                    ),
                  ),
                  onExpansionChanged: (value) {
                    setState(() {
                      _isExpandedLanguage = value;
                    });
                  },
                  title: Text(
                    context.tr('settings.language_section_title'),
                    style: TextStyle(
                        color:
                            thmode.darkMode ? Colors.white : AppColors.darkBG,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    localeProvider.isPortuguese
                        ? '🇧🇷 ${context.tr('settings.portuguese_label')} (${context.tr('settings.active_badge')})'
                        : '🇺🇸 ${context.tr('settings.english_label')} (${context.tr('settings.active_badge')})',
                    style: TextStyle(
                      fontSize: 12,
                      color: thmode.darkMode ? Colors.white60 : Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  leading: const Icon(
                    Icons.language_rounded,
                    color: AppColors.patasColor,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('settings.language_section_desc'),
                            style: TextStyle(
                              color: thmode.darkMode
                                  ? Colors.white70
                                  : Colors.black87,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Opção 1: Português (Brasil)
                          _buildLanguageOptionCard(
                            context: context,
                            title: context.tr('settings.portuguese_label'),
                            subtitle: context.tr('settings.portuguese_sub'),
                            flag: '🇧🇷',
                            isSelected: localeProvider.isPortuguese,
                            thmode: thmode,
                            onTap: () async {
                              await localeProvider.setPortuguese();
                            },
                          ),
                          const SizedBox(height: 10),
                          // Opção 2: Inglês (EUA / Global)
                          _buildLanguageOptionCard(
                            context: context,
                            title: context.tr('settings.english_label'),
                            subtitle: context.tr('settings.english_sub'),
                            flag: '🇺🇸',
                            isSelected: localeProvider.isEnglish,
                            thmode: thmode,
                            onTap: () async {
                              await localeProvider.setEnglish();
                            },
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.patasColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.patasColor.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  size: 16,
                                  color: AppColors.patasColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    context.tr('settings.language_hint'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: thmode.darkMode
                                          ? Colors.white70
                                          : AppColors.darkBG,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
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
                    context.tr('settings.accessibility_title'),
                    style: TextStyle(
                        color:
                            thmode.darkMode ? Colors.white : AppColors.darkBG,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    context.tr('settings.accessibility_subtitle'),
                    style: TextStyle(
                      fontSize: 12,
                      color: thmode.darkMode ? Colors.white60 : Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  leading: const Icon(
                    Icons.accessibility_new_rounded,
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
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
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
                    context.tr('settings.privacy_title'),
                    style: TextStyle(
                        color:
                            thmode.darkMode ? Colors.white : AppColors.darkBG,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    context.tr('settings.privacy_subtitle'),
                    style: TextStyle(
                      fontSize: 12,
                      color: thmode.darkMode ? Colors.white60 : Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  leading: const Icon(
                    Icons.privacy_tip_outlined,
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
                                      context.tr('settings.privacy_accounts'),
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
                                      context.tr('settings.privacy_personal_data'),
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
                                      context.tr('settings.privacy_info_permissions'),
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
                                      context.tr('settings.privacy_blocked_users'),
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
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
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
                    context.tr('settings.security_title'),
                    style: TextStyle(
                        color:
                            thmode.darkMode ? Colors.white : AppColors.darkBG,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    context.tr('settings.security_subtitle'),
                    style: TextStyle(
                      fontSize: 12,
                      color: thmode.darkMode ? Colors.white60 : Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  leading: const Icon(
                    Icons.security_outlined,
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
                                          context.tr('settings.security_password_label'),
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: thmode.darkMode
                                                  ? Colors.white
                                                  : AppColors.darkBG,
                                              fontSize: 18),
                                        ),
                                        Text(
                                          context.tr('settings.security_password_desc'),
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
                                          context.tr('settings.security_alerts_label'),
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: thmode.darkMode
                                                  ? Colors.white
                                                  : AppColors.darkBG,
                                              fontSize: 18),
                                        ),
                                        Text(
                                          context.tr('settings.security_alerts_desc'),
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
                                  SnackBar(
                                    content: Text(
                                        context.tr('settings.security_trusted_snackbar')),
                                    duration: const Duration(seconds: 2),
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
                                          context.tr('settings.security_trusted_contacts_label'),
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: thmode.darkMode
                                                  ? Colors.white
                                                  : AppColors.darkBG,
                                              fontSize: 18),
                                        ),
                                        Text(
                                          context.tr('settings.security_trusted_contacts_desc'),
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
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
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
                    context.tr('settings.notifications_title'),
                    style: TextStyle(
                        color:
                            thmode.darkMode ? Colors.white : AppColors.darkBG,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    context.tr('settings.notifications_subtitle'),
                    style: TextStyle(
                      fontSize: 12,
                      color: thmode.darkMode ? Colors.white60 : Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  leading: const Icon(
                    Icons.notifications_none_outlined,
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
                                          context.tr('settings.notifications_posts_label'),
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: thmode.darkMode
                                                  ? Colors.white
                                                  : AppColors.darkBG,
                                              fontSize: 18),
                                        ),
                                        Text(
                                          context.tr('settings.notifications_posts_desc'),
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
                                          context.tr('settings.notifications_followers_label'),
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: thmode.darkMode
                                                  ? Colors.white
                                                  : AppColors.darkBG,
                                              fontSize: 18),
                                        ),
                                        Text(
                                          context.tr('settings.notifications_followers_desc'),
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
                                          context.tr('settings.notifications_email_sms_label'),
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: thmode.darkMode
                                                  ? Colors.white
                                                  : AppColors.darkBG,
                                              fontSize: 18),
                                        ),
                                        Text(
                                          context.tr('settings.notifications_email_sms_desc'),
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
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
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
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                    ),
                  ),
                  onExpansionChanged: (value) {
                    setState(() {
                      _isExpanded5 = value;
                    });
                  },
                  title: Text(
                    context.tr('settings.help_title'),
                    style: TextStyle(
                        color:
                            thmode.darkMode ? Colors.white : AppColors.darkBG,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    context.tr('settings.help_subtitle'),
                    style: TextStyle(
                      fontSize: 12,
                      color: thmode.darkMode ? Colors.white60 : Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  leading: const Icon(
                    Icons.help_outline_rounded,
                    color: AppColors.patasColor,
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
                                      context.tr('settings.help_support_banner_title'),
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
                                      context.tr('settings.help_support_banner_desc'),
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
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
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
                    context.tr('settings.legal_title'),
                    style: TextStyle(
                        color:
                            thmode.darkMode ? Colors.white : AppColors.darkBG,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    context.tr('settings.legal_subtitle'),
                    style: TextStyle(
                      fontSize: 12,
                      color: thmode.darkMode ? Colors.white60 : Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                                      context.tr('settings.terms_of_use'),
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
                                      context.tr('settings.privacy_policy'),
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
                                      context.tr('settings.request_account_deletion'),
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
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
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
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                    ),
                  ),
                  onExpansionChanged: (value) {
                    setState(() {
                      _isExpanded6 = value;
                    });
                  },
                  title: Text(
                    context.tr('settings.about_title'),
                    style: TextStyle(
                        color:
                            thmode.darkMode ? Colors.white : AppColors.darkBG,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    context.t('settings.about_subtitle', args: {
                      'version': _appVersion.isNotEmpty
                          ? _appVersion.split(' ').first
                          : '1.0.0'
                    }),
                    style: TextStyle(
                      fontSize: 12,
                      color: thmode.darkMode ? Colors.white60 : Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  leading: const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.patasColor,
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
                              context.t('settings.version_label',
                                  args: {'version': _appVersion}),
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
                              context.tr('settings.developed_by'),
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
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
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
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                    ),
                  ),
                  onExpansionChanged: (value) {
                    setState(() {
                      _isExpanded7 = value;
                    });
                  },
                  title: Text(
                    context.tr('settings.logout_title'),
                    style: TextStyle(
                        color:
                            thmode.darkMode ? Colors.white : AppColors.darkBG,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    context.tr('settings.logout_subtitle'),
                    style: TextStyle(
                      fontSize: 12,
                      color: thmode.darkMode ? Colors.white60 : Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                              context.tr('settings.logout_prompt'),
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
                              child: Text(
                                context.tr('settings.logout_action'),
                                style: TextStyle(
                                    color: AppColors.patasColor, fontSize: 16),
                              ))
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const MobileScrollPadding(),
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
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(
              context.tr('settings.deletion_dialog_title'),
              style: const TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          context.tr('settings.deletion_dialog_content'),
          style: TextStyle(
            color: thmode.darkMode ? Colors.white70 : Colors.black87,
            fontSize: 13.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('common.cancel')),
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
                SnackBar(
                  content: Text(
                    context.tr('settings.deletion_dialog_snackbar'),
                  ),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            child: Text(context.tr('settings.deletion_dialog_confirm')),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOptionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String flag,
    required bool isSelected,
    required DarkMode thmode,
    required VoidCallback onTap,
  }) {
    final borderColor = isSelected
        ? AppColors.patasColor
        : (thmode.darkMode ? Colors.white12 : Colors.grey.shade300);
    final cardBg = isSelected
        ? AppColors.patasColor.withValues(alpha: 0.1)
        : (thmode.darkMode ? Colors.white.withValues(alpha: 0.03) : Colors.white);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.patasColor.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: thmode.darkMode ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.patasColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      context.tr('settings.active_badge'),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else
              Icon(
                Icons.radio_button_unchecked,
                size: 20,
                color: thmode.darkMode ? Colors.white38 : Colors.grey.shade400,
              ),
          ],
        ),
      ),
    );
  }
}
