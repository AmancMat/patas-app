-- Criar função RPC segura para desvinculação de tags ignorando RLS do cliente
CREATE OR REPLACE FUNCTION public.deactivate_tag_safe(tag_uuid UUID, pet_uuid UUID)
RETURNS BOOLEAN AS $$
DECLARE
    is_pet_lost BOOLEAN;
BEGIN
    -- 1. Validar propriedade e integridade da tag antes de alterar qualquer dado
    SELECT is_lost INTO is_pet_lost
    FROM public.tags 
    WHERE id = tag_uuid AND pet_id = pet_uuid AND tutor_id = auth.uid();

    IF is_pet_lost IS NULL THEN
        RAISE EXCEPTION 'Tag não encontrada ou não pertence a este tutor.';
    END IF;

    -- 2. Validar se o pet está em Modo Perdido
    IF is_pet_lost = TRUE THEN
        RAISE EXCEPTION 'Não é possível desvincular a tag com o pet marcado como perdido. Desative o Modo Perdido primeiro.';
    END IF;

    -- 3. Deletar os avistamentos vinculados à tag para garantir privacidade do tutor anterior
    DELETE FROM public.sightings WHERE tag_id = tag_uuid;

    -- 4. DELETAR A ASSINATURA DO PET (Limpa automaticamente o histórico de faturas em cascata)
    DELETE FROM public.subscriptions WHERE pet_id = pet_uuid;

    -- 5. Limpar o vínculo da tag no banco de dados (o SECURITY DEFINER ignora a RLS de update)
    UPDATE public.tags 
    SET pet_id = NULL,
        tutor_id = NULL,
        activated_at = NULL,
        status = 'inactive', -- Retorna para inativa para permitir nova ativação
        is_lost = FALSE
    WHERE id = tag_uuid;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
