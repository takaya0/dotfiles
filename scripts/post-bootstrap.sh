#!/bin/bash
# mise bootstrap の最後に [tasks.bootstrap] から実行される追加セットアップ。
# bootstrap のたびに実行されるので、各処理はインストール済みならスキップする。
set -euo pipefail

DOTFILES_DIR="$HOME/dotfiles"

# bun（Codex CLI のインストールに使う）などのグローバル [tools] が入っていることを保証する。
# 通常は bootstrap の tools ステップで入っているので何もしない
echo "Installing mise tools..."
mise install --yes

# Claude Code（ネイティブインストーラ）
if ! command -v claude &>/dev/null; then
  echo "Installing Claude Code..."
  curl -fsSL https://claude.ai/install.sh | bash
fi

# Rust（rustup）。PATH は ~/.zshenv で ~/.cargo/env を読み込んでいるので rc ファイルは書き換えさせない
if ! command -v rustup &>/dev/null && [ ! -x "$HOME/.cargo/bin/rustup" ]; then
  echo "Installing Rust..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
fi

# Codex CLI（bun 経由）
if ! command -v codex &>/dev/null && [ ! -x "$HOME/.bun/bin/codex" ]; then
  echo "Installing Codex CLI..."
  mise exec -- bun add -g @openai/codex
fi

# VS Code 拡張
CODE_BIN=""
if command -v code &>/dev/null; then
  CODE_BIN="code"
elif [ -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]; then
  CODE_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
fi

if [ -n "$CODE_BIN" ]; then
  installed="$("$CODE_BIN" --list-extensions | tr '[:upper:]' '[:lower:]')"
  while IFS= read -r ext; do
    [ -z "$ext" ] && continue
    if ! grep -qxF "$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')" <<<"$installed"; then
      echo "Installing VS Code extension: $ext"
      "$CODE_BIN" --install-extension "$ext" >/dev/null 2>&1 || echo "  failed: $ext"
    fi
  done <"$DOTFILES_DIR/scripts/vscode-extensions.txt"
else
  echo "VS Code not found, skipping extension installation."
fi
