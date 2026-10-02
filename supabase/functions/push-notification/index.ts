import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4"
import { sendFcmNotification } from "../common/fcm.ts"
import { getCorsHeaders, handleCors } from "../common/cors.ts"

// Trava em memória na Edge Function para impedir envios simultâneos para o mesmo usuário e título (15 segundos)
const recentPushes = new Map<string, number>();

function isDuplicatePush(userId: string, title: string): boolean {
  const now = Date.now();
  // Limpa entradas com mais de 30 segundos
  for (const [key, timestamp] of recentPushes.entries()) {
    if (now - timestamp > 30000) {
      recentPushes.delete(key);
    }
  }

  const key = `${userId}_${title.trim()}`;
  if (recentPushes.has(key)) {
    const lastTimestamp = recentPushes.get(key)!;
    if (now - lastTimestamp < 15000) {
      return true;
    }
  }

  recentPushes.set(key, now);
  return false;
}

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

    const body = await req.json()
    console.log('Push notification webhook received payload:', JSON.stringify(body))

    let record = body.record
    if (!record && body.type === 'INSERT') {
      record = body.record
    }

    if (!record) {
      record = body
    }

    const userId = record.user_id as string
    const title = record.title as string
    const content = record.content as string
    const type = (record.type as string) ?? 'system'
    const notificationData = (record.data as Record<string, unknown>) ?? {}

    if (!userId || !title) {
      return new Response(
        JSON.stringify({ message: 'Payload inválido: user_id e title são obrigatórios.' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
      )
    }

    // 🛑 Trava de Idempotência: impede envio duplo de FCM se o Supabase disparar múltiplos webhooks/triggers
    if (isDuplicatePush(userId, title)) {
      console.log(`🛑 Push duplicado suprimido pela Edge Function para ${userId}: "${title}"`)
      return new Response(
        JSON.stringify({ success: true, message: 'Push duplicado suprimido pela trava de idempotência.' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      )
    }

    // Busca o FCM Token e a preferência de som do usuário na tabela `users`
    const { data: userRecord, error: userError } = await supabaseAdmin
      .from('users')
      .select('fcm_token, notification_sound_key')
      .eq('id', userId)
      .single()

    if (userError || !userRecord?.fcm_token) {
      console.log(`Usuário ${userId} não possui fcm_token cadastrado. Push omitido.`)
      return new Response(
        JSON.stringify({ message: 'FCM Token não encontrado para este usuário.' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      )
    }

    const fcmToken = userRecord.fcm_token as String
    const soundKey = (userRecord.notification_sound_key as String) ?? 'default'

    const channelId = soundKey !== 'default'
      ? `channel_${soundKey}`
      : 'high_importance_channel'

    // Formata os dados para o payload do FCM (strings chave-valor)
    const fcmData: Record<string, string> = {
      type,
      title,
      content,
    }

    for (const [key, value] of Object.entries(notificationData)) {
      if (value !== null && value !== undefined) {
        fcmData[key] = String(value)
      }
    }

    // Dispara a notificação Push via FCM HTTP v1
    await sendFcmNotification({
      token: fcmToken,
      title: title,
      body: content ?? '',
      sound: soundKey,
      channelId,
      data: fcmData,
    })

    console.log(`✅ Push Notification FCM enviado com sucesso para ${userId} (Som: ${soundKey}).`)

    return new Response(
      JSON.stringify({ success: true, message: 'Push Notification enviada com sucesso.' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )
  } catch (error) {
    console.error('❌ Erro na Edge Function push-notification:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})
