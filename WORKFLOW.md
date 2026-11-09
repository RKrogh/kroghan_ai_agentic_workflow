# The workflow

One person (the **owner**) and one lead Claude session run a project together. The lead
plans, briefs sub-agents, guards quality and hands the owner only what needs a human:
decisions, designs, QA and anything that touches production. Sub-agents do the building
and the reviewing, each in its own git worktree.

The owner's loop is short: open a session in the umbrella folder, ask "what should we do?",
say GO, come back to a status block, answer questions on a page, QA what merged.

This file is the playbook. Every rule carries the reason it exists, because each one was
learned from something that went wrong. Keep the reasons when you adapt the rules.

---

## 1. Layout: an umbrella folder and a planning repo

```
~/projects/<project>/            plain folder, NOT a git repo; sessions start here
├── CLAUDE.md                    lead-session instructions (from template/CLAUDE.md)
├── .worktrees/                  optional: shared worktree area
├── <project>-planning/          private git repo: the plan and the hand-off pages
│   ├── BACKLOG.md               source of truth: milestones, tracks, lanes, Q-ids
│   ├── NEXT-SESSION.md          temporary agenda: where the last session stopped
│   ├── *.html                   question pages, QA checklists, prototypes, explainers
│   └── qa/                      scripts the owner runs to test locally
├── <project>/                   code repo (AGENTS.md, docs/adr, docs/map)
└── <project>-web/ ...           more code repos, siblings
```

- **Sessions start in the umbrella** so one session reaches every repo. Git runs only inside
  a repo.
- **The planning repo is on GitHub**, so a cloud session started from a phone sees the same
  plan. Anything a cloud session needs must live in GitHub, not on your machine (memory,
  notes and secrets stay local).
- **Agents own the planning repo.** They commit small batches straight to its `main` without
  asking. Waiting for a go on every planning commit leaves the plan stale between sessions.
- **Edits to shared planning files are small and targeted, never rewrites.** Several agents
  edit `BACKLOG.md` at once; a rewrite silently drops someone else's line.

## 2. The backlog: tracks, lanes and Q-ids

`BACKLOG.md` has fixed sections (see `template/planning/BACKLOG.md`):

| Section | What it holds |
|---|---|
| Where we are | One table, one row per repo, state in a sentence |
| Open questions (Q-ids) | Every question ever asked, with its answer |
| Milestones | `M1`, `M2`... checkable outcomes |
| Track H: Human | `H1`, `H2`...: things only a person with a wallet, signature or account can do, sorted by what they block |
| Track A: Agents | Lanes (`A-O` ops, `A-P` product, `A-D` docs...), items `A-P12`. One lane = one worktree, its own files, so lanes run in parallel without merge fights |
| Parked / Ideas | With a trigger for when to revisit |

**Q-ids.** Every question to the owner gets a stable, never-reused id (`Q-07`), is written
into BACKLOG, and is referred to by id in chat. The owner answers by id ("Q-07: b").
Answered ones get `[x]` plus the date and the answer in the owner's words.
*Why:* with parallel agents and quick turns, "1." in a reply was ambiguous about which list
it meant.

### Anatomy of a question

This structure is what lets a project grow through decisions while agents run on their
own. Every question has the same five parts, on the page and in BACKLOG:

| Part | What it is | Why |
|---|---|---|
| **Id** | `Q-123`, next free number, never reused | Answers are unambiguous across parallel agents and sessions; ADRs, briefs, PRs and issues can cite the decision |
| **Question** | One plain sentence | The owner knows in one line what is being decided |
| **Context** | 2 to 4 sentences: what the thing is, where it lives, what the problem is, why it matters | The owner answers from the page alone, without the files or the session's memory |
| **Options + recommendation** | (a), (b), (c) with a one-line trade-off each; the recommended one preselected, with a sentence on why | Agreeing costs one glance; the owner spends attention only where they disagree |
| **Note** | Free text per question | Nuance, conditions and "yes, but" thoughts. Notes often carry the real decision; they are recorded with the answer in the owner's words |

The answer comes back as `Q-123: (b) ... | note`. The lead records it in BACKLOG (`[x]`, date,
choice, note) and carries it into what it shapes: an ADR cites the Q-ids that decided it
(`Decided with: Q-120..Q-123`), a brief lists the decided Q-ids so the implementer does not
reopen them, a PR body names the Q-ids it implements. That chain (question, answer, ADR,
lane, PR) is what lets agents run autonomously: they build on recorded decisions, and stop
at the next undecided one.

**Bugs live in GitHub issues, the plan lives in BACKLOG.** Backlog lines link issues
(`[gh #42]`). So do follow-ups and unfinished work: anything a session leaves behind
becomes an issue, so any later session, local or cloud, can pick it up.
*Why:* session reports are not a persistent record; the next session never reads them.

## 3. The session loop

**Start** (`/agent-workflow:session-start`)
1. Read `NEXT-SESSION.md` and `BACKLOG.md`, check open PRs and agent-filed issues.
2. Put **unanswered questions and pending owner checks first**, with how long they have
   waited. *Why:* question pages sat for days; the owner saw them but nobody brought them
   back. Unanswered is unfinished work, not background.
3. Propose a short plan: which lanes to run, what needs the owner. Wait for GO.

**GO** (`/agent-workflow:run-lanes`)
- The lead spawns implementers, one lane per worktree, and keeps the main thread for
  coordination. Runs continue **until the plan runs out or real design is needed**.
- **Design stop:** when a solution needs designing (a UX flow, a data model fork), agents
  do not guess and do not ask a terse one-liner. They stop and bring a proposal: an
  interactive HTML prototype or an ADR draft with options. *Why:* some decisions are more
  than a Q-id answer; the best designs came out of rounds of clicking a prototype.
- **Status checkpoints** after every 2 or 3 agent completions, or when the owner returns:
  what runs, what merged (links), what the owner must do, open Q-ids.
  *Why:* when sub-agents finish quickly, things get lost between turns.

**End** (`/agent-workflow:session-end`)
- Leftovers become issues. `NEXT-SESSION.md` gets a new top section: "start with",
  "unanswered, carried over", "owner to check", deploy notes, gotchas.
- Commit and push the planning repo. Before the machine goes off, everything is pushed.

## 3b. GitHub is the workbench, through your `gh` CLI

Claude Code has no GitHub access of its own on your machine: it runs **your** logged-in
`gh` CLI (`gh auth login` once). Everything it does on GitHub is done as you, and that
is what turns GitHub into the shared workbench between you, local sessions and cloud
sessions.

| Agents use `gh` to | Commands |
|---|---|
| File what they find, and leftovers | `gh issue list --state all --search ...` first, then `gh issue create` with the bug or task template, labels `found-by-agent`, `follow-up`, `qa` |
| Pick up work | `gh issue list --label found-by-agent`, `gh issue view <n>`; the fix PR says `Fixes #n`, so the merge closes it |
| Open and move PRs | `gh pr create --draft`, `gh pr ready`, `gh pr ready --undo`, `gh pr update-branch` |
| Review | `gh pr diff <n>`, `gh pr comment <n>` with the gate verdict on the first line |
| Check CI for real | `gh pr checks <n>`, `gh run list --branch <b>`, `gh run view <id> --json jobs` |
| Merge | `gh pr merge <n> --squash --delete-branch` |
| Set up a repo | `gh repo create --private`, `gh label create` |

- **Issues are the work queue.** Anything not finished becomes an issue, and an issue is a
  valid lane: "fix #123" is a complete brief starter. You can file issues yourself, from
  the phone too, and the next session picks them up.
- **Cloud sessions** (claude.ai/code, scheduled routines) don't use your `gh`: they reach
  your repos through the Claude GitHub App, which you grant per repo. Check it covers
  private repos before trusting an overnight run.
- **Permissions.** Auto mode or a permission prompt may block `gh pr merge`. If you granted
  standing merge permission (Q-01), allow it once in the umbrella's
  `.claude/settings.local.json` (`"allow": ["Bash(gh pr merge:*)"]`; the installer writes
  this with `--merge yes`) instead of merging by hand.
- Since agents act as you, the guardrails matter: draft PRs, the review gate, and no live
  production writes.

## 4. Code changes: the review gate

Every agent change goes through the same pipe (written into each repo's `AGENTS.md`):

1. Implementer works in its **own worktree and branch**. Never edits, resets or removes
   another agent's worktree or branch.
2. Opens a **draft PR** and runs the checks locally. CI skips drafts, so pushes are free.
3. A **separate reviewer agent** posts a PR comment whose **first line** is exactly
   `Independent review: APPROVE` or `Independent review: CHANGES REQUESTED`.
   A reviewer of a bug fix **reverts the fix locally to prove the tests catch the bug.**
   *Why:* it caught real defects that green CI missed (a resource leak, lost audit rows,
   false marketing copy). Same-model reviewers share the author's blind spots, so tricky
   fixes and re-reviews run on a stronger model.
4. After APPROVE: `gh pr ready` starts the **one** CI run. Fixes after that re-run CI, so
   batch them.
5. **Confirm the jobs ran and passed**, not just that nothing failed. *Why:* a run where
   every job showed `skipping` looked green. Check `gh run view <id> --json jobs`.
6. Squash-merge (agents merge themselves on APPROVE + real green CI, if the owner granted
   it once, as a Q-id). Merge serially; update the next PR from `main` before marking it
   ready. *Why:* hot files (docs indexes) made each following PR conflict.

Nit-only fixes after an APPROVE need no second review.

## 5. Hand-offs to the owner

The owner is frontend-light and answers from the page alone, without the files or the
session's context. Every hand-off is built for that.

**Question pages** (`/agent-workflow:ask-questions`, template in `template/planning/pages/`)
- Each question has its **own 2 to 4 sentence explainer**: what the thing is, where it
  lives, what the problem is, why it matters. Then options with one-line trade-offs.
  *Why:* a condensed page with titles and options only left questions unanswerable.
- **The recommended option arrives already selected.** *Why:* unticked boxes were read as
  "no recommendation" and skipped.
- Answers **autosave** in the browser; a "Copy answers" button gives `Q-07: (b) | note` lines
  to paste into chat.
- Once published and the owner starts answering, the page is **frozen**: never republish
  it. New questions go on a new page. *Why:* a republish mid-answer wiped answers, twice.
- Big themes get a **discussion session**, not just Q-ids.

**QA checklists** (`/agent-workflow:qa-handoff`): one line per thing to try, each with
Pass / Fail / Skip and a note, autosaved. A "not built yet, don't file these" section stops
false bug reports. Claude reads the marks back and files issues for the fails.

**Prototypes and explainers:** a temporary interactive HTML file in the planning repo with
Q-id answer boxes. Update the DOM in place (keyed); never re-render on a timer, it eats
clicks and input.

**Owner-only actions:** agents never run live production writes (provisioning, DNS,
billing, deploys to prod). They dry-run, summarise what would change, and hand the owner a
one-line `! <command>`. After the owner runs it, the agent verifies.

## 6. Agent hygiene (in every brief)

- **No `git stash`.** The stash stack is shared by all worktrees of a repo; two agents'
  changes crossed over. Use a throwaway detached worktree or a WIP commit instead.
- **Own test resources.** Agents use their own test database names and ports; a shared
  e2e database picked up another branch's migration.
- **File what you find.** Bugs, security gaps and doc drift outside the task become issues
  (search first, verify on `main`, label `found-by-agent`).
- **Dependency cooldown.** Only versions public for 14+ days, unless you are on a high or
  critical advisory and the fix is younger. Fresh releases are where supply-chain attacks
  land.
- **Prefer provider features.** If a provider (payments, mail, cloud) already does it,
  configure it instead of building a parallel layer. Duplicates drift.
- **Docs stay true.** A PR that changes structure updates the system map (`docs/map/`) in
  the same PR; a decision gets an ADR (`docs/adr/`). A diagram that lies is worse than none.
- **Writing:** plain words, no em dashes, no ticket numbers in durable docs or code
  comments (write the context instead). PR bodies and commits may reference issues.

## 7. Long runs and overnight

- Local agents die when the machine sleeps. Push often.
- For real overnight work, use a **scheduled cloud routine** (the `/schedule` skill).
  Verify where an agent actually ran: an `isolation: "remote"` launch has silently run on
  the local machine, and the work vanished with it.
- Cloud environments may lack your SDKs (for example no dotnet). Tell cloud agents to rely
  on CI or install the SDK first.
- GitHub Actions minutes cost money: CI once per reviewed change, no runs on `main`, don't
  re-run casually.

## 8. What stays personal

The kit carries the process. These stay with each person and are not in the kit:
- Personal tone and style (your global `~/.claude/CLAUDE.md`).
- Auto-memory: Claude still learns per user. When it learns a **process** rule that should
  hold for everyone, promote it into `CLAUDE.md` or `AGENTS.md` (and, if general, back into
  this kit).
- Secrets, machine quirks, local QA scripts.
- An optional personal knowledge base for memory across projects (see "Optional: a personal
  knowledge base" in the README). It helps local sessions recall earlier findings; the
  workflow never depends on it.
