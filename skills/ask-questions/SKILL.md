---
name: ask-questions
description: Hand open questions to the owner with stable Q-ids, recorded in BACKLOG.md, and (for more than one or two, or any that need context) an autosaving question page with an explainer per question and the recommendation preselected. Use whenever you need a decision from the owner.
---

# Ask questions

The owner answers from the page alone, without the files or your context. Write for that.

## Ids and backlog

1. Next id: highest `Q-NN` in BACKLOG.md plus one. Ids are never reused.
2. Add each question under "Open questions (Q-ids)":
   `- [ ] **Q-NN** (asked YYYY-MM-DD, page: <file>.html) Question. Options (a) ..., (b) .... Recommendation: (a).`
3. Refer to questions by id everywhere. Never ask with a bare numbered list.
4. Commit and push the planning repo.

One or two simple questions can go straight in chat, still with ids.

## The page

Copy `pages/questions-template.html` from the planning repo (if missing, it is in this
plugin at `template/planning/pages/`) to `<planning>/questions-YYYY-MM-DD.html` (add a
letter for a second page that day). Fill `PAGE` and `QUESTIONS`:

- **Explainer per question, 2 to 4 sentences:** what the thing is, where it lives, what the
  problem is, why it matters to the owner. A page with only titles and options leaves
  questions unanswerable.
- **Options with a one-line trade-off each.** Two to four options.
- **`rec` set on every question.** The recommendation arrives preselected; unticked boxes
  read as "no recommendation" and get skipped.
- **A note field on every question** (the template adds it). Tell the owner to use it:
  conditions and "yes, but" thoughts often carry the real decision.
- Group by topic; put the one that unblocks building first.
- A new, unique `PAGE.key`.

Publish it (an Artifact page if available, otherwise tell the owner the file path to open)
and say plainly: **"Stable, start answering."**

## Freeze

Once the owner may have started answering, **never republish that page**: a republish wipes
their in-progress answers. New or changed questions go on a new page.

## Answers

The owner pastes lines like `Q-07: (b) ... | note`. For each: mark `[x]` in BACKLOG with the
date, the choice and the note in their words. Carry the decision into what it shapes: the
ADR (`Decided with: Q-..`), the implementer brief (list decided Q-ids so agents don't
reopen them), the issue or PR body. Anything still open stays open and goes under "Unanswered, carried over"
in NEXT-SESSION.md at session end.

## When a question is really a design

If the choice needs the owner to see or click something (a flow, a layout, an interaction),
build an interactive prototype instead and put the Q-ids on it. Update the DOM in place,
keyed; never re-render on a timer. Big themes get a discussion session, not only Q-ids.
