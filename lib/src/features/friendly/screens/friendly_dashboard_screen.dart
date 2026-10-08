import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:patas_web_app/core/localization/localizations_ext.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/providers/user_role_provider.dart';

import '../models/friendly_place_model.dart';
import '../services/friendly_service.dart';
import 'friendly_place_details_page.dart';
import 'add_friendly_place_page.dart';

class FriendlyDashboardScreen extends StatefulWidget {
  const FriendlyDashboardScreen({super.key});

  @override
  State<FriendlyDashboardScreen> createState() => _FriendlyDashboardScreenState();
}

class _FriendlyDashboardScreenState extends State<FriendlyDashboardScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final _friendlyService = FriendlyService();
  final TextEditingController _searchController = TextEditingController();
  
  LatLng? _currentPosition;
  List<FriendlyPlace> _places = [];
  FriendlyPlace? _selectedPlace;
  
  String _searchQuery = '';
  String _selectedCategoryFilter = 'all';
  
  bool _isLoadingLocation = true;
  bool _isLoadingPlaces = false;
  bool _isSatelliteView = true;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Serviço de localização (GPS) está desativado.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Permissão de localização negada.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Permissão de localização negada permanentemente.';
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
        _loadPlaces();
      }
    } catch (e) {
      debugPrint('Erro ao obter localização: $e');
      if (mounted) {
        setState(() {
          // Fallback para São Paulo
          _currentPosition = const LatLng(-23.5505, -46.6333);
          _isLoadingLocation = false;
        });
        _loadPlaces();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível obter localização: $e. Usando São Paulo como padrão.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _loadPlaces() async {
    setState(() => _isLoadingPlaces = true);
    final places = await _friendlyService.getFriendlyPlaces();
    if (mounted) {
      setState(() {
        _places = places;
        _isLoadingPlaces = false;
      });
    }
  }

  List<FriendlyPlace> _getFilteredPlaces() {
    return _places.where((place) {
      final matchesSearch = place.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          place.address.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesCategory = _selectedCategoryFilter == 'all' ||
          place.category.toLowerCase() == _selectedCategoryFilter.toLowerCase();
          
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
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
      curve: Curves.fastOutSlowIn,
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

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'restaurant':
      case 'restaurante':
        return Icons.restaurant_rounded;
      case 'hotel':
      case 'hospedagem':
        return Icons.hotel_rounded;
      case 'park':
      case 'parque':
        return Icons.park_rounded;
      case 'cafe':
      case 'cafeteria':
        return Icons.local_cafe_rounded;
      case 'shopping':
        return Icons.local_mall_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  String _getCategoryName(String category) {
    switch (category.toLowerCase()) {
      case 'restaurant':
        return 'Restaurante';
      case 'hotel':
        return 'Hotel / Hospedagem';
      case 'park':
        return 'Parque / Ao ar livre';
      case 'cafe':
        return 'Café / Doceria';
      case 'shopping':
        return 'Shopping';
      default:
        return 'Outro';
    }
  }

  void _showPlaceSummary(FriendlyPlace place) {
    final isDark = Provider.of<DarkMode>(context, listen: false).darkMode;

    setState(() {
      _selectedPlace = place;
    });

    // Foca o mapa no Pin selecionado e dá um zoom confortável
    _animatedMapMove(LatLng(place.latitude, place.longitude), 17.0);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 84),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 15,
                offset: Offset(0, -5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      place.name,
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.darkBG,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      if (Provider.of<UserRoleProvider>(context, listen: false).role == UserRole.admin)
                        IconButton(
                          tooltip: 'Excluir Local (Admin)',
                          icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                          onPressed: () async {
                            Navigator.pop(context);
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: const Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
                                    SizedBox(width: 10),
                                    Text('Excluir Local?', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                content: Text(
                                  'Tem certeza que deseja excluir permanentemente o local "${place.name}"?\n\nEsta ação é exclusiva para administradores e não poderá ser desfeita.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    icon: const Icon(Icons.delete_forever_rounded, color: Colors.white),
                                    label: const Text('Excluir Local', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              final success = await _friendlyService.deleteFriendlyPlace(place.id);
                              if (success) {
                                _loadPlaces();
                              }
                            }
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    _getCategoryIcon(place.category),
                    size: 16,
                    color: AppColors.patasColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getCategoryName(place.category),
                    style: const TextStyle(
                      color: AppColors.patasColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      place.address,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (place.creatorName != null && place.creatorName!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 11,
                      backgroundColor: AppColors.patasColor.withValues(alpha: 0.15),
                      backgroundImage: (place.creatorPhotoUrl != null && place.creatorPhotoUrl!.isNotEmpty)
                          ? NetworkImage(place.creatorPhotoUrl!)
                          : null,
                      child: (place.creatorPhotoUrl == null || place.creatorPhotoUrl!.isEmpty)
                          ? const Icon(Icons.person_rounded, size: 12, color: AppColors.patasColor)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('friendly.suggested_by'),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                    Text(
                      place.creatorName!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : AppColors.darkBG,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Fecha o resumo
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FriendlyPlaceDetailsPage(place: place),
                      ),
                    ).then((_) => _loadPlaces()); // Recarrega se houve edição de polígono
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.patasColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    context.tr('friendly.explore_place_btn'),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      // Quando fechar o bottom sheet, remove o polígono e pin selecionados
      if (mounted) {
        setState(() {
          _selectedPlace = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    Widget mainContent = Scaffold(
      backgroundColor: isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
      appBar: PatasEssencialAppBar(
        title: context.tr('friendly.title'),
        subtitle: context.tr('friendly.subtitle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.patasColor),
            onPressed: _loadPlaces,
            tooltip: context.tr('friendly.refresh_tooltip'),
          ),
        ],
      ),
      body: _isLoadingLocation
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.patasColor),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('friendly.locating'),
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 16,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: Stack(
                children: [
                  _buildRealMap(isDark),
                  
                  // 1. FILTROS DE CATEGORIAS E BUSCA NO TOPO
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Campo de Busca
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1F2937) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: context.tr('friendly.search_hint'),
                              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.patasColor),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Carrossel Horizontal de Categorias
                        SizedBox(
                          height: 42,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _buildCategoryChip('all', context.tr('friendly.cat_all'), Icons.map_rounded, isDark),
                              _buildCategoryChip('restaurant', context.tr('friendly.cat_restaurant'), Icons.restaurant_rounded, isDark),
                              _buildCategoryChip('hotel', context.tr('friendly.cat_hotel'), Icons.hotel_rounded, isDark),
                              _buildCategoryChip('park', context.tr('friendly.cat_park'), Icons.park_rounded, isDark),
                              _buildCategoryChip('cafe', context.tr('friendly.cat_cafe'), Icons.local_cafe_rounded, isDark),
                              _buildCategoryChip('shopping', context.tr('friendly.cat_shopping'), Icons.local_mall_rounded, isDark),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. TOGGLE SATÉLITE (reposicionado para evitar sobreposição)
                  Positioned(
                    top: 138,
                    right: 16,
                    child: _buildSatelliteToggle(isDark),
                  ),

                  // 3. CONTROLES DE ZOOM E GPS (canto inferior direito)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Column(
                      children: [
                        _buildMapControl(isDark, Icons.my_location_rounded, () {
                          if (_currentPosition != null) {
                            _animatedMapMove(_currentPosition!, 15.0);
                          }
                        }),
                        const SizedBox(height: 12),
                        _buildMapControl(isDark, Icons.add_rounded, () {
                          final currentZoom = _mapController.camera.zoom;
                          _animatedMapMove(_mapController.camera.center, currentZoom + 1);
                        }),
                        const SizedBox(height: 8),
                        _buildMapControl(isDark, Icons.remove_rounded, () {
                          final currentZoom = _mapController.camera.zoom;
                          _animatedMapMove(_mapController.camera.center, currentZoom - 1);
                        }),
                      ],
                    ),
                  ),
                  
                  if (_isLoadingPlaces)
                    const Positioned(
                      top: 138,
                      left: 16,
                      child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.patasColor),
                    ),

                  // 4. BOTÃO PARA SUGERIR LOCAL NOVO (Pill com gradiente, brilho e texto)
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: GestureDetector(
                      onTap: () async {
                        final refresh = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddFriendlyPlacePage(
                              initialPosition: _currentPosition ?? const LatLng(-23.5505, -46.6333),
                              existingPlaces: _places,
                            ),
                          ),
                        );
                        if (refresh == true) {
                          _loadPlaces();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.patasColor, Color(0xFFFF5252)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.patasColor.withValues(alpha: 0.45),
                              blurRadius: 14,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add_location_alt_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              context.tr('friendly.add_place_short'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Fredoka',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
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

    return mainContent;
  }

  Widget _buildCategoryChip(String value, String label, IconData icon, bool isDark) {
    final isSelected = _selectedCategoryFilter == value;
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        ),
        onSelected: (selected) {
          setState(() {
            _selectedCategoryFilter = selected ? value : 'all';
          });
        },
        selectedColor: AppColors.patasColor,
        checkmarkColor: Colors.transparent,
        showCheckmark: false,
        backgroundColor: isDark ? const Color(0xFF374151) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected
                ? AppColors.patasColor
                : (isDark ? Colors.white10 : Colors.grey.shade200),
          ),
        ),
      ),
    );
  }

  Widget _buildRealMap(bool isDark) {
    const osmUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    const satelliteUrl =
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

    final filteredPlaces = _getFilteredPlaces();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentPosition ?? const LatLng(-23.5505, -46.6333),
        initialZoom: 15.0,
        maxZoom: 18.0,
        minZoom: 3.0,
      ),
      children: [
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
              urlTemplate: osmUrl,
              userAgentPackageName: 'patas.online.app',
              tileProvider: CancellableNetworkTileProvider(),
            ),
          ),
        
        // Camada de Polígonos de Perímetro Pet Friendly (Exibe o perímetro de todos os locais que possuem área definida)
        PolygonLayer(
          polygons: [
            ...filteredPlaces
                .where((place) => place.getPolygonPoints().isNotEmpty)
                .map(
                  (place) => Polygon(
                    points: place.getPolygonPoints(),
                    color: (_selectedPlace?.id == place.id)
                        ? AppColors.patasColor.withValues(alpha: 0.35)
                        : AppColors.patasColor.withValues(alpha: 0.18),
                    borderColor: AppColors.patasColor,
                    borderStrokeWidth: (_selectedPlace?.id == place.id) ? 3.5 : 2.0,
                  ),
                ),
          ],
        ),

        // Camada de Marcadores (Pins)
        MarkerLayer(
          markers: [
            // Localização do Usuário
            if (_currentPosition != null)
              Marker(
                point: _currentPosition!,
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: _buildUserLocationMarker(isDark),
              ),
            // Estabelecimentos Filtrados
            ...filteredPlaces.map((place) {
              return Marker(
                point: LatLng(place.latitude, place.longitude),
                width: 48,
                height: 48,
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: () => _showPlaceSummary(place),
                  child: _buildPlacePin(place, isDark),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildUserLocationMarker(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.patasColor.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: AppColors.patasColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatasPawSvg({required Color color, double size = 24}) {
    final colorHex = '#${color.toARGB32().toRadixString(16).substring(2)}';
    final svgString = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" fill="none">
  <!-- Central Main Pad -->
  <path d="M 50 46 C 35 46, 22 57, 22 72 C 22 83, 33 89, 50 89 C 67 89, 78 83, 78 72 C 78 57, 65 46, 50 46 Z" fill="$colorHex"/>
  <!-- Toe 1 (Far Left) -->
  <ellipse cx="22" cy="38" rx="7.5" ry="12" fill="$colorHex" transform="rotate(-28 22 38)"/>
  <!-- Toe 2 (Center Left) -->
  <ellipse cx="40" cy="24" rx="8" ry="13" fill="$colorHex" transform="rotate(-8 40 24)"/>
  <!-- Toe 3 (Center Right) -->
  <ellipse cx="60" cy="24" rx="8" ry="13" fill="$colorHex" transform="rotate(8 60 24)"/>
  <!-- Toe 4 (Far Right) -->
  <ellipse cx="78" cy="38" rx="7.5" ry="12" fill="$colorHex" transform="rotate(28 78 38)"/>
</svg>
''';
    return SvgPicture.string(
      svgString,
      width: size,
      height: size,
    );
  }

  Widget _buildPlacePin(FriendlyPlace place, bool isDark) {
    final isSelected = _selectedPlace?.id == place.id;
    final pinIconColor = isSelected ? Colors.white : AppColors.patasColor;

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? AppColors.patasColor : (isDark ? const Color(0xFF2D3748) : Colors.white),
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? Colors.white : AppColors.patasColor,
          width: 2.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Center(
        child: _buildPatasPawSvg(color: pinIconColor, size: 24),
      ),
    );
  }

  Widget _buildSatelliteToggle(bool isDark) {
    return GestureDetector(
      onTap: () => setState(() => _isSatelliteView = !_isSatelliteView),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _isSatelliteView
              ? Colors.black.withValues(alpha: 0.8)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isSatelliteView
                ? Colors.white24
                : AppColors.patasColor.withValues(alpha: 0.3),
            width: 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isSatelliteView ? Icons.map_rounded : Icons.satellite_alt_rounded,
              size: 16,
              color: _isSatelliteView ? Colors.white : AppColors.patasColor,
            ),
            const SizedBox(width: 8),
            Text(
              _isSatelliteView ? 'Mapa' : 'Satélite',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _isSatelliteView ? Colors.white : AppColors.patasColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControl(bool isDark, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white70 : AppColors.patasColor,
          size: 22,
        ),
      ),
    );
  }
}
