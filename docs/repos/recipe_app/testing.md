# PantryPilot Testing Strategy

**Status:** Section 0 baseline, reconciled to current suite on 2026-11-19

## Current coverage

The current suite has 5 Vitest/jsdom files and 13 tests covering login flows,
password reset, recipe form validation/submission, recipe data access and image
MIME validation, and pantry image MIME validation with pre-insert rejection.

The broader journey lists below are planned coverage, not completed coverage.

## Required levels

- Unit tests for ingredient normalization, stock thresholds, suggestion logic, and form validation.
- Component tests for login, recipe forms, pantry rows, shopping-list actions, loading states, and error states.
- Integration tests for Supabase data access with isolated test users and data.
- End-to-end tests for sign-in, recipe creation, pantry updates, and adding missing ingredients to the shopping list.

## Journey/state coverage

- Login: success, invalid credentials, OAuth success, OAuth cancellation/failure, password reset, expired session.
- Recipe hub: first-use empty state, populated state, loading, and network error.
- Recipe editor: validation errors, image preview/progress/retry, save success, replacement, removal, and delete confirmation.
- Pantry: add/edit/delete, low-stock and expiration states, empty state, and failed mutation.
- Shopping list: derived suggestions, duplicate prevention, completion, and failed update.
- Accessibility: keyboard navigation, focus order, labels, contrast, reduced-motion behavior, and 44px touch targets.

## Security tests

- A user cannot read another user’s recipes, pantry items, shopping items, favorites, or image files.
- Unauthenticated users cannot access protected routes or mutations.
- Invalid uploads are rejected by type and size policy.
- Service-role credentials never appear in the client bundle.

## CI checks

The PR procedure gate is invoked as:

```sh
CI_PROJECT_PREFIX=recipe_app \
CI_PLACEHOLDER_ALLOW=recipe_app/.placeholder-allow \
sh recipe_app/scripts/ci-pr-checks.sh <target-sha> <head-sha>
```

The root workflow runs procedure checks plus `npm ci`, `npm run typecheck`,
`npm test`, and `npm run build` from `recipe_app/`. There are currently no
configured coverage thresholds/reports, formatting or lint checks, live Supabase
integration tests, end-to-end tests, accessibility automation, RLS/Storage
security tests, oversized-image tests, or image-dimension tests. The build passes
with a non-failing approximately 503.10 kB main-bundle warning.

<!-- update-this-doc-when: package.json, src/test/**, scripts/**, .github/workflows/recipe-app-checks.yml -->

