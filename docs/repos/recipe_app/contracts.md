# PantryPilot Contracts Inventory

**Status:** Section 0 baseline, reconciled to source on 2026-11-19

This is the exhaustive inventory for the current static application baseline. Current contracts and explicitly labeled planned operations are listed together; any new route, environment variable, integration, storage path, database object, or public data shape must be added here in the same change that introduces it.

## Client routes

| Route | Purpose | Auth |
|---|---|---|
| `/login` | Sign in, sign up, OAuth, password reset | Public |
| `/reset-password` | Complete password reset | Public |
| `/` | Authenticated recipe hub | Required |
| `/recipes/new` | Create a recipe | Required |
| `/pantry` | Manage pantry inventory | Required |
| `/shopping` | Placeholder coming-soon shopping-list screen | Required |
| `/popular` | Placeholder coming-soon popular-recipes screen | Required |
| `/profile` | Placeholder coming-soon profile/settings screen | Required |

`/recipes/new` is create-only. There is no recipe detail/edit route. Shopping-list,
favorites, recipe editing, and full profile/settings behavior are planned, not current.

## Environment variables

- `VITE_SUPABASE_URL` — required client Supabase project URL
- `VITE_SUPABASE_ANON_KEY` — required publishable Supabase key
No service-role, database-password, or OAuth client secret may be a Vite client variable.

## Auth integration

- Email/password sign-up and sign-in
- Google OAuth
- Apple OAuth
- Password-reset request and callback
- Session refresh and logout
- OAuth redirect allowlist: `http://localhost:5173`, preview URL UNKNOWN, and `https://recipe.dillonlsmith.com`
- Account linking behavior: UNKNOWN — needs human confirmation
- Signup profile data: the UI sends first name as Supabase `user_metadata.first_name`; profile-row persistence is not implemented or verified.

## Storage contract

- Provider: Supabase Storage
- Buckets: private `recipe-images` and `pantry-images`
- Path convention: `{user_id}/recipes/{recipe_id}/{uuid}.{ext}` or `{user_id}/pantry/{pantry_item_id}/{uuid}.{ext}`; the Storage policy sees three folder segments because the filename is excluded by `storage.foldername()`.
- Allowed MIME types: `image/jpeg`, `image/png`, `image/webp`
- Maximum file size: 5 MB. Image dimensions are not currently validated.
- Private images use signed URLs when displayed.
- Service-role key is never exposed to the browser or static build.
- Recipe replacement/deletion attempts to remove the previous object; failed uploads are cleaned up where implemented. Pantry images are created with an item and removed on item deletion; pantry-image replacement is not implemented. Orphan cleanup remains deferred.

## Integrations

- Supabase Auth: email/password, Google OAuth, Apple OAuth
- Supabase PostgreSQL: application data
- Supabase Storage: authenticated recipe and pantry item image files
- GitHub Actions: CI checks
- Hostinger shared hosting: static production files
- Custom API server: none planned
- Supabase RPCs/Edge Functions: none planned
- Webhooks: none planned

## Database boundary

The application depends on `profiles`, `recipes`, `recipe_ingredients`, `pantry_items`, `shopping_list_items`, and `favorites`, as described in `data-model.md`. All user-owned objects require ownership enforcement.

## Build and deployment contracts

- Vite source variables use the `VITE_` prefix.
- Production build command is `npm run build` from `recipe_app/` or `npm --prefix recipe_app run build` from the workspace root; output is `recipe_app/dist/`.
- Hostinger must serve `index.html` for client-side routes; rewrite method is UNKNOWN — needs human confirmation.
- Root `.github/workflows/recipe-app-checks.yml` runs procedure checks and the `typecheck, test, and build` job; it does not archive or deploy `dist/`.
- Hostinger upload mechanism and deployment secret inventory are UNKNOWN — needs human confirmation.

## Contract change rule

Any change to this inventory requires a documented compatibility assessment, relevant tests, and updates to the related data-model, API, UX, or deployment documentation in the same change.

<!-- update-this-doc-when: src/App.tsx, src/lib/*.ts, src/types/*.ts, .env.example, supabase/migrations/*.sql, .github/workflows/recipe-app-checks.yml -->

