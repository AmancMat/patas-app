import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../constants/app_colors.dart';
import '../../../common_widgets/patas_essencial_app_bar.dart';
import '../../../common_widgets/mobile_scroll_padding.dart';
import '../../../utils/responsive_layout.dart';
import '../../../models/active_account_model.dart';
import '../../../providers/active_account_provider.dart';
import '../models/rescue_alert_model.dart';
import '../models/shelter_animal_model.dart';
import '../services/shelter_service.dart';
import 'report_rescue_alert_sheet.dart';
import 'ong_create_animal_sheet.dart';

class OngRescueAlertsScreen extends StatefulWidget {
  final String? ongId;

  const OngRescueAlertsScreen({super.key, this.ongId});

  @override
  State<OngRescueAlertsScreen> createState() => _OngRescueAlertsScreenState();
}

class _OngRescueAlertsScreenState extends State<OngRescueAlertsScreen>
    with SingleTickerProviderStateMixin {
  final _shelterService = ShelterService();

  late TabController _tabController;
  List<RescueAlert> _allAlerts = [];
  bool _isLoading = true;
  String _selectedTypeFilter = 'todos';
  String _effectiveOngId = '';

  String _getUrgencyLabel(RescueAlert alert, BuildContext context) {
    switch (alert.urgency) {
      case RescueUrgency.critico:
        return context.tr('acolhe.urgency_critical');
      case RescueUrgency.alta:
        return context.tr('acolhe.urgency_high');
      case RescueUrgency.media:
        return context.tr('acolhe.urgency_medium');
      case RescueUrgency.baixa:
        return context.tr('acolhe.urgency_low');
    }
  }

  String _getStatusLabel(RescueAlert alert, BuildContext context) {
    switch (alert.status) {
      case RescueAlertStatus.aberto:
        return context.tr('acolhe.status_open');
      case RescueAlertStatus.emAtendimento:
        return context.tr('acolhe.status_in_progress');
      case RescueAlertStatus.resgatado:
        return context.tr('acolhe.status_rescued');
      case RescueAlertStatus.cancelado:
        return context.tr('acolhe.status_canceled');
    }
  }

  String _getTypeLabel(RescueAlert alert, BuildContext context) {
    switch (alert.alertType) {
      case RescueAlertType.ferido:
        return context.tr('acolhe.type_injured');
      case RescueAlertType.atropelado:
        return context.tr('acolhe.type_hit_by_car');
      case RescueAlertType.abandonadoFilhotes:
        return context.tr('acolhe.type_puppies');
      case RescueAlertType.mausTratos:
        return context.tr('acolhe.type_abuse');
      case RescueAlertType.perdido:
        return context.tr('acolhe.type_lost');
      case RescueAlertType.outro:
        return context.tr('acolhe.type_other');
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _initOngIdAndLoad());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initOngIdAndLoad() async {
    if (widget.ongId != null && widget.ongId!.isNotEmpty) {
      _effectiveOngId = widget.ongId!;
    } else {
      final accProvider = Provider.of<ActiveAccountProvider>(
        context,
        listen: false,
      );
      if (accProvider.activeAccount?.type == AccountType.ong) {
        _effectiveOngId = accProvider.activeAccount!.id;
      } else {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          try {
            final res = await Supabase.instance.client
                .from('ong_profiles')
                .select('id')
                .eq('user_id', user.id)
                .maybeSingle();
            if (res != null) {
              _effectiveOngId = res['id'] as String;
            }
          } catch (_) {}
        }
      }
    }
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    try {
      final alerts = await _shelterService.getRescueAlerts();
      if (mounted) {
        setState(() {
          _allAlerts = alerts;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[OngRescueAlertsScreen] Erro ao carregar alertas: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _assumeRescue(RescueAlert alert) async {
    if (_effectiveOngId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('acolhe.snack_only_ong_assume'),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final success = await _shelterService.assignRescueAlertToOng(
      alertId: alert.id,
      ongId: _effectiveOngId,
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('acolhe.snack_call_assumed', {'title': alert.title})),
            backgroundColor: Colors.teal,
          ),
        );
      }
      _loadAlerts();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao assumir chamado. Tente novamente.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _convertToShelterAnimal(RescueAlert alert) async {
    if (_effectiveOngId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('acolhe.snack_select_ong_first')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Cria rascunho de animal pré-preenchido com os dados do resgate
    final draftAnimal = ShelterAnimal(
      id: '',
      ongId: _effectiveOngId,
      name: alert.title,
      species: 'canino',
      status: 'em_tratamento',
      rescueStory:
          'Resgatado em: ${alert.address}\n\nRelato original: ${alert.description}\nContato do relator: ${alert.reporterName} (${alert.reporterPhone})',
      photoUrl: alert.photos.isNotEmpty ? alert.photos.first : null,
      galleryPhotos: alert.photos,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await OngCreateAnimalSheet.show(
      context,
      ongId: _effectiveOngId,
      animalToEdit: draftAnimal,
    );

    if (result == true) {
      // Marca o chamado como resgatado
      await _shelterService.markRescueAlertCompleted(
        alertId: alert.id,
        notes: 'Resgatado e acolhido no abrigo.',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr('acolhe.snack_animal_sheltered'),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadAlerts();
    }
  }

  Future<void> _completeRescue(RescueAlert alert, bool isDark) async {
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          context.tr('acolhe.dialog_complete_title'),
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.darkBG,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('acolhe.dialog_complete_prompt'),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: notesController,
              maxLines: 2,
              style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
              decoration: InputDecoration(
                hintText: context.tr('acolhe.dialog_notes_hint'),
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey.shade400,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white12 : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              context.tr('common.cancel'),
              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(context.tr('acolhe.dialog_confirm_rescue_btn')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _shelterService.markRescueAlertCompleted(
        alertId: alert.id,
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      );
      _loadAlerts();
    }
  }

  Future<void> _confirmDelete(RescueAlert alert, bool isDark) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          context.tr('acolhe.dialog_delete_call_title'),
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.darkBG,
          ),
        ),
        content: Text(
          context.tr('acolhe.dialog_delete_call_prompt'),
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              context.tr('common.back'),
              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(context.tr('common.delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _shelterService.deleteRescueAlert(alert.id);
      _loadAlerts();
    }
  }

  void _openWhatsApp(String phone, String title) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final text =
        'Olá! Estou entrando em contato pelo Patas a respeito do chamado de resgate: *$title*.';
    final uri = Uri.parse(
      'https://wa.me/55$cleanPhone?text=${Uri.encodeComponent(text)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showImageDialog(BuildContext context, String imageUrl, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              clipBehavior: Clip.none,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    padding: const EdgeInsets.all(32),
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    child: const Icon(
                      Icons.broken_image_rounded,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final accProvider = Provider.of<ActiveAccountProvider>(context);
    final isOng = accProvider.activeAccount?.type == AccountType.ong;

    // Métricas em tempo real
    final totalAlerts = _allAlerts.length;
    final openAlerts = _allAlerts
        .where((a) => a.status == RescueAlertStatus.aberto)
        .length;
    final criticalAlerts = _allAlerts
        .where(
          (a) =>
              a.urgency == RescueUrgency.critico ||
              a.urgency == RescueUrgency.alta ||
              a.alertType == RescueAlertType.ferido ||
              a.alertType == RescueAlertType.atropelado,
        )
        .length;
    final inProgressAlerts = _allAlerts
        .where((a) => a.status == RescueAlertStatus.emAtendimento)
        .length;
    final rescuedAlerts = _allAlerts
        .where((a) => a.status == RescueAlertStatus.resgatado)
        .length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
      appBar: PatasEssencialAppBar(
        title: context.tr('acolhe.rescue_alerts_title'),
        subtitle: isOng
            ? context.tr('acolhe.rescue_sub_ong')
            : context.tr('acolhe.rescue_sub_tutor'),
        showBackButton: true,
        leadingIcon: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.amber,
          size: 22,
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            onPressed: _loadAlerts,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: context.tr('acolhe.report_risk_animal'),
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.add_alert_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () {
                ReportRescueAlertSheet.show(context, onSaved: _loadAlerts);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: context.isDesktop
              ? 20
              : (MediaQuery.paddingOf(context).bottom + 76),
        ),
        child: FloatingActionButton.extended(
          heroTag: null,
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_alert_rounded),
          label: Text(
            context.tr('acolhe.report_risk_animal'),
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          onPressed: () {
            ReportRescueAlertSheet.show(context, onSaved: _loadAlerts);
          },
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.patasColor),
            )
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: _buildContent(
                    context,
                    isDark: isDark,
                    isOng: isOng,
                    isDesktop: context.isDesktop,
                    totalAlerts: totalAlerts,
                    openAlerts: openAlerts,
                    criticalAlerts: criticalAlerts,
                    inProgressAlerts: inProgressAlerts,
                    rescuedAlerts: rescuedAlerts,
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required bool isDark,
    required bool isOng,
    required bool isDesktop,
    required int totalAlerts,
    required int openAlerts,
    required int criticalAlerts,
    required int inProgressAlerts,
    required int rescuedAlerts,
  }) {
    // Filtragem por aba
    List<RescueAlert> listByTab;
    if (_tabController.index == 0) {
      listByTab = _allAlerts
          .where((a) => a.status == RescueAlertStatus.aberto)
          .toList();
    } else if (_tabController.index == 1) {
      listByTab = _allAlerts
          .where((a) => a.status == RescueAlertStatus.emAtendimento)
          .toList();
    } else {
      listByTab = _allAlerts
          .where((a) => a.status == RescueAlertStatus.resgatado)
          .toList();
    }

    // Filtragem por tipo de risco
    if (_selectedTypeFilter != 'todos') {
      listByTab = listByTab
          .where(
            (a) => RescueAlert.typeDbString(a.alertType) == _selectedTypeFilter,
          )
          .toList();
    }

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 16,
        vertical: 20,
      ),
      children: [
        // Hero Banner
        _buildHeroBanner(isDark: isDark, isOng: isOng),
        const SizedBox(height: 20),

        // Régua de 4 KPIs
        _buildKpiMetrics(
          isDark: isDark,
          isDesktop: isDesktop,
          totalAlerts: totalAlerts,
          openAlerts: openAlerts,
          criticalAlerts: criticalAlerts,
          inProgressAlerts: inProgressAlerts,
          rescuedAlerts: rescuedAlerts,
        ),
        const SizedBox(height: 24),

        // Barra de Abas refinada
        _buildTabsAndFilters(
          isDark: isDark,
          openCount: openAlerts,
          inProgressCount: inProgressAlerts,
          rescuedCount: rescuedAlerts,
        ),
        const SizedBox(height: 16),

        // Listagem de Cards de Resgate
        if (listByTab.isEmpty)
          _buildEmptyState(isDark: isDark)
        else
          ...listByTab.map(
            (alert) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildRescueCard(
                context,
                alert: alert,
                isDark: isDark,
                isOng: isOng,
                isDesktop: isDesktop,
              ),
            ),
          ),

        if (!isDesktop) const MobileScrollPadding(),
      ],
    );
  }

  Widget _buildHeroBanner({required bool isDark, required bool isOng}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1B4B), const Color(0xFF311042)]
              : [const Color(0xFFFFF1F2), const Color(0xFFFFE4E6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.redAccent.withValues(alpha: 0.3)
              : Colors.red.shade100,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.emergency_rounded,
              color: Colors.redAccent,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOng
                      ? context.tr('acolhe.banner_rescue_ong')
                      : context.tr('acolhe.banner_rescue_tutor'),
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.darkBG,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOng
                      ? context.tr('acolhe.banner_rescue_desc_ong')
                      : context.tr('acolhe.banner_rescue_desc_tutor'),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiMetrics({
    required bool isDark,
    required bool isDesktop,
    required int totalAlerts,
    required int openAlerts,
    required int criticalAlerts,
    required int inProgressAlerts,
    required int rescuedAlerts,
  }) {
    final kpis = [
      _KpiData(
        title: context.tr('acolhe.kpi_open_calls'),
        value: openAlerts.toString(),
        icon: Icons.campaign_rounded,
        color: Colors.amber.shade700,
      ),
      _KpiData(
        title: context.tr('acolhe.kpi_critical_cases'),
        value: criticalAlerts.toString(),
        icon: Icons.error_outline_rounded,
        color: Colors.redAccent,
      ),
      _KpiData(
        title: context.tr('acolhe.kpi_in_treatment'),
        value: inProgressAlerts.toString(),
        icon: Icons.medical_services_rounded,
        color: Colors.blueAccent,
      ),
      _KpiData(
        title: context.tr('acolhe.kpi_rescued'),
        value: rescuedAlerts.toString(),
        icon: Icons.task_alt_rounded,
        color: Colors.green,
      ),
    ];

    if (isDesktop) {
      return Row(
        children: kpis
            .map(
              (kpi) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _buildKpiCard(kpi: kpi, isDark: isDark),
                ),
              ),
            )
            .toList(),
      );
    }

    // Mobile: Grade 2x2 sem compressão
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(kpi: kpis[0], isDark: isDark),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKpiCard(kpi: kpis[1], isDark: isDark),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(kpi: kpis[2], isDark: isDark),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKpiCard(kpi: kpis[3], isDark: isDark),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard({required _KpiData kpi, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kpi.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(kpi.icon, size: 20, color: kpi.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  kpi.value,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.darkBG,
                  ),
                ),
                Text(
                  kpi.title,
                  style: TextStyle(
                    fontSize: 11,
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
    );
  }

  Widget _buildTabsAndFilters({
    required bool isDark,
    required int openCount,
    required int inProgressCount,
    required int rescuedCount,
  }) {
    final filterOptions = [
      {'key': 'todos', 'label': context.tr('acolhe.filter_all_risks')},
      {'key': 'ferido', 'label': context.tr('acolhe.filter_injured')},
      {'key': 'atropelado', 'label': context.tr('acolhe.filter_hit_by_car')},
      {'key': 'abandonado_filhotes', 'label': context.tr('acolhe.filter_puppies')},
      {'key': 'maus_tratos', 'label': context.tr('acolhe.filter_mistreatment')},
      {'key': 'perdido', 'label': context.tr('acolhe.filter_lost')},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tabs com acabamento refinado
        Container(
          height: 48,
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE8EDF2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.shade300,
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: isDark ? const Color(0xFFDC2626) : Colors.redAccent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? const Color(0xFFDC2626) : Colors.redAccent)
                      .withValues(alpha: isDark ? 0.35 : 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 2,
            ),
            labelColor: Colors.white,
            unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
            labelStyle: const TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            tabs: [
              Tab(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(context.tr('acolhe.tab_open_calls', {'count': openCount.toString()})),
                ),
              ),
              Tab(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(context.tr('acolhe.tab_in_progress_calls', {'count': inProgressCount.toString()})),
                ),
              ),
              Tab(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(context.tr('acolhe.tab_rescued_calls', {'count': rescuedCount.toString()})),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Filtros de Tipo de Risco
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filterOptions.map((opt) {
              final isSelected = _selectedTypeFilter == opt['key'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    opt['label']!,
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: isDark
                      ? const Color(0xFFDC2626)
                      : Colors.redAccent,
                  backgroundColor: isDark
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected
                          ? Colors.transparent
                          : (isDark ? Colors.white12 : Colors.grey.shade300),
                    ),
                  ),
                  showCheckmark: false,
                  onSelected: (val) {
                    setState(() {
                      _selectedTypeFilter = opt['key']!;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRescueCard(
    BuildContext context, {
    required RescueAlert alert,
    required bool isDark,
    required bool isOng,
    required bool isDesktop,
  }) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final formattedDate = dateFormat.format(alert.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: alert.urgency == RescueUrgency.critico
              ? Colors.redAccent.withValues(alpha: 0.5)
              : (isDark ? Colors.white12 : Colors.grey.shade200),
          width: alert.urgency == RescueUrgency.critico ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header do Card: Badges de Urgência e Tipo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              child: Row(
                children: [
                  // Badge Urgência
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: alert.urgencyColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: alert.urgencyColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          alert.urgencyIcon,
                          size: 14,
                          color: alert.urgencyColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _getUrgencyLabel(alert, context),
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: alert.urgencyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Badge Tipo de Risco
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: alert.typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(alert.typeIcon, size: 14, color: alert.typeColor),
                        const SizedBox(width: 5),
                        Text(
                          _getTypeLabel(alert, context),
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: alert.typeColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Data
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),

            // Corpo do Card
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título do Chamado
                  Text(
                    alert.title,
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.darkBG,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Descrição detalhada
                  Text(
                    alert.description,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Miniaturas de Fotos (se houver)
                  if (alert.photos.isNotEmpty) ...[
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: alert.photos.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (ctx, idx) {
                          final photoUrl = alert.photos[idx];
                          return GestureDetector(
                            onTap: () =>
                                _showImageDialog(context, photoUrl, isDark),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Stack(
                                children: [
                                  Image.network(
                                    photoUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 80,
                                      height: 80,
                                      color: isDark
                                          ? const Color(0xFF0F172A)
                                          : Colors.grey.shade200,
                                      child: const Icon(
                                        Icons.broken_image_rounded,
                                        size: 24,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.zoom_in_rounded,
                                        size: 14,
                                        color: Colors.white,
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
                    const SizedBox(height: 14),
                  ],

                  // Endereço e Localização
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${alert.address}${alert.neighborhood != null ? ' - ${alert.neighborhood}' : ''}${alert.city != null ? ', ${alert.city}' : ''}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.darkBG,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (alert.referencePoint != null &&
                            alert.referencePoint!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.only(left: 26),
                            child: Text(
                              context.tr('acolhe.ref_point', {'point': alert.referencePoint ?? ''}),
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Dados do Relator
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.patasColor.withValues(
                          alpha: 0.15,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 16,
                          color: AppColors.patasColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('acolhe.reported_by', {'name': alert.reporterName}),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            Text(
                              alert.reporterPhone,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Botão WhatsApp com o Relator
                      ElevatedButton.icon(
                        onPressed: () =>
                            _openWhatsApp(alert.reporterPhone, alert.title),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 15,
                        ),
                        label: const Text(
                          'WhatsApp',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Observações finais de resgate (se concluído)
                  if (alert.notes != null && alert.notes!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.tr('acolhe.outcome_label', {'notes': alert.notes ?? ''}),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Barra Inferior de Ações
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Status badge textual
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: alert.statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getStatusLabel(alert, context),
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: alert.statusColor,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Ações para ONGs
                  if (alert.status == RescueAlertStatus.aberto && isOng) ...[
                    ElevatedButton.icon(
                      onPressed: () => _assumeRescue(alert),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.local_hospital_rounded, size: 16),
                      label: Text(
                        context.tr('acolhe.assume_call_btn'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ] else if (alert.status == RescueAlertStatus.emAtendimento &&
                      isOng) ...[
                    // Converter em Acolhido no Abrigo
                    OutlinedButton.icon(
                      onPressed: () => _convertToShelterAnimal(alert),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.patasColor,
                        side: const BorderSide(color: AppColors.patasColor),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.pets_rounded, size: 16),
                      label: Text(
                        context.tr('acolhe.shelter_pet_btn'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Marcar como Concluído
                    ElevatedButton.icon(
                      onPressed: () => _completeRescue(alert, isDark),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: Text(
                        context.tr('common.finish'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],

                  // Botão de Excluir / Cancelar
                  IconButton(
                    tooltip: context.tr('acolhe.delete_call_tooltip'),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                      size: 20,
                    ),
                    onPressed: () => _confirmDelete(alert, isDark),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({required bool isDark}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 56,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              context.tr('acolhe.empty_calls_title'),
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.darkBG,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr('acolhe.empty_calls_desc'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : Colors.black54,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}
