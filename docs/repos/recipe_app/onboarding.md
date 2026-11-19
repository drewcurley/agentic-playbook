# PantryPilot Onboarding

**Status:** Section 0 baseline, reconciled to current repository on 2026-11-19

## Prerequisites

- Git
- Node.js and npm compatible with the repository lockfile
- A Supabase project for development
- A GitHub account with repository access

## Local setup

1. Clone the repository.
2. Install dependencies from the workspace root with `npm --prefix recipe_app ci`.
3. Copy `.env.example` to `.env.local`.
4. Add development Supabase values.
5. Run migrations or database setup commands.
6. Start the Vite development server with `npm --prefix recipe_app run dev`.
7. Run `npm --prefix recipe_app run typecheck`, `npm --prefix recipe_app test`, and `npm --prefix recipe_app run build` before opening a pull request.

## Workflow

Use a feature branch, update the relevant task and contract docs, run local checks, open a pull request, and wait for GitHub Actions before merging.

<!-- update-this-doc-when: package.json, .env.example, .github/workflows/recipe-app-checks.yml, AGENTS.md -->

