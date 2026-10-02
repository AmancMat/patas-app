-- ==============================================================================
-- MIGRAÇÃO: Habilitação de Realtime no Supabase para o Patas Love
-- ==============================================================================

-- Adiciona a tabela love_messages na publicação do Realtime para que
-- novas mensagens sejam emitidas aos clientes conectados instantaneamente.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'love_messages'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE love_messages;
  END IF;
END $$;

-- Adiciona a tabela love_chats na publicação do Realtime para sincronização
-- de status de encontro (proposta, agendamento e realização) em tempo real.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'love_chats'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE love_chats;
  END IF;
END $$;
