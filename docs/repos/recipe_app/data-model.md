# PantryPilot Data Model

**Status:** Section 0 baseline, reconciled to migrations on 2026-11-19

## Ownership rule

User-owned tables carry `user_id`; `recipe_ingredients` is owned through its parent recipe. Row-level security allows access only to the authenticated user. The database, not client filtering, is the security boundary.

## Implemented tables

### `profiles` (implemented)

- `id` — UUID, references the auth user
- `display_name` — optional profile text populated from signup `user_metadata.first_name` by the `handle_new_user_profile` database trigger
- `created_at`, `updated_at` — timestamps
- RLS permits select/insert/update for the owner; there is no profile delete policy.

PII: `display_name` is user-provided profile data. Authentication email remains owned by `auth.users` and is not duplicated as a password or credential.

### `recipes` (implemented)

- `id` — UUID primary key
- `user_id` — UUID owner
- `title` — required text
- `description` — optional text
- `instructions` — required text
- `prep_minutes`, `cook_minutes` — optional non-negative integers
- `servings` — optional positive integer
- `difficulty` — controlled value: easy, medium, hard
- `image_path` — optional Supabase Storage path
- `created_at`, `updated_at` — timestamps

Constraints: non-negative times, positive servings, owner-only access. Indexes: `(user_id, updated_at)` and `(user_id, title)`.

### `recipe_ingredients` (implemented)

- `id` — UUID primary key
- `recipe_id` — recipe reference
- `name` — required text; the database trims only for non-empty validation
- `quantity` — optional numeric value
- `unit` — optional text
- `notes` — optional text
- `position` — ordering integer
- `created_at`, `updated_at` — timestamps

Constraints: foreign key to `recipes`, unique `(recipe_id, position)`, index on `recipe_id`.

### `pantry_items` (implemented)

- `id` — UUID primary key
- `user_id` — UUID owner
- `name` — required text; the database trims only for non-empty validation
- `quantity` — numeric value
- `unit` — required text
- `category` — optional free-form text
- `low_stock_threshold` — optional numeric value
- `expires_on` — optional date
- `image_path` — optional private Supabase Storage path
- `created_at`, `updated_at` — timestamps

Constraints: non-negative quantity and threshold, index `(user_id, name)`, index `(user_id, expires_on)`.

### `shopping_list_items` (implemented)

- `id` — UUID primary key
- `user_id` — UUID owner
- `name` — required text; the database trims only for non-empty validation
- `quantity` — optional numeric value
- `unit` — optional text
- `source_recipe_id` — optional recipe reference
- `is_completed` — boolean
- `created_at`, `updated_at` — timestamps

Constraints: index `(user_id, is_completed, created_at)`, `source_recipe_id` foreign key with `ON DELETE SET NULL`; RLS requires the source recipe, when present, to belong to the same user.

### `favorites` (implemented)

- `user_id` — UUID owner
- `recipe_id` — recipe reference
- `created_at` — timestamp
- composite primary key on user and recipe

## Image metadata

Recipe images are not stored as raw blobs in PostgreSQL. `recipes.image_path` references a private Storage object. If image metadata grows beyond the recipe row, a future `recipe_images` table may hold `id`, `recipe_id`, `user_id`, `storage_path`, `original_filename`, `mime_type`, `byte_size`, `width`, `height`, `alt_text`, and timestamps. That table is not part of the initial schema until upload requirements are finalized.

## RLS invariants

- Policies deny access by default.
- A user may select/insert/update/delete only rows whose `user_id` equals the authenticated Supabase user ID.
- Recipe ingredients are accessible only through recipes owned by the current user; they do not have their own `user_id`.
- Favorites are writable only for the current user and recipes visible to that user.
- Storage objects must use an owner-scoped path and matching Storage policies.

## Deletion and retention

Database rows cascade from `auth.users` through profiles, recipes, pantry items, shopping items, favorites, and recipe ingredients; deleting a recipe sets shopping-list `source_recipe_id` to null. Storage objects do not cascade. Storage cleanup and retention duration remain UNKNOWN — needs human confirmation.

## Derived behavior

Shopping suggestions are derived from recipe ingredients plus pantry quantities and thresholds. They are not stored as a second source of truth.

## Migration rules

- All schema changes use versioned migrations.
- Migrations must be additive where practical and tested against an isolated database.
- Production changes must not be made manually through the dashboard.
- Live application of the migrations and cross-user RLS/Storage verification: UNKNOWN — needs human confirmation.

Indexes include `shopping_list_items(source_recipe_id)` and `favorites(recipe_id)` for foreign-key lookups.

<!-- update-this-doc-when: supabase/migrations/*.sql, src/types/database.ts, src/lib/*.ts -->

