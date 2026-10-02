import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/constants/routes.dart';
import 'package:patas_web_app/src/features/interests/interests_service.dart';

class InterestsQuestionnairePage extends StatefulWidget {
  const InterestsQuestionnairePage({super.key});

  @override
  State<InterestsQuestionnairePage> createState() =>
      _InterestsQuestionnairePageState();
}

class _InterestsQuestionnairePageState
    extends State<InterestsQuestionnairePage> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSaving = false;

  final InterestsService _interestsService = InterestsService();

  // --- Respostas do Usuário ---
  final Set<String> _selectedSpecies = {};
  final Set<String> _selectedContentTypes = {};
  final Set<String> _selectedPetProfiles = {};
  bool _preferLocal = false;

  // Animação de entrada para as perguntas
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_currentPage < 3) {
      _fadeController.reverse().then((_) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
        setState(() => _currentPage++);
        _fadeController.forward();
      });
    } else {
      _finish();
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _fadeController.reverse().then((_) {
        _pageController.previousPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
        setState(() => _currentPage--);
        _fadeController.forward();
      });
    }
  }

  void _skipAll() => _finish();

  Future<void> _finish() async {
    setState(() => _isSaving = true);

    final interests = {
      'species': _selectedSpecies.toList(),
      'content_types': _selectedContentTypes.toList(),
      'pet_profile': _selectedPetProfiles.toList(),
      'prefer_local': _preferLocal,
      'completed': true,
    };

    try {
      await _interestsService.saveInterests(interests);
    } catch (_) {
      // Salva silenciosamente — não bloqueia o avanço do usuário
    }

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      NamedRoute.home,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final bgColor = isDark ? AppColors.darkBG : AppColors.bodyLight;
    final textColor = isDark ? Colors.white : AppColors.darkBG;
    final subtitleColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                _buildHeader(textColor, subtitleColor, isDark),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildPage1(textColor, subtitleColor, isDark),
                      _buildPage2(textColor, subtitleColor, isDark),
                      _buildPage3(textColor, subtitleColor, isDark),
                      _buildPage4(textColor, subtitleColor, isDark),
                    ],
                  ),
                ),
                _buildFooter(textColor, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // Header com barra de progresso
  // ──────────────────────────────────────────
  Widget _buildHeader(Color textColor, Color subtitleColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (_currentPage > 0) ...[
                    Semantics(
                      label: 'Voltar para pergunta anterior',
                      button: true,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.patasColor, size: 20),
                        onPressed: _goToPreviousPage,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    'Seus Interesses 🐾',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.patasColor,
                      fontFamily: 'Fredoka',
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _skipAll,
                child: Text(
                  'Pular tudo',
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Barra de progresso animada
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / 4,
              minHeight: 6,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey[200],
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.patasColor),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pergunta ${_currentPage + 1} de 4',
            style: TextStyle(
              color: subtitleColor,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // Footer com botão Próximo / Concluir
  // ──────────────────────────────────────────
  Widget _buildFooter(Color textColor, bool isDark) {
    final isLast = _currentPage == 3;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: _isSaving
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                onPressed: _goToNextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.patasColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isLast ? 'Começar minha jornada! 🚀' : 'Próximo',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Fredoka',
                  ),
                ),
              ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // Pergunta 1: Espécies de pets
  // ──────────────────────────────────────────
  Widget _buildPage1(Color textColor, Color subtitleColor, bool isDark) {
    final options = [
      {'label': 'Cachorros 🐶', 'value': 'canino'},
      {'label': 'Gatos 🐱', 'value': 'felino'},
      {'label': 'Aves e Pássaros 🦜', 'value': 'ave'},
      {'label': 'Pequenos Roedores 🐹', 'value': 'roedor'},
      {'label': 'Exóticos e Répteis 🦎', 'value': 'exotico'},
      {'label': 'Quero ver todos! 🐾', 'value': 'todos'},
    ];

    return _buildQuestionScroll(
      textColor: textColor,
      subtitleColor: subtitleColor,
      isDark: isDark,
      question: 'Que espécies você quer\nver no seu feed?',
      hint: 'Selecione uma ou mais opções',
      child: _buildChipGrid(
        options: options,
        selected: _selectedSpecies,
        isDark: isDark,
        onToggle: (value) {
          setState(() {
            if (value == 'todos') {
              // "Todos" seleciona e limpa os outros, ou vice-versa
              if (_selectedSpecies.contains('todos')) {
                _selectedSpecies.clear();
              } else {
                _selectedSpecies
                  ..clear()
                  ..add('todos');
              }
            } else {
              _selectedSpecies.remove('todos');
              if (_selectedSpecies.contains(value)) {
                _selectedSpecies.remove(value);
              } else {
                _selectedSpecies.add(value);
              }
            }
          });
        },
      ),
    );
  }

  // ──────────────────────────────────────────
  // Pergunta 2: Tipo de conteúdo
  // ──────────────────────────────────────────
  Widget _buildPage2(Color textColor, Color subtitleColor, bool isDark) {
    final options = [
      {'label': 'Fotos e momentos fofos 📸', 'value': 'fotos'},
      {'label': 'Saúde e bem-estar animal 🏥', 'value': 'saude'},
      {'label': 'Locais pet friendly 🌳', 'value': 'locais'},
      {'label': 'Mimos e novidades 🛍️', 'value': 'produtos'},
      {'label': 'ONGs e pets perdidos 🆘', 'value': 'ongs'},
    ];

    return _buildQuestionScroll(
      textColor: textColor,
      subtitleColor: subtitleColor,
      isDark: isDark,
      question: 'Que tipo de conteúdo\nte interessa mais?',
      hint: 'Pode escolher vários!',
      child: _buildChipGrid(
        options: options,
        selected: _selectedContentTypes,
        isDark: isDark,
        onToggle: (value) {
          setState(() {
            if (_selectedContentTypes.contains(value)) {
              _selectedContentTypes.remove(value);
            } else {
              _selectedContentTypes.add(value);
            }
          });
        },
      ),
    );
  }

  // ──────────────────────────────────────────
  // Pergunta 3: Perfil de pet preferido
  // ──────────────────────────────────────────
  Widget _buildPage3(Color textColor, Color subtitleColor, bool isDark) {
    final options = [
      {'label': 'Filhotes cheios de energia 🍼', 'value': 'filhote'},
      {'label': 'Pets calmos de apartamento 🛋️', 'value': 'calmo'},
      {'label': 'Aventureiros e de grande porte 🏃', 'value': 'aventureiro'},
      {'label': 'Pets idosos com histórias 👴', 'value': 'idoso'},
    ];

    return _buildQuestionScroll(
      textColor: textColor,
      subtitleColor: subtitleColor,
      isDark: isDark,
      question: 'Qual perfil de pet\nvocê prefere acompanhar?',
      hint: 'Selecione os que mais combinam com você',
      child: _buildChipGrid(
        options: options,
        selected: _selectedPetProfiles,
        isDark: isDark,
        onToggle: (value) {
          setState(() {
            if (_selectedPetProfiles.contains(value)) {
              _selectedPetProfiles.remove(value);
            } else {
              _selectedPetProfiles.add(value);
            }
          });
        },
      ),
    );
  }

  // ──────────────────────────────────────────
  // Pergunta 4: Preferência geográfica
  // ──────────────────────────────────────────
  Widget _buildPage4(Color textColor, Color subtitleColor, bool isDark) {
    return _buildQuestionScroll(
      textColor: textColor,
      subtitleColor: subtitleColor,
      isDark: isDark,
      question: 'Gostaria de ver o que\nestá acontecendo perto de você?',
      hint: 'Isso ajuda a priorizar conteúdo da sua região',
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildLocalOptionCard(
            title: 'Sim, priorizar minha região 📍',
            subtitle: 'Veja pets e eventos perto de você',
            value: true,
            isDark: isDark,
            textColor: textColor,
            subtitleColor: subtitleColor,
          ),
          const SizedBox(height: 16),
          _buildLocalOptionCard(
            title: 'Não, quero ver o mundo inteiro 🌎',
            subtitle: 'Descubra pets e histórias de todo lugar',
            value: false,
            isDark: isDark,
            textColor: textColor,
            subtitleColor: subtitleColor,
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // Helpers: Layout padrão de pergunta
  // ──────────────────────────────────────────
  Widget _buildQuestionScroll({
    required Color textColor,
    required Color subtitleColor,
    required bool isDark,
    required String question,
    required String hint,
    required Widget child,
  }) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
                fontFamily: 'Fredoka',
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hint,
              style: TextStyle(
                fontSize: 14,
                color: subtitleColor,
              ),
            ),
            const SizedBox(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  // Grade de chips animados
  Widget _buildChipGrid({
    required List<Map<String, String>> options,
    required Set<String> selected,
    required bool isDark,
    required void Function(String) onToggle,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((opt) {
        final value = opt['value']!;
        final label = opt['label']!;
        final isSelected = selected.contains(value);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: GestureDetector(
            onTap: () => onToggle(value),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.patasColor.withValues(alpha: 0.15)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isSelected
                      ? AppColors.patasColor
                      : (isDark ? Colors.white24 : Colors.grey[300]!),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.patasColor.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.patasColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.patasColor
                          : (isDark ? Colors.white70 : Colors.grey[700]),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Card de opção única (pergunta 4)
  Widget _buildLocalOptionCard({
    required String title,
    required String subtitle,
    required bool value,
    required bool isDark,
    required Color textColor,
    required Color subtitleColor,
  }) {
    final isSelected = _preferLocal == value;

    return GestureDetector(
      onTap: () => setState(() => _preferLocal = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.patasColor.withValues(alpha: 0.12)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.patasColor
                : (isDark ? Colors.white24 : Colors.grey[300]!),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.patasColor.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.patasColor : textColor,
                      fontFamily: 'Fredoka',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.patasColor,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
