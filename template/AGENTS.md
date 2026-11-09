# {{REPO}}

Instructions for coding agents working in this repo. Claude Code and Codex both read this
file (Claude Code via a one-line `CLAUDE.md` that says `@AGENTS.md`).

## Build and verify

<!-- Fill in: how to restore, build, test, lint, and run the app locally.
     Keep it to commands an agent can copy. Move a long runbook to
     .claude/skills/verify/SKILL.md and link it here. -->

```bash
# restore / build / test
```

## Pull requests and CI

CI minutes cost money, so CI runs once per reviewed change, not on every push:

- Open the PR as a **draft** (`gh pr create --draft`). CI skips drafts, so push as often as
  you like. (CI must trigger on `ready_for_review` and skip drafts; see "CI that runs once"
  in the planning repo's WORKFLOW.md.)
- Before asking for review, run the same checks locally. Say in the PR what you ran.
- After the independent review approves, mark the PR ready (`gh pr ready`). That starts the
  one CI run the merge waits for.
- **Confirm the jobs actually ran and passed**, not only that nothing failed. A run where
  every job shows `skipping` is not a pass; check `gh run list --branch <b>` and
  `gh run view <id> --json jobs`.
- Fixes after that re-run CI, so batch them into one push. If CI fails on something that
  needs real work, put the PR back to draft (`gh pr ready --undo`) while you fix it.
- `main` has no CI run of its own. Before merging a PR whose CI ran on an older `main`,
  update it (`gh pr update-branch`) if `main` gained changes in the same area. Merge PRs
  one at a time.

## Working rules

- **Parallel agents.** Several agents work at once. Work only in a worktree and branch that
  you created or were pointed at; never edit, reset or remove another agent's.
- **Never use `git stash`.** All worktrees of a repo share one stash stack, so stashed
  changes can cross into another agent's work. To compare before and after, use a throwaway
  detached worktree or a WIP commit.
- **Own test resources.** Use your own test database names and ports, never a shared one.
- **Never push to `main`.** Branch, open a PR, squash-merge it.
- **Independent review gate.** Every agent PR gets a separate reviewer agent, which posts a
  PR comment whose **first line** is exactly `Independent review: APPROVE` or
  `Independent review: CHANGES REQUESTED`. Merge only with an APPROVE plus green CI. A
  reviewer of a bug fix reverts the fix locally to prove the tests catch the bug. Nit-only
  fixes after an APPROVE need no second review.
- **No live infrastructure writes.** Never run provisioning, DNS, billing or other
  production writes. Dry-run if the tool supports it, describe the change, and hand the
  owner the one-line command.
- **Leftover work goes to GitHub issues**, filed like bugs (below). PRs link them with
  `Fixes #n` or `Refs #n`.
- **Dependency cooldown.** Move a dependency only to a version public for at least 14 days
  (packages, container images, CI actions, transitive pins). Exception: you are on a version
  with a high or critical advisory and the fix is younger; take it and say so in the PR.
- **Prefer provider features.** If an external provider already does it, configure it rather
  than building a duplicate layer.
- **Questions to the owner** use stable `Q-NN` ids from the planning repo's BACKLOG
  ({{PLANNING_REPO}}). If you cannot read it, put the question with a new Q-id in the PR
  body and say it needs a backlog entry.
- **Writing.** Plain words, no em dashes. No ticket, issue or PR numbers in durable docs or
  code comments; write the context instead.

## Docs: keep them true

- `docs/adr/` is why: a decision with alternatives gets an ADR (copy `0000-template.md`).
  An amended ADR says so at the top, with the date.
- `docs/map/` is what the system is. A PR that changes structure (modules, data model,
  endpoints, background jobs, deploy topology, key flows) updates the matching map file in
  the same PR, or says in the PR checklist why none is needed. A diagram that lies is worse
  than none.

## Bugs and findings: file an issue

An agent that discovers a bug, security gap or doc drift outside its task files a GitHub
issue before finishing:

- Verify it on current `main` and search first
  (`gh issue list --state all --search "<keywords>"`).
- Write the body with the bug template's headings: Summary, Where (file:line links),
  Reproduce, Expected, Actual, Impact, Suggested fix. (The issue forms only work in the
  browser; from the CLI use `gh issue create --title ... --body-file ... --label ...`.)
- Labels, passed explicitly: `found-by-agent` plus what fits (`bug`, `security`,
  `documentation`, `tech-debt`, `follow-up`, `qa`).
- Mention the issue in your report and next to the BACKLOG item it relates to.
