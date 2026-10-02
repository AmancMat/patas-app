-- ==============================================================================
-- MIGRATION: Patas Love Schema (Acasalamento e Chat entre Tutores)
-- Data: 2026-07-30
-- ==============================================================================

-- 1. Adicionar campo de opt-in do Patas Love na tabela de pets
ALTER TABLE pets ADD COLUMN IF NOT EXISTS is_love_active BOOLEAN DEFAULT false;

-- 2. Tabela de Chats entre dois Pets (love_chats)
CREATE TABLE IF NOT EXISTS love_chats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pet_a_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
    pet_b_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT unique_pet_pair UNIQUE(pet_a_id, pet_b_id)
);

-- Index para agilizar consultas de chats por pet
CREATE INDEX IF NOT EXISTS idx_love_chats_pet_a ON love_chats(pet_a_id);
CREATE INDEX IF NOT EXISTS idx_love_chats_pet_b ON love_chats(pet_b_id);

-- 3. Tabela de Mensagens de Texto (love_messages)
CREATE TABLE IF NOT EXISTS love_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID NOT NULL REFERENCES love_chats(id) ON DELETE CASCADE,
    sender_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Index para listagem de mensagens ordenadas por data
CREATE INDEX IF NOT EXISTS idx_love_messages_chat_created ON love_messages(chat_id, created_at ASC);

-- 4. Tabela de Bloqueios entre Tutores (love_blocks)
CREATE TABLE IF NOT EXISTS love_blocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    blocker_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    blocked_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT unique_block_pair UNIQUE(blocker_id, blocked_id)
);

-- ==============================================================================
-- POLÍTICAS DE SEGURANÇA (RLS)
-- ==============================================================================

ALTER TABLE love_chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE love_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE love_blocks ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------
-- RLS: love_chats
-- Permitir SELECT se o usuário autenticado for dono do pet_a ou pet_b
-- ------------------------------------------------------------------------------
CREATE POLICY "Tutores envolvidos podem ver seus chats"
ON love_chats FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM pets
        WHERE (pets.id = love_chats.pet_a_id OR pets.id = love_chats.pet_b_id)
          AND pets.user_id = auth.uid()
    )
);

CREATE POLICY "Tutores autenticados podem iniciar chats"
ON love_chats FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM pets
        WHERE (pets.id = love_chats.pet_a_id OR pets.id = love_chats.pet_b_id)
          AND pets.user_id = auth.uid()
    )
);

-- ------------------------------------------------------------------------------
-- RLS: love_messages
-- ------------------------------------------------------------------------------
CREATE POLICY "Tutores do chat podem ler mensagens"
ON love_messages FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM love_chats
        JOIN pets ON (pets.id = love_chats.pet_a_id OR pets.id = love_chats.pet_b_id)
        WHERE love_chats.id = love_messages.chat_id
          AND pets.user_id = auth.uid()
    )
);

CREATE POLICY "Tutores do chat podem enviar mensagens"
ON love_messages FOR INSERT
TO authenticated
WITH CHECK (
    sender_user_id = auth.uid()
    AND EXISTS (
        SELECT 1 FROM love_chats
        JOIN pets ON (pets.id = love_chats.pet_a_id OR pets.id = love_chats.pet_b_id)
        WHERE love_chats.id = love_messages.chat_id
          AND pets.user_id = auth.uid()
    )
);

-- ------------------------------------------------------------------------------
-- RLS: love_blocks
-- ------------------------------------------------------------------------------
CREATE POLICY "Usuário pode visualizar seus bloqueios"
ON love_blocks FOR SELECT
TO authenticated
USING (blocker_id = auth.uid());

CREATE POLICY "Usuário pode criar bloqueio"
ON love_blocks FOR INSERT
TO authenticated
WITH CHECK (blocker_id = auth.uid());

CREATE POLICY "Usuário pode remover seu bloqueio"
ON love_blocks FOR DELETE
TO authenticated
USING (blocker_id = auth.uid());
