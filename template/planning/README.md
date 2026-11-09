# {{PROJECT}} planning

Planning files for {{PROJECT}}, shared by local and cloud Claude/Codex sessions. The code
lives in separate repos, siblings of this one under the umbrella folder.

- `BACKLOG.md` is the source of truth: milestones, the human track (H), agent lanes (A), and
  the open and answered questions with stable ids (Q-NN).
- `NEXT-SESSION.md` is the temporary agenda: where the last session stopped.
- `WORKFLOW.md` is the playbook: how sessions, agents, reviews and hand-offs work, and why.
- The `*.html` pages are question pages, QA checklists, prototypes and explainers. A question
  page is frozen once the owner starts answering it.
- `qa/` holds scripts the owner runs to test locally.

## Rules for every session (local or cloud)

- Work a session finds but does not finish goes to a GitHub issue in the repo it belongs
  to, so any session, including a cloud session started from a phone, can pick it up.
  BACKLOG lines link the issue.
- Ask {{OWNER}} questions with stable Q-ids, never bare numbers; record answers in BACKLOG.
- Edits here are small and targeted, never rewrites; several agents edit in parallel.
  Commit straight to `main` with a short message.
- Code changes go through draft PRs, an independent reviewer comment whose first line is
  `Independent review: APPROVE`, then `gh pr ready` for the one CI run, then squash-merge.
  Details in each repo's AGENTS.md.
- Agents never run live infrastructure writes; they dry-run and hand {{OWNER}} the command.
- Plain language, no em dashes.
