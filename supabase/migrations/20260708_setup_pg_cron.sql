-- ============================================================
-- PATAS ENCONTRA — Configuração Automática (pg_cron e Webhooks)
-- Execute este script completo no SQL Editor do Supabase
-- ============================================================

-- ============================================================
-- PARTE 1: Ativação das Extensões
-- ============================================================
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- ============================================================
-- PARTE 2: Database Webhook para Avistamentos (Sightings)
-- Executa a Edge Function 'sighting-alert' a cada novo registro
-- ============================================================

CREATE OR REPLACE FUNCTION public.notify_sighting_webhook()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  PERFORM net.http_post(
    url := current_setting('app.supabase_url') || '/functions/v1/sighting-alert',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.service_role_key')
    ),
    body := jsonb_build_object(
      'type', TG_OP,
      'table', TG_TABLE_NAME,
      'record', row_to_json(NEW)
    )
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sighting_webhook ON public.sightings;
CREATE TRIGGER trg_sighting_webhook
AFTER INSERT ON public.sightings
FOR EACH ROW
EXECUTE FUNCTION public.notify_sighting_webhook();

-- ============================================================
-- PARTE 3: Agendamento de Tarefas Diárias (pg_cron)
-- ============================================================

-- Remove se já existirem para evitar duplicidade ou erros de chave primária
SELECT cron.unschedule(jobid) FROM cron.job WHERE jobname = 'check-expired-subscriptions';
SELECT cron.unschedule(jobid) FROM cron.job WHERE jobname = 'notify-trial-expiring';
SELECT cron.unschedule(jobid) FROM cron.job WHERE jobname = 'notify-grace-expiring';

-- Job 1: Verificação diária de assinaturas expiradas (03:00 UTC)
SELECT cron.schedule(
  'check-expired-subscriptions',
  '0 3 * * *',
  'SELECT public.check_expired_subscriptions()'
);

-- Job 2: Alertas de Trial expirando em 5 dias (09:00 UTC)
SELECT cron.schedule(
  'notify-trial-expiring',
  '0 9 * * *',
  $$
    SELECT net.http_post(
      url := current_setting('app.supabase_url') || '/functions/v1/subscription-alert',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.service_role_key')
      ),
      body := '{"alert_type": "trial_expiring"}'::jsonb
    )
  $$
);

-- Job 3: Alertas de Grace Period expirando em 5 dias (09:05 UTC)
SELECT cron.schedule(
  'notify-grace-expiring',
  '5 9 * * *',
  $$
    SELECT net.http_post(
      url := current_setting('app.supabase_url') || '/functions/v1/subscription-alert',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.service_role_key')
      ),
      body := '{"alert_type": "grace_expiring"}'::jsonb
    )
  $$
);

-- ============================================================
-- VERIFICAÇÃO — Execute para confirmar os agendamentos ativos
-- ============================================================
SELECT jobid, jobname, schedule, command, active
FROM cron.job
ORDER BY jobid;
