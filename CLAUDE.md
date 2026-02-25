# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 概要

chezmoi + Homebrew で macOS 環境を管理する dotfiles リポジトリ。`~/dotfiles` が chezmoi の sourceDir として直接使われる。

## よく使うコマンド

```bash
chezmoi apply           # 設定を適用（変更後は必ずこれを実行）
chezmoi diff            # 適用前に差分を確認
chezmoi apply --dry-run # 変更をシミュレート（実際には適用しない）
chezmoi update          # 外部リポジトリ（Prezto）を更新
chezmoi apply --verbose # エラー調査時
```

## chezmoi 命名規則

| プレフィックス/サフィックス | 意味 |
|---|---|
| `dot_` | ホームディレクトリに `.` として展開（例: `dot_zshrc` → `~/.zshrc`） |
| `.tmpl` | Go テンプレートとして処理される（展開後は .tmpl なし） |
| `run_onchange_*.tmpl` | テンプレートの出力内容が変わった場合のみ実行されるスクリプト |
| `run_once_after_*` | `chezmoi apply` で一度だけ実行されるスクリプト |
| `exact_` | ディレクトリ内の管理外ファイルを削除（`dot_claude/` には **使わない** — ランタイムデータが消えるため） |

## パッケージ管理

| カテゴリ | 設定ファイル |
|---|---|
| CLIツール (brews) | `.chezmoidata.yaml` の `brews:` リスト |
| GUIアプリ (casks) | `.chezmoidata.yaml` の `casks:` リスト |
| VS Code / Cursor 拡張 | `.chezmoidata.yaml` の `vscode_extensions:` リスト |
| 言語ランタイム | `dot_config/mise/config.toml` |

パッケージを追加する手順: `.chezmoidata.yaml` を編集 → `chezmoi apply`（`run_onchange_install-packages.sh.tmpl` が自動実行される）

## テンプレートデータ

- **`.chezmoi.toml.tmpl`**: `{{ .name }}`（yataka）、`{{ .email }}`（ytk.koizumi@gmail.com）
- **`.chezmoidata.yaml`**: `{{ .brews }}`、`{{ .casks }}`、`{{ .vscode_extensions }}`
- **組み込み変数**: `{{ .chezmoi.homeDir }}` など

## アーキテクチャ上の重要ポイント

- `dot_claude/` は `exact_` なし — `~/.claude/` にはランタイムデータ（セッション、キャッシュ等）が混在するため
- `.chezmoiignore` に列挙されたファイル（README.md, INSTALL.md, scripts/, .cursor/, bin/, CLAUDE.md）はホームに展開されない
- Prezto は `.chezmoiexternal.toml` で `--recursive` git clone として管理
- `run_onchange_install-packages.sh.tmpl` は Homebrew bundle の他に mise, Claude Code, Codex CLI もインストールする

## コミットメッセージ

コミットメッセージは**日本語**で記述する（`.cursor/rules/commit-message-japanese.mdc` に基づく）。
