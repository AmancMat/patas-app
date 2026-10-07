/**
 * Patas - Doação Privada / Anônima para ONGs via Cloak Protocol (Solana Mainnet)
 * Submissão oficial para a Privacy Week da Superteam Brasil (Colosseum Hackathon)
 * 
 * Uso:
 *   npx tsx send-private-donation.ts <recipientPubkey> <lamports>
 * Exemplo para 0.015 SOL:
 *   npx tsx send-private-donation.ts 7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU 15000000
 */

import { readFileSync } from 'fs';
import * as path from 'path';
import * as dotenv from 'dotenv';

// Importações oficiais do SDK Cloak v0.2.5
import {
  CLOAK_PROGRAM_ID,
  CLOAK_PRODUCTION_RELAY_URL,
  NATIVE_SOL_MINT,
  createRecoverableDepositUtxo,
  createZeroUtxo,
  fullWithdraw,
  generateUtxoKeypair,
  getNkFromUtxoPrivateKey,
  transact,
  address,
  createCloakRpc,
  signerFromSecretKey,
} from '@cloak.dev/sdk';

dotenv.config();

async function main() {
  const [recipientArg, lamportsArg] = process.argv.slice(2);

  if (!recipientArg || !lamportsArg) {
    console.error('Uso: npx tsx send-private-donation.ts <recipientPubkey> <lamports>');
    console.error('Exemplo para 0.015 SOL: npx tsx send-private-donation.ts <ONG_WALLET> 15000000');
    process.exit(1);
  }

  const rpcUrl = process.env.SOLANA_RPC_URL || 'https://api.mainnet-beta.solana.com';
  const relayUrl = process.env.CLOAK_RELAY_URL || CLOAK_PRODUCTION_RELAY_URL;
  const keypairPath = process.env.KEYPAIR_PATH;

  if (!keypairPath) {
    console.error('Erro: A variável de ambiente KEYPAIR_PATH não foi informada no .env ou comando.');
    process.exit(1);
  }

  const connection = createCloakRpc(rpcUrl);
  const signer = await signerFromSecretKey(
    Uint8Array.from(JSON.parse(readFileSync(path.resolve(keypairPath), 'utf8'))),
  );

  const recipient = address(recipientArg);
  const amount = BigInt(lamportsArg);

  console.log('🐾 ========================================================');
  console.log('🐾 [Patas Acolhe] - Doação Anônima via Cloak Protocol (ZK)');
  console.log('🐾 ========================================================');
  console.log(`Doador (Protegido por ZK): ${signer.address}`);
  console.log(`Destinatário (ONG / Abrigo Patas): ${recipient}`);
  console.log(`Valor da Doação: ${amount} lamports (~${Number(amount) / 1e9} SOL)`);
  console.log(`RPC Solana: ${rpcUrl}`);
  console.log(`Relay Cloak: ${relayUrl}`);
  console.log(`Cloak Program ID: ${CLOAK_PROGRAM_ID}`);

  // Base de visualização da carteira (nk). Derivado das chaves de UTXO do Cloak.
  const owner = await generateUtxoKeypair();
  const nk = getNkFromUtxoPrivateKey(owner.privateKey);

  // 1. Depósito no Shielded Pool da Cloak (Entrada na privacidade ZK)
  console.log('\n[Passo 1/2] Depositando fundos no Shielded Pool da Cloak...');
  const { utxo, noteSalt } = await createRecoverableDepositUtxo(amount, nk, NATIVE_SOL_MINT);

  const deposited = await transact(
    {
      inputUtxos: [await createZeroUtxo(NATIVE_SOL_MINT)],
      outputUtxos: [utxo],
      externalAmount: amount,
      depositor: signer.address,
    },
    {
      connection,
      programId: CLOAK_PROGRAM_ID,
      relayUrl,
      depositorKeypair: signer,
      chainNoteViewingKeyNk: nk,
      chainNoteSalt: noteSalt,
    },
  );

  console.log('✓ Depósito confirmado no Shielded Pool com sucesso!');
  console.log(`Assinatura do Depósito: ${deposited.signature}`);

  if (!deposited.outputUtxos || deposited.outputUtxos.length === 0) {
    throw new Error('Nenhuma nota UTXO gerada pelo depósito no pool da Cloak.');
  }

  // 2. Saque anônimo para a carteira da ONG (Full Withdraw ZK)
  // A rede enxerga a saída para a ONG, mas o vínculo com o doador é 100% quebrado através de prova Groth16!
  console.log('\n[Passo 2/2] Realizando saque anônimo para a ONG via Prova Zero-Knowledge...');
  const withdrawn = await fullWithdraw([deposited.outputUtxos[0]], recipient, {
    connection,
    programId: CLOAK_PROGRAM_ID,
    relayUrl,
    depositorKeypair: signer,
    walletPublicKey: signer.address,
    chainNoteViewingKeyNk: nk,
    cachedMerkleTree: deposited.merkleTree,
  });

  console.log('✓ Doação anônima concluída com sucesso!');
  console.log(`Assinatura do Saque ZK (Prova Mainnet): ${withdrawn.signature}`);
  console.log(`Solana Explorer: https://solscan.io/tx/${withdrawn.signature}`);
  console.log('🐾 Identidade do doador 100% preservada on-chain!');
}

main().catch((err) => {
  console.error('\n❌ Erro na execução da doação privada via Cloak:');
  console.error(err instanceof Error ? err.message : String(err));
  process.exit(1);
});
