import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/features/health/consultas/clinic_search_page.dart';
import 'package:patas_web_app/src/features/health/consultas/consultation_form_page.dart';
import 'package:patas_web_app/src/features/health/models/consultation_model.dart';
import 'package:patas_web_app/src/features/health/services/health_service.dart';
import 'package:patas_web_app/src/features/pets/active_pet_provider.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import '../../../../app.dart';

class ConsultationListPage extends StatefulWidget {
  const ConsultationListPage({super.key});

  @override
  State<ConsultationListPage> createState() => _ConsultationListPageState();
}

class _ConsultationListPageState extends State<ConsultationListPage> {
  final HealthService _healthService = HealthService();
  late Future<List<PetConsultation>> _consultationsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final activePet =
        Provider.of<ActivePetProvider>(context, listen: false).activePet;
    if (activePet != null) {
      _consultationsFuture = _healthService.getConsultations(activePet.id);
    } else {
      _consultationsFuture = Future.value([]);
    }
  }

  void _refresh() {
    setState(() {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final activePet = Provider.of<ActivePetProvider>(context).activePet;

    if (activePet == null) {
      return Scaffold(
        backgroundColor: thmode.darkMode ? AppColors.darkBG : Colors.white,
        appBar: AppBar(
          title:
              const Text('Consultas', style: TextStyle(fontFamily: 'Fredoka')),
          elevation: 0,
        ),
        body: const Center(child: Text('Selecione um pet na Home.')),
      );
    }

    return Scaffold(
      backgroundColor: thmode.darkMode ? AppColors.darkBG : Colors.white,
      appBar: PatasEssencialAppBar(
        title: 'Consultas de ${activePet.name}',
        subtitle: 'Histórico clínico e agendamentos',
        leadingIcon: const Icon(
          Icons.medical_services_rounded,
          color: AppColors.patasColor,
          size: 22,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.patasColor),
            tooltip: 'Buscar Clínicas',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ClinicSearchPage()),
              );

              if (result != null &&
                  result is Map<String, dynamic> &&
                  context.mounted) {
                final formResult = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConsultationFormPage(
                      clinicId: result['id'],
                      clinicName: result['name'],
                    ),
                  ),
                );
                if (formResult == true) _refresh();
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<PetConsultation>>(
        future: _consultationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final consultations = snapshot.data ?? [];
          if (consultations.isEmpty) {
            return Center(
              child: Text(
                'Nenhuma consulta registrada.',
                style: TextStyle(
                  color: thmode.darkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: consultations.length,
            itemBuilder: (context, index) {
              final consult = consultations[index];
              return _ConsultationCard(
                consult: consult,
                onCancel: _refresh,
              );
            },
          );
        },
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: context.isDesktop
              ? 20
              : (MediaQuery.paddingOf(context).bottom + 76),
        ),
        child: FloatingActionButton(
          heroTag: null,
          onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ClinicSearchPage()),
          );

          if (result != null &&
              result is Map<String, dynamic> &&
              context.mounted) {
            final formResult = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ConsultationFormPage(
                  clinicId: result['id'],
                  clinicName: result['name'],
                ),
              ),
            );
            if (formResult == true) _refresh();
          }
        },
          backgroundColor: AppColors.patasColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

class _ConsultationCard extends StatelessWidget {
  final PetConsultation consult;
  final VoidCallback onCancel;
  const _ConsultationCard({required this.consult, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: thmode.darkMode ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      DateFormat('dd/MM/yyyy').format(consult.date),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.patasColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('HH:mm').format(consult.date),
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            thmode.darkMode ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(consult.status)
                        .withAlpha(26), // 0.1 * 255 = 25.5 -> 26
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _getStatusColor(consult.status), width: 0.5),
                  ),
                  child: Text(
                    consult.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(consult.status),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: Colors.red),
                  onPressed: () => _showDeleteDialog(context),
                  tooltip: 'Excluir Consulta',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (consult.clinicName != null)
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        consult.clinicName!,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  )
                else
                  const Text(
                    'Profissional não definido',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic),
                  ),
                if (consult.weight != null)
                  Text(
                    '${consult.weight} kg',
                    style: TextStyle(
                      fontSize: 12,
                      color: thmode.darkMode ? Colors.white60 : Colors.black54,
                    ),
                  ),
              ],
            ),
            const Divider(),
            if (consult.symptoms != null && consult.symptoms!.isNotEmpty) ...[
              Text(
                'Queixa/Sintomas:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: thmode.darkMode ? Colors.white : Colors.black,
                ),
              ),
              Text(
                consult.symptoms!,
                style: TextStyle(
                  fontSize: 13,
                  color: thmode.darkMode ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (consult.diagnosis != null && consult.diagnosis!.isNotEmpty) ...[
              const Text(
                'Diagnóstico:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.blue,
                ),
              ),
              Text(
                consult.diagnosis!,
                style: TextStyle(
                  fontSize: 13,
                  color: thmode.darkMode ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
            if (consult.status.toLowerCase() == 'aguardando') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showCancelDialog(context),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('CANCELAR AGENDAMENTO',
                      style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Cancelamento'),
        content: const Text(
            'Deseja realmente cancelar esta solicitação de agendamento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('NÃO'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Forçamos a atualização e verificamos o retorno
                await HealthService().cancelConsultation(consult.id);
                onCancel(); // Chama o refresh da lista
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Agendamento cancelado com sucesso.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao cancelar: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('SIM, CANCELAR',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Consulta'),
        content: const Text(
            'Tem certeza que deseja remover este registro permanentemente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('VOLTAR'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await HealthService().deleteConsultation(consult.id);
                onCancel();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Registro excluído permanentemente.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao excluir: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('EXCLUIR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aguardando':
        return Colors.orange;
      case 'confirmada':
        return Colors.blue;
      case 'em_atendimento':
        return Colors.green;
      case 'concluida':
        return AppColors.patasColor;
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
