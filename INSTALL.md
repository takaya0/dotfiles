# インストール手順

## 前提条件

- macOS (Apple Silicon)
- sudo権限

## ワンライナーセットアップ（新規マシン）

ターミナルを開いて以下を実行するだけです:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/takaya0/dotfiles/main/scripts/bootstrap.sh)
```

以下が自動で実行されます:
1. Xcode Command Line Tools のインストール
2. Homebrew のインストール
3. dotfiles リポジトリを `~/dotfiles` にクローン
4. chezmoi のインストール
5. 適用予定の変更を表示 → 確認後 `chezmoi apply` を実行

### chezmoi apply で自動インストールされるもの

- Homebrew パッケージ（CLI ツール）・Cask（GUI アプリ）
- mise（言語ランタイムマネージャ）と全ランタイム（bun, node, python, ruby 等）
- Claude Code
- Codex CLI（bun 経由）
- VS Code / Cursor 拡張機能
- macOS デフォルト設定（初回のみ）
- Prezto（zsh フレームワーク）

## clone 済みの場合

```bash
~/dotfiles/scripts/bootstrap.sh
```

## インストール後

ターミナルを再起動してシェル設定を反映してください:

```bash
exec zsh
```

## 設定の更新

dotfiles を変更した後は:

```bash
chezmoi apply
```

差分を事前確認したい場合:

```bash
chezmoi diff
chezmoi apply
```

## 検証

```bash
# 設定ファイルの確認
ls -la ~/.config/wezterm/ ~/.config/zed/ ~/.config/karabiner/ ~/.config/mise/ ~/.claude/

# Homebrew パッケージの確認
which rg fd bat eza zoxide fzf delta jq yq gh mise

# Git 設定の確認
git config --global user.name
git config --global user.email
```

## トラブルシューティング

### chezmoi apply が失敗する

```bash
chezmoi apply --verbose
```

### Homebrew パッケージが足りない

`.chezmoidata.yaml` の `brews` または `casks` にパッケージ名を追加して再適用:

```bash
chezmoi apply
```

### Prezto が読み込まれない

```bash
chezmoi update
```
