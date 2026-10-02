-- ============================================================
-- MIGRATION: Relacionamento Computado friendly_reviews -> tutor_profiles
-- Data: 28/07/2026
-- Execute este script no SQL Editor do Supabase
-- ============================================================

CREATE OR REPLACE FUNCTION public.tutor_profiles(friendly_reviews public.friendly_reviews)
RETURNS SETOF public.tutor_profiles
ROWS 1
LANGUAGE sql
STABLE AS $$
  SELECT * FROM public.tutor_profiles WHERE id = friendly_reviews.user_id;
$$;

-- Relacionamento Computado friendly_places -> tutor_profiles
CREATE OR REPLACE FUNCTION public.tutor_profiles(friendly_places public.friendly_places)
RETURNS SETOF public.tutor_profiles
ROWS 1
LANGUAGE sql
STABLE AS $$
  SELECT * FROM public.tutor_profiles WHERE id = friendly_places.user_id;
$$;
