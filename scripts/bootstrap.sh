#!/bin/bash
set -euo pipefail

# ==============================================================
# bootstrap.sh - macOS 環境構築スクリプト
#
# 使い方（新規マシン）:
#   bash <(curl -fsSL https://raw.githubusercontent.com/takaya0/dotfiles/main/scripts/bootstrap.sh)
#
# 使い方（clone 済み）:
#   ~/dotfiles/scripts/bootstrap.sh
# ==============================================================

DOTFILES_REPO="https://github.com/takaya0/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"

# ------ ヘルパー関数 ------

info() { printf '  [ .. ] %s\n' "$1"; }
ok()   { printf '  [ OK ] %s\n' "$1"; }

# ------ Phase 1: Xcode Command Line Tools ------

install_xcode_clt() {
  if xcode-select -p &>/dev/null; then
    ok "Xcode Command Line Tools はインストール済みです"
    return
  fi
  info "Xcode Command Line Tools をインストールします..."
  info "ダイアログが表示されたら「インストール」をクリックしてください"
  xcode-select --install
  until xcode-select -p &>/dev/null; do
    sleep 5
  done
  ok "Xcode Command Line Tools をインストールしました"
}

# ------ Phase 2: Homebrew ------

install_homebrew() {
  if command -v brew &>/dev/null; then
    ok "Homebrew はインストール済みです"
    # 既存インストールでも PATH を確実に通す
    eval "$(/opt/homebrew/bin/brew shellenv)"
    return
  fi
  info "Homebrew をインストールします..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
  ok "Homebrew をインストールしました"
}

# ------ Phase 3: dotfiles clone ------

clone_dotfiles() {
  if [ -d "$DOTFILES_DIR" ]; then
    ok "dotfiles は $DOTFILES_DIR に存在します"
    return
  fi
  info "dotfiles リポジトリをクローンします..."
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  ok "dotfiles を $DOTFILES_DIR にクローンしました"
}

# ------ Phase 4: chezmoi ------

install_chezmoi() {
  if command -v chezmoi &>/dev/null; then
    ok "chezmoi はインストール済みです"
    return
  fi
  info "chezmoi をインストールします..."
  brew install chezmoi
  ok "chezmoi をインストールしました"
}

# ------ Phase 5: chezmoi 適用 ------

apply_chezmoi() {
  info "chezmoi を初期化します..."
  chezmoi init --source="$DOTFILES_DIR"

  info "適用予定の変更を表示します..."
  chezmoi diff || true

  echo ""
  read -p "上記の変更を適用しますか？ [y/N] " -n 1 -r
  echo ""

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    info "設定を適用します..."
    chezmoi apply --verbose
    ok "設定の適用が完了しました"
  else
    info "スキップしました。後で 'chezmoi apply' を実行してください。"
  fi
}

# ------ メイン ------

main() {
  echo ""
  echo "========================================="
  echo "  macOS dotfiles セットアップ"
  echo "========================================="
  echo ""

  install_xcode_clt
  install_homebrew
  clone_dotfiles
  install_chezmoi
  apply_chezmoi

  echo ""
  echo "完了！シェルの変更を反映するにはターミナルを再起動してください:"
  echo "  exec zsh"
  echo ""
}

main
