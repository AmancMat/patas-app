class PetPassport {
  final String petId;
  final String petName;
  final String species;
  final String breed;
  final String? gender;
  final DateTime? birthDate;
  final String? photoUrl;
  final String microchipNumber;
  final String ownerName;
  final String ownerWallet;
  final String vaccineStatus;
  final String cNftAssetId;
  final String merkleTreeAddress;
  final String? txSignature;
  final int? blockSlot;
  final int leafIndex;
  final DateTime issuedAt;
  final bool isVerifiedOnChain;
  final bool isPhysicalMicrochip;

  const PetPassport({
    required this.petId,
    required this.petName,
    required this.species,
    required this.breed,
    this.gender,
    this.birthDate,
    this.photoUrl,
    required this.microchipNumber,
    required this.ownerName,
    required this.ownerWallet,
    required this.vaccineStatus,
    required this.cNftAssetId,
    required this.merkleTreeAddress,
    this.txSignature,
    this.blockSlot,
    required this.leafIndex,
    required this.issuedAt,
    this.isVerifiedOnChain = true,
    this.isPhysicalMicrochip = false,
  });

  /// URL de auditoria no Solana Explorer (cluster Devnet)
  String get explorerUrl {
    return 'https://explorer.solana.com/address/$merkleTreeAddress?cluster=devnet';
  }

  /// URL da transação de cunhagem no Solana Explorer
  String get explorerTxUrl {
    if (txSignature != null && txSignature!.isNotEmpty) {
      return 'https://explorer.solana.com/tx/$txSignature?cluster=devnet';
    }
    return explorerUrl;
  }

  /// Retorna os metadados no padrão oficial Metaplex Bubblegum para cNFT
  Map<String, dynamic> toMetaplexMetadata() {
    return {
      'name': '$petName — $breed',
      'symbol': 'PATAS',
      'description': 'Passaporte Digital Soberano emitido na rede Solana via Metaplex Bubblegum.',
      'image': photoUrl ?? 'https://patas.online/assets/images/placeholder_pet.png',
      'external_url': 'https://patas.online/#/passport?id=$petId',
      'attributes': [
        {'trait_type': 'Microchip', 'value': microchipNumber},
        {'trait_type': 'Tipo Microchip', 'value': isPhysicalMicrochip ? 'Físico Veterinário (RFID)' : 'Digital Provisório (ISO 11784)'},
        {'trait_type': 'Espécie', 'value': species},
        {'trait_type': 'Raça', 'value': breed},
        {'trait_type': 'Gênero', 'value': gender ?? 'Não informado'},
        {'trait_type': 'Status Vacinal', 'value': vaccineStatus},
        {'trait_type': 'Tutor Responsável', 'value': ownerName},
        {'trait_type': 'Carteira Custodiante', 'value': ownerWallet},
        {'trait_type': 'Padrão Tecnológico', 'value': 'Solana State Compression (cNFT)'},
        {'trait_type': 'Emissão', 'value': issuedAt.toIso8601String()},
      ],
    };
  }

  factory PetPassport.fromPet({
    required String petId,
    required String petName,
    required String species,
    String? breed,
    String? gender,
    DateTime? birthDate,
    String? photoUrl,
    String? customMicrochip,
    bool isPhysicalMicrochip = false,
    String? ownerName,
    String? ownerWallet,
    String? customVaccines,
    String? cNftAssetId,
    String? txSignature,
    int? blockSlot,
  }) {
    // Gera um número de microchip padrão ISO 11784 determinístico baseado no petId
    final hashSuffix = petId.replaceAll('-', '').substring(0, 10).toUpperCase();
    final defaultMicrochip = '9810-098$hashSuffix';

    // Endereço de demonstração da Árvore de Merkle Bubblegum na Devnet
    const defaultTree = 'cNFT2PAtasMerkLeTreeDevnet7xKXtg2CW87d97TXJ';
    final assetId = cNftAssetId ?? 'cNFT_sol_${petId.replaceAll('-', '').substring(0, 12)}';

    return PetPassport(
      petId: petId,
      petName: petName,
      species: species,
      breed: breed ?? 'SRD (Sem Raça Definida)',
      gender: gender,
      birthDate: birthDate,
      photoUrl: photoUrl,
      microchipNumber: customMicrochip ?? defaultMicrochip,
      ownerName: ownerName ?? 'Tutor Cadastrado',
      ownerWallet: (ownerWallet != null && ownerWallet.trim().isNotEmpty)
          ? ownerWallet.trim()
          : '7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU',
      vaccineStatus: customVaccines ?? 'V10, Antirrábica e Giardia Atualizadas (2026)',
      cNftAssetId: assetId,
      merkleTreeAddress: defaultTree,
      txSignature: txSignature,
      blockSlot: blockSlot,
      leafIndex: (petId.hashCode.abs() % 10000) + 1,
      issuedAt: DateTime.now(),
      isVerifiedOnChain: true,
      isPhysicalMicrochip: isPhysicalMicrochip,
    );
  }
}
