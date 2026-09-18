-- MediKiosk AI - Patient cross-device PIN authentication (staging)
-- Run this in Supabase SQL Editor before testing patient registration/login.
-- The raw PIN is never stored. The Express server stores a salted scrypt hash.

create table if not exists public.patient_auth (
  patient_id text primary key references public.patients(id) on delete cascade,
  pin_hash text not null,
  disabled boolean not null default false,
  created_at timestamptz not null default timezone('utc'::text, now()),
  updated_at timestamptz not null default timezone('utc'::text, now())
);

create index if not exists idx_patient_auth_patient_id
  on public.patient_auth(patient_id);

alter table public.patient_auth enable row level security;

-- No public/anon policies are created intentionally.
-- Only the server's SUPABASE_SERVICE_ROLE_KEY should read/write this table.

revoke all on table public.patient_auth from anon, authenticated;
grant all on table public.patient_auth to service_role;
