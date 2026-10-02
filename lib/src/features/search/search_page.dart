import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:patas_web_app/src/features/home/timeline/services/post_service.dart';
import 'package:patas_web_app/src/features/home/timeline/services/story_service.dart';
import 'package:patas_web_app/src/features/home/timeline/models/post_model.dart';
import 'package:patas_web_app/src/features/home/timeline/models/story_model.dart';
import 'package:patas_web_app/src/features/pets/models/pet_model.dart';
import 'package:patas_web_app/src/features/home/profile/profile_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../../main.dart'; // Para supabase
import '../../../app.dart';
import '../../constants/app_colors.dart';
import '../home/timeline/full_screen_story.dart';
import 'package:patas_web_app/src/common_widgets/mobile_scroll_padding.dart';

import 'package:patas_web_app/src/features/ongs_corp/models/ong_profile_model.dart';
import 'package:patas_web_app/src/features/ongs_corp/models/corp_profile_model.dart';
import 'package:patas_web_app/src/features/ongs_corp/org_profile_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final PostService _postService = PostService();
  final StoryService _storyService = StoryService();

  List<dynamic> _searchResults = [];
  final List<dynamic> _discoveryItems = [];
  bool _isLoading = false;
  bool _isLoadingDiscovery = false;
  int _discoveryOffset = 0;
  bool _hasMoreDiscovery = true;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadDiscoveryData();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingDiscovery &&
        _hasMoreDiscovery &&
        _searchController.text.isEmpty) {
      _loadDiscoveryData();
    }
  }

  Future<void> _loadDiscoveryData() async {
    if (_isLoadingDiscovery) return;

    if (mounted) setState(() => _isLoadingDiscovery = true);

    try {
      final results = await Future.wait([
        _postService.getDiscoveryPosts(limit: 15, offset: _discoveryOffset),
        if (_discoveryOffset == 0)
          _storyService.getDiscoveryStories(limit: 5)
        else
          Future.value([]),
      ]).timeout(const Duration(seconds: 10));

      final newPosts = results[0] as List<Post>;
      final newStories = results[1] as List<Story>;

      if (mounted) {
        setState(() {
          _discoveryItems.addAll(newStories);
          _discoveryItems.addAll(newPosts);
          _discoveryOffset += newPosts.length;
          if (newPosts.length < 15) {
            _hasMoreDiscovery = false;
          }
          _isLoadingDiscovery = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar discovery: $e');
      if (mounted) setState(() => _isLoadingDiscovery = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    setState(() {});
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (value.trim().isNotEmpty) {
        _performSearch(value.trim());
      } else {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final ongsFuture = supabase
          .from('ong_profiles')
          .select()
          .ilike('name', '%$query%')
          .limit(20);

      final corpsFuture = supabase
          .from('company_profiles')
          .select()
          .ilike('name', '%$query%')
          .limit(20);

      final petsFuture = supabase
          .from('pets')
          .select()
          .ilike('name', '%$query%')
          .limit(20);

      final usersFuture = supabase
          .from('tutor_profiles')
          .select()
          .ilike('name', '%$query%')
          .limit(20);

      final responses = await Future.wait([
        ongsFuture,
        corpsFuture,
        petsFuture,
        usersFuture,
      ]);

      final ongs = (responses[0] as List)
          .map((e) => {...Map<String, dynamic>.from(e), '_type': 'ong'})
          .toList();
      final corps = (responses[1] as List)
          .map((e) => {...Map<String, dynamic>.from(e), '_type': 'corp'})
          .toList();
      final pets = (responses[2] as List)
          .map((e) => {...Map<String, dynamic>.from(e), '_type': 'pet'})
          .toList();
      final tutors = (responses[3] as List)
          .map((e) => {...Map<String, dynamic>.from(e), '_type': 'tutor'})
          .toList();

      final List<dynamic> results = [
        ...ongs,
        ...corps,
        ...pets,
        ...tutors,
      ];

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro na pesquisa: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro na pesquisa: $e')));
        setState(() {
          _isLoading = false;
          _searchResults = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);

    return Scaffold(
      backgroundColor: thmode.darkMode
          ? AppColors.bodygray
          : const Color(0xffF5F5F5),
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 56,
        backgroundColor: thmode.darkMode
            ? const Color(0xff1a1a1a)
            : const Color(0xffFAFAFA),
        automaticallyImplyLeading: false,
        shape: Border(
          bottom: BorderSide(
            color: thmode.darkMode ? Colors.white10 : Colors.grey.shade200,
            width: 1,
          ),
        ),
        titleSpacing: 16,
        title: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: TextFormField(
                controller: _searchController,
                onChanged: _onTextChanged,
                cursorColor: AppColors.patasColor,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10.0,
                    horizontal: 16.0,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.patasColor,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          color: thmode.darkMode
                              ? Colors.white60
                              : Colors.black54,
                          onPressed: () {
                            _searchController.clear();
                            _onTextChanged('');
                          },
                        )
                      : null,
                  errorStyle: const TextStyle(height: 0),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25.0)),
                    borderSide: BorderSide(
                      color: AppColors.patasColor,
                      width: 2.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(25.0)),
                    borderSide: BorderSide(
                      color: thmode.darkMode
                          ? Colors.white24
                          : AppColors.patasColor.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                  hintText: 'Pesquisar...',
                  hintStyle: TextStyle(
                    color: thmode.darkMode
                        ? Colors.white54
                        : Colors.black45,
                  ),
                ),
                style: TextStyle(
                  color: thmode.darkMode
                      ? AppColors.lightBG
                      : AppColors.darkBG,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty
          ? (_searchController.text.isNotEmpty
                ? Center(
                    child: Text(
                      'Nenhum resultado encontrado',
                      style: TextStyle(
                        color: thmode.darkMode
                            ? AppColors.lightBG
                            : AppColors.darkBG,
                      ),
                    ),
                  )
                : _buildDiscoveryGrid())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: ListView.builder(
                  padding: EdgeInsets.only(
                    top: 8,
                    bottom: MobileScrollPadding.bottomInset(context),
                  ),
                  itemCount: _searchResults.length,
                  itemBuilder: (BuildContext context, int index) {
                    final item = _searchResults[index];
                    final String type = item['_type'] ??
                        (item.containsKey('species') ? 'pet' : 'tutor');
                    final bool isPet = type == 'pet';
                    final bool isOng = type == 'ong';
                    final bool isCorp = type == 'corp';
                    final bool isTutor = type == 'tutor';

                    final String name = item['name'] ?? 'Sem nome';
                    final String? photoUrl = item['photo_url'];

                    String subtitle;
                    String badgeLabel;
                    Color badgeColor;
                    IconData fallbackIcon;

                    if (isPet) {
                      subtitle = item['breed'] ?? (item['species'] ?? 'Pet');
                      badgeLabel = 'PET';
                      badgeColor = AppColors.patasColor;
                      fallbackIcon = Icons.pets;
                    } else if (isOng) {
                      final activity = item['activity_areas'];
                      if (activity is List && activity.isNotEmpty) {
                        subtitle = activity.join(', ');
                      } else {
                        subtitle = item['about'] ?? 'ONG de Proteção Animal';
                      }
                      badgeLabel = 'ONG';
                      badgeColor = const Color(0xFF2E7D32);
                      fallbackIcon = Icons.volunteer_activism;
                    } else if (isCorp) {
                      subtitle = item['category'] ?? (item['about'] ?? 'Empresa Parceira');
                      badgeLabel = 'EMPRESA';
                      badgeColor = const Color(0xFF1976D2);
                      fallbackIcon = Icons.business;
                    } else {
                      subtitle = 'Tutor';
                      badgeLabel = 'TUTOR';
                      badgeColor = const Color(0xFF7B1FA2);
                      fallbackIcon = Icons.person;
                    }

                    return Semantics(
                      button: true,
                      label: 'Abrir perfil de $name ($badgeLabel)',
                      child: GestureDetector(
                        onTap: () {
                          if (isPet) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProfilePage(pet: Pet.fromJson(item)),
                              ),
                            );
                          } else if (isOng) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrgProfilePage(
                                  ong: OngProfile.fromJson(item),
                                  ongId: item['id'],
                                ),
                              ),
                            );
                          } else if (isCorp) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrgProfilePage(
                                  corp: CorpProfile.fromJson(item),
                                  corpId: item['id'],
                                ),
                              ),
                            );
                          } else if (isTutor) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfilePage(userId: item['id']),
                              ),
                            );
                          }
                        },
                        child: Container(
                          height: 88,
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: thmode.darkMode
                                ? Colors.grey[800]
                                : Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundColor:
                                      badgeColor.withValues(alpha: 0.15),
                                  backgroundImage: (photoUrl != null &&
                                          photoUrl.isNotEmpty)
                                      ? NetworkImage(photoUrl)
                                      : null,
                                  child: (photoUrl == null || photoUrl.isEmpty)
                                      ? Icon(
                                          fallbackIcon,
                                          size: 28,
                                          color: badgeColor,
                                        )
                                      : null,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: thmode.darkMode
                                                  ? AppColors.lightBG
                                                  : AppColors.darkBG,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: badgeColor
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: badgeColor
                                                  .withValues(alpha: 0.4),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            badgeLabel,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: badgeColor,
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: thmode.darkMode
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(right: 16.0),
                                child: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }

  Widget _buildDiscoveryGrid() {
    if (_discoveryItems.isEmpty && _isLoadingDiscovery) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.patasColor),
      );
    }

    final width = MediaQuery.of(context).size.width;
    int crossAxisCount = 3;
    if (width > 1400) {
      crossAxisCount = 6;
    } else if (width > 1100) {
      crossAxisCount = 5;
    } else if (width > 800) {
      crossAxisCount = 4;
    }

    return SingleChildScrollView(
      controller: _scrollController,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8,
                ),
                child: AlignedGridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  itemBuilder: (context, index) {
                    final item = _discoveryItems[index];

                    if (item is Story) {
                      return _buildStoryDiscoveryItem(item);
                    } else if (item is Post) {
                      return _buildPostDiscoveryItem(item);
                    }

                    return const SizedBox();
                  },
                  itemCount: _discoveryItems.length,
                ),
              ),
              if (_hasMoreDiscovery)
                Container(
                  height: 80,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(
                    color: AppColors.patasColor,
                  ),
                ),
              const MobileScrollPadding(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryDiscoveryItem(Story story) {
    return Semantics(
      button: true,
      label: 'Ver story explorado',
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FullScreenStory(stories: [story]),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: 9 / 16,
                child: CachedNetworkImage(
                  imageUrl: story.mediaUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Skeletonizer(
                    enabled: true,
                    child: Container(
                      color: Colors.white,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostDiscoveryItem(Post post) {
    if (post.imageUrl == null) return const SizedBox();

    return Semantics(
      button: true,
      label: 'Ver publicação explorada',
      child: GestureDetector(
        onTap: () {
          if (post.pet != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProfilePage(pet: post.pet)),
            );
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: post.imageUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) => Skeletonizer(
              enabled: true,
              child: Container(
                color: Colors.white,
                width: double.infinity,
                height: 150,
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[300],
              height: 150,
              child: const Icon(Icons.broken_image),
            ),
          ),
        ),
      ),
    );
  }
}
