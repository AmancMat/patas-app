import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:patas_web_app/src/common_widgets/mobile_scroll_padding.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/features/health/models/exam_model.dart';
import 'package:patas_web_app/src/features/health/models/medical_record_model.dart';
import 'package:patas_web_app/src/features/health/services/health_service.dart';
import 'package:patas_web_app/src/features/health/services/patas_saude_service.dart';
import 'package:patas_web_app/src/features/pets/active_pet_provider.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:provider/provider.dart';
import '../../../../app.dart';

class ExamsListPage extends StatefulWidget {
  const ExamsListPage({super.key});

  @override
  State<ExamsListPage> createState() => _ExamsListPageState();
}

class _ExamsListPageState extends State<ExamsListPage>
    with SingleTickerProviderStateMixin {
  final HealthService _healthService = HealthService();
  final PatasSaudeService _saudeService = PatasSaudeService();

  late TabController _tabController;
  List<PetExam> _manualExams = [];
  List<ExamRequest> _vetExamRequests = [];
  bool _isLoading = true;
  String? _loadedPetId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final activePet = Provider.of<ActivePetProvider>(context).activePet;
    if (activePet != null && activePet.id != _loadedPetId) {
      _loadedPetId = activePet.id;
      _loadData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final activePet =
        Provider.of<ActivePetProvider>(context, listen: false).activePet;
    if (activePet == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _saudeService.getPetExamRequests(activePet.id),
        _healthService.getExams(activePet.id).catchError((_) => <PetExam>[]),
      ]);

      if (mounted) {
        setState(() {
          _vetExamRequests = results[0] as List<ExamRequest>;
          _manualExams = results[1] as List<PetExam>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar exames: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddExamDialog() {
    final activePet =
        Provider.of<ActivePetProvider>(context, listen: false).activePet;
    if (activePet == null) return;

    final nameController = TextEditingController();
    final observationsController = TextEditingController();
    String selectedType = 'Laboratorial / Sangue';
    DateTime selectedDate = DateTime.now();
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
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBG : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Registrar Exame / Laudo',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.darkBG,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Adicione um exame realizado para ${activePet.name}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Nome do Exame
                    TextField(
                      controller: nameController,
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Nome do Exame *',
                        hintText: 'Ex: Hemograma Completo, Ultrassom Abdominal',
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.03),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tipo de Exame
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      dropdownColor:
                          isDark ? const Color(0xFF2A2A3E) : Colors.white,
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Tipo / Categoria',
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.03),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Laboratorial / Sangue',
                          child: Text('Laboratorial / Sangue'),
                        ),
                        DropdownMenuItem(
                          value: 'Imagem (Raio-X / Ultrassom)',
                          child: Text('Imagem (Raio-X / Ultrassom)'),
                        ),
                        DropdownMenuItem(
                          value: 'Fezes / Urina',
                          child: Text('Fezes / Urina'),
                        ),
                        DropdownMenuItem(
                          value: 'Cardiológico / ECG',
                          child: Text('Cardiológico / ECG'),
                        ),
                        DropdownMenuItem(
                          value: 'Biópsia / Citologia',
                          child: Text('Biópsia / Citologia'),
                        ),
                        DropdownMenuItem(
                          value: 'Outros',
                          child: Text('Outros'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Data da Realização
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Data de Realização',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy').format(selectedDate),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.patasColor,
                          fontSize: 15,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_today_rounded,
                            color: AppColors.patasColor),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setModalState(() => selectedDate = picked);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Observações / Conclusão
                    TextField(
                      controller: observationsController,
                      maxLines: 3,
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Observações / Resultados / Laudo',
                        hintText:
                            'Ex: Taxas normais, leve alteração em leucócitos...',
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.03),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Botão Salvar
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.patasColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (nameController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Informe o nome do exame realizado.'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() => isSaving = true);

                                final newExam = PetExam(
                                  id: '',
                                  petId: activePet.id,
                                  userId: activePet.userId,
                                  date: selectedDate,
                                  type: selectedType,
                                  name: nameController.text.trim(),
                                  observations: observationsController.text
                                          .trim()
                                          .isEmpty
                                      ? null
                                      : observationsController.text.trim(),
                                );

                                try {
                                  await _healthService.addExam(newExam);
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Exame registrado com sucesso!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    _loadData();
                                  }
                                } catch (e) {
                                  setModalState(() => isSaving = false);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Erro ao registrar exame: $e'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Salvar Exame',
                                style: TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
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
    final activePet = Provider.of<ActivePetProvider>(context).activePet;

    final content = Scaffold(
      backgroundColor:
          isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
      appBar: PatasEssencialAppBar(
        title: activePet != null
            ? 'Exames de ${activePet.name}'
            : 'Exames & Laudos',
        subtitle: 'Histórico de exames laboratoriais e pedidos médicos',
        showBackButton: true,
        bottomHeight: 50.0,
        bottomWidget: Center(
          child: SizedBox(
            width: 450,
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFE8EDF2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.patasColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 13,
                ),
                labelColor: Colors.white,
                unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
                tabs: [
                  Tab(text: 'Pedidos Médicos (${_vetExamRequests.length})'),
                  Tab(text: 'Laudos & Histórico (${_manualExams.length})'),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: context.isDesktop
              ? 20
              : (MediaQuery.paddingOf(context).bottom + 76),
        ),
        child: FloatingActionButton.extended(
          heroTag: null,
          onPressed: _showAddExamDialog,
          backgroundColor: AppColors.patasColor,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Novo Exame',
            style: TextStyle(
              fontFamily: 'Fredoka',
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.patasColor),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildVetRequestsTab(isDark),
                _buildManualExamsTab(isDark),
              ],
            ),
    );

    return ResponsiveLayout(
      mobile: content,
      desktop: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: content,
        ),
      ),
    );
  }

  Widget _buildVetRequestsTab(bool isDark) {
    if (_vetExamRequests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_turned_in_rounded,
                size: 64,
                color: isDark ? Colors.white24 : Colors.black12,
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhum pedido de exame pendente',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : AppColors.darkBG,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Quando um médico veterinário solicitar exames durante uma consulta, eles aparecerão automaticamente aqui.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MobileScrollPadding.bottomInset(context),
      ),
      itemCount: _vetExamRequests.length + 1,
      itemBuilder: (context, index) {
        if (index == _vetExamRequests.length) {
          return const MobileScrollPadding();
        }
        final request = _vetExamRequests[index];
        final vetName = request.vet?.fullName ?? 'Médico Veterinário';
        final crmv = request.vet != null
            ? 'CRMV ${request.vet!.crmvUf} ${request.vet!.crmvNumber}'
            : '';

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBG : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.patasColor.withValues(alpha: 0.15),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.assignment_rounded,
                      color: Colors.indigo,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.examType,
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.darkBG,
                          ),
                        ),
                        Text(
                          'Solicitado por Dr(a). $vetName $crmv',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (request.status == 'completed'
                              ? Colors.green
                              : Colors.orange)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      request.status == 'completed'
                          ? 'Concluído'
                          : 'Solicitado',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: request.status == 'completed'
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              if (request.observations != null &&
                  request.observations!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Instruções: ${request.observations}',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(request.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildManualExamsTab(bool isDark) {
    if (_manualExams.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_open_rounded,
                size: 64,
                color: isDark ? Colors.white24 : Colors.black12,
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhum laudo registrado ainda',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : AppColors.darkBG,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Toque no botão "Novo Exame" abaixo para registrar hemogramas, raio-X ou ultrassons já realizados.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MobileScrollPadding.bottomInset(context),
      ),
      itemCount: _manualExams.length + 1,
      itemBuilder: (context, index) {
        if (index == _manualExams.length) {
          return const MobileScrollPadding();
        }
        final exam = _manualExams[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBG : Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.biotech_rounded,
                  color: Colors.teal,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.name,
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.darkBG,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      exam.type,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.patasColor,
                      ),
                    ),
                    if (exam.observations != null &&
                        exam.observations!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        exam.observations!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('dd/MM/yyyy').format(exam.date),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
