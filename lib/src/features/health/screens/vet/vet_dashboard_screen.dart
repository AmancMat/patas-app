import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';

import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import '../../models/vet_profile_model.dart';
import '../../models/appointment_model.dart';
import '../../models/vet_subscription_model.dart';
import '../../services/patas_saude_service.dart';
import '../../services/vet_subscription_service.dart';
import 'package:flutter_svg/svg.dart';
import 'package:patas_web_app/src/common_widgets/mobile_scroll_padding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:patas_web_app/src/external_services/secure_storage.dart';
import 'package:patas_web_app/src/constants/routes.dart';
import 'vet_registration_screen.dart';
import 'vet_consultation_screen.dart';
import 'vet_checkout_page.dart';
import 'vet_pix_payment_page.dart';

class VetDashboardScreen extends StatefulWidget {
  const VetDashboardScreen({super.key});

  @override
  State<VetDashboardScreen> createState() => _VetDashboardScreenState();
}

class _VetDashboardScreenState extends State<VetDashboardScreen>
    with SingleTickerProviderStateMixin {
  final _saudeService = PatasSaudeService();
  final _subscriptionService = VetSubscriptionService();

  VetProfile? _vetProfile;
  List<HealthAppointment> _appointments = [];
  VetSubscription? _subscription;
  List<VetInvoice> _invoices = [];
  bool _isLoading = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadVetData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadVetData() async {
    setState(() => _isLoading = true);
    final profile = await _saudeService.getVetProfileForCurrentUser();
    List<HealthAppointment> appts = [];
    VetSubscription? sub;
    List<VetInvoice> invs = [];

    if (profile != null) {
      appts = await _saudeService.getVetAppointments(profile.id);
      sub = await _subscriptionService.getSubscriptionForVet(profile.id);
      invs = await _subscriptionService.getInvoicesForVet(profile.id);
    }

    if (mounted) {
      setState(() {
        _vetProfile = profile;
        _appointments = appts;
        _subscription = sub;
        _invoices = invs;
        _isLoading = false;
      });
    }
  }

  /// Ativos: data futura E status não finalizado
  List<HealthAppointment> get _activeAppointments {
    return _appointments.where((appt) {
      if (appt.status == 'cancelled' || appt.status == 'completed')
        return false;
      try {
        final dt = DateTime.parse(
          '${appt.appointmentDate} ${appt.appointmentTime}',
        );
        return dt.isAfter(DateTime.now());
      } catch (_) {
        return false;
      }
    }).toList();
  }

  /// Histórico: cancelados, concluídos ou data já passou
  List<HealthAppointment> get _historyAppointments {
    return _appointments.where((appt) {
      if (appt.status == 'cancelled' || appt.status == 'completed') return true;
      try {
        final dt = DateTime.parse(
          '${appt.appointmentDate} ${appt.appointmentTime}',
        );
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

  Future<void> _handleCancelAppointment(HealthAppointment appt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Cancelar Consulta',
          style: TextStyle(
            fontFamily: 'Fredoka',
            color: AppColors.patasColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Deseja cancelar o atendimento de ${appt.petName ?? 'este paciente'}?\n\nO tutor será notificado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Confirmar Cancelamento',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final tabCtrl = _tabController;
      setState(() => _isLoading = true);
      final success = await _saudeService.cancelAppointment(appt.id);
      if (mounted) {
        await _loadVetData();
        if (success) {
          tabCtrl.animateTo(1);
          messenger.showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.transparent,
              elevation: 0,
              duration: const Duration(seconds: 3),
              content: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                      child: const Icon(
                        Icons.history_rounded,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Consulta cancelada',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Movida para o Histórico automaticamente.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
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

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Sair da Conta Profissional',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Deseja realmente encerrar a sessão do seu painel profissional?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Sair', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      } catch (_) {}

      try {
        await const SecureStorage().deleteAll();
      } catch (_) {}

      try {
        await Supabase.instance.client.auth.signOut(scope: SignOutScope.global);
      } catch (_) {}

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          NamedRoute.professionalLogin,
          (route) => false,
        );
      }
    }
  }

  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final isDesktop = context.isDesktop;
    final scaffoldBg = isDark ? AppColors.bodygray : const Color(0xFFF5F7FA);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.patasColor),
        ),
      );
    }

    if (_vetProfile == null) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        appBar: PatasEssencialAppBar(
          title: 'Painel Profissional',
          subtitle: 'Área do Veterinário e Clínica',
          showBackButton: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              tooltip: 'Sair da Conta',
              onPressed: _confirmLogout,
            ),
          ],
        ),
        body: _buildNoCadastro(isDark),
      );
    }

    // Conteúdo da aba selecionada
    Widget activeTabContent;
    switch (_selectedNavIndex) {
      case 1:
        activeTabContent = RefreshIndicator(
          color: AppColors.patasColor,
          onRefresh: _loadVetData,
          child: _historyAppointments.isEmpty
              ? _buildEmptyState(isHistory: true)
              : _buildList(_historyAppointments, isDark, isHistory: true),
        );
        break;
      case 2:
        activeTabContent = RefreshIndicator(
          color: AppColors.patasColor,
          onRefresh: _loadVetData,
          child: _buildEquipeTab(isDark),
        );
        break;
      case 3:
        activeTabContent = RefreshIndicator(
          color: AppColors.patasColor,
          onRefresh: _loadVetData,
          child: _buildFinancialTab(isDark),
        );
        break;
      case 4:
        activeTabContent = VetRegistrationScreen(
          existingProfile: _vetProfile,
          showAppBar: false,
        );
        break;
      case 0:
      default:
        activeTabContent = RefreshIndicator(
          color: AppColors.patasColor,
          onRefresh: _loadVetData,
          child: _activeAppointments.isEmpty
              ? _buildEmptyState(isHistory: false)
              : _buildList(_activeAppointments, isDark, isHistory: false),
        );
        break;
    }

    final mainTabBody = Column(
      children: [
        if (_selectedNavIndex != 4) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: _buildProfileBanner(isDark),
          ),
          const SizedBox(height: 12),
        ],
        Expanded(child: activeTabContent),
      ],
    );

    // Layout Desktop com Sidebar B2B dedicada à esquerda
    if (isDesktop) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        body: Row(
          children: [
            _buildDesktopSidebar(isDark),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: Colors.black12,
            ),
            Expanded(
              child: Scaffold(
                backgroundColor: scaffoldBg,
                appBar: PatasEssencialAppBar(
                  title: 'Painel Patas Vet',
                  subtitle: 'Dr(a). ${_vetProfile!.fullName}',
                  showBackButton: false,
                ),
                body: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: mainTabBody,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Layout Mobile com BottomNavigationBar unificada
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: PatasEssencialAppBar(
        title: 'Painel Patas Vet',
        subtitle: 'Dr(a). ${_vetProfile!.fullName}',
        showBackButton: false,
      ),
      body: mainTabBody,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex.clamp(0, 4),
        onTap: (index) {
          setState(() => _selectedNavIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        selectedItemColor: AppColors.patasColor,
        unselectedItemColor: isDark ? Colors.white54 : Colors.black54,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          fontFamily: 'Fredoka',
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontFamily: 'Fredoka',
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_rounded),
            activeIcon: Icon(
              Icons.calendar_month_rounded,
              color: AppColors.patasColor,
            ),
            label: 'Agendamentos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            activeIcon: Icon(
              Icons.history_rounded,
              color: AppColors.patasColor,
            ),
            label: 'Histórico',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_rounded),
            activeIcon: Icon(Icons.groups_rounded, color: AppColors.patasColor),
            label: 'Equipe',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_rounded),
            activeIcon: Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.patasColor,
            ),
            label: 'Financeiro',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            activeIcon: Icon(
              Icons.settings_rounded,
              color: AppColors.patasColor,
            ),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar(bool isDark) {
    return Container(
      width: 240,
      color: isDark ? const Color(0xFF0F172A) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset('assets/icons/patas.svg', height: 32, width: 32),
              const SizedBox(width: 10),
              const Text(
                'Patas Vet',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.patasColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_vetProfile != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.patasColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.patasColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.patasColor.withValues(
                      alpha: 0.2,
                    ),
                    backgroundImage:
                        _vetProfile!.photoUrl != null &&
                            _vetProfile!.photoUrl!.isNotEmpty
                        ? NetworkImage(_vetProfile!.photoUrl!)
                        : null,
                    child:
                        _vetProfile!.photoUrl == null ||
                            _vetProfile!.photoUrl!.isEmpty
                        ? const Icon(
                            Icons.medical_services,
                            color: AppColors.patasColor,
                            size: 20,
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _vetProfile!.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDark ? Colors.white : AppColors.darkBG,
                          ),
                        ),
                        Text(
                          'CRMV ${_vetProfile!.crmvNumber}/${_vetProfile!.crmvUf}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Grupo 1: Atendimentos & Clínica
          _buildSidebarNavItem(
            index: 0,
            icon: Icons.calendar_month_rounded,
            label: 'Agendamentos',
            isDark: isDark,
          ),
          _buildSidebarNavItem(
            index: 1,
            icon: Icons.history_rounded,
            label: 'Histórico',
            isDark: isDark,
          ),
          _buildSidebarNavItem(
            index: 2,
            icon: Icons.groups_rounded,
            label: 'Equipe Clínica',
            isDark: isDark,
          ),
          const Divider(height: 24),

          // Grupo 2: Gestão B2B
          _buildSidebarNavItem(
            index: 3,
            icon: Icons.account_balance_wallet_rounded,
            label: 'Financeiro',
            isDark: isDark,
          ),
          _buildSidebarNavItem(
            index: 4,
            icon: Icons.settings_rounded,
            label: 'Ajustes CRMV',
            isDark: isDark,
          ),
          const Spacer(),

          // Grupo 3: Conta
          const Divider(height: 16),
          _buildSidebarNavItem(
            index: 5,
            icon: Icons.logout_rounded,
            label: 'Sair da Conta',
            isDark: isDark,
            color: Colors.redAccent,
            onTapCustom: _confirmLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isDark,
    Color? color,
    VoidCallback? onTapCustom,
  }) {
    final isSelected = _selectedNavIndex == index;
    final itemColor =
        color ??
        (isSelected
            ? AppColors.patasColor
            : (isDark ? Colors.white70 : Colors.black87));

    return InkWell(
      onTap: onTapCustom ?? () => setState(() => _selectedNavIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.patasColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: itemColor, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: itemColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
                fontFamily: 'Fredoka',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCadastro(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadVetData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.patasColor.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.medical_information_rounded,
                  size: 48,
                  color: AppColors.patasColor,
                ),
                const SizedBox(height: 12),
                Text(
                  'Cadastre seu CRMV e Clínica',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.darkBG,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Cadastre seu perfil profissional para atender pacientes, emitir prontuários SOAP e receber agendamentos de tutores.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.badge_rounded, color: Colors.white),
                  label: const Text(
                    'Cadastrar CRMV',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VetRegistrationScreen(),
                      ),
                    ).then((_) => _loadVetData());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.patasColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipeTab(bool isDark) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.patasColor.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.patasColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      color: AppColors.patasColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Equipe Clínica & Escala de Plantão',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.darkBG,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Gerencie veterinários parceiros, plantonistas e funções da sua clínica/hospital.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Convidar Veterinário',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Recurso em breve: Convites para membros da equipe clínica.',
                            ),
                            backgroundColor: AppColors.patasColor,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.patasColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(
                        Icons.access_time_filled_rounded,
                        size: 18,
                        color: isDark ? Colors.white : AppColors.darkBG,
                      ),
                      label: Text(
                        'Escala 24h',
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.darkBG,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Recurso em breve: Gestão de turnos de plantão 24h.',
                            ),
                            backgroundColor: AppColors.patasColor,
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: isDark ? Colors.white30 : Colors.black26,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Membros da Equipe',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.darkBG,
          ),
        ),
        const SizedBox(height: 10),

        if (_vetProfile != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.patasColor.withValues(alpha: 0.2),
                  backgroundImage:
                      _vetProfile!.photoUrl != null &&
                          _vetProfile!.photoUrl!.isNotEmpty
                      ? NetworkImage(_vetProfile!.photoUrl!)
                      : null,
                  child:
                      _vetProfile!.photoUrl == null ||
                          _vetProfile!.photoUrl!.isEmpty
                      ? const Icon(
                          Icons.medical_services,
                          color: AppColors.patasColor,
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _vetProfile!.fullName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark ? Colors.white : AppColors.darkBG,
                        ),
                      ),
                      Text(
                        'CRMV ${_vetProfile!.crmvNumber}/${_vetProfile!.crmvUf} • Responsável Técnico',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.patasColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Admin / RT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.patasColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        const MobileScrollPadding(),
      ],
    );
  }

  Widget _buildProfileBanner(bool isDark) {
    final sub = _subscription;
    final status = sub?.status ?? 'trial';
    final remainingDays = sub?.remainingTrialDays ?? 14;

    Color badgeBg;
    Color badgeTextColor;
    String badgeText;
    IconData badgeIcon;

    if (status == 'active') {
      badgeBg = const Color(0xFF10B981).withValues(alpha: 0.15);
      badgeTextColor = const Color(0xFF10B981);
      badgeText = 'PRO';
      badgeIcon = Icons.stars_rounded;
    } else if (status == 'grace_period') {
      badgeBg = Colors.orange.withValues(alpha: 0.15);
      badgeTextColor = Colors.orange;
      badgeText = 'Pendente';
      badgeIcon = Icons.warning_amber_rounded;
    } else if (status == 'past_due') {
      badgeBg = Colors.redAccent.withValues(alpha: 0.15);
      badgeTextColor = Colors.redAccent;
      badgeText = 'Suspenso';
      badgeIcon = Icons.error_outline_rounded;
    } else {
      // trial
      badgeBg = AppColors.patasColor.withValues(alpha: 0.15);
      badgeTextColor = AppColors.patasColor;
      badgeText =
          'Teste: $remainingDays ${remainingDays == 1 ? 'dia' : 'dias'}';
      badgeIcon = Icons.timer_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (status == 'active')
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.patasColor.withValues(alpha: 0.2),
            backgroundImage:
                (_vetProfile!.photoUrl != null &&
                    _vetProfile!.photoUrl!.isNotEmpty)
                ? NetworkImage(_vetProfile!.photoUrl!)
                : null,
            child:
                (_vetProfile!.photoUrl == null ||
                    _vetProfile!.photoUrl!.isEmpty)
                ? const Icon(
                    Icons.medical_services_rounded,
                    size: 26,
                    color: AppColors.patasColor,
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _vetProfile!.fullName,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.darkBG,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'CRMV ${_vetProfile!.crmvUf} ${_vetProfile!.crmvNumber}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.patasColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_vetProfile!.clinicName != null &&
                    _vetProfile!.clinicName!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _vetProfile!.clinicName!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Canto direito: Badge no topo + Editar embaixo
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Badge de Assinatura (canto superior direito)
              InkWell(
                onTap: () {
                  if (_vetProfile != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            VetCheckoutPage(vetProfile: _vetProfile!),
                      ),
                    ).then((_) => _loadVetData());
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: badgeTextColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeIcon, size: 13, color: badgeTextColor),
                      const SizedBox(width: 4),
                      Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: badgeTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Botão Editar (canto inferior direito)
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          VetRegistrationScreen(existingProfile: _vetProfile),
                    ),
                  ).then((_) => _loadVetData());
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.edit_rounded,
                        size: 16,
                        color: AppColors.patasColor,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Editar',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.patasColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required bool isHistory}) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 60),
        Center(
          child: Column(
            children: [
              Icon(
                isHistory
                    ? Icons.history_rounded
                    : Icons.calendar_today_rounded,
                size: 56,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                isHistory
                    ? 'Nenhum histórico encontrado.'
                    : 'Nenhum agendamento ativo.',
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  isHistory
                      ? 'Atendimentos concluídos ou cancelados aparecerão aqui.'
                      : 'Quando tutores agendarem consultas, elas aparecerão aqui.',
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
    bool isDark, {
    required bool isHistory,
  }) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      itemCount: appts.length + 1,
      itemBuilder: (context, index) {
        if (index == appts.length) {
          return const MobileScrollPadding();
        }
        return _buildCard(appts[index], isDark, isHistory: isHistory);
      },
    );
  }

  Widget _buildCard(
    HealthAppointment appt,
    bool isDark, {
    required bool isHistory,
  }) {
    final petName = appt.petName ?? 'Pet Paciente';
    final petPhoto = appt.petPhotoUrl;

    String dateLabel = '${appt.appointmentDate} às ${appt.appointmentTime}';
    try {
      final dt = DateTime.parse(
        '${appt.appointmentDate} ${appt.appointmentTime}',
      );
      dateLabel =
          '${DateFormat("dd 'de' MMMM 'de' yyyy", 'pt_BR').format(dt)} às ${appt.appointmentTime.substring(0, 5)}';
    } catch (_) {}

    return Opacity(
      opacity: isHistory ? 0.75 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
              // Cabeçalho: pet + badge de status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.patasColor.withValues(
                          alpha: 0.2,
                        ),
                        backgroundImage:
                            (petPhoto != null && petPhoto.isNotEmpty)
                            ? NetworkImage(petPhoto)
                            : null,
                        child: (petPhoto == null || petPhoto.isEmpty)
                            ? const Icon(
                                Icons.pets_rounded,
                                size: 18,
                                color: AppColors.patasColor,
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        petName,
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.darkBG,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        appt.status,
                      ).withValues(alpha: 0.15),
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
              const Divider(height: 20),

              // Data, modalidade e queixa
              Row(
                children: [
                  Icon(
                    Icons.event_rounded,
                    size: 14,
                    color: isHistory ? Colors.grey : AppColors.patasColor,
                  ),
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
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    appt.modality == 'home'
                        ? Icons.home_work_rounded
                        : Icons.medical_information_rounded,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    appt.modality == 'home' ? 'A Domicílio' : 'Na Clínica',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),

              if (appt.notes != null && appt.notes!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Queixa: ${appt.notes}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ],

              // Botões de ação — apenas na aba Ativos
              if (!isHistory) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.medical_services_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: const Text(
                          'Iniciar Atendimento',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VetConsultationScreen(
                                appointment: appt,
                                petId: appt.petId,
                                vetId: appt.vetId,
                                petName: petName,
                              ),
                            ),
                          ).then((_) => _loadVetData());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.patasColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () => _handleCancelAppointment(appt),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                      child: const Icon(
                        Icons.cancel_outlined,
                        size: 20,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialTab(bool isDark) {
    final sub = _subscription;
    final isPastDue = sub != null && sub.isPastDue;
    final isActive = sub != null && sub.status == 'active';
    final isGrace = sub != null && sub.status == 'grace_period';

    Color bannerColor = AppColors.patasColor;
    String statusTitle = 'Degustação Grátis Pro';
    String statusSubtitle =
        'Restam ${sub?.remainingTrialDays ?? 14} dias no seu período de testes. Assine para garantir visibilidade contínua.';
    IconData statusIcon = Icons.verified_outlined;
    String btnLabel = 'Assinar Plano Pro';

    if (isActive) {
      bannerColor = Colors.green;
      statusTitle = 'Assinatura Pro Ativa';
      statusSubtitle =
          'Seu perfil está em destaque no mapa e você pode receber agendamentos online ilimitados.';
      statusIcon = Icons.check_circle_rounded;
      btnLabel = 'Gerenciar Plano';
    } else if (isGrace) {
      bannerColor = Colors.orange;
      statusTitle = 'Período de Tolerância';
      statusSubtitle =
          'Sua fatura está pendente. Regularize em breve para evitar a suspensão do seu perfil.';
      statusIcon = Icons.warning_amber_rounded;
      btnLabel = 'Pagar Fatura';
    } else if (isPastDue) {
      bannerColor = Colors.redAccent;
      statusTitle = 'Perfil Suspenso (Inadimplente)';
      statusSubtitle =
          'Seu perfil está temporariamente oculto no mapa e buscas. Regularize sua fatura para reativar.';
      statusIcon = Icons.error_outline_rounded;
      btnLabel = 'Regularizar Agora';
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        // Card de Status da Assinatura
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: bannerColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: bannerColor.withValues(alpha: 0.08),
                blurRadius: 12,
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
                      color: bannerColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon, color: bannerColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusTitle,
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.darkBG,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          statusSubtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.star_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    btnLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    if (_vetProfile != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              VetCheckoutPage(vetProfile: _vetProfile!),
                        ),
                      ).then((_) => _loadVetData());
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bannerColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Seção Histórico de Faturas
        Text(
          'Histórico de Faturas',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.darkBG,
          ),
        ),
        const SizedBox(height: 12),

        if (_invoices.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: const Column(
              children: [
                Icon(Icons.receipt_long_rounded, size: 40, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'Nenhuma fatura emitida até o momento.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          )
        else
          ..._invoices.map((inv) {
            Color statusColor = Colors.orange;
            String statusText = 'Pendente';
            if (inv.isPaid) {
              statusColor = Colors.green;
              statusText = 'Paga';
            } else if (inv.status == 'overdue') {
              statusColor = Colors.redAccent;
              statusText = 'Vencida';
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 0,
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.receipt_rounded,
                    color: statusColor,
                    size: 22,
                  ),
                ),
                title: Text(
                  'Fatura Pro • R\$ ${inv.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.darkBG,
                  ),
                ),
                subtitle: Text(
                  inv.dueDate != null
                      ? 'Vencimento: ${inv.dueDate!.day}/${inv.dueDate!.month}/${inv.dueDate!.year}'
                      : 'Fatura B2B',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                trailing: inv.isPaid
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          statusText,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: () {
                          if (_vetProfile != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VetPixPaymentPage(
                                  invoice: inv,
                                  vetProfile: _vetProfile!,
                                ),
                              ),
                            ).then((_) => _loadVetData());
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.patasColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Pagar PIX',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            );
          }),
      ],
    );
  }
}
