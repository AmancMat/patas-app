-- ==============================================================================
-- PATAS ACOLHE: ATUALIZAÇÃO SOLANA PAY E POLÍTICA DE STORAGE PARA CAMPANHAS
-- Migração: 20260928_add_solana_wallet_and_campaign_storage.sql
-- ==============================================================================

-- 1. Adicionar coluna 'solana_wallet' na tabela de campanhas de doação
ALTER TABLE public.shelter_donation_campaigns 
ADD COLUMN IF NOT EXISTS solana_wallet TEXT;

-- 2. Garantir índice para consultas se necessário
CREATE INDEX IF NOT EXISTS idx_campaigns_solana_wallet 
ON public.shelter_donation_campaigns(solana_wallet) 
WHERE solana_wallet IS NOT NULL;

-- 3. Políticas de Storage para o Bucket 'pet_avatars' (pasta public/campaigns)
-- Permite que usuários autenticados façam upload de imagens de campanhas
DROP POLICY IF EXISTS "Permitir upload de capas de campanhas por autenticados" ON storage.objects;
CREATE POLICY "Permitir upload de capas de campanhas por autenticados"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'pet_avatars' 
    AND (storage.foldername(name))[1] = 'public'
);

-- Permite atualização/sobrescrita de arquivos na pasta public
DROP POLICY IF EXISTS "Permitir atualizacao de capas de campanhas por autenticados" ON storage.objects;
CREATE POLICY "Permitir atualizacao de capas de campanhas por autenticados"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
    bucket_id = 'pet_avatars' 
    AND (storage.foldername(name))[1] = 'public'
);

-- Permite leitura pública de todas as fotos na pasta public
DROP POLICY IF EXISTS "Permitir leitura publica de capas de campanhas" ON storage.objects;
CREATE POLICY "Permitir leitura publica de capas de campanhas"
ON storage.objects
FOR SELECT
TO public
USING (
    bucket_id = 'pet_avatars'
);
