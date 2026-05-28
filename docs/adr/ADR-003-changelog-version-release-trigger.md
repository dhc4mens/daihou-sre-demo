# ADR-003: CHANGELOG.md バージョン更新 = GitHub Release 自動生成トリガー

## ステータス

承認済み（2026-05-05）

## コンテキスト

GitHub Releases が手動更新のため更新忘れが発生しやすく、タグ管理も統一されていなかった。
リリース作業を自動化しつつ、リリース粒度は人間がコントロールできる仕組みが必要。

## 決定

CHANGELOG.md の最新バージョンヘッダ（`## [x.y.z]`）を GitHub Release の自動作成トリガーとする。

### リリースフロー

1. 通常の PR はそのまま main にマージ（`## [Unreleased]` のまま → リリースなし）
2. リリースしたい時は `## [Unreleased]` → `## [x.y.z]` に変更して PR 作成 → マージ → 自動でタグ + GitHub Release 作成

### バージョン更新基準（Semantic Versioning）

| 変更内容 | バージョン | 例 |
|---------|-----------|---|
| 破壊的変更・大規模リリース | MAJOR | 1.0.0 → 2.0.0 |
| 新機能追加 | MINOR | 1.0.0 → 1.1.0 |
| バグ修正・小改善・ドキュメント更新 | PATCH | 1.0.0 → 1.0.1 |

## 理由

- 更新忘れをなくす（GitHub Actions タブへの手動アクセス不要）
- リリース粒度を人間がコントロール（毎 merge ではなく CHANGELOG 変更時のみ）
- 既存の CHANGELOG 更新ルール（CLAUDE.md）と自然に統合される

## 対象リポジトリ

dhc4mens 配下の全リポジトリに統一適用:
daihou-corporate-site / daihou-gbp / daihou-sre / CloudLogAI / portfolio
