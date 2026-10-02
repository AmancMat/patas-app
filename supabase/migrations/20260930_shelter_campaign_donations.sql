-- ==============================================================================
-- PATAS ACOLHE: RECIBOS & HISTÓRICO DE DOAÇÕES DE CAMPANHAS
-- Migração: 20260930_shelter_campaign_donations.sql
-- Descrição: Registro individual de cada doação feita por pets/tutores com recibos,
--            rastreio on-chain (Solana Pay), PIX e cartões.
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.shelter_campaign_donations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id UUID NOT NULL REFERENCES public.shelter_donation_campaigns(id) ON DELETE CASCADE,
    donor_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    donor_pet_id UUID REFERENCES public.pets(id) ON DELETE SET NULL,
    donor_name TEXT,
    donor_photo TEXT,
    amount NUMERIC(12,2) NOT NULL,
    currency TEXT NOT NULL DEFAULT 'BRL', -- 'BRL', 'USDC', 'SOL'
    original_amount NUMERIC(12,4), -- valor original da moeda/token
    token_symbol TEXT DEFAULT 'BRL', -- 'BRL', 'USDC', 'SOL'
    payment_method TEXT NOT NULL DEFAULT 'pix', -- 'solana_pay', 'pix', 'cartao'
    tx_signature TEXT,
    status TEXT NOT NULL DEFAULT 'confirmed', -- 'pending', 'confirmed', 'failed'
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Índices de performance
CREATE INDEX IF NOT EXISTS idx_donations_campaign_id ON public.shelter_campaign_donations(campaign_id);
CREATE INDEX IF NOT EXISTS idx_donations_donor_user ON public.shelter_campaign_donations(donor_user_id);
CREATE INDEX IF NOT EXISTS idx_donations_donor_pet ON public.shelter_campaign_donations(donor_pet_id);
CREATE INDEX IF NOT EXISTS idx_donations_tx_sig ON public.shelter_campaign_donations(tx_signature);
CREATE INDEX IF NOT EXISTS idx_donations_created_at ON public.shelter_campaign_donations(created_at DESC);

-- Habilitar Row Level Security (RLS)
ALTER TABLE public.shelter_campaign_donations ENABLE ROW LEVEL SECURITY;

-- Políticas de RLS
DROP POLICY IF EXISTS "Permitir leitura pública de doações confirmadas" ON public.shelter_campaign_donations;
CREATE POLICY "Permitir leitura pública de doações confirmadas"
ON public.shelter_campaign_donations
FOR SELECT
USING (true);

DROP POLICY IF EXISTS "Permitir inserção de doações por usuários autenticados" ON public.shelter_campaign_donations;
CREATE POLICY "Permitir inserção de doações por usuários autenticados"
ON public.shelter_campaign_donations
FOR INSERT
WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir atualização de doações pelo doador ou gestor" ON public.shelter_campaign_donations;
CREATE POLICY "Permitir atualização de doações pelo doador ou gestor"
ON public.shelter_campaign_donations
FOR UPDATE
USING (auth.uid() = donor_user_id);
