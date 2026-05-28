# Runbook — ALB 5xxスパイク

最終更新: 2026-04-25
重要度: High
対象サービス: CloudLogAI（ALB + ECS Fargate）

---

## 症状

- CloudWatch Alarm: `ALB_5xxErrorRate` が閾値超過（> 0.5%）
- ユーザーから API エラー（500/502/503/504）の報告
- SLO の API可用性（≥99.5%）が脅かされている状態

## 原因候補

| # | エラーコード | 原因 | 確認ポイント |
|:---|:---|:---|:---|
| 1 | 502 Bad Gateway | ECSタスク停止・ヘルスチェック失敗 | ECSサービスの状態 |
| 2 | 503 Service Unavailable | 全ターゲットが Unhealthy | ALBターゲットグループ |
| 3 | 504 Gateway Timeout | アプリの処理遅延・タイムアウト | レイテンシメトリクス |
| 4 | 500 Internal Server Error | アプリバグ・DynamoDB/外部APIエラー | アプリログ |

## 調査手順

### 1. ALBメトリクスで状況確認
```bash
# 5xxエラー数を確認（直近30分）
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name HTTPCode_ELB_5XX_Count \
  --dimensions Name=LoadBalancer,Value=<alb-arn-suffix> \
  --start-time $(date -u -d '30 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Sum
```

### 2. ターゲットグループのヘルス確認
```bash
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn> \
  --query 'TargetHealthDescriptions[].{target:Target.Id,state:TargetHealth.State,reason:TargetHealth.Reason}'
```

### 3. アプリログでエラー確認
```bash
aws logs filter-log-events \
  --log-group-name /ecs/<service-name> \
  --start-time $(date -d '30 minutes ago' +%s000) \
  --filter-pattern "ERROR"
```

## 対応手順

### ケースA: ECSタスク停止 → `ecs-service-down.md` へ

### ケースB: 処理遅延（504）→ スケールアウト
```bash
aws ecs update-service \
  --cluster <cluster-name> \
  --service <service-name> \
  --desired-count 3
```

### ケースC: アプリバグ（500）→ 直前バージョンへロールバック
```bash
aws ecs update-service \
  --cluster <cluster-name> \
  --service <service-name> \
  --task-definition <family>:<previous-revision>
```

## 自動化TODO

- [ ] `HTTPCode_ELB_5XX_Count` Alarm → SNS でオンコール通知（#4）
- [ ] エラーレート > 1% が5分継続 → Lambda で自動スケールアウト（#4）

## 関連リソース

- ALB設定: `terraform/modules/alb/`
- SLO定義: `monitoring/slos/cloudlogai.md`（API可用性 ≥99.5%）
- ECSサービス停止時: `runbooks/ecs-service-down.md`
