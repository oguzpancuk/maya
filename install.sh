#!/usr/bin/env bash
# maya installer: links global/ into ~/.claude/ so the personal layer follows
# you in every local Claude Code session. Idempotent; never silently
# overwrites — existing real files are backed up first, loudly.
set -euo pipefail

MAYA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"
BACKUP_DIR="${CLAUDE_DIR}/maya-backup-$(date +%Y%m%d-%H%M%S)"

link() { # link <source-in-maya> <target-under-~/.claude>
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mkdir -p "$BACKUP_DIR"
    mv "$dst" "$BACKUP_DIR/$(basename "$dst")"
    echo "  backed up existing $(basename "$dst") -> $BACKUP_DIR/"
  fi
  ln -sfn "$src" "$dst"
  echo "  linked $dst -> $src"
}

echo "maya install: linking global layer into ${CLAUDE_DIR}"
link "$MAYA_DIR/global/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"

for skill in "$MAYA_DIR"/global/skills/*/; do
  name="$(basename "$skill")"
  link "${skill%/}" "$CLAUDE_DIR/skills/$name"
done

for agent in "$MAYA_DIR"/global/agents/*.md; do
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
