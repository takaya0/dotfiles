#!/bin/bash
set -euo pipefail

echo "🚀 Starting macOS setup with chezmoi..."

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew is not installed. Please install it first:"
    echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

echo "✅ Homebrew is installed"

# Install chezmoi if not present
if ! command -v chezmoi &> /dev/null; then
    echo "📦 Installing chezmoi..."
    brew install chezmoi
fi

echo "✅ chezmoi is installed"

# Initialize chezmoi with this dotfiles directory
DOTFILES_DIR="$HOME/dotfiles"

if [ ! -d "$DOTFILES_DIR" ]; then
    echo "❌ dotfiles directory not found at $DOTFILES_DIR"
    exit 1
fi

echo "🔧 Initializing chezmoi with source directory: $DOTFILES_DIR"
chezmoi init --source="$DOTFILES_DIR"

echo "🔍 Previewing changes..."
chezmoi diff

echo ""
read -p "Apply the above changes? [y/N] " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "✨ Applying chezmoi configuration..."
    chezmoi apply --verbose
    echo ""
    echo "✅ Configuration applied successfully!"
else
    echo "⏭️  Skipped. Run 'chezmoi apply' manually when ready."
fi

echo ""
echo "Next steps:"
echo "  1. Restart your terminal to apply zsh changes"
echo "  2. Run 'chezmoi apply' to apply future changes"
echo "  3. Check if all config files are properly linked:"
echo "     - ls -la ~/.config/wezterm"
echo "     - ls -la ~/.config/zed"
echo "     - ls -la ~/.claude"
