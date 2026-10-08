import 'package:flutter/material.dart';
import 'package:patas_web_app/core/localization/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app.dart';
import '../../../constants/app_colors.dart';
import '../../../common_widgets/patas_essencial_app_bar.dart';
import '../../../common_widgets/mobile_scroll_padding.dart';
import '../../../utils/responsive_layout.dart';
import '../../../models/active_account_model.dart';
import '../../../providers/active_account_provider.dart';
import '../models/shelter_event_model.dart';
import '../services/shelter_service.dart';
import 'create_shelter_event_sheet.dart';

class OngEventsDashboardScreen extends StatefulWidget {
  final String? ongId;

  const OngEventsDashboardScreen({super.key, this.ongId});

  @override
  State<OngEventsDashboardScreen> createState() =>
      _OngEventsDashboardScreenState();
}

class _OngEventsDashboardScreenState extends State<OngEventsDashboardScreen>
    with SingleTickerProviderStateMixin {
  final _shelterService = ShelterService();

  late TabController _tabController;
  List<ShelterEvent> _allEvents = [];
  bool _isLoading = true;
  String _selectedTypeFilter = 'todos';
  String _effectiveOngId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      final accProvider =
          Provider.of<ActiveAccountProvider>(context, listen: false);
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
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final events = await _shelterService.getEvents(
        ongId: _effectiveOngId.isNotEmpty ? _effectiveOngId : null,
      );
      if (mounted) {
        setState(() {
          _allEvents = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[OngEventsDashboardScreen] Erro ao carregar eventos: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAttendance(ShelterEvent event) async {
    final newAttending = !event.isUserAttending;

    // Atualização otimista na lista
    setState(() {
      final idx = _allEvents.indexWhere((e) => e.id == event.id);
      if (idx != -1) {
        _allEvents[idx] = event.copyWith(
          isUserAttending: newAttending,
          attendeesCount: newAttending
              ? event.attendeesCount + 1
              : (event.attendeesCount > 0 ? event.attendeesCount - 1 : 0),
        );
      }
    });

    try {
      await _shelterService.toggleEventAttendance(
        eventId: event.id,
        currentlyAttending: event.isUserAttending,
      );
    } catch (_) {
      // Reverte em caso de falha
      _loadEvents();
    }
  }

  Future<void> _confirmDelete(ShelterEvent event, bool isDark) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          context.tr('acolhe.delete_event'),
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.darkBG,
          ),
        ),
        content: Text(
          context.tr('acolhe.delete_event_confirm', {'name': event.title}),
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              context.tr('common.back'),
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
              ),
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
            child: Text(context.tr('acolhe.delete_event')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _shelterService.deleteEvent(event.id);
      _loadEvents();
    }
  }

  void _shareEvent(ShelterEvent event) async {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    final dateStr =
        '${dateFormat.format(event.startDate)} às ${timeFormat.format(event.startDate)}';

    final text =
        '🐾 *${event.title}* (${event.eventTypeLabel})\n'
        '📅 Data: $dateStr\n'
        '📍 Local: ${event.locationName} - ${event.address}\n'
        '${event.description}\n\n'
        'Venha prestigiar e ajude a salvar vidas no app Patas!';

    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openWhatsAppContact(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/55$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final accProvider = Provider.of<ActiveAccountProvider>(context);
    final isOng = accProvider.activeAccount?.type == AccountType.ong;

    // Métricas calculadas em tempo real
    final totalEvents = _allEvents.length;
    final upcomingEvents = _allEvents.where((e) => !e.isPast).length;
    final adocaoEvents = _allEvents
        .where((e) => e.eventType == ShelterEventType.adocao)
        .length;
    final totalAttendees =
        _allEvents.fold<int>(0, (sum, e) => sum + e.attendeesCount);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
      appBar: PatasEssencialAppBar(
        title: isOng ? context.tr('acolhe.events_title_ong') : context.tr('acolhe.events_title_tutor'),
        subtitle: isOng
            ? context.tr('acolhe.events_sub_ong')
            : context.tr('acolhe.events_sub_tutor'),
        showBackButton: true,
        leadingIcon: const Icon(
          Icons.campaign_rounded,
          color: Colors.deepPurpleAccent,
          size: 22,
        ),
        actions: [
          if (isOng && _effectiveOngId.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                tooltip: context.tr('acolhe.new_event'),
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.deepPurpleAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: () {
                  CreateShelterEventSheet.show(
                    context,
                    ongId: _effectiveOngId,
                    onSaved: _loadEvents,
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: (isOng && _effectiveOngId.isNotEmpty)
          ? Padding(
              padding: EdgeInsets.only(
                bottom: context.isDesktop
                    ? 20
                    : (MediaQuery.paddingOf(context).bottom + 76),
              ),
              child: FloatingActionButton.extended(
                heroTag: null,
                backgroundColor: Colors.deepPurpleAccent,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.campaign_rounded),
                label: Text(
                  context.tr('acolhe.publish_event'),
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  CreateShelterEventSheet.show(
                    context,
                    ongId: _effectiveOngId,
                    onSaved: _loadEvents,
                  );
                },
              ),
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadEvents,
          color: Colors.deepPurpleAccent,
          child: ResponsiveLayout(
            mobile: _buildContent(
              context,
              isDark: isDark,
              isOng: isOng,
              isDesktop: false,
              totalEvents: totalEvents,
              upcomingEvents: upcomingEvents,
              adocaoEvents: adocaoEvents,
              totalAttendees: totalAttendees,
            ),
            desktop: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: _buildContent(
                  context,
                  isDark: isDark,
                  isOng: isOng,
                  isDesktop: true,
                  totalEvents: totalEvents,
                  upcomingEvents: upcomingEvents,
                  adocaoEvents: adocaoEvents,
                  totalAttendees: totalAttendees,
                ),
              ),
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
    required int totalEvents,
    required int upcomingEvents,
    required int adocaoEvents,
    required int totalAttendees,
  }) {
    // Filtragem por aba e categoria
    final activeEvents = _allEvents.where((e) => !e.isPast).toList();
    final pastEvents = _allEvents.where((e) => e.isPast).toList();

    List<ShelterEvent> currentList =
        _tabController.index == 0 ? activeEvents : pastEvents;

    if (_selectedTypeFilter != 'todos') {
      currentList = currentList
          .where((e) =>
              ShelterEvent.eventTypeDbString(e.eventType) ==
              _selectedTypeFilter)
          .toList();
    }

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 16,
        vertical: 20,
      ),
      children: [
        // Header com banner informativo
        _buildHeroBanner(isDark: isDark, isOng: isOng),
        const SizedBox(height: 20),

        // Régua de 4 KPIs
        _buildKpiMetrics(
          isDark: isDark,
          isDesktop: isDesktop,
          totalEvents: totalEvents,
          upcomingEvents: upcomingEvents,
          adocaoEvents: adocaoEvents,
          totalAttendees: totalAttendees,
        ),
        const SizedBox(height: 24),

        // Barra de Abas (Próximos vs Histórico)
        _buildTabsAndFilters(isDark: isDark, upcomingCount: activeEvents.length),
        const SizedBox(height: 16),

        // Listagem de Cards de Evento
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.deepPurpleAccent,
              ),
            ),
          )
        else if (currentList.isEmpty)
          _buildEmptyState(isDark: isDark, isOng: isOng)
        else
          ...currentList.map((event) => _buildEventCard(
                event: event,
                isDark: isDark,
                isOng: isOng,
                isDesktop: isDesktop,
              )),

        // Compensação dinâmica de rolagem
        const MobileScrollPadding(),
      ],
    );
  }

  Widget _buildHeroBanner({required bool isDark, required bool isOng}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF4C1D95), const Color(0xFF1E293B)]
              : [const Color(0xFF7C3AED), const Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurpleAccent.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.campaign_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOng
                      ? context.tr('acolhe.hero_events_ong')
                      : context.tr('acolhe.hero_events_tutor'),
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOng
                      ? context.tr('acolhe.hero_events_ong_desc')
                      : context.tr('acolhe.hero_events_tutor_desc'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    height: 1.3,
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
    required int totalEvents,
    required int upcomingEvents,
    required int adocaoEvents,
    required int totalAttendees,
  }) {
    final kpis = [
      _KpiData(
        title: context.tr('acolhe.kpi_upcoming_events'),
        value: upcomingEvents.toString(),
        icon: Icons.calendar_month_rounded,
        color: Colors.deepPurpleAccent,
      ),
      _KpiData(
        title: context.tr('acolhe.kpi_adoption_fairs'),
        value: adocaoEvents.toString(),
        icon: Icons.volunteer_activism_rounded,
        color: const Color(0xFF7C3AED),
      ),
      _KpiData(
        title: context.tr('acolhe.kpi_confirmed_rsvps'),
        value: totalAttendees.toString(),
        icon: Icons.people_alt_rounded,
        color: Colors.green,
      ),
      _KpiData(
        title: context.tr('acolhe.kpi_total_completed'),
        value: totalEvents.toString(),
        icon: Icons.check_circle_outline_rounded,
        color: Colors.blueAccent,
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

    // Mobile: Grade 2x2 para conforto e zero aperto
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildKpiCard(kpi: kpis[0], isDark: isDark)),
            const SizedBox(width: 10),
            Expanded(child: _buildKpiCard(kpi: kpis[1], isDark: isDark)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildKpiCard(kpi: kpis[2], isDark: isDark)),
            const SizedBox(width: 10),
            Expanded(child: _buildKpiCard(kpi: kpis[3], isDark: isDark)),
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
                    fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildTabsAndFilters({
    required bool isDark,
    required int upcomingCount,
  }) {
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
              color: isDark
                  ? const Color(0xFF6D28D9)
                  : Colors.deepPurpleAccent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: (isDark
                          ? const Color(0xFF6D28D9)
                          : Colors.deepPurpleAccent)
                      .withValues(alpha: isDark ? 0.35 : 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(context.tr('acolhe.tab_upcoming', {'count': '$upcomingCount'})),
                ),
              ),
              Tab(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(context.tr('acolhe.tab_history')),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Filtro por tipo
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('todos', context.tr('acolhe.filter_type_all'), isDark),
              const SizedBox(width: 6),
              _buildFilterChip('adocao', context.tr('acolhe.filter_type_adocao'), isDark),
              const SizedBox(width: 6),
              _buildFilterChip('bazar', context.tr('acolhe.filter_type_bazar'), isDark),
              const SizedBox(width: 6),
              _buildFilterChip('vacinacao', context.tr('acolhe.filter_type_vacinacao'), isDark),
              const SizedBox(width: 6),
              _buildFilterChip('encontro', context.tr('acolhe.filter_type_encontro'), isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label, bool isDark) {
    final isSelected = _selectedTypeFilter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? Colors.white
              : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
      selected: isSelected,
      selectedColor: Colors.deepPurpleAccent,
      backgroundColor:
          isDark ? const Color(0xFF1E293B) : Colors.white,
      side: BorderSide(
        color: isSelected
            ? Colors.deepPurpleAccent
            : (isDark ? Colors.white12 : Colors.grey.shade300),
      ),
      onSelected: (val) {
        if (val) setState(() => _selectedTypeFilter = value);
      },
    );
  }

  Widget _buildEventCard({
    required ShelterEvent event,
    required bool isDark,
    required bool isOng,
    required bool isDesktop,
  }) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    final dateStr =
        '${dateFormat.format(event.startDate)} às ${timeFormat.format(event.startDate)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner ou Cabeçalho com Badge
          if (event.bannerUrl != null && event.bannerUrl!.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(17)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  event.bannerUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.deepPurpleAccent.withValues(alpha: 0.15),
                    child: const Icon(
                      Icons.campaign_rounded,
                      size: 48,
                      color: Colors.deepPurpleAccent,
                    ),
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Linha de Badges (Tipo + Presenças)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: event.eventTypeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(event.eventTypeIcon,
                              size: 14, color: event.eventTypeColor),
                          const SizedBox(width: 4),
                          Text(
                            event.eventTypeLabel.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: event.eventTypeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_alt_rounded,
                              size: 13, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            context.tr('acolhe.confirmed_count', {'count': '${event.attendeesCount}'}),
                            style: const TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (isOng)
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: isDark ? Colors.white60 : Colors.black54,
                          size: 20,
                        ),
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : Colors.white,
                        onSelected: (val) {
                          if (val == 'edit') {
                            CreateShelterEventSheet.show(
                              context,
                              ongId: event.ongId,
                              eventToEdit: event,
                              onSaved: _loadEvents,
                            );
                          } else if (val == 'delete') {
                            _confirmDelete(event, isDark);
                          }
                        },
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_outlined, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  context.tr('acolhe.edit_event'),
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.darkBG,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_outline_rounded,
                                    size: 18, color: Colors.redAccent),
                                const SizedBox(width: 8),
                                Text(
                                  context.tr('acolhe.delete_event'),
                                  style: const TextStyle(color: Colors.redAccent),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Título
                Text(
                  event.title,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.darkBG,
                  ),
                ),
                const SizedBox(height: 8),

                // Data e Horário
                Row(
                  children: [
                    Icon(
                      Icons.event_rounded,
                      size: 16,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.darkBG,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Local e Endereço
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.place_rounded,
                      size: 16,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${event.locationName} • ${event.address}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Descrição
                Text(
                  event.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),

                // Botões de Ação
                Row(
                  children: [
                    // Botão de Presença (RSVP)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _toggleAttendance(event),
                        icon: Icon(
                          event.isUserAttending
                              ? Icons.check_circle_rounded
                              : Icons.celebration_rounded,
                          size: 16,
                        ),
                        label: Text(
                          event.isUserAttending
                              ? context.tr('acolhe.rsvp_attending')
                              : context.tr('acolhe.rsvp_attend_btn'),
                          style: const TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: event.isUserAttending
                              ? Colors.green
                              : Colors.deepPurpleAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Compartilhar WhatsApp
                    IconButton(
                      tooltip: context.tr('acolhe.share_whatsapp'),
                      onPressed: () => _shareEvent(event),
                      style: IconButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF0F172A)
                            : Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(
                        Icons.share_rounded,
                        size: 20,
                        color: Colors.green,
                      ),
                    ),

                    if (event.contactWhatsapp != null &&
                        event.contactWhatsapp!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: context.tr('acolhe.contact_whatsapp'),
                        onPressed: () =>
                            _openWhatsAppContact(event.contactWhatsapp!),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0xFF0F172A)
                              : Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 20,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required bool isDark, required bool isOng}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : Colors.deepPurpleAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_busy_rounded,
                size: 48,
                color: Colors.deepPurpleAccent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('acolhe.empty_events_title'),
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.darkBG,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isOng
                  ? context.tr('acolhe.empty_events_ong')
                  : context.tr('acolhe.empty_events_tutor'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black54,
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
