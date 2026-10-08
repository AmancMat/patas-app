import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app.dart';
import '../../../main.dart';
import '../../constants/app_colors.dart';
import '../home/profile/profile_page.dart';
import '../ongs_corp/org_profile_page.dart';
import '../pets/models/follow_item_model.dart';
import '../pets/services/follow_service.dart';
import 'package:patas_web_app/src/common_widgets/mobile_scroll_padding.dart';

import 'package:patas_web_app/src/localization/localizations_ext.dart';

class FollowListPage extends StatefulWidget {
  final String? petId; // Para buscar seguidores deste Pet
  final String? userId; // Para buscar quem este Usuário segue
  final int initialIndex;

  const FollowListPage({
    super.key,
    this.petId,
    this.userId,
    this.initialIndex = 0,
  });

  @override
  State<FollowListPage> createState() => _FollowListPageState();
}

class _FollowListPageState extends State<FollowListPage> {
  final FollowService _followService = FollowService();
  late Future<List<FollowItem>> _followersFuture;
  late Future<List<FollowItem>> _followingFuture;

  @override
  void initState() {
    super.initState();
    _followersFuture = Future.value([]);
    _followingFuture = Future.value([]);
    _loadData();
  }

  Future<void> _loadData() async {
    String? effectivePetId = widget.petId;
    String? effectiveUserId = widget.userId;

    // Se temos apenas petId, tenta descobrir o userId do dono do pet
    if (effectiveUserId == null && effectivePetId != null) {
      try {
        final res = await supabase
            .from('pets')
            .select('user_id')
            .eq('id', effectivePetId)
            .maybeSingle();
        effectiveUserId = res?['user_id'] as String?;
      } catch (_) {}
    }

    // Se temos apenas userId, tenta descobrir o pet principal para seguidores
    if (effectivePetId == null && effectiveUserId != null) {
      try {
        final res = await supabase
            .from('pets')
            .select('id')
            .eq('user_id', effectiveUserId)
            .limit(1)
            .maybeSingle();
        effectivePetId = res?['id'] as String?;
      } catch (_) {}
    }

    effectiveUserId ??= supabase.auth.currentUser?.id;

    if (mounted) {
      setState(() {
        if (effectivePetId != null) {
          _followersFuture = _followService.getFollowersItems(effectivePetId);
        } else {
          _followersFuture = Future.value([]);
        }

        if (effectiveUserId != null) {
          _followingFuture = _followService.getFollowingItems(effectiveUserId);
        } else {
          _followingFuture = Future.value([]);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialIndex,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBG : const Color(0xFFF9F9FB),
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.patasColor,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            context.tr('profile.connections'),
            style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold),
          ),
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          foregroundColor: isDark ? Colors.white : AppColors.darkBG,
          bottom: TabBar(
            indicatorColor: AppColors.patasColor,
            labelColor: AppColors.patasColor,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            tabs: [
              Tab(text: context.tr('profile.followers')),
              Tab(text: context.tr('profile.following')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList(_followersFuture, isDark, context.tr('profile.no_followers_yet')),
            _buildList(_followingFuture, isDark, context.tr('profile.not_following_yet')),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    Future<List<FollowItem>> future,
    bool isDark,
    String emptyMsg,
  ) {
    return FutureBuilder<List<FollowItem>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.patasColor),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              context.tr('profile.error_loading_connections'),
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
          );
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 56,
                    color: Colors.grey.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    emptyMsg,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.only(
            top: 10,
            bottom: MobileScrollPadding.bottomInset(context),
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];

            Color badgeColor;
            String badgeText;
            IconData fallbackIcon;

            switch (item.type) {
              case FollowItemType.ong:
                badgeColor = const Color(0xFF2E7D32);
                badgeText = context.tr('profile.badge_ong');
                fallbackIcon = Icons.volunteer_activism;
                break;
              case FollowItemType.corp:
                badgeColor = const Color(0xFF1976D2);
                badgeText = context.tr('profile.badge_corp');
                fallbackIcon = Icons.business;
                break;
              case FollowItemType.pet:
                badgeColor = AppColors.patasColor;
                badgeText = context.tr('profile.badge_pet');
                fallbackIcon = Icons.pets;
                break;
              case FollowItemType.tutor:
                badgeColor = const Color(0xFF7B1FA2);
                badgeText = context.tr('profile.badge_tutor');
                fallbackIcon = Icons.person;
                break;
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: badgeColor.withValues(alpha: 0.15),
                  backgroundImage:
                      (item.photoUrl != null && item.photoUrl!.isNotEmpty)
                          ? NetworkImage(item.photoUrl!)
                          : null,
                  child: (item.photoUrl == null || item.photoUrl!.isEmpty)
                      ? Icon(fallbackIcon, size: 24, color: badgeColor)
                      : null,
                ),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.darkBG,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: badgeColor.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey,
                ),
                onTap: () {
                  if (item.type == FollowItemType.pet && item.pet != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(pet: item.pet!),
                      ),
                    );
                  } else if (item.type == FollowItemType.ong) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrgProfilePage(
                          ong: item.ong,
                          ongId: item.id,
                        ),
                      ),
                    );
                  } else if (item.type == FollowItemType.corp) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrgProfilePage(
                          corp: item.corp,
                          corpId: item.id,
                        ),
                      ),
                    );
                  } else if (item.type == FollowItemType.tutor) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProfilePage(userId: item.userId ?? item.id),
                      ),
                    );
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}
