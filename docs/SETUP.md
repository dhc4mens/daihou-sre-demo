# リポジトリ初期セットアップ手順

このテンプレートから新規リポジトリを作る／既存リポジトリに適用する手順。

## A. 新規リポジトリを作る場合（推奨）

```bash
gh repo create dhc4mens/<new-repo-name> \
  --template dhc4mens/repo-setup-template \
  --public   # または --private
  --clone

cd <new-repo-name>
```

その後：

1. プレースホルダー置換
   - `{{PROJECT_NAME}}` → 実リポ名
   - `{{ONE_LINE_DESCRIPTION}}` → 一行概要
   - `YYYY-MM-DD` → 日付
2. ラベル作成: `bash scripts/setup-labels.sh`
3. pre-commit フックをインストール: `bash scripts/install-hooks.sh`
4. プロジェクト追加（複数リポ横断管理する場合）:
   ```bash
   # オープンIssue を手動追加
   gh project item-add 1 --owner dhc4mens --url <issue-url>
   ```
5. CLAUDE.md のプロジェクト概要セクションを埋める
6. 初期コミット・push

## B. 既存リポジトリに適用する場合

```bash
# 適用先リポジトリにいる前提
cp -r /path/to/repo-setup-template/.github .
cp /path/to/repo-setup-template/scripts/setup-labels.sh scripts/ 2>/dev/null || cp /path/to/repo-setup-template/scripts/setup-labels.sh .

bash scripts/setup-labels.sh

# CLAUDE.md / CHANGELOG.md / TODO.md は既存があれば上書きしない
# なければテンプレートを参考に作成
```

その後、feature ブランチを切って PR で整備内容をマージ。

## Dependabot version updates

`.github/dependabot.yml` が同梱されている。展開後は以下を調整：

- **不要 ecosystem は削除**（例: Node のみのリポは `pip` / `terraform` ブロックを削る）
- **`directory`** を実際のパスに合わせる（例: `/src/lambda/xxx`）
- 初回は `monthly` で noise 抑制、安定後に `weekly` 検討
- `type/chore` + `priority/low` ラベルは `setup-labels.sh` 実行後に自動付与される

alerts（脆弱性検知）はリポ単位で別途 `gh api -X PUT /repos/OWNER/REPO/vulnerability-alerts` で有効化。

## Claude Code per-project 設定（`.claude/settings.json`）

テンプレートには `.claude/settings.json` が同梱されている（中身はほぼ空）。

```json
{
  "permissions": {
    "additionalDirectories": []
  }
}
```

🔴 **`model` / `effortLevel` はここに書かない**（dotfiles ADR-013 Decision 8）。プロジェクトの settings はユーザーの settings（`~/.claude/settings.json`）の値を**上書き**するので、ここに書くと、このリポで起動した瞬間に個人のモデル選択が潰れる。どのモデル・effort で作業するかは個人の選択で、ユーザー層が正本。

このファイルに書くのは「このリポを使う誰にとっても必要なもの」だけ（リポ固有の permissions・env など）。

**自分だけの上書き**は `.claude/settings.local.json` を使う（`.gitignore` 済み、コミット不要）。秘密は平書きしない（MCP の認証は `headersHelper`）:

```json
{ "effortLevel": "high" }
```

## 設定するラベル（10個）

| カテゴリ | ラベル | 色 |
|:---|:---|:---|
| type/ | bug / feature / chore / docs | 赤/水色/灰/青 |
| priority/ | high / medium / low | 濃赤/黄/灰 |
| status/ | ready / wip / blocked | 緑/黄/濃赤 |

## pre-commit フック

ローカルチェックを自動化し、GitHub Actions CI の負荷を最小化する構成。

### セットアップ

```bash
bash scripts/install-hooks.sh
```

以下の2種類のフックが有効になる：

| フック種別 | タイミング | 内容 |
|:---|:---|:---|
| pre-commit | `git commit` 前 | trailing-whitespace / end-of-file / YAML/JSON 検証 / terraform fmt / ruff（Python） |
| pre-push | `git push` 前 | main への直接 push を拒否 |

### CI との関係

GitHub Actions の `ci.yml` は `pre-commit run --all-files` を実行するだけ。
ローカルでフックが通っていれば CI も数秒で pass する。
フックをスキップして（`--no-verify`）push してきた場合は CI で落とす。

### 言語別カスタマイズ

`.pre-commit-config.yaml` はプロジェクトに不要なフックを削除して使う：

- Terraform を使わない → `antonbabenko/pre-commit-terraform` セクションを削除
- Python を使わない → `astral-sh/ruff-pre-commit` セクションを削除
- mypy を有効化したい → `mirrors-mypy` セクションのコメントを外す

## 参考

- 適用実績: daihou-corporate-site, CloudLogAI, portfolio
- 運用ボード: https://github.com/users/dhc4mens/projects/1
