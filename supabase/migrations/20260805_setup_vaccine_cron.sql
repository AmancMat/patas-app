-- ============================================================
-- PATAS SAÚDE — Agendamento de Alertas de Vacinação (pg_cron)
-- Execute este script no SQL Editor do Supabase para agendar lembretes diários de vacinas
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Remove o job antigo se existir para evitar duplicidades
SELECT cron.unschedule(jobid) FROM cron.job WHERE jobname = 'notify-upcoming-vaccines';

-- Agendamento Diário (11:00 UTC = 08:00 Horário de Brasília)
-- Dispara a Edge Function 'vaccine-alert' que verifica doses a vencer em 3 dias, 1 dia e no dia
SELECT cron.schedule(
  'notify-upcoming-vaccines',
  '0 11 * * *',
  $$
    SELECT net.http_post(
      url := current_setting('app.supabase_url') || '/functions/v1/vaccine-alert',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.service_role_key')
      ),
      body := '{"days_ahead": [3, 1, 0]}'::jsonb
    )
  $$
);

-- Consulta de confirmação dos jobs agendados no banco
SELECT jobid, jobname, schedule, command, active
FROM cron.job
WHERE jobname = 'notify-upcoming-vaccines';
