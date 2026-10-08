import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/core/localization/localizations_ext.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/features/encontra/services/encontra_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';

class HistoricoAvistamentosScreen extends StatefulWidget {
  const HistoricoAvistamentosScreen({super.key});

  @override
  State<HistoricoAvistamentosScreen> createState() =>
      _HistoricoAvistamentosScreenState();
}

class _HistoricoAvistamentosScreenState
    extends State<HistoricoAvistamentosScreen>
    with TickerProviderStateMixin {
  final _encontraService = EncontraService();
  final MapController _mapController = MapController();
  int _selectedSightingIndex = 0;
  List<Map<String, dynamic>> _sightings = [];
  bool _isLoading = true;
  bool _isSatelliteView = true;

  @override
  void initState() {
    super.initState();
    _loadSightings();
  }

  Future<void> _loadSightings() async {
    setState(() => _isLoading = true);
    final data = await _encontraService.getMySightings();
    if (mounted) {
      setState(() {
        _sightings = data;
        _isLoading = false;
      });
    }
  }

  LatLng _getInitialCenter() {
    if (_sightings.isNotEmpty) {
      for (final s in _sightings) {
        final lat = (s['latitude'] as num?)?.toDouble();
        final lng = (s['longitude'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          return LatLng(lat, lng);
        }
      }
    }
    return const LatLng(-23.5505, -46.6333); // São Paulo
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    // Interpolação suave de latitude, longitude e zoom
    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: destZoom,
    );

    final controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn, // Frenagem suave elástica similar à do Maps
    );

    controller.addListener(() {
      if (mounted) {
        _mapController.move(
          LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
          zoomTween.evaluate(animation),
        );
      }
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  void _centerMapOnSighting(int index) {
    if (index >= 0 && index < _sightings.length) {
      final sighting = _sightings[index];
      final lat = (sighting['latitude'] as num?)?.toDouble();
      final lng = (sighting['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        _animatedMapMove(
          LatLng(lat, lng),
          16.0,
        ); // Foca com zoom confortável animado
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    Widget mainContent = Scaffold(
      backgroundColor: isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
      appBar: PatasEssencialAppBar(
        title: context.tr('encontra.history_title'),
        subtitle: context.tr('encontra.history_subtitle'),
        showBackButton: true,
        leadingIcon: const Icon(
          Icons.history_rounded,
          color: AppColors.patasColor,
          size: 22,
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.patasColor,
            ),
            onPressed: _loadSightings,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: isDesktop
                  ? _buildDesktopLayout(isDark)
                  : _buildMobileLayout(isDark),
            ),
    );

    return mainContent;
  }

  Widget _buildMobileLayout(bool isDark) {
    return Column(
      children: [
        // 1. MAPA REAL
        Expanded(flex: 5, child: _buildRealMap(isDark)),

        // 2. PAINEL INFERIOR - LISTA DE DETALHES DE AVISTAMENTO
        Expanded(
          flex: 4,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 15,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: _buildSightingListContent(isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. LINHA DO TEMPO DE AVISTAMENTOS NA ESQUERDA
        Container(
          width: 420,
          margin: const EdgeInsets.fromLTRB(24, 8, 0, 24),
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
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: _buildSightingListContent(isDark),
        ),

        // 2. MAPA REAL
        Expanded(child: _buildRealMap(isDark)),
      ],
    );
  }

  Widget _buildSightingListContent(bool isDark) {
    if (_sightings.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off_rounded, size: 52, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            context.tr('encontra.no_sightings_registered'),
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 16,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('encontra.activate_lost_mode_to_receive'),
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('encontra.timeline_title'),
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : AppColors.darkBG,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: _sightings.length,
            itemBuilder: (context, index) {
              final sighting = _sightings[index];
              final isSelected = _selectedSightingIndex == index;
              final tag = sighting['tags'] as Map<String, dynamic>?;
              final pet = tag?['pets'] as Map<String, dynamic>?;
              final petName = pet?['name'] ?? 'Pet';
              final lat = sighting['latitude'] as num?;
              final lng = sighting['longitude'] as num?;
              final seenAt = sighting['seen_at'] as String?;
              final message = sighting['message'] as String?;
              final finderName = sighting['finder_name'] as String?;

              String timeAgo = '';
              String timeStr = '';
              if (seenAt != null) {
                final seen = DateTime.tryParse(seenAt);
                if (seen != null) {
                  final diff = DateTime.now().difference(seen);
                  if (diff.inMinutes < 60) {
                    timeAgo = context.tr('encontra.time_min', {'min': '${diff.inMinutes}'});
                  } else if (diff.inHours < 24) {
                    timeAgo = context.tr('encontra.time_hour', {'hour': '${diff.inHours}'});
                  } else {
                    timeAgo = context.tr('encontra.time_day', {'day': '${diff.inDays}'});
                  }

                  final hour = seen.hour.toString().padLeft(2, '0');
                  final minute = seen.minute.toString().padLeft(2, '0');
                  final day = seen.day.toString().padLeft(2, '0');
                  final month = seen.month.toString().padLeft(2, '0');
                  timeStr = '$day/$month às $hour:$minute';
                }
              }

              final address = sighting['address'] as String?;
              final locationLabel = address != null && address.isNotEmpty
                  ? address
                  : (lat != null && lng != null
                      ? 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}'
                      : context.tr('encontra.location_not_available'));

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSightingIndex = index;
                  });
                  _centerMapOnSighting(index);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.redAccent.withValues(alpha: 0.1)
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.grey.shade50),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Colors.redAccent
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.15)
                                : Colors.grey.shade200),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: isSelected
                            ? Colors.redAccent
                            : Colors.grey,
                        radius: 12,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  petName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.darkBG,
                                  ),
                                ),
                                Text(
                                  timeAgo,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? Colors.white30
                                        : Colors.black38,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              locationLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(height: 6),
                              Text(
                                message != null && message.isNotEmpty
                                    ? '"$message"'
                                    : context.tr('encontra.no_comment'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black.withValues(alpha: 0.8),
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person_outline,
                                    size: 12,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${finderName != null && finderName.isNotEmpty ? finderName : context.tr('encontra.unknown_finder')} · $timeStr ($timeAgo)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRealMap(bool isDark) {
    final initialCenter = _getInitialCenter();

    const osmUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    const satelliteUrl =
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade300,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: 14.0,
                maxZoom: 18.0,
                minZoom: 3.0,
              ),
              children: [
                // No modo satélite, não aplica o filtro de inversão
                if (_isSatelliteView)
                  TileLayer(
                    urlTemplate: satelliteUrl,
                    userAgentPackageName: 'patas.online.app',
                    tileProvider: CancellableNetworkTileProvider(),
                  )
                else
                  ColorFiltered(
                    colorFilter: isDark
                        ? const ColorFilter.matrix([
                            -1.0,
                            0.0,
                            0.0,
                            0.0,
                            255.0,
                            0.0,
                            -1.0,
                            0.0,
                            0.0,
                            255.0,
                            0.0,
                            0.0,
                            -1.0,
                            0.0,
                            255.0,
                            0.0,
                            0.0,
                            0.0,
                            1.0,
                            0.0,
                          ])
                        : const ColorFilter.matrix([
                            1.0,
                            0.0,
                            0.0,
                            0.0,
                            0.0,
                            0.0,
                            1.0,
                            0.0,
                            0.0,
                            0.0,
                            0.0,
                            0.0,
                            1.0,
                            0.0,
                            0.0,
                            0.0,
                            0.0,
                            0.0,
                            1.0,
                            0.0,
                          ]),
                    child: TileLayer(
                      urlTemplate: osmUrl,
                      userAgentPackageName: 'patas.online.app',
                      tileProvider: CancellableNetworkTileProvider(),
                    ),
                  ),
                MarkerLayer(
                  markers: _sightings.asMap().entries.map((entry) {
                    final index = entry.key;
                    final sighting = entry.value;
                    final isSelected = _selectedSightingIndex == index;
                    final lat =
                        (sighting['latitude'] as num?)?.toDouble() ?? 0.0;
                    final lng =
                        (sighting['longitude'] as num?)?.toDouble() ?? 0.0;

                    return Marker(
                      point: LatLng(lat, lng),
                      width: 120,
                      height: 95,
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedSightingIndex = index;
                          });
                          _centerMapOnSighting(index);
                        },
                        child: _buildMapPin(index + 1, isSelected),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            // Controles de zoom (canto inferior direito)
            Positioned(
              right: 16,
              bottom: 16,
              child: Column(
                children: [
                  _buildMapControl(isDark, Icons.add, () {
                    final currentZoom = _mapController.camera.zoom;
                    _animatedMapMove(
                      _mapController.camera.center,
                      currentZoom + 1,
                    );
                  }),
                  const SizedBox(height: 8),
                  _buildMapControl(isDark, Icons.remove, () {
                    final currentZoom = _mapController.camera.zoom;
                    _animatedMapMove(
                      _mapController.camera.center,
                      currentZoom - 1,
                    );
                  }),
                ],
              ),
            ),

            // Toggle satélite / mapa (canto superior direito)
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () =>
                    setState(() => _isSatelliteView = !_isSatelliteView),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _isSatelliteView
                        ? Colors.black.withValues(alpha: 0.72)
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.white.withValues(alpha: 0.88)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isSatelliteView
                          ? Colors.white24
                          : AppColors.patasColor.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isSatelliteView
                            ? Icons.map_rounded
                            : Icons.satellite_alt_rounded,
                        size: 15,
                        color: _isSatelliteView
                            ? Colors.white
                            : AppColors.patasColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isSatelliteView ? context.tr('encontra.map_toggle') : context.tr('encontra.satellite_toggle'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _isSatelliteView
                              ? Colors.white
                              : AppColors.patasColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Badge de atribuição do provedor (canto inferior esquerdo)
            Positioned(
              left: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _isSatelliteView ? '© Esri World Imagery' : '© OpenStreetMap',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPin(int index, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.redAccent : Colors.grey.shade700,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            context.tr('encontra.sighting_pin', {'index': '$index'}),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Stack(
          alignment: Alignment.center,
          children: [
            if (isSelected)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.0, end: 2.2),
                duration: const Duration(seconds: 1),
                builder: (context, value, child) {
                  return Container(
                    width: 32 * value,
                    height: 32 * value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.redAccent.withValues(
                        alpha: (2.2 - value) / 3,
                      ),
                    ),
                  );
                },
                onEnd: () {
                  setState(() {});
                },
              ),
            Icon(
              Icons.location_on,
              color: isSelected ? Colors.redAccent : Colors.grey.shade700,
              size: isSelected ? 36 : 28,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMapControl(bool isDark, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white70 : AppColors.darkBG,
          size: 20,
        ),
      ),
    );
  }
}
