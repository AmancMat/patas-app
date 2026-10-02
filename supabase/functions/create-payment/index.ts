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

    const { plan_id, cpf, pet_id, vet_id, billing_type = 'PIX', billingType, auto_renew = false, creditCard, creditCardHolderInfo } = await req.json()
    const finalBillingType = billingType || billing_type;

    if (!plan_id) {
      throw new Error('plan_id é obrigatório')
    }
    if (!pet_id && !vet_id) {
      throw new Error('pet_id ou vet_id é obrigatório')
    }

    if (finalBillingType === 'CREDIT_CARD') {
      if (!creditCard || !creditCard.number || !creditCard.holderName || !creditCard.expiryMonth || !creditCard.expiryYear || !creditCard.ccv) {
        throw new Error('Dados do cartão de crédito incompletos')
      }
      if (!creditCardHolderInfo || !creditCardHolderInfo.name || !creditCardHolderInfo.email || !creditCardHolderInfo.cpfCnpj || !creditCardHolderInfo.postalCode || !creditCardHolderInfo.addressNumber || !creditCardHolderInfo.phone) {
        throw new Error('Dados do titular do cartão de crédito incompletos')
      }
    }

    // Initialize Supabase Client with Admin/Service Role to bypass client RLS for admin-level operations
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 1. Get user details (email and name)
    const email = user.email!;
    
    // Search profile name
    const { data: profile } = await supabaseAdmin
      .from('profiles')
      .select('name')
      .eq('id', user.id)
      .maybeSingle()

    const name = profile?.name ?? user.user_metadata?.name ?? 'Tutor Patas';

    // ============================================================
    // BRANCH A: PROVISIONS FOR VETERINARIAN B2B PAYMENTS (vet_id)
    // ============================================================
    if (vet_id) {
      const { data: vet } = await supabaseAdmin
        .from('vet_profiles')
        .select('*')
        .eq('id', vet_id)
        .maybeSingle();

      const { data: vetPlan, error: vetPlanErr } = await supabaseAdmin
        .from('vet_plans')
        .select('*')
        .eq('id', plan_id)
        .single();

      if (vetPlanErr || !vetPlan) {
        throw new Error('Plano de veterinário não encontrado');
      }

      const price = Number(vetPlan.price);
      const asaasApiKey = Deno.env.get('ASAAS_API_KEY') || 'mock-api-key';
      const asaasUrl = Deno.env.get('ASAAS_API_URL') || 'https://sandbox.asaas.com/api/v3';

      let customerId = '';
      const searchRes = await fetch(`${asaasUrl}/customers?email=${encodeURIComponent(email)}`, {
        method: 'GET',
        headers: { 'access_token': asaasApiKey, 'Content-Type': 'application/json' }
      });
      const searchData = await searchRes.json();
      if (searchData.data && searchData.data.length > 0) {
        customerId = searchData.data[0].id;
        if (cpf) {
          await fetch(`${asaasUrl}/customers/${customerId}`, {
            method: 'PUT',
            headers: { 'access_token': asaasApiKey, 'Content-Type': 'application/json' },
            body: JSON.stringify({ cpfCnpj: cpf, name, email })
          });
        }
      } else {
        const createCustRes = await fetch(`${asaasUrl}/customers`, {
          method: 'POST',
          headers: { 'access_token': asaasApiKey, 'Content-Type': 'application/json' },
          body: JSON.stringify({ name, email, cpfCnpj: cpf || undefined, externalReference: user.id })
        });
        const custData = await createCustRes.json();
        if (!custData.id) {
          throw new Error(`Erro ao criar cliente no Asaas: ${JSON.stringify(custData)}`);
        }
        customerId = custData.id;
      }

      let paymentData: any;
      if (finalBillingType === 'PIX') {
        const dueDate = new Date();
        dueDate.setDate(dueDate.getDate() + 1);
        const formattedDueDate = dueDate.toISOString().split('T')[0];

        const createPaymentRes = await fetch(`${asaasUrl}/payments`, {
          method: 'POST',
          headers: { 'access_token': asaasApiKey, 'Content-Type': 'application/json' },
          body: JSON.stringify({
            customer: customerId,
            billingType: 'PIX',
            value: price,
            dueDate: formattedDueDate,
            description: `Assinatura Patas Saúde B2B - Plano ${vetPlan.name}`,
            externalReference: vet_id
          })
        });
        paymentData = await createPaymentRes.json();
        if (!paymentData.id) {
          throw new Error(`Erro ao gerar cobrança no Asaas: ${JSON.stringify(paymentData)}`);
        }
      } else if (finalBillingType === 'CREDIT_CARD') {
        const today = new Date();
        const formattedDueDate = today.toISOString().split('T')[0];

        const createPaymentRes = await fetch(`${asaasUrl}/payments`, {
          method: 'POST',
          headers: { 'access_token': asaasApiKey, 'Content-Type': 'application/json' },
          body: JSON.stringify({
            customer: customerId,
            billingType: 'CREDIT_CARD',
            value: price,
            dueDate: formattedDueDate,
            description: `Assinatura Patas Saúde B2B - Plano ${vetPlan.name}`,
            externalReference: vet_id,
            creditCard,
            creditCardHolderInfo
          })
        });
        paymentData = await createPaymentRes.json();
        if (!paymentData.id) {
          if (paymentData.errors && paymentData.errors.length > 0) {
            throw new Error(`Recusa de pagamento: ${paymentData.errors.map((e: any) => e.description).join(', ')}`);
          }
          throw new Error(`Erro ao processar cartão no Asaas: ${JSON.stringify(paymentData)}`);
        }
      }

      let pixCopiaCola = null;
      let pixQrCodeUrl = null;

      if (finalBillingType === 'PIX') {
        const pixDataRes = await fetch(`${asaasUrl}/payments/${paymentData.id}/pixQrCode`, {
          method: 'GET',
          headers: { 'access_token': asaasApiKey, 'Content-Type': 'application/json' }
        });
        const pixData = await pixDataRes.json();
        if (pixData.payload) {
          pixCopiaCola = pixData.payload;
          pixQrCodeUrl = pixData.encodedImage 
            ? `data:image/png;base64,${pixData.encodedImage}`
            : `https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${encodeURIComponent(pixData.payload)}`;
        }
      }

      let { data: vetSub } = await supabaseAdmin
        .from('vet_subscriptions')
        .select('*')
        .eq('vet_id', vet_id)
        .maybeSingle();

      const isApproved = finalBillingType === 'CREDIT_CARD' && (paymentData.status === 'CONFIRMED' || paymentData.status === 'RECEIVED' || paymentData.status === 'PENDING');
      const now = new Date();
      const endPeriod = new Date();
      endPeriod.setDate(endPeriod.getDate() + (vetPlan.billing_cycle === 'annual' ? 365 : 30));
      const subStatus = isApproved ? 'active' : (vetSub?.status || 'trial');

      if (!vetSub) {
        const { data: newVetSub, error: subInsErr } = await supabaseAdmin
          .from('vet_subscriptions')
          .insert({
            vet_id: vet_id,
            user_id: user.id,
            plan_id: vetPlan.id,
            status: subStatus,
            current_period_start: now.toISOString(),
            current_period_end: endPeriod.toISOString(),
            asaas_customer_id: customerId
          })
          .select()
          .single();
        if (subInsErr) throw subInsErr;
        vetSub = newVetSub;
      } else {
        const { data: updatedVetSub, error: subUpdErr } = await supabaseAdmin
          .from('vet_subscriptions')
          .update({
            plan_id: vetPlan.id,
            status: subStatus,
            current_period_start: now.toISOString(),
            current_period_end: endPeriod.toISOString(),
            asaas_customer_id: customerId,
            updated_at: now.toISOString()
          })
          .eq('id', vetSub.id)
          .select()
          .single();
        if (subUpdErr) throw subUpdErr;
        vetSub = updatedVetSub;
      }

      const { data: vetInvoice, error: invErr } = await supabaseAdmin
        .from('vet_invoices')
        .upsert({
          subscription_id: vetSub.id,
          vet_id: vet_id,
          user_id: user.id,
          amount: price,
          status: isApproved ? 'paid' : 'pending',
          due_date: new Date(paymentData.dueDate + 'T23:59:59').toISOString(),
          paid_at: isApproved ? now.toISOString() : null,
          pix_qr_code: pixQrCodeUrl,
          pix_copy_paste: pixCopiaCola,
          asaas_payment_id: paymentData.id
        }, { onConflict: 'asaas_payment_id' })
        .select()
        .single();

      if (invErr) throw invErr;

      return new Response(JSON.stringify({ invoice: vetInvoice, ...vetInvoice }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // ============================================================
    // BRANCH B: PET SUBSCRIPTION PAYMENTS (pet_id - Patas Encontra)
    // ============================================================

    // 1.1 Fetch pet name
    const { data: pet } = await supabaseAdmin
      .from('pets')
      .select('name')
      .eq('id', pet_id)
      .maybeSingle()
    const petName = pet?.name ?? 'Pet';

    // 2. Fetch plan details
    const { data: plan, error: planErr } = await supabaseAdmin
      .from('subscription_plans')
      .select('*')
      .eq('id', plan_id)
      .single()
    
    if (planErr || !plan) {
      throw new Error('Plano não encontrado')
    }

    const price = plan.price_in_cents / 100;

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
      // Atualizar CPF do cliente existente (pode ter sido criado sem CPF anteriormente)
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

    let paymentData;

    if (billing_type === 'PIX') {
      // 4. Generate dynamic PIX payment in Asaas
      const dueDate = new Date();
      dueDate.setDate(dueDate.getDate() + 1); // 1 day due date
      const formattedDueDate = dueDate.toISOString().split('T')[0];

      const createPaymentRes = await fetch(`${asaasUrl}/payments`, {
        method: 'POST',
        headers: {
          'access_token': asaasApiKey,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          customer: customerId,
          billingType: 'PIX',
          value: price,
          dueDate: formattedDueDate,
          description: `Assinatura Patas Encontra - Plano ${plan.name} - Pet ${petName}`,
          externalReference: pet_id
        })
      });

      paymentData = await createPaymentRes.json();
      if (!paymentData.id) {
        throw new Error(`Erro ao gerar cobrança no Asaas: ${JSON.stringify(paymentData)}`);
      }
    } else if (billing_type === 'CREDIT_CARD' && !auto_renew) {
      // 4.1 Generate Credit Card Single payment
      const today = new Date();
      const formattedDueDate = today.toISOString().split('T')[0];

      const createPaymentRes = await fetch(`${asaasUrl}/payments`, {
        method: 'POST',
        headers: {
          'access_token': asaasApiKey,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          customer: customerId,
          billingType: 'CREDIT_CARD',
          value: price,
          dueDate: formattedDueDate,
          description: `Assinatura Patas Encontra - Plano ${plan.name} - Pet ${petName}`,
          externalReference: pet_id,
          creditCard,
          creditCardHolderInfo
        })
      });

      paymentData = await createPaymentRes.json();
      if (!paymentData.id) {
        if (paymentData.errors && paymentData.errors.length > 0) {
          throw new Error(`Recusa de pagamento: ${paymentData.errors.map((e: any) => e.description).join(', ')}`);
        }
        throw new Error(`Erro ao processar pagamento com cartão no Asaas: ${JSON.stringify(paymentData)}`);
      }
    } else if (billing_type === 'CREDIT_CARD' && auto_renew) {
      // 4.2 Generate Credit Card Subscription (Recurring)
      const today = new Date();
      const formattedDueDate = today.toISOString().split('T')[0];
      const cycle = plan.billing_interval === 'year' ? 'YEARLY' : 'MONTHLY';

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
          cycle,
          description: `Assinatura Recorrente Patas Encontra - Plano ${plan.name} - Pet ${petName}`,
          externalReference: pet_id,
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

      // Buscar a primeira cobrança gerada para essa assinatura recorrente
      const paymentsBySubRes = await fetch(`${asaasUrl}/payments?subscription=${subData.id}`, {
        method: 'GET',
        headers: {
          'access_token': asaasApiKey,
          'Content-Type': 'application/json'
        }
      });
      const paymentsBySubData = await paymentsBySubRes.json();
      
      let initialPayment = null;
      if (paymentsBySubData.data && paymentsBySubData.data.length > 0) {
        initialPayment = paymentsBySubData.data[0];
      }

      paymentData = initialPayment;
      if (!paymentData) {
        throw new Error('Assinatura recorrente criada, mas nenhuma fatura inicial foi encontrada no Asaas.');
      }
      
      // Armazenar a referência da assinatura no objeto de pagamento
      paymentData.subscriptionId = subData.id;
    }

    // 5. Get PIX Copy and Paste & QR Code URL (Only if billing_type is PIX)
    let pixCopiaCola = null;
    let pixQrCodeUrl = null;

    if (billing_type === 'PIX') {
      const pixDataRes = await fetch(`${asaasUrl}/payments/${paymentData.id}/pixQrCode`, {
        method: 'GET',
        headers: {
          'access_token': asaasApiKey,
          'Content-Type': 'application/json'
        }
      });

      const pixData = await pixDataRes.json();
      if (!pixData.payload) {
        throw new Error(`Erro ao obter dados do PIX: ${JSON.stringify(pixData)}`);
      }
      pixCopiaCola = pixData.payload;
      pixQrCodeUrl = pixData.encodedImage 
        ? `data:image/png;base64,${pixData.encodedImage}` 
        : `https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${encodeURIComponent(pixData.payload)}`;
    }

    // 6. Handle Database entries
    // A. Check subscription
    let { data: subscription } = await supabaseAdmin
      .from('subscriptions')
      .select('*')
      .eq('pet_id', pet_id)
      .maybeSingle()

    // Determine initial status and date intervals
    let initialSubStatus: 'trial' | 'active' = 'trial';
    let gatewaySubId: string | null = null;
    
    const isCreditCardApproved = billing_type === 'CREDIT_CARD' && (paymentData.status === 'CONFIRMED' || paymentData.status === 'RECEIVED' || paymentData.status === 'PENDING');
    
    if (isCreditCardApproved) {
      initialSubStatus = 'active';
    }
    
    if (billing_type === 'CREDIT_CARD' && auto_renew && paymentData.subscriptionId) {
      gatewaySubId = paymentData.subscriptionId;
    }

    const startCoverage = new Date();
    const endCoverage = new Date();
    const isAnnual = plan.billing_interval === 'year';
    endCoverage.setDate(endCoverage.getDate() + (isAnnual ? 365 : 30));
    
    const gracePeriodEnd = new Date(endCoverage);
    gracePeriodEnd.setDate(gracePeriodEnd.getDate() + 7);

    if (!subscription) {
      const now = new Date();
      const trialEnds = new Date();
      trialEnds.setDate(trialEnds.getDate() + 14); // 14 days trial

      const insertData: any = {
        user_id: user.id,
        pet_id: pet_id,
        plan_id: plan.id,
        status: initialSubStatus,
        gateway_customer_id: customerId
      };

      if (isCreditCardApproved) {
        insertData.current_period_start = startCoverage.toISOString();
        insertData.current_period_end = endCoverage.toISOString();
        insertData.grace_period_ends_at = gracePeriodEnd.toISOString();
      } else {
        insertData.trial_started_at = now.toISOString();
        insertData.trial_ends_at = trialEnds.toISOString();
      }

      if (gatewaySubId) {
        insertData.gateway_subscription_id = gatewaySubId;
      }

      const { data: newSub, error: insertError } = await supabaseAdmin
        .from('subscriptions')
        .insert(insertData)
        .select()
        .single()
      
      if (insertError) throw insertError;
      subscription = newSub;
    } else {
      // Update plan and customer ID in existing subscription
      const updateData: any = {
        plan_id: plan.id,
        status: initialSubStatus,
        gateway_customer_id: customerId,
        updated_at: new Date().toISOString()
      };

      if (isCreditCardApproved) {
        updateData.current_period_start = startCoverage.toISOString();
        updateData.current_period_end = endCoverage.toISOString();
        updateData.grace_period_ends_at = gracePeriodEnd.toISOString();
      }

      if (gatewaySubId) {
        updateData.gateway_subscription_id = gatewaySubId;
      }

      const { data: updatedSub, error: updateError } = await supabaseAdmin
        .from('subscriptions')
        .update(updateData)
        .eq('id', subscription.id)
        .select()
        .single()

      if (updateError) throw updateError;
      subscription = updatedSub;
    }

    // B. Create Invoice linked to gateway_charge_id
    const now = new Date();
    const coverageEnd = new Date();
    coverageEnd.setDate(coverageEnd.getDate() + (plan.billing_interval === 'year' ? 365 : 30));

    const invoiceStatus = isCreditCardApproved ? 'paid' : 'pending';
    const paidAt = isCreditCardApproved ? now.toISOString() : null;

    const { data: invoice, error: invoiceError } = await supabaseAdmin
      .from('invoices')
      .upsert({
        subscription_id: subscription.id,
        user_id: user.id,
        amount_in_cents: plan.price_in_cents,
        status: invoiceStatus,
        pix_copia_cola: pixCopiaCola,
        pix_qr_code_url: pixQrCodeUrl,
        gateway_charge_id: paymentData.id,
        paid_at: paidAt,
        due_date: new Date(paymentData.dueDate + 'T23:59:59').toISOString(),
        period_start: now.toISOString(),
        period_end: coverageEnd.toISOString()
      }, { onConflict: 'gateway_charge_id' })
      .select()
      .single()

    if (invoiceError) throw invoiceError;

    // Se o pagamento do cartão foi aprovado, expirar as faturas pendentes anteriores da mesma assinatura no banco local
    if (isCreditCardApproved) {
      await supabaseAdmin
        .from('invoices')
        .update({ status: 'expired' })
        .eq('subscription_id', subscription.id)
        .eq('status', 'pending')
        .neq('id', invoice.id);
    }

    return new Response(JSON.stringify(invoice), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})
