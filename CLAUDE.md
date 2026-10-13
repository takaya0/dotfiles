# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 概要

mise bootstrap で macOS 環境を管理する dotfiles リポジトリ。`~/dotfiles` に clone して使う（設定内で `~/dotfiles/home` を絶対パスで参照している）。

## よく使うコマンド

```bash
mise bootstrap            # すべて適用（dotfiles / repos / packages / macOS defaults / tools / 追加セットアップ）
mise bootstrap --dry-run  # 変更をシミュレート（実際には適用しない）
mise bootstrap status     # 各パートの状態を確認
mise dot apply            # dotfiles だけ適用
mise dot status           # dotfiles の状態を確認
mise dot add --changed    # copy で配置したファイルのアプリ側の変更をリポジトリに取り込む
```

`mise bootstrap` はカレントディレクトリの `mise.toml` の `[bootstrap]` も合わせて適用するため、他プロジェクトの外（`~` など）で実行する。

## 構成

| パス | 役割 |
|---|---|
| `home/` | `~` に展開されるファイル。`dot-xxx` は `.xxx` になる（`dot_prefix = true`） |
| `home/dot-config/mise/conf.d/bootstrap.toml` | mise bootstrap の定義（dotfiles / repos / packages / macOS defaults / tasks） |
| `home/dot-config/mise/config.toml` | 言語ランタイム（`[tools]`）。Renovate が更新する |
| `scripts/bootstrap.sh` | 新規マシン用の初回セットアップ |
| `scripts/post-bootstrap.sh` | `[tasks.bootstrap]` から毎回実行される追加セットアップ（冪等にする） |
| `scripts/vscode-extensions.txt` | VS Code 拡張リスト |

## dotfiles の配置ルール

- `home/` 配下は `symlink-each` で 1 ファイルずつ symlink される。`~` 側の管理外ファイルは残る（`~/.claude/` のランタイムデータ等）
- `manifest = "git"` のため、**`git add` したファイルだけ**が配置される
- アプリ自身が書き換えるファイル（Karabiner / Zed / VS Code / Cursor の設定、`~/.claude/settings.json`）は `exclude` して個別に `mode = "copy"` で配置する。新たにそういうファイルを追加するときは両方に書く
- `~/.config/karabiner` は 0700、`~/.config/zed/settings.json` は 0600 を `permissions` で指定している

## パッケージ管理

| カテゴリ | 設定場所 |
|---|---|
| CLIツール | `bootstrap.toml` の `[bootstrap.packages]` に `"brew:<name>" = "latest"` |
| GUIアプリ | `bootstrap.toml` の `[bootstrap.packages]` に `"brew-cask:<name>" = "latest"` |
| 言語ランタイム | `home/dot-config/mise/config.toml` の `[tools]` |
| VS Code 拡張 | `scripts/vscode-extensions.txt` |
| Claude Code / Rust / Codex CLI | `scripts/post-bootstrap.sh` |

パッケージを追加する手順: `bootstrap.toml` を編集 → `mise bootstrap packages apply`

## コミットメッセージ

コミットメッセージは**日本語**で記述し、Conventional Commit 形式（絵文字付き）を使う（詳細: `home/dot-claude/rules/core/commit.md`）。

例:
```
✨ feat: ユーザー認証機能を追加

JWT ベースの認証を実装。

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```
