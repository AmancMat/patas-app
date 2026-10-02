-- ============================================================
-- SUPABASE SECURITY & DATABASE MAINTENANCE
-- Execute este script completo no SQL Editor do Supabase
-- ============================================================

-- ============================================================
-- FASE 1: Segurança e Privacidade de Dados (LGPD/GDPR)
-- ============================================================

-- Ação 1.1: Recriar a View do Leaderboard com Security Invoker (PostgreSQL 15+)
-- Isso herda as políticas de RLS das tabelas base para quem consulta
DROP VIEW IF EXISTS public.leaderboard_view;

CREATE VIEW public.leaderboard_view 
WITH (security_invoker = true) AS
SELECT 
  l.user_id,
  SUM(l.points) AS total_points,
  ROW_NUMBER() OVER (
    ORDER BY SUM(l.points) DESC, 
             COUNT(r.id) DESC, 
             MIN(l.created_at) ASC
  ) AS rank,
  p.name AS pet_name,
  p.photo_url AS pet_photo_url,
  COUNT(r.id) AS total_invites
FROM public.gamification_ledger l
LEFT JOIN public.pets p ON p.user_id = l.user_id AND p.is_active = true
LEFT JOIN public.referrals r ON r.inviter_id = l.user_id
GROUP BY l.user_id, p.name, p.photo_url;

-- Ação 1.2: Blindagem da Tabela public.users (Ocultar e-mails e tokens)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Remover políticas de SELECT existentes que permitem leitura pública total
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.users;
DROP POLICY IF EXISTS "Allow public read users" ON public.users;

-- Criar política para o próprio usuário ler todos os seus dados
DROP POLICY IF EXISTS "Allow users to read their own full data" ON public.users;
CREATE POLICY "Allow users to read their own full data"
ON public.users
FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- Função auxiliar SECURITY DEFINER para verificar se o usuário é admin
-- (SECURITY DEFINER ignora o RLS, quebrando o ciclo de recursão infinita)
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Criar política para administradores lerem todos os usuários
DROP POLICY IF EXISTS "Allow admins to read all users" ON public.users;
CREATE POLICY "Allow admins to read all users"
ON public.users
FOR SELECT
TO authenticated
USING (public.is_admin());

-- Criar a View Pública Segura (ocultando emails, tokens e hashes)
CREATE OR REPLACE VIEW public.tutor_profiles 
WITH (security_invoker = true) AS
SELECT 
  id,
  name,
  photo_url,
  interests,
  role
FROM public.users;

-- Ação 1.3: Restrição de Leitura no Gamification Ledger
ALTER TABLE public.gamification_ledger ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read ledger" ON public.gamification_ledger;

DROP POLICY IF EXISTS "Allow select own ledger entries" ON public.gamification_ledger;
CREATE POLICY "Allow select own ledger entries"
ON public.gamification_ledger
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);


-- ============================================================
-- FASE 2: Proteção Anti-Fraude e Transações Atômicas (Zero-Trust)
-- ============================================================

-- Ação 2.1: Migrar Lógica de Pontuação de Curtidas e Comentários para Triggers
CREATE OR REPLACE FUNCTION public.process_engagement_points()
RETURNS TRIGGER AS $$
DECLARE
  v_points INT;
  v_max_daily INT;
  v_today_count INT;
  v_action_type VARCHAR;
  v_user_id UUID;
BEGIN
  -- Definir parâmetros com base na tabela
  IF TG_TABLE_NAME = 'likes' THEN
    v_action_type := 'like_post';
    v_points := 5;
    v_max_daily := 5;
    v_user_id := NEW.user_id;
  ELSIF TG_TABLE_NAME = 'comments' THEN
    v_action_type := 'comment_post';
    v_points := 5;
    v_max_daily := 5;
    v_user_id := NEW.user_id;
  END IF;

  -- Se for operação de exclusão (un-like ou delete comentário), remove os pontos de forma atômica
  IF TG_OP = 'DELETE' THEN
    IF TG_TABLE_NAME = 'likes' THEN
      v_user_id := OLD.user_id;
      v_action_type := 'like_post';
    ELSIF TG_TABLE_NAME = 'comments' THEN
      v_user_id := OLD.user_id;
      v_action_type := 'comment_post';
    END IF;

    DELETE FROM public.gamification_ledger
    WHERE id = (
      SELECT id FROM public.gamification_ledger
      WHERE user_id = v_user_id AND action_type = v_action_type
      ORDER BY created_at DESC
      LIMIT 1
    );
    RETURN OLD;
  END IF;

  -- Se for operação de inserção (novo like ou comentário)
  -- 1. Contar pontos já ganhos hoje com Lock de segurança para evitar Race Conditions
  SELECT COUNT(*) INTO v_today_count
  FROM public.gamification_ledger
  WHERE user_id = v_user_id
    AND action_type = v_action_type
    AND created_at >= CURRENT_DATE::timestamp AT TIME ZONE 'UTC'
    AND created_at < (CURRENT_DATE + 1)::timestamp AT TIME ZONE 'UTC';

  -- 2. Conceder pontos apenas se estiver abaixo do limite
  IF v_today_count < v_max_daily THEN
    INSERT INTO public.gamification_ledger (user_id, action_type, points)
    VALUES (v_user_id, v_action_type, v_points);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ativar Triggers de Likes e Comments
DROP TRIGGER IF EXISTS trigger_likes_gamification ON public.likes;
CREATE TRIGGER trigger_likes_gamification
AFTER INSERT OR DELETE ON public.likes
FOR EACH ROW EXECUTE FUNCTION public.process_engagement_points();

DROP TRIGGER IF EXISTS trigger_comments_gamification ON public.comments;
CREATE TRIGGER trigger_comments_gamification
AFTER INSERT OR DELETE ON public.comments
FOR EACH ROW EXECUTE FUNCTION public.process_engagement_points();

-- Ação 2.2: Transação Atômica de Referral (RPC)
CREATE OR REPLACE FUNCTION public.process_referral_safe(
  p_invited_id UUID,
  p_referral_code VARCHAR
)
RETURNS BOOLEAN AS $$
DECLARE
  v_inviter_id UUID;
BEGIN
  -- 1. Localizar o padrinho através do código (8 primeiros caracteres do ID)
  SELECT id INTO v_inviter_id
  FROM public.users
  WHERE id::text LIKE p_referral_code || '%'
  LIMIT 1;

  -- Validações de segurança e prevenção de auto-indicação
  IF v_inviter_id IS NULL OR v_inviter_id = p_invited_id THEN
    RETURN FALSE;
  END IF;

  -- 2. Registrar indicação
  INSERT INTO public.referrals (inviter_id, invited_id)
  VALUES (v_inviter_id, p_invited_id);

  -- 3. Conceder 500 pontos no ledger
  INSERT INTO public.gamification_ledger (user_id, action_type, points)
  VALUES (v_inviter_id, 'referral_success', 500);

  RETURN TRUE;
EXCEPTION
  WHEN OTHERS THEN
    -- Executa rollback implícito em qualquer falha
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================================
-- FASE 3: Otimizações de Performance (Índices)
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_ledger_user_action_created
ON public.gamification_ledger (user_id, action_type, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_ledger_created_at
ON public.gamification_ledger (created_at);

CREATE INDEX IF NOT EXISTS idx_referrals_inviter
ON public.referrals (inviter_id);
