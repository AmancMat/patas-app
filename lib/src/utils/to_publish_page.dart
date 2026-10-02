import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import 'package:patas_web_app/src/features/home/timeline/models/post_model.dart';
import 'package:patas_web_app/src/features/home/timeline/services/post_service.dart';
import 'package:patas_web_app/src/features/home/timeline/timeline_provider.dart';
import 'package:patas_web_app/src/features/pets/active_pet_provider.dart';
import 'package:patas_web_app/src/features/home/timeline/widgets/profile_selector_dialog.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/main.dart';
import 'package:patas_web_app/src/constants/routes.dart';
import 'package:patas_web_app/src/utils/image_helper.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:patas_web_app/src/features/video/services/video_picker_service.dart';
import 'package:patas_web_app/src/features/video/services/video_compression_service.dart';
import 'package:patas_web_app/src/features/video/screens/camera_recording_screen.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:patas_web_app/src/common_widgets/patas_button.dart';

class ToPublishPage extends StatefulWidget {
  const ToPublishPage({super.key});

  @override
  State<ToPublishPage> createState() => _ToPublishPageState();
}

class _ToPublishPageState extends State<ToPublishPage> {
  final TextEditingController _contentController = TextEditingController();
  final PostService _postService = PostService();
  final ImageHelper _imageHelper = ImageHelper();
  final VideoPickerService _videoPickerService = VideoPickerService();

  String selectedImagePath = '';
  String selectedVideoPath = '';
  File? selectedVideoThumbnail;
  bool isVideo = false;

  bool _isPublishing = false;
  double _videoCompressionProgress = 0.0;
  String _publishingStatus = '';
  int? _videoDurationSeconds;

  // Gerenciamento de Perfil para Publicação
  PublishProfile? _selectedProfile;

  // XFile original do vídeo (usado no Web para upload via readAsBytes)
  XFile? _pickedVideoXFile;
  // Controller de prévia do vídeo (Web e Mobile)
  VideoPlayerController? _previewVideoController;
  bool _previewVideoInitialized = false;
  bool _isDurationCapped = false;

  @override
  void dispose() {
    _contentController.dispose();
    _previewVideoController?.dispose();
    super.dispose();
  }

  /// Inicializa a prévia do vídeo de forma unificada (Web e Mobile)
  Future<void> _initVideoPreview(String pathOrBlob) async {
    _previewVideoController?.dispose();
    if (kIsWeb) {
      _previewVideoController = VideoPlayerController.networkUrl(Uri.parse(pathOrBlob));
    } else {
      _previewVideoController = VideoPlayerController.file(File(pathOrBlob));
    }
    try {
      await _previewVideoController!.initialize();
      _previewVideoController!.setLooping(true);
      _previewVideoController!.setVolume(0); // Prévia inicia muda
      _previewVideoController!.play();
      if (mounted) {
        final measuredDuration = _previewVideoController!.value.duration.inSeconds;
        setState(() {
          _previewVideoInitialized = true;
          if (_videoDurationSeconds == null || _videoDurationSeconds == 0) {
            _videoDurationSeconds = measuredDuration;
          }
        });
      }
    } catch (e) {
      debugPrint('⚠️ Erro ao inicializar prévia de vídeo: $e');
    }
  }

  /// Verifica se o vídeo ultrapassa o limite do app e permite o usuário decidir
  Future<bool> _checkVideoDurationLimit(int durationSeconds, {required int maxLimitSeconds}) async {
    if (durationSeconds <= maxLimitSeconds) {
      _isDurationCapped = false;
      return true; // Dentro do limite
    }

    final bool? continueWithLimit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.timer_outlined, color: AppColors.patasColor, size: 26),
            SizedBox(width: 8),
            Text(
              'Vídeo Longo',
              style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Este vídeo tem $durationSeconds segundos. O limite máximo para publicações no feed é de $maxLimitSeconds segundos.',
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
            Text(
              'Se continuar, o vídeo será publicado considerando os primeiros $maxLimitSeconds segundos.',
              style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.patasColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Continuar (${maxLimitSeconds}s)'),
          ),
        ],
      ),
    );

    if (continueWithLimit == true) {
      _isDurationCapped = true;
      _videoDurationSeconds = maxLimitSeconds;
      return true;
    } else {
      return false; // Usuário cancelou
    }
  }

  Future<void> _handlePublish() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    if (_contentController.text.isEmpty && selectedImagePath.isEmpty && selectedVideoPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Adicione uma imagem, vídeo ou texto para publicar.')),
      );
      return;
    }

    final activePet =
        Provider.of<ActivePetProvider>(context, listen: false).activePet;

    setState(() {
      _isPublishing = true;
      _publishingStatus = 'Preparando...';
    });

    // Pequeno delay para garantir que o overlay apareça
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      Post? createdPost;

      if (isVideo && selectedVideoPath.isNotEmpty) {
        // Publicar post com vídeo
        setState(() => _publishingStatus = 'Enviando vídeo...');

        createdPost = await _postService.createPostWithVideo(
          videoFile: kIsWeb ? File(_pickedVideoXFile!.path) : File(selectedVideoPath),
          thumbnailFile: selectedVideoThumbnail,
          durationSeconds: _videoDurationSeconds ?? 0,
          content: _contentController.text,
          petId: _selectedProfile?.type == 'pet' ? _selectedProfile?.id : null,
          ongId: _selectedProfile?.type == 'ong' ? _selectedProfile?.id : null,
          companyId:
              _selectedProfile?.type == 'company' ? _selectedProfile?.id : null,
          profileType: _selectedProfile?.type ?? 'pet',
          onUploadProgress: (progress) {
            if (mounted) {
              setState(() => _publishingStatus =
                  'Enviando vídeo... ${(progress * 100).toInt()}%');
            }
          },
        );
      } else {
        // Publicar post com imagem
        String? imageUrl;
        if (selectedImagePath.isNotEmpty) {
          setState(() => _publishingStatus = 'Enviando imagem...');
          imageUrl = await _postService.uploadPostImage(
            File(selectedImagePath),
          );
        }

        setState(() => _publishingStatus = 'Finalizando publicação...');

        final post = Post(
          id: '', // Supabase gera
          userId: user.id,
          petId: _selectedProfile?.type == 'pet' ? _selectedProfile?.id : null,
          ongId: _selectedProfile?.type == 'ong' ? _selectedProfile?.id : null,
          companyId:
              _selectedProfile?.type == 'company' ? _selectedProfile?.id : null,
          profileType: _selectedProfile?.type ?? 'pet',
          content: _contentController.text,
          imageUrl: imageUrl,
          createdAt: DateTime.now(),
          // Campos extras que o provider pode precisar para exibição imediata
          userName: user.userMetadata?['name'],
          pet: _selectedProfile?.type == 'pet' ? activePet : null,
        );

        createdPost = await _postService.createPost(post);
      }

      if (!context.mounted) return;
      if (mounted) {
        // Adiciona localmente para feedback instantâneo
        if (createdPost != null) {
          Provider.of<TimelineProvider>(context, listen: false)
              .addPostLocally(createdPost);
        } else {
          // Se falhou o retorno mas não deu erro, recarrega
          Provider.of<TimelineProvider>(context, listen: false)
              .loadTimeline(silent: true);
        }

        Navigator.of(context).pushNamedAndRemoveUntil(
          NamedRoute.home,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao publicar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  void _clearMedia() {
    _previewVideoController?.pause();
    _previewVideoController?.dispose();
    _previewVideoController = null;
    setState(() {
      selectedImagePath = '';
      selectedVideoPath = '';
      selectedVideoThumbnail = null;
      isVideo = false;
      _pickedVideoXFile = null;
      _previewVideoInitialized = false;
      _videoDurationSeconds = null;
      _isDurationCapped = false;
    });
  }

  Widget _buildMediaPreview() {
    if (selectedImagePath.isEmpty && !isVideo) {
      return const SizedBox.shrink();
    }

    final isWide = context.isWide;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      constraints: BoxConstraints(
        maxHeight: isWide ? 420 : 360,
        minWidth: double.infinity,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Mídia (Vídeo ou Foto)
          isVideo
              ? _previewVideoInitialized && _previewVideoController != null
                  ? AspectRatio(
                      aspectRatio: (_previewVideoController!.value.aspectRatio > 0)
                          ? _previewVideoController!.value.aspectRatio.clamp(0.8, 16 / 9)
                          : (16 / 9),
                      child: ClipRect(
                        child: SizedBox.expand(
                          child: Builder(
                            builder: (context) {
                              final bool isRotated = _previewVideoController!.value.rotationCorrection == 90 ||
                                  _previewVideoController!.value.rotationCorrection == 270;
                              final double videoWidth = isRotated
                                  ? _previewVideoController!.value.size.height
                                  : _previewVideoController!.value.size.width;
                              final double videoHeight = isRotated
                                  ? _previewVideoController!.value.size.width
                                  : _previewVideoController!.value.size.height;

                              return FittedBox(
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                                child: SizedBox(
                                  width: videoWidth > 0 ? videoWidth : 16,
                                  height: videoHeight > 0 ? videoHeight : 9,
                                  child: VideoPlayer(_previewVideoController!),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    )
                  : const Center(
                      child: CircularProgressIndicator(color: AppColors.patasColor),
                    )
              : kIsWeb
                  ? Image.network(
                      selectedImagePath,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(child: Icon(Icons.broken_image, size: 50)),
                    )
                  : Image.file(
                      File(selectedImagePath),
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),

          // Botão Flutuante de Fechar (Top-Right)
          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _clearMedia,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),

          // Badge de Duração do Vídeo (Bottom-Left)
          if (isVideo)
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
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
                          ? '${_videoDurationSeconds ?? 60}s (máx. 60s)'
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

          // Botão Flutuante de Trocar Mídia (Bottom-Right)
          Positioned(
            bottom: 12,
            right: 12,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isVideo ? _showVideoSourceDialog : _showImageSourceDialog,
                borderRadius: BorderRadius.circular(16),
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cached_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Trocar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
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
      ),
    );
  }

  Widget _buildCustomHeader(DarkMode thmode) {
    final isDark = thmode.darkMode;
    return Container(
      padding: EdgeInsets.only(
        top: context.isWide ? 18 : MediaQuery.of(context).padding.top + 10,
        bottom: context.isWide ? 14 : 14,
        left: context.isWide ? 14 : 12,
        right: context.isWide ? 18 : 16,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: isDark ? Colors.white : AppColors.darkBG,
              size: 26,
            ),
            onPressed: () => Navigator.pop(context),
            splashRadius: 22,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: () async {
                  final profile = await showModalBottomSheet<PublishProfile>(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const ProfileSelectorDialog(),
                  );
                  if (profile != null) {
                    setState(() => _selectedProfile = profile);
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 11,
                        backgroundColor: isDark ? Colors.white24 : Colors.grey.shade300,
                        backgroundImage: (_selectedProfile?.photoUrl != null &&
                                _selectedProfile!.photoUrl!.isNotEmpty)
                            ? NetworkImage(_selectedProfile!.photoUrl!)
                            : null,
                        child: (_selectedProfile?.photoUrl == null ||
                                _selectedProfile!.photoUrl!.isEmpty)
                            ? const Icon(Icons.pets, size: 12, color: AppColors.patasColor)
                            : null,
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          _selectedProfile?.name ?? 'Selecionar Perfil',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.darkBG,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: (isDark ? Colors.white70 : AppColors.darkBG).withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          PatasButton(
            text: 'Publicar',
            onPressed: _handlePublish,
            isLoading: _isPublishing,
            variant: PatasButtonVariant.primary,
            size: PatasButtonSize.small,
          ),
        ],
      ),
    );
  }

  Widget _buildActionDock(DarkMode thmode) {
    final hasMedia = selectedImagePath.isNotEmpty || isVideo;
    final isDark = thmode.darkMode;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: context.isWide
            ? 12
            : (MediaQuery.of(context).viewInsets.bottom > 0
                ? 10
                : MediaQuery.of(context).padding.bottom + 8),
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBG : AppColors.selectedColor,
        border: Border(
          top: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.07),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Botão Galeria de Fotos
          _buildDockIconButton(
            icon: Icons.photo_library_outlined,
            label: 'Galeria',
            onTap: selectImageFromGallery,
            thmode: thmode,
          ),
          const SizedBox(width: 6),

          // Botão Câmera
          _buildDockIconButton(
            icon: Icons.camera_alt_outlined,
            label: 'Câmera',
            onTap: selectImageFromCamera,
            thmode: thmode,
          ),
          const SizedBox(width: 6),

          // Botão Vídeo
          _buildDockIconButton(
            icon: Icons.videocam_outlined,
            label: 'Vídeo',
            onTap: _showVideoSourceDialog,
            thmode: thmode,
          ),

          const Spacer(),

          // Badge indicador se mídia estiver anexada
          if (hasMedia)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.patasColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.patasColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isVideo ? Icons.videocam_rounded : Icons.image_rounded,
                    size: 14,
                    color: AppColors.patasColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isVideo ? 'Vídeo' : 'Foto',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.patasColor,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDockIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required DarkMode thmode,
  }) {
    final isDark = thmode.darkMode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: AppColors.patasColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: (isDark ? Colors.white : AppColors.darkBG).withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final activePet = Provider.of<ActivePetProvider>(context).activePet;

    if (_selectedProfile == null && activePet != null) {
      _selectedProfile = PublishProfile(
        id: activePet.id,
        name: activePet.name,
        photoUrl: activePet.photoUrl,
        type: 'pet',
      );
    }

    final isWide = context.isWide;
    final scaffoldBg = isWide 
        ? Colors.transparent 
        : (thmode.darkMode ? AppColors.darkBG : AppColors.selectedColor);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        children: [
          // 1. Fundo Glassmorphism (Backdrop Filter) - Externo
          if (isWide)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ),
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.transparent,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 750 : double.infinity,
                  maxHeight: isWide ? 850 : double.infinity,
                ),
                child: Container(
                  margin: isWide ? const EdgeInsets.symmetric(vertical: 24, horizontal: 20) : EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: thmode.darkMode
                        ? AppColors.darkBG
                        : AppColors.selectedColor,
                    borderRadius: isWide
                        ? BorderRadius.circular(32)
                        : BorderRadius.zero,
                    boxShadow: isWide
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
                  child: Column(
                    children: [
                      // 1. Header customizado
                      _buildCustomHeader(thmode),

                      // 2. Área principal de conteúdo (Scrollable)
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Linha com Avatar + Campo de Texto
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: thmode.darkMode
                                        ? Colors.white24
                                        : Colors.grey.shade300,
                                    backgroundImage: (_selectedProfile?.photoUrl != null &&
                                            _selectedProfile!.photoUrl!.isNotEmpty)
                                        ? NetworkImage(_selectedProfile!.photoUrl!)
                                        : null,
                                    child: (_selectedProfile?.photoUrl == null ||
                                            _selectedProfile!.photoUrl!.isEmpty)
                                        ? const Icon(Icons.pets,
                                            size: 20, color: AppColors.patasColor)
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: TextField(
                                      controller: _contentController,
                                      keyboardType: TextInputType.multiline,
                                      maxLines: null,
                                      minLines: 3,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: thmode.darkMode
                                            ? Colors.white
                                            : AppColors.darkBG,
                                        height: 1.4,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: "No que seu pet está pensando agora?",
                                        hintStyle: TextStyle(
                                          fontSize: 16,
                                          color: (thmode.darkMode
                                                  ? Colors.white70
                                                  : AppColors.darkBG)
                                              .withValues(alpha: 0.45),
                                        ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        contentPadding: const EdgeInsets.only(top: 6),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Prévia da mídia anexada (se houver)
                              _buildMediaPreview(),

                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),

                      // 3. Barra de Ações Inferior (Action Dock)
                      if (!_isPublishing) _buildActionDock(thmode),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Overlay de publicação (Processing)
          if (_isPublishing) _buildPublishingOverlay(),
        ],
      ),
    );
  }

  Widget _buildPublishingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: AppColors.patasColor,
                  strokeWidth: 5,
                ),
                const SizedBox(height: 24),
                Text(
                  _publishingStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                    fontFamily: 'Fredoka',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Estamos preparando sua publicação...',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Future<String> selectImageFromGallery() async {
    final file = await _imageHelper.pickCropAndCompress(
      context: context,
      source: ImageSource.gallery,
      aspectRatioPresets: [
        CropAspectRatioPreset.original,
        CropAspectRatioPreset.square,
        CropAspectRatioPreset.ratio4x3,
        CropAspectRatioPreset.ratio16x9,
      ],
    );
    if (file != null) {
      setState(() {
        isVideo = false;
        selectedImagePath = file.path;
      });
    }
    return file?.path ?? '';
  }

  Future<String> selectImageFromCamera() async {
    final file = await _imageHelper.pickCropAndCompress(
      context: context,
      source: ImageSource.camera,
      aspectRatioPresets: [
        CropAspectRatioPreset.original,
        CropAspectRatioPreset.square,
        CropAspectRatioPreset.ratio4x3,
        CropAspectRatioPreset.ratio16x9,
      ],
    );
    if (file != null) {
      setState(() {
        isVideo = false;
        selectedImagePath = file.path;
      });
    }
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
                'Adicionar Foto',
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
                  await selectImageFromGallery();
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
                  await selectImageFromCamera();
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
                'Adicionar Vídeo',
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
                subtitle: 'Selecione um vídeo já gravado (máx. 60s)',
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

  /// Processa a seleção de vídeo da galeria: seleciona bruto, valida limite de tempo e comprime/corta
  Future<void> _handleVideoSelection() async {
    try {
      // 1. Seleciona arquivo bruto da galeria
      final rawVideoFile = await _videoPickerService.pickVideoOnly(
        type: VideoType.post,
        source: ImageSource.gallery,
      );

      if (rawVideoFile == null) return; // Usuário cancelou no seletor

      // 2. Valida a duração real do vídeo
      final validation = await _videoPickerService.validateVideoFile(
        videoFile: rawVideoFile,
        type: VideoType.post,
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

      // 3. Validação de limite de tempo com decisão do usuário ANTES de comprimir
      final canProceed = await _checkVideoDurationLimit(
        originalDuration,
        maxLimitSeconds: 60,
      );
      if (!canProceed) return; // Usuário cancelou no diálogo

      final int targetDuration = _isDurationCapped ? 60 : (originalDuration > 0 ? originalDuration : 60);

      // 4. Mostrar diálogo de progresso de compressão e corte
      setState(() {
        _videoCompressionProgress = 0.0;
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => PopScope(
            canPop: false,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: AppColors.patasColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _videoCompressionProgress > 0
                        ? 'Otimizando e ajustando vídeo... ${(_videoCompressionProgress * 100).toInt()}%'
                        : 'Otimizando e ajustando vídeo...',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Compactando para envio rápido e sem falhas.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // 5. Comprime e CORTA fisicamente o vídeo para o targetDuration
      final result = await _videoPickerService.compressAndProcessFile(
        videoFile: rawVideoFile,
        type: VideoType.post,
        maxDurationSeconds: targetDuration,
        onCompressionProgress: (progress) {
          if (mounted) {
            setState(() => _videoCompressionProgress = progress);
          }
        },
      );

      // Fechar diálogo de progresso
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (result.success && result.videoFile != null) {
        final processedFile = result.videoFile!;
        if (mounted) {
          setState(() {
            isVideo = true;
            _pickedVideoXFile = XFile(processedFile.path);
            selectedVideoPath = processedFile.path;
            selectedVideoThumbnail = result.thumbnailFile;
            selectedImagePath = result.thumbnailFile?.path ?? (kIsWeb ? 'video_placeholder' : processedFile.path);
            _videoDurationSeconds = targetDuration;
            _previewVideoInitialized = false;
          });

          // Inicializar prévia de vídeo real cortado e otimizado
          _initVideoPreview(processedFile.path);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isDurationCapped
                    ? 'Vídeo cortado para 60s e otimizado com sucesso!'
                    : 'Vídeo otimizado com sucesso! Duração: ${targetDuration}s',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? 'Erro ao otimizar vídeo'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro inesperado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() {});
    }
  }

  /// Lida com gravação de vídeo pela câmera e edição com compressão/corte físico
  Future<void> _handleCameraRecording() async {
    try {
      // 1. Navegar para tela de gravação
      final recordedVideoPath = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => const CameraRecordingScreen(
            maxDurationSeconds: 60, // Posts: 60s
          ),
        ),
      );

      if (!mounted || recordedVideoPath == null) return;

      final rawVideoFile = File(recordedVideoPath);

      // 2. Valida a duração real do vídeo
      final validation = await _videoPickerService.validateVideoFile(
        videoFile: rawVideoFile,
        type: VideoType.post,
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

      // 3. Validação de limite de tempo
      final canProceed = await _checkVideoDurationLimit(
        originalDuration,
        maxLimitSeconds: 60,
      );
      if (!canProceed) return;

      final int targetDuration = _isDurationCapped ? 60 : (originalDuration > 0 ? originalDuration : 60);

      // 4. Diálogo de progresso de compressão
      setState(() {
        _videoCompressionProgress = 0.0;
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => PopScope(
            canPop: false,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.patasColor),
                  const SizedBox(height: 16),
                  Text(
                    _videoCompressionProgress > 0
                        ? 'Otimizando e ajustando vídeo... ${(_videoCompressionProgress * 100).toInt()}%'
                        : 'Otimizando e ajustando vídeo...',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Compactando para envio rápido e sem falhas.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // 5. Comprime e corta fisicamente
      final result = await _videoPickerService.compressAndProcessFile(
        videoFile: rawVideoFile,
        type: VideoType.post,
        maxDurationSeconds: targetDuration,
        onCompressionProgress: (progress) {
          if (mounted) {
            setState(() => _videoCompressionProgress = progress);
          }
        },
      );

      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (result.success && result.videoFile != null) {
        final processedFile = result.videoFile!;
        if (mounted) {
          setState(() {
            isVideo = true;
            _pickedVideoXFile = XFile(processedFile.path);
            selectedVideoPath = processedFile.path;
            selectedVideoThumbnail = result.thumbnailFile;
            selectedImagePath = result.thumbnailFile?.path ?? (kIsWeb ? 'video_placeholder' : processedFile.path);
            _videoDurationSeconds = targetDuration;
            _previewVideoInitialized = false;
          });

          _initVideoPreview(processedFile.path);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isDurationCapped
                    ? 'Vídeo cortado para 60s e otimizado com sucesso!'
                    : 'Vídeo gravado e otimizado com sucesso!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro inesperado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() {});
    }
  }
}
