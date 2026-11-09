---
name: qa-handoff
description: Hand merged work to the owner for manual QA as an autosaving Pass/Fail/Skip checklist page, then read the results back and file issues for the fails. Use after a batch of merges the owner should try, or when the owner asks "what should I test?".
---

# QA hand-off

## Build the checklist

Copy `pages/qa-checklist-template.html` from the planning repo (if it is missing there, it is
in the kit at `template/planning/pages/`: two folders up from this skill's base directory) to `<planning>/qa-YYYY-MM-DD.html`. Fill the `<title>` and:

- `SETUP`: the exact commands to get the local stack into the right state (pull, restart,
  secrets on, seed data). Copy-pasteable. A `qa/` script in the planning repo beats a long
  list.
- `AREAS`: one per feature area, each with an id prefix (`SIGNUP`, `EDITOR`). One item per
  thing to try: a concrete action, then what the owner should see. Pull the steps from the
  PR bodies of what merged. Note which PR an item tests if it is not on `main` yet.
- `NOT_BUILT`: known gaps, so they are not filed as bugs.

Publish it and say **"Stable, start marking."** Never republish it once the owner has
started; a retest goes on a new page. Add "QA page, N items" under "Owner to check" in
NEXT-SESSION.md.

## Read the results

The owner pastes lines like `EDITOR-3: FAIL | the save button is hidden on a phone`.

- Each FAIL: reproduce if you can, then file a GitHub issue (bug template headings in the body,
  labels `bug,found-by-agent,qa` passed explicitly), or attach to an existing one. Link it in BACKLOG.
- A FAIL that is really a design problem (the owner could not find something, expected a
  different flow) becomes a design proposal, not a bug fix.
- SKIP with a note: a pending check; carry it in NEXT-SESSION.md.
- Report back: N pass, N fail (issue links), N skipped, and what you propose to fix first.
