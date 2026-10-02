-- ==============================================================================
-- PATAS ACOLHE: PRONTUÁRIO COLETIVO & HISTÓRICO CLÍNICO DO ABRIGO
-- Migração: 20260924_shelter_medical_records.sql
-- Descrição: Tabela para controle sanitário individual e em lote dos acolhidos
-- ==============================================================================

-- 1. TABELA DE REGISTROS MÉDICOS DOS ACOLHIDOS (shelter_medical_records)
CREATE TABLE IF NOT EXISTS public.shelter_medical_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ong_id UUID NOT NULL,
    animal_id UUID NOT NULL REFERENCES public.shelter_animals(id) ON DELETE CASCADE,
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    record_type TEXT NOT NULL DEFAULT 'anotacao', -- 'vacina', 'vermifugo', 'castracao', 'tratamento', 'exame', 'anotacao'
    title TEXT NOT NULL,
    description TEXT,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    next_due_date TIMESTAMPTZ,
    veterinarian_name TEXT,
    batch_id TEXT, -- ID compartilhado para procedimentos aplicados em lote coletivo
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Índices de alta performance
CREATE INDEX IF NOT EXISTS idx_shelter_med_ong_id ON public.shelter_medical_records(ong_id);
CREATE INDEX IF NOT EXISTS idx_shelter_med_animal_id ON public.shelter_medical_records(animal_id);
CREATE INDEX IF NOT EXISTS idx_shelter_med_type ON public.shelter_medical_records(record_type);
CREATE INDEX IF NOT EXISTS idx_shelter_med_applied_at ON public.shelter_medical_records(applied_at);
CREATE INDEX IF NOT EXISTS idx_shelter_med_batch_id ON public.shelter_medical_records(batch_id);

-- ==============================================================================
-- POLÍTICAS DE SEGURANÇA (ROW LEVEL SECURITY - RLS)
-- ==============================================================================

ALTER TABLE public.shelter_medical_records ENABLE ROW LEVEL SECURITY;

-- 1. Leitura: Responsáveis da ONG e tutores que visualizam o animal
DROP POLICY IF EXISTS "Leitura de prontuários da ONG e público" ON public.shelter_medical_records;
CREATE POLICY "Leitura de prontuários da ONG e público"
    ON public.shelter_medical_records
    FOR SELECT
    USING (
        auth.uid() = created_by
        OR EXISTS (
            SELECT 1 FROM public.ong_profiles op 
            WHERE op.id = shelter_medical_records.ong_id AND op.user_id = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM public.shelter_animals sa 
            WHERE sa.id = shelter_medical_records.animal_id AND sa.is_public_adoption = true
        )
    );

-- 2. Inserção: Membros e voluntários autenticados da ONG
DROP POLICY IF EXISTS "Inserção de prontuário por responsáveis da ONG" ON public.shelter_medical_records;
CREATE POLICY "Inserção de prontuário por responsáveis da ONG"
    ON public.shelter_medical_records
    FOR INSERT
    WITH CHECK (
        auth.uid() IS NOT NULL
        AND (
            auth.uid() = created_by
            OR EXISTS (
                SELECT 1 FROM public.ong_profiles op 
                WHERE op.id = shelter_medical_records.ong_id AND op.user_id = auth.uid()
            )
        )
    );

-- 3. Atualização: Responsáveis da ONG
DROP POLICY IF EXISTS "Atualização de prontuário por responsáveis da ONG" ON public.shelter_medical_records;
CREATE POLICY "Atualização de prontuário por responsáveis da ONG"
    ON public.shelter_medical_records
    FOR UPDATE
    USING (
        auth.uid() = created_by
        OR EXISTS (
            SELECT 1 FROM public.ong_profiles op 
            WHERE op.id = shelter_medical_records.ong_id AND op.user_id = auth.uid()
        )
    );

-- 4. Exclusão: Responsáveis da ONG
DROP POLICY IF EXISTS "Exclusão de prontuário por responsáveis da ONG" ON public.shelter_medical_records;
CREATE POLICY "Exclusão de prontuário por responsáveis da ONG"
    ON public.shelter_medical_records
    FOR DELETE
    USING (
        auth.uid() = created_by
        OR EXISTS (
            SELECT 1 FROM public.ong_profiles op 
            WHERE op.id = shelter_medical_records.ong_id AND op.user_id = auth.uid()
        )
    );
