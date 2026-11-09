---
name: new-project
description: Set up the agent workflow for a new or existing project. Scaffolds the umbrella CLAUDE.md, the planning repo (BACKLOG, NEXT-SESSION, WORKFLOW, page templates) and AGENTS.md plus issue/PR/ADR templates in each code repo, then helps fill the first backlog. Use when the owner wants to start a project with this workflow or adopt it in existing repos.
---

# New project

## 1. Ask once, then act

Gather (ask only what you cannot infer from the folder):
- Project name and a short slug (`acme`).
- Umbrella folder (default `~/projects/<slug>_project`).
- The owner's name as it should appear in instructions (default: "the owner").
- Code repos: names, and whether they exist already.
- GitHub owner for the planning repo (private).
- Standing merge permission for agents on APPROVE plus green CI: yes, no, or ask later.
  The installer records it as Q-01 (answered for yes/no, open for ask).

## 2. Scaffold

Run the kit's installer, `install.sh` in the kit root. When this skill loads, its base
directory is shown; the kit root is two folders up from it. If `install.sh` is not there
(skills copied with `--local-skills`), ask the owner where their clone of the kit is. Read
the script first; it only writes files that do not exist yet:

```bash
<kit>/install.sh --name "<Project>" --slug <slug> --owner "<Owner>" \
  --dir <umbrella> --repos "<slug>,<slug>-web" --merge yes|no|ask --dry-run   # then without --dry-run
```

It creates, without overwriting anything:
- `<umbrella>/CLAUDE.md` (lead instructions)
- `<umbrella>/<slug>-planning/` with BACKLOG, NEXT-SESSION, WORKFLOW, README, `pages/`, `qa/`
  (git init on `main`)
- In each code repo: `AGENTS.md`, `CLAUDE.md` (`@AGENTS.md`), `.github/` issue and PR
  templates, `docs/adr/0000-template.md`, `docs/map/README.md`

The installer ends with numbered next steps. With the owner's go, run them: the private
planning repo on GitHub, a first commit and a GitHub repo for each code repo it created
(agents branch from `origin/main`, so a repo without a remote blocks every lane), the labels
(`found-by-agent`, `follow-up`, `qa`, `security`, `tech-debt`) in each code repo, and CI
that skips drafts and runs on ready (`template/snippets/ci-draft-gate.yml` in the kit).

## 3. Fill the base plate

This is the planning phase that makes later autonomous runs work. With the owner:
- "Where we are", strategy lines and the critical path.
- Milestones `M1..`.
- Track H: what only the owner can do, sorted by what it blocks.
- Track A: lanes with first items, each small enough for one PR.
- The first ADRs for decisions already made.
- Each repo's `AGENTS.md` "Build and verify" section with real commands.

Ask the design questions through `ask-questions`, not in chat prose.

## 4. Hand over

Tell the owner: start sessions in the umbrella folder, ask "what should we do?", and say GO.
