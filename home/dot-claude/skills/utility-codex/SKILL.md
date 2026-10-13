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
# ✅ 一時ファイルに書いて stdin 経由で渡す（<slug> はレビューごとに一意な名前）
cat > /tmp/codex/<slug>.prompt.md <<'EOF'
複数行のプロンプト
...
EOF

cat /tmp/codex/<slug>.prompt.md | codex exec --skip-git-repo-check --sandbox read-only -c 'model_reasoning_effort="high"' -C <repo_dir> -
```

ポイント：
- 末尾の `-` が「stdin から読む」の明示。引数解析と stdin の両方にフォールバックさせない
- `Write` ツールで `/tmp/codex/<slug>.prompt.md` を作るのが確実（heredoc ネストの罠を回避）
- `<slug>` は **レビュー依頼ごとに一意**な kebab-case 名（レビュー内容から命名。例: `sentry-foundation`, `auth-refactor`）。固定名 `prompt.txt` は使わない。これにより複数レビューを並列実行してもファイルが衝突しない（詳細は「並列レビュー」セクション）

### 2. 必須オプション

| オプション | 役割 | いつ使うか |
|------|------|------|
| `-c 'model_reasoning_effort="high"'` | 推論の深さ（reasoning effort）を指定 | **常に付ける**。未指定だと `~/.codex/config.toml` の設定を継承する（→ 次節） |
| `--skip-git-repo-check` | カレントディレクトリが git リポジトリでなくても起動 | 常に付ける（安全側） |
| `--sandbox read-only` | コマンド実行を読み取り専用に制限 | レビュー・相談用途では常に付ける（`codex exec` のみ。`codex review` は下記参照） |
| `-C <repo_dir>` | 作業ディレクトリを指定 | リポジトリ内のファイルを参照させたい時は必須（`codex exec` のみ） |
| `-m <model>` | モデル指定 | 必要に応じて（デフォルトで OK） |

書き込みが必要な相談（codex に編集させたい）の場合のみ `--sandbox workspace-write` を使う。デフォルトは read-only。

**クォート形式はシングルクォートで囲む**（`-c 'model_reasoning_effort="high"'`）。`-c model_reasoning_effort="high"` だとシェルが二重引用符を剥がして CLI には `model_reasoning_effort=high` が渡る。Codex は TOML パース失敗時にリテラル文字列として扱うため実際には動くが、公式例の TOML 値形式に合わせておくほうが堅い。

### 2-1. reasoning effort の使い分け

`~/.codex/config.toml` の `model_reasoning_effort` がグローバル既定として効くため、**明示しないとその値（現状 `xhigh`）を継承して極端に遅くなる**。スキル経由の呼び出しでは常に明示すること。`-c` はインボケーション単位の上書きなので、対話モード（ユーザーが `! codex` で直接叩く運用）の設定には影響しない。

| effort | 使う場面 |
|------|------|
| `high`（**既定**） | プランレビュー / コードレビュー / 設計相談 / 調査結論のセカンドオピニオン |
| `medium` | 1 行で答えられる短い質問、軽い事実確認 |
| `xhigh` / `max` / `ultra` | **通常使わない。ユーザーが明示的に要求した場合のみ** |

有効な effort 値は**モデル依存**。現在サポートされる値は `codex debug models --bundled` の `supported_reasoning_levels` で確認できる（例: `gpt-5.6-sol` は `low` / `medium` / `high` / `xhigh` / `max` / `ultra`）。`high` / `medium` はどのモデルでも概ね利用可能。

実効値の確認方法は「トラブルシューティング」の末尾を参照。

### 3. 必ずバックグラウンド実行する

`codex exec` は数分かかることが多い。foreground で待つとブロックする。

```bash
# Bash ツールで run_in_background: true 指定 + 出力を slug ごとの tee で保存
cat /tmp/codex/<slug>.prompt.md | codex exec --skip-git-repo-check --sandbox read-only -c 'model_reasoning_effort="high"' -C /path/to/repo - 2>&1 | tee /tmp/codex/<slug>.output.txt
```

**完了監視は `run_in_background` のタスク完了通知に一本化する**（単発・並列とも同じ）：
- 各レビューを `run_in_background: true` の Bash タスクとして起動すると、そのタスクが終了したときに **タスク単位で完了通知が届く**。複数レビューを並列起動しても、終わった順に 1 件ずつ通知が来るので、どのレビューが終わったか取り違えない。
- `pgrep -f "codex exec"` を使った until ループ監視（Monitor ツール／Bash いずれも）は **使わない**。`codex exec` プロセス全体にマッチするため、並列実行中は「無関係な別レビューが終わるまで」ブロックしてしまう。

## コマンド一覧

### codex review（git 差分レビュー）

**`codex review` は `-C` / `--sandbox` / `--skip-git-repo-check` を受け付けない**（付けると `error: unexpected argument` で起動失敗する）。そのため:

- **作業ディレクトリ**: 対象リポジトリ内で実行する（別ディレクトリを明示したい場合は後述の `codex exec ... review` 形式）
- **サンドボックス**: `--sandbox` が使えないため、放置すると `config.toml` の `sandbox_mode`（現状 `workspace-write` + ネットワーク有効）を継承してしまう。レビュー用途では **`-c 'sandbox_mode="read-only"'` で明示的に読み取り専用に落とす**

```bash
# ステージされた変更をレビュー
codex review --uncommitted -c 'model_reasoning_effort="high"' -c 'sandbox_mode="read-only"'

# 特定のブランチとの差分をレビュー
codex review --base main -c 'model_reasoning_effort="high"' -c 'sandbox_mode="read-only"'

# 特定のコミットをレビュー
codex review --commit <SHA> -c 'model_reasoning_effort="high"' -c 'sandbox_mode="read-only"'

# カスタム指示でレビュー（短い指示なら位置引数 OK）
codex review "セキュリティの観点でレビューして" -c 'model_reasoning_effort="high"' -c 'sandbox_mode="read-only"'
```

長いカスタム指示は `codex exec` と同様に stdin 経由で渡す。出力も slug ごとに tee する：

```bash
cat /tmp/codex/<slug>.prompt.md | codex review --uncommitted -c 'model_reasoning_effort="high"' -c 'sandbox_mode="read-only"' - 2>&1 | tee /tmp/codex/<slug>.output.txt
```

別ディレクトリのリポジトリをレビューする場合は `codex exec` のサブコマンド形式を使う（こちらは `-C` が効く）：

```bash
codex exec -C /path/to/repo review --uncommitted -c 'model_reasoning_effort="high"' -c 'sandbox_mode="read-only"'
```

### codex exec（非対話レビュー・相談）

短い 1 行の質問のみ位置引数で OK。軽い質問なので effort は `medium`：

```bash
codex exec --skip-git-repo-check --sandbox read-only -c 'model_reasoning_effort="medium"' "Go の sync.Map と通常の map+Mutex の使い分けは？"
```

それ以外（複数行、コードを含む、プランレビュー等）は必ず stdin 経由。effort は既定の `high`：

```bash
cat /tmp/codex/<slug>.prompt.md | codex exec --skip-git-repo-check --sandbox read-only -c 'model_reasoning_effort="high"' -C /path/to/repo -
```

### codex（対話モード）

通常 Claude Code から起動しない（Claude が応答できないため）。ユーザーが直接 `! codex` で叩く運用を想定。

## ワークフロー（推奨）

単発レビューでも slug を使い、並列と運用を統一する。

1. ユーザーから相談内容を受け取り、レビューを表す一意な `<slug>`（kebab-case）を決める
2. プロンプトを `Write` ツールで `/tmp/codex/<slug>.prompt.md` に書き出す
   - レビュー対象ファイル・ディレクトリのパスをプロンプト内に明記
   - 「最終的に承認／条件付き承認／却下のいずれかを判定してください」等の出力形式指示を含める
3. `cat /tmp/codex/<slug>.prompt.md | codex exec --skip-git-repo-check --sandbox read-only -c 'model_reasoning_effort="high"' -C <repo_dir> - 2>&1 | tee /tmp/codex/<slug>.output.txt` を `run_in_background: true` で実行
4. そのタスクの完了通知を待つ（pgrep ループは使わない）
5. 完了したら `/tmp/codex/<slug>.output.txt` を Read で読み、ユーザーに要約 + 重要箇所の引用を報告
6. 報告完了後、`rm -f /tmp/codex/<slug>.*` で当該レビューの一時ファイルを削除する（次回実行時に古い出力と混同しないため。他の slug には触れない）

### 例 1: 設計プランをレビュー

```
ユーザー: 「このプランをcodexでレビューして」
→ slug を決める（例: plan-review）
→ Write で /tmp/codex/plan-review.prompt.md に「プランファイルのパス + レビュー観点 + 出力形式」を書き出す
→ cat /tmp/codex/plan-review.prompt.md | codex exec --skip-git-repo-check --sandbox read-only -c 'model_reasoning_effort="high"' -C <repo> - 2>&1 | tee /tmp/codex/plan-review.output.txt を run_in_background で実行
→ タスクの完了通知を待つ
→ /tmp/codex/plan-review.output.txt を Read してユーザーに要約報告
→ rm -f /tmp/codex/plan-review.* で一時ファイルを削除
```

### 例 2: 短い設計上の質問

```
ユーザー: 「Echo の middleware ordering で気をつけるべきことを codex に聞いて」
→ codex exec --skip-git-repo-check --sandbox read-only -c 'model_reasoning_effort="medium"' "Echo v5 で middleware ordering で起こりがちなバグと対処" を直接実行
→ 1 行の短いプロンプトなら位置引数で OK。軽い質問なので effort は medium
```

### 例 3: 現在のリポジトリでの差分レビュー

```
ユーザー: 「いまの変更を codex でレビューして」
→ slug を決める（例: uncommitted-review）
→ 対象リポジトリ内で codex review --uncommitted -c 'model_reasoning_effort="high"' -c 'sandbox_mode="read-only"' 2>&1 | tee /tmp/codex/uncommitted-review.output.txt を run_in_background で実行
   （codex review は -C を受け付けない。別ディレクトリなら codex exec -C <repo> review ... 形式）
→ タスクの完了通知を待つ
→ /tmp/codex/uncommitted-review.output.txt を要約して報告
→ rm -f /tmp/codex/uncommitted-review.* で削除
```

## 並列レビュー

複数のレビュー依頼を同時に走らせる場合、各レビューを **slug で分離**して並列実行する。固定ファイル名（`prompt.txt` / `output.txt`）を共有しないことが唯一かつ最重要のポイント。

1. レビュー依頼ごとに **一意な `<slug>`** を決める（重複しない説明的な名前。例: `sentry-foundation`, `auth-refactor`）
2. 各 slug について `Write` で `/tmp/codex/<slug>.prompt.md` を作成
3. 各 slug を **別々の `run_in_background: true` Bash 呼び出し**で起動する（1 メッセージ内に複数の Bash 呼び出しを並べてよい）。各々 `2>&1 | tee /tmp/codex/<slug>.output.txt` で出力を slug ごとに保存

   ```bash
   # レビュー A（run_in_background: true）
   cat /tmp/codex/sentry-foundation.prompt.md | codex exec --skip-git-repo-check --sandbox read-only -c 'model_reasoning_effort="high"' -C <repo> - 2>&1 | tee /tmp/codex/sentry-foundation.output.txt
   # レビュー B（別の run_in_background: true）
   cat /tmp/codex/auth-refactor.prompt.md | codex exec --skip-git-repo-check --sandbox read-only -c 'model_reasoning_effort="high"' -C <repo> - 2>&1 | tee /tmp/codex/auth-refactor.output.txt
   ```

4. **タスクごとの完了通知**を受けるたびに、その slug の `/tmp/codex/<slug>.output.txt` を Read し、どのレビューの結果かを明示してユーザーに報告（終わった順に 1 件ずつ処理してよい）
5. 報告し終えた slug から順に `rm -f /tmp/codex/<slug>.*` でクリーンアップ。他の slug のファイルには触れない

注意:
- ❌ **slug を使い回さない**。同名だと後発が先発のプロンプト／出力を上書きする
- ❌ **`pgrep -f "codex exec"` で待たない**。全 codex プロセスにマッチし、無関係な別レビューの終了まで待ってしまう。`run_in_background` のタスク完了通知だけで待つ

## トラブルシューティング

### 症状: codex exec が無限にハングする

**原因**: 位置引数のプロンプト解析に失敗 → stdin フォールバックで永久待機。

**確認方法**: `tail` で出力ファイルに `Reading additional input from stdin...` が出ていればこの症状。

**対処**:
1. `pkill -f "codex exec"` で停止（※並列実行中は他のレビューも巻き込むので注意。単発時のみ安全）
2. プロンプトを `Write` で `/tmp/codex/<slug>.prompt.md` に書き出す
3. `cat /tmp/codex/<slug>.prompt.md | codex exec ... -c 'model_reasoning_effort="high"' -` で再実行

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

### 症状: レビューが極端に遅い / タイムアウト

1. **`-c 'model_reasoning_effort=...'` が付いているか確認**。未指定だと `~/.codex/config.toml` の設定（現状 `xhigh`）を継承して非常に遅くなる。これが最頻の原因
2. effort を `medium` に下げて再実行
3. プロンプトを簡潔にして再実行
4. `--model` を軽量モデルに変更
5. バックグラウンドのタイムアウトを延長（Bash ツールなら `timeout: 600000` まで指定可）

### 実効 reasoning effort の確認方法

`codex exec` / `codex review` は起動時ヘッダに実効値を出力する。`head` で打ち切れば **API 応答を待たずに** 確認できるので確認コストはほぼゼロ：

```bash
echo "hi" | codex exec --skip-git-repo-check --sandbox read-only -c 'model_reasoning_effort="medium"' - 2>&1 | head -9
# → "reasoning effort: medium" と表示されれば OK（"sandbox:" 行も同時に確認できる）
```

注意: **不正な値はエラーにならず素通りする**（`-c 'model_reasoning_effort="bogus"'` は `reasoning effort: bogus` として起動してしまう）。`--strict-config` もキー名しか検証しないため、値の確認はこのヘッダ目視で行う。

事後確認したい場合は rollout ログからも読める：

```bash
newest=$(find ~/.codex/sessions -name "*.jsonl" -print0 | xargs -0 ls -t | head -1)
grep -o '"effort":"[a-z]*"' "$newest" | sort -u
```

## アンチパターン

- ❌ 複数行プロンプトを `"$(cat <<EOF...EOF)"` で位置引数に渡す（ハング）
- ❌ `codex exec` を foreground 実行して数分間ブロックする
- ❌ `-c 'model_reasoning_effort=...'` を付けずに実行する（`config.toml` のグローバル既定を継承する。そこが高い effort だとレビューが不必要に長時間化する）
- ❌ `--sandbox` 指定なしで実行（書き込みリスクあり）。`codex review` は `--sandbox` 自体が使えないので `-c 'sandbox_mode="read-only"'` で代替する
- ❌ `codex review` に `-C` / `--sandbox` / `--skip-git-repo-check` を渡す（`error: unexpected argument` で起動失敗）
- ❌ `-C` なしで他リポジトリのファイルを参照させようとする
- ❌ 出力を `tee` で保存せず stdout に流すだけ（バックグラウンドで結果が消える）
- ❌ 並列レビューで同じファイル名（固定 `prompt.txt` / `output.txt`）を使い回す（上書き・出力混在）。レビューごとに一意な `<slug>` を使う
- ❌ `pgrep -f "codex exec"` で完了を待つ（全 codex プロセスにマッチし、無関係な別レビューの終了まで待ってブロックする）。`run_in_background` のタスク完了通知を使う
- ❌ 報告後に `/tmp/codex/<slug>.*` を残したまま放置（次タスクと混同するリスク）
