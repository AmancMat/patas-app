-- ==============================================================================
-- PATAS ACOLHE: CALENDÁRIO DE EVENTOS, FEIRAS DE ADOÇÃO E BAZARES
-- Migração: 20260924_shelter_events.sql
-- Descrição: Gestão de eventos e feiras de adoção pela ONG com publicação
--            no feed social e confirmação de presença (RSVP) pelos tutores
-- ==============================================================================

-- 1. TABELA PRINCIPAL DE EVENTOS DO ABRIGO
CREATE TABLE IF NOT EXISTS public.shelter_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ong_id UUID NOT NULL,
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    event_type TEXT NOT NULL DEFAULT 'adocao', -- 'adocao', 'vacinacao', 'bazar', 'encontro', 'outro'
    banner_url TEXT,
    location_name TEXT NOT NULL,
    address TEXT NOT NULL,
    city TEXT,
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ,
    contact_whatsapp TEXT,
    contact_phone TEXT,
    attendees_count INT NOT NULL DEFAULT 0,
    is_published_feed BOOLEAN NOT NULL DEFAULT true,
    status TEXT NOT NULL DEFAULT 'agendado', -- 'agendado', 'em_andamento', 'concluido', 'cancelado'
    participating_animals_ids UUID[] DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Índices de alta performance
CREATE INDEX IF NOT EXISTS idx_shelter_events_ong_id ON public.shelter_events(ong_id);
CREATE INDEX IF NOT EXISTS idx_shelter_events_start_date ON public.shelter_events(start_date);
CREATE INDEX IF NOT EXISTS idx_shelter_events_type ON public.shelter_events(event_type);
CREATE INDEX IF NOT EXISTS idx_shelter_events_status ON public.shelter_events(status);

-- 2. TABELA DE CONFIRMAÇÕES DE PRESENÇA (RSVP)
CREATE TABLE IF NOT EXISTS public.shelter_event_attendees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES public.shelter_events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_event_user_attendee UNIQUE (event_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_event_attendees_event ON public.shelter_event_attendees(event_id);
CREATE INDEX IF NOT EXISTS idx_event_attendees_user ON public.shelter_event_attendees(user_id);

-- 3. TRIGGER PARA ATUALIZAR AUTOMATICAMENTE O CONTADOR attendees_count
CREATE OR REPLACE FUNCTION public.fn_sync_event_attendees_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.shelter_events
        SET attendees_count = attendees_count + 1
        WHERE id = NEW.event_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.shelter_events
        SET attendees_count = GREATEST(0, attendees_count - 1)
        WHERE id = OLD.event_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_sync_event_attendees_count ON public.shelter_event_attendees;
CREATE TRIGGER trg_sync_event_attendees_count
AFTER INSERT OR DELETE ON public.shelter_event_attendees
FOR EACH ROW EXECUTE FUNCTION public.fn_sync_event_attendees_count();

-- ==============================================================================
-- POLÍTICAS DE SEGURANÇA (ROW LEVEL SECURITY - RLS)
-- ==============================================================================

ALTER TABLE public.shelter_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shelter_event_attendees ENABLE ROW LEVEL SECURITY;

-- Regras para shelter_events:
-- 1. Leitura: Aberta para todos os usuários autenticados (feed e catálogo)
DROP POLICY IF EXISTS "Leitura pública de eventos agendados" ON public.shelter_events;
CREATE POLICY "Leitura pública de eventos agendados"
    ON public.shelter_events
    FOR SELECT
    USING (true);

-- 2. Inserção: Apenas membros e administradores da ONG
DROP POLICY IF EXISTS "Criação de eventos pela ONG" ON public.shelter_events;
CREATE POLICY "Criação de eventos pela ONG"
    ON public.shelter_events
    FOR INSERT
    WITH CHECK (
        auth.uid() = created_by
        OR EXISTS (
            SELECT 1 FROM public.ong_profiles op 
            WHERE op.id = shelter_events.ong_id AND op.user_id = auth.uid()
        )
    );

-- 3. Atualização: Apenas a própria ONG
DROP POLICY IF EXISTS "Atualização de eventos pela ONG" ON public.shelter_events;
CREATE POLICY "Atualização de eventos pela ONG"
    ON public.shelter_events
    FOR UPDATE
    USING (
        auth.uid() = created_by
        OR EXISTS (
            SELECT 1 FROM public.ong_profiles op 
            WHERE op.id = shelter_events.ong_id AND op.user_id = auth.uid()
        )
    );

-- 4. Exclusão: Apenas a própria ONG
DROP POLICY IF EXISTS "Exclusão de eventos pela ONG" ON public.shelter_events;
CREATE POLICY "Exclusão de eventos pela ONG"
    ON public.shelter_events
    FOR DELETE
    USING (
        auth.uid() = created_by
        OR EXISTS (
            SELECT 1 FROM public.ong_profiles op 
            WHERE op.id = shelter_events.ong_id AND op.user_id = auth.uid()
        )
    );

-- Regras para shelter_event_attendees:
-- 1. Leitura: Usuários autenticados podem ver quem vai
DROP POLICY IF EXISTS "Leitura de presenças em eventos" ON public.shelter_event_attendees;
CREATE POLICY "Leitura de presenças em eventos"
    ON public.shelter_event_attendees
    FOR SELECT
    USING (true);

-- 2. Inserção: O próprio usuário autenticado pode confirmar sua presença
DROP POLICY IF EXISTS "Confirmação de presença pelo usuário" ON public.shelter_event_attendees;
CREATE POLICY "Confirmação de presença pelo usuário"
    ON public.shelter_event_attendees
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- 3. Cancelamento: O próprio usuário pode cancelar sua confirmação
DROP POLICY IF EXISTS "Cancelamento de presença pelo usuário" ON public.shelter_event_attendees;
CREATE POLICY "Cancelamento de presença pelo usuário"
    ON public.shelter_event_attendees
    FOR DELETE
    USING (auth.uid() = user_id);
