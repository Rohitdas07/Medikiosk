-- MediKiosk patient identity migration
-- Matches existing public.patients.id type: TEXT
ALTER TABLE public.patients
  ADD COLUMN IF NOT EXISTS aadhaar_last4 TEXT,
  ADD COLUMN IF NOT EXISTS aadhaar_verification_status TEXT DEFAULT 'not_verified',
  ADD COLUMN IF NOT EXISTS aadhaar_verification_ref TEXT,
  ADD COLUMN IF NOT EXISTS consent_given BOOLEAN DEFAULT FALSE;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'patients_aadhaar_status_check'
  ) THEN
    ALTER TABLE public.patients
      ADD CONSTRAINT patients_aadhaar_status_check
      CHECK (aadhaar_verification_status IN ('not_verified','demo_verified','verified'));
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.aadhaar_verification_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id TEXT NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
  verification_mode TEXT NOT NULL DEFAULT 'demo',
  status TEXT NOT NULL DEFAULT 'not_verified',
  verification_ref TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.aadhaar_verification_logs ENABLE ROW LEVEL SECURITY;
CREATE INDEX IF NOT EXISTS idx_aadhaar_logs_patient_id
  ON public.aadhaar_verification_logs(patient_id);

-- No unique email index is created because existing data contains duplicate emails.
-- This is demo verification only; do not store full Aadhaar numbers.


-- Require ABHA IDs to be exactly 14 digits when supplied.
-- Run only after correcting any existing invalid ABHA values.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'patients_abha_id_14_digits_check'
  ) THEN
    ALTER TABLE public.patients
      ADD CONSTRAINT patients_abha_id_14_digits_check
      CHECK (abha_id IS NULL OR abha_id ~ '^[0-9]{14}$');
  END IF;
END $$;
