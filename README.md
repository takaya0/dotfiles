# dotfiles

macOS環境を chezmoi + Homebrew で管理するdotfilesリポジトリ。

## 🎯 特徴

- **chezmoi**: dotfilesの管理・適用を担当
- **Homebrew**: CLIツール・GUIアプリをすべて管理
- **mise**: 言語ランタイムのバージョン管理
- **Prezto**: zshフレームワーク（chezmoi external git-repoとして管理）

## 📁 構成

```
dotfiles/                                    # chezmoi source directory
├── .chezmoi.toml.tmpl                       # chezmoi設定テンプレート
├── .chezmoidata.yaml                        # パッケージ・拡張機能リスト
├── .chezmoiexternal.toml                    # Prezto (外部git-repo)
├── .chezmoiignore                           # chezmoi非管理ファイル
│
├── dot_gitconfig.tmpl                       # → ~/.gitconfig
├── dot_zshrc.tmpl                           # → ~/.zshrc
├── dot_zprofile.tmpl                        # → ~/.zprofile
├── dot_zshenv.tmpl                          # → ~/.zshenv
├── dot_zpreztorc.tmpl                       # → ~/.zpreztorc
│
├── dot_config/                              # → ~/.config/
│   ├── wezterm/                             # WezTerm設定
│   ├── zed/                                 # Zed設定
│   ├── karabiner/                           # Karabiner設定
│   └── mise/                               # mise設定
│
├── dot_claude/                              # → ~/.claude/
│   ├── settings.json
│   ├── rules/core/                          # ルールファイル
│   ├── commands/                            # カスタムコマンド
│   ├── agents/                              # エージェント設定
│   └── skills/                              # スキルディレクトリ
│
├── Library/Application Support/
│   ├── Code/User/settings.json             # VS Code設定
│   └── Cursor/User/settings.json           # Cursor設定
│
├── run_onchange_install-packages.sh.tmpl    # Homebrew bundle
├── run_onchange_install-vscode-extensions.sh.tmpl  # VS Code拡張
├── run_once_after_configure-macos.sh        # macOSデフォルト設定
└── scripts/bootstrap.sh                     # 初回セットアップ
```

## 🚀 セットアップ

### 新規セットアップ（ワンライナー）

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/takaya0/dotfiles/main/scripts/bootstrap.sh)
```

Xcode CLT → Homebrew → dotfiles clone → chezmoi → 設定適用 まで自動実行されます。

### clone 済みの場合

```bash
~/dotfiles/scripts/bootstrap.sh
```

## 🔄 設定の更新

```bash
# dotfilesを編集後
chezmoi apply

# 差分を確認してから適用
chezmoi diff
chezmoi apply
```

## 📦 パッケージ管理方針

| カテゴリ | 管理方法 | 設定場所 |
|---------|---------|----------|
| CLIツール | Homebrew | `.chezmoidata.yaml` |
| 言語ランタイム | mise | `dot_config/mise/config.toml` |
| GUIアプリ | Homebrew Cask | `.chezmoidata.yaml` |
| VS Code拡張 | code CLI | `.chezmoidata.yaml` |

## 🛠️ 設定ファイルの編集

設定ファイルは chezmoi 命名規則に従い管理されています。

- **WezTerm**: `dot_config/wezterm/*.lua`
- **Zed**: `dot_config/zed/settings.json`
- **Karabiner**: `dot_config/karabiner/karabiner.json`
- **mise**: `dot_config/mise/config.toml`
- **VS Code**: `Library/Application Support/Code/User/settings.json`
- **Claude Code**: `dot_claude/`

## 🔗 参考リンク

- [chezmoi](https://www.chezmoi.io/)
- [Homebrew](https://brew.sh/)
- [mise](https://mise.jdx.dev/)
- [Prezto](https://github.com/sorin-ionescu/prezto)
