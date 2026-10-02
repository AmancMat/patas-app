-- ============================================================
-- MIGRATION: Corrigir relacionamentos tutor_profiles e view segura
-- Execute este script no SQL Editor do Supabase
-- ============================================================

-- 1. Alterar a view tutor_profiles para rodar com privilégios do definer (bypassing users RLS)
-- Isso expõe de forma segura apenas os campos públicos de todos os usuários
CREATE OR REPLACE VIEW public.tutor_profiles AS
SELECT 
  id,
  name,
  photo_url,
  interests,
  role
FROM public.users;

-- 2. Criar relacionamento computado de posts -> tutor_profiles no PostgREST
CREATE OR REPLACE FUNCTION public.tutor_profiles(posts public.posts)
RETURNS SETOF public.tutor_profiles
ROWS 1
LANGUAGE sql
STABLE AS $$
  SELECT * FROM public.tutor_profiles WHERE id = posts.user_id;
$$;

-- 3. Criar relacionamento computado de stories -> tutor_profiles no PostgREST
CREATE OR REPLACE FUNCTION public.tutor_profiles(stories public.stories)
RETURNS SETOF public.tutor_profiles
ROWS 1
LANGUAGE sql
STABLE AS $$
  SELECT * FROM public.tutor_profiles WHERE id = stories.user_id;
$$;

-- 4. Criar relacionamento computado de comments -> tutor_profiles no PostgREST
CREATE OR REPLACE FUNCTION public.tutor_profiles(comments public.comments)
RETURNS SETOF public.tutor_profiles
ROWS 1
LANGUAGE sql
STABLE AS $$
  SELECT * FROM public.tutor_profiles WHERE id = comments.user_id;
$$;
