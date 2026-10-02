import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models/solana_pay_model.dart';

class SolanaPayService {
  // Endereço público oficial de demonstração para a Devnet (carteira do Patas Acolhe Treasury)
  static const String defaultTreasuryWallet =
      '7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU';

  // Endpoint RPC oficial e gratuito da Solana Devnet
  static const String devnetRpcUrl = 'https://api.devnet.solana.com';

  /// Gera um ID de referência criptográfico aleatório para rastrear a transação on-chain
  static String generateReferenceId() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Cria uma nova doação preparada para Solana Pay
  static SolanaPayDonation createDonation({
    required String campaignId,
    required String campaignTitle,
    String? ongName,
    String? customWallet,
    required double amount,
    String tokenSymbol = 'USDC',
  }) {
    return SolanaPayDonation(
      recipientWallet: (customWallet != null && customWallet.trim().isNotEmpty)
          ? customWallet.trim()
          : defaultTreasuryWallet,
      amount: amount,
      tokenSymbol: tokenSymbol,
      referenceId: generateReferenceId(),
      campaignId: campaignId,
      campaignTitle: campaignTitle,
      ongName: ongName,
      createdAt: DateTime.now(),
    );
  }

  /// Consulta os validadores da Solana Devnet para verificar a última assinatura recebida
  /// Retorna a assinatura da transação mais recente se houver
  static Future<String?> getLatestTransactionSignature(String walletAddress) async {
    try {
      final response = await http.post(
        Uri.parse(devnetRpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'getSignaturesForAddress',
          'params': [
            walletAddress,
            {'limit': 1}
          ]
        }),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['result'] as List<dynamic>?;
        if (result != null && result.isNotEmpty) {
          final first = result.first as Map<String, dynamic>;
          final err = first['err'];
          // Apenas transações confirmadas com sucesso (sem erro)
          if (err == null) {
            return first['signature'] as String?;
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('[SolanaPayService] Erro ao consultar RPC da Solana: $e');
      return null;
    }
  }

  /// Consulta os validadores da Solana Devnet para listar assinaturas recentes recebidas
  static Future<List<Map<String, dynamic>>> getRecentSignatures(
    String walletAddress, {
    int limit = 10,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(devnetRpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'getSignaturesForAddress',
          'params': [
            walletAddress,
            {'limit': limit}
          ]
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['result'] as List<dynamic>?;
        if (result != null) {
          return result
              .whereType<Map<String, dynamic>>()
              .where((tx) => tx['err'] == null)
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('[SolanaPayService] Erro ao buscar assinaturas recentes: $e');
      return [];
    }
  }

  /// Tenta abrir o deep link diretamente no app da carteira (Phantom / Solflare / Solana Pay)
  static Future<bool> launchWallet(String solanaUri) async {
    try {
      final uri = Uri.parse(solanaUri);

      // 1. Tenta abrir diretamente com o esquema solana:
      try {
        if (await canLaunchUrl(uri)) {
          final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (launched) return true;
        } else {
          // Tentativa direta no Android caso canLaunchUrl retorne falso antes da primeira execução
          final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (launched) return true;
        }
      } catch (e) {
        debugPrint('[SolanaPayService] Tentativa solana: direta falhou: $e');
      }

      // 2. Fallback: Deep link universal da Phantom
      try {
        final phantomUniversalUri = Uri.parse(
          'https://phantom.app/ul/browse/${Uri.encodeComponent(solanaUri)}?ref=patas',
        );
        if (await canLaunchUrl(phantomUniversalUri)) {
          final launched = await launchUrl(phantomUniversalUri, mode: LaunchMode.externalApplication);
          if (launched) return true;
        }
      } catch (e) {
        debugPrint('[SolanaPayService] Fallback phantom universal falhou: $e');
      }

      return false;
    } catch (e) {
      debugPrint('[SolanaPayService] Erro ao abrir carteira: $e');
      return false;
    }
  }

  /// Abre a página da Phantom Wallet na Google Play Store
  static Future<bool> openPhantomPlayStore() async {
    final playStoreUri = Uri.parse('https://play.google.com/store/apps/details?id=app.phantom');
    try {
      return await launchUrl(playStoreUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[SolanaPayService] Erro ao abrir Play Store: $e');
      return false;
    }
  }

  /// Abre o explorador da Solana no navegador
  static Future<void> openExplorer({String? transactionSignature, String? address}) async {
    final url = getExplorerUrl(
      transactionSignature: transactionSignature,
      address: address,
    );
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[SolanaPayService] Erro ao abrir explorer: $e');
    }
  }

  /// Link direto para o Solana Explorer (Devnet)
  static String getExplorerUrl({String? transactionSignature, String? address}) {
    if (transactionSignature != null) {
      return 'https://explorer.solana.com/tx/$transactionSignature?cluster=devnet';
    }
    return 'https://explorer.solana.com/address/${address ?? defaultTreasuryWallet}?cluster=devnet';
  }
}
