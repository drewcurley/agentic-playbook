# PantryPilot UX Baseline

**Status:** Section 0 baseline, reconciled to current UI on 2026-11-19

## Primary user

Home cooks who want one place to remember recipes, understand what is in the pantry, and reduce forgotten or duplicate grocery purchases.

## Core journeys

1. Sign up or sign in with email, Google, or Apple.
2. Land on the recipe hub and see saved recipes or a helpful empty state.
3. Add a recipe with ingredients, instructions, timing, servings, and an optional image.
4. Add pantry items and see low-stock/expiring states.
5. Use placeholder screens for shopping, popular recipes, and profile.

## Authentication states

The UI supports validation, loading, success, expired-session, and password-reset states. OAuth provider setup and complete cancellation/failure/email-verification coverage remain unverified.

## Image-upload journey

Users select an image, see a local preview, and can remove it. Unsupported type and size failures are surfaced. Progress, cancel/retry, user-provided alt text, and automated abandoned-upload handling are not currently implemented.

## Required states

Every screen must define loading, empty, success, and actionable error states. Destructive actions require confirmation. Every interactive icon needs an accessible label.

## Visual direction

- Red: primary actions, warnings, and active emphasis
- Black/deep charcoal: navigation, headings, and structure
- Blue: information, secondary actions, and supporting highlights
- Recipe imagery is supplementary content and must never carry meaning by color alone.

## Accessibility

Target WCAG 2.2 AA. Support keyboard navigation, visible focus, sufficient contrast, responsive touch targets, semantic headings, screen-reader labels, and reduced motion.

Accessibility conformance is a target, not verified compliance; no automated audit, keyboard-navigation test, contrast verification, or screen-reader test is configured. Source verification currently covers local image previews, removal, and reduced-motion CSS. Recipe cards expose inline instructions and deletion; there is no recipe detail/edit screen. Upload progress, cancel/retry, image-dimension validation, pantry-image replacement, and automated accessibility coverage are not implemented.

<!-- update-this-doc-when: src/app/**, src/components/**, src/styles/**, src/test/** -->

