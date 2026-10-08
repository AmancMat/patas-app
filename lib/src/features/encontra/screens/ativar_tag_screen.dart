import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:patas_web_app/src/common_widgets/mobile_scroll_padding.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/core/localization/localizations_ext.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/features/encontra/services/encontra_service.dart';
import 'package:patas_web_app/src/features/pets/active_pet_provider.dart';
import 'package:patas_web_app/src/features/pets/models/pet_model.dart';
import 'package:patas_web_app/src/features/pets/services/pet_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class AtivarTagScreen extends StatefulWidget {
  final Pet? lockedPet;
  const AtivarTagScreen({super.key, this.lockedPet});

  @override
  State<AtivarTagScreen> createState() => _AtivarTagScreenState();
}

class _AtivarTagScreenState extends State<AtivarTagScreen> {
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _encontraService = EncontraService();
  final _petService = PetService();
  final _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _isScanning = true;
  String? _scannedUuid;
  bool _isActivating = false;
  String? _errorMessage;

  List<Pet> _allPets = [];
  bool _isLoadingPets = false;

  // Tags disponíveis para simulação (não ativadas)
  List<Map<String, dynamic>> _availableTags = [];
  bool _isLoadingTags = false;

  @override
  void initState() {
    super.initState();
    if (widget.lockedPet != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Provider.of<ActivePetProvider>(context, listen: false).setActivePet(widget.lockedPet!);
        }
      });
    }
    _loadPets();
    _loadAvailableTags();
  }

  Future<void> _loadPets() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    setState(() => _isLoadingPets = true);
    try {
      final pets = await _petService.getPetsByUserId(user.id);
      if (mounted) setState(() => _allPets = pets);
    } catch (e) {
      debugPrint('AtivarTagScreen: Erro ao carregar pets: $e');
    } finally {
      if (mounted) setState(() => _isLoadingPets = false);
    }
  }

  Future<void> _loadAvailableTags() async {
    setState(() => _isLoadingTags = true);
    try {
      final tags = await _encontraService.getAvailableTags();
      if (mounted) setState(() => _availableTags = tags);
    } catch (e) {
      debugPrint('AtivarTagScreen: Erro ao carregar tags disponíveis: $e');
    } finally {
      if (mounted) setState(() => _isLoadingTags = false);
    }
  }

  void _handleBarcodeDetected(String rawValue) {
    debugPrint('Tag Detectada por câmera: $rawValue');
    String targetUuid = rawValue.trim();

    // Se for link do localizador do Patas Encontra, extrai o UUID (fim do path)
    if (targetUuid.contains('/encontra/t/')) {
      final parts = targetUuid.split('/encontra/t/');
      if (parts.length > 1) {
        targetUuid = parts[1]
            .split('?')
            .first; // Remove query params adicionais
      }
    }

    // Regex de UUID v4 ou similar (8-4-4-4-12 hex)
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );

    if (uuidRegex.hasMatch(targetUuid)) {
      _scannerController.stop();
      if (mounted) {
        setState(() {
          _isScanning = false;
          _scannedUuid = targetUuid;
          _errorMessage = null;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _errorMessage = context.tr('encontra.invalid_tag_code');
        });
      }
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
      appBar: PatasEssencialAppBar(
        title: context.tr('encontra.activate_title'),
        subtitle: context.tr('encontra.activate_subtitle'),
        showBackButton: true,
        leadingIcon: Icon(
          Icons.qr_code_scanner_rounded,
          color: AppColors.patasColor,
          size: 22,
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: context.isDesktop ? 24.0 : 16.0,
                vertical: 20.0,
              ),
              child: Form(
                key: _formKey,
                child: isDesktop
                    ? _buildDesktopLayout(isDark)
                    : _buildMobileLayout(isDark),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card do pet ativo sempre visível
        _buildActivePetCard(isDark),
        const SizedBox(height: 20),
        if (_isScanning) ...[
          _buildScannerTitle(isDark),
          const SizedBox(height: 24),
          _buildScannerWidget(isDark),
          const SizedBox(height: 24),
          _buildSimulateButton(),
        ] else ...[
          _buildScanSuccessCard(isDark),
          const SizedBox(height: 24),
          _buildPinInputSection(isDark),
          const SizedBox(height: 8),
          if (_errorMessage != null) _buildErrorBanner(),
          const SizedBox(height: 16),
          _buildConfirmButton(),
        ],
        if (!context.isDesktop) const MobileScrollPadding(),
      ],
    );
  }

  Widget _buildDesktopLayout(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Coluna da Esquerda: Escaneamento + Card do Pet
        Expanded(
          flex: 5,
          child: Column(
            children: [
              // Card do pet ativo no topo
              _buildActivePetCard(isDark),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.2 : 0.05,
                      ),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildScannerTitle(isDark),
                    const SizedBox(height: 32),
                    _buildScannerWidget(isDark),
                    if (_isScanning) ...[
                      const SizedBox(height: 32),
                      _buildSimulateButton(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 32),

        // Coluna da Direita: Instruções ou Entrada de PIN
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isScanning) ...[_buildInstructionsCard(isDark)],
              if (!_isScanning) ...[
                _buildScanSuccessCard(isDark),
                const SizedBox(height: 24),
                _buildPinInputSection(isDark),
                const SizedBox(height: 8),
                if (_errorMessage != null) _buildErrorBanner(),
                const SizedBox(height: 16),
                _buildConfirmButton(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScannerTitle(bool isDark) {
    return Column(
      children: [
        Text(
          _isScanning
              ? context.tr('encontra.scan_instruction_title')
              : context.tr('encontra.tag_identified_title'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _isScanning
              ? context.tr('encontra.scan_instruction_subtitle')
              : context.tr('encontra.tag_identified_subtitle'),
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildScannerWidget(bool isDark) {
    return Center(
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isScanning ? AppColors.patasColor : Colors.greenAccent,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_isScanning)
                MobileScanner(
                  controller: _scannerController,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      final String? rawValue = barcode.rawValue;
                      if (rawValue != null) {
                        _handleBarcodeDetected(rawValue);
                      }
                    }
                  },
                )
              else
                Icon(
                  Icons.qr_code_rounded,
                  color: Colors.greenAccent.withValues(alpha: 0.2),
                  size: 140,
                ),
              if (_isScanning) ...[
                // Moldura de foco
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.patasColor, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                Positioned(
                  top: 130,
                  child: Container(
                    width: 190,
                    height: 3,
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent,
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.greenAccent,
                  size: 64,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimulateButton() {
    return OutlinedButton.icon(
      onPressed: _showSimulationPicker,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.patasColor,
        side: const BorderSide(color: AppColors.patasColor),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: const Icon(Icons.flash_on),
      label: Text(context.tr('encontra.simulate_scan_btn')),
    );
  }

  Widget _buildScanSuccessCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('encontra.qr_scanned_success'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr('encontra.code_label', {'uuid': '$_scannedUuid'}),
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.redAccent),
            onPressed: () {
              _scannerController.start();
              setState(() {
                _isScanning = true;
                _scannedUuid = null;
                _pinController.clear();
                _errorMessage = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPinInputSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('encontra.enter_security_pin'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('encontra.pin_desc'),
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: TextStyle(
              letterSpacing: 8,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '000000',
              hintStyle: const TextStyle(
                letterSpacing: 8,
                color: Colors.black38,
              ),
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF111827)
                  : const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.patasColor,
                  width: 2,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return context.tr('encontra.pin_required');
              }
              if (value.length != 6) {
                return context.tr('encontra.pin_length_err');
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return ElevatedButton(
      onPressed: _isActivating ? null : _submitActivation,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.patasColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: _isActivating
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              context.tr('encontra.finish_activation_btn'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
    );
  }

  Widget _buildInstructionsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('encontra.step_instructions_title'),
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.patasColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildStepRow(
            isDark,
            stepNum: '1',
            title: context.tr('encontra.step1_title'),
            desc:
                context.tr('encontra.step1_desc'),
          ),
          const SizedBox(height: 16),
          _buildStepRow(
            isDark,
            stepNum: '2',
            title: context.tr('encontra.step2_title'),
            desc:
                context.tr('encontra.step2_desc'),
          ),
          const SizedBox(height: 16),
          _buildStepRow(
            isDark,
            stepNum: '3',
            title: context.tr('encontra.step3_title'),
            desc:
                context.tr('encontra.step3_desc'),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow(
    bool isDark, {
    required String stepNum,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: AppColors.patasColor.withValues(alpha: 0.12),
          radius: 14,
          child: Text(
            stepNum,
            style: const TextStyle(
              color: AppColors.patasColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white70 : AppColors.darkBG,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 12,
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

  Widget _buildActivePetCard(bool isDark) {
    return Consumer<ActivePetProvider>(
      builder: (context, provider, _) {
        final activePet = provider.activePet;

        if (activePet == null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('encontra.no_pet_selected_title'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        context.tr('encontra.no_pet_selected_desc'),
                        style: const TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.patasColor.withValues(alpha: 0.10),
                AppColors.patasColor.withValues(alpha: 0.04),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.patasColor.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              // Avatar do pet
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.patasColor.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child:
                      activePet.photoUrl != null &&
                          activePet.photoUrl!.isNotEmpty
                      ? Image.network(
                          activePet.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildPetAvatarFallback(activePet),
                        )
                      : _buildPetAvatarFallback(activePet),
                ),
              ),
              const SizedBox(width: 14),
              // Info do pet
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('encontra.tag_activating_for'),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activePet.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Fredoka',
                        color: isDark ? Colors.white : AppColors.darkBG,
                      ),
                    ),
                    if (activePet.species.isNotEmpty)
                      Text(
                        '${activePet.species}${activePet.breed != null ? ' · ${activePet.breed}' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Botão Alterar (ocultado se viermos travados com um pet específico)
              if (widget.lockedPet == null)
                TextButton.icon(
                  onPressed: () => _showPetSelectionSheet(isDark),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: Text(context.tr('encontra.change_pet_btn')),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.patasColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: AppColors.patasColor.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPetAvatarFallback(Pet pet) {
    return Container(
      color: AppColors.patasColor.withValues(alpha: 0.12),
      child: Center(
        child: Text(
          pet.name.isNotEmpty ? pet.name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.patasColor,
          ),
        ),
      ),
    );
  }

  void _showPetSelectionSheet(bool isDark) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    if (isDesktop) {
      _showPetSelectionDialog(isDark);
    } else {
      _showPetSelectionBottomSheet(isDark);
    }
  }

  void _showPetSelectionDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        child: _buildPetSelectionContent(isDark, ctx),
      ),
    );
  }

  void _showPetSelectionBottomSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: _buildPetSelectionContent(isDark, ctx),
      ),
    );
  }

  Widget _buildPetSelectionContent(bool isDark, BuildContext sheetContext) {
    return Consumer<ActivePetProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle visual (apenas no bottom sheet)
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('encontra.select_pet_title'),
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.patasColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('encontra.select_pet_subtitle'),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (_isLoadingPets)
                const Center(
                  child: CircularProgressIndicator(color: AppColors.patasColor),
                )
              else if (_allPets.isEmpty)
                Text(
                  context.tr('encontra.no_pets_found'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _allPets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final pet = _allPets[index];
                      final isActive = provider.activePet?.id == pet.id;
                      return InkWell(
                        onTap: () {
                          provider.setActivePet(pet);
                          Navigator.pop(sheetContext);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.patasColor.withValues(alpha: 0.10)
                                : (isDark
                                      ? const Color(0xFF111827)
                                      : const Color(0xFFF9FAFB)),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isActive
                                  ? AppColors.patasColor
                                  : (isDark
                                        ? Colors.white12
                                        : Colors.grey.shade200),
                              width: isActive ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: ClipOval(
                                  child:
                                      pet.photoUrl != null &&
                                          pet.photoUrl!.isNotEmpty
                                      ? Image.network(
                                          pet.photoUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _buildPetAvatarFallback(pet),
                                        )
                                      : _buildPetAvatarFallback(pet),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pet.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.darkBG,
                                      ),
                                    ),
                                    if (pet.species.isNotEmpty)
                                      Text(
                                        '${pet.species}${pet.breed != null ? ' · ${pet.breed}' : ''}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black45,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (isActive)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.patasColor,
                                  size: 22,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage ?? '',
              style: const TextStyle(fontSize: 13, color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showSimulationPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('encontra.simulate_dialog_title'),
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: AppColors.patasColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('encontra.simulate_dialog_subtitle'),
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _isLoadingTags
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                          color: AppColors.patasColor,
                        ),
                      ),
                    )
                  : _availableTags.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        context.tr('encontra.no_tags_available'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _availableTags.length,
                        itemBuilder: (ctx, i) {
                          final tag = _availableTags[i];
                          final seq = (i + 1).toString().padLeft(4, '0');
                          final uuid = tag['id'] as String? ?? '';
                          final pin = tag['pin_code']?.toString() ?? '—';
                          final shortUuid = uuid.length > 8
                              ? '${uuid.substring(0, 8)}...'
                              : uuid;
                          return InkWell(
                            onTap: () {
                              Navigator.pop(ctx);
                              setState(() {
                                _isScanning = false;
                                _scannedUuid = uuid;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF111827)
                                    : const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white12
                                      : Colors.grey.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      seq,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      shortUuid,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.patasColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      pin,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppColors.patasColor,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  context.tr('common_cancel'),
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitActivation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_scannedUuid == null) return;

    final activePetProvider = Provider.of<ActivePetProvider>(
      context,
      listen: false,
    );
    final activePet = activePetProvider.activePet;

    if (activePet == null) {
      setState(() {
        _errorMessage =
            'Nenhum pet selecionado. Selecione um pet antes de ativar a tag.';
      });
      return;
    }

    setState(() {
      _isActivating = true;
      _errorMessage = null;
    });

    final result = await _encontraService.activateTag(
      tagUuid: _scannedUuid!,
      pin: _pinController.text.trim(),
      petId: activePet.id,
    );

    if (!mounted) return;

    setState(() {
      _isActivating = false;
    });

    if (result['success'] == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.tr('encontra.activation_success_title'),
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            context.tr('encontra.activation_success_desc', {'name': activePet.name}),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                final navigator = Navigator.of(context);
                Navigator.of(dialogContext).pop(); // Fecha dialog usando o context do builder
                Future.delayed(const Duration(milliseconds: 250), () {
                  navigator.pop(); // Volta para o painel de forma segura
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.patasColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        _errorMessage = result['message'] as String?;
      });
    }
  }
}
