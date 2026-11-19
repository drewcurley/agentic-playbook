# PantryPilot Stack

**Status:** Section 0 baseline, reconciled to source on 2026-11-19

| Area | Decision | Reason |
|---|---|---|
| UI | React | Component-based interface for recipes, pantry, and forms |
| Language | TypeScript | Safer data contracts and refactoring |
| Build tool | Vite | Produces static assets compatible with Hostinger shared hosting |
| Styling | Plain CSS | Readable, direct red/black/blue design system with minimal build complexity |
| Auth | Supabase Auth | Email/password, Google, and Apple login |
| Database | Supabase PostgreSQL | Relational recipe, ingredient, and inventory data |
| File storage | Supabase Storage | Authenticated user recipe images |
| CI | GitHub Actions | Repeatable checks on pull requests and `main` |
| Hosting | Hostinger shared hosting | Serves the generated static files and owns the domain |
| Source control | GitHub | Code review, history, and CI |
| Package manager | npm | Standard Node.js workflow and simplest GitHub Actions setup |

## Non-decisions

- No custom Node.js server is part of the first deployment model.
- No service-role key is shipped to the browser.
- No image provider is required for user-uploaded recipe images.

<!-- update-this-doc-when: package.json, src/**, supabase/migrations/*.sql, hosting configuration -->

