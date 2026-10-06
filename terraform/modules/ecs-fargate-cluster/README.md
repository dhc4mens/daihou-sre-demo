# ecs-fargate-cluster モジュール

ECS Cluster（Fargate 前提）+ Capacity Providers + 共有 Task Execution Role を作成する。

プロジェクトごとに **1個だけ** 作成する想定。配下のタスクは `ecs-fargate-taskdef` モジュールで定義する。

## 作成されるリソース

- `aws_ecs_cluster` — Container Insights enhanced がデフォルトで有効
- `aws_ecs_cluster_capacity_providers` — FARGATE + FARGATE_SPOT
- `aws_iam_role` (task execution) — 全タスクで共有
- `aws_iam_role_policy_attachment` — `AmazonECSTaskExecutionRolePolicy`（AWS managed）
- `aws_iam_role_policy` (Secrets Manager 読取、`secrets_manager_prefix_arns` 指定時のみ)

## 使い方

### 最小構成

```hcl
module "ecs_cluster" {
  source       = "git::https://github.com/dhc4mens/daihou-sre.git//terraform/modules/ecs-fargate-cluster?ref=main"
  project_name = "daihou-gbp"
}
```

### Secrets Manager 連携付き（Fargate タスクからシークレット読み込み想定）

```hcl
module "ecs_cluster" {
  source       = "git::https://github.com/dhc4mens/daihou-sre.git//terraform/modules/ecs-fargate-cluster?ref=main"
  project_name = "daihou-gbp"

  secrets_manager_prefix_arns = [
    "arn:aws:secretsmanager:ap-northeast-1:123456789012:secret:gbp/*",
  ]
}
```

### Container Insights を無効化（コスト削減）

```hcl
module "ecs_cluster" {
  source       = "git::https://github.com/dhc4mens/daihou-sre.git//terraform/modules/ecs-fargate-cluster?ref=main"
  project_name = "my-project"

  enable_container_insights_enhanced = false
}
```

### デフォルトを Fargate Spot に（コスト優先）

```hcl
module "ecs_cluster" {
  source       = "git::https://github.com/dhc4mens/daihou-sre.git//terraform/modules/ecs-fargate-cluster?ref=main"
  project_name = "my-project"

  default_capacity_provider = "FARGATE_SPOT"
}
```

## 入力変数

| 変数 | 型 | デフォルト | 説明 |
|:---|:---|:---|:---|
| `project_name` | string | （必須） | クラスタ名と IAM Role のプレフィックス |
| `cluster_name` | string | `null` | クラスタ名を明示指定（未指定なら project_name） |
| `enable_container_insights_enhanced` | bool | `true` | enhanced metrics を有効化 |
| `capacity_providers` | list(string) | `["FARGATE", "FARGATE_SPOT"]` | 利用可能な capacity provider |
| `default_capacity_provider` | string | `FARGATE` | デフォルト |
| `secrets_manager_prefix_arns` | list(string) | `[]` | Secrets Manager 読み取り対象 ARN |
| `extra_tags` | map(string) | `{}` | 全リソース追加タグ |

## 出力

| 出力 | 説明 |
|:---|:---|
| `cluster_id` | ECS Cluster ID |
| `cluster_arn` | ECS Cluster ARN |
| `cluster_name` | ECS Cluster 名 |
| `task_execution_role_arn` | Task Execution Role の ARN（TaskDef に渡す） |
| `task_execution_role_name` | Task Execution Role 名 |

## 前提・注意

- **default_tags で必須タグ注入が前提。** 呼び出し側 provider で `Project / Environment / ManagedBy / Owner / Repository / CreatedDate` を設定
- **Container Insights enhanced** は追加コストあり（金額は [CloudWatch の料金](https://aws.amazon.com/cloudwatch/pricing/) を参照）。本格運用前は無効化検討可
- クラスタ単体は無料、課金は配下タスクの vCPU/メモリ単価

## 既存 daihou-gbp からの移行

`daihou-gbp/infrastructure/ecs.tf` と `iam.tf` の Task Execution Role 部分をこのモジュール呼び出しに置き換え可能（別PR）。
