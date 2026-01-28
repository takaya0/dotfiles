#!/bin/bash
set -euo pipefail

echo "🚀 Starting macOS configuration with Nix..."

# Check if Nix is installed
if ! command -v nix &> /dev/null; then
    echo "❌ Nix is not installed. Please install it first:"
    echo "   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install"
    exit 1
fi

echo "✅ Nix is installed"

# Navigate to dotfiles directory
DOTFILES_DIR="$HOME/dotfiles"
cd "$DOTFILES_DIR"

echo "📦 Updating flake lock..."
nix flake update

echo "🔧 Building and activating nix-darwin configuration..."
nix run nix-darwin -- switch --flake .

echo "✨ Configuration applied successfully!"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal to apply zsh changes"
echo "  2. Run 'darwin-rebuild switch --flake .' to apply future changes"
echo "  3. Check if all config files are properly linked:"
echo "     - ls -la ~/.config/wezterm"
echo "     - ls -la ~/.config/zed"
echo "     - ls -la ~/.claude"
