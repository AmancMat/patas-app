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

    let daysToSearch = [3, 1, 0]; // 3 dias antes, 1 dia antes e no dia do vencimento
    try {
      const body = await req.json();
      if (body.days_ahead !== undefined) {
        daysToSearch = Array.isArray(body.days_ahead) ? body.days_ahead : [Number(body.days_ahead)];
      }
    } catch (_) {
      // Usar padrão se payload estiver vazio
    }

    console.log(`💉 Iniciando busca de vacinas próximas para os dias: ${daysToSearch.join(', ')}...`);

    let totalNotificationsSent = 0;
    const now = new Date();

    for (const days of daysToSearch) {
      const targetDate = new Date(now);
      targetDate.setDate(targetDate.getDate() + days);

      const targetStart = new Date(targetDate);
      targetStart.setHours(0, 0, 0, 0);

      const targetEnd = new Date(targetDate);
      targetEnd.setHours(23, 59, 59, 999);

      // Buscar vacinas no intervalo do dia de alerta
      const { data: vaccines, error: vacError } = await supabaseAdmin
        .from('pet_vaccines')
        .select('*, pets(*)')
        .gte('next_dose_date', targetStart.toISOString())
        .lte('next_dose_date', targetEnd.toISOString());

      if (vacError) {
        console.error(`Erro ao buscar vacinas para ${days} dias:`, vacError);
        continue;
      }

      if (!vaccines || vaccines.length === 0) continue;

      for (const vac of vaccines) {
        const pet = vac.pets;
        if (!pet || !pet.user_id) continue;

        const userId = pet.user_id;

        // Buscar dados do tutor e token FCM
        const { data: userRecord } = await supabaseAdmin
          .from('users')
          .select('fcm_token, notification_sound_key')
          .eq('id', userId)
          .maybeSingle();

        const fcmToken = userRecord?.fcm_token;
        if (!fcmToken) {
          console.log(`Tutor ${userId} do pet ${pet.name} não possui fcm_token. Ignorando push.`);
          continue;
        }

        const dateFormatted = new Date(vac.next_dose_date).toLocaleDateString('pt-BR');
        let title = `💉 Vacina de ${pet.name}`;
        let bodyText = '';

        if (days === 0) {
          title = `🚨 Vacina HOJE para ${pet.name}!`;
          bodyText = `A vacina "${vac.name}" de ${pet.name} deve ser aplicada hoje (${dateFormatted}). Acesse o Patas Saúde.`;
        } else if (days === 1) {
          title = `💉 Amanhã: Vacina de ${pet.name}`;
          bodyText = `Falta apenas 1 dia para a próxima dose da vacina "${vac.name}" de ${pet.name} (${dateFormatted}).`;
        } else {
          title = `💉 Lembrete de Vacina: ${pet.name}`;
          bodyText = `Faltam ${days} dias para a dose da vacina "${vac.name}" de ${pet.name} (${dateFormatted}). Mantenha a proteção em dia!`;
        }

        const soundKey = userRecord?.notification_sound_key ?? 'default';
        const channelId = soundKey !== 'default' ? `channel_${soundKey}` : 'high_importance_channel';

        try {
          // Send FCM Notification
          await sendFcmNotification({
            token: fcmToken,
            title: title,
            body: bodyText,
            sound: soundKey,
            channelId: channelId,
            data: {
              type: 'vaccine_alert',
              pet_id: pet.id,
              vaccine_id: vac.id,
              next_dose_date: vac.next_dose_date
            }
          });

          // Insert Notification into app's notifications table
          try {
            await supabaseAdmin.from('notifications').insert({
              user_id: userId,
              title: title,
              content: bodyText,
              type: 'vaccine_alert',
              read: false,
              created_at: new Date().toISOString()
            });
          } catch (_) {
            // Ignorar erro se tabela de notificações tiver esquema diferente
          }

          totalNotificationsSent++;
          console.log(`✅ Push de vacina enviado com sucesso para tutor ${userId} (Pet: ${pet.name}, Vacina: ${vac.name})`);
        } catch (fcmErr) {
          console.error(`❌ Erro ao enviar Push FCM de vacina para ${userId}:`, fcmErr);
        }
      }
    }

    return new Response(
      JSON.stringify({ success: true, count: totalNotificationsSent, message: `Processados alertas de vacina. Total enviados: ${totalNotificationsSent}` }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    );
  } catch (error) {
    console.error('❌ Erro na Edge Function vaccine-alert:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    );
  }
});
