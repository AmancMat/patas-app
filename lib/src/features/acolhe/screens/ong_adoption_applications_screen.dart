import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import '../models/adoption_application_model.dart';
import '../services/shelter_service.dart';

class OngAdoptionApplicationsScreen extends StatefulWidget {
  final String ongId;

  const OngAdoptionApplicationsScreen({super.key, required this.ongId});

  @override
  State<OngAdoptionApplicationsScreen> createState() =>
      _OngAdoptionApplicationsScreenState();
}

class _OngAdoptionApplicationsScreenState
    extends State<OngAdoptionApplicationsScreen> {
  final ShelterService _service = ShelterService();
  List<AdoptionApplication> _applications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);
    final results = await _service.getOngAdoptionApplications(widget.ongId);
    if (mounted) {
      setState(() {
        _applications = results;
        _isLoading = false;
      });
    }
  }

  void _openWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/55$cleanPhone?text=Olá! Somos da ONG e recebemos sua ficha de adoção no Patas.');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _updateStatus(AdoptionApplication app, String newStatus) async {
    final success = await _service.updateApplicationStatus(app.id, newStatus);
    if (success) {
      _loadApplications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
      appBar: const PatasEssencialAppBar(
        title: 'Fichas de Adoção',
        subtitle: 'Interessados em adotar os acolhidos',
        leadingIcon: Icon(
          Icons.assignment_ind_rounded,
          color: Colors.purpleAccent,
          size: 22,
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadApplications,
          color: Colors.purpleAccent,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.purpleAccent),
                )
              : _applications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inbox_rounded,
                            size: 64,
                            color: isDark ? Colors.white30 : Colors.black26,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Nenhuma ficha de adoção recebida ainda.',
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: 16,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _applications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final app = _applications[index];
                        return _ApplicationCard(
                          app: app,
                          isDark: isDark,
                          onWhatsApp: () => _openWhatsApp(app.applicantPhone),
                          onStatusChange: (status) => _updateStatus(app, status),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final AdoptionApplication app;
  final bool isDark;
  final VoidCallback onWhatsApp;
  final Function(String) onStatusChange;

  const _ApplicationCard({
    required this.app,
    required this.isDark,
    required this.onWhatsApp,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topo: Nome do Interessado + Pet
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.purpleAccent.withValues(alpha: 0.15),
                child: const Icon(Icons.person, color: Colors.purpleAccent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.applicantName,
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.darkBG,
                      ),
                    ),
                    Text(
                      'Interessado no pet: ${app.animal?.name ?? "Acolhido"}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.purpleAccent,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.tune_rounded, size: 20),
                onSelected: onStatusChange,
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: 'em_analise', child: Text('Em Análise')),
                  PopupMenuItem(value: 'entrevista', child: Text('Agendar Entrevista')),
                  PopupMenuItem(value: 'aprovado', child: Text('Aprovar Adoção 🎉')),
                  PopupMenuItem(value: 'recusado', child: Text('Recusar')),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Questionário Resumido
          Row(
            children: [
              _buildInfoPill('Moradia: ${app.housingType.toUpperCase()}', isDark),
              const SizedBox(width: 6),
              _buildInfoPill(app.hasYard ? 'Com Quintal' : 'Sem Quintal', isDark),
              const SizedBox(width: 6),
              _buildInfoPill(app.hasOtherPets ? 'Tem outros pets' : 'Primeiro pet', isDark),
            ],
          ),

          if (app.adoptionReason != null && app.adoptionReason!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '"${app.adoptionReason}"',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Rodapé com Telefone & WhatsApp
          Row(
            children: [
              Icon(Icons.phone_outlined, size: 14, color: isDark ? Colors.white60 : Colors.grey),
              const SizedBox(width: 4),
              Text(
                app.applicantPhone,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: onWhatsApp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.chat_rounded, size: 16),
                label: const Text(
                  'WhatsApp',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPill(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }
}
