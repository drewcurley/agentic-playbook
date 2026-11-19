# PantryPilot Data Access and API Contract

**Status:** Section 0 baseline, reconciled to source on 2026-11-19

PantryPilot has no custom HTTP API in the shared-hosting MVP. The browser calls Supabase Auth, PostgREST/database operations, and Storage through a dedicated client module. There are no custom routes, RPCs, Edge Functions, webhooks, or external API integrations in the initial release: none planned.

## Auth operations

- Sign up with email/password
- Sign in with email/password
- Start Google OAuth
- Start Apple OAuth
- Request password reset
- Sign out
- Read the current session

OAuth configuration must include local, preview, and production redirect URLs. Exact preview and production URLs are UNKNOWN — needs human confirmation.

## Data operations

- Current source implements listing/creating/deleting recipes, creating/deleting pantry items plus quantity updates, and recipe/pantry image reads/uploads/deletes where the UI exposes them.
- Shopping-list, favorites, recipe editing/detail, and full ingredient CRUD are planned data operations, not current UI contracts.

Storage operations require an authenticated session, an exact owner-scoped path, MIME validation, and a 5 MB maximum. Buckets are private `recipe-images` and `pantry-images`; signed URLs are used for display. Live migration application and cross-user isolation remain UNKNOWN until verified against Supabase.

The storage hardening migration does not prove that the hosted Supabase project has received the policy changes.

## Validation

- Client validation provides immediate feedback.
- Database constraints and row-level security are authoritative.
- Errors must be mapped to actionable user messages without exposing credentials or internal database details.

## Future boundary

If server-side logic becomes necessary, it must be introduced as a documented service boundary rather than hidden inside UI components.

<!-- update-this-doc-when: src/lib/*.ts, src/app/*.tsx, src/types/*.ts, supabase/migrations/*.sql -->

