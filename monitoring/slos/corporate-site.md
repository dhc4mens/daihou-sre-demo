# SLI/SLO定義 — daihou-corporate-site

最終更新: 2026-04-25
対象: だいほう合同会社 コーポレートサイト（S3 + CloudFront + Lambda）

---

## サービス概要

| 項目 | 内容 |
|:---|:---|
| 構成 | S3（静的ホスティング）+ CloudFront + Lambda（お問い合わせフォーム） |
| 重要度 | High（見込み客への窓口） |
| 計測ソース | CloudWatch（CloudFront / Lambda メトリクス） |

---

## SLI / SLO

| # | SLI名 | 指標 | 計測方法 | SLO | エラーバジェット（月次） |
|:---|:---|:---|:---|:---|:---|
| 1 | サイト可用性 | CloudFront 5xxエラーレート | `5xxErrorRate` / 総リクエスト数 | ≥ 99.9% | 43分/月 |
| 2 | レイテンシ | CloudFront P95応答時間 | `OriginLatency` P95 | ≤ 500ms | - |
| 3 | フォーム成功率 | Lambda（お問い合わせ）成功率 | `Errors` / `Invocations` | ≥ 99.5% | 3.6時間/月 |

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
| 5xxエラーレート | > 0.05% | > 0.1% |
| P95レイテンシ | > 300ms | > 500ms |
| Lambda エラー率 | > 0.3% | > 0.5% |

---

## 関連リソース

- CloudWatch Alarm: `terraform/modules/monitoring/` 参照
- Runbook: `runbooks/error-budget.md`
