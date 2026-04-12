## Shared Project State (wiki/projects/)

A cross-agent wiki at `wiki/projects/` provides shared state between Claude Code,
Hermes Agent, and Open Claw. It is mounted into Docker at `/opt/workspace/wiki/`.

**Key files:**
- `project-state.md` -- active projects and their current status
- `decisions-log.md` -- append-only log of non-obvious architectural/design decisions
- `SCHEMA.md` -- conventions and format rules

**When to read:** On session start when working on any project listed in `project-state.md`.

**When to write:**
- Update `project-state.md` when a project's status, current work, or next steps change
- Append to `decisions-log.md` when making a non-obvious choice (chose X over Y because Z)
- Always bump the `updated` date in frontmatter and append to `log.md`
