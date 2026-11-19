# PantryPilot Domain

**Status:** Tier 2 baseline, reconciled to current domain terms on 2026-11-19

## Entities

- User — authenticated account from Supabase `auth.users`.
- Profile — optional display information for a user.
- Recipe — a user-owned preparation with ingredients and instructions.
- Recipe ingredient — an ordered ingredient requirement belonging to a recipe.
- Pantry item — an ingredient or supply currently owned by a user.
- Shopping-list item — a user’s planned purchase, optionally derived from a recipe.
- Favorite — a user’s relationship to a recipe.
- Recipe image — a user-owned Storage object referenced by a recipe.

## Core invariants

- A user cannot access another user’s data.
- A recipe ingredient cannot exist without its recipe.
- Suggestions are derived from recipe and pantry data.
- Pantry quantities use explicit units; shopping-list units are optional in the implemented schema.
- Image files are not the source of recipe data.

<!-- update-this-doc-when: src/app/**, src/lib/**, src/types/**, supabase/migrations/*.sql -->
