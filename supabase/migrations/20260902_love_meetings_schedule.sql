-- ==============================================================================
-- MIGRATION: Patas Love - Agendamento Cronológico de Encontros
-- Data: 2026-09-02
-- ==============================================================================

-- Adiciona colunas para suportar o fluxo cronológico na tabela love_chats:
-- 1. status: 'active', 'meeting_proposed', 'meeting_scheduled', 'met_in_person'
ALTER TABLE love_chats ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active';

-- 2. Quem propôs o encontro
ALTER TABLE love_chats ADD COLUMN IF NOT EXISTS meeting_proposed_by UUID REFERENCES auth.users(id);

-- 3. Data e horário agendados para o encontro
ALTER TABLE love_chats ADD COLUMN IF NOT EXISTS meeting_date TIMESTAMPTZ;

-- 4. Local do encontro (ex: Parque, Praça Pet, Pet Friendly)
ALTER TABLE love_chats ADD COLUMN IF NOT EXISTS meeting_location TEXT;

-- 5. Observações/dicas para o encontro
ALTER TABLE love_chats ADD COLUMN IF NOT EXISTS meeting_notes TEXT;

-- Índice para otimização de status de encontros
CREATE INDEX IF NOT EXISTS idx_love_chats_status ON love_chats(status);
