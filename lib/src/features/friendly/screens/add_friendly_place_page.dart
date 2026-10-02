import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';

import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import '../models/friendly_place_model.dart';
import '../services/friendly_service.dart';

class AddFriendlyPlacePage extends StatefulWidget {
  final LatLng initialPosition;
  final List<FriendlyPlace>? existingPlaces;

  const AddFriendlyPlacePage({
    super.key,
    required this.initialPosition,
    this.existingPlaces,
  });

  @override
  State<AddFriendlyPlacePage> createState() => _AddFriendlyPlacePageState();
}

class _AddFriendlyPlacePageState extends State<AddFriendlyPlacePage> {
  final _formKey = GlobalKey<FormState>();
  final _friendlyService = FriendlyService();
  final MapController _mapController = MapController();

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rulesController = TextEditingController();

  String _selectedCategory = 'restaurant';
  LatLng? _selectedLocation;
  bool _isPolygonMode = false;
  final List<LatLng> _polygonPoints = [];
  bool _isSaving = false;
  bool _isSatelliteView = true;

  List<FriendlyPlace> _existingPlaces = [];

  @override
  void initState() {
    super.initState();
    _selectedLocation = null;
    if (widget.existingPlaces != null) {
      _existingPlaces = widget.existingPlaces!;
    } else {
      _loadExistingPlaces();
    }
  }

  Future<void> _loadExistingPlaces() async {
    final places = await _friendlyService.getFriendlyPlaces();
    if (mounted) {
      setState(() {
        _existingPlaces = places;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _rulesController.dispose();
    super.dispose();
  }

  Future<void> _submitPlace() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, marque a localização do estabelecimento no mapa.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isPolygonMode && _polygonPoints.isNotEmpty && _polygonPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Para delimitar a Área Pet, marque pelo menos 3 pontos no mapa.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final res = await _friendlyService.createFriendlyPlace(
      name: _nameController.text.trim(),
      category: _selectedCategory,
      address: _addressController.text.trim(),
      latitude: _selectedLocation!.latitude,
      longitude: _selectedLocation!.longitude,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      rulesDescription: _rulesController.text.trim().isEmpty ? null : _rulesController.text.trim(),
      polygonPoints: _isPolygonMode ? _polygonPoints : null,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Local sugerido com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Returns true to trigger dashboard refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Erro ao cadastrar local.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    Widget mainForm = Theme(
      data: Theme.of(context).copyWith(
        brightness: isDark ? Brightness.dark : Brightness.light,
        textTheme: Theme.of(context).textTheme.copyWith(
          titleMedium: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
          bodyLarge: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
        ),
        inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
          labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38),
          prefixIconColor: isDark ? Colors.white70 : AppColors.patasColor,
        ),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Informações do Local',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : AppColors.darkBG,
              ),
            ),
            const SizedBox(height: 16),
            
            // Nome
            TextFormField(
              controller: _nameController,
              style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
              decoration: InputDecoration(
                labelText: 'Nome do Estabelecimento *',
                prefixIcon: const Icon(Icons.store_rounded, color: AppColors.patasColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Por favor, informe o nome.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Categoria
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG, fontSize: 16),
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              decoration: InputDecoration(
                labelText: 'Categoria *',
                prefixIcon: const Icon(Icons.category_rounded, color: AppColors.patasColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              items: [
                DropdownMenuItem(value: 'restaurant', child: Text('Restaurante', style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG))),
                DropdownMenuItem(value: 'hotel', child: Text('Hotel / Hospedagem', style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG))),
                DropdownMenuItem(value: 'park', child: Text('Parque / Ao ar livre', style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG))),
                DropdownMenuItem(value: 'cafe', child: Text('Café / Doceria', style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG))),
                DropdownMenuItem(value: 'shopping', child: Text('Shopping', style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG))),
                DropdownMenuItem(value: 'other', child: Text('Outro', style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG))),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedCategory = val;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Endereço
            TextFormField(
              controller: _addressController,
              style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
              decoration: InputDecoration(
                labelText: 'Endereço *',
                prefixIcon: const Icon(Icons.place_outlined, color: AppColors.patasColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Por favor, informe o endereço.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Telefone (opcional)
            TextFormField(
              controller: _phoneController,
              style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Telefone de Contato (Opcional)',
                prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.patasColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),

            // Descrição (opcional)
            TextFormField(
              controller: _descriptionController,
              style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Sobre o Local (Opcional)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),

            // Regras Pet (opcional)
            TextFormField(
              controller: _rulesController,
              style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Regras Pet (Opcional)',
                hintText: 'Ex: Apenas cães pequenos, Necessário uso de coleira, etc.',
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 28),

            // Seção Mapa
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Marcar no Mapa *',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : AppColors.darkBG,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _isSatelliteView = !_isSatelliteView),
                  child: Row(
                    children: [
                      Icon(
                        _isSatelliteView ? Icons.map_rounded : Icons.satellite_alt_rounded,
                        size: 14,
                        color: AppColors.patasColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isSatelliteView ? 'Mapa' : 'Satélite',
                        style: const TextStyle(fontSize: 11, color: AppColors.patasColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Seletor de Modo: Apenas Pin vs Pin + Polígono
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Apenas Pin', style: TextStyle(fontFamily: 'Fredoka', fontSize: 13, fontWeight: FontWeight.bold)),
                    selected: !_isPolygonMode,
                    selectedColor: AppColors.patasColor,
                    labelStyle: TextStyle(color: !_isPolygonMode ? Colors.white : (isDark ? Colors.white70 : AppColors.darkBG)),
                    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    onSelected: (val) {
                      if (val) setState(() => _isPolygonMode = false);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Pin + Área (Polígono)', style: TextStyle(fontFamily: 'Fredoka', fontSize: 13, fontWeight: FontWeight.bold)),
                    selected: _isPolygonMode,
                    selectedColor: AppColors.patasColor,
                    labelStyle: TextStyle(color: _isPolygonMode ? Colors.white : (isDark ? Colors.white70 : AppColors.darkBG)),
                    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    onSelected: (val) {
                      if (val) setState(() => _isPolygonMode = true);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              !_isPolygonMode
                  ? 'Toque no mapa para posicionar o Pin exato do local.'
                  : 'Toque para definir o Pin e continue tocando nos cantos para desenhar a Área Pet.',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            // Mini Mapa Picker
            Container(
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.patasColor.withValues(alpha: 0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: widget.initialPosition,
                    initialZoom: 15.0,
                    onTap: (tapPosition, point) {
                      setState(() {
                        if (!_isPolygonMode) {
                          _selectedLocation = point;
                        } else {
                          _polygonPoints.add(point);
                          _selectedLocation = _polygonPoints.first;
                        }
                      });
                    },
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
                    
                    // Polígonos de locais existentes + Polígono sendo desenhado
                    PolygonLayer(
                      polygons: [
                        ..._existingPlaces
                            .where((place) => place.getPolygonPoints().isNotEmpty)
                            .map(
                              (place) => Polygon(
                                points: place.getPolygonPoints(),
                                color: Colors.purple.withValues(alpha: 0.15),
                                borderColor: Colors.purple.withValues(alpha: 0.4),
                                borderStrokeWidth: 1.5,
                              ),
                            ),
                        if (_isPolygonMode && _polygonPoints.length >= 3)
                          Polygon(
                            points: _polygonPoints,
                            color: AppColors.patasColor.withValues(alpha: 0.30),
                            borderColor: AppColors.patasColor,
                            borderStrokeWidth: 2.5,
                          ),
                      ],
                    ),

                    if (_isPolygonMode && _polygonPoints.length >= 2)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _polygonPoints,
                            strokeWidth: 2.0,
                            color: AppColors.patasColor,
                          ),
                        ],
                      ),

                    // Marcadores (Locais já cadastrados + Novo Pin)
                    MarkerLayer(
                      markers: [
                        ..._existingPlaces.map(
                          (place) => Marker(
                            point: LatLng(place.latitude, place.longitude),
                            width: 22,
                            height: 22,
                            child: Opacity(
                              opacity: 0.65,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(Icons.store_rounded, size: 12, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_selectedLocation != null)
                          Marker(
                            point: _selectedLocation!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: AppColors.patasColor,
                              size: 38,
                            ),
                          ),
                        if (_isPolygonMode)
                          ..._polygonPoints.map(
                            (p) => Marker(
                              point: p,
                              width: 14,
                              height: 14,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.patasColor, width: 2),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_isPolygonMode) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _polygonPoints.isEmpty
                        ? 'Toque no mapa para adicionar o 1º ponto da área.'
                        : 'Pontos da Área Pet: ${_polygonPoints.length}',
                    style: const TextStyle(fontSize: 12, color: AppColors.patasColor, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      if (_polygonPoints.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => setState(() => _polygonPoints.removeLast()),
                          icon: const Icon(Icons.undo_rounded, size: 16, color: Colors.orange),
                          label: const Text('Desfazer', style: TextStyle(fontSize: 12, color: Colors.orange)),
                        ),
                      if (_polygonPoints.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => setState(() => _polygonPoints.clear()),
                          icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                          label: const Text('Limpar', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                        ),
                    ],
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),

            // Botão Salvar
            ElevatedButton(
              onPressed: _isSaving ? null : _submitPlace,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.patasColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Sugerir Local',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    ),
  );

    return Scaffold(
      backgroundColor: isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
      appBar: const PatasEssencialAppBar(
        title: 'Sugerir Novo Local',
        subtitle: 'Cadastre um espaço pet friendly na comunidade',
      ),
      body: isDesktop
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Card(
                  margin: const EdgeInsets.all(24),
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: mainForm,
                  ),
                ),
              ),
            )
          : mainForm,
    );
  }
}
