# SLI/SLO定義 — CloudLogAI

最終更新: 2026-04-25
対象: CloudLogAI（ECS Fargate + ALB + DynamoDB + Lambda + Cognito）

---

## サービス概要

| 項目 | 内容 |
|:---|:---|
| 構成 | ECS Fargate（API）+ ALB + DynamoDB + Lambda（異常検知）+ Cognito（認証） |
| 重要度 | High（本番SaaS・課金サービス） |
| 計測ソース | CloudWatch（ALB / ECS / DynamoDB / Lambda メトリクス） |

---

## SLI / SLO

| # | SLI名 | 指標 | 計測方法 | SLO | エラーバジェット（月次） |
|:---|:---|:---|:---|:---|:---|
| 1 | API可用性 | ALB 5xxエラーレート | `HTTPCode_ELB_5XX_Count` / 総リクエスト数 | ≥ 99.5% | 3.6時間/月 |
| 2 | APIレイテンシ | ALB P95応答時間 | `TargetResponseTime` P95 | ≤ 1000ms | - |
| 3 | データ書き込み成功率 | DynamoDB 書き込み成功率 | `SystemErrors` / 総書き込み数 | ≥ 99.9% | 43分/月 |
| 4 | 異常検知処理成功率 | Lambda 成功率 | `Errors` / `Invocations` | ≥ 99.5% | 3.6時間/月 |
| 5 | ECSタスク健全性 | 健全タスク比率 | `RunningTaskCount` / `DesiredTaskCount` | ≥ 99.5% | 3.6時間/月 |

---

## エラーバジェット計算

| SLO | 許容ダウンタイム（月） | 換算 |
|:---|:---|:---|
| 99.9% | 43.2分 | 約43分 |
| 99.5% | 216分 | 約3.6時間 |

---

## アラート閾値（目安）

| SLI | Warning | Critical |
|:---|:---|:---|
| ALB 5xxエラーレート | > 0.2% | > 0.5% |
| P95レイテンシ | > 700ms | > 1000ms |
| DynamoDB エラー率 | > 0.05% | > 0.1% |
| Lambda エラー率 | > 0.3% | > 0.5% |
| ECSタスク健全性 | < 100% | < 50% |

---

## 関連リソース

- CloudWatch Alarm: `terraform/environments/prod/app/monitoring.tf` 参照
- Runbook: `runbooks/error-budget.md`
