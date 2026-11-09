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
- Standing merge permission for agents on APPROVE plus green CI: yes or no. Record it as
  the first answered Q-id.

## 2. Scaffold

Run the kit's installer (in this plugin's root: `install.sh`; read it first, it only writes
files that do not exist yet):

```bash
<kit>/install.sh --name "<Project>" --slug <slug> --owner "<Owner>" \
  --dir <umbrella> --repos "<slug>,<slug>-web" [--merge yes|no]
```

It creates, without overwriting anything:
- `<umbrella>/CLAUDE.md` (lead instructions)
- `<umbrella>/<slug>-planning/` with BACKLOG, NEXT-SESSION, WORKFLOW, README, `pages/`, `qa/`
  (git init on `main`)
- In each code repo: `AGENTS.md`, `CLAUDE.md` (`@AGENTS.md`), `.github/` issue and PR
  templates, `docs/adr/0000-template.md`, `docs/map/README.md`

Then, with the owner's go: create the private planning repo on GitHub
(`gh repo create <owner>/<slug>-planning --private --source <planning> --push`), and the
labels `found-by-agent`, `follow-up`, `qa` in each code repo (`gh label create`).

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
