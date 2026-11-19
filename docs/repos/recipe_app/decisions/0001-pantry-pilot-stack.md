# ADR 0001 — PantryPilot static-app foundation

**Status:** Proposed — pending unanimous documentation review

## Decision

PantryPilot will use React + TypeScript + Vite, Supabase Auth/PostgreSQL/Storage, GitHub Actions, and Hostinger shared hosting for the first release.

## Context

The app needs authenticated user-owned data, recipe images, and relational pantry/recipe behavior. The current architecture targets static assets for Hostinger shared hosting; the exact Hostinger plan and its Node.js capabilities are UNKNOWN — needs human confirmation.

## Consequences

Positive: simple deployment, GitHub-friendly builds, managed authentication, PostgreSQL relationships, and no custom server to operate.

Trade-off: server-side application logic is limited. Authorization must be enforced through Supabase policies and database constraints. A future server-rendered or custom API architecture would require a Hostinger VPS or another Node-capable host.

User-uploaded images use private Supabase Storage rather than Hostinger file storage. The current contract is JPEG/PNG/WebP up to 5 MB in private `recipe-images` and `pantry-images` buckets, displayed through signed URLs. Live policy application and orphan cleanup remain UNKNOWN until verified against Supabase.

## Open follow-ups

- Confirm the exact Hostinger plan.
- Configure Google and Apple OAuth in Supabase.
- Define upload size/type limits and storage policies.
- Create development and production Supabase projects.

<!-- update-this-doc-when: package.json, supabase/migrations/*.sql, deployment and hosting decisions -->

