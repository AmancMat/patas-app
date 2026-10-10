import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app.dart';
import '../../../constants/app_colors.dart';
import '../../pets/models/pet_model.dart';
import '../services/patas_love_service.dart';

class LoveChatScreen extends StatefulWidget {
  final String chatId;
  final Pet activePet;
  final Pet targetPet;

  const LoveChatScreen({
    super.key,
    required this.chatId,
    required this.activePet,
    required this.targetPet,
  });

  @override
  State<LoveChatScreen> createState() => _LoveChatScreenState();
}

class _LoveChatScreenState extends State<LoveChatScreen>
    with TickerProviderStateMixin {
  final PatasLoveService _loveService = PatasLoveService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  // Stream Subscriptions para tempo real
  StreamSubscription<List<Map<String, dynamic>>>? _messagesSubscription;
  StreamSubscription<Map<String, dynamic>?>? _chatSubscription;

  // Status do encontro cronológico
  String _meetStatus = 'active'; // 'active' | 'meeting_proposed' | 'meeting_scheduled' | 'met_in_person'
  String? _meetingProposedBy;
  DateTime? _meetingDate;
  String? _meetingLocation;
  String? _meetingNotes;
  bool _isProcessingMeet = false;

  // Animação de celebração (pulse)
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _setupRealtimeStreams();
  }

  void _setupRealtimeStreams() {
    // 1. Ouvir mensagens em tempo real (Realtime Stream)
    _messagesSubscription = _loveService.getMessagesStream(widget.chatId).listen(
      (messages) {
        if (mounted) {
          setState(() {
            _messages = messages;
            _isLoading = false;
          });
          _scrollToBottom();
          // Marca as mensagens recebidas como lidas
          _loveService.markMessagesAsRead(
            chatId: widget.chatId,
            currentUserId: widget.activePet.userId,
          );
        }
      },
      onError: (err) {
        debugPrint('Erro no stream de mensagens: $err');
        _loadMessages(); // Fallback
      },
    );

    // 2. Ouvir atualizações de agendamento de encontro em tempo real
    _chatSubscription = _loveService.getChatMeetingStream(widget.chatId).listen(
      (details) {
        if (mounted && details != null) {
          setState(() {
            _meetStatus = details['status'] as String? ?? 'active';
            _meetingProposedBy = (details['meeting_proposed_by'] ?? details['meet_requested_by']) as String?;
            if (details['meeting_date'] != null) {
              try {
                _meetingDate = DateTime.parse(details['meeting_date'] as String);
              } catch (_) {}
            }
            _meetingLocation = details['meeting_location'] as String?;
            _meetingNotes = details['meeting_notes'] as String?;
          });
        }
      },
      onError: (err) {
        debugPrint('Erro no stream do encontro: $err');
        _loadMeetStatus(); // Fallback
      },
    );
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _chatSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final messages = await _loveService.getMessages(widget.chatId);
    if (mounted) {
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatMessageTime(dynamic createdAt) {
    if (createdAt == null) return '';
    try {
      final dt = createdAt is DateTime
          ? createdAt
          : DateTime.parse(createdAt.toString()).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    final success = await _loveService.sendMessage(
      chatId: widget.chatId,
      senderUserId: widget.activePet.userId,
      senderPetId: widget.activePet.id,
      content: text,
    );

    if (success) await _loadMessages();
    if (mounted) setState(() => _isSending = false);
  }

  Future<void> _loadMeetStatus() async {
    final details = await _loveService.getMeetingDetails(widget.chatId);
    if (mounted && details != null) {
      setState(() {
        _meetStatus = details['status'] as String? ?? 'active';
        _meetingProposedBy = (details['meeting_proposed_by'] ?? details['meet_requested_by']) as String?;
        if (details['meeting_date'] != null) {
          try {
            _meetingDate = DateTime.parse(details['meeting_date'] as String);
          } catch (_) {}
        }
        _meetingLocation = details['meeting_location'] as String?;
        _meetingNotes = details['meeting_notes'] as String?;
      });
    }
  }

  // ─── Fluxo Cronológico de Encontros ────────────────────────────────────────

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'Data a combinar';
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month às $hour:$minute';
  }

  /// Modal didático para propor um encontro
  void _showProposeMeetingModal() {
    final thmode = Provider.of<DarkMode>(context, listen: false);
    final isDark = thmode.darkMode;

    DateTime selectedDate = DateTime.now().add(const Duration(days: 2));
    TimeOfDay selectedTime = const TimeOfDay(hour: 16, minute: 0);
    final locationController = TextEditingController(text: 'Parque Pet');
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateModal) {
            final mq = MediaQuery.of(ctx);
            final bottomInset = mq.viewInsets.bottom;
            final navBarPadding = mq.padding.bottom > 0 ? mq.padding.bottom : mq.viewPadding.bottom;
            final safeBottom = math.max(navBarPadding, 24.0) + 20.0 + bottomInset;

            return Container(
              padding: EdgeInsets.fromLTRB(24, 20, 24, safeBottom),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBG : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.pinkAccent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.event_available_rounded, color: Colors.pinkAccent, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Propor Encontro Pet 🗓️',
                                style: TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.darkBG,
                                ),
                              ),
                              Text(
                                'Combine um momento presencial para ${widget.activePet.name} e ${widget.targetPet.name}',
                                style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Seletor de Data e Hora
                    Text(
                      'Data e Horário Sugeridos',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.darkBG,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: BorderSide(color: Colors.pinkAccent.withValues(alpha: 0.5)),
                            ),
                            icon: const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.pinkAccent),
                            label: Text(
                              '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}',
                              style: TextStyle(fontSize: 13, color: isDark ? Colors.white : AppColors.darkBG),
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 90)),
                              );
                              if (picked != null) {
                                setStateModal(() => selectedDate = picked);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: BorderSide(color: Colors.pinkAccent.withValues(alpha: 0.5)),
                            ),
                            icon: const Icon(Icons.access_time_rounded, size: 16, color: Colors.pinkAccent),
                            label: Text(
                              '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(fontSize: 13, color: isDark ? Colors.white : AppColors.darkBG),
                            ),
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );
                              if (picked != null) {
                                setStateModal(() => selectedTime = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Campo de Local do Encontro
                    Text(
                      'Local de Encontro',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.darkBG,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: locationController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Ex: Parque Ibirapuera, Praça dos Pets...',
                        prefixIcon: const Icon(Icons.place_rounded, color: Colors.pinkAccent, size: 20),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Campo de Recado / Observações
                    Text(
                      'Dica / Recado Especial (Opcional)',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.darkBG,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Ex: Levar brinquedo favorito, pet dócil...',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botão de Enviar Proposta
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text(
                        'Enviar Convite de Encontro 💕',
                        style: TextStyle(fontFamily: 'Fredoka', fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final combinedDateTime = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );
                        await _doProposeMeeting(
                          combinedDateTime,
                          locationController.text.trim().isEmpty ? 'Local a combinar' : locationController.text.trim(),
                          notesController.text.trim(),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _doProposeMeeting(DateTime date, String location, String? notes) async {
    setState(() => _isProcessingMeet = true);
    final success = await _loveService.proposeMeeting(
      chatId: widget.chatId,
      proposedByUserId: widget.activePet.userId,
      requesterPetName: widget.activePet.name,
      meetingDate: date,
      location: location,
      notes: notes,
    );

    if (mounted) {
      setState(() {
        _isProcessingMeet = false;
        if (success) {
          _meetStatus = 'meeting_proposed';
          _meetingProposedBy = widget.activePet.userId;
          _meetingDate = date;
          _meetingLocation = location;
          _meetingNotes = notes;
        }
      });
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('💌 Convite de encontro enviado! Aguarde a resposta do outro tutor.'),
            backgroundColor: Colors.pinkAccent,
          ),
        );
      }
    }
  }

  Future<void> _doRespondMeeting(bool accepted) async {
    setState(() => _isProcessingMeet = true);
    final success = await _loveService.respondMeetingProposal(
      chatId: widget.chatId,
      accepted: accepted,
    );

    if (mounted) {
      setState(() {
        _isProcessingMeet = false;
        if (success) {
          if (accepted) {
            _meetStatus = 'meeting_scheduled';
          } else {
            _meetStatus = 'active';
            _meetingProposedBy = null;
            _meetingDate = null;
            _meetingLocation = null;
            _meetingNotes = null;
          }
        }
      });
      if (success && accepted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Encontro agendado com sucesso! Vejam os detalhes no topo da conversa.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showConfirmRealizedModal() {
    final thmode = Provider.of<DarkMode>(context, listen: false);
    final isDark = thmode.darkMode;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkBG : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 28),
            SizedBox(width: 10),
            Text('Marcar como Realizado? 💕', style: TextStyle(fontFamily: 'Fredoka', fontSize: 19)),
          ],
        ),
        content: Text(
          'O encontro presencial entre ${widget.activePet.name} e ${widget.targetPet.name} já aconteceu?\n\n'
          'Ao confirmar, esse momento será registrado automaticamente na Linha do Tempo (Patas História) de ambos com o marco afetivo comemorativo! 🎉',
          style: TextStyle(fontSize: 13, height: 1.4, color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ainda não'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _doMarkMeetingCompleted();
            },
            child: const Text('Sim, nos encontramos! 🎉', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _doMarkMeetingCompleted() async {
    setState(() => _isProcessingMeet = true);
    final success = await _loveService.markMeetingAsCompleted(
      chatId: widget.chatId,
      petAId: widget.activePet.id,
      petBId: widget.targetPet.id,
      notes: _meetingNotes,
    );

    if (mounted) {
      setState(() {
        _isProcessingMeet = false;
        if (success) _meetStatus = 'met_in_person';
      });
      if (success) _showCelebrationDialog();
    }
  }

  void _showCelebrationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _pulseAnim,
                child: const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 72),
              ),
              const SizedBox(height: 20),
              const Text(
                'Encontro Confirmado! 🎉',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Que momento lindo! ${widget.activePet.name} e ${widget.targetPet.name} se encontraram na vida real.\n\n'
                'Esse marco afetivo foi adicionado na Linha do Tempo (Patas História) de ambos! 💕',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Uhuul! Ver na História 🐾', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Banner Cronológico Superior no Chat ───────────────────────────────────

  Widget _buildMeetingTimelineBanner() {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    Widget? bannerContent;

    // ESTADO 1: Conversando -> Convidar para Propor Encontro
    if (_meetStatus == 'active' || _meetStatus == 'pending_meet') {
      bannerContent = Container(
        margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.event_available_rounded, color: Colors.pinkAccent, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Combinação fluindo? Marque um encontro presencial!',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text(
                'Propor Encontro',
                style: TextStyle(fontFamily: 'Fredoka', fontSize: 12, fontWeight: FontWeight.bold),
              ),
              onPressed: _showProposeMeetingModal,
            ),
          ],
        ),
      );
    } else if (_meetStatus == 'meeting_proposed') {
      // ESTADO 2: Proposta em Análise
      final isMyProposal = _meetingProposedBy == widget.activePet.userId;

      if (isMyProposal) {
        bannerContent = Container(
          margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50.withValues(alpha: isDark ? 0.15 : 0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.shade400),
          ),
          child: Row(
            children: [
              const Icon(Icons.hourglass_top_rounded, color: Colors.amber, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Convite enviado: ${_formatDateTime(_meetingDate)}',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      'Local: ${_meetingLocation ?? 'A combinar'} • Aguardando confirmação',
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black54),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _isProcessingMeet ? null : () => _doRespondMeeting(false),
                child: const Text('Cancelar', style: TextStyle(color: Colors.red, fontSize: 11)),
              ),
            ],
          ),
        );
      } else {
        // Sou o receptor do convite
        bannerContent = Container(
          margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.pink.shade50.withValues(alpha: isDark ? 0.15 : 0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.pinkAccent),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ScaleTransition(
                    scale: _pulseAnim,
                    child: const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '💌 Convite de Encontro de ${widget.targetPet.name}!',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFFB5004A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Data: ${_formatDateTime(_meetingDate)} • Local: ${_meetingLocation ?? 'A combinar'}',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
              ),
              if (_meetingNotes != null && _meetingNotes!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Recado: "$_meetingNotes"',
                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: isDark ? Colors.white60 : Colors.black54),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isProcessingMeet ? null : () => _doRespondMeeting(false),
                    child: const Text('Recusar', style: TextStyle(fontSize: 11)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Aceitar Encontro', style: TextStyle(fontFamily: 'Fredoka', fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: _isProcessingMeet ? null : () => _doRespondMeeting(true),
                  ),
                ],
              ),
            ],
          ),
        );
      }
    } else if (_meetStatus == 'meeting_scheduled') {
      // ESTADO 3: Encontro Agendado!
      bannerContent = Container(
        margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.teal.shade50.withValues(alpha: isDark ? 0.15 : 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.teal.shade300),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Colors.teal, shape: BoxShape.circle),
              child: const Icon(Icons.event_available_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🗓️ Encontro Agendado!',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.teal.shade900,
                    ),
                  ),
                  Text(
                    '${_formatDateTime(_meetingDate)} em ${_meetingLocation ?? 'Local combinado'}',
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.favorite_rounded, size: 15),
              label: const Text(
                'Marcar Realizado',
                style: TextStyle(fontFamily: 'Fredoka', fontSize: 12, fontWeight: FontWeight.bold),
              ),
              onPressed: _showConfirmRealizedModal,
            ),
          ],
        ),
      );
    } else if (_meetStatus == 'met_in_person') {
      // ESTADO 4: Encontro Realizado!
      bannerContent = Container(
        margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6FA3), Color(0xFFFF4081)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '${widget.activePet.name} & ${widget.targetPet.name} já se encontraram! 💕',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Fredoka',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Fallback defensivo incondicional: se não for nenhum estado especial, exibe sempre o card de Propor Encontro
    bannerContent ??= Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.event_available_rounded, color: Colors.pinkAccent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Combinação fluindo? Marque um encontro presencial!',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text(
              'Propor Encontro',
              style: TextStyle(fontFamily: 'Fredoka', fontSize: 12, fontWeight: FontWeight.bold),
            ),
            onPressed: _showProposeMeetingModal,
          ),
        ],
      ),
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: bannerContent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final bgColor = isDark ? AppColors.bodygray : Colors.grey.shade100;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: AppColors.patasColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: isDark ? AppColors.darkBG : Colors.white,
        elevation: 1,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.targetPet.photoUrl != null
                  ? NetworkImage(widget.targetPet.photoUrl!)
                  : null,
              child: widget.targetPet.photoUrl == null
                  ? const Icon(Icons.pets, size: 18, color: Colors.pinkAccent)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.targetPet.name,
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.darkBG,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.targetPet.breed ?? widget.targetPet.species,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: isDark ? Colors.white : AppColors.darkBG,
            ),
            onSelected: (value) {
              if (value == 'block') {
                _confirmBlockTutor(context);
              } else if (value == 'report') {
                _reportTutor(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block_rounded, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Bloquear Tutor', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_rounded, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Text('Denunciar'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner Cronológico de Agendamento e Realização de Encontros
          _buildMeetingTimelineBanner(),
          // Mensagens do Chat
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.pinkAccent),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'Envie a primeira mensagem para combinar o encontro!',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white60
                                : Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe =
                              msg['sender_user_id'] == widget.activePet.userId;

                          return Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 640),
                              child: Align(
                                alignment: isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.75 > 480
                                            ? 480
                                            : MediaQuery.of(context).size.width * 0.75,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? Colors.pinkAccent
                                        : (isDark
                                            ? AppColors.darkBG
                                            : Colors.white),
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                                      bottomRight: Radius.circular(isMe ? 4 : 16),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                            alpha: thmode.darkMode ? 0.2 : 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isMe
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        msg['content'] ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isMe
                                              ? Colors.white
                                              : (isDark
                                                  ? Colors.white
                                                  : AppColors.darkBG),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _formatMessageTime(msg['created_at']),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isMe
                                                  ? Colors.white.withValues(alpha: 0.75)
                                                  : (isDark
                                                      ? Colors.white54
                                                      : Colors.black45),
                                            ),
                                          ),
                                          if (isMe) ...[
                                            const SizedBox(width: 4),
                                            Icon(
                                              msg['is_read'] == true
                                                  ? Icons.done_all_rounded
                                                  : Icons.done_rounded,
                                              size: 13,
                                              color: msg['is_read'] == true
                                                  ? const Color(0xFF90CAF9)
                                                  : Colors.white.withValues(alpha: 0.75),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Campo de Entrada de Texto no Rodapé
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBG : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: TextStyle(
                            color:
                                isDark ? Colors.white : AppColors.darkBG,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Escreva uma mensagem...',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? Colors.white38
                                  : Colors.black38,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? AppColors.bodygray
                                : Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          foregroundColor: Colors.white,
                        ),
                        icon: _isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 20),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
}

  void _confirmBlockTutor(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Bloquear Tutor?'),
        content: Text(
          'Você tem certeza que deseja bloquear o tutor de ${widget.targetPet.name}? Vocês não poderão mais enviar mensagens um ao outro.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              Navigator.of(dialogContext).pop();

              await _loveService.blockUser(
                blockerId: widget.activePet.userId,
                blockedId: widget.targetPet.userId,
              );

              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Tutor bloqueado com sucesso.')),
                );
                navigator.pop();
              }
            },
            child: const Text('Bloquear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _reportTutor(BuildContext context) {
    String selectedReason = 'Conteúdo inadequado ou ofensivo';
    final detailsController = TextEditingController();
    bool isSubmitting = false;

    final reasons = [
      'Conteúdo inadequado ou ofensivo',
      'Perfil falso ou golpe',
      'Spam ou mensagens indesejadas',
      'Maus-tratos ou maus cuidados com animais',
      'Outro motivo',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.flag_rounded, color: Colors.orange, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Denunciar ${widget.targetPet.name}',
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.patasColor,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Por favor, selecione o motivo da denúncia para que nossa equipe possa avaliar o perfil:',
                  style: TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedReason,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Motivo da Denúncia',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  items: reasons.map((r) {
                    return DropdownMenuItem<String>(
                      value: r,
                      child: Text(
                        r,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setStateDialog(() => selectedReason = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: detailsController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Descreva mais detalhes sobre o ocorrido (opcional)...',
                    hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.patasColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setStateDialog(() => isSubmitting = true);
                      final nav = Navigator.of(dialogContext);

                      await _loveService.reportUser(
                        reporterId: widget.activePet.userId,
                        reportedUserId: widget.targetPet.userId,
                        reportedPetId: widget.targetPet.id,
                        reason: selectedReason,
                        details: detailsController.text.trim(),
                      );

                      nav.pop();
                      if (context.mounted) {
                        _showReportSuccessConfirmation(context);
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Enviar Denúncia',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportSuccessConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text(
              'Denúncia Recebida',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 20,
                color: AppColors.patasColor,
              ),
            ),
          ],
        ),
        content: const Text(
          'Sua denúncia foi enviada com sucesso para nossa equipe de moderação!\n\nNós analisamos todas as denúncias com prioridade para garantir a segurança e a integridade de nossa comunidade pet.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.patasColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Entendi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
