# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What is this?

Pi is a monorepo for building AI agents and managing LLM deployments. The main product is `packages/coding-agent` — an interactive coding agent CLI. All rules in AGENTS.md apply to both humans and AI agents.

## Commands

```bash
npm install                # Install all dependencies
npm run build              # Build all packages (required before check)
npm run check              # Biome lint/format + tsgo type check (must pass before commit)
./test.sh                  # Run all tests (skips LLM-dependent tests without API keys)
./pi-test.sh               # Run pi coding agent from sources
```

Run a single test from the **package root** (not repo root):
```bash
cd packages/ai
npx tsx ../../node_modules/vitest/dist/cli.js --run test/specific.test.ts
```

**NEVER run:** `npm run dev`, `npm run build`, `npm test` (from repo root for tests).

`npm run check` does NOT run tests. It requires `npm run build` first (web-ui needs compiled `.d.ts` files).

## Architecture

```
ai  (unified multi-provider LLM API — no local deps)
 ↑
agent  (agent runtime: tool calling, state management)
 ↑
coding-agent  (CLI, tools: read/bash/edit/write, sessions)  ←  tui (terminal UI components)
 ↑
mom  (Slack bot wrapping coding-agent)
```

Separate: **web-ui** (Lit web components, depends on ai+tui), **pods** (vLLM GPU pod CLI, depends on agent).

All packages are npm workspaces under `packages/`. Lockstep versioning — all packages share the same version number.

## Key Conventions

- **No `any` types** unless absolutely necessary. Check `node_modules` for real type definitions.
- **No inline imports** — no `await import("./foo.js")`, no `import("pkg").Type`. Always top-level imports.
- **No hardcoded keybindings** — all keybindings must go through `DEFAULT_EDITOR_KEYBINDINGS` or `DEFAULT_APP_KEYBINDINGS`.
- **Biome** for formatting/linting: tabs, indent width 3, line width 120.
- **TypeScript** target ES2022, module Node16, strict mode. Uses `tsgo` for type checking.
- **Pre-commit hook** runs `npm run check` and re-stages formatted files.

## Testing

- Tests use vitest. Run from the package root, not the repo root.
- `packages/coding-agent/test/suite/` tests use `harness.ts` + faux provider. No real API keys.
- Issue regression tests go in `packages/coding-agent/test/suite/regressions/<issue-number>-<short-slug>.test.ts`.
- If you create or modify a test, you MUST run it and iterate until it passes.

## Adding a New LLM Provider

Requires changes across multiple files — see the detailed checklist in AGENTS.md under "Adding a New LLM Provider." Key touchpoints: `packages/ai/src/types.ts` (type union), `packages/ai/src/providers/` (implementation), `packages/ai/src/providers/register-builtins.ts` (lazy registration), `packages/ai/scripts/generate-models.ts`, test files, and `packages/coding-agent/src/core/model-resolver.ts`.

## Git Rules

- NEVER use `git add -A` or `git add .` — always add specific files.
- NEVER use `git commit --no-verify`.
- Include `fixes #<number>` or `closes #<number>` in commit messages when applicable.
- Changelog entries go under `## [Unreleased]` in each package's `CHANGELOG.md`. Never modify released version sections.

## .pi/ Directory

- `extensions/` — custom coding-agent extensions (diff, files, prompt-url-widget, redraws, tps)
- `prompts/` — automation prompt templates (changelog, issue, PR, write)
