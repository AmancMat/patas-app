import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import '../../../../app.dart';
import '../../../constants/app_colors.dart';
import '../../pets/active_pet_provider.dart';
import '../../home/timeline/services/post_service.dart';
import '../../love/services/patas_love_service.dart';
import '../models/patas_historica_models.dart';
import '../widgets/timeline_ruler_widget.dart';

class PatasHistoricaPage extends StatefulWidget {
  const PatasHistoricaPage({super.key});

  @override
  State<PatasHistoricaPage> createState() => _PatasHistoricaPageState();
}

class _PatasHistoricaPageState extends State<PatasHistoricaPage> {
  TimelineGranularity _granularity = TimelineGranularity.months;
  double _zoomLevel = 1.0;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _commentController = TextEditingController();

  // Dados de teste com mídias e momentos do pet
  final List<TimelineEvent> _mockEvents = [
    TimelineEvent(
      id: '1',
      petId: 'pet1',
      date: DateTime(2026, 8, 1),
      title: 'Chegada na Nova Família 🏠',
      description:
          'O dia mais feliz! Cheguei ao meu novo lar com muito carinho e petiscos deliciosos.',
      mediaUrls: ['assets/logo.png'],
      comments: [
        TimelineComment(
          id: 'c1',
          userName: 'Ana Maria',
          userAvatar: '',
          commentText: 'Coisa mais linda! Já amamos demais! ❤️',
          createdAt: DateTime(2026, 8, 1),
        ),
        TimelineComment(
          id: 'c2',
          userName: 'Pedro Henrique',
          userAvatar: '',
          commentText: 'Muito fofo! 🐶',
          createdAt: DateTime(2026, 8, 1),
        ),
      ],
    ),
    TimelineEvent(
      id: '2',
      petId: 'pet1',
      date: DateTime(2026, 6, 15),
      title: 'Primeiro Banho no Petshop 🛁',
      description: 'Fiquei super cheiroso e brinquei na água durante o banho!',
      mediaUrls: ['assets/logo.png'],
      isVideo: true,
      comments: [
        TimelineComment(
          id: 'c3',
          userName: 'Carlos Vet',
          userAvatar: '',
          commentText: 'Foi nota 10 no comportamento! 🧼',
          createdAt: DateTime(2026, 6, 15),
        ),
      ],
    ),
    TimelineEvent(
      id: '3',
      petId: 'pet1',
      date: DateTime(2025, 12, 25),
      title: 'Primeiro Natal Juntos 🎄',
      description:
          'Ganhei vários brinquedos novos do Papai Noel e comi petiscos especiais.',
      mediaUrls: ['assets/logo.png'],
      comments: [],
    ),
    TimelineEvent(
      id: '4',
      petId: 'pet1',
      date: DateTime(2025, 4, 10),
      title: 'Primeira Viagem ao Parque 🌳',
      description:
          'Corri na grama, fiz novos amigos caninos e me diverti pra valer!',
      mediaUrls: ['assets/logo.png'],
      comments: [
        TimelineComment(
          id: 'c4',
          userName: 'Juliana',
          userAvatar: '',
          commentText: 'Adorou correr livre! 🐾',
          createdAt: DateTime(2025, 4, 10),
        ),
      ],
    ),
    TimelineEvent(
      id: '5',
      petId: 'pet1',
      date: DateTime(2026, 5, 20),
      title: 'Encontro Confirmado com Luna 💕',
      description:
          'Encontro maravilhoso registrado pelo Patas Love! Conexão especial entre os pets.',
      mediaUrls: ['assets/logo.png'],
      isLoveMilestone: true,
      partnerPetId: 'pet2',
      partnerPetName: 'Luna',
      partnerPetPhotoUrl: 'assets/logo.png',
      partnerPetBreed: 'Golden Retriever',
      comments: [
        TimelineComment(
          id: 'c5',
          userName: 'Tutor da Luna',
          userAvatar: '',
          commentText: 'Foi um encontro incrível! Brincaram a tarde toda 💕',
          createdAt: DateTime(2026, 5, 20),
        ),
      ],
    ),
  ];

  bool _isLoading = true;
  List<TimelineEvent> _timelineEvents = [];
  DateTime _minDate = DateTime(2025, 1, 1);
  DateTime _maxDate = DateTime(2026, 12, 31);

  @override
  void initState() {
    super.initState();
    // Permitir rotação em modo horizontal (paisagem) EXCLUSIVAMENTE nesta tela
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPetPostsFromSupabase();
    });
  }

  Future<void> _loadPetPostsFromSupabase() async {
    final activePet = Provider.of<ActivePetProvider>(
      context,
      listen: false,
    ).activePet;

    if (activePet == null) {
      _useMockFallback();
      return;
    }

    try {
      // 1. Carrega posts do feed do pet
      final posts = await PostService().getPostsByPetId(activePet.id);
      final List<TimelineEvent> postEvents = posts.map((post) {
        final titleStr = post.content.trim().isNotEmpty
            ? (post.content.length > 30
                  ? '${post.content.substring(0, 30)}...'
                  : post.content)
            : 'Memória do Pet 🐾';

        final mediaUrl = (post.imageUrl != null && post.imageUrl!.isNotEmpty)
            ? post.imageUrl!
            : ((post.videoThumbnailUrl != null &&
                      post.videoThumbnailUrl!.isNotEmpty)
                  ? post.videoThumbnailUrl!
                  : 'assets/logo.png');

        return TimelineEvent(
          id: post.id,
          petId: post.petId ?? activePet.id,
          date: post.createdAt,
          title: titleStr,
          description: post.content,
          mediaUrls: [mediaUrl],
          isVideo: post.isVideo,
          comments: [],
        );
      }).toList();

      // 2. Carrega encontros confirmados do Patas Love (marcos afetivos)
      final meets = await PatasLoveService().getConfirmedMeetsForPet(activePet.id);
      final List<TimelineEvent> meetEvents = [];
      for (final meet in meets) {
        final isPetA = meet['pet_a_id'] == activePet.id;
        final partnerData = isPetA ? meet['pet_b'] : meet['pet_a'];
        final partnerName = partnerData != null && partnerData['name'] != null
            ? partnerData['name'] as String
            : 'Amigo Pet';
        final partnerBreed = partnerData != null && partnerData['breed'] != null
            ? partnerData['breed'] as String
            : '';
        final partnerPhoto = partnerData != null && partnerData['photo_url'] != null
            ? partnerData['photo_url'] as String
            : '';
        final meetPhoto = (meet['photo_url'] != null && (meet['photo_url'] as String).isNotEmpty)
            ? meet['photo_url'] as String
            : partnerPhoto;

        DateTime confirmedDate;
        try {
          confirmedDate = DateTime.parse(meet['confirmed_at'] as String);
        } catch (_) {
          confirmedDate = DateTime.now();
        }

        meetEvents.add(
          TimelineEvent(
            id: 'meet_${meet['id']}',
            petId: activePet.id,
            date: confirmedDate,
            title: 'Encontro Marcado com $partnerName 💕',
            description: meet['notes'] != null && (meet['notes'] as String).isNotEmpty
                ? meet['notes'] as String
                : 'Momento especial registrado através do Patas Love! ${activePet.name} e $partnerName se encontraram na vida real.',
            mediaUrls: [meetPhoto.isNotEmpty ? meetPhoto : 'assets/logo.png'],
            isVideo: false,
            comments: [],
            isLoveMilestone: true,
            partnerPetId: isPetA ? meet['pet_b_id'] : meet['pet_a_id'],
            partnerPetName: partnerName,
            partnerPetPhotoUrl: partnerPhoto,
            partnerPetBreed: partnerBreed,
          ),
        );
      }

      // 3. Mescla e ordena todos os eventos cronologicamente
      final List<TimelineEvent> allEvents = [...postEvents, ...meetEvents];

      if (allEvents.isNotEmpty) {
        allEvents.sort((a, b) => a.date.compareTo(b.date));

        DateTime firstDate = allEvents.first.date;
        DateTime lastDate = allEvents.last.date;

        // Se houver apenas 1 post ou intervalo muito curto, dá uma margem mínima
        if (lastDate.difference(firstDate).inDays < 30) {
          firstDate = DateTime(firstDate.year, firstDate.month - 2, 1);
          lastDate = DateTime(lastDate.year, lastDate.month + 2, 1);
        } else {
          firstDate = DateTime(firstDate.year, firstDate.month - 1, 1);
          lastDate = DateTime(lastDate.year, lastDate.month + 1, 1);
        }

        if (mounted) {
          setState(() {
            _timelineEvents = allEvents;
            _minDate = firstDate;
            _maxDate = lastDate;
            _isLoading = false;
          });
        }
      } else {
        _useMockFallback();
      }
    } catch (e) {
      debugPrint('Erro ao carregar posts e encontros do pet no Supabase: $e');
      _useMockFallback();
    }
  }

  void _useMockFallback() {
    if (mounted) {
      setState(() {
        _timelineEvents = _mockEvents;
        _minDate = DateTime(2025, 1, 1);
        _maxDate = DateTime(2026, 12, 31);
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commentController.dispose();
    // Bloquear a rotação horizontal ao sair, mantendo o restante do app apenas em Retrato
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _showMediaExpandModal(BuildContext context, TimelineEvent event) {
    final thmode = Provider.of<DarkMode>(context, listen: false);
    final isDark = thmode.darkMode;

    final bgColor = isDark ? AppColors.darkBG : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.darkBG;
    final subtitleColor = isDark ? Colors.white70 : Colors.black87;

    final dateStr =
        '${event.date.day.toString().padLeft(2, '0')}/${event.date.month.toString().padLeft(2, '0')}/${event.date.year}';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 600,
                  maxHeight: 750,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.2),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    children: [
                      // Header com título e fechar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.patasColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                dateStr,
                                style: const TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                event.title,
                                style: TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close_rounded, color: textColor),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),

                      // Imagem ou Vídeo Expandido
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                height: 260,
                                color: isDark
                                    ? Colors.black26
                                    : Colors.grey.shade200,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    _buildMediaImage(
                                      event.mediaUrls.isNotEmpty
                                          ? event.mediaUrls.first
                                          : '',
                                      width: double.infinity,
                                      height: 260,
                                      fit: BoxFit.cover,
                                    ),
                                    if (event.isVideo)
                                      Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.55,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 40,
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Descrição
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.description,
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.5,
                                        color: subtitleColor,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    const Divider(),
                                    const SizedBox(height: 8),

                                    // Área de Comentários / Memórias da Família
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.favorite_rounded,
                                          color: Colors.pinkAccent,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Memórias & Comentários (${event.comments.length})',
                                          style: TextStyle(
                                            fontFamily: 'Fredoka',
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    if (event.comments.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        child: Text(
                                          'Nenhum comentário ainda. Seja o primeiro a registrar uma memória!',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            color: isDark
                                                ? Colors.white38
                                                : Colors.black38,
                                          ),
                                        ),
                                      )
                                    else
                                      Column(
                                        children: event.comments.map((comment) {
                                          return Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 10,
                                            ),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xFF0F172A)
                                                  : Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                CircleAvatar(
                                                  radius: 14,
                                                  backgroundColor: AppColors
                                                      .patasColor
                                                      .withValues(alpha: 0.2),
                                                  child: Text(
                                                    comment.userName.isNotEmpty
                                                        ? comment.userName[0]
                                                              .toUpperCase()
                                                        : 'U',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          AppColors.patasColor,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        comment.userName,
                                                        style: TextStyle(
                                                          fontFamily: 'Fredoka',
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: textColor,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        comment.commentText,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: subtitleColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Campo para adicionar novo comentário
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : Colors.grey.shade100,
                          border: Border(
                            top: BorderSide(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                decoration: InputDecoration(
                                  hintText: 'Escreva uma memória carinhosa...',
                                  hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.black38,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                ),
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.send_rounded,
                                color: AppColors.patasColor,
                              ),
                              onPressed: () {
                                final text = _commentController.text.trim();
                                if (text.isNotEmpty) {
                                  setStateDialog(() {
                                    event.comments.add(
                                      TimelineComment(
                                        id: DateTime.now().toString(),
                                        userName: 'Tutor',
                                        userAvatar: '',
                                        commentText: text,
                                        createdAt: DateTime.now(),
                                      ),
                                    );
                                    _commentController.clear();
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showLoveMilestoneModal(BuildContext context, TimelineEvent event) {
    final thmode = Provider.of<DarkMode>(context, listen: false);
    final isDark = thmode.darkMode;
    final activePet = Provider.of<ActivePetProvider>(context, listen: false).activePet;

    final bgColor = isDark ? AppColors.darkBG : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.darkBG;
    final subtitleColor = isDark ? Colors.white70 : Colors.black87;

    final dateStr =
        '${event.date.day.toString().padLeft(2, '0')}/${event.date.month.toString().padLeft(2, '0')}/${event.date.year}';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.pinkAccent.withValues(alpha: isDark ? 0.35 : 0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header com Tag Rosa e Botão Fechar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.pinkAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Marco Afetivo • Patas Love',
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.pinkAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            color: textColor,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Avatares Cruzados/Entrelaçados dos 2 Pets
                      SizedBox(
                        height: 110,
                        width: 220,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Avatar do Pet Ativo (à esquerda)
                            Positioned(
                              left: 10,
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.patasColor, width: 3.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: _buildMediaImage(
                                    activePet?.photoUrl ?? '',
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            // Avatar do Pet Parceiro (à direita, sobreposto)
                            Positioned(
                              right: 10,
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.pinkAccent, width: 3.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: _buildMediaImage(
                                    event.partnerPetPhotoUrl ?? (event.mediaUrls.isNotEmpty ? event.mediaUrls.first : ''),
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            // Coração de União no Centro
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                color: Colors.pinkAccent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.favorite_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Nomes dos 2 Pets
                      Text(
                        '${activePet?.name ?? 'Pet'} & ${event.partnerPetName ?? 'Amigo'} 💕',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (event.partnerPetBreed != null && event.partnerPetBreed!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Raça: ${event.partnerPetBreed}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Badge com a Data do Encontro
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.event_available_rounded, color: Colors.pinkAccent, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Encontro realizado em $dateStr',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Descrição Afetiva
                      Text(
                        event.description,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: subtitleColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 22),

                      // Botão Celebrar
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.celebration_rounded, size: 20),
                        label: const Text(
                          'Celebrar Encontro! 🎉',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  TimelineGranularity _calculateGranularity(double zoom) {
    if (zoom < 0.8) {
      return TimelineGranularity.years;
    } else if (zoom < 1.5) {
      return TimelineGranularity.months;
    } else if (zoom < 2.3) {
      return TimelineGranularity.weeks;
    } else {
      return TimelineGranularity.days;
    }
  }

  void _updateZoom(double newZoom) {
    final clampedZoom = newZoom.clamp(0.4, 3.2);
    if ((clampedZoom - _zoomLevel).abs() > 0.01) {
      setState(() {
        _zoomLevel = clampedZoom;
        _granularity = _calculateGranularity(clampedZoom);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final activePet = Provider.of<ActivePetProvider>(context).activePet;
    final isDark = thmode.darkMode;
    final bgColor = isDark ? AppColors.bodygray : const Color(0xFFF5F7FA);

    final double rulerWidth = 1600.0 * _zoomLevel;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: PatasEssencialAppBar(
          title: 'Patas História 📖',
          subtitle: 'Linha do Tempo de ${activePet?.name ?? 'seu Pet'} • ${_granularity.label}',
          leadingIcon: CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.patasColor.withValues(alpha: 0.2),
            backgroundImage: activePet?.photoUrl != null && activePet!.photoUrl!.isNotEmpty
                ? NetworkImage(activePet.photoUrl!)
                : null,
            child: activePet?.photoUrl == null || activePet!.photoUrl!.isEmpty
                ? const Icon(
                    Icons.pets_rounded,
                    color: AppColors.patasColor,
                    size: 20,
                  )
                : null,
          ),
        ),
        body: Listener(
          onPointerSignal: (pointerSignal) {
            if (pointerSignal is PointerScrollEvent) {
              final isZoomHotkeyPressed =
                  HardwareKeyboard.instance.isShiftPressed ||
                  HardwareKeyboard.instance.isAltPressed ||
                  HardwareKeyboard.instance.isControlPressed ||
                  HardwareKeyboard.instance.isMetaPressed;

              // Se Shift, Alt, Ctrl ou Cmd estiver pressionado, altera o zoom global da tela!
              if (isZoomHotkeyPressed) {
                final zoomDelta = pointerSignal.scrollDelta.dy < 0
                    ? 0.15
                    : -0.15;
                _updateZoom(_zoomLevel + zoomDelta);
              }
            }
          },
          child: GestureDetector(
            onScaleUpdate: (details) {
              if (details.scale != 1.0) {
                _updateZoom(_zoomLevel * details.scale);
              }
            },
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.patasColor,
                    ),
                  )
                : Stack(
                    children: [
                      // 1. ÁREA CENTRAL SCROLLÁVEL HORIZONTAL COM A RÉGUA MESTRE E MINIATURAS
                      Center(
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: SizedBox(
                            width: rulerWidth,
                            height: MediaQuery.of(context).size.height,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Desenho vetorial da Régua Mestre Central Sincronizada com o Calendário Real
                                CustomPaint(
                                  size: Size(rulerWidth, double.infinity),
                                  painter: CenterRulerPainter(
                                    granularity: _granularity,
                                    zoomLevel: _zoomLevel,
                                    isDark: isDark,
                                    minDate: _minDate,
                                    maxDate: _maxDate,
                                  ),
                                ),

                                // Renderização das Miniaturas Pinned Sincronizadas com o Calendário Real
                                ...() {
                                  final eventsToDisplay =
                                      _timelineEvents.isNotEmpty
                                      ? _timelineEvents
                                      : _mockEvents;

                                  final double totalMs =
                                      (_maxDate.millisecondsSinceEpoch -
                                              _minDate.millisecondsSinceEpoch)
                                          .toDouble();

                                  const double margin = 60.0;
                                  final double usableWidth =
                                      rulerWidth - (margin * 2);

                                  return List.generate(eventsToDisplay.length, (
                                    index,
                                  ) {
                                    final event = eventsToDisplay[index];
                                    final double eventMs =
                                        (event.date.millisecondsSinceEpoch -
                                                _minDate.millisecondsSinceEpoch)
                                            .toDouble();

                                    final double ratio = totalMs > 0
                                        ? (eventMs / totalMs).clamp(0.0, 1.0)
                                        : 0.5;

                                    final double posX =
                                        margin + (ratio * usableWidth);
                                    final bool isTop = index % 2 == 0;

                                    final double centerY =
                                        MediaQuery.of(context).size.height / 2;

                                    final double topPos = isTop
                                        ? (centerY - 170.0)
                                        : (centerY - 15.0);

                                    return Positioned(
                                      left: posX - 28,
                                      top: topPos,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isTop) ...[
                                            _buildMiniatureCard(event),
                                            const SizedBox(height: 6),
                                            Container(
                                              width: event.isLoveMilestone ? 2.5 : 2,
                                              height: 32,
                                              color: event.isLoveMilestone
                                                  ? Colors.pinkAccent
                                                  : AppColors.patasColor,
                                            ),
                                          ] else ...[
                                            Container(
                                              width: event.isLoveMilestone ? 2.5 : 2,
                                              height: 32,
                                              color: event.isLoveMilestone
                                                  ? Colors.pinkAccent
                                                  : AppColors.patasColor,
                                            ),
                                            const SizedBox(height: 6),
                                            _buildMiniatureCard(event),
                                          ],
                                        ],
                                      ),
                                    );
                                  });
                                }(),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 2. CONTROLE FLUTUANTE DE ZOOM SUPERIOR
                      Positioned(
                        top: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: TimelineRulerWidget(
                            initialZoom: _zoomLevel,
                            onZoomChanged: (zoom) {
                              setState(() {
                                _zoomLevel = zoom;
                              });
                            },
                            onGranularityChanged: (granularity) {
                              setState(() {
                                _granularity = granularity;
                              });
                            },
                          ),
                        ),
                      ),

                      // 3. AVISO DE ATALHO PARA DESKTOP/WEB (CANTO INFERIOR DIREITO)
                      if (_shouldShowDesktopHint(context))
                        _buildDesktopZoomHintBadge(isDark),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // Verificação dupla à prova de falhas (Plataforma Desktop Real + Altura Mínima Mínima)
  bool _shouldShowDesktopHint(BuildContext context) {
    final isDesktopPlatform =
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;

    final hasDesktopHeight = MediaQuery.of(context).size.height >= 550;

    return isDesktopPlatform && hasDesktopHeight;
  }

  // Widget para renderizar a miniatura compacta (Thumbnail de 56x56 px)
  Widget _buildMiniatureCard(TimelineEvent event) {
    final isLove = event.isLoveMilestone;

    return InkWell(
      onTap: () => isLove
          ? _showLoveMilestoneModal(context, event)
          : _showMediaExpandModal(context, event),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (isLove ? Colors.pinkAccent : Colors.black)
                  .withValues(alpha: isLove ? 0.45 : 0.3),
              blurRadius: isLove ? 12 : 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isLove ? Colors.pinkAccent : AppColors.patasColor,
            width: isLove ? 3.0 : 2.5,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            ClipOval(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _buildMediaImage(
                    event.mediaUrls.isNotEmpty ? event.mediaUrls.first : '',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                  if (event.isVideo)
                    Container(
                      color: Colors.black38,
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
            // Badge flutuante de coração para marcos de encontro do Patas Love 💕
            if (isLove)
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.pinkAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper para carregar mídias da rede (Supabase Storage) ou assets locais
  Widget _buildMediaImage(
    String url, {
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey.shade300,
            child: const Icon(
              Icons.pets_rounded,
              color: AppColors.patasColor,
              size: 24,
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: Colors.black12,
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.patasColor,
                ),
              ),
            ),
          );
        },
      );
    } else {
      return Image.asset(
        url.isNotEmpty ? url : 'assets/logo.png',
        width: width,
        height: height,
        fit: fit,
      );
    }
  }

  // Widget de Aviso de Atalho no Canto Inferior Direito para Desktop/Web
  Widget _buildDesktopZoomHintBadge(bool isDark) {
    const orangeColor = AppColors.patasColor;

    return Positioned(
      bottom: 24,
      right: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Texto "Para Zoom" acima dos ícones em Laranja
          const Text(
            'Para Zoom',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: orangeColor,
            ),
          ),
          const SizedBox(height: 4),
          // Ícone da Tecla Shift + Mouse na horizontal em Laranja
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: orangeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: orangeColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'Shift',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: orangeColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                '+',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: orangeColor,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.mouse_rounded, size: 22, color: orangeColor),
            ],
          ),
        ],
      ),
    );
  }
}
