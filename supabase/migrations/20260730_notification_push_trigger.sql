-- ================================================================
-- MIGRATION: 20260730_notification_push_trigger.sql
-- Trigger em PostgreSQL para invocar automaticamente a Edge Function
-- `push-notification` sempre que uma notificação for inserida.
-- ================================================================

-- 1. Garante extensão pg_net para requisições assíncronas do banco
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- 2. Função de Trigger em PL/pgSQL
CREATE OR REPLACE FUNCTION public.trg_on_notification_inserted()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  edge_function_url TEXT;
  service_role_key TEXT;
  payload JSONB;
BEGIN
  -- Monta o payload com os dados da nova notificação inserida
  payload := jsonb_build_object(
    'record', jsonb_build_object(
      'id', NEW.id,
      'user_id', NEW.user_id,
      'sender_pet_id', NEW.sender_pet_id,
      'type', NEW.type,
      'title', NEW.title,
      'content', NEW.content,
      'data', NEW.data,
      'created_at', NEW.created_at
    )
  );

  -- Tenta obter a URL e a Service Key do ambiente (ou fallback padronizado)
  edge_function_url := current_setting('custom.edge_function_url', true);
  IF edge_function_url IS NULL OR edge_function_url = '' THEN
    edge_function_url := 'https://' || current_setting('request.headers', true)::json->>'host' || '/functions/v1/push-notification';
  END IF;

  service_role_key := current_setting('custom.service_role_key', true);

  -- Dispara a chamada HTTP POST via pg_net (sem bloquear a transação)
  PERFORM extensions.http_post(
    url := edge_function_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || COALESCE(service_role_key, '')
    ),
    body := payload
  );

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Garante que se o webhook falhar, a inserção da notificação no banco NÃO é interrompida
  RAISE WARNING 'Falha ao disparar webhook de Push Notification: %', SQLERRM;
  RETURN NEW;
END;
$$;

-- 3. Associa a Trigger à tabela `notifications`
DROP TRIGGER IF EXISTS on_notification_created_push ON public.notifications;

CREATE TRIGGER on_notification_created_push
  AFTER INSERT ON public.notifications
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_on_notification_inserted();

-- ================================================================
-- NOTA DE CONFIGURAÇÃO NO DASHBOARD DO SUPABASE:
-- Alternativamente ao pg_net, você também pode ativar via Dashboard:
-- Database -> Webhooks -> Add Webhook:
--   Name: push-notification-trigger
--   Table: public.notifications
--   Events: INSERT
--   Type: Supabase Edge Function
--   Edge Function: push-notification
-- ================================================================
