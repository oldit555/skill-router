#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Uninstalling Skill Router..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Remove files
rm -f ~/.claude/CLAUDE.md
rm -f ~/.claude/skill-catalog.yaml
rm -f ~/.claude/hooks/user-prompt-submit.sh
rm -f ~/.claude/bin/regenerate-catalog
rm -f ~/.claude/bin/update-project-profile
rm -rf ~/.claude/projects

echo "✓ Removed Skill Router files"

# Remove aliases from shell config (zshrc, bashrc, or profile)
for SHELL_RC in ~/.zshrc ~/.bashrc ~/.bash_profile ~/.profile; do
  if [[ -f "$SHELL_RC" ]] && grep -q "# Skill Router aliases" "$SHELL_RC"; then
    # Remove the entire aliases block (from marker to closing brace of last function)
    sed '/# Skill Router aliases/,/^}$/d' "$SHELL_RC" > "$SHELL_RC.tmp"
    mv "$SHELL_RC.tmp" "$SHELL_RC"
    echo "✓ Removed aliases from $SHELL_RC"
  fi
done

# Remove hook from settings.json
SETTINGS_FILE="$HOME/.claude/settings.json"
if [[ -f "$SETTINGS_FILE" ]] && grep -q "user-prompt-submit.sh" "$SETTINGS_FILE" 2>/dev/null; then
  if command -v jq &> /dev/null; then
    jq '.hooks.UserPromptSubmit = [.hooks.UserPromptSubmit[] | select(.hooks | all(.command | contains("user-prompt-submit.sh") | not))]' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
    mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    echo "✓ Removed hook from settings.json"
  else
    echo "⚠ jq not found - please manually remove hook from settings.json"
  fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Skill Router uninstalled"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
