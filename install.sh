#!/usr/bin/env bash
# maya installer: puts the global layer into ~/.claude/ for local Claude Code
# sessions. Skills are symlinked (edits in maya apply instantly);
# CLAUDE.md is COPIED, because desktop Cowork sessions skip a symlinked
# ~/.claude/CLAUDE.md — re-run this script after editing it in maya.
# Idempotent; never silently overwrites — existing real files are backed up.
set -euo pipefail

MAYA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"
BACKUP_DIR="${CLAUDE_DIR}/maya-backup-$(date +%Y%m%d-%H%M%S)"

backup_if_real() { # backup_if_real <path>  (real file/dir, not our artifact)
  local dst="$1"
  if [ -e "$dst" ] && [ ! -L "$dst" ] && [ ! -f "$dst.maya-managed" ]; then
    mkdir -p "$BACKUP_DIR"
    mv "$dst" "$BACKUP_DIR/$(basename "$dst")"
    echo "  backed up existing $(basename "$dst") -> $BACKUP_DIR/"
  fi
}

link() { # link <source-in-maya> <target-under-~/.claude>
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  backup_if_real "$dst"
  ln -sfn "$src" "$dst"
  echo "  linked $dst -> $src"
}

echo "maya install: global layer -> ${CLAUDE_DIR}"

# CLAUDE.md: copy (see header). A marker file tags it as maya-managed so
# re-runs update it without backing our own copy up.
mkdir -p "$CLAUDE_DIR"
backup_if_real "$CLAUDE_DIR/CLAUDE.md"
cp "$MAYA_DIR/global/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
touch "$CLAUDE_DIR/CLAUDE.md.maya-managed"
echo "  copied CLAUDE.md (re-run install.sh after editing it in maya)"

for skill in "$MAYA_DIR"/global/skills/*/; do
  [ -d "$skill" ] || continue
  link "${skill%/}" "$CLAUDE_DIR/skills/$(basename "$skill")"
done

# Prune links left by components deleted from maya (a removed skill or
# agent): only symlinks pointing into THIS checkout that no longer resolve.
prune() {
  local dir="$1" l
  [ -d "$dir" ] || return 0
  for l in "$dir"/*; do
    [ -L "$l" ] || continue
    case "$(readlink "$l")" in
      "$MAYA_DIR"/*) [ -e "$l" ] || { rm "$l"; echo "  pruned stale $(basename "$l")"; } ;;
    esac
  done
}
prune "$CLAUDE_DIR/skills"
prune "$CLAUDE_DIR/agents"

echo ""
echo "Done. Installed: /new-product, /integrate-product, /update-stack, /spec, /mvp-scope, /release-notes."
echo ""
echo "Cloud sessions and project threads do NOT read ~/.claude — for those,"
echo "the product repo's own CLAUDE.md and .claude/ (from template/) is what"
echo "carries the setup."
