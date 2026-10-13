# dotfiles

macOS環境を [mise bootstrap](https://mise.jdx.dev/bootstrap.html) で管理するdotfilesリポジトリ。

## 🎯 特徴

- **mise bootstrap**: dotfiles の配置・パッケージ・macOS 設定・追加セットアップを 1 コマンドで適用
- **mise dotfiles**: `home/` 配下のファイルを `~` に symlink（アプリが書き換えるファイルは copy）
- **mise packages**: Homebrew の formula / cask を宣言的に管理
- **mise tools**: 言語ランタイムのバージョン管理
- **Prezto**: zshフレームワーク（`[bootstrap.repos]` で clone）

## 📁 構成

```
dotfiles/
├── home/                                    # → ~/ （dot-xxx は .xxx として展開）
│   ├── dot-gitconfig                        # → ~/.gitconfig
│   ├── dot-zshrc                            # → ~/.zshrc
│   ├── dot-zprofile                         # → ~/.zprofile
│   ├── dot-zshenv                           # → ~/.zshenv
│   ├── dot-zpreztorc                        # → ~/.zpreztorc
│   │
│   ├── dot-config/                          # → ~/.config/
│   │   ├── mise/
│   │   │   ├── config.toml                  # 言語ランタイム（[tools]）
│   │   │   └── conf.d/bootstrap.toml        # mise bootstrap の定義
│   │   ├── wezterm/                         # WezTerm設定
│   │   ├── zed/                             # Zed設定（copy）
│   │   └── karabiner/                       # Karabiner設定（copy）
│   │
│   ├── dot-claude/                          # → ~/.claude/
│   │   ├── settings.json                    # （copy）
│   │   ├── rules/core/                      # ルールファイル
│   │   ├── agents/                          # エージェント設定
│   │   └── skills/                          # スキルディレクトリ
│   │
│   └── Library/Application Support/
│       ├── Code/User/settings.json          # VS Code設定（copy）
│       └── Cursor/User/settings.json        # Cursor設定（copy）
│
└── scripts/
    ├── bootstrap.sh                         # 初回セットアップ
    ├── post-bootstrap.sh                    # mise bootstrap の最後に実行される追加セットアップ
    └── vscode-extensions.txt                # VS Code拡張リスト
```

## 🚀 セットアップ

### 新規セットアップ（ワンライナー）

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/takaya0/dotfiles/main/scripts/bootstrap.sh)
```

Xcode CLT → Homebrew → dotfiles clone → mise → `mise bootstrap` まで自動実行されます。

### clone 済みの場合

```bash
~/dotfiles/scripts/bootstrap.sh
```

## 🔄 設定の更新

```bash
# 差分を確認してから適用（任意のディレクトリで実行可）
mise bootstrap --dry-run
mise bootstrap

# dotfiles だけ適用
mise dot apply
```

- symlink で配置したファイルは、`~` 側を編集するとそのままリポジトリに反映されます
- 新しいファイルは `home/` に置いて **`git add` してから** 適用します（`manifest = "git"` のため）
- copy で配置したファイル（Zed / Karabiner / VS Code / Cursor / `~/.claude/settings.json`）をアプリ側で変更した場合は、`mise dot add --changed` でリポジトリに取り込みます

## 📦 パッケージ管理方針

| カテゴリ | 管理方法 | 設定場所 |
|---------|---------|----------|
| CLIツール | mise bootstrap（`brew:`） | `home/dot-config/mise/conf.d/bootstrap.toml` |
| GUIアプリ | mise bootstrap（`brew-cask:`） | `home/dot-config/mise/conf.d/bootstrap.toml` |
| 言語ランタイム | mise tools | `home/dot-config/mise/config.toml` |
| VS Code拡張 | code CLI | `scripts/vscode-extensions.txt` |
| Claude Code / Rust / Codex CLI | インストーラ | `scripts/post-bootstrap.sh` |

## 🔗 参考リンク

- [mise bootstrap](https://mise.jdx.dev/bootstrap.html)
- [mise dotfiles](https://mise.jdx.dev/dotfiles.html)
- [Homebrew](https://brew.sh/)
- [Prezto](https://github.com/sorin-ionescu/prezto)
