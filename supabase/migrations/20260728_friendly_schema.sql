-- ============================================================
-- MIGRATION: Patas Friendly Schema
-- Data: 28/07/2026
-- Execute este script no SQL Editor do Supabase
-- ============================================================

-- 1. Criar tabela friendly_places
CREATE TABLE IF NOT EXISTS public.friendly_places (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    name VARCHAR(150) NOT NULL,
    category VARCHAR(50) NOT NULL,
    description TEXT,
    address TEXT NOT NULL,
    phone VARCHAR(20),
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    rules_description TEXT,
    photo_urls TEXT[] DEFAULT '{}',
    boundary_polygon JSONB,
    is_active BOOLEAN DEFAULT true,
    is_claimed BOOLEAN DEFAULT false,
    claimed_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Criar tabela friendly_reviews
CREATE TABLE IF NOT EXISTS public.friendly_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    place_id UUID REFERENCES public.friendly_places(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (place_id, user_id) -- Garante uma única avaliação por usuário para cada local
);

-- 3. Trigger para atualizar updated_at em friendly_places
CREATE OR REPLACE FUNCTION public.handle_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_friendly_places_updated_at ON public.friendly_places;
CREATE TRIGGER trg_friendly_places_updated_at
    BEFORE UPDATE ON public.friendly_places
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_update_timestamp();

-- 4. Criar Índices de Performance
CREATE INDEX IF NOT EXISTS idx_friendly_places_coords 
    ON public.friendly_places (latitude, longitude);

CREATE INDEX IF NOT EXISTS idx_friendly_places_active_category 
    ON public.friendly_places (is_active, category);

CREATE INDEX IF NOT EXISTS idx_friendly_reviews_place 
    ON public.friendly_reviews (place_id);

-- 5. Habilitar Row Level Security (RLS)
ALTER TABLE public.friendly_places ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.friendly_reviews ENABLE ROW LEVEL SECURITY;

-- 6. Criar Políticas RLS para friendly_places
DROP POLICY IF EXISTS "Leitura pública de locais ativos" ON public.friendly_places;
CREATE POLICY "Leitura pública de locais ativos" ON public.friendly_places
    FOR SELECT USING (is_active = true);

DROP POLICY IF EXISTS "Usuários autenticados cadastram locais" ON public.friendly_places;
CREATE POLICY "Usuários autenticados cadastram locais" ON public.friendly_places
    FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Edição do local pelo criador ou proprietário verificado" ON public.friendly_places;
CREATE POLICY "Edição do local pelo criador ou proprietário verificado" ON public.friendly_places
    FOR UPDATE TO authenticated 
    USING (
        (auth.uid() = user_id AND is_claimed = false) OR 
        (auth.uid() = claimed_by)
    )
    WITH CHECK (
        (auth.uid() = user_id AND is_claimed = false) OR 
        (auth.uid() = claimed_by)
    );

DROP POLICY IF EXISTS "Exclusão do local pelo criador (se não reivindicado)" ON public.friendly_places;
CREATE POLICY "Exclusão do local pelo criador (se não reivindicado)" ON public.friendly_places
    FOR DELETE TO authenticated 
    USING (auth.uid() = user_id AND is_claimed = false);

-- 7. Criar Políticas RLS para friendly_reviews
DROP POLICY IF EXISTS "Leitura pública de avaliações" ON public.friendly_reviews;
CREATE POLICY "Leitura pública de avaliações" ON public.friendly_reviews
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Usuários autenticados criam avaliações" ON public.friendly_reviews;
CREATE POLICY "Usuários autenticados criam avaliações" ON public.friendly_reviews
    FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuários atualizam suas próprias avaliações" ON public.friendly_reviews;
CREATE POLICY "Usuários atualizam suas próprias avaliações" ON public.friendly_reviews
    FOR UPDATE TO authenticated 
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuários excluem suas próprias avaliações" ON public.friendly_reviews;
CREATE POLICY "Usuários excluem suas próprias avaliações" ON public.friendly_reviews
    FOR DELETE TO authenticated 
    USING (auth.uid() = user_id);
