# docs/adr/

Architecture Decision Records（ADR）— 重要な設計判断の記録。

「なぜそうなっているか」を残すことで、将来の自分や新規参加者が文脈を把握しやすくする。

---

## ADR 一覧

| No | タイトル | ステータス | 概要 |
|:---|:---|:---|:---|
| [001](001-terraform-state-layer-separation.md) | Terraform State Layer Separation | Accepted | Terraform State をレイヤー（iam/environments/modules）に分離する設計 |
| [002](002-ecr-for-dev-container-image.md) | ECR for Dev Container Image | Accepted | 開発コンテナイメージを ECR で一元管理する |
| [ADR-003](ADR-003-changelog-version-release-trigger.md) | CHANGELOG Version Release Trigger | Accepted | CHANGELOG のバージョン番号とリリーストリガーの設計方針 |
| [ADR-004](ADR-004-iam-role-design.md) | IAM Role Design | Accepted | IAM ロール設計方針（admin / daihou-prod / プロジェクト別専用ロール） |

---

## 新しい ADR を追加する場合

1. ファイル名: `ADR-NNN-<kebab-case-title>.md`（連番）
2. テンプレートに沿って記載（Context / Decision / Consequences）
3. このファイルの一覧テーブルに追記する
