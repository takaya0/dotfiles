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
4. mise のインストール（`~/.local/bin/mise`）
5. `~/.config/mise/conf.d/bootstrap.toml` をリポジトリにリンク
6. 適用予定の変更を表示 → 確認後 `mise bootstrap` を実行

### mise bootstrap で自動適用されるもの

- dotfiles（`home/` 配下 → `~`）
- Prezto（zsh フレームワーク）
- Homebrew パッケージ（CLI ツール）・Cask（GUI アプリ）
- macOS デフォルト設定
- mise の言語ランタイム（bun, node, python, ruby 等）
- Claude Code / Rust / Codex CLI / VS Code 拡張機能（`scripts/post-bootstrap.sh`）

## clone 済みの場合

```bash
~/dotfiles/scripts/bootstrap.sh
```

## インストール後

ターミナルを再起動してシェル設定を反映してください:

```bash
exec zsh
```

Dock / Finder の設定は再起動後に反映されます:

```bash
killall Dock Finder
```

## 設定の更新

dotfiles を変更した後は:

```bash
mise bootstrap
```

差分を事前確認したい場合:

```bash
mise bootstrap --dry-run
mise bootstrap status
```

`mise bootstrap` はカレントディレクトリの `mise.toml` に書かれた `[bootstrap]` 定義も合わせて適用するため、`~` など他プロジェクトの外で実行してください。

## 検証

```bash
# dotfiles の状態確認
mise dot status

# 設定ファイルの確認
ls -la ~/.config/wezterm/ ~/.config/zed/ ~/.config/karabiner/ ~/.config/mise/ ~/.claude/

# パッケージの確認
mise bootstrap packages status

# Git 設定の確認
git config --global user.name
git config --global user.email
```

## トラブルシューティング

### mise bootstrap が失敗する

```bash
mise bootstrap --verbose
```

### 既存ファイルと衝突して dotfiles が適用できない

アプリやインストーラが `~` 側に実ファイルを作ると、symlink で置き換えられずに止まります。中身を確認したうえで上書きします:

```bash
mise dot diff
mise dot apply --force
```

### パッケージが足りない

`home/dot-config/mise/conf.d/bootstrap.toml` の `[bootstrap.packages]` に追加して再適用:

```bash
mise bootstrap packages apply
```

### Prezto が読み込まれない

```bash
mise bootstrap --update --only repos
```
