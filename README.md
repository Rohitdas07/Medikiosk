# MediKiosk AI — Pre-Consultation Clinical Intake & OPD System

This contains everything you need to run your app locally.

View your app in AI Studio: https://ai.studio/apps/12fe2add-13f6-4fb1-a816-2e0903191b6d

## Run Locally

**Prerequisites:**  Node.js


1. Install dependencies:
   `npm install`
2. Set the `GEMINI_API_KEY` in [.env.local](.env.local) to your Gemini API key
3. Run the app:
   `npm run dev`

## Production deployment

This repository is prepared for a Render Node web service with Supabase and Leaflet/OpenStreetMap. See `DEPLOYMENT_READINESS_AUDIT.md` and `render.yaml`.

Before using real patient data, complete the Supabase Auth/RLS migration and remove all demo/sample clinical records from production.

### Staging patient authentication setup

The current staging build supports cross-device patient sign-in with a server-verified 4-6 digit PIN. The PIN is stored only as a salted scrypt hash in `public.patient_auth`; it is not stored in browser storage or returned to the client.

Before testing patient registration/login:
1. Run `supabase/PATIENT_AUTH_MIGRATION.sql` in the Supabase SQL Editor.
2. In Render, set the **server-only** `SUPABASE_SERVICE_ROLE_KEY` environment variable to the Supabase service-role/secret key. Never put this key in `VITE_*` variables or in GitHub.
3. Redeploy the Render service.
4. Create a **new staging patient account** after this update. Older accounts created by the previous build did not persist a PIN and therefore cannot authenticate with the new PIN flow.
5. Sign in on a second device using the same registered email + PIN. Each device gets its own browser session while both sessions resolve to the same patient ID and shared Supabase record.

Aadhaar sign-in remains demo-only in this staging build because only Aadhaar last-four digits are stored. Full UIDAI/ABHA authentication and production-grade identity verification are not implemented here.
