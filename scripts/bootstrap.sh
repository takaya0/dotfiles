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

echo "🧹 Checking /etc for nix-darwin..."
if [ -e /etc/zshenv ] && [ ! -L /etc/zshenv ]; then
    echo "  - Renaming /etc/zshenv to /etc/zshenv.before-nix-darwin"
    sudo mv /etc/zshenv /etc/zshenv.before-nix-darwin
fi

echo "🧹 Checking /opt/homebrew for nix-homebrew..."
if [ -e /opt/homebrew/Library/Taps ] && [ ! -L /opt/homebrew/Library/Taps ]; then
    echo "  - Renaming /opt/homebrew/Library/Taps to /opt/homebrew/Library/Taps.before-nix-homebrew"
    sudo mv /opt/homebrew/Library/Taps /opt/homebrew/Library/Taps.before-nix-homebrew
fi

echo "🧹 Checking existing zsh dotfiles..."
zsh_dotfiles=(
  "$HOME/.zpreztorc"
  "$HOME/.zshrc"
  "$HOME/.zprofile"
  "$HOME/.zshenv"
  "$HOME/.zlogin"
)
for file in "''${zsh_dotfiles[@]}"; do
  backup="''${file}.before-hm"
  if [ -e "$file" ] && [ ! -L "$file" ] && [ ! -e "$backup" ]; then
    echo "  - Renaming $file to $backup"
    mv "$file" "$backup"
  fi
done

echo "🔧 Building and activating nix-darwin configuration..."
if [ "$(id -u)" -ne 0 ]; then
    sudo -H nix run nix-darwin -- switch --flake .
else
    nix run nix-darwin -- switch --flake .
fi

echo "✨ Configuration applied successfully!"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal to apply zsh changes"
echo "  2. Run 'sudo darwin-rebuild switch --flake .' to apply future changes"
echo "  3. Check if all config files are properly linked:"
echo "     - ls -la ~/.config/wezterm"
echo "     - ls -la ~/.config/zed"
echo "     - ls -la ~/.claude"
