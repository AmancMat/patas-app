import 'package:flutter/material.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/models/notification_model.dart';
import 'package:patas_web_app/src/services/supabase_notification_service.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/utils/date_utils.dart';
import 'package:patas_web_app/src/features/home/profile/profile_page.dart';
import 'package:patas_web_app/src/features/home/timeline/post_detail_page.dart';
import 'package:patas_web_app/src/features/acolhe/screens/ong_donations_dashboard_screen.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:patas_web_app/src/common_widgets/mobile_scroll_padding.dart';
import '../../../../app.dart';
import 'package:patas_web_app/core/localization/app_localizations.dart';

class NotificationsPage extends StatefulWidget {
  final bool isDialog;
  const NotificationsPage({super.key, this.isDialog = false});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final SupabaseNotificationService _notificationService =
      SupabaseNotificationService();

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);

    if (widget.isDialog) {
      return _buildDialogVersion(thmode, isDark, dividerColor);
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBG : Colors.white,
      appBar: PatasEssencialAppBar(
        title: context.tr('notifications.title'),
        subtitle: context.tr('notifications.subtitle'),
        leadingIcon: const Icon(
          Icons.notifications_active_rounded,
          color: AppColors.patasColor,
          size: 22,
        ),
        showBackButton: true,
        showPetSelector: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: AppColors.patasColor),
            onPressed: () => _markAllAsRead(context),
            tooltip: context.tr('notifications.mark_all_read'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _buildNotificationsList(isDark, dividerColor),
        ),
      ),
    );
  }

  Future<void> _markAllAsRead(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = context.tr('notifications.all_marked_read');
    await _notificationService.markAllAsRead();
    messenger.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildDialogVersion(DarkMode thmode, bool isDark, Color dividerColor) {
    return Container(
      width: 450,
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBG : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 12, 12),
            child: Row(
              children: [
                Text(
                  context.tr('notifications.title'),
                  style: TextStyle(
                    color: AppColors.patasColor,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Fredoka',
                    fontSize: 20,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.done_all, color: AppColors.patasColor),
                  onPressed: () => _markAllAsRead(context),
                  tooltip: context.tr('notifications.mark_all_read'),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: dividerColor),
          Expanded(child: _buildNotificationsList(isDark, dividerColor)),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(bool isDark, Color dividerColor) {
    return StreamBuilder<List<NotificationModel>>(
      stream: _notificationService.streamNotifications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.patasColor),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(context.tr('notifications.error').replaceFirst('{error}', '${snapshot.error}')),
          );
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_off_outlined,
                  size: 64,
                  color: isDark ? Colors.white24 : Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('notifications.empty'),
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: notifications.length + 1,
          padding: const EdgeInsets.symmetric(vertical: 4),
          separatorBuilder: (context, index) {
            if (index >= notifications.length) return const SizedBox.shrink();
            return Divider(
              height: 1,
              thickness: 1,
              color: dividerColor,
              indent: 16,
              endIndent: 16,
            );
          },
          itemBuilder: (context, index) {
            if (index == notifications.length) {
              return const MobileScrollPadding();
            }
            final notification = notifications[index];
            return _NotificationItem(
              notification: notification,
              isDark: isDark,
              onTap: () {
                _notificationService.markAsRead(notification.id);

                if (widget.isDialog) {
                  Navigator.pop(context);
                }

                if (notification.type == NotificationType.follow) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfilePage(
                        userId:
                            notification.senderPet?.userId ??
                            notification.data['follower_id'],
                        pet: notification.senderPet,
                      ),
                    ),
                  );
                } else if (notification.type == NotificationType.like ||
                    notification.type == NotificationType.comment) {
                  final String? postId = notification.data['post_id'];
                  if (postId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailPage(postId: postId),
                      ),
                    );
                  }
                } else if (notification.type == NotificationType.donation) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OngDonationsDashboardScreen(),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final bool isDark;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.notification,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: notification.isRead
          ? Colors.transparent
          : (isDark
              ? AppColors.patasColor.withValues(alpha: 0.12)
              : AppColors.patasColor.withValues(alpha: 0.06)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        onTap: onTap,
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: _getTypeColor(
            notification.type,
          ).withValues(alpha: 0.15),
          child: Icon(
            _getTypeIcon(notification.type),
            color: _getTypeColor(notification.type),
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: notification.isRead
                ? FontWeight.w500
                : FontWeight.bold,
            color: isDark ? Colors.white : AppColors.darkBG,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(
              notification.content,
              style: TextStyle(
                fontFamily: 'Fredoka',
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              PatasDateUtils.formatFriendlyDate(notification.createdAt),
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey.shade500,
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: !notification.isRead
            ? Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: AppColors.patasColor,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      ),
    );
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return Icons.favorite;
      case NotificationType.comment:
        return Icons.comment;
      case NotificationType.follow:
        return Icons.person_add;
      case NotificationType.vaccine:
        return Icons.medical_services;
      case NotificationType.system:
        return Icons.info_outline;
      case NotificationType.donation:
        return Icons.volunteer_activism_rounded;
      case NotificationType.rescueAlert:
        return Icons.emergency_rounded;
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return Colors.red;
      case NotificationType.comment:
        return Colors.blue;
      case NotificationType.follow:
        return Colors.green;
      case NotificationType.vaccine:
        return Colors.orange;
      case NotificationType.system:
        return AppColors.patasColor;
      case NotificationType.donation:
        return const Color(0xFF10B981);
      case NotificationType.rescueAlert:
        return const Color(0xFFEF4444);
    }
  }
}
