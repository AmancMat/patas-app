import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import '../models/shelter_animal_model.dart';
import '../models/temporary_home_model.dart';
import '../services/shelter_service.dart';

class AssignPetToHomeSheet extends StatefulWidget {
  final TemporaryHome home;
  final String ongId;

  const AssignPetToHomeSheet({
    super.key,
    required this.home,
    required this.ongId,
  });

  static Future<bool?> show(
    BuildContext context, {
    required TemporaryHome home,
    required String ongId,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AssignPetToHomeSheet(
        home: home,
        ongId: ongId,
      ),
    );
  }

  @override
  State<AssignPetToHomeSheet> createState() => _AssignPetToHomeSheetState();
}

class _AssignPetToHomeSheetState extends State<AssignPetToHomeSheet> {
  final ShelterService _service = ShelterService();

  bool _isLoading = true;
  bool _isSubmitting = false;
  List<ShelterAnimal> _availableAnimals = [];
  String? _selectedAnimalId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAvailableAnimals();
  }

  Future<void> _loadAvailableAnimals() async {
    setState(() => _isLoading = true);
    try {
      final animals = await _service.getShelterAnimals(widget.ongId);
      final available = animals.where((a) {
        final status = a.status.toLowerCase();
        final isAvailable = status == 'disponivel' ||
            status == 'quarentena' ||
            status == 'tratamento';
        final notInHome = a.temporaryHomeId == null || a.temporaryHomeId!.isEmpty;
        return isAvailable && notInHome;
      }).toList();

      if (mounted) {
        setState(() {
          _availableAnimals = available;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitAssignment() async {
    if (_selectedAnimalId == null) return;

    setState(() => _isSubmitting = true);
    final success = await _service.assignAnimalToTemporaryHome(
      animalId: _selectedAnimalId!,
      homeId: widget.home.id,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pet acolhido no lar de ${widget.home.name} com sucesso! 🏡',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erro ao vincular pet ao lar temporário.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade300;

    final filtered = _availableAnimals.where((a) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return a.name.toLowerCase().contains(q) ||
          a.species.toLowerCase().contains(q) ||
          a.breed.toLowerCase().contains(q);
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        maxWidth: 580,
      ),
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: borderColor),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          brightness: isDark ? Brightness.dark : Brightness.light,
          textTheme: Theme.of(context).textTheme.apply(
            bodyColor: isDark ? Colors.white : AppColors.darkBG,
            displayColor: isDark ? Colors.white : AppColors.darkBG,
          ),
          unselectedWidgetColor: isDark ? Colors.white60 : Colors.black54,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.home_work_rounded,
                      color: Colors.blueAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hospedar Pet no Lar',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.darkBG,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Voluntário: ${widget.home.name} (${widget.home.freeSpots} vagas restantes)',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),

            // Campo de busca
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: TextStyle(
                  fontSize: 13.5,
                  color: isDark ? Colors.white : AppColors.darkBG,
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar por nome, espécie ou raça...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white12 : Colors.grey.shade300,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white12 : Colors.grey.shade300,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Colors.blueAccent,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            // Lista de animais disponíveis
            Flexible(
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : filtered.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.pets_outlined,
                                  size: 48,
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.black26,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _availableAnimals.isEmpty
                                      ? 'Nenhum animal disponível no abrigo para encaminhamento no momento.'
                                      : 'Nenhum pet encontrado com os termos pesquisados.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final animal = filtered[index];
                            final isSelected =
                                _selectedAnimalId == animal.id;

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedAnimalId =
                                      isSelected ? null : animal.id;
                                });
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.patasColor
                                          .withValues(alpha: 0.15)
                                      : (isDark
                                          ? const Color(0xFF0F172A)
                                          : const Color(0xFFF8FAFC)),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.patasColor
                                        : borderColor,
                                    width: isSelected ? 1.8 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Foto do Pet
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: animal.photoUrl != null &&
                                              animal.photoUrl!.isNotEmpty
                                          ? Image.network(
                                              animal.photoUrl!,
                                              width: 52,
                                              height: 52,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  _buildPetPlaceholder(
                                                      animal, isDark),
                                            )
                                          : _buildPetPlaceholder(
                                              animal, isDark),
                                    ),
                                    const SizedBox(width: 14),

                                    // Dados do pet
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            animal.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: isDark
                                                  ? Colors.white
                                                  : AppColors.darkBG,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${animal.species.toUpperCase()} • ${animal.breed.isNotEmpty ? animal.breed : 'SRD'} • ${animal.size.toUpperCase()}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.white60
                                                  : Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Radio / Indicador de seleção
                                    Icon(
                                      isSelected
                                          ? Icons.check_circle_rounded
                                          : Icons
                                              .radio_button_unchecked_rounded,
                                      color: isSelected
                                          ? AppColors.patasColor
                                          : (isDark
                                              ? Colors.white38
                                              : Colors.black26),
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),

            const Divider(height: 1),

            // Botão de confirmação
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: (_selectedAnimalId == null || _isSubmitting)
                      ? null
                      : _submitAssignment,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded, color: Colors.white),
                  label: Text(
                    _isSubmitting
                        ? 'Hospedando...'
                        : 'Confirmar Hospedagem no Lar',
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.patasColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetPlaceholder(ShelterAnimal animal, bool isDark) {
    return Container(
      width: 52,
      height: 52,
      color: Colors.blueAccent.withValues(alpha: 0.15),
      child: Center(
        child: Icon(
          animal.species.toLowerCase() == 'felino'
              ? Icons.cruelty_free_rounded
              : Icons.pets_rounded,
          color: Colors.blueAccent,
          size: 26,
        ),
      ),
    );
  }
}
