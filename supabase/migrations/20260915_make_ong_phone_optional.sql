-- ==============================================================================
-- Migração: 20260915_make_ong_phone_optional.sql
-- Descrição: 
--   1. Tornar telefone/WhatsApp e outros contatos opcionais em ong_profiles.
--   2. Garantir políticas RLS públicas de SELECT em ong_profiles e company_profiles
--      para permitir que qualquer usuário logado ou visitante encontre os perfis na busca.
-- ==============================================================================

-- 1. Contatos opcionais para ONGs
ALTER TABLE public.ong_profiles ALTER COLUMN phone DROP NOT NULL;
ALTER TABLE public.ong_profiles ALTER COLUMN email DROP NOT NULL;

-- 2. Garantir RLS e leitura pública irrestrita para ONGs
ALTER TABLE public.ong_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Perfis de ONG sao publicos para visualizacao e busca" ON public.ong_profiles;
CREATE POLICY "Perfis de ONG sao publicos para visualizacao e busca"
    ON public.ong_profiles
    FOR SELECT
    USING (true);

-- 3. Garantir RLS e leitura pública irrestrita para Empresas
ALTER TABLE public.company_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Perfis de empresas sao publicos para visualizacao e busca" ON public.company_profiles;
CREATE POLICY "Perfis de empresas sao publicos para visualizacao e busca"
    ON public.company_profiles
    FOR SELECT
    USING (true);

-- 4. Índices para otimizar pesquisa textual por nome
CREATE INDEX IF NOT EXISTS idx_ong_profiles_name_trgm ON public.ong_profiles USING gin (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_company_profiles_name_trgm ON public.company_profiles USING gin (name gin_trgm_ops);
