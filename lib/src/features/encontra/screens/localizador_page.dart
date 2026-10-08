import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/core/localization/localizations_ext.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/features/encontra/services/encontra_service.dart';

class LocalizadorPage extends StatefulWidget {
  final String uuid;
  const LocalizadorPage({super.key, required this.uuid});

  @override
  State<LocalizadorPage> createState() => _LocalizadorPageState();
}

class _LocalizadorPageState extends State<LocalizadorPage> {
  final _encontraService = EncontraService();
  final _finderNameController = TextEditingController();
  final _messageController = TextEditingController();

  Map<String, dynamic>? _tagData;
  bool _isLoadingTag = true;
  bool _tagNotFound = false;

  bool _isLostMode = true;
  bool _isSendingLocation = false;
  bool _locationSent = false;

  @override
  void initState() {
    super.initState();
    _loadTagInfo();
  }

  @override
  void dispose() {
    _finderNameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadTagInfo() async {
    setState(() {
      _isLoadingTag = true;
      _tagNotFound = false;
    });

    try {
      final data = await _encontraService.getPublicTagInfo(widget.uuid);
      if (mounted) {
        if (data == null) {
          setState(() {
            _tagNotFound = true;
            _isLoadingTag = false;
          });
        } else {
          setState(() {
            _tagData = data;
            _isLostMode = data['is_lost'] == true;
            _isLoadingTag = false;
          });
        }
      }
    } catch (e) {
      debugPrint('LocalizadorPage._loadTagInfo error: $e');
      if (mounted) {
        setState(() {
          _tagNotFound = true;
          _isLoadingTag = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    if (_isLoadingTag) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.patasColor),
        ),
      );
    }

    if (_tagNotFound) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 64,
                  color: AppColors.patasColor,
                ),
                const SizedBox(height: 24),
                Text(
                  context.tr('encontra.tag_not_found_title'),
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.darkBG,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr('encontra.tag_not_found_desc'),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Toggle de simulação visível apenas em depuração (debug mode)
                if (kDebugMode) ...[
                  _buildSimulationControls(isDark),
                  const SizedBox(height: 24),
                ],

                // Card Principal com Info do Pet
                _buildMainCard(isDark),
                const SizedBox(height: 24),

                // Seção de Contatos / Botão de Ação
                _buildActionPanel(isDark),
                const SizedBox(height: 24),

                // Rodapé de marca institucional
                _buildFooter(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimulationControls(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.bug_report_outlined,
                color: _isLostMode ? Colors.red : AppColors.patasColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                context.tr('encontra.simulate_label', {'mode': _isLostMode ? context.tr('encontra.lost_mode') : 'Normal'}),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
          Switch(
            value: _isLostMode,
            activeThumbColor: Colors.redAccent,
            inactiveThumbColor: AppColors.patasColor,
            onChanged: (val) {
              setState(() {
                _isLostMode = val;
                _locationSent = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard(bool isDark) {
    final lostBg = isDark ? const Color(0xFF3A1C1C) : const Color(0xFFFFECEC);
    final normalBg = isDark ? const Color(0xFF1F2937) : Colors.white;
    final lostBorder = isDark
        ? Colors.red.withValues(alpha: 0.3)
        : Colors.red.withValues(alpha: 0.2);
    final normalBorder = isDark ? Colors.white10 : Colors.grey.shade200;

    final pet = _tagData?['pets'] as Map<String, dynamic>?;
    final petName = pet?['name'] ?? 'Pet';
    final species = pet?['species'] ?? '';
    final breed = pet?['breed'] ?? '';
    final photoUrl = pet?['photo_url'] as String?;
    final petDetail = [breed, species].where((s) => s.isNotEmpty).join(' · ');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: _isLostMode ? lostBg : normalBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _isLostMode ? lostBorder : normalBorder,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _isLostMode
                ? Colors.red.withValues(alpha: isDark ? 0.1 : 0.05)
                : Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Alerta no topo se estiver perdido
          if (_isLostMode) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('encontra.pet_lost_badge'),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Avatar com Foto do Pet
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isLostMode
                        ? Colors.redAccent
                        : AppColors.patasColor,
                    width: 3,
                  ),
                  image: photoUrl != null && photoUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(photoUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: photoUrl == null || photoUrl.isEmpty
                    ? Icon(
                        Icons.pets,
                        size: 64,
                        color: _isLostMode
                            ? Colors.redAccent
                            : AppColors.patasColor,
                      )
                    : null,
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isLostMode ? Colors.redAccent : AppColors.patasColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isLostMode ? Icons.radar : Icons.pets,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Nome do Pet
          Text(
            petName,
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.patasColor,
            ),
          ),
          const SizedBox(height: 4),

          // Raça e Espécie
          Text(
            petDetail.isEmpty ? context.tr('encontra.default_pet_name') : petDetail,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),

          const Divider(height: 1),
          const SizedBox(height: 20),

          // Informações de Cuidados / Saúde
          _buildInfoRow(
            context,
            isDark,
            icon: Icons.health_and_safety_outlined,
            title: context.tr('encontra.medical_care_title'),
            content: _isLostMode
                ? context.tr('encontra.medical_care_lost')
                : context.tr('encontra.medical_care_normal'),
            iconColor: Colors.teal,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            isDark,
            icon: Icons.info_outline_rounded,
            title: context.tr('encontra.behavior_title'),
            content: _isLostMode
                ? context.tr('encontra.behavior_lost')
                : context.tr('encontra.behavior_normal'),
            iconColor: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String title,
    required String content,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.8)
                      : Colors.black.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Colors.black54,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionPanel(bool isDark) {
    final pet = _tagData?['pets'] as Map<String, dynamic>?;
    final petName = pet?['name'] ?? 'o Pet';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isLostMode) ...[
            Text(
              context.tr('encontra.important_notice'),
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? Colors.white70
                    : Colors.black.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('encontra.notice_lost_desc', {'name': petName}),
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : Colors.black54,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Form Fields para info opcional
            TextField(
              controller: _finderNameController,
              decoration: InputDecoration(
                labelText: context.tr('encontra.finder_name_label'),
                hintText: context.tr('encontra.finder_name_hint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.person_outline),
              ),
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: context.tr('encontra.finder_msg_label'),
                hintText:
                    context.tr('encontra.finder_msg_hint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.chat_bubble_outline),
              ),
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 20),

            // Botão Principal: Enviar Localização Real
            ElevatedButton.icon(
              onPressed: _isSendingLocation || _locationSent
                  ? null
                  : _sendRealLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: _locationSent
                    ? Colors.green
                    : Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              icon: _isSendingLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      _locationSent
                          ? Icons.check_circle_outline
                          : Icons.my_location,
                    ),
              label: Text(
                _isSendingLocation
                    ? context.tr('encontra.sending_gps')
                    : (_locationSent
                          ? context.tr('encontra.location_sent')
                          : context.tr('encontra.send_location_btn')),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ] else ...[
            Text(
              context.tr('encontra.all_good_title'),
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? Colors.white70
                    : Colors.black.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('encontra.all_good_desc', {'name': petName}),
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : Colors.black54,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                // Abre o site do patas
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.patasColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.patasColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.language),
              label: Text(context.tr('encontra.meet_patas_btn')),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _sendRealLocation() async {
    setState(() {
      _isSendingLocation = true;
    });

    try {
      debugPrint('🔵 Iniciando _sendRealLocation usando Geolocator...');

      // 1. Verifica se o serviço de localização está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw context.tr('encontra.gps_disabled_err');
      }

      // 2. Verifica a permissão de localização
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw context.tr('encontra.gps_denied_err');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw context.tr('encontra.gps_denied_forever_err');
      }

      // 3. Captura a localização atual
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final lat = position.latitude;
      final lng = position.longitude;

      debugPrint('📍 Localização obtida com sucesso: $lat, $lng');

      // Salva no Supabase
      final success = await _encontraService.saveSighting(
        tagId: widget.uuid,
        latitude: lat,
        longitude: lng,
        message: _messageController.text.trim().isEmpty
            ? null
            : _messageController.text.trim(),
        finderName: _finderNameController.text.trim().isEmpty
            ? null
            : _finderNameController.text.trim(),
      );

      debugPrint('📤 Resultado do saveSighting: $success');

      if (!success) {
        throw context.tr('encontra.sighting_save_err');
      }

      if (mounted) {
        setState(() {
          _isSendingLocation = false;
          _locationSent = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr('encontra.location_sent_success'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ ERRO NO _sendRealLocation: $e');
      if (mounted) {
        setState(() {
          _isSendingLocation = false;
        });
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              context.tr('encontra.location_required_title'),
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'OK',
                  style: TextStyle(color: AppColors.patasColor),
                ),
              ),
            ],
          ),
        );
      }
    }
  }


  Widget _buildFooter(bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', width: 24, height: 24),
            const SizedBox(width: 8),
            const Text(
              'Patas Encontra',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.patasColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          context.tr('encontra.tag_tagline'),
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white30 : Colors.black38,
          ),
        ),
      ],
    );
  }
}
