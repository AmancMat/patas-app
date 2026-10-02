import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// Serviço para gerenciar a câmera e gravação de vídeos
class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _currentCameraIndex = 0;
  bool _isRecording = false;

  CameraController? get controller => _controller;
  bool get isRecording => _isRecording;
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  FlashMode _flashMode = FlashMode.off;
  FlashMode get flashMode => _flashMode;

  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double get minZoom => _minZoom;
  double get maxZoom => _maxZoom;

  /// Inicializa a câmera
  Future<void> initialize() async {
    try {
      debugPrint('🎥 Inicializando câmera...');

      // Obter câmeras disponíveis
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('Nenhuma câmera disponível no dispositivo.');
      }

      debugPrint('📷 Câmeras encontradas: ${_cameras!.length}');

      // Tentar inicializar com presets decrescentes se falhar
      final List<ResolutionPreset> presets = [
        ResolutionPreset.high,
        ResolutionPreset.medium,
        ResolutionPreset.low,
      ];

      bool initialized = false;
      Object? lastError;

      for (var preset in presets) {
        try {
          debugPrint('🔄 Tentando inicializar com preset: ${preset.name}');
          
          _controller = CameraController(
            _cameras![_currentCameraIndex],
            preset,
            enableAudio: true,
            imageFormatGroup: ImageFormatGroup.jpeg,
          );

          await _controller!.initialize();
          initialized = true;
          debugPrint('✅ Sucesso com preset: ${preset.name}');
          break;
        } catch (e) {
          debugPrint('⚠️ Falha no preset ${preset.name}: $e');
          lastError = e;
          await _controller?.dispose();
        }
      }

      if (!initialized) {
        throw Exception('Não foi possível inicializar a câmera em nenhum preset: $lastError');
      }

      // Obter limites de zoom (silencioso na Web)
      try {
        _minZoom = await _controller!.getMinZoomLevel();
        _maxZoom = await _controller!.getMaxZoomLevel();
        debugPrint('🔍 Limites de Zoom: $_minZoom - $_maxZoom');
      } catch (e) {
        debugPrint('ℹ️ Zoom não suportado: $e');
        _minZoom = 1.0;
        _maxZoom = 1.0;
      }

      // Definir flash padrão (silencioso na Web)
      try {
        await _controller!.setFlashMode(_flashMode);
      } catch (e) {
        debugPrint('ℹ️ Flash não suportado: $e');
      }

      debugPrint('🏁 Inicialização concluída!');
    } catch (e, stackTrace) {
      debugPrint('❌ Erro FATAL ao inicializar câmera: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Troca entre câmera frontal e traseira
  Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) {
      debugPrint('⚠️ Apenas uma câmera disponível');
      return;
    }

    try {
      debugPrint('🔄 Trocando câmera...');

      // Alternar índice
      _currentCameraIndex = (_currentCameraIndex + 1) % _cameras!.length;

      // Descartar controller antigo
      await _controller?.dispose();

      // Tentar inicializar com presets decrescentes se falhar
      final List<ResolutionPreset> presets = [
        ResolutionPreset.high,
        ResolutionPreset.medium,
        ResolutionPreset.low,
      ];

      bool initialized = false;
      Object? lastError;

      for (var preset in presets) {
        try {
          debugPrint('🔄 Tentando trocar com preset: ${preset.name}');
          
          _controller = CameraController(
            _cameras![_currentCameraIndex],
            preset,
            enableAudio: true,
            imageFormatGroup: ImageFormatGroup.jpeg,
          );

          await _controller!.initialize();
          initialized = true;
          debugPrint('✅ Sucesso na troca com preset: ${preset.name}');
          break;
        } catch (e) {
          debugPrint('⚠️ Falha na troca no preset ${preset.name}: $e');
          lastError = e;
          await _controller?.dispose();
        }
      }

      if (!initialized) {
        throw Exception('Não foi possível trocar a câmera em nenhum preset: $lastError');
      }

      // Obter novos limites de zoom (silencioso na Web)
      try {
        _minZoom = await _controller!.getMinZoomLevel();
        _maxZoom = await _controller!.getMaxZoomLevel();
        debugPrint('🔍 Novos Limites de Zoom: $_minZoom - $_maxZoom');
      } catch (e) {
        debugPrint('ℹ️ Zoom não suportado na nova câmera: $e');
        _minZoom = 1.0;
        _maxZoom = 1.0;
      }

      // Reaplicar flash mode (silencioso na Web)
      try {
        await _controller!.setFlashMode(_flashMode);
      } catch (e) {
        debugPrint('ℹ️ Flash não suportado na nova câmera: $e');
      }

      debugPrint('✅ Câmera trocada com sucesso!');
    } catch (e) {
      debugPrint('❌ Erro FATAL ao trocar câmera: $e');
      rethrow;
    }
  }

  /// Inicia a gravação de vídeo
  Future<void> startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('Câmera não inicializada');
    }

    if (_isRecording) {
      debugPrint('⚠️ Gravação já em andamento');
      return;
    }

    try {
      debugPrint('🎬 Iniciando gravação...');
      await _controller!.startVideoRecording();
      _isRecording = true;
      debugPrint('✅ Gravação iniciada');
    } catch (e) {
      debugPrint('❌ Erro ao iniciar gravação: $e');
      rethrow;
    }
  }

  /// Para a gravação e retorna o path do vídeo
  Future<String> stopRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('Câmera não inicializada');
    }

    if (!_isRecording) {
      throw Exception('Nenhuma gravação em andamento');
    }

    try {
      debugPrint('⏹️ Parando gravação...');
      final XFile videoFile = await _controller!.stopVideoRecording();
      _isRecording = false;

      debugPrint('✅ Gravação finalizada');
      debugPrint('📍 Path: ${videoFile.path}');

      return videoFile.path;
    } catch (e) {
      debugPrint('❌ Erro ao parar gravação: $e');
      _isRecording = false;
      rethrow;
    }
  }

  /// Pausa a gravação (se suportado)
  Future<void> pauseRecording() async {
    if (_controller == null || !_isRecording) return;

    try {
      await _controller!.pauseVideoRecording();
      debugPrint('⏸️ Gravação pausada');
    } catch (e) {
      debugPrint('❌ Erro ao pausar gravação: $e');
    }
  }

  /// Retoma a gravação (se suportado)
  Future<void> resumeRecording() async {
    if (_controller == null || !_isRecording) return;

    try {
      await _controller!.resumeVideoRecording();
      debugPrint('▶️ Gravação retomada');
    } catch (e) {
      debugPrint('❌ Erro ao retomar gravação: $e');
    }
  }

  /// Altera o modo do flash
  Future<void> setFlashMode(FlashMode mode) async {
    if (_controller == null || !isInitialized) return;

    try {
      await _controller!.setFlashMode(mode);
      _flashMode = mode;
      debugPrint('⚡ Flash alterado para: $mode');
    } catch (e) {
      debugPrint('ℹ️ Flash não suportado por este hardware/browser: $e');
      // Silenciar erro para não travar a UI
    }
  }

  /// Altera o nível de zoom
  Future<void> setZoomLevel(double level) async {
    if (_controller == null || !isInitialized) return;

    try {
      // Garantir que o valor está dentro dos limites
      final double zoom = level.clamp(_minZoom, _maxZoom);
      await _controller!.setZoomLevel(zoom);
      debugPrint('🔍 Zoom alterado para: $zoom');
    } catch (e) {
      debugPrint('ℹ️ Zoom não suportado durante o ajuste: $e');
    }
  }

  /// Libera recursos da câmera
  void dispose() {
    debugPrint('🗑️ Liberando recursos da câmera...');
    _controller?.dispose();
    _controller = null;
  }
}
