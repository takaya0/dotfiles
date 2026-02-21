#!/bin/bash
set -euo pipefail

echo "Configuring macOS defaults..."

# Dock
defaults write com.apple.dock autohide -bool false
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock mru-spaces -bool false

# Finder
defaults write com.apple.finder AppleShowAllExtensions -bool true
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.finder QuitMenuItem -bool true

# NSGlobalDomain
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# Apply changes
killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true

echo "macOS defaults configured successfully."
