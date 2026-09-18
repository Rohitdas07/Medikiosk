# MediKiosk AI — Deployment Readiness Audit

Audit target: `MediKiosk-v.1.zip` (uploaded 17 Sep 2026)

## Executive result

The application is structurally deployable as a single Node/Express + Vite service on Render, with Supabase as the data platform and Leaflet + OpenStreetMap for the core mapping experience.

**Current status: NOT YET SAFE FOR REAL PATIENT DATA.**

The deployment preparation in this package addresses hosting configuration, Render compatibility, OSM configurability, health checks, removal of hardcoded Supabase publishable-key fallbacks, and the most obvious admin-token weakness. It does **not** claim that the existing custom authentication/data-access model is a finished healthcare production security architecture.

## Readiness matrix

| Area | Status | Finding |
|---|---|---|
| React/Vite frontend | READY | Existing Vite build structure is suitable. |
| Express backend | READY WITH FIXES | Uses one server entry point and can serve Vite production output. PORT is now environment-driven. |
| Render | READY WITH CONFIG | `render.yaml` and `/health` are included. |
| Supabase URL/key configuration | READY WITH CONFIG | Hardcoded frontend/server publishable-key fallback removed. |
| Supabase RLS | BLOCKER | Existing schema contains permissive `USING (true)` / `WITH CHECK (true)` policies. These must not protect real patient records. |
| Authentication | BLOCKER | Application uses custom browser sessions and custom PIN authentication rather than a complete Supabase Auth/JWT authorization model. |
| Admin authorization | IMPROVED / VERIFY | Legacy prefix/fallback token acceptance was removed; admin API now requires a server-side active session token. |
| Staff credentials | BLOCKER | Source contains demo staff records/PIN hashes. Demo staff is now disabled unless `ENABLE_DEMO_STAFF=true`, but production provisioning still needs to be completed in Supabase. |
| Patient data storage | BLOCKER | Some application state uses browser/localStorage and sample data. Real clinical records should be server/database-backed and patient-scoped. |
| OCR | CONDITIONALLY READY | Gemini + Tesseract fallback architecture exists. Production testing is required with real image sizes, timeouts and quota failures. |
| Gemini | READY WITH CONFIG | `GEMINI_API_KEY` is server-side; production secret must be supplied in Render. |
| Leaflet | READY | Existing Leaflet components are retained. |
| OpenStreetMap tiles | READY WITH POLICY COMPLIANCE | Tile URL is configurable and defaults to the official HTTPS tile endpoint with attribution. OSM usage remains subject to its tile policy. |
| Nominatim | CONDITIONALLY READY | Server-side and configurable, but public Nominatim is rate-limited/best-effort. Use caching and move to a dedicated provider/self-hosted service as usage grows. |
| Routing | CONDITIONALLY READY | OSRM/OpenStreetMap-based routing has primary + mirror fallbacks. It should be treated as best-effort until production load is known. |
| Custom domain/HTTPS | READY | Render supports custom domains and TLS. |
| Persistent local files | BLOCKER | `data/hospital_staff_store.json` is local filesystem state; hosted instances should use Supabase instead. |
| Multi-instance scaling | BLOCKER | In-memory stores and session sets do not scale across instances. |
| Production observability | NEEDS WORK | Add structured logs, error monitoring, request IDs, and alerting before real clinical use. |

## High-risk findings that remain

### 1. Supabase policies are too permissive

The embedded SQL currently creates policies equivalent to public full CRUD on clinical tables. RLS being enabled is not sufficient if the policy allows everyone. The production model should use least-privilege policies tied to authenticated users/roles.

Supabase's production guidance recommends RLS on every exposed table and notes that grants and policies both matter. See the official Supabase production checklist and RLS documentation.

### 2. Custom authentication is not equivalent to Supabase Auth

The application currently creates its own session tokens in the Express process and stores a simplified session object in browser `sessionStorage`. These tokens are not Supabase JWTs and do not automatically establish database-level identity for direct Supabase calls.

A proper production architecture should choose one of these patterns:

- **Preferred:** Supabase Auth for patient/staff identities + JWT/RLS for direct database access.
- **Alternative:** browser talks only to the Express API; Express verifies the user's identity and uses a server-only Supabase secret/service-role credential for database operations.

Do not mix an untrusted browser identity with unrestricted database policies.

### 3. Demo staff data

The source contains seeded staff identities and PIN hashes. The deployment package now defaults `ENABLE_DEMO_STAFF=false`, so those demo records are not loaded unless explicitly enabled. Production staff must be provisioned from a controlled database/admin workflow.

### 4. Local JSON and in-memory state

The server currently maintains hospital staff, appointments and related operational state in memory and/or local JSON. This is not durable storage for a hosted clinical system. Render deployments can restart/redeploy, and multiple instances do not share process memory.

### 5. Browser localStorage

Kiosk/session persistence currently uses browser storage. That is acceptable for temporary UI state, but it must not be treated as the authoritative clinical record.

## Mapping architecture prepared in this package

Core maps now use:

- Leaflet for rendering
- `https://tile.openstreetmap.org/{z}/{x}/{y}.png` as the default tile endpoint
- OpenStreetMap attribution
- Configurable Nominatim endpoint for geocoding/facility discovery
- Configurable OSRM/OpenStreetMap routing endpoints

The OSM tile policy requires the official HTTPS tile URL, visible attribution, appropriate caching, and prohibits bulk tile downloading. OSMF services are best-effort and can be blocked for abusive/heavy usage.

## Render configuration prepared

`render.yaml` configures:

- Node web service
- `npm install --no-audit --no-fund && npm run build`
- `npm start`
- `/health` health check
- production environment variables
- OSM endpoint configuration
- disabled demo staff by default

## Deployment sequence

1. Create/confirm the production Supabase project.
2. Apply the final schema and RLS migration **after** the authentication/data-access model is finalized.
3. Configure Render secrets: Gemini, Supabase, HIS admin bootstrap credentials, and OSM contact/user-agent.
4. Connect the Git repository to Render.
5. Deploy and verify `/health`.
6. Test patient authentication and patient-only data access.
7. Test staff/doctor/nurse/admin role boundaries.
8. Test prescription OCR with representative image sizes.
9. Test Leaflet maps, hospital discovery, geocoding and routing.
10. Test appointment, prescription, history and doctor-console workflows end-to-end.
11. Only then connect a real custom domain and real patient data.

## Verification note

A dependency installation/build verification was attempted in the audit environment, but package installation exceeded the available execution window. Therefore this audit does **not** claim a successful production build from this environment. Run `npm install` followed by `npm run lint` and `npm run build` locally or in Render before deployment.
