---
title: {{PROJECT}} backlog (human + agent tracks)
tags: [{{SLUG}}, backlog, planning]
date: {{DATE}}
status: active
---

# {{PROJECT}}: where we are and what's next

_Bugs, defects and leftover tasks are GitHub issues (`[gh #N]`); this file is the plan, not
the bug tracker. Edit it in small, targeted pieces: several agents edit it at once._

## Where we are

| Repo | State | Summary |
|---|---|---|
| **{{SLUG}}** | | |

**Strategy:** <!-- the few decisions that shape everything; one line each, with the date -->

**Critical path:** <!-- step → step → step to the first real milestone -->

---

## Open questions (Q-ids)

Stable ids, never reused. Answer by id ("Q-03: b"). Answered ones get `[x]`, the date and the
answer in the owner's words. Prune old answered ones into the git history now and then.

{{MERGE_Q}}

<!-- Format:
  [ ] Q-NN (asked {{DATE}}, page: questions-{{DATE}}.html) The question in one line. Options (a) ..., (b) .... Recommendation: (a).
  [x] Q-NN (answered {{DATE}}: b; owner: "their words") The question.
-->

## Milestones

- [ ] **M1** <!-- checkable outcome -->
- [ ] **M2**

---

## Track H: Human ({{OWNER}})

Things only a person with a wallet, a signature, an account or a native tongue can do.
Sorted by how much they block. `_(blocks M1)_` marks the gate.

### Blockers (do first)
- [ ] **H1**

### Decisions
### Accounts and external setup

---

## Track A: AI agents (parallel lanes)

Each lane runs in its own **git worktree** and touches its own files, so several can run at
once without merge fights. `⛔ Hx` means the item waits on a human item. Done items keep a
short note: `(done {{DATE}}, PR repo#N: what it turned out to be)`.

### Lane O: Ops, deploy and CI
- [ ] **A-O1**

### Lane P: Product
- [ ] **A-P1**

### Lane D: Docs and analysis (no code, fully parallel)
- [ ] **A-D1**

### Parked
<!-- each with the trigger that brings it back -->

---

## Ideas (not scheduled)

## Suggested next move

**Human, this week:**

**Agents:**
