# Runbook — ECSタスク起動失敗

最終更新: 2026-04-25
重要度: High
対象サービス: CloudLogAI（ECS Fargate）

---

## 症状

- ECSコンソールでタスクが `STOPPED` 状態を繰り返す
- サービスイベントに `task failed to start` が記録される
- `RunningTaskCount` が `DesiredCount` を下回り続ける

## 原因候補

| # | 原因 | 確認ポイント |
|:---|:---|:---|
| 1 | ECRイメージ取得失敗 | `runbooks/fargate-image-pull-fail.md` 参照 |
| 2 | コンテナのクラッシュ（アプリエラー） | CloudWatch Logs の起動ログ |
| 3 | メモリ/CPU不足 | タスク定義のリソース設定 |
| 4 | 環境変数・シークレット取得失敗 | Secrets Manager / SSM パラメータの権限 |
| 5 | ヘルスチェック失敗 | ALBヘルスチェックの設定・アプリの `/health` エンドポイント |

## 調査手順

### 1. タスク停止理由を確認
```bash
# 停止タスクの一覧
aws ecs list-tasks \
  --cluster <cluster-name> \
  --desired-status STOPPED \
  --query 'taskArns[0:3]'

# 停止理由の詳細
aws ecs describe-tasks \
  --cluster <cluster-name> \
  --tasks <task-arn> \
  --query 'tasks[0].{stopCode:stopCode,stoppedReason:stoppedReason,containers:containers[].{name:name,reason:reason,exitCode:exitCode}}'
```

### 2. コンテナログを確認
```bash
# 起動直後のログを確認
aws logs tail /ecs/<service-name> --since 1h --format short
```

### 3. シークレット取得権限を確認
```bash
# タスクロールのポリシーを確認
aws iam list-role-policies --role-name <task-role-name>
aws iam list-attached-role-policies --role-name <task-role-name>
```

## 対応手順

### ケースA: アプリクラッシュ → ログ確認して修正デプロイ
1. `aws logs tail` でスタックトレースを確認
2. コードを修正して新イメージをビルド・push
3. `aws ecs update-service --force-new-deployment` で再デプロイ

### ケースB: メモリ不足 → タスク定義を更新
```bash
# 新しいタスク定義リビジョンを登録（memory を増加）
aws ecs register-task-definition --cli-input-json file://task-def.json

# サービスを新リビジョンで更新
aws ecs update-service \
  --cluster <cluster-name> \
  --service <service-name> \
  --task-definition <family>:<new-revision>
```

### ケースC: シークレット取得失敗 → IAMポリシーを確認・修正
1. Secrets Manager / SSM の該当シークレットのARNを確認
2. タスクロールに `secretsmanager:GetSecretValue` 権限を付与
3. Terraform で `aws_iam_role_policy` を更新してデプロイ

## 自動化TODO

- [ ] 起動失敗ループ検知（StoppedTaskCount > N）→ Slack/SNS 通知（#4）
- [ ] 失敗ログを S3 に自動保存して事後分析を容易にする

## 関連リソース

- ECS タスク定義: `terraform/modules/ecs-fargate-taskdef/`
- イメージ取得失敗時: `runbooks/fargate-image-pull-fail.md`
- サービス停止時: `runbooks/ecs-service-down.md`
