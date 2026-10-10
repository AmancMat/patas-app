import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/features/love/services/patas_love_service.dart';
import 'package:patas_web_app/src/localization/localizations_ext.dart';
import 'package:patas_web_app/src/common_widgets/mobile_scroll_padding.dart';
import '../../../app.dart';

class BlockedUsersPage extends StatefulWidget {
  final bool isDialog;
  const BlockedUsersPage({super.key, this.isDialog = false});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  final PatasLoveService _loveService = PatasLoveService();
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;
  List<Map<String, dynamic>> _blockedUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchBlockedUsers();
  }

  Future<void> _fetchBlockedUsers() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    final users = await _loveService.getBlockedUsers(currentUserId);

    if (mounted) {
      setState(() {
        _blockedUsers = users;
        _isLoading = false;
      });
    }
  }

  Future<void> _unblockUser(String blockedId, String userName) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    final unblockTitle = context.tr('blocked.unblock_title');
    final unblockDesc = context.tr('blocked.unblock_desc', {'name': userName});
    final unblockSuccessMsg = context.tr('blocked.unblock_success', {'name': userName});
    final unblockErrorMsg = context.tr('blocked.unblock_error');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(unblockTitle),
        content: Text(unblockDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.tr('common.cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.patasColor),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.tr('blocked.unblock_btn'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await _loveService.unblockUser(
      blockerId: currentUserId,
      blockedId: blockedId,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(unblockSuccessMsg)),
        );
        _fetchBlockedUsers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(unblockErrorMsg)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    final bodyContent = _isLoading
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: AppColors.patasColor),
            ),
          )
        : _blockedUsers.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 64,
                        color: isDark ? Colors.white38 : Colors.black26,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('blocked.empty_title'),
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 18,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('blocked.empty_desc'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                shrinkWrap: widget.isDialog,
                physics: widget.isDialog ? const NeverScrollableScrollPhysics() : null,
                padding: const EdgeInsets.all(16),
                itemCount: _blockedUsers.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == _blockedUsers.length) {
                    return const MobileScrollPadding();
                  }

                  final user = _blockedUsers[index];
                  final name = user['user_name'] as String;
                  final photo = user['user_photo'] as String?;
                  final blockedId = user['blocked_id'] as String;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBG : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.patasColor.withValues(alpha: 0.15),
                          backgroundImage: photo != null && photo.isNotEmpty
                              ? NetworkImage(photo)
                              : null,
                          child: photo == null || photo.isEmpty
                              ? const Icon(Icons.person, color: AppColors.patasColor)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isDark ? Colors.white : AppColors.darkBG,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                context.tr('blocked.user_badge'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white54 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.patasColor,
                            side: const BorderSide(color: AppColors.patasColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          onPressed: () => _unblockUser(blockedId, name),
                          child: Text(
                            context.tr('blocked.unblock_btn'),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );

    if (widget.isDialog) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('blocked.title'),
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 22,
                    color: AppColors.patasColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: context.tr('common.close'),
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: isDark ? Colors.white10 : Colors.grey.shade200),
          bodyContent,
        ],
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.bodygray : Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBG : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.patasColor,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('blocked.title'),
          style: const TextStyle(
            fontFamily: 'Fredoka',
            color: AppColors.patasColor,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: bodyContent,
    );
  }
}
