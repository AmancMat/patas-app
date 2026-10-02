-- ==============================================================================
-- PATAS RESGATE & ALERTAS REGIONAIS: CANAL DE CHAMADOS COMUNITÁRIOS
-- Migração: 20260925_rescue_alerts.sql
-- Descrição: Gestão de alertas e pedidos de socorro para animais em risco
--            enviados por tutores/cidadãos e atendidos por ONGs locais
-- ==============================================================================

-- 1. TABELA DE ALERTAS DE RESGATE
CREATE TABLE IF NOT EXISTS public.rescue_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    reporter_name TEXT NOT NULL,
    reporter_phone TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    urgency TEXT NOT NULL DEFAULT 'media', -- 'critico', 'alta', 'media', 'baixa'
    alert_type TEXT NOT NULL DEFAULT 'ferido', -- 'ferido', 'atropelado', 'abandonado_filhotes', 'maus_tratos', 'perdido', 'outro'
    photos TEXT[] DEFAULT '{}',
    address TEXT NOT NULL,
    city TEXT,
    neighborhood TEXT,
    reference_point TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    status TEXT NOT NULL DEFAULT 'aberto', -- 'aberto', 'em_atendimento', 'resgatado', 'cancelado'
    assigned_ong_id UUID,
    assigned_at TIMESTAMPTZ,
    converted_animal_id UUID REFERENCES public.shelter_animals(id) ON DELETE SET NULL,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Índices de alta performance
CREATE INDEX IF NOT EXISTS idx_rescue_alerts_status ON public.rescue_alerts(status);
CREATE INDEX IF NOT EXISTS idx_rescue_alerts_urgency ON public.rescue_alerts(urgency);
CREATE INDEX IF NOT EXISTS idx_rescue_alerts_ong_id ON public.rescue_alerts(assigned_ong_id);
CREATE INDEX IF NOT EXISTS idx_rescue_alerts_reporter ON public.rescue_alerts(reporter_user_id);
CREATE INDEX IF NOT EXISTS idx_rescue_alerts_created_at ON public.rescue_alerts(created_at DESC);

-- ==============================================================================
-- POLÍTICAS DE SEGURANÇA (ROW LEVEL SECURITY - RLS)
-- ==============================================================================

ALTER TABLE public.rescue_alerts ENABLE ROW LEVEL SECURITY;

-- 1. Leitura: Aberta para todos os usuários autenticados (tutores e ONGs)
DROP POLICY IF EXISTS "Leitura de alertas de resgate" ON public.rescue_alerts;
CREATE POLICY "Leitura de alertas de resgate"
    ON public.rescue_alerts
    FOR SELECT
    USING (true);

-- 2. Inserção: Qualquer usuário autenticado (cidadão/tutor reportando risco)
DROP POLICY IF EXISTS "Criação de chamados de socorro" ON public.rescue_alerts;
CREATE POLICY "Criação de chamados de socorro"
    ON public.rescue_alerts
    FOR INSERT
    WITH CHECK (auth.uid() = reporter_user_id OR reporter_user_id IS NULL);

-- 3. Atualização: O próprio autor OU ONGs assumindo atendimento/resgate
DROP POLICY IF EXISTS "Atualização de chamados por autor ou ONG" ON public.rescue_alerts;
CREATE POLICY "Atualização de chamados por autor ou ONG"
    ON public.rescue_alerts
    FOR UPDATE
    USING (
        auth.uid() = reporter_user_id
        OR EXISTS (
            SELECT 1 FROM public.ong_profiles op 
            WHERE op.user_id = auth.uid()
        )
    );

-- 4. Exclusão: O autor ou a ONG vinculada
DROP POLICY IF EXISTS "Exclusão de chamados pelo autor ou ONG" ON public.rescue_alerts;
CREATE POLICY "Exclusão de chamados pelo autor ou ONG"
    ON public.rescue_alerts
    FOR DELETE
    USING (
        auth.uid() = reporter_user_id
        OR EXISTS (
            SELECT 1 FROM public.ong_profiles op 
            WHERE op.id = rescue_alerts.assigned_ong_id AND op.user_id = auth.uid()
        )
    );
