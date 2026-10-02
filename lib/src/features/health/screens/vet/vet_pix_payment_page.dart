import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import '../../models/vet_profile_model.dart';
import '../../models/vet_subscription_model.dart';

class VetPixPaymentPage extends StatefulWidget {
  final VetInvoice invoice;
  final VetProfile vetProfile;

  const VetPixPaymentPage({
    super.key,
    required this.invoice,
    required this.vetProfile,
  });

  @override
  State<VetPixPaymentPage> createState() => _VetPixPaymentPageState();
}

class _VetPixPaymentPageState extends State<VetPixPaymentPage> {
  final SupabaseClient _client = Supabase.instance.client;
  RealtimeChannel? _channel;
  bool _isApproved = false;

  @override
  void initState() {
    super.initState();
    _listenToPaymentStatus();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  void _listenToPaymentStatus() {
    _channel = _client
        .channel('vet_invoice_status_${widget.invoice.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'vet_invoices',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.invoice.id,
          ),
          callback: (payload) {
            final newStatus = payload.newRecord['status'];
            if (newStatus == 'paid' && mounted) {
              setState(() => _isApproved = true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pagamento PIX confirmado com sucesso! Assinatura ativada.'),
                  backgroundColor: Colors.green,
                ),
              );
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) Navigator.pop(context, true);
              });
            }
          },
        )
        .subscribe();
  }

  void _copyPixKey() {
    final keyText = widget.invoice.pixCopyPaste ?? widget.invoice.pixQrCode ?? '';
    if (keyText.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: keyText));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chave PIX Copia e Cola copiada para a área de transferência!'),
          backgroundColor: AppColors.patasColor,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final isDesktop = context.isDesktop;
    final scaffoldBg = isDark ? AppColors.bodygray : const Color(0xFFF5F7FA);

    Widget content = Column(
      children: [
        // Status Icon / Animation
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isApproved
                ? Colors.green.withValues(alpha: 0.15)
                : AppColors.patasColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _isApproved ? Icons.check_circle_rounded : Icons.pix_rounded,
            size: 56,
            color: _isApproved ? Colors.green : AppColors.patasColor,
          ),
        ),
        const SizedBox(height: 16),

        Text(
          _isApproved ? 'Pagamento Confirmado!' : 'Aguardando Pagamento PIX',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.darkBG,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _isApproved
              ? 'Sua assinatura profissional foi ativada!'
              : 'Escaneie o QR Code abaixo com o aplicativo do seu banco:',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 24),

        // QR Code Container
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: (widget.invoice.pixQrCode != null && widget.invoice.pixQrCode!.isNotEmpty)
              ? Image.network(
                  widget.invoice.pixQrCode!,
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_2_rounded, size: 140, color: AppColors.patasColor),
                      Text('QR Code indisponível', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                )
              : const Icon(Icons.qr_code_2_rounded, size: 180, color: AppColors.patasColor),
        ),
        const SizedBox(height: 24),

        // Valor a pagar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Valor Total:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              Text(
                'R\$ ${widget.invoice.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.patasColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Botão Copiar PIX
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.copy_rounded, color: Colors.white),
            label: const Text('Copiar Chave PIX (Copia e Cola)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: _copyPixKey,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.patasColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Botão Já Realizei o Pagamento
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context, true),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.patasColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Já Realizei o Pagamento', style: TextStyle(color: AppColors.patasColor, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );

    if (isDesktop) {
      content = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Card(
              elevation: 0,
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: content,
              ),
            ),
          ),
        ),
      );
    }

    final mainScaffold = Scaffold(
      backgroundColor: scaffoldBg,
      appBar: const PatasEssencialAppBar(
        title: 'Pagamento PIX',
        subtitle: 'Instruções e QR Code para pagamento instantâneo',
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 24 : 20,
          vertical: 10,
        ).copyWith(bottom: 100),
        child: content,
      ),
    );

    return mainScaffold;
  }
}
