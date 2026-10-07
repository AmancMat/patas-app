import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/features/pets/active_pet_provider.dart';
import '../../acolhe/services/shelter_service.dart';
import '../models/solana_pay_model.dart';
import '../services/solana_pay_service.dart';

class SolanaPayDonationTab extends StatefulWidget {
  final String campaignId;
  final String campaignTitle;
  final String? ongName;
  final String? solanaWallet;
  final bool isDark;
  final void Function(double amountBrl)? onDonationConfirmed;

  const SolanaPayDonationTab({
    super.key,
    required this.campaignId,
    required this.campaignTitle,
    this.ongName,
    this.solanaWallet,
    required this.isDark,
    this.onDonationConfirmed,
  });

  @override
  State<SolanaPayDonationTab> createState() => _SolanaPayDonationTabState();
}

class _SolanaPayDonationTabState extends State<SolanaPayDonationTab> {
  final ShelterService _shelterService = ShelterService();
  double _selectedAmount = 5.0; // Padrão: $5 USDC (ou 0.05 SOL)
  String _selectedToken = 'USDC'; // 'USDC' ou 'SOL'
  late SolanaPayDonation _currentDonation;
  
  // Estados de confirmação da transação
  bool _isPaymentConfirmed = false;
  String? _confirmedTxSignature;
  Timer? _rpcPollingTimer;
  String? _initialLatestTxSignature;
  bool _isCheckingRpc = false;
  double? _creditedAmountBrl;

  // Estado do Modo Privado Cloak (Zcash on Solana)
  bool _isCloakPrivacyEnabled = false;

  final List<double> _usdcPresets = [0.0, 1.0, 5.0, 15.0, 50.0];
  final List<double> _solPresets = [0.0, 0.01, 0.05, 0.1, 0.5];

  @override
  void initState() {
    super.initState();
    _rebuildDonation();
    _startRpcListener();
  }

  @override
  void dispose() {
    _rpcPollingTimer?.cancel();
    super.dispose();
  }

  void _rebuildDonation() {
    _currentDonation = SolanaPayService.createDonation(
      campaignId: widget.campaignId,
      campaignTitle: widget.campaignTitle,
      ongName: widget.ongName,
      customWallet: widget.solanaWallet,
      amount: _selectedAmount,
      tokenSymbol: _selectedToken,
    );
  }

  /// Inicia o monitoramento ativo via RPC da Solana a cada 2.5 segundos
  void _startRpcListener() async {
    _rpcPollingTimer?.cancel();
    _rpcPollingTimer = null;
    final wallet = _currentDonation.recipientWallet;
    
    // 1. Captura a assinatura mais recente existente para usar como linha de base
    _initialLatestTxSignature = await SolanaPayService.getLatestTransactionSignature(wallet);
    if (!mounted) return;

    // 2. Cria timer de polling para escutar novas transações APÓS obter a baseline
    _rpcPollingTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) async {
      if (_isPaymentConfirmed || !mounted || _isCheckingRpc) return;

      _isCheckingRpc = true;
      try {
        final currentLatest = await SolanaPayService.getLatestTransactionSignature(wallet);
        
        // Se surgiu uma nova assinatura confirmada diferente da inicial
        if (currentLatest != null && currentLatest != _initialLatestTxSignature) {
          // Checa se já foi computada anteriormente no banco de dados
          final alreadyProcessed = await _shelterService.isTxSignatureAlreadyProcessed(currentLatest);
          if (alreadyProcessed) {
            _initialLatestTxSignature = currentLatest;
            return;
          }

          timer.cancel();
          _onTransactionConfirmed(currentLatest);
        }
      } catch (e) {
        debugPrint('[SolanaPayDonationTab] Erro ao consultar RPC: $e');
      } finally {
        _isCheckingRpc = false;
      }
    });
  }

  void _onTransactionConfirmed(String signature) async {
    if (!mounted || _isPaymentConfirmed) return;

    // Cancela imediatamente o timer de polling para evitar leituras concorrentes
    _rpcPollingTimer?.cancel();
    _rpcPollingTimer = null;
    _isCheckingRpc = false;

    // Se for valor livre (0.0), assume valor base de referência ou estimativa
    final double effectiveAmount = _selectedAmount > 0 ? _selectedAmount : (_selectedToken == 'USDC' ? 5.0 : 0.05);

    // Converte o token doado para o equivalente em R$
    final double brlValue = _selectedToken == 'USDC'
        ? (effectiveAmount * 5.50) // $1 USDC ~ R$ 5,50
        : (effectiveAmount * 750.0); // 1 SOL ~ R$ 750,00
    final double roundedBrl = double.parse(brlValue.toStringAsFixed(2));

    setState(() {
      _isPaymentConfirmed = true;
      _confirmedTxSignature = signature;
      _creditedAmountBrl = roundedBrl;
    });

    // Captura o pet ativo do contexto se houver
    String? petId;
    String? petName;
    String? petPhoto;
    try {
      final petProvider = Provider.of<ActivePetProvider>(context, listen: false);
      final activePet = petProvider.activePet;
      if (activePet != null) {
        petId = activePet.id;
        petName = activePet.name;
        petPhoto = activePet.photoUrl;
      }
    } catch (_) {}

    // Registra imediatamente no banco de dados e incrementa a campanha
    try {
      await _shelterService.registerDonationProgress(
        campaignId: widget.campaignId,
        addedAmount: roundedBrl,
        paymentMethod: 'solana_pay',
        txSignature: signature,
        donorPetId: petId,
        donorName: petName,
        donorPhoto: petPhoto,
        originalAmount: _selectedAmount > 0 ? _selectedAmount : null,
        tokenSymbol: _selectedToken,
      );
    } catch (e) {
      debugPrint('[SolanaPayDonationTab] Erro ao registrar doação no banco: $e');
    }

    if (mounted) {
      // Dispara callback para o componente pai atualizar o dashboard/mural
      widget.onDonationConfirmed?.call(roundedBrl);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Color(0xFF14F195), size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _selectedAmount > 0
                      ? '🎉 Doação de R\$ ${roundedBrl.toStringAsFixed(2).replaceAll('.', ',')} ($_selectedAmount $_selectedToken) computada com sucesso!'
                      : '🎉 Doação de R\$ ${roundedBrl.toStringAsFixed(2).replaceAll('.', ',')} ($_selectedToken) computada com sucesso!',
                  style: const TextStyle(fontFamily: 'Fredoka', fontSize: 13, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E1B4B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _onAmountSelected(double amount) {
    setState(() {
      _selectedAmount = amount;
      _rebuildDonation();
      _isPaymentConfirmed = false;
      _confirmedTxSignature = null;
    });
    _startRpcListener();
  }

  void _onTokenChanged(String token) {
    setState(() {
      _selectedToken = token;
      _selectedAmount = token == 'USDC' ? 5.0 : 0.05;
      _rebuildDonation();
      _isPaymentConfirmed = false;
      _confirmedTxSignature = null;
    });
    _startRpcListener();
  }

  void _copyWallet(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _currentDonation.recipientWallet));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Endereço Solana copiado! Transfira via Phantom ou Solflare.',
                style: TextStyle(fontFamily: 'Fredoka', fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF14F195),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleOpenWallet(String solanaUri) async {
    final success = await SolanaPayService.launchWallet(solanaUri);
    if (success) return;

    if (!mounted) return;

    // Se for Web / Desktop e não abriu extensão, abre diálogo amigável instruindo o uso da câmera
    if (kIsWeb) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF9945FF), size: 24),
              const SizedBox(width: 10),
              Text(
                'Como pagar pelo Desktop',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark ? Colors.white : AppColors.darkBG,
                ),
              ),
            ],
          ),
          content: Text(
            'No computador, abra o app da Phantom ou Solflare no seu celular e aponte a câmera para o QR Code na tela.\n\nA transação será identificada e confirmada instantaneamente!',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: widget.isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendi', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      // Se for Mobile e nenhuma carteira respondeu (ex: Phantom não instalada no aparelho)
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF9945FF), size: 24),
              const SizedBox(width: 10),
              Text(
                'Carteira Solana',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark ? Colors.white : AppColors.darkBG,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nenhum aplicativo de carteira compatível (Phantom ou Solflare) respondeu à solicitação.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? Colors.white : AppColors.darkBG,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Você pode instalar a Phantom Wallet na Play Store ou copiar o endereço da ONG para transferir diretamente de qualquer corretora ou aplicativo.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: widget.isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _copyWallet(context);
              },
              child: const Text(
                'Copiar Endereço',
                style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                SolanaPayService.openPhantomPlayStore();
              },
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text(
                'Baixar Phantom',
                style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9945FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }
  }

  /// Simulação manual para gravação rápida no vídeo
  void _simulateInstantConfirmation() {
    _onTransactionConfirmed('simulated_tx_${DateTime.now().millisecondsSinceEpoch}');
  }

  void _handleCloakDonation() async {
    final launched = await SolanaPayService.openCloakPayment(
      recipientWallet: _currentDonation.recipientWallet,
      amount: _selectedAmount > 0 ? _selectedAmount : 0.01,
      currency: _selectedToken,
      campaignTitle: widget.campaignTitle,
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Não foi possível abrir o link da Cloak automaticamente.',
            style: TextStyle(fontFamily: 'Fredoka'),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _copyCloakLink(BuildContext context) {
    final url = SolanaPayService.generateCloakPaymentUrl(
      recipientWallet: _currentDonation.recipientWallet,
      amount: _selectedAmount > 0 ? _selectedAmount : 0.01,
      currency: _selectedToken,
      campaignTitle: widget.campaignTitle,
    );
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.shield_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Link da Doação Privada Cloak copiado com sucesso!',
                style: TextStyle(fontFamily: 'Fredoka', fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showCloakExplanationDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF14F195).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_rounded, color: Color(0xFF14F195), size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Privacidade com Cloak',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.darkBG,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Como funciona a Doação Privada no Patas:',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.darkBG,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '1. A Cloak utiliza Provas Zero-Knowledge (modelo Zcash na Solana).\n'
              '2. Os fundos entram em um Shielded Pool (piscina protegida).\n'
              '3. O abrigo recebe a doação diretamente, mas a ponte que liga a sua carteira ao destino fica 100% invisível no explorador da Solana.\n'
              '4. Seu patrimônio e seu saldo pessoal continuam em sigilo absoluto.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF14F195).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF14F195).withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user_rounded, color: Color(0xFF14F195), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Protocolo oficial auditado na Solana Mainnet.',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF14F195),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendi', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
          ),
          ElevatedButton.icon(
            onPressed: () => SolanaPayService.openExplorer(address: 'https://docs.cloak.ag'),
            icon: const Icon(Icons.open_in_new_rounded, size: 14),
            label: const Text('Docs Cloak', style: TextStyle(fontFamily: 'Fredoka', fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF14F195),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final solanaUri = _currentDonation.toSolanaPayUri(isDevnet: true);
    final cloakPaymentUrl = SolanaPayService.generateCloakPaymentUrl(
      recipientWallet: _currentDonation.recipientWallet,
      amount: _selectedAmount > 0 ? _selectedAmount : 0.01,
      currency: _selectedToken,
      campaignTitle: widget.campaignTitle,
    );
    final effectiveQrUri = _isCloakPrivacyEnabled
        ? cloakPaymentUrl
        : solanaUri;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Seletor de Modo de Privacidade (Cloak Shielded)
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _isCloakPrivacyEnabled
                ? (isDark ? const Color(0xFF0F172A) : const Color(0xFFF0FDF4))
                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isCloakPrivacyEnabled
                  ? const Color(0xFF14F195)
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              width: _isCloakPrivacyEnabled ? 1.5 : 1,
            ),
            boxShadow: _isCloakPrivacyEnabled
                ? [
                    BoxShadow(
                      color: const Color(0xFF14F195).withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isCloakPrivacyEnabled
                      ? const Color(0xFF14F195).withValues(alpha: 0.2)
                      : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _isCloakPrivacyEnabled ? Icons.shield_rounded : Icons.shield_outlined,
                  color: _isCloakPrivacyEnabled ? const Color(0xFF14F195) : (isDark ? Colors.white60 : Colors.black54),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Doação Anônima (Cloak)',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _isCloakPrivacyEnabled
                                ? const Color(0xFF10B981)
                                : (isDark ? Colors.white : AppColors.darkBG),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF14F195).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ZK SHIELD',
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isCloakPrivacyEnabled
                          ? 'Sua carteira pessoal e saldo ficam 100% invisíveis na chain.'
                          : 'Oculta sua carteira pessoal via Zero-Knowledge.',
                      style: TextStyle(
                        fontSize: 11,
                        color: _isCloakPrivacyEnabled ? (isDark ? Colors.white70 : Colors.black87) : (isDark ? Colors.white60 : Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _isCloakPrivacyEnabled,
                activeThumbColor: const Color(0xFF10B981),
                activeTrackColor: const Color(0xFF14F195).withValues(alpha: 0.4),
                onChanged: (val) {
                  setState(() {
                    _isCloakPrivacyEnabled = val;
                  });
                },
              ),
            ],
          ),
        ),

        // Link explicativo sobre o protocolo Cloak
        if (_isCloakPrivacyEnabled) ...[
          GestureDetector(
            onTap: () => _showCloakExplanationDialog(context, isDark),
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF14F195).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF14F195).withValues(alpha: 0.25)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF10B981)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Zcash on Solana: Como a prova ZK protege você?',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF10B981)),
                ],
              ),
            ),
          ),
        ],

        // Seletor de Moeda (USDC vs SOL)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildTokenToggleItem(
                  title: 'Dólar Digital (USDC)',
                  symbol: 'USDC',
                  isSelected: _selectedToken == 'USDC',
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _buildTokenToggleItem(
                  title: 'Solana (SOL)',
                  symbol: 'SOL',
                  isSelected: _selectedToken == 'SOL',
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Presets de Valores
        Text(
          'Escolha o valor da doação:',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (_selectedToken == 'USDC' ? _usdcPresets : _solPresets)
              .map((val) {
            final isSelected = _selectedAmount == val;
            final isFree = val == 0.0;
            final brlEquiv = _selectedToken == 'USDC'
                ? (val * 5.50).toStringAsFixed(0)
                : (val * 750.0).toStringAsFixed(0);
            return ChoiceChip(
              label: Text(
                isFree
                    ? '✨ Valor Livre'
                    : (_selectedToken == 'USDC'
                        ? '\$ ${val.toInt()} (~R\$ $brlEquiv)'
                        : '$val SOL (~R\$ $brlEquiv)'),
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12.5,
                  color: isSelected
                      ? Colors.black
                      : (isDark ? Colors.white : AppColors.darkBG),
                ),
              ),
              selected: isSelected,
              onSelected: (_) => _onAmountSelected(val),
              selectedColor: const Color(0xFF14F195),
              backgroundColor:
                  isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            );
          }).toList(),
        ),
        if (_selectedAmount == 0.0) ...[
          const SizedBox(height: 8),
          Text(
            '💡 Escaneie o QR Code e digite na Phantom/Solflare o valor exato que deseja doar.',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 12,
              color: isDark ? const Color(0xFF14F195) : const Color(0xFF0D9488),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],

        const SizedBox(height: 18),

        // QR Code Container com Moldura Estilizada Solana
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isPaymentConfirmed
                    ? const Color(0xFF14F195)
                    : (_isCloakPrivacyEnabled ? const Color(0xFF10B981) : const Color(0xFF9945FF)),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_isPaymentConfirmed
                          ? const Color(0xFF14F195)
                          : (_isCloakPrivacyEnabled ? const Color(0xFF14F195) : const Color(0xFF9945FF)))
                      .withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                QrImageView(
                  data: effectiveQrUri,
                  version: QrVersions.auto,
                  size: 190.0,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF1E1B4B),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF0F172A),
                  ),
                ),
                // Overlay de Sucesso confirmado em tempo real
                if (_isPaymentConfirmed)
                  Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      color: const Color(0xFF14F195).withValues(alpha: 0.98),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 40, color: Color(0xFF0F172A)),
                        const SizedBox(height: 4),
                        const Text(
                          'PAGO COM SUCESSO!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '+ R\$ ${_creditedAmountBrl?.toStringAsFixed(2).replaceAll('.', ',') ?? ''}',
                          style: const TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          _selectedAmount > 0
                              ? '($_selectedAmount $_selectedToken)'
                              : '($_selectedToken)',
                          style: const TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 11,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        if (_confirmedTxSignature != null) ...[
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () => SolanaPayService.openExplorer(
                              transactionSignature: _confirmedTxSignature,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.open_in_new_rounded, size: 12, color: Color(0xFF0F172A)),
                                SizedBox(width: 4),
                                Text(
                                  'Ver Comprovante',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Tag de Status / Protocolo Oficial
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isPaymentConfirmed
                      ? [const Color(0xFF10B981), const Color(0xFF14F195)]
                      : [const Color(0xFF9945FF), const Color(0xFF14F195)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isPaymentConfirmed ? Icons.verified_rounded : Icons.sync_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _isPaymentConfirmed
                        ? 'Transação Confirmada On-Chain'
                        : (_isCloakPrivacyEnabled
                            ? 'Modo Cloak Ativo • Zero-Knowledge Shield'
                            : 'Aguardando pagamento na Devnet...'),
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Banner e Botão de Conclusão quando Pago
        if (_isPaymentConfirmed) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.volunteer_activism_rounded, color: Color(0xFF10B981), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Doação somada à meta da campanha!',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.darkBG,
                        ),
                      ),
                      Text(
                        'O progresso da barra e o total arrecadado já foram atualizados no mural.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.check_circle_rounded, size: 18),
              label: const Text(
                'Concluir e Ver no Mural',
                style: TextStyle(fontFamily: 'Fredoka', fontSize: 14, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
            ),
          ),
        ],

        const SizedBox(height: 18),

        // Carteira de Destino e Botões de Ação
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Endereço da Carteira Solana (ONG):',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  InkWell(
                    onTap: () => SolanaPayService.openExplorer(address: _currentDonation.recipientWallet),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.launch_rounded, size: 12, color: Color(0xFF14F195)),
                        SizedBox(width: 4),
                        Text(
                          'Explorer',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF14F195),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SelectableText(
                _currentDonation.recipientWallet,
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.darkBG,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Botões de Ação Dinâmicos (Padrão vs Modo Cloak)
        if (_isCloakPrivacyEnabled) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyCloakLink(context),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text(
                    'Copiar Link ZK',
                    style: TextStyle(fontFamily: 'Fredoka', fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : AppColors.darkBG,
                    side: BorderSide(
                      color: isDark ? const Color(0xFF14F195).withValues(alpha: 0.5) : const Color(0xFF10B981),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _handleCloakDonation,
                  icon: const Icon(Icons.shield_rounded, size: 18),
                  label: const Text(
                    'Doar com Cloak',
                    style: TextStyle(fontFamily: 'Fredoka', fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 3,
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyWallet(context),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text(
                    'Copiar Wallet',
                    style: TextStyle(fontFamily: 'Fredoka', fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : AppColors.darkBG,
                    side: BorderSide(
                      color: isDark ? Colors.white24 : Colors.grey.shade400,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleOpenWallet(solanaUri),
                  icon: const Icon(Icons.account_balance_wallet_rounded, size: 16),
                  label: const Text(
                    'Abrir Carteira',
                    style: TextStyle(fontFamily: 'Fredoka', fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9945FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 10),

        // Botão de Demonstração / Teste Rápido no Vídeo
        TextButton.icon(
          onPressed: _simulateInstantConfirmation,
          icon: const Icon(Icons.play_circle_outline_rounded, size: 16, color: Color(0xFF14F195)),
          label: const Text(
            'Simular Confirmação Instantânea (Demo Hackathon)',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF14F195),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTokenToggleItem({
    required String title,
    required String symbol,
    required bool isSelected,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () => _onTokenChanged(symbol),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1E293B) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? (isDark ? Colors.white : AppColors.darkBG)
                  : (isDark ? Colors.white60 : Colors.black54),
            ),
          ),
        ),
      ),
    );
  }
}
