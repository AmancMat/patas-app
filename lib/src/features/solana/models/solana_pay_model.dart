class SolanaPayDonation {
  final String recipientWallet;
  final double amount;
  final String tokenSymbol; // 'USDC' ou 'SOL'
  final String referenceId;
  final String campaignId;
  final String campaignTitle;
  final String? ongName;
  final DateTime createdAt;

  const SolanaPayDonation({
    required this.recipientWallet,
    required this.amount,
    this.tokenSymbol = 'USDC',
    required this.referenceId,
    required this.campaignId,
    required this.campaignTitle,
    this.ongName,
    required this.createdAt,
  });

  /// Mint address do USDC na Solana (Devnet vs Mainnet)
  static const String usdcDevnetMint = '4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU';
  static const String usdcMainnetMint = 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v';

  static String _formatCleanAmount(double val) {
    String s = val.toStringAsFixed(4);
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '');
      s = s.replaceAll(RegExp(r'\.$'), '');
    }
    return s;
  }

  /// Gera a URI padronizada do Solana Pay Specification
  String toSolanaPayUri({bool isDevnet = true}) {
    final encodedLabel = Uri.encodeComponent(ongName ?? 'Patas Acolhe');
    final encodedMessage = Uri.encodeComponent('Doação Campanha Patas');

    final bool isFreeAmount = amount <= 0;
    final amountParam = isFreeAmount ? '' : '&amount=${_formatCleanAmount(amount)}';

    if (tokenSymbol == 'USDC') {
      final tokenMint = isDevnet ? usdcDevnetMint : usdcMainnetMint;
      return 'solana:$recipientWallet?spl-token=$tokenMint$amountParam&label=$encodedLabel&message=$encodedMessage';
    } else {
      final queryStart = isFreeAmount ? '?label=$encodedLabel' : '?amount=${_formatCleanAmount(amount)}&label=$encodedLabel';
      return 'solana:$recipientWallet$queryStart&message=$encodedMessage';
    }
  }
}
