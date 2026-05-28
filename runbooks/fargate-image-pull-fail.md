# Runbook — Fargateイメージ取得失敗（ECR pull失敗）

最終更新: 2026-04-25
重要度: High
対象サービス: CloudLogAI（ECS Fargate + ECR）

---

## 症状

- ECSタスクが `STOPPED` 状態で停止
- タスク停止理由に以下のいずれかが表示される:
  - `CannotPullContainerError`
  - `ImagePullBackoff`
  - `ECR: authorization token has expired`

## 原因候補

| # | 原因 | 確認ポイント |
|:---|:---|:---|
| 1 | タスク実行ロールのECR権限不足 | IAMロールの `ecr:GetAuthorizationToken` 等 |
| 2 | 指定タグが ECR に存在しない | ECRコンソール / タスク定義のイメージURI |
| 3 | ECR リポジトリが別リージョン | タスク定義のイメージURIのリージョン部分 |
| 4 | VPCからECRへの疎通なし（NAT/VPCエンドポイント） | VPC設定・セキュリティグループ |
| 5 | ECR ライフサイクルポリシーでイメージが削除済み | ECRコンソール → ライフサイクルポリシー |

## 調査手順

### 1. タスク停止理由を確認
```bash
aws ecs describe-tasks \
  --cluster <cluster-name> \
  --tasks <task-arn> \
  --query 'tasks[0].containers[0].{reason:reason,status:lastStatus}'
```

### 2. ECRイメージの存在確認
```bash
# タスク定義のイメージURIを確認
aws ecs describe-task-definition \
  --task-definition <family> \
  --query 'taskDefinition.containerDefinitions[0].image'

# ECRにそのタグが存在するか確認
aws ecr list-images \
  --repository-name <repo-name> \
  --query 'imageIds[?imageTag==`<tag>`]'
```

### 3. タスク実行ロールの権限確認
```bash
aws iam list-attached-role-policies \
  --role-name <task-execution-role-name>
# AmazonECSTaskExecutionRolePolicy がアタッチされているか確認
```

## 対応手順

### ケースA: タグ指定ミス → 正しいタグで再デプロイ
1. ECRコンソールで正しいタグを確認
2. タスク定義を正しいイメージURIで更新
3. `aws ecs update-service --force-new-deployment`

### ケースB: IAM権限不足 → タスク実行ロールにポリシーを追加
```bash
# AmazonECSTaskExecutionRolePolicy をアタッチ
aws iam attach-role-policy \
  --role-name <task-execution-role-name> \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
```

### ケースC: ECRにイメージなし → CI/CDから再ビルド・push
1. GitHub Actions で該当ブランチのワークフローを手動実行
2. イメージが push されたことを ECR コンソールで確認
3. ECS サービスを `force-new-deployment` で更新

## 自動化TODO

- [ ] `CannotPullContainerError` 検知 → SNS でアラート通知（#4）
- [ ] ECRライフサイクルポリシーで最新5イメージは保護する設定を追加

## 関連リソース

- タスク定義: `terraform/modules/ecs-fargate-taskdef/`
- ECSサービス停止時: `runbooks/ecs-service-down.md`
- タスク起動失敗時: `runbooks/ecs-task-failed.md`
