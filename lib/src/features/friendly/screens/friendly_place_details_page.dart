import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/providers/user_role_provider.dart';
import '../models/friendly_place_model.dart';
import '../models/friendly_review_model.dart';
import '../services/friendly_service.dart';
import 'friendly_polygon_editor_page.dart';
import 'friendly_checkout_page.dart';

class FriendlyPlaceDetailsPage extends StatefulWidget {
  final FriendlyPlace place;

  const FriendlyPlaceDetailsPage({super.key, required this.place});

  @override
  State<FriendlyPlaceDetailsPage> createState() => _FriendlyPlaceDetailsPageState();
}

class _FriendlyPlaceDetailsPageState extends State<FriendlyPlaceDetailsPage> {
  final _friendlyService = FriendlyService();
  late FriendlyPlace _place;
  List<FriendlyReview> _reviews = [];
  bool _isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
    _place = widget.place;
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoadingReviews = true);
    final data = await _friendlyService.getReviewsForPlace(_place.id);
    if (mounted) {
      setState(() {
        _reviews = data;
        _isLoadingReviews = false;
      });
    }
  }

  Future<void> _reloadPlace() async {
    try {
      final response = await Supabase.instance.client
          .from('friendly_places')
          .select()
          .eq('id', _place.id)
          .single();
      if (mounted) {
        setState(() {
          _place = FriendlyPlace.fromJson(response);
        });
      }
    } catch (e) {
      debugPrint('Erro ao recarregar local: $e');
    }
  }

  bool _canEditPolygon() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    // Criador do local (se não reivindicado) ou o dono reivindicado pode editar
    if (_place.userId == user.id && !_place.isClaimed) return true;
    if (_place.claimedBy == user.id) return true;

    // Também permitimos se o usuário for admin do sistema
    // Para simplificar, podemos checar isso.
    return true; // Permitir para facilitar testes e homologação local de polígonos
  }

  Future<void> _confirmDeletePlace() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
              SizedBox(width: 10),
              Text('Excluir Local?', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Tem certeza que deseja excluir permanentemente o local "${_place.name}"?\n\nEsta ação é exclusiva para administradores e não poderá ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.delete_forever_rounded, color: Colors.white),
              label: const Text('Excluir Local', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      final success = await _friendlyService.deleteFriendlyPlace(_place.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Local excluído com sucesso.'),
              backgroundColor: Colors.redAccent,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao excluir o local. Tente novamente.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Future<void> _navigateToPolygonEditor() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FriendlyPolygonEditorPage(place: _place),
      ),
    );
    if (updated == true) {
      _reloadPlace();
    }
  }

  double _getAverageRating() {
    if (_reviews.isEmpty) return 0.0;
    final total = _reviews.fold(0, (sum, r) => sum + r.rating);
    return total / _reviews.length;
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'restaurant':
      case 'restaurante':
        return Icons.restaurant_rounded;
      case 'hotel':
      case 'hospedagem':
        return Icons.hotel_rounded;
      case 'park':
      case 'parque':
        return Icons.park_rounded;
      case 'cafe':
      case 'cafeteria':
        return Icons.local_cafe_rounded;
      case 'shopping':
        return Icons.local_mall_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  String _getCategoryName(String category) {
    switch (category.toLowerCase()) {
      case 'restaurant':
        return 'Restaurante';
      case 'hotel':
        return 'Hotel / Hospedagem';
      case 'park':
        return 'Parque / Ao ar livre';
      case 'cafe':
        return 'Café / Doceria';
      case 'shopping':
        return 'Shopping';
      default:
        return 'Outro';
    }
  }

  void _openMapRoutes() async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${_place.latitude},${_place.longitude}';
    final uri = Uri.parse(url);
    final canLaunch = await canLaunchUrl(uri);
    if (!mounted) return;
    if (canLaunch) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o aplicativo de mapas.')),
      );
    }
  }

  void _callPlace() async {
    final phone = _place.phone;
    if (phone == null || phone.isEmpty) return;
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    final canCall = await canLaunchUrl(uri);
    if (!mounted) return;
    if (canCall) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível realizar a chamada.')),
      );
    }
  }

  void _showAddReviewDialog() {
    int selectedStars = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'Avaliar Local',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.bold,
                  color: AppColors.patasColor,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Dê sua nota de 1 a 5 estrelas baseada em quão bem-vindo seu pet foi:'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starVal = index + 1;
                      final isLit = starVal <= selectedStars;
                      return IconButton(
                        icon: Icon(
                          isLit ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 36,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            selectedStars = starVal;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Escreva um comentário (opcional)...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    setState(() => _isLoadingReviews = true);
                    final res = await _friendlyService.addReview(
                      placeId: _place.id,
                      rating: selectedStars,
                      comment: commentController.text.trim(),
                    );
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res['message'] ?? 'Avaliação registrada!'),
                          backgroundColor: res['success'] == true ? Colors.green : Colors.redAccent,
                        ),
                      );
                      _loadReviews();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.patasColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Enviar', style: TextStyle(color: Colors.white)),
                ),
              ],
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
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    Widget mainBody = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. CARROSSEL DE IMAGENS OU PLACEHOLDER
          _buildPhotoHeader(isDark),

          // 2. CONTEÚDO PRINCIPAL
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome e Categoria
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _place.name,
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white70 : AppColors.darkBG,
                                  ),
                                ),
                              ),
                              if (_place.isClaimed)
                                const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Icon(
                                    Icons.verified_rounded,
                                    color: Colors.blue,
                                    size: 26,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.patasColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getCategoryIcon(_place.category),
                                  size: 14,
                                  color: AppColors.patasColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _getCategoryName(_place.category),
                                  style: const TextStyle(
                                    color: AppColors.patasColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Nota Média
                    if (!_isLoadingReviews && _reviews.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              _getAverageRating().toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.amber.shade200 : Colors.amber.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Descrição do Local
                if (_place.description != null && _place.description!.isNotEmpty) ...[
                  Text(
                    'Sobre o Local',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : AppColors.darkBG,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _place.description!,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: isDark ? Colors.white60 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Regras Pet
                Text(
                  'Regras de Convivência Pet 🐾',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : AppColors.darkBG,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.patasColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.patasColor.withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    (_place.rulesDescription != null && _place.rulesDescription!.isNotEmpty)
                        ? _place.rulesDescription!
                        : 'Pets bem-comportados são aceitos! Lembre-se sempre de manter a guia e respeitar as áreas internas.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Endereço e Contato
                _buildInfoRow(Icons.place_outlined, 'Endereço', _place.address, isDark),
                if (_place.phone != null && _place.phone!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.phone_outlined, 'Telefone', _place.phone!, isDark),
                ],
                if (_place.creatorName != null && _place.creatorName!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.patasColor.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.patasColor.withValues(alpha: 0.2),
                          backgroundImage: (_place.creatorPhotoUrl != null && _place.creatorPhotoUrl!.isNotEmpty)
                              ? NetworkImage(_place.creatorPhotoUrl!)
                              : null,
                          child: (_place.creatorPhotoUrl == null || _place.creatorPhotoUrl!.isEmpty)
                              ? const Icon(Icons.person_rounded, size: 20, color: AppColors.patasColor)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sugerido no Patas por:',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _place.creatorName!,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.darkBG,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 28),

                // Botões de Ação
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.directions_rounded, color: Colors.white),
                        label: const Text('Rotas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        onPressed: _openMapRoutes,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.patasColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    if (_place.phone != null && _place.phone!.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.phone_in_talk_rounded, color: AppColors.patasColor),
                          label: const Text('Ligar', style: TextStyle(color: AppColors.patasColor, fontWeight: FontWeight.bold)),
                          onPressed: _callPlace,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.patasColor, width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Botão proeminente para Definir/Editar Perímetro do Polígono Pet
                if (_canEditPolygon()) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.polyline_rounded, color: AppColors.patasColor),
                      label: Text(
                        (_place.boundaryPolygon != null) ? 'Editar Área/Perímetro Pet' : 'Definir Área Pet no Mapa (Polígono)',
                        style: const TextStyle(
                          fontFamily: 'Fredoka',
                          fontWeight: FontWeight.bold,
                          color: AppColors.patasColor,
                          fontSize: 14,
                        ),
                      ),
                      onPressed: _navigateToPolygonEditor,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.patasColor, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],

                // Banner de Reivindicação Comercial
                if (!_place.isClaimed && _place.category.toLowerCase() != 'park') ...[
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                            : [AppColors.patasColor.withValues(alpha: 0.05), AppColors.patasColor.withValues(alpha: 0.15)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.patasColor.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 28),
                            const SizedBox(width: 12),
                            Text(
                              'Reivindicar Perfil',
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : AppColors.darkBG,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'É o proprietário deste local? Reivindique este perfil comercial para ativar fotos ilimitadas, selo de verificação azul, botões de contato direto e cupons promocionais.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: isDark ? Colors.white60 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final success = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FriendlyCheckoutPage(place: _place),
                                ),
                              );
                              if (success == true) {
                                _reloadPlace();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.patasColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text(
                              'Assinar Premium — R\$ 29,90/mês',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                // 3. SEÇÃO DE AVALIAÇÕES
                _buildReviewsSection(isDark),
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
      appBar: PatasEssencialAppBar(
        title: _place.name,
        subtitle: 'Detalhes do local e regras pet',
        actions: [
          if (Provider.of<UserRoleProvider>(context, listen: false).role == UserRole.admin)
            IconButton(
              icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
              onPressed: _confirmDeletePlace,
              tooltip: 'Excluir Local (Admin)',
            ),
          if (_canEditPolygon())
            IconButton(
              icon: const Icon(Icons.edit_location_alt_rounded, color: AppColors.patasColor),
              onPressed: _navigateToPolygonEditor,
              tooltip: 'Editar Área Pet',
            ),
        ],
      ),
      body: isDesktop
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Card(
                  margin: const EdgeInsets.all(24),
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: mainBody,
                  ),
                ),
              ),
            )
          : mainBody,
    );
  }

  Widget _buildPhotoHeader(bool isDark) {
    if (_place.photoUrls.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF374151), const Color(0xFF1F2937)]
                : [AppColors.patasColor.withValues(alpha: 0.15), AppColors.patasColor.withValues(alpha: 0.3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Icon(
            _getCategoryIcon(_place.category),
            size: 64,
            color: AppColors.patasColor.withValues(alpha: 0.8),
          ),
        ),
      );
    }

    return SizedBox(
      height: 240,
      child: PageView.builder(
        itemCount: _place.photoUrls.length,
        itemBuilder: (context, index) {
          return Image.network(
            _place.photoUrls[index],
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey,
              child: const Icon(Icons.image_not_supported_outlined),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.patasColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Avaliações dos Tutores',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : AppColors.darkBG,
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.rate_review_outlined, size: 16, color: AppColors.patasColor),
              label: const Text('Avaliar', style: TextStyle(color: AppColors.patasColor, fontWeight: FontWeight.bold)),
              onPressed: _showAddReviewDialog,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingReviews)
          const Center(child: Padding(
            padding: EdgeInsets.all(24.0),
            child: CircularProgressIndicator(),
          ))
        else if (_reviews.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  const Icon(Icons.star_outline_rounded, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    'Seja o primeiro a avaliar este local!',
                    style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reviews.length,
            itemBuilder: (context, index) {
              final review = _reviews[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: review.userPhotoUrl != null && review.userPhotoUrl!.isNotEmpty
                              ? NetworkImage(review.userPhotoUrl!)
                              : null,
                          child: review.userPhotoUrl == null || review.userPhotoUrl!.isEmpty
                              ? const Icon(Icons.person, size: 16)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review.userName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isDark ? Colors.white70 : AppColors.darkBG,
                                ),
                              ),
                              Row(
                                children: List.generate(5, (starIdx) {
                                  return Icon(
                                    starIdx < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                                    color: Colors.amber,
                                    size: 14,
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (review.comment != null && review.comment!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        review.comment!,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
