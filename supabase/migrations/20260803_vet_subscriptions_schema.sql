-- ============================================================
-- MIGRATION: Assinaturas e Planos B2B para a Área Veterinária (Patas Saúde)
-- Data: 03/08/2026
-- Execute este script no SQL Editor do Supabase
-- ============================================================

-- 1. Tabela de Planos B2B para Veterinários/Clínicas
CREATE TABLE IF NOT EXISTS public.vet_plans (
  id VARCHAR(100) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  price NUMERIC(10,2) NOT NULL,
  billing_cycle VARCHAR(20) DEFAULT 'monthly', -- 'monthly', 'annual'
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed de Planos B2B Padrão
INSERT INTO public.vet_plans (id, name, description, price, billing_cycle)
VALUES
  ('vet-plan-mensal', 'Plano Pro Mensal', 'Perfil em destaque no mapa de busca, prontuário SOAP ilimitado e agendamento online.', 89.90, 'monthly'),
  ('vet-plan-anual', 'Plano Pro Anual', 'Perfil em destaque no mapa de busca, prontuário SOAP ilimitado e agendamento online com 2 meses grátis.', 899.00, 'annual')
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  price = EXCLUDED.price,
  billing_cycle = EXCLUDED.billing_cycle;

-- 2. Tabela de Assinaturas B2B dos Veterinários
CREATE TABLE IF NOT EXISTS public.vet_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vet_id UUID REFERENCES public.vet_profiles(id) ON DELETE CASCADE UNIQUE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  plan_id VARCHAR(100) REFERENCES public.vet_plans(id),
  status VARCHAR(20) DEFAULT 'trial', -- 'trial', 'active', 'grace_period', 'past_due', 'canceled'
  current_period_start TIMESTAMPTZ DEFAULT NOW(),
  current_period_end TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '14 days'),
  trial_ends_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '14 days'),
  asaas_customer_id TEXT,
  asaas_subscription_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Tabela de Faturas B2B dos Veterinários
CREATE TABLE IF NOT EXISTS public.vet_invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subscription_id UUID REFERENCES public.vet_subscriptions(id) ON DELETE CASCADE,
  vet_id UUID REFERENCES public.vet_profiles(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  amount NUMERIC(10,2) NOT NULL,
  status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'paid', 'overdue', 'canceled'
  due_date TIMESTAMPTZ,
  paid_at TIMESTAMPTZ,
  pix_qr_code TEXT,
  pix_copy_paste TEXT,
  asaas_payment_id TEXT,
  pdf_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Habilitar RLS nas tabelas
ALTER TABLE public.vet_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vet_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vet_invoices ENABLE ROW LEVEL SECURITY;

-- Políticas RLS
CREATE POLICY "Leitura pública de vet_plans" ON public.vet_plans FOR SELECT USING (true);

CREATE POLICY "Leitura de vet_subscriptions" ON public.vet_subscriptions FOR SELECT USING (true);
CREATE POLICY "Gerenciamento de vet_subscriptions pelo profissional" ON public.vet_subscriptions FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Leitura de vet_invoices pelo dono" ON public.vet_invoices FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Gerenciamento de vet_invoices pelo dono" ON public.vet_invoices FOR ALL USING (auth.uid() = user_id);

-- 4. Função helper para verificar adimplência do veterinário
CREATE OR REPLACE FUNCTION public.check_vet_is_adimplente(p_vet_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_status VARCHAR(20);
  v_end TIMESTAMPTZ;
BEGIN
  SELECT status, current_period_end INTO v_status, v_end
  FROM public.vet_subscriptions
  WHERE vet_id = p_vet_id;

  IF v_status IS NULL THEN
    RETURN EXISTS (
      SELECT 1 FROM public.vet_profiles
      WHERE id = p_vet_id AND created_at >= (NOW() - INTERVAL '14 days')
    );
  END IF;

  IF v_status IN ('trial', 'active', 'grace_period') THEN
    RETURN true;
  ELSE
    RETURN false;
  END IF;
END;
$$;
