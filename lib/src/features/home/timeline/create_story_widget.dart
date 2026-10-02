import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../../app.dart';
import '../../../constants/app_colors.dart';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:patas_web_app/src/features/pets/active_pet_provider.dart';
import 'package:patas_web_app/src/features/home/timeline/timeline_provider.dart';
import 'package:patas_web_app/src/providers/story_publish_provider.dart';
import 'package:patas_web_app/src/utils/image_helper.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:patas_web_app/src/features/video/services/video_picker_service.dart';
import 'package:patas_web_app/src/features/video/services/video_compression_service.dart';
import 'package:patas_web_app/src/features/video/screens/camera_recording_screen.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:patas_web_app/src/common_widgets/patas_button.dart';

class CreateStoryWidget extends StatefulWidget {
  const CreateStoryWidget({super.key});

  @override
  State<CreateStoryWidget> createState() => _CreateStoryWidgetState();
}

class _CreateStoryWidgetState extends State<CreateStoryWidget> {
  String selectedImagePath = '';
  String selectedVideoPath = '';
  File? _rawVideoFile;
  File? selectedVideoThumbnail;
  bool isVideo = false;

  final ImageHelper _imageHelper = ImageHelper();
  final VideoPickerService _videoPickerService = VideoPickerService();

  int? _videoDurationSeconds;
  bool _isDurationCapped = false;

  // XFile original do vídeo (usado no Web para upload via readAsBytes)
  XFile? _pickedVideoXFile;
  // Controller de prévia do vídeo (Web e Mobile)
  VideoPlayerController? _videoPreviewController;
  bool _videoPreviewInitialized = false;

  @override
  void dispose() {
    _videoPreviewController?.dispose();
    super.dispose();
  }

  Future<void> _initVideoPreview(String pathOrBlob) async {
    _videoPreviewController?.dispose();
    if (kIsWeb) {
      _videoPreviewController = VideoPlayerController.networkUrl(Uri.parse(pathOrBlob));
    } else {
      _videoPreviewController = VideoPlayerController.file(File(pathOrBlob));
    }
    try {
      await _videoPreviewController!.initialize();
      _videoPreviewController!.setLooping(true);
      _videoPreviewController!.play();
      if (mounted) {
        setState(() => _videoPreviewInitialized = true);
      }
    } catch (e) {
      debugPrint('⚠️ Erro ao inicializar prévia de vídeo: $e');
    }
  }

  /// Verifica se o vídeo ultrapassa o limite de 30s do Story
  Future<bool> _checkVideoDurationLimit(int originalDuration) async {
    const int maxStoryDuration = 30;
    if (originalDuration <= maxStoryDuration) {
      _isDurationCapped = false;
      return true;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.timer_outlined, color: AppColors.patasColor, size: 26),
            SizedBox(width: 8),
            Text('Vídeo Longo', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'O vídeo selecionado tem ${originalDuration}s.\n\n'
          'Stories podem ter no máximo $maxStoryDuration segundos.\n'
          'Deseja publicar apenas os primeiros $maxStoryDuration segundos do seu vídeo?',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.patasColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continuar com 30s', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _isDurationCapped = true;
      return true;
    } else {
      _isDurationCapped = false;
      return false;
    }
  }

  Future<void> _publishStory() async {
    if (!isVideo && selectedImagePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma imagem ou vídeo primeiro!')),
      );
      return;
    }
    if (isVideo && selectedVideoPath.isEmpty && _pickedVideoXFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um vídeo primeiro!')),
      );
      return;
    }

    final activePetProvider =
        Provider.of<ActivePetProvider>(context, listen: false);
    final petId = activePetProvider.activePet?.id;
    final timelineProvider =
        Provider.of<TimelineProvider>(context, listen: false);
    final storyPublishProvider =
        Provider.of<StoryPublishProvider>(context, listen: false);

    final bool currentIsVideo = isVideo;
    final File? currentRawVideo = _rawVideoFile ??
        (selectedVideoPath.isNotEmpty ? File(selectedVideoPath) : null);
    final XFile? currentXFile = _pickedVideoXFile;
    final File? currentImage =
        selectedImagePath.isNotEmpty ? File(selectedImagePath) : null;
    final File? currentThumbnail = selectedVideoThumbnail;
    final int effectiveDuration =
        _isDurationCapped ? 30 : (_videoDurationSeconds ?? 30);

    // Fecha a tela IMEDIATAMENTE (zero bloqueio para o usuário!)
    Navigator.pop(context, true);

    // Inicia otimização e publicação em segundo plano
    storyPublishProvider.publishStory(
      isVideo: currentIsVideo,
      videoFile: currentRawVideo,
      pickedVideoXFile: currentXFile,
      imageFile: currentImage,
      thumbnailFile: currentThumbnail,
      durationSeconds: effectiveDuration,
      petId: petId,
      timelineProvider: timelineProvider,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dark Studio imersivo (Estilo Instagram/TikTok Stories)
    final scaffoldBg = context.isWide 
        ? Colors.transparent 
        : const Color(0xFF0F0F12);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: scaffoldBg,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.transparent,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: context.isWide ? 450 : double.infinity,
              maxHeight: context.isWide ? 850 : double.infinity,
            ),
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: Container(
                margin: context.isWide ? EdgeInsets.symmetric(vertical: 20.h) : EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0F12),
                  borderRadius: context.isWide
                      ? BorderRadius.circular(32.r)
                      : BorderRadius.zero,
                  boxShadow: context.isWide
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 50,
                            offset: const Offset(0, 15),
                          )
                        ]
                      : null,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1. Preview Wallpaper/Content
                    Positioned.fill(
                      child: (!isVideo && selectedImagePath.isEmpty)
                          ? Container(
                              color: const Color(0xFF0F0F12),
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: context.isWide ? 28 : 28.w),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: context.isWide ? 84 : 88.r,
                                        height: context.isWide ? 84 : 88.r,
                                        decoration: BoxDecoration(
                                          color: AppColors.patasColor
                                              .withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.auto_awesome_rounded,
                                          size: context.isWide ? 40 : 42.r,
                                          color: AppColors.patasColor,
                                        ),
                                      ),
                                      SizedBox(height: context.isWide ? 18 : 20.h),
                                      Text(
                                        'Criar Story',
                                        style: TextStyle(
                                          fontSize: context.isWide ? 22 : 22.sp,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Fredoka',
                                          letterSpacing: -0.3,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: context.isWide ? 8 : 8.h),
                                      Text(
                                        'Compartilhe fotos e vídeos rápidos dos seus pets com seus amigos',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: context.isWide ? 13 : 13.sp,
                                          color: Colors.white.withValues(alpha: 0.65),
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : isVideo && _videoPreviewInitialized && _videoPreviewController != null
                              ? Builder(
                                  builder: (context) {
                                    final bool isRotated = _videoPreviewController!.value.rotationCorrection == 90 ||
                                        _videoPreviewController!.value.rotationCorrection == 270;
                                    final double videoWidth = isRotated
                                        ? _videoPreviewController!.value.size.height
                                        : _videoPreviewController!.value.size.width;
                                    final double videoHeight = isRotated
                                        ? _videoPreviewController!.value.size.width
                                        : _videoPreviewController!.value.size.height;
                                    final bool isLandscape = (_videoPreviewController!.value.aspectRatio > 1.0);

                                    return FittedBox(
                                      fit: isLandscape ? BoxFit.contain : BoxFit.cover,
                                      alignment: Alignment.center,
                                      child: SizedBox(
                                        width: videoWidth > 0 ? videoWidth : 16,
                                        height: videoHeight > 0 ? videoHeight : 9,
                                        child: VideoPlayer(_videoPreviewController!),
                                      ),
                                    );
                                  },
                                )
                              : isVideo
                                  ? Container(
                                      color: Colors.black87,
                                      child: const Center(
                                        child: CircularProgressIndicator(color: AppColors.patasColor),
                                      ),
                                    )
                                  : kIsWeb
                                      ? Image.network(
                                          selectedImagePath,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            color: Colors.black12,
                                            child: const Center(child: Icon(Icons.broken_image)),
                                          ),
                                        )
                                      : Image.file(
                                          File(selectedImagePath),
                                          fit: BoxFit.cover,
                                        ),
                    ),

                    // 2. Custom Internal AppBar
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.only(
                          top: context.isWide ? 15 : MediaQuery.of(context).padding.top + 10.h,
                          bottom: context.isWide ? 10 : 10.h,
                          left: context.isWide ? 8 : 8.w,
                          right: context.isWide ? 12 : 12.w,
                        ),
                        decoration: BoxDecoration(
                          gradient: (selectedImagePath.isNotEmpty || isVideo)
                              ? LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.7),
                                    Colors.transparent,
                                  ],
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                              onPressed: () {
                                if (selectedImagePath.isNotEmpty || isVideo) {
                                  _clearMedia();
                                } else {
                                  Navigator.pop(context);
                                }
                              },
                            ),
                            const Spacer(),
                            if (selectedImagePath.isNotEmpty || (isVideo && selectedVideoPath.isNotEmpty))
                              PatasButton(
                                text: 'Publicar',
                                onPressed: _publishStory,
                                isLoading: false,
                                variant: PatasButtonVariant.primary,
                                size: PatasButtonSize.small,
                              ),
                          ],
                        ),
                      ),
                    ),

                    // 3. Action Dock (Quando vazio)
                    if (selectedImagePath.isEmpty && !isVideo)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom + (context.isWide ? 24 : 32.h),
                            left: 16.w,
                            right: 16.w,
                            top: 20.h,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildDockButton(
                                icon: Icons.photo_library_outlined,
                                label: 'Galeria',
                                onTap: () async {
                                  final path = await selectImageFromGallery();
                                  if (path.isNotEmpty) {
                                    setState(() => selectedImagePath = path);
                                  }
                                },
                              ),
                              SizedBox(width: 8.w),
                              _buildDockButton(
                                icon: Icons.camera_alt_outlined,
                                label: 'Câmera',
                                onTap: () async {
                                  final path = await selectImageFromCamera();
                                  if (path.isNotEmpty) {
                                    setState(() => selectedImagePath = path);
                                  }
                                },
                              ),
                              SizedBox(width: 8.w),
                              _buildDockButton(
                                icon: Icons.videocam_outlined,
                                label: 'Vídeo',
                                onTap: _showVideoSourceDialog,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // 4. Controles quando a mídia está carregada
                    if (selectedImagePath.isNotEmpty || isVideo) ...[
                      // Badge de duração (Bottom-Left)
                      if (isVideo)
                        Positioned(
                          bottom: context.isWide ? 24 : 32.h,
                          left: 16.w,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.videocam_rounded, color: Colors.white, size: 16),
                                const SizedBox(width: 5),
                                Text(
                                  _isDurationCapped
                                      ? '30s (máx. 30s)'
                                      : '${_videoDurationSeconds ?? 0}s',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Botão Trocar Mídia (Bottom-Right)
                      Positioned(
                        bottom: context.isWide ? 24 : 32.h,
                        right: 16.w,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isVideo ? _showVideoSourceDialog : _showImageSourceDialog,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.isWide ? 12 : 12.w,
                                vertical: context.isWide ? 8 : 8.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.cached_rounded, color: Colors.white, size: 16),
                                  SizedBox(width: 5.w),
                                  Text(
                                    'Trocar',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: context.isWide ? 13 : 13.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _clearMedia() {
    _videoPreviewController?.dispose();
    setState(() {
      selectedImagePath = '';
      selectedVideoPath = '';
      selectedVideoThumbnail = null;
      isVideo = false;
      _pickedVideoXFile = null;
      _videoPreviewController = null;
      _videoPreviewInitialized = false;
      _videoDurationSeconds = null;
      _isDurationCapped = false;
    });
  }

  Widget _buildDockButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.isWide ? 14 : 14.w,
            vertical: context.isWide ? 10 : 10.h,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E24),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: context.isWide ? 18 : 20.r,
                color: AppColors.patasColor,
              ),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: context.isWide ? 13 : 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }




  selectImageFromGallery() async {
    final file = await _imageHelper.pickCropAndCompress(
      context: context,
      source: ImageSource.gallery,
      aspectRatio: const CropAspectRatio(ratioX: 9, ratioY: 16),
    );
    return file?.path ?? '';
  }

  selectImageFromCamera() async {
    final file = await _imageHelper.pickCropAndCompress(
      context: context,
      source: ImageSource.camera,
      aspectRatio: const CropAspectRatio(ratioX: 9, ratioY: 16),
    );
    return file?.path ?? '';
  }

  // BottomSheet moderno para escolher foto (Galeria ou Câmera)
  Future _showImageSourceDialog() async {
    final thmode = Provider.of<DarkMode>(context, listen: false);
    final isDark = thmode.darkMode;

    return showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkBG : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Adicionar Foto ao Story',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Fredoka',
                  color: isDark ? Colors.white : AppColors.darkBG,
                ),
              ),
              const SizedBox(height: 20),
              _buildSheetOption(
                icon: Icons.photo_library_outlined,
                title: 'Galeria',
                subtitle: 'Escolha uma foto da galeria do seu aparelho',
                onTap: () async {
                  Navigator.pop(ctx);
                  final path = await selectImageFromGallery();
                  if (path.isNotEmpty) {
                    setState(() => selectedImagePath = path);
                  }
                },
                thmode: thmode,
              ),
              const SizedBox(height: 12),
              _buildSheetOption(
                icon: Icons.camera_alt_outlined,
                title: 'Câmera',
                subtitle: 'Tire uma foto nova agora com a câmera',
                onTap: () async {
                  Navigator.pop(ctx);
                  final path = await selectImageFromCamera();
                  if (path.isNotEmpty) {
                    setState(() => selectedImagePath = path);
                  }
                },
                thmode: thmode,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // BottomSheet moderno para escolher vídeo (Galeria ou Câmera)
  Future _showVideoSourceDialog() async {
    final thmode = Provider.of<DarkMode>(context, listen: false);
    final isDark = thmode.darkMode;

    return showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkBG : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Adicionar Vídeo ao Story',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Fredoka',
                  color: isDark ? Colors.white : AppColors.darkBG,
                ),
              ),
              const SizedBox(height: 20),
              _buildSheetOption(
                icon: Icons.video_library_outlined,
                title: 'Escolher da Galeria',
                subtitle: 'Selecione um vídeo já gravado (máx. 30s)',
                onTap: () {
                  Navigator.pop(ctx);
                  _handleVideoSelection();
                },
                thmode: thmode,
              ),
              const SizedBox(height: 12),
              _buildSheetOption(
                icon: Icons.videocam_outlined,
                title: 'Gravar com a Câmera',
                subtitle: 'Grave um novo vídeo agora com edição rápida',
                onTap: () {
                  Navigator.pop(ctx);
                  _handleCameraRecording();
                },
                thmode: thmode,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required DarkMode thmode,
  }) {
    final isDark = thmode.darkMode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.patasColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppColors.patasColor,
                  size: 22,
                ),
              ),
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
                        color: isDark ? Colors.white : AppColors.darkBG,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: (isDark ? Colors.white70 : AppColors.darkBG).withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Processa a seleção de vídeo da galeria: carrega a prévia IMEDIATAMENTE sem bloquear o usuário
  Future<void> _handleVideoSelection() async {
    try {
      // 1. Seleciona arquivo bruto da galeria
      final rawVideoFile = await _videoPickerService.pickVideoOnly(
        type: VideoType.story,
        source: ImageSource.gallery,
      );

      if (rawVideoFile == null) return; // Usuário cancelou

      // 2. Valida a duração real do vídeo
      final validation = await _videoPickerService.validateVideoFile(
        videoFile: rawVideoFile,
        type: VideoType.story,
      );

      if (!validation.isValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(validation.errorMessage ?? 'Vídeo inválido'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final int originalDuration = validation.durationSeconds ?? 0;

      // 3. Validação de limite de tempo (Stories: 30s)
      final canProceed = await _checkVideoDurationLimit(originalDuration);
      if (!canProceed) {
        _clearMedia();
        return;
      }

      final int targetDuration = _isDurationCapped ? 30 : (originalDuration > 0 ? originalDuration : 30);

      // 4. Carrega a prévia IMEDIATAMENTE na tela sem bloquear com diálogos!
      if (mounted) {
        setState(() {
          isVideo = true;
          _rawVideoFile = File(rawVideoFile.path);
          _pickedVideoXFile = XFile(rawVideoFile.path);
          selectedVideoPath = rawVideoFile.path;
          selectedVideoThumbnail = null;
          selectedImagePath = (kIsWeb ? 'video_placeholder' : '');
          _videoDurationSeconds = targetDuration;
          _videoPreviewInitialized = false;
        });

        // Inicializar prévia instantânea do vídeo
        _initVideoPreview(rawVideoFile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar vídeo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Lida com gravação de vídeo pela câmera: carrega a prévia IMEDIATAMENTE sem bloquear o usuário
  Future<void> _handleCameraRecording() async {
    try {
      // 1. Navegar para tela de gravação
      final String? videoPath = await showGeneralDialog<String>(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'Fechar',
        barrierColor: Colors.black.withValues(alpha: 0.5),
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, anim1, anim2) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: const CameraRecordingScreen(
              maxDurationSeconds: 30, // Stories
            ),
          );
        },
        transitionBuilder: (context, anim1, anim2, child) {
          return FadeTransition(
            opacity: anim1,
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: anim1,
                curve: Curves.easeOutBack,
              ).drive(Tween<double>(begin: 0.8, end: 1.0)),
              child: child,
            ),
          );
        },
      );

      if (videoPath == null) return;
      if (!mounted) return;

      final rawVideoFile = File(videoPath);

      // 2. Valida a duração real do vídeo
      final validation = await _videoPickerService.validateVideoFile(
        videoFile: rawVideoFile,
        type: VideoType.story,
      );

      if (!validation.isValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(validation.errorMessage ?? 'Vídeo inválido'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final int originalDuration = validation.durationSeconds ?? 0;

      // 3. Validação de limite de tempo (Stories: 30s)
      final canProceed = await _checkVideoDurationLimit(originalDuration);
      if (!canProceed) {
        _clearMedia();
        return;
      }

      final int targetDuration = _isDurationCapped ? 30 : (originalDuration > 0 ? originalDuration : 30);

      // 4. Carrega a prévia IMEDIATAMENTE na tela sem bloquear
      if (mounted) {
        setState(() {
          isVideo = true;
          _rawVideoFile = rawVideoFile;
          _pickedVideoXFile = XFile(videoPath);
          selectedVideoPath = videoPath;
          selectedVideoThumbnail = null;
          selectedImagePath = (kIsWeb ? 'video_placeholder' : '');
          _videoDurationSeconds = targetDuration;
          _videoPreviewInitialized = false;
        });

        // Inicializar prévia instantânea do vídeo gravado
        _initVideoPreview(videoPath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar gravação: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
