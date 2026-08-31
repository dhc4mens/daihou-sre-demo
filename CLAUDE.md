# CLAUDE.md - daihou-sre-demo 固有ルール

> 共通ルール（ブランチ命名・コミット規約・CHANGELOG更新等）は `~/.claude/CLAUDE.md` を参照

## プロジェクト概要

SRE基盤デモリポジトリ。daihou-sre（private）から設計思想・実装パターン・運用ドキュメントを
公開用に抽出したもの。**面談・ポートフォリオ用途。**

- **可視性**: 🔴 **PUBLIC**
- **リポジトリ**: https://github.com/dhc4mens/daihou-sre-demo
- **抽出元**: dhc4mens/daihou-sre（private）

---

## 🔴 このリポは閲覧専用。動かすものではない

`terraform/` にあるのは `modules/` だけで **`environments/`（root module）を持たない。**
バックエンド設定も変数の実値も無いので `terraform apply` は通らない。**設計と実装の見せ方を
読ませるための構成**であり、動く本番環境は daihou-sre 側にある。

構成・読み方の詳細は [README.md](README.md) が正本。**ここに写しを置かない。**

---

## 🔴 PUBLIC なので、書く前に必ず確認すること

- **AWS アカウントIDを書かない。** ダミーの `123456789012`（AWS ドキュメント用）を使う。
  実アカウントIDは 2026-08-31 まで17箇所に露出していた（#5 で是正）
- **実 ARN・実ドメイン・実バケット名・Secrets Manager のパスを書かない。**
  変数で受け取る形にして既定値を持たせない（`monitoring` モジュールの `sns_topic_arn` /
  `ses_sns_topic_arn` がその形）
- **private リポから抽出する時は差分を見る。** 抽出元 daihou-sre の実値がそのまま入る事故が起きやすい

```bash
# コミット前のセルフチェック
grep -rnE "[0-9]{12}" . --exclude-dir=.git | grep -v 123456789012
grep -rn "daihou-llc\.com" . --exclude-dir=.git
```

---

## 抽出元との関係

daihou-sre から**コピーした**ファイルがあり、本体の更新に自動追随しない。

| 種類 | 本数 | 扱い |
|:---|---:|:---|
| ADR | 4 | 本体と重複。陳腐化の確認方法は dotfiles [#310](https://github.com/dhc4mens/dotfiles/issues/310)（ADR監査 Phase 0 item 2）で扱う |
| Runbook | 7 | 同上 |
| SLO 定義 | 2 | 同上 |

⚠️ **本体を直した時に、ここへ反映するかを都度判断する。** 「デモとして初回リリース時点で
意図的に固定する」という選択もありうるが、**まだ決めていない**（#5）。

---

## 注意事項（プロジェクト固有）

- **CHANGELOG は生かす。** 閲覧専用でも中身は更新されるため、初回リリースで固定しない
- TODO の正本は GitHub Issue（[TODO.md](TODO.md) はリダイレクト文書）

---

## 参照リンク

- [README.md](README.md) — 構成と読み方の正本
- [CHANGELOG.md](CHANGELOG.md)
- [TODO.md](TODO.md)
- [ADR 一覧](docs/adr/README.md)

---

最終更新: 2026-08-31
