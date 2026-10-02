-- ==============================================================================
-- PATAS ACOLHE & CENTRAL DE ADOÇÃO RESPONSÁVEL
-- Migração: 20260914_patas_acolhe_and_adoption_schema.sql
-- Descrição: Tabelas para gestão de animais sob tutela de ONGs e fichas de adoção
-- ==============================================================================

-- 1. TABELA DE ANIMAIS ACOLHIDOS DA ONG (shelter_animals)
CREATE TABLE IF NOT EXISTS public.shelter_animals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ong_id UUID NOT NULL,
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    species TEXT NOT NULL DEFAULT 'canino', -- 'canino', 'felino', 'outro'
    breed TEXT DEFAULT 'SRD (Sem Raça Definida)',
    gender TEXT NOT NULL DEFAULT 'macho', -- 'macho', 'femea'
    size TEXT NOT NULL DEFAULT 'medio', -- 'pequeno', 'medio', 'grande'
    age_estimate TEXT, -- ex: '2 anos', 'Filhote (~4 meses)', 'Adulto', 'Idoso'
    rescue_story TEXT,
    behavior_notes TEXT,
    photo_url TEXT,
    gallery_photos TEXT[] DEFAULT '{}',
    is_castrated BOOLEAN NOT NULL DEFAULT false,
    is_vaccinated BOOLEAN NOT NULL DEFAULT false,
    is_dewormed BOOLEAN NOT NULL DEFAULT false,
    special_needs TEXT,
    status TEXT NOT NULL DEFAULT 'disponivel', -- 'disponivel', 'em_tratamento', 'adotado', 'lar_temporario'
    is_public_adoption BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Índices para consultas rápidas
CREATE INDEX IF NOT EXISTS idx_shelter_animals_ong_id ON public.shelter_animals(ong_id);
CREATE INDEX IF NOT EXISTS idx_shelter_animals_status ON public.shelter_animals(status);
CREATE INDEX IF NOT EXISTS idx_shelter_animals_species ON public.shelter_animals(species);
CREATE INDEX IF NOT EXISTS idx_shelter_animals_public ON public.shelter_animals(is_public_adoption);

-- 2. TABELA DE FICHAS / PROPOSTAS DE ADOÇÃO (adoption_applications)
CREATE TABLE IF NOT EXISTS public.adoption_applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    animal_id UUID REFERENCES public.shelter_animals(id) ON DELETE CASCADE,
    ong_id UUID NOT NULL,
    applicant_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    applicant_name TEXT NOT NULL,
    applicant_phone TEXT NOT NULL,
    applicant_email TEXT,
    housing_type TEXT NOT NULL DEFAULT 'casa', -- 'casa', 'apartamento', 'sitio'
    has_yard BOOLEAN DEFAULT true,
    has_other_pets BOOLEAN DEFAULT false,
    other_pets_details TEXT,
    household_agreement BOOLEAN DEFAULT true,
    adoption_reason TEXT,
    status TEXT NOT NULL DEFAULT 'pendente', -- 'pendente', 'em_analise', 'entrevista', 'aprovado', 'recusado'
    notes_ong TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_adoption_app_animal_id ON public.adoption_applications(animal_id);
CREATE INDEX IF NOT EXISTS idx_adoption_app_ong_id ON public.adoption_applications(ong_id);
CREATE INDEX IF NOT EXISTS idx_adoption_app_user_id ON public.adoption_applications(applicant_user_id);
CREATE INDEX IF NOT EXISTS idx_adoption_app_status ON public.adoption_applications(status);

-- ==============================================================================
-- POLÍTICAS DE SEGURANÇA (ROW LEVEL SECURITY - RLS)
-- ==============================================================================

ALTER TABLE public.shelter_animals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.adoption_applications ENABLE ROW LEVEL SECURITY;

-- 1. Políticas para shelter_animals:
DROP POLICY IF EXISTS "Animais disponíveis para adoção são públicos" ON public.shelter_animals;
CREATE POLICY "Animais disponíveis para adoção são públicos"
    ON public.shelter_animals
    FOR SELECT
    USING (
        is_public_adoption = true 
        OR auth.uid() = created_by
        OR EXISTS (
            SELECT 1 FROM public.ong_profiles op 
            WHERE op.id = shelter_animals.ong_id AND op.user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "ONGs e usuários autenticados podem cadastrar acolhidos" ON public.shelter_animals;
CREATE POLICY "ONGs e usuários autenticados podem cadastrar acolhidos"
    ON public.shelter_animals
    FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Responsáveis pela ONG podem atualizar animais acolhidos" ON public.shelter_animals;
CREATE POLICY "Responsáveis pela ONG podem atualizar animais acolhidos"
    ON public.shelter_animals
    FOR UPDATE
    USING (
        auth.uid() = created_by
        OR EXISTS (
            SELECT 1 FROM public.ong_profiles op 
            WHERE op.id = shelter_animals.ong_id AND op.user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Responsáveis pela ONG podem deletar animais acolhidos" ON public.shelter_animals;
CREATE POLICY "Responsáveis pela ONG podem deletar animais acolhidos"
    ON public.shelter_animals
    FOR DELETE
    USING (
        auth.uid() = created_by
        OR EXISTS (
            SELECT 1 FROM public.ong_profiles op 
            WHERE op.id = shelter_animals.ong_id AND op.user_id = auth.uid()
        )
    );

-- 2. Políticas para adoption_applications:
DROP POLICY IF EXISTS "Tutor e ONG podem visualizar propostas de adoção" ON public.adoption_applications;
CREATE POLICY "Tutor e ONG podem visualizar propostas de adoção"
    ON public.adoption_applications
    FOR SELECT
    USING (
        auth.uid() = applicant_user_id
        OR EXISTS (
            SELECT 1 FROM public.ong_profiles op 
            WHERE op.id = adoption_applications.ong_id AND op.user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Tutores autenticados podem enviar ficha de adoção" ON public.adoption_applications;
CREATE POLICY "Tutores autenticados podem enviar ficha de adoção"
    ON public.adoption_applications
    FOR INSERT
    WITH CHECK (auth.uid() = applicant_user_id);

DROP POLICY IF EXISTS "ONG e Tutor podem atualizar propostas de adoção" ON public.adoption_applications;
CREATE POLICY "ONG e Tutor podem atualizar propostas de adoção"
    ON public.adoption_applications
    FOR UPDATE
    USING (
        auth.uid() = applicant_user_id
        OR EXISTS (
            SELECT 1 FROM public.ong_profiles op 
            WHERE op.id = adoption_applications.ong_id AND op.user_id = auth.uid()
        )
    );
