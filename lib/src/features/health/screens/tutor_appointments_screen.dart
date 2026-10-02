import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:intl/intl.dart';

import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/features/pets/active_pet_provider.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import '../models/appointment_model.dart';
import '../services/patas_saude_service.dart';
import 'book_appointment_screen.dart';

class TutorAppointmentsScreen extends StatefulWidget {
  const TutorAppointmentsScreen({super.key});

  @override
  State<TutorAppointmentsScreen> createState() => _TutorAppointmentsScreenState();
}

class _TutorAppointmentsScreenState extends State<TutorAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  final _saudeService = PatasSaudeService();
  List<HealthAppointment> _appointments = [];
  bool _isLoading = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    final activePet = Provider.of<ActivePetProvider>(context, listen: false).activePet;
    if (activePet == null) return;

    setState(() => _isLoading = true);
    final appts = await _saudeService.getTutorAppointments(activePet.id);
    if (mounted) {
      setState(() {
        _appointments = appts;
        _isLoading = false;
      });
    }
  }

  /// Ativos: futuro + status confirmado ou pendente
  List<HealthAppointment> get _activeAppointments {
    return _appointments.where((appt) {
      if (appt.status == 'cancelled' || appt.status == 'completed') return false;
      try {
        final dt = DateTime.parse('${appt.appointmentDate} ${appt.appointmentTime}');
        return dt.isAfter(DateTime.now());
      } catch (_) {
        return false;
      }
    }).toList();
  }

  /// Histórico: cancelados, concluídos, ou com data já passada
  List<HealthAppointment> get _historyAppointments {
    return _appointments.where((appt) {
      if (appt.status == 'cancelled' || appt.status == 'completed') return true;
      try {
        final dt = DateTime.parse('${appt.appointmentDate} ${appt.appointmentTime}');
        return !dt.isAfter(DateTime.now());
      } catch (_) {
        return true;
      }
    }).toList();
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Confirmada';
      case 'in_progress':
        return 'Em Atendimento';
      case 'completed':
        return 'Concluída';
      case 'cancelled':
        return 'Cancelada';
      default:
        return 'Pendente';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  void _showLimitDialog(int limitHours) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Prazo Limite Excedido',
          style: TextStyle(fontFamily: 'Fredoka', color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Não é possível cancelar ou reagendar esta consulta.\n\n'
          'Este profissional configurou um prazo limite de $limitHours horas de antecedência para alterações.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido',
                style: TextStyle(color: AppColors.patasColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCancel(HealthAppointment appt) async {
    final DateTime apptDt = DateTime.parse('${appt.appointmentDate} ${appt.appointmentTime}');
    final difference = apptDt.difference(DateTime.now());
    final limitHours = appt.vet?.cancellationLimitHours ?? 24;

    if (difference.inHours < limitHours) {
      _showLimitDialog(limitHours);
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final tabCtrl = _tabController;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Cancelar Consulta',
          style: TextStyle(fontFamily: 'Fredoka', color: AppColors.patasColor, fontWeight: FontWeight.bold),
        ),
        content: const Text('Deseja realmente cancelar esta consulta? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirmar Cancelamento', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await _saudeService.cancelAppointment(appt.id);
      if (mounted) {
        await _loadAppointments();
        if (success) {
          tabCtrl.animateTo(1);

          messenger.showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.transparent,
              elevation: 0,
              duration: const Duration(seconds: 3),
              content: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.history_rounded, size: 18, color: Colors.redAccent),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Consulta cancelada',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            'Movida para o Histórico automaticamente.',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Erro ao cancelar consulta.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleReschedule(HealthAppointment appt) async {
    if (appt.vet == null) return;

    final DateTime apptDt = DateTime.parse('${appt.appointmentDate} ${appt.appointmentTime}');
    final difference = apptDt.difference(DateTime.now());
    final limitHours = appt.vet!.cancellationLimitHours;

    if (difference.inHours < limitHours) {
      _showLimitDialog(limitHours);
      return;
    }

    final success = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookAppointmentScreen(
          vet: appt.vet!,
          rescheduleAppointmentId: appt.id,
        ),
      ),
    );

    if (success == true) {
      _loadAppointments();
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final isDesktop = context.isDesktop;
    final activePet = Provider.of<ActivePetProvider>(context).activePet;

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final scaffoldBg = isDark ? AppColors.bodygray : const Color(0xFFF5F7FA);

    Widget bodyContent = _isLoading
        ? const Center(child: CircularProgressIndicator(color: AppColors.patasColor))
        : TabBarView(
            controller: _tabController,
            children: [
              RefreshIndicator(
                color: AppColors.patasColor,
                onRefresh: _loadAppointments,
                child: _activeAppointments.isEmpty
                    ? _buildEmptyState(isHistory: false)
                    : _buildList(_activeAppointments, isDark, cardBg, isHistory: false),
              ),
              RefreshIndicator(
                color: AppColors.patasColor,
                onRefresh: _loadAppointments,
                child: _historyAppointments.isEmpty
                    ? _buildEmptyState(isHistory: true)
                    : _buildList(_historyAppointments, isDark, cardBg, isHistory: true),
              ),
            ],
          );

    if (isDesktop && !_isLoading) {
      bodyContent = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750),
          child: bodyContent,
        ),
      );
    }

    final mainContent = Scaffold(
      backgroundColor: scaffoldBg,
      appBar: PatasEssencialAppBar(
        title: 'Consultas & Agendamentos',
        subtitle: activePet != null ? 'Histórico do pet ${activePet.name}' : 'Agenda veterinária do pet',
        bottomHeight: 50.0,
        bottomWidget: Center(
          child: SizedBox(
            width: 450,
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE8EDF2),
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
                    fontFamily: 'Fredoka', fontSize: 13, fontWeight: FontWeight.bold),
                unselectedLabelStyle:
                    const TextStyle(fontFamily: 'Fredoka', fontSize: 13),
                labelColor: Colors.white,
                unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
                tabs: const [
                  Tab(text: 'Agendamentos Ativos'),
                  Tab(text: 'Histórico'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: bodyContent,
    );

    return mainContent;
  }

  Widget _buildEmptyState({required bool isHistory}) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.22),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isHistory ? Icons.history_rounded : Icons.calendar_month_rounded,
                size: 56,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                isHistory ? 'Nenhum histórico encontrado.' : 'Nenhuma consulta agendada ainda.',
                style: const TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  isHistory
                      ? 'Consultas concluídas ou canceladas aparecerão aqui.'
                      : 'Acesse o "Mapa de Vets" para buscar clínicas e agendar um atendimento para seu pet.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList(
    List<HealthAppointment> appts,
    bool isDark,
    Color cardBg, {
    required bool isHistory,
  }) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: appts.length,
      itemBuilder: (context, index) {
        final appt = appts[index];
        return _buildCard(appt, isDark, cardBg, isHistory: isHistory);
      },
    );
  }

  Widget _buildCard(
    HealthAppointment appt,
    bool isDark,
    Color cardBg, {
    required bool isHistory,
  }) {
    final vetName = appt.vet?.fullName ?? 'Veterinário';
    final vetPhoto = appt.vet?.photoUrl;
    final crmv = appt.vet != null ? 'CRMV ${appt.vet!.crmvUf} ${appt.vet!.crmvNumber}' : '';

    // Formata data para exibição mais amigável
    String dateLabel = '${appt.appointmentDate} às ${appt.appointmentTime}';
    try {
      final dt = DateTime.parse('${appt.appointmentDate} ${appt.appointmentTime}');
      dateLabel = '${DateFormat("dd 'de' MMMM 'de' yyyy", 'pt_BR').format(dt)} às ${appt.appointmentTime.substring(0, 5)}';
    } catch (_) {}

    return Opacity(
      opacity: isHistory ? 0.75 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        color: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isHistory
              ? BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 1)
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho: avatar + nome + badge de status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.patasColor.withValues(alpha: 0.2),
                        backgroundImage: (vetPhoto != null && vetPhoto.isNotEmpty)
                            ? NetworkImage(vetPhoto)
                            : null,
                        child: (vetPhoto == null || vetPhoto.isEmpty)
                            ? const Icon(Icons.medical_services_rounded, size: 20, color: AppColors.patasColor)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vetName,
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.darkBG,
                            ),
                          ),
                          if (crmv.isNotEmpty)
                            Text(crmv, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(appt.status).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusLabel(appt.status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(appt.status),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Data, hora e modalidade
              Row(
                children: [
                  Icon(Icons.event_rounded, size: 16, color: isHistory ? Colors.grey : AppColors.patasColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      dateLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : AppColors.darkBG,
                      ),
                    ),
                  ),
                  Icon(
                    appt.modality == 'home' ? Icons.home_work_rounded : Icons.medical_information_rounded,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    appt.modality == 'home' ? 'A Domicílio' : 'Na Clínica',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),

              if (appt.notes != null && appt.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Obs: ${appt.notes}',
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ],

              // Botões de ação — apenas na aba Ativos
              if (!isHistory)
                (() {
                  bool canModify = false;
                  try {
                    final DateTime apptDt =
                        DateTime.parse('${appt.appointmentDate} ${appt.appointmentTime}');
                    canModify = apptDt.isAfter(DateTime.now()) &&
                        (appt.status == 'confirmed' || appt.status == 'pending');
                  } catch (_) {}

                  if (!canModify) return const SizedBox.shrink();

                  return Column(
                    children: [
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.edit_calendar_rounded,
                                size: 16, color: AppColors.patasColor),
                            label: const Text(
                              'Reagendar',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.patasColor),
                            ),
                            onPressed: () => _handleReschedule(appt),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.cancel_outlined,
                                size: 16, color: Colors.redAccent),
                            label: const Text(
                              'Cancelar',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.redAccent),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _handleCancel(appt),
                          ),
                        ],
                      ),
                    ],
                  );
                })(),
            ],
          ),
        ),
      ),
    );
  }
}
