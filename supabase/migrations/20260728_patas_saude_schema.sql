-- ============================================================
-- MIGRATION: Schema Completo para o Ecossistema Patas Saúde
-- Data: 28/07/2026
-- Execute este script no SQL Editor do Supabase
-- ============================================================

-- 1. Tabela de Perfis Profissionais (Veterinários & Clínicas)
CREATE TABLE IF NOT EXISTS public.vet_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  crmv_number TEXT NOT NULL,
  crmv_uf VARCHAR(2) NOT NULL,
  clinic_name TEXT,
  full_name TEXT NOT NULL,
  type VARCHAR(20) DEFAULT 'veterinarian', -- 'veterinarian', 'clinic', 'hospital_24h'
  bio TEXT,
  specialties TEXT[] DEFAULT '{}',
  phone TEXT,
  address TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  photo_url TEXT,
  accepts_home_visit BOOLEAN DEFAULT false,
  accepts_clinic_visit BOOLEAN DEFAULT true,
  consultation_price NUMERIC(10,2) DEFAULT 0.00,
  validation_status VARCHAR(20) DEFAULT 'approved', -- 'pending', 'approved', 'rejected'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Tabela de Horários e Slots de Atendimento dos Veterinários
CREATE TABLE IF NOT EXISTS public.vet_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vet_id UUID REFERENCES public.vet_profiles(id) ON DELETE CASCADE,
  day_of_week INT NOT NULL, -- 1=Segunda, 7=Domingo
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  slot_duration_minutes INT DEFAULT 30,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Tabela de Agendamentos de Consultas (Tutor <-> Profissional)
CREATE TABLE IF NOT EXISTS public.health_appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tutor_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  pet_id UUID REFERENCES public.pets(id) ON DELETE CASCADE,
  vet_id UUID REFERENCES public.vet_profiles(id) ON DELETE CASCADE,
  appointment_date DATE NOT NULL,
  appointment_time TIME NOT NULL,
  modality VARCHAR(20) DEFAULT 'clinic', -- 'clinic', 'home'
  status VARCHAR(20) DEFAULT 'confirmed', -- 'pending', 'confirmed', 'in_progress', 'completed', 'cancelled'
  notes TEXT,
  total_price NUMERIC(10,2) DEFAULT 0.00,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Tabela de Prontuários Eletrônicos Veterinários (Padrão SOAP)
CREATE TABLE IF NOT EXISTS public.medical_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id UUID REFERENCES public.health_appointments(id) ON DELETE SET NULL,
  pet_id UUID REFERENCES public.pets(id) ON DELETE CASCADE,
  vet_id UUID REFERENCES public.vet_profiles(id) ON DELETE CASCADE,
  anamnesis_subjective TEXT, -- S: Anamnese e queixas do tutor
  vital_signs_objective JSONB DEFAULT '{}'::jsonb, -- O: Temp, FC, FR, TPC, Peso kg
  diagnosis_assessment TEXT, -- A: Diagnóstico presuntivo / definitivo
  treatment_plan TEXT, -- P: Conduta e orientações
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Tabela de Receitas Médicas Digitais com Calculadora & Posologia
CREATE TABLE IF NOT EXISTS public.prescriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  medical_record_id UUID REFERENCES public.medical_records(id) ON DELETE CASCADE,
  pet_id UUID REFERENCES public.pets(id) ON DELETE CASCADE,
  vet_id UUID REFERENCES public.vet_profiles(id) ON DELETE CASCADE,
  medications JSONB DEFAULT '[]'::jsonb, -- Array de {name, dosage_mg, frequency, duration_days, instructions}
  general_instructions TEXT,
  qr_code_hash TEXT UNIQUE,
  pdf_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Tabela de Pedidos de Exames e Laudos
CREATE TABLE IF NOT EXISTS public.exam_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  medical_record_id UUID REFERENCES public.medical_records(id) ON DELETE CASCADE,
  pet_id UUID REFERENCES public.pets(id) ON DELETE CASCADE,
  vet_id UUID REFERENCES public.vet_profiles(id) ON DELETE CASCADE,
  exam_type TEXT NOT NULL, -- Ex: 'Hemograma Completo', 'Ultrassom Abdominal', 'Raio-X'
  observations TEXT,
  status VARCHAR(20) DEFAULT 'requested', -- 'requested', 'completed'
  report_pdf_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Habilitar RLS nas novas tabelas
ALTER TABLE public.vet_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vet_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.health_appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medical_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prescriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exam_requests ENABLE ROW LEVEL SECURITY;

-- Políticas RLS Permissivas para Leitura e Inserção
CREATE POLICY "Leitura pública de vet_profiles" ON public.vet_profiles FOR SELECT USING (true);
CREATE POLICY "Escrita pelo dono de vet_profiles" ON public.vet_profiles FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Leitura pública de vet_schedules" ON public.vet_schedules FOR SELECT USING (true);
CREATE POLICY "Escrita pelo dono de vet_schedules" ON public.vet_schedules FOR ALL USING (true);

CREATE POLICY "Acesso a agendamentos" ON public.health_appointments FOR ALL USING (true);
CREATE POLICY "Acesso a prontuarios" ON public.medical_records FOR ALL USING (true);
CREATE POLICY "Acesso a receitas" ON public.prescriptions FOR ALL USING (true);
CREATE POLICY "Acesso a exames" ON public.exam_requests FOR ALL USING (true);
