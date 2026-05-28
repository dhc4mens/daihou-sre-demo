# ADR-001: tfstate をインフラ層・アプリ層に分離する

> Architecture Decision Record — 作成: 2026-04-24 / ステータス: Accepted

---

## ステータス

**Accepted** — Issue [#67](https://github.com/dhc4mens/daihou-sre/issues/67) にて採択

---

## コンテキスト

daihou-sre の Terraform は現在、インフラ層（VPC・IAM・S3 等）とアプリ層（Lambda・ECS・CloudWatch 等）を単一の tfstate で管理している。リソース数の増加に伴い、以下の問題が顕在化しつつある。

- `terraform plan` の実行時間が全リソース分かかり、CI/CD のオーバーヘッドが増大
- アプリ層の軽微な変更でも、インフラ層のリソースまで差分チェックが走る
- 将来的にチーム分業した場合、state ロック競合のリスクがある

インフラ層は変更頻度が低く、アプリ層は頻繁に変わるという特性の違いがあり、一括管理はこのギャップに対して非効率である。

---

## 決定

tfstate を以下の2層に分離する。

| 層 | ディレクトリ（案） | 対象リソース（代表例） | 変更頻度 |
|:---|:---|:---|:---|
| インフラ層（infra） | `terraform/infra/` | VPC / Subnet / IGW / IAM / S3 / Route53 / ACM | 低 |
| アプリ層（app） | `terraform/app/` | Lambda / ECS / API Gateway / CloudWatch Alarms | 高 |

cross-state 参照は `terraform_remote_state` data source を用いてインフラ層の outputs をアプリ層に渡す。

---

## 理由

- **plan 高速化**: アプリ層だけ plan する場合、インフラ層リソースを走査しない
- **blast radius 縮小**: アプリ層の apply ミスがインフラ層に波及しない
- **CI/CD のレイテンシ削減**: 変更頻度の高いアプリ層のパイプラインが軽量になる
- **ロック競合の回避**: 将来のチーム開発時に state ロックが競合しにくい

管理ファイル数の増加・outputs 設計コストは初期に集中するが、中長期でトータルプラスと判断した。

---

## 却下した選択肢

| 案 | 却下理由 |
|:---|:---|
| 現状維持（単一 state） | リソース増加に伴い plan 時間が線形に増加し続ける |
| Terraform Workspace による分離 | Workspace は環境分離（prod/stg）向けであり、層分離には不向き |
| モジュール分割のみ | state は共有のままなので plan オーバーヘッドは変わらない |

---

## 影響・対処

| 項目 | 内容 |
|:---|:---|
| state 移行 | `terraform state mv` で既存リソースを移行。移行手順はドキュメント化必須 |
| outputs 設計 | インフラ層が出力すべき値（VPC ID / Subnet IDs / IAM Role ARN 等）を事前に洗い出す |
| CI/CD 分岐 | GitHub Actions で infra / app のワークフローを分ける |
| `terraform_remote_state` | S3 backend の場合は state ファイルパスを outputs として参照 |

---

## 参照

- [Issue #67 — tfstate をインフラ層・アプリ層に分離する](https://github.com/dhc4mens/daihou-sre/issues/67)
- [terraform-conventions.md](../terraform-conventions.md)
- [aws-account-baseline.md](../aws-account-baseline.md)
