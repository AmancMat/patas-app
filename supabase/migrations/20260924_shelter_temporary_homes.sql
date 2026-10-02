-- ==============================================================================
-- PATAS ACOLHE & TUTORES VOLUNTÁRIOS: REDE DE LARES TEMPORÁRIOS (LTs)
-- Migração: 20260924_shelter_temporary_homes.sql
-- Descrição: Tabela para gestão de lares temporários, inscrições de tutores comuns
--            e vinculação com animais acolhidos da ONG
-- ==============================================================================

-- 1. TABELA DE LARES TEMPORÁRIOS (shelter_temporary_homes)
CREATE TABLE IF NOT EXISTS public.shelter_temporary_homes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ong_id UUID NOT NULL,
    volunteer_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT,
    city TEXT,
    neighborhood TEXT,
    address TEXT,
    housing_type TEXT NOT NULL DEFAULT 'casa', -- 'casa', 'apartamento', 'sitio'
    has_yard BOOLEAN DEFAULT true,
    has_other_pets BOOLEAN DEFAULT false,
    other_pets_details TEXT,
    allowed_species TEXT NOT NULL DEFAULT 'ambos', -- 'canino', 'felino', 'ambos'
    allowed_sizes TEXT[] DEFAULT '{"pequeno","medio"}', -- 'pequeno', 'medio', 'grande'
    can_administer_medication BOOLEAN DEFAULT false,
    max_capacity INT NOT NULL DEFAULT 1,
    status TEXT NOT NULL DEFAULT 'disponivel', -- 'disponivel', 'ocupado', 'pausado', 'candidatura_pendente'
    is_community_volunteer BOOLEAN NOT NULL DEFAULT false, -- True se o tutor comum se voluntariou pelo app
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Índices de alta performance
CREATE INDEX IF NOT EXISTS idx_shelter_lt_ong_id ON public.shelter_temporary_homes(ong_id);
CREATE INDEX IF NOT EXISTS idx_shelter_lt_volunteer_id ON public.shelter_temporary_homes(volunteer_user_id);
CREATE INDEX IF NOT EXISTS idx_shelter_lt_status ON public.shelter_temporary_homes(status);
CREATE INDEX IF NOT EXISTS idx_shelter_lt_species ON public.shelter_temporary_homes(allowed_species);

-- 2. VINCULAR COLUNA temporary_home_id NA TABELA shelter_animals
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'shelter_animals' 
        AND column_name = 'temporary_home_id'
    ) THEN
        ALTER TABLE public.shelter_animals 
        ADD COLUMN temporary_home_id UUID REFERENCES public.shelter_temporary_homes(id) ON DELETE SET NULL;
        
        CREATE INDEX IF NOT EXISTS idx_shelter_animals_lt_id ON public.shelter_animals(temporary_home_id);
    END IF;
END $$;

-- ==============================================================================
-- POLÍTICAS DE SEGURANÇA (ROW LEVEL SECURITY - RLS)
-- ==============================================================================

ALTER TABLE public.shelter_temporary_homes ENABLE ROW LEVEL SECURITY;

-- 1. Leitura: Responsáveis da ONG e o próprio tutor voluntário
DROP POLICY IF EXISTS "Leitura de lares temporários pela ONG e voluntário" ON public.shelter_temporary_homes;
CREATE POLICY "Leitura de lares temporários pela ONG e voluntário"
    ON public.shelter_temporary_homes
    FOR SELECT
    USING (
        auth.uid() = volunteer_user_id
        OR auth.uid() = created_by
        OR EXISTS (
            SELECT 1 FROM public.ong_profiles op 
            WHERE op.id = shelter_temporary_homes.ong_id AND op.user_id = auth.uid()
        )
    );

-- 2. Inserção: Responsáveis da ONG e tutores comuns se candidatando como voluntários
DROP POLICY IF EXISTS "Cadastro e candidatura de lar temporário" ON public.shelter_temporary_homes;
CREATE POLICY "Cadastro e candidatura de lar temporário"
    ON public.shelter_temporary_homes
    FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

-- 3. Atualização: Responsáveis da ONG ou o próprio tutor voluntário
DROP POLICY IF EXISTS "Atualização de lar temporário por ONG ou voluntário" ON public.shelter_temporary_homes;
CREATE POLICY "Atualização de lar temporário por ONG ou voluntário"
    ON public.shelter_temporary_homes
    FOR UPDATE
    USING (
        auth.uid() = volunteer_user_id
        OR auth.uid() = created_by
        OR EXISTS (
            SELECT 1 FROM public.ong_profiles op 
            WHERE op.id = shelter_temporary_homes.ong_id AND op.user_id = auth.uid()
        )
    );

-- 4. Exclusão: Responsáveis da ONG
DROP POLICY IF EXISTS "Exclusão de lar temporário pela ONG" ON public.shelter_temporary_homes;
CREATE POLICY "Exclusão de lar temporário pela ONG"
    ON public.shelter_temporary_homes
    FOR DELETE
    USING (
        auth.uid() = created_by
        OR EXISTS (
            SELECT 1 FROM public.ong_profiles op 
            WHERE op.id = shelter_temporary_homes.ong_id AND op.user_id = auth.uid()
        )
    );
