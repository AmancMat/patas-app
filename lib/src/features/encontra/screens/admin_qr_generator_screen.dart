import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/constants/routes.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/providers/user_role_provider.dart';
import 'package:patas_web_app/src/features/encontra/services/qr_generator_service.dart';

class AdminQrGeneratorScreen extends StatefulWidget {
  const AdminQrGeneratorScreen({super.key});

  @override
  State<AdminQrGeneratorScreen> createState() => _AdminQrGeneratorScreenState();
}

class _AdminQrGeneratorScreenState extends State<AdminQrGeneratorScreen> {
  final _generatorService = QrGeneratorService();
  final _qtyController = TextEditingController(text: '50');

  int _quantity = 50;
  bool _isGenerating = false;
  String _statusMessage = '';
  double _progressPercent = 0.0;

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  void _onQtyChanged(String val) {
    final parsed = int.tryParse(val);
    if (parsed != null) {
      setState(() {
        _quantity = parsed.clamp(1, 500);
      });
    }
  }

  Future<void> _startGeneration() async {
    // Valida limites antes de iniciar
    if (_quantity < 1 || _quantity > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione uma quantidade entre 1 e 500.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _statusMessage = 'Iniciando processo...';
      _progressPercent = 0.0;
    });

    try {
      final success = await _generatorService.generateBatch(
        quantity: _quantity,
        onProgress: (status, progress) {
          setState(() {
            _statusMessage = status;
            _progressPercent = progress;
          });
        },
      );

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Lote de tags gerado e baixado com sucesso!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text(
              'Erro na Geração',
              style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold),
            ),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Entendido', style: TextStyle(color: AppColors.patasColor)),
              )
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _progressPercent = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    // 1. Camada de Segurança: Verifica a role do usuário no provider
    final roleProvider = Provider.of<UserRoleProvider>(context);
    
    if (roleProvider.role != UserRole.admin) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 64, color: AppColors.patasColor),
                const SizedBox(height: 24),
                const Text(
                  'Acesso Restrito',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.patasColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Você não tem as credenciais necessárias de administrador para acessar o painel de geração de QR Codes.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(context, NamedRoute.home, (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.patasColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Voltar ao Início', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.patasColor,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Gerador de Tags',
          style: TextStyle(
            fontFamily: 'Fredoka',
            color: AppColors.patasColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 550),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildIntroBanner(isDark),
                const SizedBox(height: 24),
                _buildGeneratorCard(isDark),
                const SizedBox(height: 24),
                _buildInfoCard(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntroBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.patasColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.patasColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.qr_code_2_rounded, size: 48, color: AppColors.patasColor),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Painel Administrativo',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.patasColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gere em lote UUIDs, PINs, salve no banco e baixe os arquivos de imagem para produção das tags físicas.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGeneratorCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Configurar Lote',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : AppColors.darkBG,
            ),
          ),
          const SizedBox(height: 16),

          // Seletor numérico e Slider lado a lado
          Row(
            children: [
              Expanded(
                flex: 7,
                child: Slider(
                  value: _quantity.toDouble(),
                  min: 1,
                  max: 500,
                  divisions: 499,
                  activeColor: AppColors.patasColor,
                  inactiveColor: isDark ? Colors.white10 : Colors.grey.shade200,
                  label: '$_quantity',
                  onChanged: _isGenerating 
                      ? null 
                      : (val) {
                          setState(() {
                            _quantity = val.round();
                            _qtyController.text = _quantity.toString();
                          });
                        },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _qtyController,
                  keyboardType: TextInputType.number,
                  enabled: !_isGenerating,
                  onChanged: _onQtyChanged,
                  decoration: const InputDecoration(
                    labelText: 'Qtd.',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Painel de progresso da geração
          if (_isGenerating) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: _progressPercent,
                    backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.patasColor),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(_progressPercent * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.patasColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Botão Gerar
          ElevatedButton.icon(
            onPressed: _isGenerating ? null : _startGeneration,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.patasColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            icon: const Icon(Icons.bolt),
            label: Text(
              _isGenerating ? 'Gerando Lote...' : 'Gerar e Baixar Lote (ZIP)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blueAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                'Observações Importantes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDark ? Colors.white70 : AppColors.darkBG,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBulletPoint(isDark, 'Os QR Codes gerados contêm o link direcionado para a página pública de busca do pet: https://patas.online/encontra/t/<UUID>.'),
          const SizedBox(height: 8),
          _buildBulletPoint(isDark, 'O arquivo CSV gerado contém o código PIN correspondente de cada tag. Este PIN deve ser impresso no adesivo protetor raspável (raspadinha) de cada tag.'),
          const SizedBox(height: 8),
          _buildBulletPoint(isDark, 'Apenas o administrador do Patas possui permissões para executar este processo em lote devido às políticas RLS de gravação.'),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(bool isDark, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('• ', style: TextStyle(fontSize: 14, color: isDark ? Colors.white60 : Colors.black54)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54, height: 1.3),
          ),
        ),
      ],
    );
  }
}
