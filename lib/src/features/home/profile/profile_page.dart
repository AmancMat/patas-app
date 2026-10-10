import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:patas_web_app/src/features/family/create_family_member_page.dart';
import 'package:patas_web_app/src/features/family/edit_family_member_page.dart';
import 'package:patas_web_app/src/features/family/models/family_member_model.dart';
import 'package:patas_web_app/src/features/family/services/family_service.dart';
import 'package:patas_web_app/src/features/pets/active_pet_provider.dart';
import 'package:patas_web_app/src/providers/active_account_provider.dart';
import 'package:patas_web_app/src/models/active_account_model.dart';
import 'package:patas_web_app/src/features/settings/edit_profile_page.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:provider/provider.dart';
import '../../../../app.dart';
import '../../../../main.dart';
import '../../../constants/app_colors.dart';
import 'package:patas_web_app/src/features/home/profile/photo_content_widget.dart';
import 'package:patas_web_app/src/features/home/profile/publish_widget.dart';
import 'package:patas_web_app/src/features/home/profile/start_publish_widget.dart';
import 'package:patas_web_app/src/features/pets/models/pet_model.dart';
import 'package:patas_web_app/src/features/pets/pets_create/add_kind_page.dart';
import 'package:patas_web_app/src/features/pets/pets_edit/edit_pet_page.dart';
import 'package:patas_web_app/src/features/pets/services/pet_service.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../timeline/models/post_model.dart';
import '../timeline/services/post_service.dart';
import '../pet_detail.dart';
import '../../pets/services/follow_service.dart';
import '../../pets/follow_list_page.dart';
import 'package:patas_web_app/src/features/love/services/patas_love_service.dart';
import 'package:patas_web_app/src/providers/profile_view_provider.dart';
import 'package:patas_web_app/src/localization/localizations_ext.dart';

class ProfilePage extends StatefulWidget {
  final Pet? pet;
  final String? userId;

  const ProfilePage({super.key, this.pet, this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FocusNode _focusNode = FocusNode();
  late Color color = Colors.red;

  final PetService _petService = PetService();
  late Future<List<Pet>> _petsFuture;

  final FamilyService _familyService = FamilyService();
  late Future<List<FamilyMember>> _familyFuture;

  final PostService _postService = PostService();
  late Future<List<Post>> _postsFuture;

  final FollowService _followService = FollowService();
  final PatasLoveService _loveService = PatasLoveService();
  bool _isFollowing = false;
  late Future<int> _followersCountFuture;
  late Future<int> _followingCountFuture;

  Pet? _displayPet;

  String? _lastActiveAccountId;
  String? _lastActivePetId;

  String get _targetUserId {
    if (widget.userId != null) return widget.userId!;
    if (widget.pet != null) return widget.pet!.userId;
    return supabase.auth.currentUser?.id ?? '';
  }

  bool get _isOwner {
    final currentUserId = supabase.auth.currentUser?.id;
    return _targetUserId == currentUserId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isOwner) {
      final activeAccount =
          Provider.of<ActiveAccountProvider>(context).activeAccount;
      final activePet = Provider.of<ActivePetProvider>(context).activePet;

      if (activeAccount?.id != _lastActiveAccountId ||
          activePet?.id != _lastActivePetId) {
        _lastActiveAccountId = activeAccount?.id;
        _lastActivePetId = activePet?.id;
        _refreshData();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPets();
    _loadFamilyMembers();
    _loadPosts();
    _loadFollowData();
  }

  Future<void> _loadFollowData() async {
    final activePet = widget.pet ??
        _displayPet ??
        Provider.of<ActivePetProvider>(context, listen: false).activePet;
    final currentUser = supabase.auth.currentUser;
    try {
      if (activePet != null) {
        _followersCountFuture = _followService.getFollowersCount(activePet.id);
      } else {
        _followersCountFuture = Future.value(0);
      }
      if (currentUser != null) {
        _followingCountFuture =
            _followService.getFollowingCount(_targetUserId);
        if (activePet != null) {
          final following = await _followService.isFollowing(activePet.id);
          if (mounted) {
            setState(() {
              _isFollowing = following;
            });
          }
        }
      } else {
        _followingCountFuture = Future.value(0);
      }
      await Future.wait([_followersCountFuture, _followingCountFuture]);
    } catch (e) {
      debugPrint('Erro ao carregar dados de seguimento: $e');
      if (mounted) {
        _followersCountFuture = Future.value(0);
        _followingCountFuture = Future.value(0);
      }
    }
  }

  Future<void> _loadPosts() async {
    final activeAccountProvider =
        Provider.of<ActiveAccountProvider>(context, listen: false);
    final isUserAccount =
        activeAccountProvider.activeAccount?.type == AccountType.user &&
            widget.userId != null;
    final activePet = isUserAccount
        ? null
        : (widget.pet ??
            _displayPet ??
            Provider.of<ActivePetProvider>(context, listen: false).activePet);
    try {
      final postsFuture = _postService.getPosts(
        petId: activePet?.id,
        userId: isUserAccount ? _targetUserId : null,
      );
      setState(() {
        _postsFuture = postsFuture;
      });
      await postsFuture;
    } catch (e) {
      debugPrint('Erro ao carregar posts: $e');
      if (mounted) {
        setState(() {
          _postsFuture = Future.value([]);
        });
      }
      _showErrorSnackBar(e.toString());
    }
  }

  Future<void> _loadPets() async {
    try {
      final targetId = _targetUserId;
      if (targetId.isNotEmpty) {
        final petsFuture = _petService.getPetsByUserId(targetId);
        setState(() {
          _petsFuture = petsFuture;
        });
        final pets = await petsFuture;
        if (mounted) {
          if (_isOwner) {
            final petProv = Provider.of<ActivePetProvider>(context, listen: false);
            if (petProv.activePet == null) {
              petProv.initialize();
            }
          } else {
            if (widget.pet == null && pets.isNotEmpty && _displayPet == null) {
              setState(() {
                _displayPet = pets.first;
              });
              _loadPosts();
              _loadFollowData();
            }
          }
        }
      } else {
        setState(() {
          _petsFuture = Future.value([]);
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar pets: $e');
      if (mounted) {
        setState(() {
          _petsFuture = Future.value([]);
        });
      }
      _showErrorSnackBar(e.toString());
    }
  }

  Future<void> _loadFamilyMembers() async {
    try {
      final targetId = _targetUserId;
      if (targetId.isNotEmpty) {
        final familyFuture = _familyService.getFamilyMembers(targetId);
        setState(() {
          _familyFuture = familyFuture;
        });
        await familyFuture;
      } else {
        setState(() {
          _familyFuture = Future.value([]);
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar familiares: $e');
      if (mounted) {
        setState(() {
          _familyFuture = Future.value([]);
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _loadPets(),
      _loadFamilyMembers(),
      _loadPosts(),
      _loadFollowData(),
    ]);
  }

  Future<void> _pickCoverImage() async {
    final activePet = widget.pet ??
        Provider.of<ActivePetProvider>(context, listen: false).activePet;
    if (activePet == null) return;
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      try {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr('profile.uploading_cover'))));
        }
        final String coverUrl =
            await _petService.uploadPetCover(File(image.path));
        final updatedPet = Pet(
          id: activePet.id,
          userId: activePet.userId,
          name: activePet.name,
          species: activePet.species,
          breed: activePet.breed,
          birthDate: activePet.birthDate,
          photoUrl: activePet.photoUrl,
          createdAt: activePet.createdAt,
          gender: activePet.gender,
          size: activePet.size,
          color: activePet.color,
          birthPlace: activePet.birthPlace,
          currentCity: activePet.currentCity,
          coverUrl: coverUrl,
        );
        await _petService.updatePet(updatedPet);
        if (mounted) {
          Provider.of<ActivePetProvider>(context, listen: false)
              .setActivePet(updatedPet);
          setState(() {});
        }
      } catch (e) {
        debugPrint('Erro ao atualizar capa: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr('profile.cover_update_error', {'error': '$e'}))));
        }
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD PRINCIPAL
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    _focusNode.addListener(() {
      setState(() {
        color = _focusNode.hasFocus ? Colors.blue : Colors.red;
      });
    });
    final thmode = Provider.of<DarkMode>(context);
    final activeAccountProvider = Provider.of<ActiveAccountProvider>(context);
    final activePetProvider = Provider.of<ActivePetProvider>(context);

    final bool isUserAccount =
        activeAccountProvider.activeAccount?.type == AccountType.user &&
            widget.userId != null;

    final Pet? activePet = isUserAccount
        ? null
        : (widget.pet ??
            _displayPet ??
            (_isOwner ? activePetProvider.activePet : null));

    final bool isOwner = _isOwner;

    return ResponsiveLayout(
      mobile: _buildMobileLayout(
          context, thmode, activePet, isOwner, isUserAccount,
          activeAccountProvider: activeAccountProvider),
      desktop: _buildDesktopLayout(
          context, thmode, activePet, isOwner, isUserAccount,
          activeAccountProvider: activeAccountProvider),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MOBILE — Layout original preservado
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout(
    BuildContext context,
    DarkMode thmode,
    Pet? activePet,
    bool isOwner,
    bool isUserAccount, {
    required ActiveAccountProvider activeAccountProvider,
  }) {
    Widget getDisplayAvatar(double radius) {
      if (isUserAccount) {
        if (activeAccountProvider.activeAccount?.photoUrl != null &&
            activeAccountProvider.activeAccount!.photoUrl!.isNotEmpty) {
          return CircleAvatar(
            radius: radius,
            backgroundImage:
                NetworkImage(activeAccountProvider.activeAccount!.photoUrl!),
          );
        }
        return CircleAvatar(
          radius: radius,
          backgroundColor: Colors.white,
          child: Icon(Icons.person_rounded,
              size: radius * 1.2, color: Colors.grey.shade400),
        );
      } else {
        if (activePet?.photoUrl != null && activePet!.photoUrl!.isNotEmpty) {
          return CircleAvatar(
            radius: radius,
            backgroundImage: NetworkImage(activePet.photoUrl!),
          );
        }
        return CircleAvatar(
          radius: radius,
          backgroundColor: Colors.white,
          child: Icon(Icons.pets_rounded,
              size: radius * 1.0, color: Colors.grey.shade400),
        );
      }
    }

    // Fallback de segurança para perfis bloqueados ou indisponíveis
    if (!isOwner && !isUserAccount && activePet == null && widget.pet != null) {
      return Scaffold(
        backgroundColor: thmode.darkMode ? AppColors.darkBG : Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.patasColor, size: 20),
            onPressed: () {
              try {
                Provider.of<ProfileViewProvider>(context, listen: false).clear();
              } catch (_) {}
              bottomNavIndexNotifier.value = 2;
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block_rounded, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  context.tr('profile.unavailable_title'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('profile.unavailable_desc'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: thmode.darkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.patasColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () {
                    try {
                      Provider.of<ProfileViewProvider>(context, listen: false).clear();
                    } catch (_) {}
                    bottomNavIndexNotifier.value = 2;
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(context.tr('profile.back_to_feed'), style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: thmode.darkMode ? AppColors.darkBG : Colors.white,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.patasColor,
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              Skeletonizer(
                enabled: isUserAccount
                    ? activeAccountProvider.isLoading
                    : activePet == null,
                effect: ShimmerEffect(
                  baseColor: thmode.darkMode
                      ? Colors.grey[800]!
                      : AppColors.patasColor.withValues(alpha: 0.1),
                  highlightColor: thmode.darkMode
                      ? Colors.grey[700]!
                      : AppColors.patasColor.withValues(alpha: 0.2),
                ),
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        SizedBox(
                          height: 200,
                          width: double.infinity,
                          child: Image(
                            fit: BoxFit.cover,
                            image: (activePet?.coverUrl != null &&
                                    activePet!.coverUrl!.isNotEmpty)
                                ? NetworkImage(activePet.coverUrl!)
                                : const AssetImage('assets/image_capa.jpg')
                                    as ImageProvider,
                          ),
                        ),
                        if (Navigator.canPop(context))
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 10,
                            left: 15,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                tooltip: 'Voltar',
                                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white, size: 18),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          ),
                        if (isOwner && !isUserAccount)
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 10,
                            right: 20,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: IconButton(
                                tooltip: context.tr('profile.cover_tooltip'),
                                icon: const Icon(Icons.edit,
                                    color: Colors.white, size: 18),
                                onPressed: _pickCoverImage,
                              ),
                            ),
                          ),
                      Positioned(
                        top: 160,
                        left: 10,
                        child: Semantics(
                          label: context.tr('profile.photo_semantic', {'name': activePet?.name ?? (isUserAccount ? activeAccountProvider.activeAccount?.name ?? 'perfil' : 'perfil')}),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.patasColor,
                            child: getDisplayAvatar(48),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 206,
                        left: 115,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SizedBox(
                              height: 28,
                              width: 200,
                              child: Text(
                                activePet?.name ??
                                    (isUserAccount
                                        ? activeAccountProvider
                                                .activeAccount?.name ??
                                            'Nome'
                                        : 'Nome do Perfil'),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                    fontSize: 16,
                                    color: thmode.darkMode
                                        ? Colors.white
                                        : AppColors.darkBG,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (isUserAccount)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  context.tr('profile.tutor_role'),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.patasColor,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            if (activePet?.birthPlace != null &&
                                activePet!.birthPlace!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(children: [
                                  const Icon(Icons.cake_rounded,
                                      size: 13,
                                      color: AppColors.patasColor),
                                  const SizedBox(width: 4),
                                  RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontFamily: 'Fredoka',
                                          color: thmode.darkMode
                                              ? Colors.white70
                                              : Colors.black54),
                                      children: [
                                        TextSpan(
                                            text: context.tr('profile.born_in'),
                                            style: const TextStyle(
                                                fontWeight:
                                                    FontWeight.bold)),
                                        TextSpan(text: activePet.birthPlace),
                                      ],
                                    ),
                                  ),
                                ]),
                              ),
                            if (activePet?.currentCity != null &&
                                activePet!.currentCity!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(children: [
                                  const Icon(Icons.location_on_rounded,
                                      size: 13,
                                      color: AppColors.patasColor),
                                  const SizedBox(width: 4),
                                  RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontFamily: 'Fredoka',
                                          color: thmode.darkMode
                                              ? Colors.white70
                                              : Colors.black54),
                                      children: [
                                        TextSpan(
                                            text: context.tr('profile.lives_in'),
                                            style: const TextStyle(
                                                fontWeight:
                                                    FontWeight.bold)),
                                        TextSpan(
                                            text: activePet.currentCity),
                                      ],
                                    ),
                                  ),
                                ]),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 60, left: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (!isUserAccount)
                          Expanded(
                            flex: 35,
                            child: PetDetail(
                              pet: activePet,
                              isOwner: isOwner,
                            ),
                          ),
                        Expanded(
                          flex: 65,
                          child: Container(
                            padding: const EdgeInsets.only(right: 8),
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Expanded(
                                        child:
                                            FutureBuilder<List<Post>>(
                                      future: _postsFuture,
                                      builder: (context, snapshot) {
                                        final count =
                                            snapshot.data?.length ?? 0;
                                        return _buildStatItem('$count', context.tr('profile.posts_stat'), thmode);
                                      },
                                    )),
                                    Expanded(
                                        child: FutureBuilder<int>(
                                      future: _followingCountFuture,
                                      builder: (context, snapshot) {
                                        final count =
                                            snapshot.data ?? 0;
                                        return _buildStatItem('$count', context.tr('profile.following_stat'), thmode,
                                          onTap: () =>
                                              Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  FollowListPage(
                                                userId: _targetUserId,
                                                petId: activePet?.id,
                                                initialIndex: 1,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    )),
                                    Expanded(
                                        child: FutureBuilder<int>(
                                      future: _followersCountFuture,
                                      builder: (context, snapshot) {
                                        final count =
                                            snapshot.data ?? 0;
                                        return _buildStatItem('$count', context.tr('profile.followers_stat'), thmode,
                                          onTap: () {
                                            if (activePet != null) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      FollowListPage(
                                                    userId: _targetUserId,
                                                    petId: activePet.id,
                                                    initialIndex: 0,
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                        );
                                      },
                                    )),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (activePet != null &&
                                    activePet.userId !=
                                        supabase.auth.currentUser?.id)
                                  _buildFollowButton(activePet),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── Botão editar perfil ─────────────────────────────────────
            if (isUserAccount && isOwner)
              Padding(
                padding: const EdgeInsets.only(top: 20, left: 12, right: 12),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const EditProfilePage()),
                    );
                    if (result == true && context.mounted) {
                      Provider.of<ActiveAccountProvider>(context,
                              listen: false)
                          .initialize();
                      if (mounted) setState(() {});
                    }
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: Text(context.tr('profile.edit_profile_btn')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.patasColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            _buildFamilySection(thmode, isOwner, isUserAccount),
            _buildPhotosSection(thmode, activePet),
            _buildPetsSection(thmode, isOwner),
            _buildPatasLoveExpansionSection(thmode, activePet, isOwner),
            const StartPublishWidget(),
            FutureBuilder<List<Post>>(
              future: _postsFuture,
              builder: (context, snapshot) {
                return PublishWidget(
                  posts: snapshot.data ?? [],
                  isLoading:
                      snapshot.connectionState == ConnectionState.waiting,
                  onActionComplete: _loadPosts,
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DESKTOP — Layout web-friendly
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDesktopLayout(
    BuildContext context,
    DarkMode thmode,
    Pet? activePet,
    bool isOwner,
    bool isUserAccount, {
    required ActiveAccountProvider activeAccountProvider,
  }) {
    final bgColor = thmode.darkMode ? AppColors.bodygray : const Color(0xffF5F5F5);
    final cardBg = thmode.darkMode ? const Color(0xff1e1e1e) : Colors.white;
    final borderColor =
        thmode.darkMode ? Colors.white10 : Colors.grey.shade200;
    final textColor = thmode.darkMode ? Colors.white : AppColors.darkBG;

    // Usando Scaffold para garantir o contexto de Material, essencial para InkWell e outros widgets.
    return Scaffold(
      backgroundColor: bgColor,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.patasColor,
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Card de cabeçalho do perfil ─────────────────────
                    _buildDesktopProfileHeader(
                      context,
                      thmode,
                      activePet,
                      isOwner,
                      isUserAccount,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textColor: textColor,
                      activeAccountProvider: activeAccountProvider,
                    ),
                    const SizedBox(height: 20),
                    // ── Linha de botão editar perfil ────────────────────
                    if (isUserAccount && isOwner)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const EditProfilePage()),
                              );
                              if (result == true && context.mounted) {
                                Provider.of<ActiveAccountProvider>(context,
                                        listen: false)
                                    .initialize();
                                if (mounted) setState(() {});
                              }
                            },
                            icon: const Icon(Icons.edit, size: 18),
                            label: Text(context.tr('profile.edit_profile_btn')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.patasColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                    // ── Layout de 2 colunas: conteúdo + detalhes ───────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Coluna direita: detalhes, família, pets
                        SizedBox(
                          width: 260,
                          child: Column(
                            children: [
                              // Card de detalhes do pet
                              if (!isUserAccount)
                                _buildDesktopCard(
                                  thmode,
                                  cardBg: cardBg,
                                  borderColor: borderColor,
                                  title: context.tr('profile.details_section'),
                                  icon: Icons.info_outline_rounded,
                                  child: PetDetail(
                                    pet: activePet,
                                    isOwner: isOwner,
                                  ),
                                ),
                              if (!isUserAccount) const SizedBox(height: 16),
                              // Card Família
                              _buildDesktopCard(
                                thmode,
                                cardBg: cardBg,
                                borderColor: borderColor,
                                title: context.tr('profile.family_section'),
                                icon: Icons.nature_people,
                                trailing: isOwner
                                    ? IconButton(
                                        tooltip: context.tr('profile.add_family_tooltip'),
                                        icon: Icon(Icons.add,
                                            color: thmode.darkMode
                                                ? Colors.white70
                                                : Colors.black54,
                                            size: 20),
                                        onPressed: () async {
                                          final result = await _openCreateFamilyMember(context);
                                          if (result == true) {
                                            _loadFamilyMembers();
                                          }
                                        },
                                      )
                                    : null,
                                child: _buildFamilyList(thmode, isOwner),
                              ),
                              const SizedBox(height: 16),
                              // Card Meus Pets
                              _buildDesktopCard(
                                thmode,
                                cardBg: cardBg,
                                borderColor: borderColor,
                                title: context.tr('profile.my_pets_section'),
                                icon: Icons.pets_rounded,
                                trailing: isOwner
                                    ? IconButton(
                                        tooltip: context.tr('profile.add_pet_tooltip'),
                                        icon: const Icon(Icons.add_circle,
                                            color: AppColors.patasColor,
                                            size: 22),
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      const AddKindPage()));
                                          if (result == true) _loadPets();
                                        },
                                      )
                                    : null,
                                child: _buildPetsList(thmode, isOwner),
                              ),
                               if (activePet != null) const SizedBox(height: 16),
                               if (activePet != null)
                                 _buildDesktopCard(
                                   thmode,
                                   cardBg: cardBg,
                                   borderColor: borderColor,
                                   title: context.tr('profile.patas_love_title'),
                                   icon: Icons.favorite_rounded,
                                   child: _buildPatasLoveSection(activePet, isOwner, thmode),
                                 ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Coluna esquerda: fotos + posts
                        Expanded(
                          child: Column(
                            children: [
                              // Card Fotos
                              _buildDesktopCard(
                                thmode,
                                cardBg: cardBg,
                                borderColor: borderColor,
                                title: context.tr('profile.photos_section'),
                                icon: Icons.photo_library_outlined,
                                child: PhotoContentWidget(pet: activePet),
                              ),
                              const SizedBox(height: 16),
                              // Publicar + Posts
                              const StartPublishWidget(),
                              const SizedBox(height: 8),
                              FutureBuilder<List<Post>>(
                                future: _postsFuture,
                                builder: (context, snapshot) {
                                  return PublishWidget(
                                    posts: snapshot.data ?? [],
                                    isLoading: snapshot.connectionState ==
                                        ConnectionState.waiting,
                                    onActionComplete: _loadPosts,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Header de perfil desktop ─────────────────────────────────────────────
  Widget _buildDesktopProfileHeader(
    BuildContext context,
    DarkMode thmode,
    Pet? activePet,
    bool isOwner,
    bool isUserAccount, {
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required ActiveAccountProvider activeAccountProvider,
  }) {
    final coverUrl = activePet?.coverUrl;
    final hasCover = coverUrl != null && coverUrl.isNotEmpty;
    final photoUrl = isUserAccount
        ? activeAccountProvider.activeAccount?.photoUrl
        : activePet?.photoUrl;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final name = activePet?.name ??
        (isUserAccount
            ? activeAccountProvider.activeAccount?.name ?? 'Perfil'
            : 'Perfil');

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: thmode.darkMode
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Faixa de capa
          Stack(
            children: [
              SizedBox(
                height: 220, // Altura atualizada para melhorar proporção
                width: double.infinity,
                child: Image(
                  fit: BoxFit.cover,
                  image: hasCover
                      ? NetworkImage(coverUrl) as ImageProvider
                      : const AssetImage('assets/image_capa.jpg'),
                ),
              ),
              if (isOwner && !isUserAccount)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20)),
                    child: IconButton(
                      tooltip: context.tr('profile.cover_tooltip'),
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: _pickCoverImage,
                    ),
                  ),
                ),
            ],
          ),
          // Informações do perfil
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Avatar (sobrepõe capa)
                Transform.translate(
                  offset: const Offset(0, -36),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: cardBg, width: 4),
                    ),
                    child: Semantics(
                      label: context.tr('profile.photo_semantic', {'name': name}),
                      child: CircleAvatar(
                        radius: 52,
                        backgroundColor:
                            AppColors.patasColor.withValues(alpha: 0.15),
                        backgroundImage:
                            hasPhoto ? NetworkImage(photoUrl) : null,
                        child: !hasPhoto
                            ? Icon(
                                isUserAccount
                                    ? Icons.person_rounded
                                    : Icons.pets_rounded,
                                size: 46,
                                color: AppColors.patasColor,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Nome, localização e Estatísticas (com Wrap para responsividade)
                Expanded(
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      // Nome + localização
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                fontFamily: 'Fredoka',
                              ),
                            ),
                            if (isUserAccount)
                              Text(context.tr('profile.tutor_role'),
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.patasColor,
                                      fontWeight: FontWeight.w500)),
                            if (activePet?.birthPlace != null &&
                                activePet!.birthPlace!.isNotEmpty)
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.cake_rounded,
                                    size: 13, color: AppColors.patasColor),
                                const SizedBox(width: 4),
                                Text('${context.tr('profile.born_in')}${activePet.birthPlace}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: thmode.darkMode
                                            ? Colors.white70
                                            : Colors.black54)),
                              ]),
                            if (activePet?.currentCity != null &&
                                activePet!.currentCity!.isNotEmpty)
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.location_on_rounded,
                                    size: 13, color: AppColors.patasColor),
                                const SizedBox(width: 4),
                                Text('${context.tr('profile.lives_in')}${activePet.currentCity}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: thmode.darkMode
                                            ? Colors.white70
                                            : Colors.black54)),
                              ]),
                          ],
                        ),
                      ),
                      // Estatísticas (com Wrap caso aperte ainda mais)
                      Wrap(
                        spacing: 24,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          FutureBuilder<List<Post>>(
                            future: _postsFuture,
                            builder: (context, snapshot) => _buildStatItem('${snapshot.data?.length ?? 0}', context.tr('profile.posts_stat'), thmode),
                          ),
                          FutureBuilder<int>(
                            future: _followingCountFuture,
                            builder: (context, snapshot) => _buildStatItem(
                              '${snapshot.data ?? 0}',
                              'Seguindo',
                              thmode,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => FollowListPage(
                                          userId: _targetUserId,
                                          petId: activePet?.id,
                                          initialIndex: 1))),
                            ),
                          ),
                          FutureBuilder<int>(
                            future: _followersCountFuture,
                            builder: (context, snapshot) => _buildStatItem(
                              '${snapshot.data ?? 0}',
                              'Seguidores',
                              thmode,
                              onTap: activePet != null
                                  ? () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => FollowListPage(
                                              userId: _targetUserId,
                                              petId: activePet.id,
                                              initialIndex: 0)))
                                  : null,
                            ),
                          ),
                          if (activePet != null &&
                              activePet.userId != supabase.auth.currentUser?.id)
                            _buildFollowButton(activePet),
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
    );
  }

  // ─── Card genérico desktop ────────────────────────────────────────────────
  Widget _buildDesktopCard(
    DarkMode thmode, {
    required Color cardBg,
    required Color borderColor,
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    final textColor = thmode.darkMode ? Colors.white : AppColors.darkBG;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: thmode.darkMode
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3))
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.patasColor),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(title,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textColor))),
                if (trailing != null) trailing,
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),
          Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ],
      ),
    );
  }

  // ─── Modais Desktop / Rotas Mobile ───────────────────────────────────────
  Future<bool?> _openCreateFamilyMember(BuildContext context) {
    if (context.isDesktop) {
      return showDialog<bool>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.25),
        barrierDismissible: true,
        builder: (ctx) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pop(ctx),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            Center(
              child: GestureDetector(
                onTap: () {},
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520, maxHeight: 660),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: const CreateFamilyMemberPage(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const CreateFamilyMemberPage()),
    );
  }

  Future<bool?> _openEditFamilyMember(BuildContext context, FamilyMember member) {
    if (context.isDesktop) {
      return showDialog<bool>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.25),
        barrierDismissible: true,
        builder: (ctx) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pop(ctx),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            Center(
              child: GestureDetector(
                onTap: () {},
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520, maxHeight: 660),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: EditFamilyMemberPage(member: member),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => EditFamilyMemberPage(member: member)),
    );
  }

  Future<bool?> _openEditPet(BuildContext context, Pet pet) {
    if (context.isDesktop) {
      return showDialog<bool>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.25),
        barrierDismissible: true,
        builder: (ctx) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pop(ctx),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            Center(
              child: GestureDetector(
                onTap: () {},
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 580, maxHeight: 760),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: EditPetPage(pet: pet),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => EditPetPage(pet: pet)),
    );
  }

  // ─── Lista de família (usada no desktop) ─────────────────────────────────
  Widget _buildFamilyList(DarkMode thmode, bool isOwner) {
    return FutureBuilder<List<FamilyMember>>(
      future: _familyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                      color: AppColors.patasColor)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(context.tr('profile.no_family_members'),
                style: TextStyle(
                    fontSize: 12,
                    color:
                        thmode.darkMode ? Colors.white54 : Colors.grey)),
          );
        }
        final members = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 18,
                backgroundImage: member.photoUrl != null &&
                        member.photoUrl!.isNotEmpty
                    ? NetworkImage(member.photoUrl!)
                    : null,
                child: member.photoUrl == null || member.photoUrl!.isEmpty
                    ? const Icon(Icons.person, size: 16)
                    : null,
              ),
              title: Text(member.name,
                  style: TextStyle(
                      fontSize: 13,
                      color:
                          thmode.darkMode ? Colors.white : AppColors.darkBG)),
              subtitle: Text(FamilyMember.localizedRelationship(context, member.relationship),
                  style: TextStyle(
                      fontSize: 11,
                      color: thmode.darkMode
                          ? Colors.white54
                          : Colors.grey)),
              trailing: isOwner
                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                          tooltip: context.tr('profile.edit_family_tooltip'),
                          icon: const Icon(Icons.edit,
                              size: 16, color: AppColors.patasColor),
                          onPressed: () async {
                            final result = await _openEditFamilyMember(context, member);
                            if (result == true) _loadFamilyMembers();
                          }),
                      IconButton(
                          tooltip: context.tr('profile.delete_family_tooltip'),
                          icon: Icon(Icons.delete,
                              size: 16,
                              color: Colors.red.withValues(alpha: 0.7)),
                          onPressed: () => _confirmDeleteFamily(member)),
                    ])
                  : null,
            );
          },
        );
      },
    );
  }

  // ─── Lista de pets (usada no desktop) ────────────────────────────────────
  Widget _buildPetsList(DarkMode thmode, bool isOwner) {
    return FutureBuilder<List<Pet>>(
      future: _petsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                      color: AppColors.patasColor)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Column(children: [
            Text(context.tr('profile.no_pets'),
                style: TextStyle(
                    fontSize: 12,
                    color:
                        thmode.darkMode ? Colors.white54 : Colors.grey)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                final result = await Navigator.push(context,
                    MaterialPageRoute(
                        builder: (context) => const AddKindPage()));
                if (result == true) _loadPets();
              },
              icon: const Icon(Icons.add, size: 16),
              label: Text(context.tr('profile.add_pet_btn')),
            ),
          ]);
        }
        final pets = snapshot.data!;
        return Consumer<ActivePetProvider>(
          builder: (context, activePetProvider, child) {
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pets.length,
              itemBuilder: (context, index) {
                final pet = pets[index];
                final isActive =
                    isOwner && activePetProvider.activePet?.id == pet.id;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  tileColor: isActive
                      ? AppColors.patasColor.withValues(alpha: 0.08)
                      : null,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundImage: pet.photoUrl != null &&
                            pet.photoUrl!.isNotEmpty
                        ? NetworkImage(pet.photoUrl!)
                        : null,
                    child: pet.photoUrl == null || pet.photoUrl!.isEmpty
                        ? const Icon(Icons.pets, size: 16)
                        : null,
                  ),
                  title: Text(pet.name,
                      style: TextStyle(
                          fontSize: 13,
                          color: thmode.darkMode
                              ? Colors.white
                              : AppColors.darkBG)),
                  subtitle: Text(pet.breed ?? pet.species,
                      style: TextStyle(
                          fontSize: 11,
                          color: thmode.darkMode
                              ? Colors.white54
                              : Colors.grey)),
                  onTap: () {
                    if (isOwner) {
                      final accProv =
                          Provider.of<ActiveAccountProvider>(context,
                              listen: false);
                      final petProv = Provider.of<ActivePetProvider>(
                          context,
                          listen: false);
                      accProv.setActiveAccount(
                          ActiveAccount(
                              id: pet.id,
                              name: pet.name,
                              photoUrl: pet.photoUrl,
                              type: AccountType.pet),
                          petProvider: petProv);
                    } else {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ProfilePage(
                                  userId: pet.userId, pet: pet)));
                    }
                  },
                  trailing: isOwner
                      ? Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                              tooltip: context.tr('profile.edit_pet_tooltip'),
                              icon: const Icon(Icons.edit,
                                  size: 16, color: AppColors.patasColor),
                              onPressed: () async {
                                final result = await _openEditPet(context, pet);
                                if (result == true && mounted) _loadPets();
                              }),
                          IconButton(
                              tooltip: context.tr('profile.delete_pet_tooltip'),
                              icon: Icon(Icons.delete,
                                  size: 16,
                                  color:
                                      Colors.red.withValues(alpha: 0.7)),
                              onPressed: pets.length <= 1
                                  ? () => showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(context.tr('profile.delete_pet_limit_title')),
                                          content: Text(context.tr('profile.delete_pet_limit_desc')),
                                          actions: [
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: Text(context.tr('common.understood')))
                                          ],
                                        ),
                                      )
                                  : () => _confirmDeletePet(pet, pets,
                                      activePetProvider)),
                        ])
                      : null,
                );
              },
            );
          },
        );
      },
    );
  }

  // ─── Seções mobile (família, fotos, pets) ─────────────────────────────────
  Widget _buildFamilySection(
      DarkMode thmode, bool isOwner, bool isUserAccount) {
    if (isUserAccount) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.only(left: 8, right: 16),
      color: thmode.darkMode ? Colors.black54 : AppColors.bodyLight,
      child: ExpansionTile(
        trailing:
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.tr('profile.family_section'), style: TextStyle(
                    fontSize: 18,
                    color: thmode.darkMode
                        ? Colors.white
                        : AppColors.darkBG)),
            if (isOwner)
              IconButton(
                tooltip: context.tr('profile.add_family_tooltip'),
                icon: Icon(Icons.add,
                    color: thmode.darkMode
                        ? Colors.white70
                        : Colors.black54),
                onPressed: () async {
                  final result = await _openCreateFamilyMember(context);
                  if (result == true) _loadFamilyMembers();
                },
              ),
          ],
        ),
        leading: const Icon(Icons.nature_people, color: Colors.deepOrange),
        children: [_buildFamilyList(thmode, isOwner)],
      ),
    );
  }

  Widget _buildPhotosSection(DarkMode thmode, Pet? activePet) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.only(left: 8, right: 16),
      color: thmode.darkMode ? Colors.black54 : AppColors.bodyLight,
      child: ExpansionTile(
        trailing:
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        title: Text(context.tr('profile.photos_section'), style: TextStyle(
                fontSize: 18,
                color: thmode.darkMode
                    ? Colors.white
                    : AppColors.darkBG)),
        leading: const Icon(Icons.photo, color: Colors.deepOrange),
        children: [
          SizedBox(
              width: double.infinity,
              child: PhotoContentWidget(pet: activePet))
        ],
      ),
    );
  }

  Widget _buildPetsSection(DarkMode thmode, bool isOwner) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.only(left: 8, right: 16),
      color: thmode.darkMode ? Colors.black54 : AppColors.bodyLight,
      child: ExpansionTile(
        trailing:
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.tr('profile.my_pets_section'), style: TextStyle(
                    fontSize: 21,
                    fontFamily: 'Fredoka',
                    color: AppColors.patasColor)),
            if (isOwner)
              IconButton(
                tooltip: context.tr('profile.add_pet_tooltip'),
                icon: const Icon(Icons.add_circle,
                    color: AppColors.patasColor, size: 28),
                onPressed: () async {
                  final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AddKindPage()));
                  if (result == true) _loadPets();
                },
              ),
          ],
        ),
        leading: SizedBox(
            height: 26,
            width: 26,
            child: SvgPicture.asset('assets/icons/patas.svg')),
        children: [_buildPetsList(thmode, isOwner)],
      ),
    );
  }

  // ─── Diálogos de confirmação ──────────────────────────────────────────────
  void _confirmDeleteFamily(FamilyMember member) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(context.tr('profile.confirm_delete_title')),
        content: Text(context.tr('profile.confirm_delete_family_desc', {'name': member.name, 'relationship': member.relationship})),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(context.tr('common.cancel'))),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(dialogCtx);
              final msg = ScaffoldMessenger.of(context);
              nav.pop();
              try {
                await _familyService.deleteFamilyMember(member.id);
                if (!mounted) return;
                msg.showSnackBar(SnackBar(
                    content: Text(
                        context.tr('profile.family_deleted_success', {'name': member.name}))));
                _loadFamilyMembers();
              } catch (e) {
                if (!mounted) return;
                msg.showSnackBar(SnackBar(
                    content: Text(context.tr('profile.delete_error', {'error': '$e'}))));
              }
            },
            child: Text(context.tr('common.delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePet(
      Pet pet, List<Pet> pets, ActivePetProvider activePetProvider) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(context.tr('profile.confirm_delete_title')),
        content: Text(context.tr('profile.confirm_delete_pet_desc', {'name': pet.name})),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(context.tr('common.cancel'))),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(dialogCtx);
              final msg = ScaffoldMessenger.of(context);
              nav.pop();
              try {
                final wasActive = activePetProvider.activePet?.id == pet.id;
                await _petService.deletePet(pet.id);
                if (wasActive) activePetProvider.setActivePet(null);
                if (!mounted) return;
                msg.showSnackBar(SnackBar(
                    content: Text(context.tr('profile.pet_deleted_success', {'name': pet.name}))));
                _loadPets();
              } catch (e) {
                if (!mounted) return;
                msg.showSnackBar(
                    SnackBar(content: Text(context.tr('profile.delete_error', {'error': '$e'}))));
              }
            },
            child: Text(context.tr('common.delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ─── Widgets auxiliares ───────────────────────────────────────────────────
  Widget _buildStatItem(String value, String label, DarkMode thmode,
      {VoidCallback? onTap}) {
    return Semantics(
      button: true,
      label: 'Ver $label',
      child: InkWell(
        onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: thmode.darkMode ? Colors.white : AppColors.darkBG,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.patasColor),
              ),
            ),
          ],
        ),
      ),
    ),
);
  }

  Widget _buildFollowButton(Pet activePet) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    if (!_isFollowing) {
      return ElevatedButton(
        onPressed: () async {
          try {
            final activePetActor =
                Provider.of<ActivePetProvider>(context, listen: false).activePet;
            await _followService.followPet(activePet.id,
                senderPetId: activePetActor?.id);
            setState(() {
              _isFollowing = true;
              _loadFollowData();
            });
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(context.tr('profile.follow_error')),
                backgroundColor: Colors.red,
              ));
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.patasColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          minimumSize: const Size(0, 34),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Text(context.tr('profile.follow'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      );
    }

    final menuBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.darkBG;
    final iconColor = isDark ? Colors.white70 : Colors.black87;

    return PopupMenuButton<String>(
      color: menuBgColor,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      onSelected: (value) {
        if (value == 'unfollow') {
          _handleUnfollow(activePet);
        } else if (value == 'block') {
          _confirmBlockTutor(activePet);
        } else if (value == 'report') {
          _reportTutor(activePet);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'unfollow',
          child: Row(
            children: [
              Icon(Icons.person_remove_rounded, color: iconColor, size: 20),
              const SizedBox(width: 10),
              Text(context.tr('profile.unfollow'), style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'block',
          child: Row(
            children: [
              const Icon(Icons.block_rounded, color: Colors.redAccent, size: 20),
              const SizedBox(width: 10),
              Text(context.tr('profile.block_option'), style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              const Icon(Icons.flag_rounded, color: Colors.orange, size: 20),
              const SizedBox(width: 10),
              Text(context.tr('profile.report_option'), style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.tr('profile.following'), style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down_rounded,
              color: textColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUnfollow(Pet activePet) async {
    try {
      await _followService.unfollowPet(activePet.id);
      setState(() {
        _isFollowing = false;
        _loadFollowData();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.tr('profile.unfollow_error')),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _confirmBlockTutor(Pet targetPet) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('profile.block_tutor_title')),
        content: Text(context.tr('profile.block_tutor_desc', {'name': targetPet.name})),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.tr('common.cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final currentUserId = supabase.auth.currentUser?.id;
              if (currentUserId == null) return;

              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(dialogContext).pop();

              final success = await _loveService.blockUser(
                blockerId: currentUserId,
                blockedId: targetPet.userId,
              );

              if (success) {
                try {
                  await _followService.unfollowPet(targetPet.id);
                } catch (_) {}

                if (mounted) {
                  // 1. Limpar perfil alvo gravado no Provider global de visualização de perfil
                  try {
                    Provider.of<ProfileViewProvider>(context, listen: false).clear();
                  } catch (_) {}

                  // 2. Notificar o usuário com SnackBar flutuante
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(context.tr('profile.tutor_blocked_success', {'name': targetPet.name})),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );

                  // 3. Atualizar os notifiers de navegação para a Home e o Feed principal
                  bottomNavIndexNotifier.value = 2; // Índice da Home na BottomNaviBar
                  homeTabIndexNotifier.value = 1; // Índice do Feed na HomePage

                  // 4. Retornar da rota pushed se houver histórico (Navigator.push)
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                }
              } else {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(context.tr('profile.tutor_block_error'))),
                  );
                }
              }
            },
            child: Text(context.tr('profile.block_option'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _reportTutor(Pet targetPet) {
    String selectedReason = 'Conteúdo inadequado ou ofensivo';
    final detailsController = TextEditingController();
    bool isSubmitting = false;

    final reasons = [
      'Conteúdo inadequado ou ofensivo',
      'Perfil falso ou golpe',
      'Spam ou mensagens indesejadas',
      'Maus-tratos ou maus cuidados com animais',
      'Outro motivo',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.flag_rounded, color: Colors.orange, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr('profile.report_tutor_title', {'name': targetPet.name}),
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.patasColor,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('profile.report_tutor_desc'),
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedReason,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: context.tr('profile.report_reason_label'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  items: reasons.map((r) {
                    return DropdownMenuItem<String>(
                      value: r,
                      child: Text(
                        r,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setStateDialog(() => selectedReason = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: detailsController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: context.tr('profile.report_details_hint'),
                    hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(),
              child: Text(context.tr('common.cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.patasColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final currentUserId = supabase.auth.currentUser?.id;
                      if (currentUserId == null) return;

                      setStateDialog(() => isSubmitting = true);
                      final nav = Navigator.of(dialogContext);

                      await _loveService.reportUser(
                        reporterId: currentUserId,
                        reportedUserId: targetPet.userId,
                        reportedPetId: targetPet.id,
                        reason: selectedReason,
                        details: detailsController.text.trim(),
                      );

                      nav.pop();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                context.tr('profile.report_success')),
                          ),
                        );
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(context.tr('profile.report_submit_btn'),
                      style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatasLoveExpansionSection(
      DarkMode thmode, Pet? activePet, bool isOwner) {
    if (activePet == null) return const SizedBox.shrink();
    final species = activePet.species.toLowerCase().trim();
    final isDogOrCat = species == 'cão' ||
        species == 'cao' ||
        species == 'cachorro' ||
        species == 'gato' ||
        species == 'felino' ||
        species == 'canino';

    if (!isDogOrCat) return const SizedBox.shrink();
    if (!isOwner && !activePet.isLoveActive) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.only(left: 8, right: 16),
      color: thmode.darkMode ? Colors.black54 : AppColors.bodyLight,
      child: ExpansionTile(
        initiallyExpanded: false,
        trailing: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        title: Text(context.tr('profile.patas_love_title'), style: const TextStyle(
            fontSize: 21,
            fontFamily: 'Fredoka',
            color: Colors.pinkAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading:
            const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 26),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 16),
            child: _buildPatasLoveSection(activePet, isOwner, thmode),
          ),
        ],
      ),
    );
  }

  Widget _buildPatasLoveSection(Pet pet, bool isOwner, DarkMode thmode) {
    final species = pet.species.toLowerCase().trim();
    final isDogOrCat = species == 'cão' ||
        species == 'cao' ||
        species == 'cachorro' ||
        species == 'gato' ||
        species == 'felino' ||
        species == 'canino';

    if (!isDogOrCat) return const SizedBox.shrink();

    final textColor = thmode.darkMode ? Colors.white : AppColors.darkBG;
    final cardColor = thmode.darkMode
        ? AppColors.darkBG
        : Colors.pink.withValues(alpha: 0.05);

    if (isOwner) {
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: pet.isLoveActive
                ? Colors.pinkAccent.withValues(alpha: 0.5)
                : (thmode.darkMode ? Colors.white12 : Colors.black12),
            width: pet.isLoveActive ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.pink.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_rounded,
                  color: Colors.pinkAccent, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('profile.patas_love_available'),
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: textColor,
                    ),
                  ),
                  Text(context.tr('profile.patas_love_subtitle'),
                    style: TextStyle(
                      fontSize: 10,
                      color: thmode.darkMode ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: pet.isLoveActive,
              activeThumbColor: Colors.pinkAccent,
              onChanged: (value) async {
                final updatedPet = Pet(
                  id: pet.id,
                  userId: pet.userId,
                  name: pet.name,
                  species: pet.species,
                  breed: pet.breed,
                  birthDate: pet.birthDate,
                  photoUrl: pet.photoUrl,
                  createdAt: pet.createdAt,
                  gender: pet.gender,
                  size: pet.size,
                  color: pet.color,
                  birthPlace: pet.birthPlace,
                  currentCity: pet.currentCity,
                  coverUrl: pet.coverUrl,
                  bloodType: pet.bloodType,
                  weight: pet.weight,
                  isLoveActive: value,
                );

                await _petService.updatePet(updatedPet);
                if (!mounted) return;

                context.read<ActivePetProvider>().setActivePet(updatedPet);
                setState(() {
                  _displayPet = updatedPet;
                });

                if (value) {
                  _showLoveActivationDialog(context, pet.name);
                }
              },
            ),
          ],
        ),
      );
    } else {
      if (!pet.isLoveActive) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.pink.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.pinkAccent.withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.pinkAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('profile.patas_love_public_available'),
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                    ),
                  ),
                  Text(context.tr('profile.patas_love_public_subtitle'),
                    style: TextStyle(
                      fontSize: 10,
                      color: thmode.darkMode ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  void _showLoveActivationDialog(BuildContext context, String petName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(context.tr('profile.love_activated_title'),
                style: const TextStyle(
                    fontFamily: 'Fredoka',
                    color: AppColors.patasColor,
                    fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          context.tr('profile.love_activated_desc', {'name': petName}),
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.patasColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.tr('common.understood'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
