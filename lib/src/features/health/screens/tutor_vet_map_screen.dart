import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';

import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import '../models/vet_profile_model.dart';
import '../services/patas_saude_service.dart';
import 'book_appointment_screen.dart';

class TutorVetMapScreen extends StatefulWidget {
  const TutorVetMapScreen({super.key});

  @override
  State<TutorVetMapScreen> createState() => _TutorVetMapScreenState();
}

class _TutorVetMapScreenState extends State<TutorVetMapScreen> {
  final MapController _mapController = MapController();
  final _saudeService = PatasSaudeService();
  final TextEditingController _searchController = TextEditingController();

  List<VetProfile> _vets = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';
  bool _isSatelliteView = true;

  @override
  void initState() {
    super.initState();
    _loadVets();
  }

  Future<void> _loadVets() async {
    setState(() => _isLoading = true);
    final list = await _saudeService.getVetsAndClinics(
      search: _searchController.text,
      typeFilter: _selectedCategory,
    );
    if (mounted) {
      setState(() {
        _vets = list;
        _isLoading = false;
      });
    }
  }

  IconData _getVetIcon(String type) {
    switch (type.toLowerCase()) {
      case 'hospital_24h':
        return Icons.local_hospital_rounded;
      case 'clinic':
        return Icons.medical_information_rounded;
      default:
        return Icons.medical_services_rounded;
    }
  }

  String _getCategoryLabel(String type) {
    switch (type.toLowerCase()) {
      case 'hospital_24h':
        return 'Hospital 24h';
      case 'clinic':
        return 'Clínica Veterinária';
      default:
        return 'Veterinário Autônomo';
    }
  }

  void _showVetDetailsModal(VetProfile vet) {
    final isDark = Provider.of<DarkMode>(context, listen: false).darkMode;

    if (vet.latitude != null && vet.longitude != null) {
      _mapController.move(LatLng(vet.latitude!, vet.longitude!), 16.0);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 84),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, -5)),
            ],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.patasColor.withValues(alpha: 0.2),
                      backgroundImage: (vet.photoUrl != null && vet.photoUrl!.isNotEmpty)
                          ? NetworkImage(vet.photoUrl!)
                          : null,
                      child: (vet.photoUrl == null || vet.photoUrl!.isEmpty)
                          ? Icon(_getVetIcon(vet.type), size: 28, color: AppColors.patasColor)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vet.fullName,
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.darkBG,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_getCategoryLabel(vet.type)} • CRMV ${vet.crmvUf} ${vet.crmvNumber}',
                            style: const TextStyle(fontSize: 12, color: AppColors.patasColor, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (vet.bio != null && vet.bio!.isNotEmpty) ...[
                  Text(
                    vet.bio!,
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ],

                if (vet.address != null && vet.address!.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          vet.address!,
                          style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (vet.acceptsClinicVisit)
                      Chip(
                        avatar: const Icon(Icons.medical_information_rounded, size: 14, color: Colors.white),
                        label: const Text('Atende na Clínica', style: TextStyle(fontSize: 11, color: Colors.white)),
                        backgroundColor: Colors.teal.shade700,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      ),
                    if (vet.acceptsHomeVisit)
                      Chip(
                        avatar: const Icon(Icons.home_work_rounded, size: 14, color: Colors.white),
                        label: const Text('Atende a Domicílio', style: TextStyle(fontSize: 11, color: Colors.white)),
                        backgroundColor: Colors.indigo.shade700,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_month_rounded, color: Colors.white),
                  label: Text(
                    vet.consultationPrice > 0
                        ? 'Agendar Consulta (R\$ ${vet.consultationPrice.toStringAsFixed(2)})'
                        : 'Agendar Consulta',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookAppointmentScreen(vet: vet),
                      ),
                    ).then((_) => _loadVets());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.patasColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final defaultCenter = const LatLng(-23.5505, -46.6333);

    final mainContent = Scaffold(
      backgroundColor: isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
      appBar: PatasEssencialAppBar(
        title: 'Patas Saúde',
        subtitle: 'Mapa de veterinários e clínicas 24h',
        bottomHeight: 88.0,
        bottomWidget: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 750),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => _loadVets(),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white : AppColors.darkBG,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nome, especialidade ou endereço...',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.grey.shade500,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.patasColor, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _loadVets();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'Todos', Icons.apps_rounded, isDark),
                      _buildFilterChip('veterinarian', 'Veterinários', Icons.medical_services_rounded, isDark),
                      _buildFilterChip('clinic', 'Clínicas', Icons.medical_information_rounded, isDark),
                      _buildFilterChip('hospital_24h', 'Hospitais 24h', Icons.local_hospital_rounded, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Mapa Interativo
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: defaultCenter,
                    initialZoom: 13.0,
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

                    MarkerLayer(
                      markers: _vets
                          .where((v) => v.latitude != null && v.longitude != null)
                          .map((vet) {
                        return Marker(
                          point: LatLng(vet.latitude!, vet.longitude!),
                          width: 44,
                          height: 44,
                          child: GestureDetector(
                            onTap: () => _showVetDetailsModal(vet),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.patasColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                                ],
                              ),
                              child: Icon(
                                _getVetIcon(vet.type),
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                // Toggle Satélite
                Positioned(
                  top: 16,
                  right: 16,
                  child: FloatingActionButton.small(
                    heroTag: null,
                    backgroundColor: isDark ? AppColors.darkBG : Colors.white,
                    onPressed: () => setState(() => _isSatelliteView = !_isSatelliteView),
                    child: Icon(
                      _isSatelliteView ? Icons.map_rounded : Icons.satellite_alt_rounded,
                      color: AppColors.patasColor,
                    ),
                  ),
                ),

                if (_isLoading)
                  const Positioned(
                    top: 16,
                    left: 16,
                    child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.patasColor),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    return mainContent;
  }

  Widget _buildFilterChip(String value, String label, IconData icon, bool isDark) {
    final isSelected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (!isSelected) {
            setState(() => _selectedCategory = value);
            _loadVets();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.patasColor
                : (isDark ? const Color(0xFF1E293B) : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.patasColor
                  : (isDark ? Colors.white12 : Colors.grey.shade300),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.patasColor.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.darkBG),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.darkBG),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
