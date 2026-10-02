import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';

import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import '../../models/vet_profile_model.dart';
import '../../services/patas_saude_service.dart';

class VetRegistrationScreen extends StatefulWidget {
  final VetProfile? existingProfile;
  final bool showAppBar;

  const VetRegistrationScreen({
    super.key,
    this.existingProfile,
    this.showAppBar = true,
  });

  @override
  State<VetRegistrationScreen> createState() => _VetRegistrationScreenState();
}

class _VetRegistrationScreenState extends State<VetRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _saudeService = PatasSaudeService();
  final MapController _mapController = MapController();

  late TextEditingController _nameController;
  late TextEditingController _crmvNumberController;
  late TextEditingController _crmvUfController;
  late TextEditingController _clinicNameController;
  late TextEditingController _bioController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _numberController;
  late TextEditingController _priceController;

  String _type = 'veterinarian'; // 'veterinarian', 'clinic', 'hospital_24h'
  bool _acceptsHomeVisit = false;
  bool _acceptsClinicVisit = true;
  bool _isSaving = false;

  double? _selectedLatitude;
  double? _selectedLongitude;

  int _consultationDuration = 30;
  int _maxAppointmentsPerSlot = 1;
  int _cancellationLimitHours = 24;

  final List<String> _selectedSpecialties = [];
  final List<String> _availableSpecialties = [
    'Clínica Geral', 'Dermatologia', 'Ortopedia', 'Cardiologia',
    'Oftalmologia', 'Cirurgia Geral', 'Odontologia', 'Oncologia',
    'Neurologia', 'Animais Silvestres', 'Fisioterapia'
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.existingProfile;
    _nameController = TextEditingController(text: p?.fullName ?? '');
    _crmvNumberController = TextEditingController(text: p?.crmvNumber ?? '');
    _crmvUfController = TextEditingController(text: p?.crmvUf ?? 'SP');
    _clinicNameController = TextEditingController(text: p?.clinicName ?? '');
    _bioController = TextEditingController(text: p?.bio ?? '');
    _phoneController = TextEditingController(text: p?.phone ?? '');
    _addressController = TextEditingController(text: p?.address ?? '');
    _numberController = TextEditingController();
    _priceController = TextEditingController(text: p != null ? p.consultationPrice.toStringAsFixed(2) : '150.00');

    if (p != null) {
      _type = p.type;
      _acceptsHomeVisit = p.acceptsHomeVisit;
      _acceptsClinicVisit = p.acceptsClinicVisit;
      _selectedSpecialties.addAll(p.specialties);
      _selectedLatitude = p.latitude;
      _selectedLongitude = p.longitude;
      _consultationDuration = p.consultationDurationMinutes;
      _maxAppointmentsPerSlot = p.maxAppointmentsPerSlot;
      _cancellationLimitHours = p.cancellationLimitHours;
    } else {
      _selectedSpecialties.add('Clínica Geral');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _crmvNumberController.dispose();
    _crmvUfController.dispose();
    _clinicNameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _numberController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<Map<String, double>?> _geocodeAddress(String address) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(address)}&format=json&limit=1',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'patas.online.app',
      });
      if (response.statusCode == 200) {
        final list = json.decode(response.body) as List;
        if (list.isNotEmpty) {
          final first = list.first;
          final lat = double.tryParse(first['lat'].toString());
          final lon = double.tryParse(first['lon'].toString());
          if (lat != null && lon != null) {
            return {'latitude': lat, 'longitude': lon};
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao geocodificar endereço: $e');
    }
    return null;
  }

  Future<List<NominatimAddress>> _searchAddressNominatim(String query) async {
    if (query.trim().length < 3) return [];
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'patas.online.app',
      });
      if (response.statusCode == 200) {
        final list = json.decode(response.body) as List;
        return list.map((item) {
          return NominatimAddress(
            displayName: item['display_name'] ?? '',
            latitude: double.tryParse(item['lat'].toString()) ?? 0.0,
            longitude: double.tryParse(item['lon'].toString()) ?? 0.0,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Erro ao buscar sugestões de endereço: $e');
    }
    return [];
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    double? latitude = _selectedLatitude;
    double? longitude = _selectedLongitude;

    final addressText = _addressController.text.trim();
    if (addressText.isNotEmpty && (latitude == null || longitude == null)) {
      final coords = await _geocodeAddress(addressText);
      if (coords != null) {
        latitude = coords['latitude'];
        longitude = coords['longitude'];
      } else {
        if (mounted) {
          final proceed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Endereço não localizado', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
              content: const Text(
                'Não conseguimos localizar as coordenadas exatas deste endereço no mapa.\n\nDeseja salvar mesmo assim? (Seu perfil ficará indisponível na busca por mapa).',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Ajustar Endereço', style: TextStyle(color: AppColors.patasColor)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Salvar sem Pin', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          );

          if (proceed != true) {
            setState(() => _isSaving = false);
            return;
          }
        }
      }
    }

    final numberText = _numberController.text.trim();
    final fullAddress = numberText.isNotEmpty ? '$addressText, $numberText' : addressText;

    final price = double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0.0;

    final success = await _saudeService.createOrUpdateVetProfile(
      crmvNumber: _crmvNumberController.text.trim(),
      crmvUf: _crmvUfController.text.trim().toUpperCase(),
      clinicName: _clinicNameController.text.trim().isEmpty ? null : _clinicNameController.text.trim(),
      fullName: _nameController.text.trim(),
      type: _type,
      bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
      specialties: _selectedSpecialties,
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      address: fullAddress.isEmpty ? null : fullAddress,
      latitude: latitude,
      longitude: longitude,
      acceptsHomeVisit: _acceptsHomeVisit,
      acceptsClinicVisit: _acceptsClinicVisit,
      consultationPrice: price,
      consultationDurationMinutes: _consultationDuration,
      maxAppointmentsPerSlot: _maxAppointmentsPerSlot,
      cancellationLimitHours: _cancellationLimitHours,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil profissional salvo com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao salvar perfil profissional.'),
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
    final isDesktop = context.isDesktop;
    final scaffoldBg = isDark ? AppColors.bodygray : const Color(0xFFF5F7FA);

    Widget formContent = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tipo de Profissional / Estabelecimento
          Text(
            'Tipo de Perfil *',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.darkBG,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Veterinário', style: TextStyle(fontFamily: 'Fredoka', fontSize: 12, fontWeight: FontWeight.bold)),
                  selected: _type == 'veterinarian',
                  selectedColor: AppColors.patasColor,
                  labelStyle: TextStyle(color: _type == 'veterinarian' ? Colors.white : (isDark ? Colors.white70 : AppColors.darkBG)),
                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  onSelected: (val) {
                    if (val) setState(() => _type = 'veterinarian');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Clínica', style: TextStyle(fontFamily: 'Fredoka', fontSize: 12, fontWeight: FontWeight.bold)),
                  selected: _type == 'clinic',
                  selectedColor: AppColors.patasColor,
                  labelStyle: TextStyle(color: _type == 'clinic' ? Colors.white : (isDark ? Colors.white70 : AppColors.darkBG)),
                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  onSelected: (val) {
                    if (val) setState(() => _type = 'clinic');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Hospital 24h', style: TextStyle(fontFamily: 'Fredoka', fontSize: 12, fontWeight: FontWeight.bold)),
                  selected: _type == 'hospital_24h',
                  selectedColor: AppColors.patasColor,
                  labelStyle: TextStyle(color: _type == 'hospital_24h' ? Colors.white : (isDark ? Colors.white70 : AppColors.darkBG)),
                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  onSelected: (val) {
                    if (val) setState(() => _type = 'hospital_24h');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Nome Completo & Nome da Clínica
          if (isDesktop)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nameController,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Informe o nome profissional' : null,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
                    decoration: InputDecoration(
                      labelText: 'Nome Profissional Completo *',
                      hintText: 'Ex: Dr. Carlos Eduardo Silva',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _clinicNameController,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
                    decoration: InputDecoration(
                      labelText: 'Nome da Clínica / Consultório (Opcional)',
                      hintText: 'Ex: Clínica Veterinária São Francisco',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            )
          else ...[
            TextFormField(
              controller: _nameController,
              validator: (val) => val == null || val.trim().isEmpty ? 'Informe o nome profissional' : null,
              style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
              decoration: InputDecoration(
                labelText: 'Nome Profissional Completo *',
                hintText: 'Ex: Dr. Carlos Eduardo Silva',
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _clinicNameController,
              style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
              decoration: InputDecoration(
                labelText: 'Nome da Clínica / Consultório (Opcional)',
                hintText: 'Ex: Clínica Veterinária São Francisco',
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // CRMV Número, UF, Telefone, Preço
          if (isDesktop)
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _crmvNumberController,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Informe o número do CRMV' : null,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
                    decoration: InputDecoration(
                      labelText: 'Número do CRMV *',
                      hintText: 'Ex: 12345',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _crmvUfController,
                    validator: (val) => val == null || val.trim().isEmpty ? 'UF' : null,
                    maxLength: 2,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
                    decoration: InputDecoration(
                      labelText: 'UF *',
                      hintText: 'SP',
                      counterText: '',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: TextFormField(
                    controller: _phoneController,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
                    decoration: InputDecoration(
                      labelText: 'Telefone / WhatsApp',
                      hintText: '(11) 99999-9999',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _priceController,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Valor Consulta (R\$)',
                      hintText: '150.00',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            )
          else ...[
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _crmvNumberController,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Informe o número do CRMV' : null,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
                    decoration: InputDecoration(
                      labelText: 'Número do CRMV *',
                      hintText: 'Ex: 12345',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _crmvUfController,
                    validator: (val) => val == null || val.trim().isEmpty ? 'UF' : null,
                    maxLength: 2,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
                    decoration: InputDecoration(
                      labelText: 'UF *',
                      hintText: 'SP',
                      counterText: '',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
                    decoration: InputDecoration(
                      labelText: 'Telefone / WhatsApp',
                      hintText: '(11) 99999-9999',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Valor Consulta (R\$)',
                      hintText: '150.00',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),

          // Endereço + Número/Complemento
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildAddressAutocomplete(isDark, isDesktop),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _numberController,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
                    decoration: InputDecoration(
                      labelText: 'Número e Complemento (Opcional)',
                      hintText: 'Ex: 1000, Bloco B, Sala 4',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            )
          else ...[
            _buildAddressAutocomplete(isDark, isDesktop),
            const SizedBox(height: 16),
            TextFormField(
              controller: _numberController,
              style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
              decoration: InputDecoration(
                labelText: 'Número e Complemento (Opcional)',
                hintText: 'Ex: 1000, Bloco B, Sala 4',
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Mini Mapa Interativo
          Text(
            'Marcar Localização Exata no Mapa *',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.darkBG,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: isDesktop ? 260 : 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.patasColor.withValues(alpha: 0.3)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(_selectedLatitude ?? -23.5505, _selectedLongitude ?? -46.6333),
                  initialZoom: 15.0,
                  onTap: (tapPosition, point) {
                    setState(() {
                      _selectedLatitude = point.latitude;
                      _selectedLongitude = point.longitude;
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                    userAgentPackageName: 'patas.online.app',
                    tileProvider: CancellableNetworkTileProvider(),
                  ),
                  if (_selectedLatitude != null && _selectedLongitude != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(_selectedLatitude!, _selectedLongitude!),
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Toque no mapa para ajustar a posição do Pin se necessário (útil para evitar sobreposição na mesma rua).',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Bio
          TextFormField(
            controller: _bioController,
            maxLines: 3,
            style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
            decoration: InputDecoration(
              labelText: 'Bio / Apresentação Profissional',
              hintText: 'Resumo sobre sua formação, experiência e atendimento...',
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 20),

          // Especialidades
          Text(
            'Especialidades Médicas',
            style: TextStyle(fontFamily: 'Fredoka', fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.darkBG),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableSpecialties.map((s) {
              final isSelected = _selectedSpecialties.contains(s);
              return FilterChip(
                label: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                selected: isSelected,
                selectedColor: AppColors.patasColor,
                labelStyle: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.darkBG)),
                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedSpecialties.add(s);
                    } else {
                      _selectedSpecialties.remove(s);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Opções de Modalidade de Atendimento (Switches)
          if (isDesktop)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.patasColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SwitchListTile(
                      title: Text('Atende na Clínica', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.darkBG)),
                      subtitle: const Text('Consultas presenciais no seu espaço.', style: TextStyle(fontSize: 11)),
                      value: _acceptsClinicVisit,
                      activeThumbColor: AppColors.patasColor,
                      onChanged: (val) => setState(() => _acceptsClinicVisit = val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SwitchListTile(
                      title: Text('Atende a Domicílio', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.darkBG)),
                      subtitle: const Text('Consultas em domicílio.', style: TextStyle(fontSize: 11)),
                      value: _acceptsHomeVisit,
                      activeThumbColor: AppColors.patasColor,
                      onChanged: (val) => setState(() => _acceptsHomeVisit = val),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            SwitchListTile(
              title: Text('Atende na Clínica / Consultório', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.darkBG)),
              subtitle: const Text('Permite que tutores agendem consultas presenciais no seu espaço.'),
              value: _acceptsClinicVisit,
              activeThumbColor: AppColors.patasColor,
              onChanged: (val) => setState(() => _acceptsClinicVisit = val),
            ),
            SwitchListTile(
              title: Text('Atende a Domicílio', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.darkBG)),
              subtitle: const Text('Permite que tutores agendam consultas em domicílio.'),
              value: _acceptsHomeVisit,
              activeThumbColor: AppColors.patasColor,
              onChanged: (val) => setState(() => _acceptsHomeVisit = val),
            ),
          ],

          // Configuração da Agenda
          const Divider(height: 40),
          Text(
            'Configurações de Agendamento',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.darkBG,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _consultationDuration,
                  dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Tempo Médio Consulta',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 30, child: Text('30 minutos')),
                    DropdownMenuItem(value: 45, child: Text('45 minutos')),
                    DropdownMenuItem(value: 60, child: Text('60 minutos (1h)')),
                    DropdownMenuItem(value: 90, child: Text('90 minutos (1h30)')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _consultationDuration = val);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _maxAppointmentsPerSlot,
                  dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Capacidade por Horário',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  items: List.generate(10, (index) {
                    final val = index + 1;
                    return DropdownMenuItem(
                      value: val,
                      child: Text(val == 1 ? '1 pet por vez' : '$val pets por vez'),
                    );
                  }),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _maxAppointmentsPerSlot = val);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _cancellationLimitHours,
            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Antecedência Mínima para Cancelar / Reagendar',
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            items: const [
              DropdownMenuItem(value: 0, child: Text('Sem limite (a qualquer momento)')),
              DropdownMenuItem(value: 2, child: Text('2 horas antes')),
              DropdownMenuItem(value: 6, child: Text('6 horas antes')),
              DropdownMenuItem(value: 12, child: Text('12 horas antes')),
              DropdownMenuItem(value: 24, child: Text('24 horas antes (1 dia)')),
              DropdownMenuItem(value: 48, child: Text('48 horas antes (2 dias)')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _cancellationLimitHours = val);
              }
            },
          ),
          const SizedBox(height: 32),

          // Botão Salvar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _submitRegistration,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.patasColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Salvar Perfil Profissional',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );

    if (isDesktop) {
      formContent = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Card(
              elevation: 0,
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: formContent,
              ),
            ),
          ),
        ),
      );
    }

    final bodyContent = SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 20,
        vertical: 10,
      ).copyWith(bottom: 100),
      child: formContent,
    );

    if (!widget.showAppBar) {
      return bodyContent;
    }

    final mainScaffold = Scaffold(
      backgroundColor: scaffoldBg,
      appBar: PatasEssencialAppBar(
        title: widget.existingProfile != null ? 'Editar Perfil Profissional' : 'Cadastro Profissional CRMV',
        subtitle: 'Perfil público de atendimento veterinário e clínica',
      ),
      body: bodyContent,
    );

    return mainScaffold;
  }

  Widget _buildAddressAutocomplete(bool isDark, bool isDesktop) {
    return Autocomplete<NominatimAddress>(
      displayStringForOption: (option) => option.displayName,
      optionsBuilder: (textEditingValue) async {
        return await _searchAddressNominatim(textEditingValue.text);
      },
      onSelected: (selection) {
        setState(() {
          _selectedLatitude = selection.latitude;
          _selectedLongitude = selection.longitude;
          _addressController.text = selection.displayName;
        });
        _mapController.move(LatLng(selection.latitude, selection.longitude), 16.0);
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(16),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: Container(
              width: isDesktop ? 460 : MediaQuery.of(context).size.width - 40,
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 460),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text(
                        option.displayName,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        if (textEditingController.text.isEmpty && _addressController.text.isNotEmpty) {
          textEditingController.text = _addressController.text;
        }

        textEditingController.addListener(() {
          if (textEditingController.text != _addressController.text) {
            _addressController.text = textEditingController.text;
            _selectedLatitude = null;
            _selectedLongitude = null;
          }
        });

        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          onFieldSubmitted: (val) => onFieldSubmitted(),
          style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
          decoration: InputDecoration(
            labelText: 'Endereço Comercial *',
            hintText: 'Ex: Av. Paulista, 1000 - Bela Vista, São Paulo - SP',
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      },
    );
  }
}

class NominatimAddress {
  final String displayName;
  final double latitude;
  final double longitude;

  NominatimAddress({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });
}
