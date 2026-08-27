#!/usr/bin/env bash
# maya installer: puts the global layer into ~/.claude/ for local Claude Code
# sessions. Skills and agents are symlinked (edits in maya apply instantly);
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

for agent in "$MAYA_DIR"/global/agents/*.md; do
  [ -f "$agent" ] || continue
  link "$agent" "$CLAUDE_DIR/agents/$(basename "$agent")"
done

echo ""
echo "Done. Remaining manual steps (one-time, inside any Claude Code session):"
echo "  /plugin install code-review@claude-plugins-official"
echo "  /plugin install commit-commands@claude-plugins-official"
echo "  /plugin install security-guidance@claude-plugins-official"
echo "  /plugin install typescript-lsp@claude-plugins-official"
echo "     (typescript-lsp also needs: npm i -g typescript-language-server typescript)"
echo ""
echo "Check the per-plugin 'Context cost' shown in /plugin before confirming."
echo "Cloud/remote sessions do NOT read ~/.claude — for those, the product repo's"
echo "own .claude/ (from template/) is what carries the setup."
