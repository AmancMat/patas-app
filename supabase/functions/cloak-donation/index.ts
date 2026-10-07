import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { getCorsHeaders, handleCors } from "../common/cors.ts"

interface CloakDonationRequest {
  recipientWallet: string
  amount: number
  currency: 'SOL' | 'USDC'
  memo?: string
  campaignTitle?: string
}

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;
  const corsHeaders = getCorsHeaders(req);

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Método não permitido' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  try {
    const body: CloakDonationRequest = await req.json();
    const { recipientWallet, amount, currency, memo, campaignTitle } = body;

    if (!recipientWallet || !amount || amount <= 0) {
      return new Response(JSON.stringify({ error: 'Parâmetros inválidos para doação' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Geração do link oficial de pagamento privado da Cloak (Mainnet Solana)
    // O link permite que qualquer doador resgate ou pague direto no pool protegido sem revelar sua carteira pública
    const cloakPaymentUrl = `https://pay.cloak.ag/?to=${encodeURIComponent(recipientWallet)}&amount=${amount}&currency=${currency}&label=${encodeURIComponent('Patas Acolhe • ' + (campaignTitle || 'Resgate Animal'))}&memo=${encodeURIComponent(memo || 'Doação Anônima via Cloak')}`;

    return new Response(
      JSON.stringify({
        success: true,
        protocol: 'Cloak Zcash on Solana',
        network: 'Solana Mainnet-Beta',
        shielded: true,
        paymentUrl: cloakPaymentUrl,
        details: {
          recipientWallet,
          amount,
          currency,
          privacyGuarantee: 'Identidade e saldo do doador são protegidos por Provas Zero-Knowledge no Shielded Pool.',
        },
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: 'Erro ao gerar doação privada Cloak', details: String(error) }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});
