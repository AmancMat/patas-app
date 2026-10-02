import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import '../models/shelter_animal_model.dart';
import '../models/shelter_medical_record_model.dart';
import '../services/shelter_service.dart';

class AnimalMedicalHistorySheet extends StatefulWidget {
  final ShelterAnimal animal;
  final String ongId;
  final VoidCallback onUpdated;

  const AnimalMedicalHistorySheet({
    super.key,
    required this.animal,
    required this.ongId,
    required this.onUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required ShelterAnimal animal,
    required String ongId,
    required VoidCallback onUpdated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AnimalMedicalHistorySheet(
        animal: animal,
        ongId: ongId,
        onUpdated: onUpdated,
      ),
    );
  }

  @override
  State<AnimalMedicalHistorySheet> createState() =>
      _AnimalMedicalHistorySheetState();
}

class _AnimalMedicalHistorySheetState extends State<AnimalMedicalHistorySheet> {
  final ShelterService _service = ShelterService();
  List<ShelterMedicalRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    final list = await _service.getMedicalRecords(
      widget.ongId,
      animalId: widget.animal.id,
    );
    if (mounted) {
      setState(() {
        _records = list;
        _isLoading = false;
      });
    }
  }

  void _openAddRecordDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => _AddRecordDialog(
        animal: widget.animal,
        ongId: widget.ongId,
        onSaved: () {
          _loadRecords();
          widget.onUpdated();
        },
        isDark: isDark,
      ),
    );
  }

  Future<void> _confirmDelete(ShelterMedicalRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Registro?'),
        content: Text('Deseja remover o procedimento "${record.title}" do prontuário?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _service.deleteMedicalRecord(record.id);
      if (success) {
        _loadRecords();
        widget.onUpdated();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
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

          // Cabeçalho do Acolhido
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 56,
                    height: 56,
                    color: Colors.teal.withValues(alpha: 0.15),
                    child: widget.animal.photoUrl != null &&
                            widget.animal.photoUrl!.isNotEmpty
                        ? Image.network(widget.animal.photoUrl!,
                            fit: BoxFit.cover)
                        : Icon(
                            widget.animal.species == 'felino'
                                ? Icons.pets_rounded
                                : Icons.pets,
                            color: Colors.teal,
                            size: 28,
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.animal.name,
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.darkBG,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${widget.animal.species == 'felino' ? 'Gato(a)' : 'Cão'} · ${widget.animal.breed}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Badges de Saúde
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildMiniBadge(
                            label: widget.animal.isCastrated
                                ? 'Castrado'
                                : 'Não Castrado',
                            isOk: widget.animal.isCastrated,
                            isDark: isDark,
                          ),
                          _buildMiniBadge(
                            label: widget.animal.isVaccinated
                                ? 'Vacinas OK'
                                : 'Vacina Pendente',
                            isOk: widget.animal.isVaccinated,
                            isDark: isDark,
                          ),
                          _buildMiniBadge(
                            label: widget.animal.isDewormed
                                ? 'Vermifugado'
                                : 'Vermífugo Pendente',
                            isOk: widget.animal.isDewormed,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Barra de Título da Linha do Tempo e Botão "+ Procedimento"
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history_edu_rounded,
                        color: Colors.teal, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Histórico Clínico',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.darkBG,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _openAddRecordDialog(isDark),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Novo Procedimento',
                      style: TextStyle(fontFamily: 'Fredoka', fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),

          // Conteúdo da Linha do Tempo
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.teal))
                : _records.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.assignment_turned_in_outlined,
                                  size: 48,
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text(
                                'Nenhum procedimento registrado ainda.',
                                style: TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Cadastre vacinas, vermífugos, exames ou anotações clínicas deste animal.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        itemCount: _records.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final r = _records[index];
                          return _buildTimelineItem(r, isDark);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge({
    required String label,
    required bool isOk,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isOk
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOk ? Icons.check_circle_rounded : Icons.pending_rounded,
            size: 11,
            color: isOk ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isOk ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(ShelterMedicalRecord record, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: record.typeColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(record.typeIcon, color: record.typeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        record.title,
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.darkBG,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 18, color: Colors.redAccent),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Remover',
                      onPressed: () => _confirmDelete(record),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Aplicado em: ${record.formattedAppliedDate}${record.veterinarianName != null ? ' · Por: ${record.veterinarianName}' : ''}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
                if (record.nextDueDate != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Próxima dose: ${record.formattedNextDueDate}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                ],
                if (record.description != null &&
                    record.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    record.description!,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddRecordDialog extends StatefulWidget {
  final ShelterAnimal animal;
  final String ongId;
  final VoidCallback onSaved;
  final bool isDark;

  const _AddRecordDialog({
    required this.animal,
    required this.ongId,
    required this.onSaved,
    required this.isDark,
  });

  @override
  State<_AddRecordDialog> createState() => _AddRecordDialogState();
}

class _AddRecordDialogState extends State<_AddRecordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _vetController = TextEditingController();

  String _recordType = 'vacina';
  DateTime _appliedAt = DateTime.now();
  DateTime? _nextDueDate;
  bool _isSaving = false;

  final Map<String, String> _typePresets = {
    'vacina': 'Vacina V10 Polivalente',
    'vermifugo': 'Vermífugo Drontal Plus',
    'castracao': 'Castração Cirúrgica Realizada',
    'tratamento': 'Tratamento Tópico / Antibiótico',
    'exame': 'Exame Laboratorial de Sangue',
    'anotacao': 'Avaliação Clínica de Rotina',
  };

  @override
  void initState() {
    super.initState();
    _titleController.text = _typePresets[_recordType] ?? '';
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
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final record = ShelterMedicalRecord(
      id: '',
      ongId: widget.ongId,
      animalId: widget.animal.id,
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
      createdAt: DateTime.now(),
    );

    final result = await ShelterService().createMedicalRecord(record);
    if (mounted) {
      setState(() => _isSaving = false);
      if (result != null) {
        widget.onSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Procedimento registrado com sucesso!'),
            backgroundColor: Colors.teal,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao salvar procedimento. Tente novamente.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor:
          widget.isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.medical_services_rounded,
                            color: Colors.teal, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Novo Procedimento',
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: widget.isDark
                                    ? Colors.white
                                    : AppColors.darkBG,
                              ),
                            ),
                            Text(
                              'Animal: ${widget.animal.name}',
                              style: TextStyle(
                                fontSize: 11,
                                color: widget.isDark
                                    ? Colors.white60
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Tipo de Procedimento
                  DropdownButtonFormField<String>(
                    initialValue: _recordType,
                    dropdownColor: widget.isDark
                        ? const Color(0xFF0F172A)
                        : Colors.white,
                    decoration: InputDecoration(
                      labelText: 'Tipo de Procedimento',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                      prefixIcon: const Icon(Icons.category_rounded, size: 20),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'vacina', child: Text('Vacina')),
                      DropdownMenuItem(
                          value: 'vermifugo', child: Text('Vermífugo / Antipulgas')),
                      DropdownMenuItem(
                          value: 'castracao', child: Text('Castração Cirúrgica')),
                      DropdownMenuItem(
                          value: 'tratamento', child: Text('Tratamento / Medicação')),
                      DropdownMenuItem(
                          value: 'exame', child: Text('Exame Laboratorial')),
                      DropdownMenuItem(
                          value: 'anotacao', child: Text('Anotação Clínica')),
                    ],
                    onChanged: _onTypeChanged,
                  ),
                  const SizedBox(height: 14),

                  // Título / Nome da medicação
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Nome do Procedimento / Fármaco *',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                      prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Informe o nome do procedimento'
                        : null,
                  ),
                  const SizedBox(height: 14),

                  // Data de Aplicação
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Data da Aplicação',
                        style: TextStyle(fontSize: 12)),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy').format(_appliedAt),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.calendar_today_rounded, size: 20),
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

                  // Data da Próxima Dose
                  if (_recordType == 'vacina' || _recordType == 'vermifugo') ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Próxima Dose / Reforço',
                          style: TextStyle(fontSize: 12)),
                      subtitle: Text(
                        _nextDueDate != null
                            ? DateFormat('dd/MM/yyyy').format(_nextDueDate!)
                            : 'Nenhum agendamento',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _nextDueDate != null ? Colors.teal : Colors.grey,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_nextDueDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () =>
                                  setState(() => _nextDueDate = null),
                            ),
                          const Icon(Icons.event_repeat_rounded, size: 20),
                        ],
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _nextDueDate ??
                              _appliedAt.add(const Duration(days: 90)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 730)),
                        );
                        if (picked != null) {
                          setState(() => _nextDueDate = picked);
                        }
                      },
                    ),
                  ],

                  // Veterinário / Voluntário
                  TextFormField(
                    controller: _vetController,
                    decoration: InputDecoration(
                      labelText: 'Responsável / Veterinário (Opcional)',
                      hintText: 'Ex: Dra. Juliana (CRMV/SP 12345)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Observações
                  TextFormField(
                    controller: _descController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Observações / Lote / Dosagem',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                      prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Ações
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSaving ? null : () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Salvar no Prontuário',
                                style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
