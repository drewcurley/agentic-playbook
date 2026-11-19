# Workspace Manifest — PantryPilot

This playbook governs the PantryPilot project in the shared workspace.

## Project

- **Name:** PantryPilot
- **Playbook repo:** `agentic-playbook`
- **Workspace layout:** this workspace has one authoritative Git repository at its root; `agentic-playbook/` is the process source and `recipe_app/` is the product source within that repository.

## Repositories in this project

| dir | role | git URL | default branch | contracts doc |
|-----|------|---------|----------------|---------------|
| `recipe_app` | Vite/React/Supabase web application within the workspace-root repository | `https://github.com/nollidsmith/recipe_app.git` | `main` | `recipe_app/docs/contracts.md` |

## Cross-repo truth

PantryPilot currently has one code repository. Root `.github/workflows/` and root `.githooks/` are authoritative; product code, docs, migrations, and tasks live under `recipe_app/`. There are no sibling-repository API, event, package, or shared-store seams to coordinate. Supabase, Google OAuth, Apple OAuth, and Hostinger are external integrations documented in `recipe_app/docs/contracts.md`.

The project-wide integration map remains the authoritative place to record a seam if another repository is added later.
