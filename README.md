# agent-workflow-kit

A working method for running a software project with one human owner and a lead Claude
Code session that coordinates many sub-agents for hours at a time. The owner opens a
session, asks "what should we do?", says GO, and gets back merged PRs, a status block,
a page of open questions to answer, and a QA checklist to try.

It packages two things:

- **A Claude Code plugin** (`agent-workflow`): skills for the rituals (session start,
  running lanes, asking questions, QA hand-off, session end, new project) and two agent
  definitions (implementer, reviewer).
- **A project template** plus `install.sh`: the umbrella `CLAUDE.md`, a planning repo
  (`BACKLOG.md`, `NEXT-SESSION.md`, question and QA page templates), and per-repo
  `AGENTS.md`, issue, PR, ADR and system-map templates.

Read [WORKFLOW.md](WORKFLOW.md) first: it is the playbook, and every rule carries the reason
it exists.

## What you get

| Piece | What it does |
|---|---|
| Planning repo | `BACKLOG.md` with milestones, a human track (H), agent lanes (A) and stable question ids (Q-NN). `NEXT-SESSION.md` says where the last session stopped. Private on GitHub, so cloud sessions see it too |
| Lanes | Parallel implementers, one git worktree each, no shared files |
| Review gate | A separate reviewer agent posts `Independent review: APPROVE` as the first line of a PR comment; bug-fix reviews revert the fix to prove the tests catch it; CI runs once, after approval, and "all jobs skipped" does not count as green |
| Question pages | One explainer per question, recommendation preselected, answers autosave, "Copy answers" gives `Q-07: (b) | note` lines. Frozen once answering starts |
| QA pages | Pass / Fail / Skip per line with notes, autosaved; fails become issues |
| Design stops | Agents stop at real design forks and bring a prototype or ADR draft instead of guessing |
| Hand-offs | Production writes stay with the owner as one-line commands; leftovers become GitHub issues |

## Install the plugin

From a clone (or this folder) on your machine, inside Claude Code:

```
/plugin marketplace add ~/projects/agent-workflow-kit
/plugin install agent-workflow@agent-workflow-kit
```

From GitHub once the repo is pushed: `/plugin marketplace add <github-owner>/agent-workflow-kit`.

Skills then show up as `agent-workflow:session-start`, `agent-workflow:run-lanes`,
`agent-workflow:ask-questions`, `agent-workflow:qa-handoff`,
`agent-workflow:session-end`, `agent-workflow:new-project`.

Prefer no plugin? `install.sh --local-skills` copies the skills and agents into the
project's `.claude/` folder instead.

## Start a project

Either ask Claude Code to run `agent-workflow:new-project`, or run the installer yourself:

```bash
./install.sh --name "Acme" --slug acme --dir ~/projects/acme_project \
  --owner "Alex" --repos "acme,acme-web" --merge no --dry-run   # look first
./install.sh --name "Acme" --slug acme --dir ~/projects/acme_project \
  --owner "Alex" --repos "acme,acme-web" --merge no
```

The installer never overwrites a file; on existing repos it only adds what is missing.
Then start Claude Code in the umbrella folder and fill the base plate with it: where you
are, milestones, the human track, the first agent lanes, the first ADRs. That planning
phase is what makes the later autonomous runs work. After that: "what should we do?", GO.

## Requirements

- Claude Code, `git`, `perl` (for the installer's placeholder filling).
- The GitHub CLI, logged in (`gh auth login`). Claude Code files issues, picks them up,
  opens and reviews PRs, checks CI and merges through **your** `gh`, so it acts as you.
  Cloud sessions instead need the Claude GitHub App installed on your repos. See
  "GitHub is the workbench" in WORKFLOW.md.
- GitHub repos for the code and a private one for planning.
- CI that skips draft PRs and runs when a PR is marked ready, so pushes are free and CI
  runs once per reviewed change. Both halves matter: see "CI that runs once" in
  WORKFLOW.md and `template/snippets/ci-draft-gate.yml`.

## Optional: a personal knowledge base

Not part of the kit, and nothing in it depends on one. The planning repo and GitHub are the
shared record; cloud sessions only ever see those. What a local knowledge base adds is
memory across projects on your own machines: debugging gotchas, decisions and patterns that
a session in another project can find later.

One option is [OpenIdiom](https://github.com/robertkrogh/OpenIdiom) (`oi`), an open-source
Rust CLI that indexes a folder of Markdown notes (Obsidian-compatible) with keyword search,
tag and link queries, and optional semantic search with local embeddings.

A setup that works:

- **One vault folder**, e.g. `~/projects/notes/`, with a subfolder agents write to
  (`notes/claude/`). Run `oi` from the vault root.
- **Tell agents in your personal `~/.claude/CLAUDE.md`**, not in a project: search the vault
  (`oi search`, `oi query --tag`) when prior context could help, and write a short note
  (frontmatter with `title`, `tags`, `date`; `[[wikilinks]]` to related notes) when a session
  produces something a future session would want. The bar: "would a future session benefit
  from finding this?"
- **Sync between your machines with [Syncthing](https://syncthing.net/)**: peer to peer, no
  cloud in between. Sync the notes, not the index: put `.openidiom/index.db*` in the
  folder's `.stignore` (a SQLite file synced while in use gets conflict copies) and run
  `oi index` on each machine after a sync.
- Keep project state out of it. Plans, questions and leftover work still go to the
  planning repo and GitHub issues, where every session and every teammate can see them.

## Adapting it

The kit is a starting point. Rules you learn the hard way belong in your umbrella
`CLAUDE.md` or a repo's `AGENTS.md`, with the reason. If they are general, send them back
here.

## Layout of this repo

```
.claude-plugin/        plugin.json, marketplace.json
agents/                implementer.md, reviewer.md
skills/                one folder per skill
template/              files install.sh copies into a project
  snippets/            CI snippet (not installed; merge into your workflow)
  CLAUDE.md            umbrella lead instructions
  AGENTS.md            per code repo rules
  planning/            BACKLOG, NEXT-SESSION, README, pages/
  repo/                .github templates, docs/adr, docs/map
install.sh
WORKFLOW.md            the playbook
```
