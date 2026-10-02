import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import '../../pets/models/pet_model.dart';
import '../models/pet_passport_model.dart';
import '../services/pet_passport_service.dart';
import 'pet_passport_detail_sheet.dart';

class PetPassportOnboardingDialog extends StatefulWidget {
  final Pet pet;
  final ValueChanged<PetPassport>? onMintCompleted;

  const PetPassportOnboardingDialog({
    super.key,
    required this.pet,
    this.onMintCompleted,
  });

  static Future<PetPassport?> show(
    BuildContext context, {
    required Pet pet,
    ValueChanged<PetPassport>? onMintCompleted,
  }) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    return showDialog<PetPassport>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 24 : 16,
          vertical: 24,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: PetPassportOnboardingDialog(
              pet: pet,
              onMintCompleted: onMintCompleted,
            ),
          ),
        ),
      ),
    );
  }

  @override
  State<PetPassportOnboardingDialog> createState() => _PetPassportOnboardingDialogState();
}

class _PetPassportOnboardingDialogState extends State<PetPassportOnboardingDialog> {
  bool _isMinting = false;
  String _mintStep = 'Preparando metadados...';

  void _startMint() async {
    setState(() {
      _isMinting = true;
      _mintStep = 'Consultando nó Solana Devnet...';
    });

    try {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() => _mintStep = 'Cunhando cNFT (Metaplex Bubblegum)...');
      }

      final passport = await PetPassportService.mintAndRegisterPassport(
        pet: widget.pet,
      );

      if (mounted) {
        setState(() => _mintStep = 'Registro gravado na Árvore de Merkle!');
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (mounted) {
        widget.onMintCompleted?.call(passport);
        Navigator.of(context).pop(passport);

        // Abre diretamente o passaporte oficial emitido
        PetPassportDetailSheet.show(context, passport: passport);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isMinting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao emitir passaporte: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF9945FF).withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9945FF).withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Topo com ícone e badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9945FF), Color(0xFF14F195)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14F195).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'TECNOLOGIA SOLANA cNFT',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF14F195),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Passaporte Digital do Pet',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.darkBG,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Texto explicativo amigável
          Text(
            'Crie a certidão digital oficial de ${widget.pet.name}. Um documento vitalício, infalsificável e aceito em clínicas e viagens — sem custos para você:',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 16),

          // 3 Pilares com Ícones
          _buildPillarItem(
            icon: Icons.memory_rounded,
            color: const Color(0xFF14F195),
            title: 'Microchip ISO 11784 (RG Digital)',
            description: 'Identificador internacional gerado para o pet, pronto para ser vinculado ao chip físico veterinário.',
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildPillarItem(
            icon: Icons.vaccines_rounded,
            color: const Color(0xFF9945FF),
            title: 'Caderneta de Vacinas Atualizável',
            description: 'Histórico auditável na Solana. Novas vacinas são somadas à mesma identidade para sempre.',
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildPillarItem(
            icon: Icons.energy_savings_leaf_rounded,
            color: const Color(0xFF38BDF8),
            title: 'Sem Burocracia ou Custo (Gasless)',
            description: 'Você não precisa de criptomoedas nem entender de finanças. O Patas cuida de tudo.',
            isDark: isDark,
          ),

          const SizedBox(height: 14),

          // Botão Didático de Tira-Dúvidas / O que é Blockchain
          InkWell(
            onTap: () => _showFaqDialog(context, isDark, widget.pet.name),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF9945FF).withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.help_outline_rounded,
                    color: Color(0xFF9945FF),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'O que é Blockchain e Passaporte? Tire suas dúvidas',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFC084FC) : const Color(0xFF7E22CE),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Botão Principal ou Progresso de Emissão
          if (_isMinting) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF14F195).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF14F195),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _mintStep,
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.darkBG,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: _startMint,
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: const Text(
                'Emitir Passaporte Oficial On-Chain',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9945FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Agora Não',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPillarItem({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.darkBG,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.black54,
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

  void _showFaqDialog(BuildContext context, bool isDark, String petName) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 650),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF9945FF).withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 25,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Topo do Modal
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9945FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.lightbulb_rounded,
                          color: Color(0xFF9945FF),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Entenda em 1 Minuto',
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.darkBG,
                              ),
                            ),
                            Text(
                              'Sem jargões complicados, tudo direto ao ponto.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark ? Colors.white60 : Colors.black54,
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Lista Scrollável de Perguntas e Respostas
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildFaqItem(
                          isDark: isDark,
                          icon: Icons.account_balance_rounded,
                          color: const Color(0xFF9945FF),
                          question: 'O que é essa tal de Blockchain?',
                          answer:
                              'Imagine um cartório digital mundial, aberto 24 horas por dia, que não pertence a nenhuma empresa ou governo. '
                              'Ao registrar a certidão de $petName lá, os dados ficam carimbados para sempre e ninguém no mundo pode apagar, alterar ou falsificar a identidade dele.',
                        ),
                        const SizedBox(height: 12),
                        _buildFaqItem(
                          isDark: isDark,
                          icon: Icons.memory_rounded,
                          color: const Color(0xFF14F195),
                          question: 'Esse Microchip é o mesmo que o veterinário aplica?',
                          answer:
                              'Sim, segue exatamente o mesmo padrão internacional (ISO 11784). Ao emitir no Patas, geramos um RG Digital provisório. '
                              'Quando você levar $petName para colocar o microchip físico (o grãozinho injetado sob a pele), você poderá cadastrar o número definitivo aqui para vincular tudo no mesmo passaporte!',
                        ),
                        const SizedBox(height: 12),
                        _buildFaqItem(
                          isDark: isDark,
                          icon: Icons.vaccines_rounded,
                          color: const Color(0xFF38BDF8),
                          question: 'E quando $petName tomar novas vacinas no futuro?',
                          answer:
                              'O passaporte tem uma chave única permanente (como um CPF). Toda vez que você ou a clínica cadastrar uma nova vacina no Patas, '
                              'o registro on-chain na Solana é atualizado com o novo carimbo sanitário, somando ao histórico sem precisar criar outro documento.',
                        ),
                        const SizedBox(height: 12),
                        _buildFaqItem(
                          isDark: isDark,
                          icon: Icons.price_check_rounded,
                          color: const Color(0xFFF59E0B),
                          question: 'Eu preciso pagar ou entender de criptomoedas?',
                          answer:
                              'Não! O processo é 100% gratuito para você. O Patas cobre todas as taxas da rede Solana e faz tudo de forma automática nos bastidores. Você só aproveita a segurança.',
                        ),
                      ],
                    ),
                  ),
                ),

                // Botão Fechar no Rodapé
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9945FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Entendi! Voltar para a Emissão',
                      style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem({
    required bool isDark,
    required IconData icon,
    required Color color,
    required String question,
    required String answer,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  question,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.darkBG,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
