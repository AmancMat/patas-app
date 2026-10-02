import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PixPaymentPage extends StatefulWidget {
  final Map<String, dynamic> invoice;

  const PixPaymentPage({
    super.key,
    required this.invoice,
  });

  @override
  State<PixPaymentPage> createState() => _PixPaymentPageState();
}

class _PixPaymentPageState extends State<PixPaymentPage> {
  final _client = Supabase.instance.client;
  bool _isCopied = false;
  bool _isSimulatingPayment = false;
  late StreamSubscription _paymentListener;
  bool _paymentConfirmed = false;

  @override
  void initState() {
    super.initState();
    _startPaymentListener();
  }

  void _startPaymentListener() {
    // Escuta em tempo real se a fatura foi paga no banco
    _paymentListener = _client
        .from('invoices')
        .stream(primaryKey: ['id'])
        .eq('id', widget.invoice['id'])
        .listen((data) {
          if (data.isNotEmpty) {
            final invoiceStatus = data.first['status'];
            if (invoiceStatus == 'paid' && !_paymentConfirmed) {
              setState(() {
                _paymentConfirmed = true;
              });
              _showSuccessDialog();
            }
          }
        });
  }

  @override
  void dispose() {
    _paymentListener.cancel();
    super.dispose();
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.invoice['pix_copia_cola'] ?? ''));
    setState(() => _isCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  // Método de simulação para testar localmente a aprovação do PIX
  Future<void> _simulatePaymentApproval() async {
    setState(() => _isSimulatingPayment = true);
    try {
      final now = DateTime.now();

      // 1. Atualiza a fatura para paga (paid) com timeout
      await _client.from('invoices').update({
        'status': 'paid',
        'paid_at': now.toIso8601String(),
      }).eq('id', widget.invoice['id']).timeout(const Duration(seconds: 4));

      // 2. Atualiza a assinatura vinculada para ativa (active) com timeout
      final subId = widget.invoice['subscription_id'];
      await _client.from('subscriptions').update({
        'status': 'active',
        'current_period_start': widget.invoice['period_start'],
        'current_period_end': widget.invoice['period_end'],
        'grace_period_ends_at': DateTime.parse(widget.invoice['period_end'])
            .add(const Duration(days: 7))
            .toIso8601String(),
      }).eq('id', subId).timeout(const Duration(seconds: 4));

      debugPrint('Simulação: Pagamento do PIX aprovado com sucesso.');
      if (!_paymentConfirmed) {
        setState(() {
          _paymentConfirmed = true;
        });
        _showSuccessDialog();
      }
    } catch (e) {
      debugPrint('Erro na simulação do PIX: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ou lentidão na rede ao simular PIX: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSimulatingPayment = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pagamento Aprovado!',
                  style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const Text(
            'Sua assinatura do Patas Encontra foi ativada com sucesso! Suas tags inteligentes já estão ativas e protegidas.',
            style: TextStyle(fontFamily: 'Roboto_flex'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // fecha dialog
                Navigator.of(context).pop(true); // volta para a página anterior indicando sucesso
              },
              child: const Text(
                'Entendido',
                style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: AppColors.patasColor),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final value = (widget.invoice['amount_in_cents'] ?? 0) / 100;
    
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 800;

    // Coluna esquerda com instruções de uso e simulação
    final infoColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isDesktop) ...[
          Text(
            'Aguardando Pagamento',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.bodyAbsoluteBlack,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Abra o aplicativo do seu banco e escaneie o QR Code ou cole a chave PIX copia e cola abaixo.',
            style: TextStyle(
              fontFamily: 'Roboto_flex',
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ] else ...[
          Text(
            'Aguardando Pagamento',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.bodyAbsoluteBlack,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Abra o aplicativo do seu banco e escaneie o QR Code ao lado para realizar o pagamento. Se preferir, você também pode copiar a chave PIX Copia e Cola para finalizar a sua assinatura.',
            style: TextStyle(
              fontFamily: 'Roboto_flex',
              fontSize: 15,
              color: isDark ? Colors.white70 : Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
        ],

        // Botão Pix Copia e Cola
        ElevatedButton.icon(
          onPressed: _copyToClipboard,
          icon: Icon(_isCopied ? Icons.check : Icons.copy, size: 20),
          label: Text(
            _isCopied ? 'Chave Copiada com Sucesso!' : 'Copiar PIX Copia e Cola',
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isCopied ? Colors.green : AppColors.patasColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
        ),
        const SizedBox(height: 28),

        // Seção de Simulação Local (Importante para testes)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.orange.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.bug_report_outlined, color: Colors.orange, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Ambiente de Simulação',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Como não há um banco real conectado ao ambiente de testes, clique no botão abaixo para simular que o banco autorizou o pagamento do PIX e atualizar o banco.',
                style: TextStyle(
                  fontFamily: 'Roboto_flex',
                  fontSize: 12,
                  color: Colors.orange,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: OutlinedButton(
                  onPressed: _isSimulatingPayment ? null : _simulatePaymentApproval,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange, width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSimulatingPayment
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                          ),
                        )
                      : const Text(
                          'Simular Confirmação de PIX',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    // Card do QR Code
    final qrCodeCard = Card(
      elevation: 0,
      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.invoice['pix_qr_code_url'] != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Image.network(
                  widget.invoice['pix_qr_code_url'],
                  height: 220,
                  width: 220,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 220,
                    width: 220,
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.qr_code_2_rounded, size: 80, color: Colors.grey),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Text(
              'Valor da Assinatura',
              style: TextStyle(
                fontFamily: 'Roboto_flex',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white60 : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'R\$ ${value.toStringAsFixed(2)}',
              style: const TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.patasColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined, size: 14, color: Colors.green.shade400),
                const SizedBox(width: 6),
                Text(
                  'Pagamento 100% Seguro',
                  style: TextStyle(
                    fontFamily: 'Roboto_flex',
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
      appBar: const PatasEssencialAppBar(
        title: 'Pagamento via PIX',
        subtitle: 'Escaneie ou copie a chave para ativar',
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1050),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Lado Esquerdo: Textos, Ações e Simulação
                      Expanded(
                        flex: 6,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 48.0),
                          child: infoColumn,
                        ),
                      ),
                      // Lado Direito: QR Code e Detalhes
                      Expanded(
                        flex: 4,
                        child: qrCodeCard,
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      infoColumn,
                      const SizedBox(height: 24),
                      qrCodeCard,
                      const SizedBox(height: 140), // Padding de segurança para não ser encoberto pela BottomNavigationBar
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
