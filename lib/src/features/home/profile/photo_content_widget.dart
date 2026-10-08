import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/features/home/profile/photo_gallery_page.dart';
import 'package:patas_web_app/src/features/home/timeline/services/story_service.dart';
import 'package:patas_web_app/src/features/home/timeline/services/post_service.dart';
import 'package:patas_web_app/src/features/pets/models/pet_model.dart';
import 'package:patas_web_app/src/localization/locator.dart';
import '../../../../app.dart';
import '../../../constants/app_colors.dart';

import 'package:patas_web_app/src/localization/localizations_ext.dart';

class PhotoFolder {
  final String title;
  final Future<List<String>> imagesFuture;

  PhotoFolder({required this.title, required this.imagesFuture});
}

class PhotoContentWidget extends StatefulWidget {
  final Pet? pet;
  const PhotoContentWidget({super.key, this.pet});

  @override
  State<PhotoContentWidget> createState() => _PhotoContentWidgetState();
}

class _PhotoContentWidgetState extends State<PhotoContentWidget> {
  Future<List<String>>? _profileImagesFuture;
  Future<List<String>>? _postImagesFuture;
  Future<List<String>>? _storyImagesFuture;

  @override
  void initState() {
    super.initState();
    _loadFutures();
  }

  @override
  void didUpdateWidget(covariant PhotoContentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pet?.id != widget.pet?.id) {
      _loadFutures();
    }
  }

  void _loadFutures() {
    final petId = widget.pet?.id;
    if (petId != null) {
      _profileImagesFuture = _getProfileImages();
      _postImagesFuture = _getPostImages(petId);
      _storyImagesFuture = _getStoryImages(petId);
    }
  }

  List<PhotoFolder> _getFolders(BuildContext context) {
    final petId = widget.pet?.id;
    if (petId == null) return [];

    return [
      PhotoFolder(
        title: context.tr('profile.folder_profile'),
        imagesFuture: _profileImagesFuture ?? Future.value([]),
      ),
      PhotoFolder(
        title: context.tr('profile.folder_posts'),
        imagesFuture: _postImagesFuture ?? Future.value([]),
      ),
      PhotoFolder(
        title: context.tr('profile.folder_stories'),
        imagesFuture: _storyImagesFuture ?? Future.value([]),
      ),
    ];
  }

  Future<List<String>> _getProfileImages() async {
    if (widget.pet?.photoUrl != null && widget.pet!.photoUrl!.isNotEmpty) {
      return [widget.pet!.photoUrl!];
    }
    return [];
  }

  Future<List<String>> _getPostImages(String petId) async {
    final posts = await locator.get<PostService>().getPosts(petId: petId);
    return posts
        .where((post) => post.imageUrl != null && post.imageUrl!.isNotEmpty)
        .map((post) => post.imageUrl!)
        .toList();
  }

  Future<List<String>> _getStoryImages(String petId) async {
    final stories = await locator.get<StoryService>().getStoriesByPetId(petId);
    return stories.map((story) => story.mediaUrl).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pet == null) {
      return Center(child: Text(context.tr('profile.no_pet_selected')));
    }

    final folders = _getFolders(context);
    final thmode = Provider.of<DarkMode>(context);
    return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            childAspectRatio: 0.88,
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 14),
        itemCount: folders.length,
        itemBuilder: (BuildContext ctx, index) {
          final folder = folders[index];
          return FutureBuilder<List<String>>(
            future: folder.imagesFuture,
            builder: (context, snapshot) {
              final images = snapshot.data ?? [];
              final String? previewImage =
                  images.isNotEmpty ? images.first : null;

              return LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Flexible(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => PhotoGalleryPage(
                                      title: folder.title,
                                      imageUrls: images,
                                    )));
                          },
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SizedBox(
                              height: 85,
                              width: 100,
                              child: Stack(
                                alignment: Alignment.center,
                                children: <Widget>[
                                  const Icon(
                                    Icons.folder,
                                    color: Colors.white,
                                    size: 100,
                                  ),
                                  if (previewImage != null)
                                    Positioned(
                                      top: 28,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: CachedNetworkImage(
                                          imageUrl: previewImage,
                                          height: 45,
                                          width: 75,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                            color: Colors.grey[200],
                                          ),
                                          errorWidget: (context, url, error) =>
                                              const Icon(Icons.error),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '${folder.title} (${images.length})',
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color:
                                thmode.darkMode ? Colors.white : AppColors.darkBG,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        });
  }
}
