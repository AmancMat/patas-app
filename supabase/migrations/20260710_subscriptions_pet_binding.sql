-- 1. Limpar dados antigos das faturas e assinaturas para evitar conflito de restrições
TRUNCATE TABLE public.invoices CASCADE;
TRUNCATE TABLE public.subscriptions CASCADE;

-- 2. Adicionar coluna pet_id na tabela subscriptions vinculando com pets
ALTER TABLE public.subscriptions 
    ADD COLUMN pet_id UUID REFERENCES public.pets(id) ON DELETE CASCADE NOT NULL;

-- 3. Adicionar restrição UNIQUE para garantir no máximo uma assinatura ativa por pet
ALTER TABLE public.subscriptions 
    ADD CONSTRAINT subscriptions_pet_id_key UNIQUE (pet_id);

-- 4. Criar índice para otimização de consultas financeiras por pet
CREATE INDEX IF NOT EXISTS idx_subscriptions_pet ON public.subscriptions(pet_id);

-- 5. Atualizar a função e trigger de validação de avistamentos (sightings) para verificar a assinatura por pet
CREATE OR REPLACE FUNCTION public.check_sighting_subscription()
RETURNS TRIGGER AS $$
DECLARE
    pet_sub_status VARCHAR(50);
BEGIN
    -- Buscar o status da assinatura do pet associado à tag
    SELECT s.status INTO pet_sub_status
    FROM public.tags t
    LEFT JOIN public.subscriptions s ON s.pet_id = t.pet_id
    WHERE t.id = NEW.tag_id;

    -- Se o pet tiver assinatura e ela estiver suspensa/cancelada/atrasada, bloqueia o avistamento
    IF pet_sub_status IN ('past_due', 'canceled', 'inactive') THEN
        RAISE EXCEPTION 'O serviço de localização para esta tag está suspenso.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
