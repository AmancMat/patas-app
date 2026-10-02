import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import '../models/shelter_animal_model.dart';
import '../services/shelter_service.dart';

class BatchHealthActionSheet extends StatefulWidget {
  final String ongId;
  final List<ShelterAnimal> allAnimals;
  final VoidCallback onCompleted;

  const BatchHealthActionSheet({
    super.key,
    required this.ongId,
    required this.allAnimals,
    required this.onCompleted,
  });

  static Future<void> show(
    BuildContext context, {
    required String ongId,
    required List<ShelterAnimal> allAnimals,
    required VoidCallback onCompleted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BatchHealthActionSheet(
        ongId: ongId,
        allAnimals: allAnimals,
        onCompleted: onCompleted,
      ),
    );
  }

  @override
  State<BatchHealthActionSheet> createState() => _BatchHealthActionSheetState();
}

class _BatchHealthActionSheetState extends State<BatchHealthActionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _vetController = TextEditingController();

  String _recordType = 'vermifugo';
  DateTime _appliedAt = DateTime.now();
  DateTime? _nextDueDate;
  bool _isSaving = false;

  final Set<String> _selectedAnimalIds = {};
  String _searchQuery = '';

  final Map<String, String> _typePresets = {
    'vermifugo': 'Vermifugação Coletiva (Drontal / Simparic)',
    'vacina': 'Campanha de Vacinação V10 / Antirrábica',
    'castracao': 'Mutirão de Castração do Abrigo',
  };

  @override
  void initState() {
    super.initState();
    _titleController.text = _typePresets[_recordType] ?? '';
    _nextDueDate = _appliedAt.add(const Duration(days: 90));
    _autoSelectPendingAnimals();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _vetController.dispose();
    super.dispose();
  }

  void _onTypeChanged(String? val) {
    if (val != null) {
      setState(() {
        _recordType = val;
        _titleController.text = _typePresets[val] ?? '';
        if (val == 'vacina') {
          _nextDueDate = _appliedAt.add(const Duration(days: 365));
        } else if (val == 'vermifugo') {
          _nextDueDate = _appliedAt.add(const Duration(days: 90));
        } else {
          _nextDueDate = null;
        }
        _autoSelectPendingAnimals();
      });
    }
  }

  void _autoSelectPendingAnimals() {
    _selectedAnimalIds.clear();
    for (final a in widget.allAnimals) {
      if (_recordType == 'vacina' && !a.isVaccinated) {
        _selectedAnimalIds.add(a.id);
      } else if (_recordType == 'vermifugo' && !a.isDewormed) {
        _selectedAnimalIds.add(a.id);
      } else if (_recordType == 'castracao' && !a.isCastrated) {
        _selectedAnimalIds.add(a.id);
      }
    }
    // Se nenhum estiver pendente, seleciona todos por padrão
    if (_selectedAnimalIds.isEmpty) {
      _selectedAnimalIds.addAll(widget.allAnimals.map((a) => a.id));
    }
  }

  void _selectAll() {
    setState(() {
      _selectedAnimalIds.addAll(widget.allAnimals.map((a) => a.id));
    });
  }

  void _selectSpecies(String species) {
    setState(() {
      _selectedAnimalIds.clear();
      for (final a in widget.allAnimals) {
        if (a.species == species) {
          _selectedAnimalIds.add(a.id);
        }
      }
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedAnimalIds.clear();
    });
  }

  Future<void> _submitBatch() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAnimalIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione ao menos um animal para a ação em lote.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final success = await ShelterService().applyBatchHealthAction(
      ongId: widget.ongId,
      animalIds: _selectedAnimalIds.toList(),
      recordType: _recordType,
      title: _titleController.text.trim(),
      description: _descController.text.trim().isNotEmpty
          ? _descController.text.trim()
          : null,
      appliedAt: _appliedAt,
      nextDueDate: _nextDueDate,
      veterinarianName: _vetController.text.trim().isNotEmpty
          ? _vetController.text.trim()
          : null,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        widget.onCompleted();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ação em lote aplicada com sucesso para ${_selectedAnimalIds.length} animais! 🎉',
            ),
            backgroundColor: Colors.teal,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao aplicar ação em lote. Tente novamente.'),
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

    final filteredAnimals = widget.allAnimals.where((a) {
      if (_searchQuery.isEmpty) return true;
      return a.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a.breed.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Cabeçalho da Ação em Lote
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.flash_on_rounded,
                      color: Colors.orange, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ação Sanitária em Lote',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.darkBG,
                        ),
                      ),
                      Text(
                        'Aplique vacinas ou vermífugos para vários acolhidos de uma só vez.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // 1. Tipo de Procedimento
                  DropdownButtonFormField<String>(
                    initialValue: _recordType,
                    dropdownColor: isDark
                        ? const Color(0xFF0F172A)
                        : Colors.white,
                    decoration: InputDecoration(
                      labelText: 'Tipo de Campanha Coletiva',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                      prefixIcon: const Icon(Icons.category_rounded, size: 20),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'vermifugo',
                          child: Text('Vermifugação / Antipulgas Coletivo')),
                      DropdownMenuItem(
                          value: 'vacina',
                          child: Text('Vacinação em Lote (V10 / Antirrábica)')),
                      DropdownMenuItem(
                          value: 'castracao',
                          child: Text('Mutirão de Castração')),
                    ],
                    onChanged: _onTypeChanged,
                  ),
                  const SizedBox(height: 14),

                  // 2. Título da Campanha
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Nome da Ação / Medicamento *',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                      prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Informe o nome da ação'
                        : null,
                  ),
                  const SizedBox(height: 14),

                  // 3. Datas (Aplicação e Próxima Dose)
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Data da Ação',
                              style: TextStyle(fontSize: 11)),
                          subtitle: Text(
                            DateFormat('dd/MM/yyyy').format(_appliedAt),
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          trailing: const Icon(Icons.calendar_today_rounded,
                              size: 18),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _appliedAt,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 30)),
                            );
                            if (picked != null) {
                              setState(() => _appliedAt = picked);
                            }
                          },
                        ),
                      ),
                      if (_nextDueDate != null) ...[
                        const SizedBox(width: 14),
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Próximo Reforço',
                                style: TextStyle(fontSize: 11)),
                            subtitle: Text(
                              DateFormat('dd/MM/yyyy').format(_nextDueDate!),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            trailing: const Icon(Icons.event_repeat_rounded,
                                size: 18),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _nextDueDate!,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 730)),
                              );
                              if (picked != null) {
                                setState(() => _nextDueDate = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ],
                  ),

                  // 4. Veterinário Responsável
                  TextFormField(
                    controller: _vetController,
                    decoration: InputDecoration(
                      labelText: 'Responsável / Veterinário (Opcional)',
                      hintText: 'Ex: Dra. Camila CRMV/SP',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 5. Observações
                  TextFormField(
                    controller: _descController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Lote do Frasco / Observações Sanitárias',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                      prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 6. Seletor de Animais
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Acolhidos Selecionados (${_selectedAnimalIds.length}/${widget.allAnimals.length})',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.darkBG,
                        ),
                      ),
                      TextButton(
                        onPressed: _selectedAnimalIds.length ==
                                widget.allAnimals.length
                            ? _deselectAll
                            : _selectAll,
                        child: Text(
                          _selectedAnimalIds.length ==
                                  widget.allAnimals.length
                              ? 'Desmarcar Todos'
                              : 'Marcar Todos',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),

                  // Chips de Filtro Rápido de Seleção
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.pets, size: 14),
                        label: const Text('Só Cães',
                            style: TextStyle(fontSize: 11)),
                        onPressed: () => _selectSpecies('canino'),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.pets, size: 14),
                        label: const Text('Só Gatos',
                            style: TextStyle(fontSize: 11)),
                        onPressed: () => _selectSpecies('felino'),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.pending_actions_rounded,
                            size: 14, color: Colors.orange),
                        label: const Text('Só Pendentes',
                            style: TextStyle(fontSize: 11)),
                        onPressed: _autoSelectPendingAnimals,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Barra de Busca de Animais
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Buscar acolhido por nome ou raça...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white12 : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Lista de Animais com Checkbox
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                      ),
                    ),
                    child: filteredAnimals.isEmpty
                        ? const Center(
                            child: Text(
                              'Nenhum acolhido encontrado.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: filteredAnimals.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final animal = filteredAnimals[index];
                              final isSelected =
                                  _selectedAnimalIds.contains(animal.id);

                              return CheckboxListTile(
                                value: isSelected,
                                activeColor: Colors.teal,
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _selectedAnimalIds.add(animal.id);
                                    } else {
                                      _selectedAnimalIds.remove(animal.id);
                                    }
                                  });
                                },
                                title: Text(
                                  animal.name,
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.darkBG,
                                  ),
                                ),
                                subtitle: Text(
                                  '${animal.species == 'felino' ? 'Gato' : 'Cão'} · ${animal.breed}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                secondary: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    color: Colors.teal.withValues(alpha: 0.1),
                                    child: animal.photoUrl != null &&
                                            animal.photoUrl!.isNotEmpty
                                        ? Image.network(animal.photoUrl!,
                                            fit: BoxFit.cover)
                                        : const Icon(Icons.pets,
                                            size: 18, color: Colors.teal),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Botão de Disparo em Lote
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _submitBatch,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.done_all_rounded),
                    label: Text(
                      _isSaving
                          ? 'Aplicando em lote...'
                          : 'Confirmar Aplicação em Lote (${_selectedAnimalIds.length} pets)',
                      style: const TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
