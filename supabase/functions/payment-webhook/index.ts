import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4"
import { getCorsHeaders, handleCors } from "../common/cors.ts"

serve(async (req) => {
  // CORS check com Allowlist oficial
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;
  const corsHeaders = getCorsHeaders(req);

  try {
    // Security check: Verify webhook token sent by Asaas
    const webhookTokenHeader = req.headers.get('asaas-access-token');
    const systemWebhookToken = Deno.env.get('ASAAS_WEBHOOK_TOKEN');
    
    // In production, always enforce webhook token check
    if (systemWebhookToken && webhookTokenHeader !== systemWebhookToken) {
      return new Response(JSON.stringify({ error: 'Não autorizado' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    const body = await req.json()
    const { event, payment } = body

    if (!payment || !payment.id) {
      throw new Error('Dados de pagamento inválidos ou ausentes no webhook')
    }

    // We only process successful payment events
    const isPaymentConfirmed = ['PAYMENT_RECEIVED', 'PAYMENT_CONFIRMED'].includes(event);
    if (!isPaymentConfirmed) {
      return new Response(JSON.stringify({ message: `Ignorado evento: ${event}` }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Initialize Supabase Client with Admin/Service Role to bypass client RLS policies
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // ============================================================
    // 0. Check if this payment belongs to vet_invoices (Patas Saúde B2B)
    // ============================================================
    const { data: vetInvoice } = await supabaseAdmin
      .from('vet_invoices')
      .select('*, vet_subscriptions(*, vet_plans(*))')
      .eq('asaas_payment_id', payment.id)
      .maybeSingle();

    if (vetInvoice) {
      console.log(`✅ Fatura B2B de Veterinário encontrada: ${vetInvoice.id}. Processando pagamento...`);
      const paidAt = payment.clientPaymentDate 
        ? new Date(payment.clientPaymentDate).toISOString() 
        : new Date().toISOString();

      await supabaseAdmin
        .from('vet_invoices')
        .update({ status: 'paid', paid_at: paidAt })
        .eq('id', vetInvoice.id);

      const vetSub = vetInvoice.vet_subscriptions;
      const vetPlan = vetSub?.vet_plans;
      const startCoverage = new Date();
      const endCoverage = new Date();
      const isAnnual = vetPlan?.billing_cycle === 'annual';
      endCoverage.setDate(endCoverage.getDate() + (isAnnual ? 365 : 30));

      if (vetSub) {
        await supabaseAdmin
          .from('vet_subscriptions')
          .update({
            status: 'active',
            current_period_start: startCoverage.toISOString(),
            current_period_end: endCoverage.toISOString(),
            updated_at: new Date().toISOString()
          })
          .eq('id', vetSub.id);
      }

      return new Response(JSON.stringify({ success: true, message: 'Fatura e assinatura de veterinário atualizadas com sucesso.' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // 1. Find the invoice linked to gateway_charge_id (Asaas payment ID)
    let { data: invoice, error: invoiceErr } = await supabaseAdmin
      .from('invoices')
      .select('*, subscriptions(*, subscription_plans(*))')
      .eq('gateway_charge_id', payment.id)
      .maybeSingle()

    if (invoiceErr) {
      throw invoiceErr;
    }

    // Se a fatura não foi encontrada de imediato, pode ser uma Race Condition com a criação síncrona da Edge Function.
    // Vamos aguardar 2.5 segundos e tentar buscar novamente para dar tempo da transação ser salva pela create-payment.
    if (!invoice) {
      console.log(`ℹ️ Fatura ${payment.id} não encontrada de imediato. Aguardando 2.5s para retry (evitar race condition)...`);
      await new Promise((resolve) => setTimeout(resolve, 2500));
      
      const { data: retryInvoice, error: retryErr } = await supabaseAdmin
        .from('invoices')
        .select('*, subscriptions(*, subscription_plans(*))')
        .eq('gateway_charge_id', payment.id)
        .maybeSingle();

      if (retryErr) {
        throw retryErr;
      }
      invoice = retryInvoice;
    }

    // Se a fatura correspondente não for encontrada, pode ser uma cobrança recorrente automática gerada pelo Asaas
    if (!invoice) {
      if (payment.subscription) {
        console.log(`ℹ️ Fatura não encontrada para gateway_charge_id: ${payment.id}. Verificando assinatura recorrente: ${payment.subscription}`);
        
        // Buscar assinatura pelo ID recorrente do Asaas
        const { data: subscription, error: subErr } = await supabaseAdmin
          .from('subscriptions')
          .select('*, subscription_plans(*)')
          .eq('gateway_subscription_id', payment.subscription)
          .maybeSingle()

        if (subErr) throw subErr;

        if (subscription) {
          console.log(`✅ Assinatura recorrente encontrada no banco local: ${subscription.id}. Criando nova fatura correspondente.`);
          
          const plan = subscription.subscription_plans;
          const now = new Date();
          const coverageEnd = new Date();
          const isAnnual = plan.billing_interval === 'year';
          coverageEnd.setDate(coverageEnd.getDate() + (isAnnual ? 365 : 30));

          // Criar fatura pré-paga no banco usando upsert para evitar duplicidade em race conditions
          const { data: newInvoice, error: createInvoiceErr } = await supabaseAdmin
            .from('invoices')
            .upsert({
              subscription_id: subscription.id,
              user_id: subscription.user_id,
              amount_in_cents: Math.round(payment.value * 100),
              status: 'pending', // Será alterada para 'paid' logo em seguida no fluxo normal do webhook
              gateway_charge_id: payment.id,
              due_date: new Date(payment.dueDate + 'T23:59:59').toISOString(),
              period_start: now.toISOString(),
              period_end: coverageEnd.toISOString()
            }, { onConflict: 'gateway_charge_id' })
            .select('*, subscriptions(*, subscription_plans(*))')
            .single()

          if (createInvoiceErr) throw createInvoiceErr;
          invoice = newInvoice;
        } else {
          throw new Error(`Fatura não encontrada e nenhuma assinatura local vinculada ao gateway_subscription_id: ${payment.subscription}`)
        }
      } else {
        throw new Error(`Fatura correspondente não encontrada para gateway_charge_id: ${payment.id} (não vinculada a uma assinatura recorrente)`)
      }
    }

    // If the invoice is already paid, no action needed
    if (invoice.status === 'paid') {
      return new Response(JSON.stringify({ message: 'Fatura já estava processada e paga.' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // 2. Update invoice status to paid
    const paidAt = payment.clientPaymentDate 
      ? new Date(payment.clientPaymentDate).toISOString() 
      : new Date().toISOString();

    const { error: updateInvoiceErr } = await supabaseAdmin
      .from('invoices')
      .update({
        status: 'paid',
        paid_at: paidAt
      })
      .eq('id', invoice.id)

    if (updateInvoiceErr) throw updateInvoiceErr;

    // 3. Update subscription status to active and calculate coverage dates
    const subscription = invoice.subscriptions;
    const plan = subscription.subscription_plans;

    const startCoverage = new Date();
    const endCoverage = new Date();
    // Extend subscription by 30 days or 365 days depending on the plan type
    const isAnnual = plan.billing_interval === 'year';
    endCoverage.setDate(endCoverage.getDate() + (isAnnual ? 365 : 30));

    const gracePeriodEnd = new Date(endCoverage);
    gracePeriodEnd.setDate(gracePeriodEnd.getDate() + 7); // 7 days grace period

    const { error: updateSubErr } = await supabaseAdmin
      .from('subscriptions')
      .update({
        status: 'active',
        current_period_start: startCoverage.toISOString(),
        current_period_end: endCoverage.toISOString(),
        grace_period_ends_at: gracePeriodEnd.toISOString(),
        updated_at: new Date().toISOString()
      })
      .eq('id', subscription.id)

    if (updateSubErr) throw updateSubErr;

    console.log(`✅ Assinatura ${subscription.id} ativada com sucesso via webhook. Fatura: ${invoice.id}`);

    return new Response(JSON.stringify({ success: true, message: 'Fatura e assinatura atualizadas com sucesso.' }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  } catch (error) {
    console.error('❌ ERRO NO WEBHOOK DE PAGAMENTO:', error.message)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})
