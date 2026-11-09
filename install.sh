#!/usr/bin/env bash
# Scaffold the agent workflow into an umbrella folder.
# Writes only files that do not exist yet; existing files are reported and left alone.
# The one exception: an ignore line is appended to an existing .gitignore when missing.
set -euo pipefail

KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage: install.sh --name NAME --slug SLUG --dir UMBRELLA [options]

  --name NAME          Project display name, e.g. "Acme"
  --slug SLUG          Short lowercase id, e.g. acme (planning repo becomes SLUG-planning)
  --dir UMBRELLA       Umbrella folder (created if missing), e.g. ~/projects/acme_project
  --owner NAME         Who answers questions and QAs (default: "the owner")
  --repos LIST         Comma-separated code repo folder names under UMBRELLA (default: SLUG).
                       Existing repos get the missing files added; missing ones are created
                       with git init. Names: letters, digits, dot, dash, underscore.
  --gh-owner OWNER     GitHub user or org for the repos (default: from `gh api user`)
  --merge yes|no|ask   Standing permission for agents to squash-merge on APPROVE + green CI.
                       yes/no are recorded as answered Q-01; ask (default) leaves Q-01 open.
  --local-skills       Also copy skills and agents into UMBRELLA/.claude (use without the plugin)
  --dry-run            Print what would be written, write nothing
EOF
}

NAME="" SLUG="" DIR="" OWNER="the owner" REPOS="" GH_OWNER="" MERGE="ask" LOCAL_SKILLS=0 DRY=0
need() { [[ $# -ge 2 && -n "$2" ]] || { echo "Option $1 needs a value" >&2; usage >&2; exit 2; }; }
while [[ $# -gt 0 ]]; do
  case "$1" in
    --name) need "$@"; NAME="$2"; shift 2 ;;
    --slug) need "$@"; SLUG="$2"; shift 2 ;;
    --dir) need "$@"; DIR="$2"; shift 2 ;;
    --owner) need "$@"; OWNER="$2"; shift 2 ;;
    --repos) need "$@"; REPOS="$2"; shift 2 ;;
    --gh-owner) need "$@"; GH_OWNER="$2"; shift 2 ;;
    --merge) need "$@"; MERGE="$2"; shift 2 ;;
    --local-skills) LOCAL_SKILLS=1; shift ;;
    --dry-run) DRY=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$NAME" && -n "$SLUG" && -n "$DIR" ]] || { usage >&2; exit 2; }
[[ "$SLUG" =~ ^[a-z0-9][a-z0-9-]*$ ]] || { echo "--slug must be lowercase letters, digits and dashes" >&2; exit 2; }
[[ "$MERGE" =~ ^(yes|no|ask)$ ]] || { echo "--merge must be yes, no or ask" >&2; exit 2; }
command -v perl >/dev/null || { echo "perl is required for placeholder filling" >&2; exit 1; }

DIR="${DIR/#\~/$HOME}"
REPOS="${REPOS:-$SLUG}"
PLANNING_DIR="$SLUG-planning"
TODAY="$(date +%F)"
if [[ -z "$GH_OWNER" ]]; then
  GH_OWNER="$(gh api user --jq .login 2>/dev/null || true)"
  if [[ -z "$GH_OWNER" ]]; then
    GH_OWNER="GITHUB-OWNER"
    echo "Warning: gh is not logged in and --gh-owner was not given; files will say GITHUB-OWNER. Replace it later." >&2
  fi
fi

REPO_LIST=()
IFS=',' read -r -a raw_repos <<< "$REPOS"
for r in "${raw_repos[@]}"; do
  r="${r#"${r%%[![:space:]]*}"}"; r="${r%"${r##*[![:space:]]}"}"   # trim
  [[ -z "$r" ]] && continue
  [[ "$r" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ && "$r" != *..* ]] || { echo "Bad repo name: '$r'" >&2; exit 2; }
  REPO_LIST+=("$r")
done
[[ ${#REPO_LIST[@]} -gt 0 ]] || { echo "--repos is empty" >&2; exit 2; }

REPO_ROWS="" REPO_STATE_ROWS=""
for r in "${REPO_LIST[@]}"; do
  REPO_ROWS+="| \`$r/\` | Code repo. See its \`AGENTS.md\` |"$'\n'
  REPO_STATE_ROWS+="| **$r** | | |"$'\n'
done
REPO_ROWS="${REPO_ROWS%$'\n'}"
REPO_STATE_ROWS="${REPO_STATE_ROWS%$'\n'}"

MERGE_TEXT="Standing permission for agents to squash-merge their PRs on an independent APPROVE plus a CI run whose jobs ran and passed"
case "$MERGE" in
  yes)
    MERGE_RULE="(standing permission, Q-01). Before launch, flag legal, pricing, security posture and deploy changes for the owner's final read."
    MERGE_Q="- [x] **Q-01** (answered $TODAY: yes) $MERGE_TEXT." ;;
  no)
    MERGE_RULE="never (Q-01 answered no): list approved PRs with green CI for the owner to merge."
    MERGE_Q="- [x] **Q-01** (answered $TODAY: no, the owner merges) $MERGE_TEXT." ;;
  ask)
    MERGE_RULE="only once the owner answers Q-01 with yes; until then, list approved PRs for the owner to merge."
    MERGE_Q="- [ ] **Q-01** (asked $TODAY) $MERGE_TEXT? Recommendation: yes; legal, pricing, security and deploy changes still get your read before launch." ;;
esac

yaml_escape() { local s="${1//\\/\\\\}"; printf '%s' "${s//\"/\\\"}"; }

export KIT_PROJECT="$NAME" KIT_PROJECT_YAML="$(yaml_escape "$NAME")" KIT_SLUG="$SLUG" \
  KIT_OWNER="$OWNER" KIT_DATE="$TODAY" KIT_PLANNING_DIR="$PLANNING_DIR" \
  KIT_PLANNING_REPO="$GH_OWNER/$PLANNING_DIR" KIT_REPO_ROWS="$REPO_ROWS" \
  KIT_REPO_STATE_ROWS="$REPO_STATE_ROWS" KIT_MERGE_RULE="$MERGE_RULE" KIT_MERGE_Q="$MERGE_Q"

fill() { perl -pe 's/\{\{(\w+)\}\}/exists $ENV{"KIT_$1"} ? $ENV{"KIT_$1"} : $&/ge'; }

written=0 skipped=0
skip() { echo "  skip   $1${2:+ ($2)}"; skipped=$((skipped + 1)); }
note_write() { echo "  write  $1"; written=$((written + 1)); }

# put SRC DEST [raw]: copy (placeholders filled unless raw) when DEST does not exist.
put() {
  local src="$1" dest="$2" raw="${3:-}"
  if [[ -e "$dest" ]]; then skip "$dest" "exists"; return; fi
  note_write "$dest"
  [[ $DRY == 1 ]] && return
  mkdir -p "$(dirname "$dest")"
  if [[ -n "$raw" ]]; then cp "$src" "$dest"; else fill < "$src" > "$dest"; fi
}
# put_text DEST TEXT
put_text() {
  local dest="$1" text="$2"
  if [[ -e "$dest" ]]; then skip "$dest" "exists"; return; fi
  note_write "$dest"
  [[ $DRY == 1 ]] && return
  mkdir -p "$(dirname "$dest")"
  printf '%s\n' "$text" > "$dest"
}
# ignore_line REPO LINE: make sure REPO/.gitignore has LINE (append, never rewrite).
ignore_line() {
  local gi="$1/.gitignore" line="$2"
  if [[ -e "$gi" ]] && grep -qxF "$line" "$gi"; then return; fi
  if [[ -e "$gi" ]]; then echo "  append $gi ($line)"; else note_write "$gi"; fi
  [[ $DRY == 1 ]] && return
  printf '%s\n' "$line" >> "$gi"
}
NEW_REPOS=()
ensure_git() {
  local d="$1"
  [[ -d "$d/.git" ]] && return
  echo "  git    init $d"
  NEW_REPOS+=("$d")
  [[ $DRY == 1 ]] && return
  mkdir -p "$d" && git -C "$d" init -q -b main
}

T="$KIT_ROOT/template"
echo "Umbrella: $DIR"
[[ $DRY == 1 ]] || mkdir -p "$DIR"
put "$T/CLAUDE.md" "$DIR/CLAUDE.md"

echo "Planning repo: $DIR/$PLANNING_DIR"
P="$DIR/$PLANNING_DIR"
ensure_git "$P"
for f in BACKLOG.md NEXT-SESSION.md README.md; do put "$T/planning/$f" "$P/$f"; done
put "$KIT_ROOT/WORKFLOW.md" "$P/WORKFLOW.md" raw
put "$T/planning/pages/questions-template.html" "$P/pages/questions-template.html" raw
put "$T/planning/pages/qa-checklist-template.html" "$P/pages/qa-checklist-template.html" raw
put_text "$P/qa/README.md" $'# QA scripts\n\nScripts the owner runs to test locally (start the stack, seed data, drive a flow).\nKeep secrets and private test data out of git.'
for l in node_modules/ .worktrees/ '*.local.*'; do ignore_line "$P" "$l"; done

for r in "${REPO_LIST[@]}"; do
  R="$DIR/$r"
  echo "Code repo: $R"
  ensure_git "$R"
  if [[ -e "$R/AGENTS.md" ]]; then
    skip "$R/AGENTS.md" "exists; compare it with template/AGENTS.md, the review gate and PR rules live there"
  else
    KIT_REPO="$r" put "$T/AGENTS.md" "$R/AGENTS.md"
  fi
  if [[ -e "$R/CLAUDE.md" ]]; then
    skip "$R/CLAUDE.md" "exists; make sure it points at AGENTS.md"
  else
    put_text "$R/CLAUDE.md" '@AGENTS.md'
  fi
  # GitHub accepts several PR template spellings; add ours only when none exists.
  if { find "$R" "$R/.github" "$R/docs" -maxdepth 1 -iname "pull_request_template.md" 2>/dev/null || true; } | grep -q . \
     || [[ -d "$R/.github/PULL_REQUEST_TEMPLATE" ]]; then
    skip "$R/.github/pull_request_template.md" "a PR template exists already"
  else
    put "$T/repo/.github/pull_request_template.md" "$R/.github/pull_request_template.md"
  fi
  while IFS= read -r -d '' src; do
    rel="${src#"$T/repo/"}"
    [[ "$rel" == .github/pull_request_template.md ]] && continue
    put "$src" "$R/$rel"
  done < <(find "$T/repo" -type f -print0)
  ignore_line "$R" ".worktrees/"
done

if [[ "$MERGE" == yes ]]; then
  if [[ -e "$DIR/.claude/settings.local.json" ]]; then
    skip "$DIR/.claude/settings.local.json" "exists; add \"Bash(gh pr merge:*)\" to permissions.allow yourself"
  else
    put_text "$DIR/.claude/settings.local.json" $'{\n  "permissions": {\n    "allow": ["Bash(gh pr merge:*)"]\n  }\n}'
  fi
fi

if [[ $LOCAL_SKILLS == 1 ]]; then
  echo "Local skills and agents: $DIR/.claude"
  while IFS= read -r -d '' src; do
    put "$src" "$DIR/.claude/skills/${src#"$KIT_ROOT/skills/"}" raw
  done < <(find "$KIT_ROOT/skills" -type f -print0)
  for a in "$KIT_ROOT"/agents/*.md; do put "$a" "$DIR/.claude/agents/$(basename "$a")" raw; done
fi

echo
echo -n "Done: $written written, $skipped skipped"
[[ $DRY == 1 ]] && echo " (dry run, nothing written)." || echo "."

LABELS='for l in found-by-agent follow-up qa security tech-debt; do gh label create "$l" 2>/dev/null || true; done'
echo
echo "Next steps:"
echo "  1. Planning repo on GitHub (private):"
echo "       cd \"$P\" && git add -A && git commit -m \"Planning base plate\" && gh repo create \"$GH_OWNER/$PLANNING_DIR\" --private --source . --push"
step=2
for d in "${NEW_REPOS[@]}"; do
  [[ "$d" == "$P" ]] && continue
  echo "  $step. New code repo $(basename "$d"): first commit and remote (agents branch from origin/main):"
  echo "       cd \"$d\" && git add -A && git commit -m \"Agent workflow base\" && gh repo create \"$GH_OWNER/$(basename "$d")\" --private --source . --push"
  step=$((step + 1))
done
echo "  $step. Labels, in each code repo:  $LABELS"
echo "  $((step + 1)). Fill \"Build and verify\" in each AGENTS.md with real commands."
echo "  $((step + 2)). Make CI skip drafts and run on ready (see \"CI that runs once\" in WORKFLOW.md)."
echo "  $((step + 3)). Start Claude Code in $DIR and fill the backlog with it (skill: new-project, step 3)."
