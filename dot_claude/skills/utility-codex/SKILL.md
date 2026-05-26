---
name: utility-codex
description: Codex CLI（OpenAI）を使用してコード、設計、実装について相談・レビューを行う。別の視点からのフィードバックが欲しい時、セカンドオピニオンを求める時、コードレビューを依頼する時、設計の妥当性を確認したい時に使用する。「codexに相談」「セカンドオピニオン」「別の視点で確認」などで起動。
---

# Codex

Codex CLI（OpenAI）を使用して、コードや設計について相談・レビューを行う。

## 判断フロー

```
ユーザーのリクエスト
    │
    ├─ git差分のレビュー？ ─────→ codex review
    │
    ├─ 特定の質問・相談？ ──────→ codex exec（プロンプトは stdin 経由）
    │
    └─ 対話的に相談したい？ ────→ codex（対話モード）
```

## 必ず守るべき呼び出しパターン

### 1. プロンプトは常に stdin 経由（`-` 引数）で渡す

`codex exec` の位置引数は短い 1 行プロンプトを想定している。複数行や日本語、シェル特殊文字を含むプロンプトを `"$(cat <<EOF...EOF)"` で位置引数に渡すと、引数解析失敗時に **stdin 読み取りへサイレントにフォールバックし、永久に入力待ちでハングする**。

**禁止パターン（過去にハングした実績あり）**:

```bash
# ❌ 複数行プロンプトを位置引数で渡すとハング
codex exec "$(cat <<'EOF'
複数行のプロンプト
...
EOF
)"
```

**推奨パターン**:

```bash
# ✅ 一時ファイルに書いて stdin 経由で渡す
cat > /tmp/codex/prompt.txt <<'EOF'
複数行のプロンプト
...
EOF

cat /tmp/codex/prompt.txt | codex exec --skip-git-repo-check --sandbox read-only -C <repo_dir> -
```

ポイント：
- 末尾の `-` が「stdin から読む」の明示。引数解析と stdin の両方にフォールバックさせない
- `Write` ツールで `/tmp/codex/prompt.txt` を作るのが確実（heredoc ネストの罠を回避）

### 2. 必須オプション

| オプション | 役割 | いつ使うか |
|------|------|------|
| `--skip-git-repo-check` | カレントディレクトリが git リポジトリでなくても起動 | 常に付ける（安全側） |
| `--sandbox read-only` | コマンド実行を読み取り専用に制限 | レビュー・相談用途では常に付ける |
| `-C <repo_dir>` | 作業ディレクトリを指定 | リポジトリ内のファイルを参照させたい時は必須 |
| `-m <model>` | モデル指定 | 必要に応じて（デフォルトで OK） |

書き込みが必要な相談（codex に編集させたい）の場合のみ `--sandbox workspace-write` を使う。デフォルトは read-only。

### 3. 必ずバックグラウンド実行する

`codex exec` は数分かかることが多い。foreground で待つとブロックする。

```bash
# Bash ツールで run_in_background: true 指定 + 出力を tee で保存
cat /tmp/codex_prompt.txt | codex exec --skip-git-repo-check --sandbox read-only -C /path/to/repo - 2>&1 | tee /tmp/codex_output.txt
```

完了監視は次のいずれか：
- Monitor ツールで `until ! pgrep -f "codex exec" > /dev/null; do sleep 5; done; echo DONE` を流す
- Bash の run_in_background で同じ until ループを回し、終了通知を受ける

## コマンド一覧

### codex review（git 差分レビュー）

```bash
# ステージされた変更をレビュー
codex review --uncommitted

# 特定のブランチとの差分をレビュー
codex review --base main

# 特定のコミットをレビュー
codex review --commit <SHA>

# カスタム指示でレビュー（短い指示なら位置引数 OK）
codex review "セキュリティの観点でレビューして"
```

長いカスタム指示は `codex exec` と同様に stdin 経由で渡す：

```bash
cat /tmp/review_instructions.txt | codex review --uncommitted -
```

### codex exec（非対話レビュー・相談）

短い 1 行の質問のみ位置引数で OK：

```bash
codex exec --skip-git-repo-check --sandbox read-only "Go の sync.Map と通常の map+Mutex の使い分けは？"
```

それ以外（複数行、コードを含む、プランレビュー等）は必ず stdin 経由：

```bash
cat /tmp/codex_prompt.txt | codex exec --skip-git-repo-check --sandbox read-only -C /path/to/repo -
```

### codex（対話モード）

通常 Claude Code から起動しない（Claude が応答できないため）。ユーザーが直接 `! codex` で叩く運用を想定。

## ワークフロー（推奨）

1. ユーザーから相談内容を受け取る
2. プロンプトを `Write` ツールで `/tmp/codex_prompt.txt` に書き出す
   - レビュー対象ファイル・ディレクトリのパスをプロンプト内に明記
   - 「最終的に承認／条件付き承認／却下のいずれかを判定してください」等の出力形式指示を含める
3. `cat /tmp/codex_prompt.txt | codex exec --skip-git-repo-check --sandbox read-only -C <repo_dir> - 2>&1 | tee /tmp/codex_output.txt` をバックグラウンド実行
4. Monitor または run_in_background の until ループで完了を待つ
5. 完了したら出力ファイルを Read で読み、ユーザーに要約 + 重要箇所の引用を報告
6. 報告完了後、`rm -f /tmp/codex_prompt.txt /tmp/codex_output.txt` で一時ファイルを削除する（次回実行時に古い出力と混同しないため）

### 例 1: 設計プランをレビュー

```
ユーザー: 「このプランをcodexでレビューして」
→ Write で /tmp/codex_prompt.txt に「プランファイルのパス + レビュー観点 + 出力形式」を書き出す
→ cat /tmp/codex_prompt.txt | codex exec --skip-git-repo-check --sandbox read-only -C <repo> - をバックグラウンド実行
→ Monitor で完了を待つ
→ 出力を Read してユーザーに要約報告
→ rm -f /tmp/codex_prompt.txt /tmp/codex_output.txt で一時ファイルを削除
```

### 例 2: 短い設計上の質問

```
ユーザー: 「Echo の middleware ordering で気をつけるべきことを codex に聞いて」
→ codex exec --skip-git-repo-check --sandbox read-only "Echo v5 で middleware ordering で起こりがちなバグと対処" を直接実行
→ 1 行の短いプロンプトなら位置引数で OK
```

### 例 3: 現在のリポジトリでの差分レビュー

```
ユーザー: 「いまの変更を codex でレビューして」
→ codex review --uncommitted -C /path/to/repo を実行
→ バックグラウンド実行 + Monitor で完了監視
→ 出力を要約して報告
```

## トラブルシューティング

### 症状: codex exec が無限にハングする

**原因**: 位置引数のプロンプト解析に失敗 → stdin フォールバックで永久待機。

**確認方法**: `tail` で出力ファイルに `Reading additional input from stdin...` が出ていればこの症状。

**対処**:
1. `pkill -f "codex exec"` で停止
2. プロンプトを `Write` で `/tmp/codex_prompt.txt` に書き出す
3. `cat /tmp/codex_prompt.txt | codex exec ... -` で再実行

### 症状: codex コマンドが見つからない

```bash
# Bun 環境
bun add -g @openai/codex

# Homebrew 環境
brew install openai/openai/codex
```

### 症状: 認証エラー

```bash
codex login
```

ユーザーに `! codex login` の入力を促す（インタラクティブ）。

### 症状: タイムアウト

- プロンプトを簡潔にして再実行
- `--model` を軽量モデルに変更
- バックグラウンドのタイムアウトを延長（Bash ツールなら `timeout: 600000` まで指定可）

## アンチパターン

- ❌ 複数行プロンプトを `"$(cat <<EOF...EOF)"` で位置引数に渡す（ハング）
- ❌ `codex exec` を foreground 実行して数分間ブロックする
- ❌ `--sandbox` 指定なしで実行（書き込みリスクあり）
- ❌ `-C` なしで他リポジトリのファイルを参照させようとする
- ❌ 出力を `tee` で保存せず stdout に流すだけ（バックグラウンドで結果が消える）
- ❌ 報告後に `/tmp/codex_prompt.txt` / `/tmp/codex_output.txt` を残したまま放置（次タスクと混同するリスク）
