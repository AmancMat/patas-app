-- ==============================================================================
-- PATAS ACOLHE: MURAL DE DOAÇÕES & PIX TRANSPARENTE
-- Migração: 20260914_shelter_donation_campaigns.sql
-- Descrição: Tabela de campanhas de arrecadação comunitária com chave PIX direta
-- ==============================================================================

-- 1. TABELA DE CAMPANHAS DE DOAÇÃO (shelter_donation_campaigns)
CREATE TABLE IF NOT EXISTS public.shelter_donation_campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ong_id UUID NOT NULL,
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    ong_name TEXT,
    ong_photo_url TEXT,
    title TEXT NOT NULL,
    description TEXT,
    image_url TEXT,
    category TEXT NOT NULL DEFAULT 'Ração & Alimento', -- 'Ração & Alimento', 'Saúde & Cirurgia', 'Reforma & Abrigo', 'Geral & Manutenção'
    goal_type TEXT NOT NULL DEFAULT 'money', -- 'money' (financeira R$) ou 'items' (kg, sacos, etc)
    target_amount NUMERIC(12,2) NOT NULL DEFAULT 1000.00,
    current_amount NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    unit_label TEXT NOT NULL DEFAULT 'R$',
    pix_key TEXT,
    pix_key_type TEXT DEFAULT 'cnpj', -- 'cnpj', 'email', 'telefone', 'aleatoria'
    beneficiary_pet_name TEXT,
    beneficiary_pet_photo TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    ends_at TIMESTAMPTZ
);

-- Índices de performance
CREATE INDEX IF NOT EXISTS idx_campaigns_ong_id ON public.shelter_donation_campaigns(ong_id);
CREATE INDEX IF NOT EXISTS idx_campaigns_category ON public.shelter_donation_campaigns(category);
CREATE INDEX IF NOT EXISTS idx_campaigns_is_active ON public.shelter_donation_campaigns(is_active);
CREATE INDEX IF NOT EXISTS idx_campaigns_created_at ON public.shelter_donation_campaigns(created_at DESC);

-- 2. HABILITAR ROW LEVEL SECURITY (RLS)
ALTER TABLE public.shelter_donation_campaigns ENABLE ROW LEVEL SECURITY;

-- Políticas de RLS:

-- A) Leitura Pública (Qualquer usuário autenticado ou visitante pode ver campanhas ativas para doar)
DROP POLICY IF EXISTS "Permitir leitura pública de campanhas ativas" ON public.shelter_donation_campaigns;
CREATE POLICY "Permitir leitura pública de campanhas ativas"
ON public.shelter_donation_campaigns
FOR SELECT
USING (true);

-- B) Inserção: Usuários autenticados (ONGs) podem criar campanhas
DROP POLICY IF EXISTS "Permitir criação de campanhas por usuários autenticados" ON public.shelter_donation_campaigns;
CREATE POLICY "Permitir criação de campanhas por usuários autenticados"
ON public.shelter_donation_campaigns
FOR INSERT
WITH CHECK (auth.role() = 'authenticated');

-- C) Atualização: Apenas o criador da campanha ou membros autenticados podem editar
DROP POLICY IF EXISTS "Permitir atualização de campanhas pelo criador" ON public.shelter_donation_campaigns;
CREATE POLICY "Permitir atualização de campanhas pelo criador"
ON public.shelter_donation_campaigns
FOR UPDATE
USING (auth.uid() = created_by OR auth.role() = 'authenticated');

-- D) Exclusão: Apenas o criador pode remover a campanha
DROP POLICY IF EXISTS "Permitir exclusão de campanhas pelo criador" ON public.shelter_donation_campaigns;
CREATE POLICY "Permitir exclusão de campanhas pelo criador"
ON public.shelter_donation_campaigns
FOR DELETE
USING (auth.uid() = created_by OR auth.role() = 'authenticated');
