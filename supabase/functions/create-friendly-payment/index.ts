import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4"
import { getCorsHeaders, handleCors } from "../common/cors.ts"

serve(async (req) => {
  // CORS check com Allowlist oficial
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;
  const corsHeaders = getCorsHeaders(req);

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      throw new Error('Cabeçalho de Autorização ausente');
    }

    // Extrair token JWT
    const token = authHeader.replace(/bearer/i, '').trim();

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        auth: {
          persistSession: false,
          autoRefreshToken: false,
        }
      }
    )

    // Obter usuário autenticado a partir do token
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser(token)
    if (userError || !user) {
      return new Response(JSON.stringify({ error: `Não autenticado: ${userError?.message || 'Token inválido'}` }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    const { place_id, cpf, creditCard, creditCardHolderInfo } = await req.json()
    if (!place_id) {
      throw new Error('place_id é obrigatório')
    }
    if (!cpf) {
      throw new Error('cpf é obrigatório')
    }

    if (!creditCard || !creditCard.number || !creditCard.holderName || !creditCard.expiryMonth || !creditCard.expiryYear || !creditCard.ccv) {
      throw new Error('Dados do cartão de crédito incompletos')
    }
    if (!creditCardHolderInfo || !creditCardHolderInfo.name || !creditCardHolderInfo.email || !creditCardHolderInfo.cpfCnpj || !creditCardHolderInfo.postalCode || !creditCardHolderInfo.addressNumber || !creditCardHolderInfo.phone) {
      throw new Error('Dados do titular do cartão de crédito incompletos')
    }

    // Initialize Supabase Client with Admin/Service Role to bypass client RLS
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 1. Get user details
    const email = user.email!;
    
    // Search profile name
    const { data: profile } = await supabaseAdmin
      .from('profiles')
      .select('name')
      .eq('id', user.id)
      .maybeSingle()

    const name = profile?.name ?? user.user_metadata?.name ?? 'Parceiro Patas';

    // 1.1 Fetch place name
    const { data: place, error: placeErr } = await supabaseAdmin
      .from('friendly_places')
      .select('*')
      .eq('id', place_id)
      .maybeSingle()
    
    if (placeErr || !place) {
      throw new Error('Estabelecimento não encontrado')
    }

    if (place.is_claimed) {
      throw new Error('Este estabelecimento já foi reivindicado')
    }

    const price = 29.90; // Assinatura fixa do Premium Patas Friendly

    // Asaas credentials
    const asaasApiKey = Deno.env.get('ASAAS_API_KEY') || 'mock-api-key';
    const asaasUrl = Deno.env.get('ASAAS_API_URL') || 'https://sandbox.asaas.com/api/v3';

    // 3. Search Customer in Asaas or create one
    let customerId = '';
    const searchRes = await fetch(`${asaasUrl}/customers?email=${encodeURIComponent(email)}`, {
      method: 'GET',
      headers: {
        'access_token': asaasApiKey,
        'Content-Type': 'application/json'
      }
    });

    const searchData = await searchRes.json();
    if (searchData.data && searchData.data.length > 0) {
      customerId = searchData.data[0].id;
      // Update existing customer
      await fetch(`${asaasUrl}/customers/${customerId}`, {
        method: 'PUT',
        headers: {
          'access_token': asaasApiKey,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ cpfCnpj: cpf, name, email })
      });
    } else {
      // Create customer
      const createCustRes = await fetch(`${asaasUrl}/customers`, {
        method: 'POST',
        headers: {
          'access_token': asaasApiKey,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          name,
          email,
          cpfCnpj: cpf,
          externalReference: user.id
        })
      });
      const custData = await createCustRes.json();
      if (!custData.id) {
        throw new Error(`Erro ao criar cliente no Asaas: ${JSON.stringify(custData)}`);
      }
      customerId = custData.id;
    }

    // 4. Generate Credit Card Subscription (Recurring)
    const today = new Date();
    const formattedDueDate = today.toISOString().split('T')[0];

    const createSubRes = await fetch(`${asaasUrl}/subscriptions`, {
      method: 'POST',
      headers: {
        'access_token': asaasApiKey,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        customer: customerId,
        billingType: 'CREDIT_CARD',
        value: price,
        nextDueDate: formattedDueDate,
        cycle: 'MONTHLY',
        description: `Assinatura Premium Patas Friendly - ${place.name}`,
        externalReference: place_id,
        creditCard,
        creditCardHolderInfo
      })
    });

    const subData = await createSubRes.json();
    if (!subData.id) {
      if (subData.errors && subData.errors.length > 0) {
        throw new Error(`Recusa de assinatura: ${subData.errors.map((e: any) => e.description).join(', ')}`);
      }
      throw new Error(`Erro ao criar assinatura recorrente no Asaas: ${JSON.stringify(subData)}`);
    }

    // 5. Update friendly_places table
    const { error: updateError } = await supabaseAdmin
      .from('friendly_places')
      .update({
        is_claimed: true,
        claimed_by: user.id,
        updated_at: new Date().toISOString()
      })
      .eq('id', place_id);

    if (updateError) {
      throw new Error(`Erro ao atualizar local no banco: ${updateError.message}`);
    }

    return new Response(JSON.stringify({ success: true, subscriptionId: subData.id }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })

  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})
