-- 0. Remover tabelas antigas se existirem (para garantir recriação com estrutura correta)
DROP TABLE IF EXISTS public.invoices CASCADE;
DROP TABLE IF EXISTS public.subscriptions CASCADE;
DROP TABLE IF EXISTS public.subscription_plans CASCADE;

-- 1. Criar enums de status se não existirem
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'subscription_status') THEN
        CREATE TYPE subscription_status AS ENUM ('trial', 'active', 'grace_period', 'past_due', 'canceled');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'invoice_status') THEN
        CREATE TYPE invoice_status AS ENUM ('pending', 'paid', 'expired', 'failed');
    END IF;
END$$;

-- 2. Tabela de Planos de Assinatura
CREATE TABLE IF NOT EXISTS public.subscription_plans (
    id VARCHAR(100) PRIMARY KEY, -- Ex: 'plan-mensal-patas-encontra', 'plan-anual-patas-encontra'
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price_in_cents INT NOT NULL, -- R$ 9,90 = 990
    billing_interval VARCHAR(20) DEFAULT 'month',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Inserir planos padrão se não existirem
INSERT INTO public.subscription_plans (id, name, description, price_in_cents, billing_interval, is_active)
VALUES 
    ('plan-mensal-patas-encontra', 'Mensal', 'Cobrado mensalmente', 599, 'month', true),
    ('plan-anual-patas-encontra', 'Anual', 'Cobrado anualmente', 6469, 'year', true)
ON CONFLICT (id) DO NOTHING;

-- 4. Tabela de Assinaturas de Usuários (com Trial de 14 dias e Tolerância de 7 dias)
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    plan_id VARCHAR(100) REFERENCES public.subscription_plans(id) NOT NULL,
    status subscription_status DEFAULT 'trial',
    trial_started_at TIMESTAMPTZ DEFAULT NOW(),
    trial_ends_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '14 days'),
    current_period_start TIMESTAMPTZ,
    current_period_end TIMESTAMPTZ,
    grace_period_ends_at TIMESTAMPTZ,
    gateway_subscription_id VARCHAR(255) UNIQUE,
    gateway_customer_id VARCHAR(255),
    trial_notification_sent BOOLEAN DEFAULT false,
    grace_notification_sent BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Tabela de Faturas / Cobranças do PIX (com rastreamento de vigência da cobertura)
CREATE TABLE IF NOT EXISTS public.invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subscription_id UUID REFERENCES public.subscriptions(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    amount_in_cents INT NOT NULL,
    status invoice_status DEFAULT 'pending',
    pix_copia_cola TEXT,
    pix_qr_code_url TEXT,
    gateway_charge_id VARCHAR(255) UNIQUE,
    pix_txid VARCHAR(255),
    paid_at TIMESTAMPTZ,
    due_date TIMESTAMPTZ NOT NULL,
    period_start TIMESTAMPTZ, -- Início da cobertura do serviço correspondente
    period_end TIMESTAMPTZ,   -- Fim da cobertura do serviço correspondente
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Habilitar RLS
ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;

-- 7. Criar políticas RLS (removendo se existirem)

-- Políticas de Planos
DROP POLICY IF EXISTS "Leitura de planos ativos" ON public.subscription_plans;
CREATE POLICY "Leitura de planos ativos" ON public.subscription_plans
    FOR SELECT USING (is_active = true);

-- Políticas de Assinaturas (Leitura, Inserção, Atualização, Exclusão para donos)
DROP POLICY IF EXISTS "Usuários leem suas assinaturas" ON public.subscriptions;
CREATE POLICY "Usuários leem suas assinaturas" ON public.subscriptions
    FOR SELECT TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuários criam suas assinaturas" ON public.subscriptions;
CREATE POLICY "Usuários criam suas assinaturas" ON public.subscriptions
    FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuários atualizam suas assinaturas" ON public.subscriptions;
CREATE POLICY "Usuários atualizam suas assinaturas" ON public.subscriptions
    FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuários deletam suas assinaturas" ON public.subscriptions;
CREATE POLICY "Usuários deletam suas assinaturas" ON public.subscriptions
    FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- Políticas de Faturas (Leitura, Inserção, Atualização, Exclusão para donos)
DROP POLICY IF EXISTS "Usuários leem suas faturas" ON public.invoices;
CREATE POLICY "Usuários leem suas faturas" ON public.invoices
    FOR SELECT TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuários criam suas faturas" ON public.invoices;
CREATE POLICY "Usuários criam suas faturas" ON public.invoices
    FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuários atualizam suas faturas" ON public.invoices;
CREATE POLICY "Usuários atualizam suas faturas" ON public.invoices
    FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuários deletam suas faturas" ON public.invoices;
CREATE POLICY "Usuários deletam suas faturas" ON public.invoices
    FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- 8. Criar índices para otimização de consultas financeiras
CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON public.subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_invoices_subscription ON public.invoices(subscription_id);
CREATE INDEX IF NOT EXISTS idx_invoices_user ON public.invoices(user_id);

-- 9. Trigger para impedir avistamentos se a assinatura estiver atrasada/suspensa (Independente de autenticação)
CREATE OR REPLACE FUNCTION public.check_sighting_subscription()
RETURNS TRIGGER AS $$
DECLARE
    tutor_sub_status VARCHAR(50);
BEGIN
    -- Buscar o status da assinatura do tutor da tag
    SELECT s.status INTO tutor_sub_status
    FROM public.tags t
    LEFT JOIN public.subscriptions s ON s.user_id = t.tutor_id
    WHERE t.id = NEW.tag_id;

    -- Se a assinatura estiver em past_due, canceled ou inactive, bloqueia a inserção do avistamento
    IF tutor_sub_status IN ('past_due', 'canceled', 'inactive') THEN
        RAISE EXCEPTION 'O serviço de localização para esta tag está suspenso.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_check_sighting_subscription ON public.sightings;
CREATE TRIGGER trg_check_sighting_subscription
    BEFORE INSERT ON public.sightings
    FOR EACH ROW
    EXECUTE FUNCTION public.check_sighting_subscription();

-- 10. Função para gerenciar suspensões e tolerâncias de assinaturas diariamente
CREATE OR REPLACE FUNCTION public.check_expired_subscriptions()
RETURNS void AS $$
BEGIN
    -- Bloquear assinaturas onde a tolerância ou o Trial expirou
    UPDATE public.subscriptions
    SET status = 'past_due', updated_at = NOW()
    WHERE status IN ('active', 'grace_period', 'trial')
      AND (
        (status = 'trial' AND trial_ends_at < NOW()) OR
        (status = 'grace_period' AND grace_period_ends_at < NOW()) OR
        (status = 'active' AND current_period_end < NOW() - INTERVAL '7 days')
      );
      
    -- Mover assinaturas ativas vencidas para tolerância (grace_period) se o novo pagamento não caiu
    UPDATE public.subscriptions
    SET status = 'grace_period', updated_at = NOW(), grace_period_ends_at = current_period_end + INTERVAL '7 days'
    WHERE status = 'active'
      AND current_period_end < NOW()
      AND current_period_end >= NOW() - INTERVAL '7 days';
END;
$$ LANGUAGE plpgsql;
