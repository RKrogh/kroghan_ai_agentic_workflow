#!/usr/bin/env bash
# Scaffold the agent workflow into an umbrella folder.
# Writes only files that do not exist yet; existing files are reported and left alone.
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
                       Existing repos get the files added; missing ones are created with git init.
  --gh-owner OWNER     GitHub user or org for the planning repo (default: from `gh api user`, else OWNER)
  --merge yes|no       Standing permission for agents to squash-merge on APPROVE + green CI (default: no)
  --local-skills       Also copy skills and agents into UMBRELLA/.claude (for use without the plugin)
  --dry-run            Print what would be written, write nothing
EOF
}

NAME="" SLUG="" DIR="" OWNER="the owner" REPOS="" GH_OWNER="" MERGE="no" LOCAL_SKILLS=0 DRY=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --name) NAME="$2"; shift 2 ;;
    --slug) SLUG="$2"; shift 2 ;;
    --dir) DIR="$2"; shift 2 ;;
    --owner) OWNER="$2"; shift 2 ;;
    --repos) REPOS="$2"; shift 2 ;;
    --gh-owner) GH_OWNER="$2"; shift 2 ;;
    --merge) MERGE="$2"; shift 2 ;;
    --local-skills) LOCAL_SKILLS=1; shift ;;
    --dry-run) DRY=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$NAME" && -n "$SLUG" && -n "$DIR" ]] || { usage >&2; exit 2; }
[[ "$SLUG" =~ ^[a-z0-9][a-z0-9-]*$ ]] || { echo "--slug must be lowercase letters, digits and dashes" >&2; exit 2; }
[[ "$MERGE" == yes || "$MERGE" == no ]] || { echo "--merge must be yes or no" >&2; exit 2; }
command -v perl >/dev/null || { echo "perl is required for placeholder filling" >&2; exit 1; }

DIR="${DIR/#\~/$HOME}"
REPOS="${REPOS:-$SLUG}"
PLANNING_DIR="$SLUG-planning"
if [[ -z "$GH_OWNER" ]]; then
  GH_OWNER="$(gh api user --jq .login 2>/dev/null || true)"
  GH_OWNER="${GH_OWNER:-OWNER}"
fi

IFS=',' read -r -a REPO_LIST <<< "$REPOS"
REPO_ROWS=""
for r in "${REPO_LIST[@]}"; do
  REPO_ROWS+="| \`$r/\` | Code repo. See its \`AGENTS.md\` |"$'\n'
done
REPO_ROWS="${REPO_ROWS%$'\n'}"

if [[ "$MERGE" == yes ]]; then
  MERGE_RULE="(standing permission, recorded as Q-01 in BACKLOG). Before launch, flag legal, pricing, security posture and deploy changes for the owner's final read."
else
  MERGE_RULE="only once the owner answers Q-01 with yes; until then, list approved PRs for the owner to merge."
fi

if [[ "$MERGE" == yes ]]; then
  MERGE_Q="- [x] **Q-01** (answered $(date +%F): yes) Standing permission for agents to squash-merge their PRs on an independent APPROVE plus a CI run whose jobs ran and passed."
else
  MERGE_Q="- [ ] **Q-01** (asked $(date +%F)) Standing permission for agents to squash-merge their PRs on an independent APPROVE plus a CI run whose jobs ran and passed? Recommendation: yes; legal, pricing, security and deploy changes still get your read before launch."
fi

export KIT_PROJECT="$NAME" KIT_SLUG="$SLUG" KIT_OWNER="$OWNER" KIT_DATE="$(date +%F)" \
  KIT_PLANNING_DIR="$PLANNING_DIR" KIT_PLANNING_REPO="$GH_OWNER/$PLANNING_DIR" \
  KIT_REPO_ROWS="$REPO_ROWS" KIT_MERGE_RULE="$MERGE_RULE" KIT_MERGE_Q="$MERGE_Q"

fill() { perl -pe 's/\{\{(\w+)\}\}/exists $ENV{"KIT_$1"} ? $ENV{"KIT_$1"} : $&/ge'; }

written=0 skipped=0
# put SRC DEST: copy with placeholders filled, unless DEST exists.
put() {
  local src="$1" dest="$2"
  if [[ -e "$dest" ]]; then
    echo "  skip   $dest (exists)"; skipped=$((skipped + 1)); return
  fi
  echo "  write  $dest"; written=$((written + 1))
  [[ $DRY == 1 ]] && return
  mkdir -p "$(dirname "$dest")"
  fill < "$src" > "$dest"
}
ensure_git() {
  local d="$1"
  [[ -d "$d/.git" ]] && return
  echo "  git    init $d"
  [[ $DRY == 1 ]] && return
  mkdir -p "$d" && git -C "$d" init -q -b main
}

T="$KIT_ROOT/template"
echo "Umbrella: $DIR"
[[ $DRY == 1 ]] || mkdir -p "$DIR"
put "$T/CLAUDE.md" "$DIR/CLAUDE.md"

echo "Planning repo: $DIR/$PLANNING_DIR"
ensure_git "$DIR/$PLANNING_DIR"
P="$DIR/$PLANNING_DIR"
for f in BACKLOG.md NEXT-SESSION.md README.md; do put "$T/planning/$f" "$P/$f"; done
put "$KIT_ROOT/WORKFLOW.md" "$P/WORKFLOW.md"
put "$T/planning/pages/questions-template.html" "$P/pages/questions-template.html"
put "$T/planning/pages/qa-checklist-template.html" "$P/pages/qa-checklist-template.html"
if [[ ! -e "$P/qa/README.md" ]]; then
  echo "  write  $P/qa/README.md"; written=$((written + 1))
  [[ $DRY == 1 ]] || { mkdir -p "$P/qa"; printf '# QA scripts\n\nScripts the owner runs to test locally (start the stack, seed data, place a test order).\nKeep secrets and private test data out of git.\n' > "$P/qa/README.md"; }
fi
if [[ ! -e "$P/.gitignore" ]]; then
  echo "  write  $P/.gitignore"; written=$((written + 1))
  [[ $DRY == 1 ]] || printf 'node_modules/\n.claude/worktrees/\n*.local.*\n' > "$P/.gitignore"
fi

for r in "${REPO_LIST[@]}"; do
  R="$DIR/$r"
  echo "Code repo: $R"
  ensure_git "$R"
  KIT_REPO="$r" put "$T/AGENTS.md" "$R/AGENTS.md"
  if [[ ! -e "$R/CLAUDE.md" ]]; then
    echo "  write  $R/CLAUDE.md"; written=$((written + 1))
    [[ $DRY == 1 ]] || printf '@AGENTS.md\n' > "$R/CLAUDE.md"
  else
    echo "  skip   $R/CLAUDE.md (exists; make sure it points at AGENTS.md)"; skipped=$((skipped + 1))
  fi
  while IFS= read -r -d '' src; do
    put "$src" "$R/${src#"$T/repo/"}"
  done < <(find "$T/repo" -type f -print0)
done

if [[ "$MERGE" == yes ]]; then
  if [[ ! -e "$DIR/.claude/settings.local.json" ]]; then
    echo "  write  $DIR/.claude/settings.local.json (allow gh pr merge)"; written=$((written + 1))
    [[ $DRY == 1 ]] || { mkdir -p "$DIR/.claude"; printf '{\n  "permissions": {\n    "allow": ["Bash(gh pr merge:*)"]\n  }\n}\n' > "$DIR/.claude/settings.local.json"; }
  else
    echo "  skip   $DIR/.claude/settings.local.json (exists; add \"Bash(gh pr merge:*)\" to permissions.allow yourself)"; skipped=$((skipped + 1))
  fi
fi

if [[ $LOCAL_SKILLS == 1 ]]; then
  echo "Local skills and agents: $DIR/.claude"
  while IFS= read -r -d '' src; do
    put "$src" "$DIR/.claude/skills/${src#"$KIT_ROOT/skills/"}"
  done < <(find "$KIT_ROOT/skills" -type f -print0)
  for a in "$KIT_ROOT"/agents/*.md; do put "$a" "$DIR/.claude/agents/$(basename "$a")"; done
fi

echo
echo "Done: $written written, $skipped skipped${DRY:+}$([[ $DRY == 1 ]] && echo ' (dry run, nothing written)')."
cat <<EOF

Next steps:
  1. Create the private planning repo on GitHub:
       cd "$P" && git add -A && git commit -m "Planning base plate" \\
         && gh repo create "$GH_OWNER/$PLANNING_DIR" --private --source . --push
  2. Labels in each code repo:  gh label create found-by-agent; gh label create follow-up; gh label create qa
  3. Fill "Build and verify" in each AGENTS.md with real commands.
  4. Start Claude Code in $DIR and ask it to fill the backlog with you (skill: new-project, step 3).
EOF
