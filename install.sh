#!/bin/bash
set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Check if already installed
if [[ -f "$CLAUDE_DIR/hooks/user-prompt-submit.sh" ]]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Skill Router is already installed."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Reinstall will:"
  echo ""
  echo "  Backup (if exists):"
  echo "    ~/.claude/CLAUDE.md → CLAUDE.md.backup.{timestamp}"
  echo ""
  echo "  Overwrite:"
  echo "    ~/.claude/CLAUDE.md"
  echo "    ~/.claude/skill-overrides.yaml"
  echo "    ~/.claude/hooks/user-prompt-submit.sh"
  echo "    ~/.claude/bin/regenerate-catalog"
  echo "    ~/.claude/bin/regenerate-project-profile"
  echo ""
  read -p "Proceed with reinstall? [y/N] " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
  fi
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Installing Skill Router..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create directories
mkdir -p "$CLAUDE_DIR/hooks"
mkdir -p "$CLAUDE_DIR/bin"
mkdir -p "$CLAUDE_DIR/projects"

# Backup existing CLAUDE.md if exists and not empty
if [[ -f "$CLAUDE_DIR/CLAUDE.md" ]] && [[ -s "$CLAUDE_DIR/CLAUDE.md" ]]; then
  echo ""
  echo "Found existing CLAUDE.md ($(wc -l < "$CLAUDE_DIR/CLAUDE.md") lines)"
  read -p "Create backup before overwriting? [Y/n] " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    BACKUP_FILE="$CLAUDE_DIR/CLAUDE.md.backup.$(date +%s)"
    cp "$CLAUDE_DIR/CLAUDE.md" "$BACKUP_FILE"
    echo "✓ Backed up to: $BACKUP_FILE"
  else
    echo "✓ Skipped backup"
  fi
fi

# Copy files
cp "$SCRIPT_DIR/files/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
cp "$SCRIPT_DIR/files/skill-overrides.yaml" "$CLAUDE_DIR/skill-overrides.yaml"
cp "$SCRIPT_DIR/files/hooks/user-prompt-submit.sh" "$CLAUDE_DIR/hooks/"
cp "$SCRIPT_DIR/files/bin/regenerate-catalog" "$CLAUDE_DIR/bin/"
cp "$SCRIPT_DIR/files/bin/regenerate-project-profile" "$CLAUDE_DIR/bin/"

echo "✓ Copied files to ~/.claude/"

# Make scripts executable
chmod +x "$CLAUDE_DIR/hooks/user-prompt-submit.sh"
chmod +x "$CLAUDE_DIR/bin/regenerate-catalog"
chmod +x "$CLAUDE_DIR/bin/regenerate-project-profile"

echo "✓ Made scripts executable"

# Update settings.json with hook config
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
HOOK_COMMAND="\$HOME/.claude/hooks/user-prompt-submit.sh"

if [[ -f "$SETTINGS_FILE" ]]; then
  # Check if hook already exists
  if grep -q "user-prompt-submit.sh" "$SETTINGS_FILE" 2>/dev/null; then
    echo "✓ Hook already configured in settings.json"
  else
    # Need to add hook - requires jq for safe JSON manipulation
    if command -v jq &> /dev/null; then
      jq '.hooks.UserPromptSubmit += [{"hooks": [{"type": "command", "command": "$HOME/.claude/hooks/user-prompt-submit.sh"}]}]' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
      mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
      echo "✓ Added hook to settings.json"
    else
      echo "⚠ jq not found - please manually add hook to settings.json"
      echo "  See README.md for manual configuration"
    fi
  fi
else
  # Create new settings.json
  cat > "$SETTINGS_FILE" << 'SETTINGS'
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/hooks/user-prompt-submit.sh"
          }
        ]
      }
    ]
  }
}
SETTINGS
  echo "✓ Created settings.json with hook"
fi

# Add aliases to ~/.zshrc
ZSHRC="$HOME/.zshrc"

# Check if aliases already exist (by function name)
if grep -q "claude-update-plugins()" "$ZSHRC" 2>/dev/null; then
  echo "✓ Aliases already in ~/.zshrc"
else
  cat >> "$ZSHRC" << 'ALIASES'

# Skill Router aliases
claude-update-plugins() {
  echo "📦 Updating marketplaces..."
  for dir in ~/.claude/plugins/marketplaces/*/; do
    echo "  → $(basename "$dir")"
    git -C "$dir" pull
  done
  echo "🔄 Regenerating skill catalog..."
  ~/.claude/bin/regenerate-catalog
  echo "🗑️  Clearing plugin cache..."
  rm -rf ~/.claude/plugins/cache 2>/dev/null
  mkdir -p ~/.claude/plugins/cache
  echo "✅ Done! Restart Claude Code to load updated plugins."
}

claude-refresh-project() {
  ~/.claude/bin/regenerate-project-profile "${1:-.}"
}
ALIASES
  echo "✓ Added aliases to ~/.zshrc"
fi

# Source zshrc
source "$ZSHRC" 2>/dev/null || true

# Run initial catalog generation
echo ""
echo "📦 Running initial plugin update..."
if [[ -d "$CLAUDE_DIR/plugins/marketplaces" ]]; then
  ~/.claude/bin/regenerate-catalog
  echo "✓ Skill catalog generated"
else
  echo "⚠ No plugins installed yet. Run 'claude-update-plugins' after installing plugins."
fi

# Show welcome message
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Skill Router installed successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "HOW IT WORKS"
echo ""
echo "  1. You type a prompt"
echo "  2. Hook analyzes keywords → outputs hints"
echo "  3. Claude does semantic matching → suggests skills/agents"
echo "  4. You confirm → Claude activates and works"
echo ""
echo "  First prompt in a new project auto-generates ~/.claude/projects/{name}.yaml:"
echo ""
echo "    project:"
echo "      name: my-app"
echo "      type: mobile"
echo ""
echo "    detected:"
echo "      stack: [expo, react-native, typescript]"
echo ""
echo "    skill_boosts:"
echo "      mobile-developer: +3"
echo "      frontend-developer: +1"
echo ""
echo "  Hook catches obvious signals, Claude handles the rest from installed skills."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "COMMANDS"
echo ""
echo "  claude-update-plugins    Update plugins + regenerate skill catalog"
echo "  claude-refresh-project   Regenerate project profile (only if project type changed)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "NEXT STEPS"
echo ""
echo "  1. Restart terminal (or: source ~/.zshrc)"
echo "  2. Start Claude in any project"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
