# Runbook — ECSサービス停止

最終更新: 2026-04-25
重要度: Critical
対象サービス: CloudLogAI（ECS Fargate）

---

## 症状

- CloudWatch Alarm: `ECSServiceRunningTaskCount` が 0 に低下
- ALBヘルスチェック: 全ターゲットが Unhealthy
- ユーザーからの API エラー報告（502/503）

## 原因候補

| # | 原因 | 確認方法 |
|:---|:---|:---|
| 1 | タスク起動失敗（後述 ecs-task-failed.md 参照） | ECSコンソール → タスク履歴 |
| 2 | デプロイ失敗によるロールバック中 | ECSコンソール → デプロイ履歴 |
| 3 | キャパシティ不足（Fargate リソース上限） | CloudWatch → ECS メトリクス |
| 4 | タスク定義の誤設定 | ECSコンソール → タスク定義 |

## 調査手順

### 1. サービス状態確認
```bash
# サービスの現在の状態を確認
aws ecs describe-services \
  --cluster <cluster-name> \
  --services <service-name> \
  --query 'services[0].{status:status,runningCount:runningCount,desiredCount:desiredCount,events:events[0:5]}'
```

### 2. 停止タスクのログ確認
```bash
# 最近の停止タスクを取得
aws ecs list-tasks \
  --cluster <cluster-name> \
  --desired-status STOPPED \
  --query 'taskArns[0:5]'

# タスク停止理由を確認
aws ecs describe-tasks \
  --cluster <cluster-name> \
  --tasks <task-arn> \
  --query 'tasks[0].{stopCode:stopCode,stoppedReason:stoppedReason,containers:containers[0].reason}'
```

### 3. CloudWatch Logsでエラー確認
```bash
aws logs tail /ecs/<service-name> --since 30m
```

## 対応手順

### ケースA: デプロイ失敗 → ロールバック
```bash
# 直前のタスク定義リビジョンを確認
aws ecs describe-task-definition --task-definition <family> --query 'taskDefinition.revision'

# 前のリビジョンでサービスを更新
aws ecs update-service \
  --cluster <cluster-name> \
  --service <service-name> \
  --task-definition <family>:<previous-revision>
```

### ケースB: サービスを強制再起動
```bash
aws ecs update-service \
  --cluster <cluster-name> \
  --service <service-name> \
  --force-new-deployment
```

### ケースC: タスク数を手動スケールアップ
```bash
aws ecs update-service \
  --cluster <cluster-name> \
  --service <service-name> \
  --desired-count 2
```

## 自動化TODO

- [ ] CloudWatch Alarm（RunningTaskCount=0）→ Lambda で `force-new-deployment` を自動実行（#4）
- [ ] 復旧失敗時に SNS 通知でオンコール呼び出し

## 関連リソース

- ECS クラスター: `terraform/environments/prod/app/main.tf`
- SLO定義: `monitoring/slos/cloudlogai.md`
- タスク起動失敗時: `runbooks/ecs-task-failed.md`
