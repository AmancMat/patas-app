-- ============================================================
-- MIGRATION: Configurações de Agenda no Perfil Veterinário
-- Data: 28/07/2026
-- Execute este script no SQL Editor do Supabase para atualizar a tabela
-- ============================================================

ALTER TABLE public.vet_profiles 
ADD COLUMN IF NOT EXISTS consultation_duration_minutes INT DEFAULT 30,
ADD COLUMN IF NOT EXISTS max_appointments_per_slot INT DEFAULT 1,
ADD COLUMN IF NOT EXISTS cancellation_limit_hours INT DEFAULT 24;

-- Atualiza registros existentes para terem valores padrão preenchidos
UPDATE public.vet_profiles 
SET 
  consultation_duration_minutes = COALESCE(consultation_duration_minutes, 30),
  max_appointments_per_slot = COALESCE(max_appointments_per_slot, 1),
  cancellation_limit_hours = COALESCE(cancellation_limit_hours, 24);
