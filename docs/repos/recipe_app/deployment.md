# PantryPilot Deployment

**Status:** Section 0 baseline, reconciled to workflow on 2026-11-19

## Environments

- Development: local Vite server; Supabase project identity is UNKNOWN — needs human confirmation
- Preview: exact preview method and hosting are UNKNOWN — needs human confirmation
- Production: intended Hostinger static hosting and domain `https://recipe.dillonlsmith.com`; actual upload process and production project are UNKNOWN — needs human confirmation

## Release flow

1. Open a feature branch.
2. Run local checks.
3. Open a GitHub pull request.
4. GitHub Actions runs the required checks.
5. Merge after review.
6. Build the static output.
7. Upload the output through the Hostinger mechanism and destination, both UNKNOWN — needs human confirmation.

## Static build contract

- Build command: `npm run build` from `recipe_app/`, or `npm --prefix recipe_app run build` from the workspace root.
- Output directory: `recipe_app/dist/`.
- Client-side routes require an SPA fallback to `index.html`; Hostinger rewrite configuration is UNKNOWN — needs human confirmation.
- HTTPS is required for production OAuth and authenticated traffic.
- Cache invalidation/versioning strategy: UNKNOWN — needs human confirmation.

## GitHub Actions deployment

`.github/workflows/recipe-app-checks.yml` runs on pull requests and pushes to `main`/`master`. It runs `procedure checks` and `typecheck, test, and build` (`npm ci`, `npm run typecheck`, `npm test`, `npm run build` from `recipe_app/`). It does not archive or upload `dist/`. Automatic deployment is not configured.

## Secrets

Local secrets live in an ignored `.env.local`. GitHub and production secrets must be configured in their respective secret stores. Never commit real Supabase keys or OAuth secrets.

## Rollback

Rollback procedure and verification are UNKNOWN — needs human confirmation.

## Hostinger constraint

The MVP is static because shared hosting does not provide the Node.js runtime required by a normal Next.js server deployment. A Hostinger VPS would be required if a server-rendered Node.js application is introduced.

<!-- update-this-doc-when: package.json, vite.config.*, .github/workflows/recipe-app-checks.yml, deployment configuration, hosting runbooks -->

