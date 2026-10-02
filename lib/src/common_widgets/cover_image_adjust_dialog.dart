import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/app.dart';

class CoverImageAdjustDialog extends StatefulWidget {
  final File? imageFile;
  final Uint8List? imageBytes;
  final XFile? xFile;

  const CoverImageAdjustDialog({
    super.key,
    this.imageFile,
    this.imageBytes,
    this.xFile,
  });

  @override
  State<CoverImageAdjustDialog> createState() => _CoverImageAdjustDialogState();
}

class _CoverImageAdjustDialogState extends State<CoverImageAdjustDialog> {
  final GlobalKey _repaintKey = GlobalKey();
  final TransformationController _transformationController =
      TransformationController();

  Uint8List? _bytes;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadBytes();
  }

  Future<void> _loadBytes() async {
    try {
      if (widget.imageBytes != null) {
        _bytes = widget.imageBytes;
      } else if (widget.xFile != null) {
        _bytes = await widget.xFile!.readAsBytes();
      } else if (widget.imageFile != null) {
        _bytes = await XFile(widget.imageFile!.path).readAsBytes();
      }
    } catch (e) {
      debugPrint('Erro ao ler bytes da imagem de capa: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmCrop() async {
    if (_isProcessing || _bytes == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary == null) {
        Navigator.of(context).pop(_bytes);
        return;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final Uint8List croppedBytes = byteData.buffer.asUint8List();
        if (mounted) {
          Navigator.of(context).pop(croppedBytes);
        }
      } else {
        if (mounted) {
          Navigator.of(context).pop(_bytes);
        }
      }
    } catch (e) {
      debugPrint('Erro ao capturar imagem recortada: $e');
      if (mounted) {
        Navigator.of(context).pop(_bytes);
      }
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkBG : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600.w,
          maxHeight: 0.85.sh,
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabeçalho
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: AppColors.patasColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.crop_rounded,
                      color: AppColors.patasColor,
                      size: 22.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ajustar Imagem de Capa',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.darkBG,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Arraste e aproxime para enquadrar na proporção ideal (16:9)',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white70 : Colors.black54,
                      size: 20.sp,
                    ),
                    tooltip: 'Cancelar',
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Área de Pré-visualização com InteractiveViewer e 16:9
              Flexible(
                child: Center(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.patasColor,
                          ),
                        )
                      : _bytes == null
                          ? Center(
                              child: Text(
                                'Não foi possível carregar a imagem selecionada.',
                                style: TextStyle(
                                  color:
                                      isDark ? Colors.white70 : Colors.black54,
                                  fontSize: 14.sp,
                                ),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: AppColors.patasColor
                                      .withValues(alpha: 0.5),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10.r),
                                child: AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: RepaintBoundary(
                                    key: _repaintKey,
                                    child: InteractiveViewer(
                                      transformationController:
                                          _transformationController,
                                      minScale: 1.0,
                                      maxScale: 4.0,
                                      boundaryMargin: EdgeInsets.all(40.r),
                                      clipBehavior: Clip.hardEdge,
                                      child: Image.memory(
                                        _bytes!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                ),
              ),
              SizedBox(height: 16.h),

              // Dica visual de controle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pinch_rounded,
                    size: 16.sp,
                    color: AppColors.patasColor,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'Use o movimento de pinça ou arraste para reposicionar',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Botões de ação
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isProcessing
                          ? null
                          : () => Navigator.of(context).pop(null),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        side: BorderSide(
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_isLoading || _bytes == null || _isProcessing)
                          ? null
                          : _confirmCrop,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.patasColor,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        elevation: 0,
                      ),
                      child: _isProcessing
                          ? SizedBox(
                              width: 18.w,
                              height: 18.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_rounded,
                                    size: 18.sp, color: Colors.white),
                                SizedBox(width: 6.w),
                                Text(
                                  'Confirmar Capa',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
