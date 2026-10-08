import 'package:flutter/material.dart';
import 'package:patas_web_app/core/localization/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/models/active_account_model.dart';
import 'package:patas_web_app/src/providers/active_account_provider.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:patas_web_app/src/common_widgets/mobile_scroll_padding.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import '../models/temporary_home_model.dart';
import '../models/shelter_animal_model.dart';
import '../services/shelter_service.dart';
import 'create_temporary_home_sheet.dart';
import 'assign_pet_to_home_sheet.dart';
import 'volunteer_temporary_home_sheet.dart';

class OngTemporaryHomesScreen extends StatefulWidget {
  final String? ongId;

  const OngTemporaryHomesScreen({super.key, this.ongId});

  @override
  State<OngTemporaryHomesScreen> createState() =>
      _OngTemporaryHomesScreenState();
}

class _OngTemporaryHomesScreenState extends State<OngTemporaryHomesScreen> {
  final ShelterService _service = ShelterService();

  bool _isLoading = true;
  List<TemporaryHome> _homes = [];
  String _selectedFilter = 'todos'; // 'todos', 'com_vagas', 'lotados', 'candidaturas'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadHomes();
  }

  String _getEffectiveOngId() {
    if (widget.ongId != null && widget.ongId!.isNotEmpty) {
      return widget.ongId!;
    }
    final activeAcc =
        Provider.of<ActiveAccountProvider>(context, listen: false).activeAccount;
    if (activeAcc?.type == AccountType.ong) {
      return activeAcc!.id;
    }
    return 'ong-1';
  }

  Future<void> _loadHomes() async {
    setState(() => _isLoading = true);
    final ongId = _getEffectiveOngId();
    final homes = await _service.getTemporaryHomes(ongId);

    if (mounted) {
      setState(() {
        _homes = homes;
        _isLoading = false;
      });
    }
  }

  Future<void> _openWhatsApp(String phone, String name) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final fullNumber = cleanPhone.startsWith('55') ? cleanPhone : '55$cleanPhone';
    final text = Uri.encodeComponent(
      'Olá $name! Entro em contato pela ONG pelo app Patas sobre o Lar Temporário. 🐾',
    );
    final url = 'https://wa.me/$fullNumber?text=$text';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível abrir o WhatsApp para $phone.')),
      );
    }
  }

  Future<void> _approveVolunteer(TemporaryHome home) async {
    final updated = home.copyWith(status: 'disponivel');
    final success = await _service.updateTemporaryHome(updated);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voluntário ${home.name} aprovado na rede de LTs! 🎉'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      _loadHomes();
    }
  }

  Future<void> _removeAnimalFromHome(
    ShelterAnimal animal,
    TemporaryHome home,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desocupar Lar Temporário?'),
        content: Text(
          'Deseja registrar o retorno de ${animal.name} do lar de ${home.name} para o abrigo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Confirmar Retorno',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ok = await _service.removeAnimalFromTemporaryHome(animal.id);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${animal.name} desocupado do lar temporário.'),
            backgroundColor: Colors.blueGrey,
          ),
        );
        _loadHomes();
      }
    }
  }

  Future<void> _deleteHome(TemporaryHome home) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Lar Temporário?'),
        content: Text(
          'Tem certeza que deseja remover ${home.name} da rede de LTs? Se houver pets vinculados, eles voltarão a ficar disponíveis no abrigo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ok = await _service.deleteTemporaryHome(home.id);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lar temporário removido.')),
        );
        _loadHomes();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    final activeAcc =
        Provider.of<ActiveAccountProvider>(context).activeAccount;
    final isOng = activeAcc?.type == AccountType.ong;

    return ResponsiveLayout(
      mobile: _buildMobileScaffold(context, isDark: isDark, isOng: isOng),
      desktop: _buildDesktopScaffold(context, isDark: isDark, isOng: isOng),
    );
  }

  // ─────────────────────────────────────────────
  // 📱 MOBILE LAYOUT
  // ─────────────────────────────────────────────

  Widget _buildMobileScaffold(
    BuildContext context, {
    required bool isDark,
    required bool isOng,
  }) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
      appBar: PatasEssencialAppBar(
        title: context.tr('acolhe.temp_homes_title'),
        subtitle: isOng
            ? context.tr('acolhe.temp_homes_sub_ong')
            : context.tr('acolhe.temp_homes_sub_tutor'),
        leadingIcon: const Icon(
          Icons.home_work_rounded,
          color: Colors.blueAccent,
          size: 22,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Atualizar',
            onPressed: _loadHomes,
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: context.isDesktop
              ? 20
              : (MediaQuery.paddingOf(context).bottom + 76),
        ),
        child: isOng
            ? FloatingActionButton.extended(
                heroTag: null,
                backgroundColor: Colors.blueAccent,
                icon: const Icon(Icons.person_add_alt_1_rounded,
                    color: Colors.white),
                label: Text(
                  context.tr('acolhe.new_volunteer'),
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  CreateTemporaryHomeSheet.show(
                    context,
                    ongId: _getEffectiveOngId(),
                    onSaved: _loadHomes,
                  );
                },
              )
            : FloatingActionButton.extended(
                heroTag: null,
                backgroundColor: Colors.blueAccent,
                icon: const Icon(Icons.volunteer_activism_rounded,
                    color: Colors.white),
                label: Text(
                  context.tr('acolhe.want_to_foster'),
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  VolunteerTemporaryHomeSheet.show(context);
                },
              ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHomes,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Banner contextual
                  _buildCommunityConnectionBanner(isDark, isOng: isOng),
                  const SizedBox(height: 16),

                  // Réguas de 4 KPIs em grade 2x2 (Regra OBRIGATÓRIA Mobile)
                  _buildKpisGrid(isDark, isMobile: true),
                  const SizedBox(height: 18),

                  // Filtros rápidos
                  _buildFilterChips(isDark),
                  const SizedBox(height: 14),

                  // Barra de busca
                  _buildSearchBar(isDark),
                  const SizedBox(height: 16),

                  // Lista de LTs
                  ..._buildHomesList(isDark, isOng: isOng),

                  const MobileScrollPadding(),
                ],
              ),
            ),
    );
  }

  // ─────────────────────────────────────────────
  // 💻 DESKTOP / TABLET LAYOUT
  // ─────────────────────────────────────────────

  Widget _buildDesktopScaffold(
    BuildContext context, {
    required bool isDark,
    required bool isOng,
  }) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadHomes,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 28,
                    ),
                    children: [
                      // Desktop Header com Breadcrumb e Ação
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: AppColors.patasColor,
                                      size: 20,
                                    ),
                                    onPressed: () => Navigator.maybePop(context),
                                    tooltip: context.tr('common.back'),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Patas Acolhe  /  Lares Temporários',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? const Color(0xFF93C5FD)
                                          : Colors.blueAccent,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isOng
                                    ? context.tr('acolhe.temp_homes_title')
                                    : context.tr('acolhe.temp_homes_title'),
                                style: TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.darkBG,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isOng
                                    ? 'Gerencie tutores voluntários da comunidade, vagas de acolhimento e hospede acolhidos.'
                                    : 'Conheça a rede de voluntários que acolhem temporariamente animais resgatados até a adoção.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: _loadHomes,
                                icon: Icon(
                                  Icons.refresh_rounded,
                                  size: 18,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                                label: Text(
                                  context.tr('common.update'),
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.darkBG,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.grey.shade300,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              isOng
                                  ? ElevatedButton.icon(
                                      onPressed: () {
                                        CreateTemporaryHomeSheet.show(
                                          context,
                                          ongId: _getEffectiveOngId(),
                                          onSaved: _loadHomes,
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.person_add_alt_1_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'Cadastrar Voluntário',
                                        style: TextStyle(
                                          fontFamily: 'Fredoka',
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blueAccent,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    )
                                  : ElevatedButton.icon(
                                      onPressed: () {
                                        VolunteerTemporaryHomeSheet.show(context);
                                      },
                                      icon: const Icon(
                                        Icons.volunteer_activism_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'Quero ser Lar Temporário 🏡',
                                        style: TextStyle(
                                          fontFamily: 'Fredoka',
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blueAccent,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Banner contextual
                      _buildCommunityConnectionBanner(isDark, isOng: isOng),
                      const SizedBox(height: 24),

                      // Réguas de 4 KPIs em 1 linha no Desktop
                      _buildKpisGrid(isDark, isMobile: false),
                      const SizedBox(height: 24),

                      // Barra de Filtros e Busca no Desktop
                      Row(
                        children: [
                          Expanded(child: _buildSearchBar(isDark)),
                          const SizedBox(width: 16),
                          _buildFilterChips(isDark),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Lista de LTs
                      ..._buildHomesList(isDark, isOng: isOng),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 🧩 BANNER DE CONEXÃO COM TUTORES COMUNS
  // ─────────────────────────────────────────────

  Widget _buildCommunityConnectionBanner(bool isDark, {required bool isOng}) {
    final pendingCount = _homes
        .where((h) => h.status == 'candidatura_pendente')
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFE8F1FC), const Color(0xFFF0F6FD)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blueAccent.withValues(alpha: isDark ? 0.4 : 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOng
                  ? Icons.connect_without_contact_rounded
                  : Icons.volunteer_activism_rounded,
              color: isDark ? const Color(0xFF93C5FD) : Colors.blueAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOng
                      ? context.tr('acolhe.banner_conn_title_ong')
                      : context.tr('acolhe.banner_conn_title_tutor'),
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : AppColors.darkBG,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isOng
                      ? (pendingCount > 0
                          ? context.tr('acolhe.banner_conn_desc_ong_pending', {'count': '$pendingCount'})
                          : context.tr('acolhe.banner_conn_desc_ong_empty'))
                      : context.tr('acolhe.banner_conn_desc_tutor'),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (isOng && pendingCount > 0)
            ElevatedButton(
              onPressed: () {
                setState(() => _selectedFilter = 'candidaturas');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                context.tr('acolhe.view_pending_count', {'count': '$pendingCount'}),
                style: const TextStyle(
                  fontFamily: 'Fredoka',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            )
          else if (!isOng)
            ElevatedButton.icon(
              onPressed: () {
                VolunteerTemporaryHomeSheet.show(context);
              },
              icon: const Icon(Icons.favorite_rounded,
                  size: 16, color: Colors.white),
              label: Text(
                context.tr('acolhe.apply_volunteer'),
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 📊 RÉGUA DE KPIS (GRADE 2x2 NO MOBILE)
  // ─────────────────────────────────────────────

  Widget _buildKpisGrid(bool isDark, {required bool isMobile}) {
    final totalHomes = _homes.length;
    final totalFreeSpots =
        _homes.fold<int>(0, (sum, h) => sum + h.freeSpots);
    final totalAnimalsInHomes =
        _homes.fold<int>(0, (sum, h) => sum + h.occupiedSpots);
    final pendingCount = _homes
        .where((h) => h.status == 'candidatura_pendente')
        .length;

    final kpi1 = _buildKpiCard(
      title: context.tr('acolhe.kpi_total_homes'),
      value: '$totalHomes',
      subtitle: context.tr('acolhe.kpi_sub_active_volunteers'),
      icon: Icons.home_work_rounded,
      color: Colors.blueAccent,
      isDark: isDark,
    );

    final kpi2 = _buildKpiCard(
      title: context.tr('acolhe.kpi_free_spots'),
      value: '$totalFreeSpots',
      subtitle: context.tr('acolhe.kpi_sub_available_now'),
      icon: Icons.event_seat_rounded,
      color: Colors.teal,
      isDark: isDark,
    );

    final kpi3 = _buildKpiCard(
      title: context.tr('acolhe.kpi_pets_in_foster'),
      value: '$totalAnimalsInHomes',
      subtitle: context.tr('acolhe.kpi_sub_sheltered_hosted'),
      icon: Icons.pets_rounded,
      color: Colors.orange,
      isDark: isDark,
    );

    final kpi4 = _buildKpiCard(
      title: context.tr('acolhe.kpi_applications'),
      value: '$pendingCount',
      subtitle: context.tr('acolhe.kpi_sub_community_tutors'),
      icon: Icons.volunteer_activism_rounded,
      color: pendingCount > 0 ? Colors.purpleAccent : Colors.grey,
      isDark: isDark,
    );

    if (isMobile) {
      // Regra OBRIGATÓRIA Mobile: Grade 2x2 (2 linhas com 2 cards)
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: kpi1),
              const SizedBox(width: 10),
              Expanded(child: kpi2),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: kpi3),
              const SizedBox(width: 10),
              Expanded(child: kpi4),
            ],
          ),
        ],
      );
    }

    // Desktop: 1 linha com 4 colunas contidas
    return Row(
      children: [
        Expanded(child: kpi1),
        const SizedBox(width: 16),
        Expanded(child: kpi2),
        const SizedBox(width: 16),
        Expanded(child: kpi3),
        const SizedBox(width: 16),
        Expanded(child: kpi4),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.darkBG,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 🔍 BUSCA E FILTROS
  // ─────────────────────────────────────────────

  Widget _buildSearchBar(bool isDark) {
    return TextField(
      onChanged: (val) => setState(() => _searchQuery = val),
      style: TextStyle(
        fontSize: 13.5,
        color: isDark ? Colors.white : AppColors.darkBG,
      ),
      decoration: InputDecoration(
        hintText: context.tr('acolhe.search_temp_homes_hint'),
        hintStyle: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 20,
          color: isDark ? Colors.white60 : Colors.black54,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.blueAccent,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    final filters = [
      {'key': 'todos', 'label': context.tr('acolhe.filter_chip_all')},
      {'key': 'com_vagas', 'label': context.tr('acolhe.filter_chip_with_spots')},
      {'key': 'lotados', 'label': context.tr('acolhe.filter_chip_full')},
      {'key': 'candidaturas', 'label': context.tr('acolhe.filter_chip_applications')},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(f['label']!),
              labelStyle: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
              selectedColor: Colors.blueAccent,
              backgroundColor:
                  isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? Colors.transparent
                      : (isDark ? Colors.white12 : Colors.grey.shade300),
                ),
              ),
              onSelected: (_) {
                setState(() => _selectedFilter = f['key']!);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 📋 LISTA DE LARES TEMPORÁRIOS
  // ─────────────────────────────────────────────

  List<Widget> _buildHomesList(bool isDark, {required bool isOng}) {
    final filtered = _homes.where((h) {
      if (_selectedFilter == 'com_vagas' && h.freeSpots <= 0) return false;
      if (_selectedFilter == 'lotados' && !h.isFull) return false;
      if (_selectedFilter == 'candidaturas' &&
          h.status != 'candidatura_pendente') {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = h.name.toLowerCase().contains(q);
        final matchPhone = h.phone.contains(q);
        final matchCity = h.city?.toLowerCase().contains(q) ?? false;
        final matchNeighborhood =
            h.neighborhood?.toLowerCase().contains(q) ?? false;
        return matchName || matchPhone || matchCity || matchNeighborhood;
      }

      return true;
    }).toList();

    if (filtered.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(
              children: [
                Icon(
                  Icons.home_work_outlined,
                  size: 54,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
                const SizedBox(height: 14),
                Text(
                  _homes.isEmpty
                      ? context.tr('acolhe.empty_temp_homes_title')
                      : context.tr('acolhe.empty_temp_homes_filter_title'),
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.darkBG,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _homes.isEmpty
                      ? (isOng
                          ? context.tr('acolhe.empty_temp_homes_desc_ong')
                          : context.tr('acolhe.empty_temp_homes_desc_tutor'))
                      : context.tr('acolhe.empty_temp_homes_filter_desc'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return filtered
        .map((home) => _buildHomeCard(home, isDark, isOng: isOng))
        .toList();
  }

  Widget _buildHomeCard(TemporaryHome home, bool isDark, {required bool isOng}) {
    final isPending = home.status == 'candidatura_pendente';
    final occupancyPercent =
        home.maxCapacity > 0 ? (home.occupiedSpots / home.maxCapacity) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPending
              ? Colors.purpleAccent.withValues(alpha: 0.5)
              : (isDark ? Colors.white12 : Colors.grey.shade300),
          width: isPending ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do Card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
            child: Row(
              children: [
                // Ícone do lar
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: home.statusColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    home.isCommunityVolunteer
                        ? Icons.volunteer_activism_rounded
                        : Icons.home_rounded,
                    color: home.statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Nome e Badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              home.name,
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.darkBG,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (home.isCommunityVolunteer)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    Colors.purpleAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.purpleAccent
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                context.tr('acolhe.volunteer_tutor_badge'),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purpleAccent,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            [
                              if (home.neighborhood != null) home.neighborhood!,
                              if (home.city != null) home.city!,
                            ].join(', ').isNotEmpty
                                ? [
                                    if (home.neighborhood != null)
                                      home.neighborhood!,
                                    if (home.city != null) home.city!,
                                  ].join(', ')
                                : context.tr('acolhe.unspecified_address'),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Badge de Status do Lar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: home.statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    home.statusLabel,
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: home.statusColor,
                    ),
                  ),
                ),

                // Menu de Ações (Apenas para ONG)
                if (isOng)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: 20,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    color:
                        isDark ? const Color(0xFF1E293B) : Colors.white,
                    onSelected: (val) {
                      if (val == 'edit') {
                        CreateTemporaryHomeSheet.show(
                          context,
                          ongId: _getEffectiveOngId(),
                          homeToEdit: home,
                          onSaved: _loadHomes,
                        );
                      } else if (val == 'delete') {
                        _deleteHome(home);
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined,
                                size: 18,
                                color: isDark ? Colors.white70 : Colors.black87),
                            const SizedBox(width: 8),
                            Text(context.tr('acolhe.edit_volunteer'),
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.darkBG)),
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
                            Text(context.tr('acolhe.delete_home'),
                                style: const TextStyle(color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Informações de Acomodação
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chips de Características
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildInfoBadge(
                      Icons.home_outlined,
                      home.housingType.toUpperCase(),
                      isDark,
                    ),
                    if (home.hasYard)
                      _buildInfoBadge(
                        Icons.fence_rounded,
                        context.tr('acolhe.secure_yard_tag'),
                        isDark,
                      ),
                    _buildInfoBadge(
                      Icons.pets_rounded,
                      context.tr('acolhe.accepts_species_tag', {'species': home.speciesLabel}),
                      isDark,
                    ),
                    if (home.canAdministerMedication)
                      _buildInfoBadge(
                        Icons.medication_rounded,
                        context.tr('acolhe.gives_meds_tag'),
                        isDark,
                      ),
                    if (home.hasOtherPets)
                      _buildInfoBadge(
                        Icons.groups_rounded,
                        context.tr('acolhe.has_other_pets_tag'),
                        isDark,
                      ),
                  ],
                ),

                const SizedBox(height: 14),

                // Barra de Ocupação de Vagas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr('acolhe.capacity_label', {'occupied': '${home.occupiedSpots}', 'max': '${home.maxCapacity}'}),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    Text(
                      home.freeSpots > 0
                          ? context.tr('acolhe.spots_available_label', {'count': '${home.freeSpots}'})
                          : context.tr('acolhe.spots_full_label'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: home.freeSpots > 0
                            ? (isDark ? Colors.tealAccent : Colors.teal)
                            : Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: occupancyPercent.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor:
                        isDark ? Colors.white12 : Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      home.isFull
                          ? Colors.orange
                          : (occupancyPercent > 0.5
                              ? Colors.blueAccent
                              : Colors.teal),
                    ),
                  ),
                ),

                // Se houver pets hospedados neste lar
                if (home.currentAnimals.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    context.tr('acolhe.currently_hosted_pets'),
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: isDark
                          ? const Color(0xFF93C5FD)
                          : const Color(0xFF1D4ED8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: home.currentAnimals.map((pet) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F3F5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? Colors.white12
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundImage: (pet.photoUrl != null &&
                                      pet.photoUrl!.isNotEmpty)
                                  ? NetworkImage(pet.photoUrl!)
                                  : null,
                              child: (pet.photoUrl == null ||
                                      pet.photoUrl!.isEmpty)
                                  ? const Icon(Icons.pets_rounded, size: 12)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              pet.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.darkBG,
                              ),
                            ),
                            if (isOng) ...[
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => _removeAnimalFromHome(pet, home),
                                borderRadius: BorderRadius.circular(12),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // Se houver notas/observações
                if (home.notes != null && home.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.grey.shade200,
                      ),
                    ),
                    child: Text(
                      'Obs: ${home.notes!}',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1),

          // Botões de Ação no Rodapé
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: isPending
                ? Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openWhatsApp(home.phone, home.name),
                          icon: const Icon(Icons.chat_bubble_outline_rounded,
                              size: 16),
                          label: Text(context.tr('acolhe.interview_zap')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark
                                ? Colors.greenAccent
                                : Colors.green.shade700,
                            side: BorderSide(
                              color: isDark
                                  ? Colors.greenAccent
                                  : Colors.green.shade700,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      if (isOng) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _approveVolunteer(home),
                            icon: const Icon(Icons.check_rounded,
                                size: 16, color: Colors.white),
                            label: Text(
                              context.tr('acolhe.approve_home'),
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purpleAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  )
                : Row(
                    children: [
                      // Botão WhatsApp
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openWhatsApp(home.phone, home.name),
                          icon: Icon(
                            Icons.chat_rounded,
                            size: 16,
                            color: isDark
                                ? Colors.greenAccent
                                : Colors.green.shade700,
                          ),
                          label: Text(
                            'WhatsApp',
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              color: isDark
                                  ? Colors.greenAccent
                                  : Colors.green.shade700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark
                                  ? Colors.greenAccent
                                  : Colors.green.shade700,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      if (isOng) ...[
                        const SizedBox(width: 12),
                        // Botão Hospedar Pet (apenas para ONG)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: home.isFull
                                ? null
                                : () async {
                                    final res = await AssignPetToHomeSheet.show(
                                      context,
                                      home: home,
                                      ongId: _getEffectiveOngId(),
                                    );
                                    if (res == true) _loadHomes();
                                  },
                            icon: const Icon(Icons.pets_rounded,
                                size: 16, color: Colors.white),
                            label: Text(
                              home.isFull ? context.tr('acolhe.home_full_btn') : context.tr('acolhe.host_pet_btn'),
                              style: const TextStyle(
                                fontFamily: 'Fredoka',
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.patasColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
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

  Widget _buildInfoBadge(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
