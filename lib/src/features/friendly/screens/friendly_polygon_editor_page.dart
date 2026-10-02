import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';

import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import '../models/friendly_place_model.dart';
import '../services/friendly_service.dart';

class FriendlyPolygonEditorPage extends StatefulWidget {
  final FriendlyPlace place;

  const FriendlyPolygonEditorPage({super.key, required this.place});

  @override
  State<FriendlyPolygonEditorPage> createState() => _FriendlyPolygonEditorPageState();
}

class _FriendlyPolygonEditorPageState extends State<FriendlyPolygonEditorPage> {
  final MapController _mapController = MapController();
  final _friendlyService = FriendlyService();
  final List<LatLng> _points = [];
  bool _isSatelliteView = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Load existing polygon points if they exist
    _points.addAll(widget.place.getPolygonPoints());
  }

  Future<void> _savePolygon() async {
    if (_points.isNotEmpty && _points.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, defina pelo menos 3 pontos para formar um perímetro.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    
    final success = await _friendlyService.updatePlacePolygon(widget.place.id, _points);
    
    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perímetro pet friendly salvo com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Returns true to trigger updates
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao salvar perímetro no banco de dados.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _addPoint(LatLng point) {
    setState(() {
      _points.add(point);
    });
  }

  void _undoLastPoint() {
    if (_points.isNotEmpty) {
      setState(() {
        _points.removeLast();
      });
    }
  }

  void _clearPoints() {
    if (_points.isNotEmpty) {
      setState(() {
        _points.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    Widget mainContent = Scaffold(
      backgroundColor: isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.patasColor,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Editar Perímetro Pet',
          style: TextStyle(
            fontFamily: 'Fredoka',
            color: AppColors.patasColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.patasColor),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _savePolygon,
              child: const Text(
                'Salvar',
                style: TextStyle(color: AppColors.patasColor, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // 1. MAPA INTERATIVO PARA TOQUES
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(widget.place.latitude, widget.place.longitude),
                initialZoom: 17.0,
                maxZoom: 20.0,
                minZoom: 3.0,
                onTap: (tapPosition, point) => _addPoint(point),
              ),
              children: [
                if (_isSatelliteView)
                  TileLayer(
                    urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                    userAgentPackageName: 'patas.online.app',
                    tileProvider: CancellableNetworkTileProvider(),
                  )
                else
                  ColorFiltered(
                    colorFilter: isDark
                        ? const ColorFilter.matrix([
                            -1.0, 0.0, 0.0, 0.0, 255.0,
                            0.0, -1.0, 0.0, 0.0, 255.0,
                            0.0, 0.0, -1.0, 0.0, 255.0,
                            0.0, 0.0, 0.0, 1.0, 0.0,
                          ])
                        : const ColorFilter.matrix([
                            1.0, 0.0, 0.0, 0.0, 0.0,
                            0.0, 1.0, 0.0, 0.0, 0.0,
                            0.0, 0.0, 1.0, 0.0, 0.0,
                            0.0, 0.0, 0.0, 1.0, 0.0,
                          ]),
                    child: TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'patas.online.app',
                      tileProvider: CancellableNetworkTileProvider(),
                    ),
                  ),
                
                // Camada do polígono desenhado
                PolygonLayer(
                  polygons: [
                    if (_points.isNotEmpty)
                      Polygon(
                        points: _points,
                        color: AppColors.patasColor.withValues(alpha: 0.25),
                        borderColor: AppColors.patasColor,
                        borderStrokeWidth: 3,
                      ),
                  ],
                ),

                // Marcador do local e vértices do polígono
                MarkerLayer(
                  markers: [
                    // Marcador central do estabelecimento
                    Marker(
                      point: LatLng(widget.place.latitude, widget.place.longitude),
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1F2937) : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.amber, width: 2.5),
                        ),
                        child: const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                      ),
                    ),
                    // Marcadores dos pontos desenhados
                    ..._points.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final point = entry.value;
                      return Marker(
                        point: point,
                        width: 22,
                        height: 22,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.patasColor, width: 3),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${idx + 1}',
                              style: const TextStyle(
                                color: AppColors.patasColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),

            // 2. BANNER DE INSTRUÇÕES NO TOPO
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withValues(alpha: 0.75) : Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppColors.patasColor, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Toque no mapa para demarcar os pontos do perímetro permitido para cães.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. CONTROLES DO PERÍMETRO (BOTÃO DESFAZER E LIMPAR)
            Positioned(
              left: 16,
              bottom: 16,
              child: Row(
                children: [
                  _buildActionButton(Icons.undo_rounded, 'Desfazer', _undoLastPoint, isDark),
                  const SizedBox(width: 12),
                  _buildActionButton(Icons.delete_sweep_rounded, 'Limpar', _clearPoints, isDark),
                ],
              ),
            ),

            // 4. TOGGLE SATÉLITE
            Positioned(
              right: 16,
              top: 86,
              child: GestureDetector(
                onTap: () => setState(() => _isSatelliteView = !_isSatelliteView),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isSatelliteView ? Colors.black87 : (isDark ? Colors.white24 : Colors.white),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isSatelliteView ? Colors.white30 : AppColors.patasColor.withValues(alpha: 0.3),
                      width: 1.2,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isSatelliteView ? Icons.map_rounded : Icons.satellite_alt_rounded,
                        size: 14,
                        color: _isSatelliteView ? Colors.white : AppColors.patasColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isSatelliteView ? 'Mapa' : 'Satélite',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _isSatelliteView ? Colors.white : AppColors.patasColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (isDesktop) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: mainContent,
        ),
      );
    }

    return mainContent;
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.patasColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : AppColors.darkBG,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
