---
name: run-lanes
description: Run backlog lanes autonomously with parallel implementer and reviewer sub-agents after the owner says GO. Covers briefs, the review gate, merging, status checkpoints and design stops. Use when the owner says GO, "run with it", "keep going", or asks for an autonomous run.
---

# Run lanes

You are the lead. You coordinate; sub-agents build and review. Keep your own thread for
planning, briefs, gate decisions and status.

## Pick lanes

- Lanes that run together must not touch the same files. Hot shared files (docs indexes,
  CI config) are a reason to serialize.
- Prefer lanes that need nothing from the owner. A lane blocked on a Q-id waits.
- Open GitHub issues are lanes too (`gh issue list --label found-by-agent`, plus issues the
  owner filed). Read the issue (`gh issue view <n>`), check it still holds on `main`, and
  brief from it; the PR says `Fixes #n` so the merge closes it. Group small related issues
  into one lane when they touch the same files.

## Brief an implementer (one per lane)

Use the `implementer` agent. The brief is all it knows, so include:
- The repo, the BACKLOG id or issue, and the goal in two sentences.
- What is decided (Q-ids and their answers) and what is out of scope.
- The files it owns; files it must not touch because another lane has them.
- Verification you expect (which tests, which flow to drive).
- The standing rules: own worktree, **no `git stash`**, own test resources, file issues for
  out-of-scope findings, design stop, draft PR only, no live production writes.

Run implementers in the background, several at once. For tricky fixes, set a stronger model
via the Agent call's model override.

## Gate every PR

When an implementer reports a draft PR:
1. Spawn a `reviewer` agent for it (not the author). For re-reviews, resume the same
   reviewer. For tricky fixes and their re-reviews, use a stronger model than the author.
2. CHANGES REQUESTED: send the findings back to the implementer; fixes come in one batch.
3. APPROVE (first line of the PR comment, exactly `Independent review: APPROVE`):
   `gh pr ready <n>`, wait for CI, then **confirm the jobs ran and passed**
   (`gh pr checks <n>`; if a job shows only `skipping`, check
   `gh run view <id> --json jobs` of the ready run). All-skipped is not a pass.
4. Merge serially if the owner has granted standing merge permission (a recorded Q-id);
   otherwise list it for the owner. Before the next PR goes ready, update it from `main`
   if they share an area. `gh pr merge <n> --squash --delete-branch`.
5. Record it in BACKLOG (`[x]` with a short "done" note) and close linked issues via
   `Fixes #n`.

If a permission prompt or classifier blocks a merge, offer the owner an allow rule rather
than handing over merge commands one by one.

## Design stop

When an agent reports a design fork, or you see one: stop that lane and build a proposal.
Use an interactive HTML prototype in the planning repo for anything the owner should click,
or an ADR draft with options for architecture. Put the decisions on it as Q-ids (see
`ask-questions`). Other lanes keep running.

## Status checkpoints

After every 2 or 3 agent completions, or when the owner comes back, post a compact block:

```
Running:   lane, agent, what it is doing
Merged:    repo #n (one line each, link)
Waiting:   PRs in review, CI runs
Owner:     things to check or run (commands), Q-ids open (page link)
Next:      what starts when a slot frees
```

## Keep going until

- The plan runs out, or
- Everything left needs the owner (answers, design, accounts, production), or
- The owner says stop or the session nears its limits.

Then run `session-end`.

## Long and overnight runs

Local agents die when the machine sleeps; tell them to push often. For overnight work use
a scheduled cloud routine (`/schedule`), and verify where an agent actually ran: an
`isolation: "remote"` launch has silently run locally. Cloud environments may lack
SDKs; tell those agents to rely on CI or install the SDK first.
