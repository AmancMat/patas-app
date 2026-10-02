import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/features/video/services/camera_service.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';

class CameraRecordingScreen extends StatefulWidget {
  final int maxDurationSeconds; // 30 para stories, 60 para posts

  const CameraRecordingScreen({
    super.key,
    required this.maxDurationSeconds,
  });

  @override
  State<CameraRecordingScreen> createState() => _CameraRecordingScreenState();
}

class _CameraRecordingScreenState extends State<CameraRecordingScreen> {
  final CameraService _cameraService = CameraService();
  bool _isInitialized = false;
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  String? _errorMessage;

  // Zoom e Flash
  double _currentZoom = 1.0;
  FlashMode _currentFlashMode = FlashMode.off;
  bool _showZoomIndicator = false;
  Timer? _zoomIndicatorTimer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      await _cameraService.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao acessar câmera: $e';
        });
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      await _cameraService.startRecording();

      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });

      // Timer para atualizar contador e parar automaticamente
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() => _recordingSeconds++);

          // Parar automaticamente ao atingir limite
          if (_recordingSeconds >= widget.maxDurationSeconds) {
            _stopRecording();
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao iniciar gravação: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      _recordingTimer?.cancel();

      final videoPath = await _cameraService.stopRecording();

      if (mounted) {
        setState(() => _isRecording = false);

        // Retornar path do vídeo
        Navigator.pop(context, videoPath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao parar gravação: $e')),
        );
      }
    }
  }

  Future<void> _switchCamera() async {
    try {
      await _cameraService.switchCamera();
      setState(() {
        _currentZoom = 1.0;
        _currentFlashMode = _cameraService.flashMode;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao trocar câmera: $e')),
        );
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (!_isInitialized) return;

    FlashMode nextMode;
    switch (_currentFlashMode) {
      case FlashMode.off:
        nextMode = FlashMode.always;
        break;
      case FlashMode.always:
        nextMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        nextMode = FlashMode.off;
        break;
      default:
        nextMode = FlashMode.off;
    }

    try {
      await _cameraService.setFlashMode(nextMode);
      setState(() => _currentFlashMode = nextMode);
    } catch (e) {
      debugPrint('Erro ao trocar flash: $e');
    }
  }

  IconData _getFlashIcon() {
    switch (_currentFlashMode) {
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.auto:
        return Icons.flash_auto;
      default:
        return Icons.flash_off;
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (!_isInitialized) return;

    // Sensibilidade do zoom
    double zoomChange = (details.scale - 1.0) * 0.1;
    double nextZoom = (_currentZoom + zoomChange).clamp(
      _cameraService.minZoom,
      _cameraService.maxZoom,
    );

    if (nextZoom != _currentZoom) {
      setState(() {
        _currentZoom = nextZoom;
        _showZoomIndicator = true;
      });
      _cameraService.setZoomLevel(_currentZoom);

      // Resetar timer do indicador
      _zoomIndicatorTimer?.cancel();
      _zoomIndicatorTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showZoomIndicator = false);
      });
    }
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _zoomIndicatorTimer?.cancel();
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.isWide ? Colors.transparent : Colors.black,
      body: Center(
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: context.isWide ? BorderRadius.circular(24.r) : BorderRadius.zero,
              boxShadow: context.isWide
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      )
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                // Preview da câmera com Zoom
                if (_isInitialized && _cameraService.controller != null)
                  Positioned.fill(
                    child: GestureDetector(
                      onScaleUpdate: _handleScaleUpdate,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _cameraService.controller!.value.previewSize?.height ?? 1080,
                          height: _cameraService.controller!.value.previewSize?.width ?? 1920,
                          child: CameraPreview(_cameraService.controller!),
                        ),
                      ),
                    ),
                  )
                else if (_errorMessage != null)
                  Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.all(24.r),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 60.r, color: Colors.white),
                            SizedBox(height: 16.h),
                            Text(
                              'Ops! Algo deu errado',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 24.h),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white24,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child: const Text('Voltar'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.patasColor),
                        SizedBox(height: 16),
                        Text(
                          'Acessando câmera...',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),

                // Overlay com controles
                Positioned.fill(
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Header com botões
                        Padding(
                          padding: EdgeInsets.all(16.r),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Botão fechar
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 32.r,
                                ),
                              ),

                              // Botão trocar câmera
                              if (_isInitialized)
                                Row(
                                  children: [
                                    // Botão Flash
                                    IconButton(
                                      onPressed: _toggleFlash,
                                      icon: Icon(
                                        _getFlashIcon(),
                                        color: Colors.white,
                                        size: 28.r,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    IconButton(
                                      onPressed: _isRecording ? null : _switchCamera,
                                      icon: Icon(
                                        Icons.flip_camera_ios,
                                        color: _isRecording
                                            ? Colors.white.withValues(alpha: 0.3)
                                            : Colors.white,
                                        size: 30.r,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),

                        // Barra de progresso estilo Stories no topo
                        if (_isRecording)
                          Padding(
                            padding:
                                EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2.r),
                              child: LinearProgressIndicator(
                                value: _recordingSeconds / widget.maxDurationSeconds,
                                backgroundColor: Colors.white.withValues(alpha: 0.1),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                minHeight: 2.h,
                              ),
                            ),
                          ),

                        const Spacer(),

                        // Indicador de Zoom
                        if (_showZoomIndicator)
                          Container(
                            padding:
                                EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              '${_currentZoom.toStringAsFixed(1)}x',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                        SizedBox(height: 16.h),

                        // Contador de tempo
                        if (_isRecording)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.fiber_manual_record,
                                  color: Colors.white,
                                  size: 12.r,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  _formatDuration(_recordingSeconds),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  ' / ${_formatDuration(widget.maxDurationSeconds)}',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        SizedBox(height: 32.h),

                        // Botão de gravação
                        if (_isInitialized)
                          GestureDetector(
                            onTap: _toggleRecording,
                            child: Container(
                              width: 80.r,
                              height: 80.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4.w,
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: 60.r,
                                  height: 60.r,
                                  decoration: BoxDecoration(
                                    color: _isRecording ? Colors.red : Colors.white,
                                    shape: _isRecording
                                        ? BoxShape.rectangle
                                        : BoxShape.circle,
                                    borderRadius: _isRecording
                                        ? BorderRadius.circular(8.r)
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        SizedBox(height: 48.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
