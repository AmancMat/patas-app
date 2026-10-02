import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4"
import { sendFcmNotification } from "../common/fcm.ts"
import { getCorsHeaders, handleCors } from "../common/cors.ts"

serve(async (req) => {
  // CORS check com Allowlist oficial
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;
  const corsHeaders = getCorsHeaders(req);

  try {
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { alert_type } = await req.json()

    if (!['trial_expiring', 'grace_expiring'].includes(alert_type)) {
      throw new Error(`alert_type inválido: ${alert_type}`)
    }

    const now = new Date()
    const targetDate = new Date(now)
    targetDate.setDate(targetDate.getDate() + 5) // 5 dias no futuro

    const targetStart = new Date(targetDate)
    targetStart.setHours(0, 0, 0, 0)
    const targetEnd = new Date(targetDate)
    targetEnd.setHours(23, 59, 59, 999)

    let query = supabaseAdmin
      .from('subscriptions')
      .select('id, user_id, status, trial_ends_at, grace_period_ends_at')

    if (alert_type === 'trial_expiring') {
      query = query
        .eq('status', 'trial')
        .gte('trial_ends_at', targetStart.toISOString())
        .lte('trial_ends_at', targetEnd.toISOString())
    } else {
      query = query
        .eq('status', 'grace_period')
        .gte('grace_period_ends_at', targetStart.toISOString())
        .lte('grace_period_ends_at', targetEnd.toISOString())
    }

    const { data: subscriptions, error: subError } = await query

    if (subError) throw subError

    if (!subscriptions || subscriptions.length === 0) {
      return new Response(
        JSON.stringify({ message: `Nenhuma assinatura encontrada para ${alert_type}` }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`📬 Enviando ${subscriptions.length} alertas do tipo: ${alert_type} (FCM v1)`)

    let successCount = 0
    let failCount = 0

    for (const sub of subscriptions) {
      const { data: user } = await supabaseAdmin
        .from('users')
        .select('fcm_token, notification_sound')
        .eq('id', sub.user_id)
        .single()

      if (!user?.fcm_token) {
        console.warn(`Usuário ${sub.user_id} sem FCM token, pulando.`)
        failCount++
        continue
      }

      let title: string
      let body: string
      let notificationDbType: string

      if (alert_type === 'trial_expiring') {
        const trialEnd = new Date(sub.trial_ends_at)
        const dayStr = trialEnd.toLocaleDateString('pt-BR')
        title = '⏳ Seu período de teste está acabando!'
        body = `Você tem 5 dias antes de ${dayStr} para assinar o Patas Encontra e manter seu pet protegido.`
        notificationDbType = 'trial_expiring'
      } else {
        const graceEnd = new Date(sub.grace_period_ends_at)
        const dayStr = graceEnd.toLocaleDateString('pt-BR')
        title = '🔴 Atenção! Serviço será bloqueado em breve'
        body = `O serviço de localização do seu pet será suspenso em 5 dias (${dayStr}). Regularize agora para manter a proteção ativa.`
        notificationDbType = 'grace_expiring'
      }

      const soundKey = (user.notification_sound as string) ?? 'default'
      const channelId = soundKey !== 'default'
        ? `channel_${soundKey}`
        : 'high_importance_channel'

      try {
        await sendFcmNotification({
          token: user.fcm_token,
          title,
          body,
          sound: soundKey,
          channelId,
          data: {
            type: notificationDbType,
            subscription_id: sub.id,
          },
        })

        await supabaseAdmin.from('notifications').insert({
          user_id: sub.user_id,
          type: notificationDbType,
          title,
          content: body,
          data: { subscription_id: sub.id, alert_type },
        })

        successCount++
      } catch (fcmErr) {
        console.error(`Falha no envio do FCM v1 para usuário ${sub.user_id}:`, fcmErr.message)
        failCount++
      }
    }

    console.log(`✅ Concluído: ${successCount} sucesso(s), ${failCount} falha(s)`)

    return new Response(
      JSON.stringify({
        success: true,
        alert_type,
        total: subscriptions.length,
        sent: successCount,
        failed: failCount,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('❌ ERRO NO SUBSCRIPTION-ALERT:', error.message)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
