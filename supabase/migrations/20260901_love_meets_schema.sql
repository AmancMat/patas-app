-- ==============================================================================
-- MIGRATION: Patas Love Meets (Marcos de Encontros Realizados)
-- Data: 2026-09-01
-- ==============================================================================

-- 1. Criação da tabela love_meets caso não exista
CREATE TABLE IF NOT EXISTS love_meets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID REFERENCES love_chats(id) ON DELETE CASCADE,
    pet_a_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
    pet_b_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
    confirmed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    photo_url TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT unique_love_meet UNIQUE(chat_id)
);

-- Índices para otimização de busca por pet
CREATE INDEX IF NOT EXISTS idx_love_meets_pet_a ON love_meets(pet_a_id);
CREATE INDEX IF NOT EXISTS idx_love_meets_pet_b ON love_meets(pet_b_id);
CREATE INDEX IF NOT EXISTS idx_love_meets_confirmed_at ON love_meets(confirmed_at);

-- 2. Habilitação de RLS
ALTER TABLE love_meets ENABLE ROW LEVEL SECURITY;

-- 3. Políticas de Segurança (RLS)
-- Permitir leitura para todos os usuários autenticados (para exibição de marcos na história pública dos pets)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'love_meets' AND policyname = 'Leitura de encontros confirmados para autenticados'
    ) THEN
        CREATE POLICY "Leitura de encontros confirmados para autenticados"
        ON love_meets FOR SELECT
        TO authenticated
        USING (true);
    END IF;
END $$;

-- Permitir criação se o usuário for tutor de um dos pets envolvidos
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'love_meets' AND policyname = 'Tutores dos pets podem registrar encontros'
    ) THEN
        CREATE POLICY "Tutores dos pets podem registrar encontros"
        ON love_meets FOR INSERT
        TO authenticated
        WITH CHECK (
            EXISTS (
                SELECT 1 FROM pets
                WHERE (pets.id = love_meets.pet_a_id OR pets.id = love_meets.pet_b_id)
                  AND pets.user_id = auth.uid()
            )
        );
    END IF;
END $$;
