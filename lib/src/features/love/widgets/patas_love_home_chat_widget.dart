import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app.dart';
import '../../../constants/app_colors.dart';
import '../../pets/active_pet_provider.dart';
import '../../pets/models/pet_model.dart';
import '../services/patas_love_service.dart';
import '../screens/patas_love_main_screen.dart';

class PatasLoveHomeChatWidget extends StatefulWidget {
  const PatasLoveHomeChatWidget({super.key});

  @override
  State<PatasLoveHomeChatWidget> createState() =>
      _PatasLoveHomeChatWidgetState();
}

class _PatasLoveHomeChatWidgetState extends State<PatasLoveHomeChatWidget> {
  bool _isExpanded = false;
  final PatasLoveService _loveService = PatasLoveService();
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _chats = [];
  Map<String, dynamic>? _selectedChat;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoadingChats = false;
  bool _isLoadingMessages = false;
  bool _isSending = false;

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _loadChats();
    }
  }

  Future<void> _loadChats() async {
    final activePet =
        Provider.of<ActivePetProvider>(context, listen: false).activePet;
    if (activePet == null) return;

    setState(() {
      _isLoadingChats = true;
      _selectedChat = null;
      _messages = [];
    });

    final chats = await _loveService.getChatsForPet(activePet.id);

    if (mounted) {
      setState(() {
        _chats = chats;
        _isLoadingChats = false;
      });
    }
  }

  Future<void> _selectChat(Map<String, dynamic> chat) async {
    setState(() {
      _selectedChat = chat;
      _isLoadingMessages = true;
    });

    final chatId = chat['id'] as String;
    final messages = await _loveService.getMessages(chatId);

    if (mounted) {
      setState(() {
        _messages = messages;
        _isLoadingMessages = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    final activePet =
        Provider.of<ActivePetProvider>(context, listen: false).activePet;

    if (text.isEmpty ||
        _selectedChat == null ||
        activePet == null ||
        _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    _msgController.clear();

    final chatId = _selectedChat!['id'] as String;
    final success = await _loveService.sendMessage(
      chatId: chatId,
      senderUserId: activePet.userId,
      senderPetId: activePet.id,
      content: text,
    );

    if (success) {
      final messages = await _loveService.getMessages(chatId);
      if (mounted) {
        setState(() {
          _messages = messages;
        });
        _scrollToBottom();
      }
    }

    if (mounted) {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final activePet = Provider.of<ActivePetProvider>(context).activePet;

    final screenWidth = MediaQuery.of(context).size.width;
    final widgetWidth = screenWidth > 420 ? 360.0 : (screenWidth - 32.0);

    final currentWidth = _isExpanded ? widgetWidth : 156.0;
    final currentHeight = _isExpanded ? 480.0 : 56.0;

    return Material(
      color: Colors.transparent,
      elevation: _isExpanded ? 10.0 : 6.0,
      shadowColor: Colors.black.withValues(alpha: _isExpanded ? 0.3 : 0.2),
      borderRadius: BorderRadius.circular(_isExpanded ? 24 : 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.fastOutSlowIn,
        width: currentWidth,
        height: currentHeight,
        decoration: BoxDecoration(
          color: _isExpanded
              ? (thmode.darkMode ? AppColors.darkBG : Colors.white)
              : AppColors.patasColor,
          borderRadius: BorderRadius.circular(_isExpanded ? 24 : 16),
          border: Border.all(
            color: AppColors.patasColor,
            width: _isExpanded ? 2.5 : 0.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_isExpanded ? 21.5 : 16),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            child: _isExpanded
                ? KeyedSubtree(
                    key: const ValueKey('ExpandedChatWindow'),
                    child: _buildExpandedWindow(context, thmode, activePet),
                  )
                : KeyedSubtree(
                    key: const ValueKey('CollapsedChatButton'),
                    child: _buildCollapsedButton(),
                  ),
          ),
        ),
      ),
    );
  }

  // ─── ESTADO RECOLHIDO: BOTÃO LARANJA ──────────────────────────────────────
  Widget _buildCollapsedButton() {
    return InkWell(
      onTap: _toggleExpand,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.favorite_rounded, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text(
              'Patas Love',
              style: TextStyle(
                fontFamily: 'Fredoka',
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ESTADO EXPANDIDO: JANELA COMPLETA DO CHAT ────────────────────────────
  Widget _buildExpandedWindow(
      BuildContext context, DarkMode thmode, Pet? activePet) {
    Map<String, dynamic>? partnerMap;
    if (_selectedChat != null) {
      final petA = _selectedChat!['pet_a'];
      final petB = _selectedChat!['pet_b'];
      partnerMap = (petA != null && petA['id'] != activePet?.id) ? petA : petB;
    }

    final partnerName = partnerMap?['name'] ?? 'Chat';
    final partnerPhoto = partnerMap?['photo_url'];

    return Column(
      children: [
        // Cabeçalho Laranja da Janela
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: const BoxDecoration(
            color: AppColors.patasColor,
          ),
          child: Row(
            children: [
              // Botão Voltar Estilizado (só aparece dentro de um chat)
              if (_selectedChat != null) ...[
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 15),
                    tooltip: 'Voltar para os contatos',
                    onPressed: () {
                      setState(() {
                        _selectedChat = null;
                        _messages = [];
                      });
                    },
                  ),
                ),
              ],

              // Ícone ou Avatar do Cabeçalho
              if (_selectedChat != null) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundImage:
                      partnerPhoto != null ? NetworkImage(partnerPhoto) : null,
                  child: partnerPhoto == null
                      ? const Icon(Icons.pets,
                          size: 14, color: AppColors.patasColor)
                      : null,
                ),
                const SizedBox(width: 8),
              ] else ...[
                const Icon(Icons.favorite_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
              ],

              // Título do Cabeçalho
              Expanded(
                child: Text(
                  _selectedChat != null
                      ? partnerName
                      : 'Patas Love — Conversas',
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Botão Fechar Janela (X)
              InkWell(
                onTap: _toggleExpand,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),

        // Conteúdo da Janela (Alterna entre Lista de Contatos e Chat)
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _selectedChat == null
                ? _buildContactsList(context, thmode, activePet)
                : _buildChatDetail(context, thmode, activePet),
          ),
        ),
      ],
    );
  }

  // ─── TELA 1: LISTA DE CONTATOS / CONVERSAS INICIADAS ─────────────────────
  Widget _buildContactsList(
      BuildContext context, DarkMode thmode, Pet? activePet) {
    if (_isLoadingChats) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.patasColor),
      );
    }

    if (_chats.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.patasColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 48,
                color: AppColors.patasColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma conversa ativa',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: thmode.darkMode ? Colors.white : AppColors.darkBG,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Encontre parceiros no Patas Love para começar a conversar!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: thmode.darkMode ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.patasColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                _toggleExpand();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PatasLoveMainScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.explore_rounded, size: 18),
              label: const Text('Ir para o Patas Love'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _chats.length,
      itemBuilder: (context, index) {
        final chat = _chats[index];
        final petA = chat['pet_a'];
        final petB = chat['pet_b'];
        final partnerMap =
            (petA != null && petA['id'] != activePet?.id) ? petA : petB;

        final partnerName = partnerMap?['name'] ?? 'Pet';
        final partnerPhoto = partnerMap?['photo_url'];
        final partnerBreed =
            partnerMap?['breed'] ?? partnerMap?['species'] ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: thmode.darkMode ? Colors.white10 : Colors.grey.shade200,
            ),
          ),
          color: thmode.darkMode ? const Color(0xFF1E293B) : Colors.white,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: CircleAvatar(
              radius: 22,
              backgroundImage:
                  partnerPhoto != null ? NetworkImage(partnerPhoto) : null,
              child: partnerPhoto == null
                  ? const Icon(Icons.pets, color: AppColors.patasColor)
                  : null,
            ),
            title: Text(
              partnerName,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: thmode.darkMode ? Colors.white : AppColors.darkBG,
              ),
            ),
            subtitle: Text(
              partnerBreed,
              style: TextStyle(
                fontSize: 12,
                color: thmode.darkMode ? Colors.white60 : Colors.black54,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.patasColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 16,
                color: AppColors.patasColor,
              ),
            ),
            onTap: () => _selectChat(chat),
          ),
        );
      },
    );
  }

  // ─── TELA 2: CHAT DETALHADO COM O CONTATO SELECIONADO ─────────────────────
  Widget _buildChatDetail(
      BuildContext context, DarkMode thmode, Pet? activePet) {
    return Column(
      children: [
        // Lista de Mensagens do Chat
        Expanded(
          child: _isLoadingMessages
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.patasColor,
                    strokeWidth: 2,
                  ),
                )
              : _messages.isEmpty
                  ? Center(
                      child: Text(
                        'Envie a primeira mensagem...',
                        style: TextStyle(
                          fontSize: 12,
                          color: thmode.darkMode
                              ? Colors.white54
                              : Colors.black45,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isMe =
                            msg['sender_user_id'] == activePet?.userId;

                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            constraints: const BoxConstraints(maxWidth: 240),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? AppColors.patasColor
                                  : (thmode.darkMode
                                      ? AppColors.darkBG
                                      : Colors.grey.shade200),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(14),
                                topRight: const Radius.circular(14),
                                bottomLeft: Radius.circular(isMe ? 14 : 2),
                                bottomRight: Radius.circular(isMe ? 2 : 14),
                              ),
                            ),
                            child: Text(
                              msg['content'] ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: isMe
                                    ? Colors.white
                                    : (thmode.darkMode
                                        ? Colors.white
                                        : Colors.black87),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),

        // Campo de Texto de Entrada no Rodapé
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: thmode.darkMode ? AppColors.darkBG : Colors.white,
            border: Border(
              top: BorderSide(
                color: thmode.darkMode ? Colors.white10 : Colors.grey.shade200,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgController,
                  style: TextStyle(
                    fontSize: 13,
                    color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Escreva uma mensagem...',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: thmode.darkMode ? Colors.white38 : Colors.black38,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: thmode.darkMode
                        ? AppColors.bodygray
                        : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                constraints: const BoxConstraints(),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.patasColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(8),
                ),
                icon: _isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 16),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
