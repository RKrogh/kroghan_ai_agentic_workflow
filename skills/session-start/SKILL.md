---
name: session-start
description: Open a lead session on a project that uses the agent workflow. Reads the planning repo, puts unanswered questions and pending owner checks first, and proposes a plan to GO on. Use when the owner opens with "what should we do?", "status", "where were we", or at the start of any session in the umbrella folder.
---

# Session start

The owner wants to know, in one screen, what is waiting on them and what you propose to do.

## Gather (in parallel where possible)

1. Find the planning repo (the umbrella `CLAUDE.md` names it). `git pull` it.
2. Read `NEXT-SESSION.md` (top sections) and `BACKLOG.md`.
3. Open questions: every `- [ ] **Q-` line in BACKLOG, with the date asked.
4. For each code repo: `git fetch`, open PRs (`gh pr list`), and agent-filed issues
   (`gh issue list --label found-by-agent --state open`). Note PRs that are approved but not
   merged, and drafts with no review yet.
5. Anything marked "owner to check", "reads", deploy notes.

## Report (short, this order)

1. **Unanswered, carried over.** Q-ids with their page link and how many days they have
   waited, pending owner checks, documents to read. These go first, always. Unanswered is
   unfinished work, not background.
2. **Where things stand.** What merged since last time, what is in flight.
3. **Proposed plan.** 2 to 5 lanes that can run in parallel without touching the same files,
   each with its BACKLOG id or issue, and which ones need the owner first. Name any design
   forks you can already see: those become proposals, not guesses.
4. Ask for GO (or for answers to the carried-over questions first, if they block lanes).

If the session is long-running and the owner returns later, give a status checkpoint
instead (see `run-lanes`).

Keep it tight: the owner reads it on one screen.
