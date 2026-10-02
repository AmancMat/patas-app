import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/features/pets/models/pet_model.dart';
import 'package:patas_web_app/src/features/pets/active_pet_provider.dart';
import 'package:patas_web_app/src/features/pets/services/pet_service.dart';
import 'package:patas_web_app/src/common_widgets/patas_button.dart';
import '../services/patas_saude_service.dart';

class PetWeightChartWidget extends StatefulWidget {
  final Pet activePet;
  const PetWeightChartWidget({super.key, required this.activePet});

  @override
  State<PetWeightChartWidget> createState() => _PetWeightChartWidgetState();
}

class _PetWeightChartWidgetState extends State<PetWeightChartWidget> {
  final PatasSaudeService _saudeService = PatasSaudeService();
  List<Map<String, dynamic>> _weightHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeightHistory();
  }

  @override
  void didUpdateWidget(covariant PetWeightChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activePet.id != widget.activePet.id || oldWidget.activePet.weight != widget.activePet.weight) {
      _loadWeightHistory();
    }
  }

  Future<void> _loadWeightHistory() async {
    setState(() => _isLoading = true);
    final petId = widget.activePet.id;
    final prefs = await SharedPreferences.getInstance();
    final records = await _saudeService.getPetMedicalRecords(petId);
    
    List<Map<String, dynamic>> history = [];

    // 1. Adiciona registros de consultas veterinárias (Supabase)
    for (var r in records) {
      if (r.weight != null && r.weight! > 0) {
        history.add({
          'weight': r.weight!,
          'date': r.createdAt,
          'source': 'Consulta',
        });
      }
    }

    // 2. Carrega histórico de pesagens salvas localmente pelo tutor
    final historyJsonStr = prefs.getString('pet_weight_history_$petId');
    if (historyJsonStr != null && historyJsonStr.isNotEmpty) {
      try {
        final List decoded = jsonDecode(historyJsonStr);
        for (var item in decoded) {
          if (item is Map) {
            final w = (item['weight'] as num?)?.toDouble();
            final dStr = item['date'] as String?;
            if (w != null && w > 0 && dStr != null) {
              history.add({
                'weight': w,
                'date': DateTime.parse(dStr),
                'source': 'Tutor',
              });
            }
          }
        }
      } catch (e) {
        debugPrint('Erro ao decodificar histórico local de peso: $e');
      }
    }

    // 3. Se não houver histórico anterior registrado e o pet já tiver um peso cadastrado no perfil
    if (history.isEmpty && widget.activePet.weight != null && widget.activePet.weight! > 0) {
      history.add({
        'weight': widget.activePet.weight!,
        'date': widget.activePet.createdAt,
        'source': 'Perfil',
      });
    }

    history.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    if (mounted) {
      setState(() {
        _weightHistory = history;
        _isLoading = false;
      });
    }
  }

  void _showUpdateWeightDialog() {
    final controller = TextEditingController(
      text: widget.activePet.weight != null ? widget.activePet.weight.toString() : '',
    );
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final thmode = Provider.of<DarkMode>(context);
        final isDark = thmode.darkMode;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final mq = MediaQuery.of(context);
            return Padding(
              padding: EdgeInsets.only(
                bottom: mq.viewInsets.bottom + mq.viewPadding.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Atualizar Peso de ${widget.activePet.name}',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.darkBG,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                      style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
                      decoration: InputDecoration(
                        labelText: 'Novo Peso (kg)',
                        hintText: 'Ex: 12.5',
                        prefixIcon: const Icon(Icons.monitor_weight_rounded, color: Colors.blue),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: PatasButton(
                        text: isSaving ? 'Salvando...' : 'Salvar Novo Peso',
                        onPressed: isSaving
                            ? null
                            : () async {
                                final text = controller.text.replaceAll(',', '.').trim();
                                final weightVal = double.tryParse(text);
                                if (weightVal == null || weightVal <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Por favor, informe um peso válido.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() => isSaving = true);

                                try {
                                  final updatedPet = Pet(
                                    id: widget.activePet.id,
                                    userId: widget.activePet.userId,
                                    name: widget.activePet.name,
                                    species: widget.activePet.species,
                                    breed: widget.activePet.breed,
                                    birthDate: widget.activePet.birthDate,
                                    photoUrl: widget.activePet.photoUrl,
                                    createdAt: widget.activePet.createdAt,
                                    gender: widget.activePet.gender,
                                    size: widget.activePet.size,
                                    color: widget.activePet.color,
                                    birthPlace: widget.activePet.birthPlace,
                                    currentCity: widget.activePet.currentCity,
                                    coverUrl: widget.activePet.coverUrl,
                                    bloodType: widget.activePet.bloodType,
                                    weight: weightVal,
                                    isLoveActive: widget.activePet.isLoveActive,
                                  );

                                  // Grava a nova medição no histórico de pesagens do tutor
                                  final prefs = await SharedPreferences.getInstance();
                                  final petId = widget.activePet.id;
                                  final existingJson = prefs.getString('pet_weight_history_$petId');
                                  List list = [];
                                  if (existingJson != null && existingJson.isNotEmpty) {
                                    try {
                                      list = jsonDecode(existingJson);
                                    } catch (_) {}
                                  }

                                  // Se já houver um peso anterior no perfil que ainda não estava no histórico, salva ele primeiro como marco inicial
                                  if (list.isEmpty && widget.activePet.weight != null && widget.activePet.weight! > 0) {
                                    list.add({
                                      'weight': widget.activePet.weight!,
                                      'date': widget.activePet.createdAt.toIso8601String(),
                                    });
                                  }

                                  list.add({
                                    'weight': weightVal,
                                    'date': DateTime.now().toIso8601String(),
                                  });
                                  await prefs.setString('pet_weight_history_$petId', jsonEncode(list));

                                  await PetService().updatePet(updatedPet);

                                  if (context.mounted) {
                                    Provider.of<ActivePetProvider>(context, listen: false)
                                        .updateActivePet(updatedPet);
                                  }

                                  await _loadWeightHistory();

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Peso de ${widget.activePet.name} atualizado para ${weightVal.toStringAsFixed(1)} kg! ⚖️'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setModalState(() => isSaving = false);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Erro ao atualizar peso: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    final currentWeight = widget.activePet.weight ??
        (_weightHistory.isNotEmpty ? _weightHistory.last['weight'] as double : 0.0);

    double diff = 0.0;
    if (_weightHistory.length >= 2) {
      final last = _weightHistory.last['weight'] as double;
      final prev = _weightHistory[_weightHistory.length - 2]['weight'] as double;
      diff = last - prev;
    }

    final maxWeight = _weightHistory.fold<double>(
      currentWeight > 0 ? currentWeight : 1.0,
      (max, item) => (item['weight'] as double) > max ? (item['weight'] as double) : max,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBG : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.monitor_weight_rounded,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Evolução de Peso',
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.darkBG,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Histórico ponderal do pet',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black54,
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
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (currentWeight > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${currentWeight.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 19, color: Colors.blue),
                    onPressed: _showUpdateWeightDialog,
                    tooltip: 'Atualizar Peso do Pet',
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            )
          else if (_weightHistory.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.grey, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Nenhum registro de peso informado ainda. Toque no ícone de editar para cadastrar o peso atual.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // Status Trend Banner
            if (diff != 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      diff > 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      color: diff > 0 ? Colors.orange : Colors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Variação: ${diff > 0 ? "+" : ""}${diff.toStringAsFixed(1)} kg na última medição',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: diff > 0 ? Colors.orange : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

            // Bar Timeline Visualization
            Container(
              height: 115,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _weightHistory.take(6).map((item) {
                  final w = item['weight'] as double;
                  final date = item['date'] as DateTime;
                  final dateStr = DateFormat('dd/MM').format(date);
                  final ratio = maxWeight > 0 ? (w / maxWeight).clamp(0.2, 1.0) : 0.5;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${w.toStringAsFixed(1)} kg',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: 22,
                        height: 45 * ratio,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.blue.shade400,
                              Colors.blue.shade700,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
