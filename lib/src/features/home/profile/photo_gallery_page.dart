import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app.dart';
import '../../../constants/app_colors.dart';

import 'package:patas_web_app/src/localization/localizations_ext.dart';

class PhotoGalleryPage extends StatelessWidget {
  final String title;
  final List<String> imageUrls;

  const PhotoGalleryPage({
    super.key,
    required this.title,
    required this.imageUrls,
  });

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final bgColor = thmode.darkMode ? AppColors.darkBG : AppColors.bodyLight;
    final textColor = thmode.darkMode ? Colors.white : AppColors.darkBG;
    final appBarColor =
        thmode.darkMode ? AppColors.darkBG : AppColors.bodyLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
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
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: imageUrls.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.photo_library_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('profile.no_photos_found'),
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.6),
                      fontSize: 16,
                      fontFamily: 'Fredoka',
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              itemCount: imageUrls.length,
              itemBuilder: (context, index) {
                final url = imageUrls[index];
                return GestureDetector(
                  onTap: () => _showFullScreenImage(context, url, index),
                  child: Hero(
                    tag: 'gallery_image_$index',
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: thmode.darkMode
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.05),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.patasColor,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.error),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showFullScreenImage(BuildContext context, String url, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _GalleryDetailView(
          url: url,
          index: index,
        ),
      ),
    );
  }
}

class _GalleryDetailView extends StatelessWidget {
  final String url;
  final int index;

  const _GalleryDetailView({required this.url, required this.index});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Using SizedBox.expand to ensure the viewer takes up the entire screen
          SizedBox.expand(
            child: InteractiveViewer(
              clipBehavior: Clip
                  .none, // Crucial: allow image to move outside its "box" during zoom
              minScale: 1.0, // Instagram usually starts at 1.0
              maxScale: 5.0, // Allow a bit more zoom
              child: Hero(
                tag: 'gallery_image_$index',
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          // Navigation / Close UI
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
