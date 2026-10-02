import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart' show kIsWeb;

class ImageHelper {
  final ImagePicker _imagePicker = ImagePicker();
  final ImageCropper _imageCropper = ImageCropper();

  /// Captura ou seleciona imagem, abre editor de corte e comprime
  Future<File?> pickCropAndCompress({
    required BuildContext context,
    required ImageSource source,
    CropAspectRatio? aspectRatio,
    List<CropAspectRatioPreset>? aspectRatioPresets,
    int maxWidth = 1080,
    int maxHeight = 1920,
    int quality = 85,
  }) async {
    try {
      // Captura valores dependentes de context ANTES de qualquer await
      final screenSize = MediaQuery.of(context).size;
      final isMobile = screenSize.width < 600;

      // Constrói uiSettings antes dos awaits para evitar uso de context após async gap
      final uiSettings = <PlatformUiSettings>[
        AndroidUiSettings(
          toolbarTitle: 'Ajustar Imagem',
          toolbarColor: const Color(0xFFF16623), // AppColors.patasColor
          toolbarWidgetColor: Colors.white,
          statusBarLight: true,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: aspectRatio != null,
          aspectRatioPresets: aspectRatioPresets ??
              [
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9,
              ],
        ),
        IOSUiSettings(
          title: 'Ajustar Imagem',
          aspectRatioLockEnabled: aspectRatio != null,
          aspectRatioPresets: aspectRatioPresets ??
              [
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9,
              ],
        ),
        WebUiSettings(
          context: context,
          presentStyle: isMobile ? WebPresentStyle.page : WebPresentStyle.dialog,
          size: CropperSize(
            width: isMobile ? screenSize.width.toInt() : 520,
            height: isMobile ? screenSize.height.toInt() : 520,
          ),
        ),
      ];

      // 1. Pick
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
      );

      if (pickedFile == null) return null;

      // 2. Crop (usa uiSettings construído antes dos awaits)
      final CroppedFile? croppedFile = await _imageCropper.cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: aspectRatio,
        uiSettings: uiSettings,
      );

      if (croppedFile == null) return null;

      // NO WEB: Não fazemos compressão manual via arquivo pois o ImageCropper já retorna
      // um blob URL que funciona perfeitamente. Tentar comprimir via dart:io quebra o path.
      if (kIsWeb) {
        return File(croppedFile.path);
      }

      // 3. Compress
      return await compressImage(
        File(croppedFile.path),
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
      );
    } catch (e) {
      debugPrint('Erro no ImageHelper: $e');
      return null;
    }
  }

  /// Comprime a imagem para os padrões otimizados
  Future<File?> compressImage(
    File file, {
    int maxWidth = 1080,
    int maxHeight = 1920,
    int quality = 85,
  }) async {
    final String targetPath = p.join(
      (await path_provider.getTemporaryDirectory()).path,
      'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    final XFile? result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: quality,
      minWidth: maxWidth,
      minHeight: maxHeight,
    );

    if (result == null) return null;
    return File(result.path);
  }
}
