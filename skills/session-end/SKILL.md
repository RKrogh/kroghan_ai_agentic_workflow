---
name: session-end
description: Close a lead session so the next one (local or cloud) can pick up cleanly. Files leftovers as issues, updates BACKLOG and NEXT-SESSION, pushes everything. Use when the owner says they are stopping, going to bed, "wrap up", or when the plan has run out.
---

# Session end

Nothing may live only in this session. The next session reads GitHub and the planning repo,
nothing else.

1. **Agents.** Make sure running agents have pushed. Note any still running and what they
   will leave behind; local agents die when the machine goes off. Work that must continue
   overnight goes to a scheduled cloud routine, not a local background agent.
2. **Leftovers become issues.** Every unfinished task, follow-up, flaky test or finding not
   yet filed: a GitHub issue in the repo it belongs to (task or bug template). Search first.
3. **BACKLOG.md** (small, targeted edits; pull first): done items `[x]` with a short note and
   PR link, new items linked to their issues, answered Q-ids recorded.
4. **NEXT-SESSION.md**: a new section on top, and refresh the two fixed sections:
   - "Next session: start with": the one or two first moves and why.
   - "Unanswered, carried over": every open Q-id with its page link and the date asked,
     owner checks, documents to read. Never let these sink below new work.
   - The dated section: merged (with how it passed the gate), in flight, owner to check
     (commands), deploy notes, new issues, gotchas. Trim sections older than about a week.
5. **Commit and push** the planning repo.
6. **Knowledge.** If the session produced something a future session should know (a
   process rule learned from a mistake, a non-obvious gotcha), put it where it will be
   read: the umbrella `CLAUDE.md` or a repo's `AGENTS.md` for rules, NEXT-SESSION for
   temporary state.
7. **Tell the owner** in a few lines: what merged, what waits on them (Q-ids, checks), what
   the next session starts with.
