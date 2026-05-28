# ecs-fargate-taskdef モジュール

ECS Fargate で1サービスを動かすための周辺リソース一式:

- ECR Repository + lifecycle policy（オプション）
- CloudWatch Log Group
- Task Role（アプリ固有の AWS 権限）
- Task Definition（Fargate 前提）

**長時間稼働型 Service（`aws_ecs_service`）は含まない。** RunTask 運用で十分な用途を想定している（daihou-gbp の takatsuen-csv 等）。Service が必要なら呼び出し側で別途作成する。

## 前提

- `ecs-fargate-cluster` モジュールを先に作成しておく（`task_execution_role_arn` を受け取る）

## 使い方

### 最小構成（takatsuen-csv 例）

```hcl
module "ecs_cluster" {
  source       = "git::https://github.com/dhc4mens/daihou-sre.git//terraform/modules/ecs-fargate-cluster?ref=main"
  project_name = "daihou-gbp"
}

module "takatsuen_csv" {
  source       = "git::https://github.com/dhc4mens/daihou-sre.git//terraform/modules/ecs-fargate-taskdef?ref=main"
  project_name = "daihou-gbp"
  service_name = "takatsuen-csv"

  task_execution_role_arn = module.ecs_cluster.task_execution_role_arn

  cpu    = "1024"
  memory = "4096"

  client_tag          = "takatsuen"
  data_classification = "pii"

  container_definitions = [
    {
      name      = "takatsuen-csv"
      image     = "${module.takatsuen_csv.ecr_repository_url}:latest"
      essential = true
      portMappings = [
        { containerPort = 8000, protocol = "tcp" }
      ]
      environment = [
        { name = "PORT", value = "8000" }
      ]
    }
  ]
}
```

`logConfiguration` はモジュール側で `/ecs/<service_name>` に自動注入される。

### ECR 既存利用時（モジュール内で作らない）

```hcl
module "svc" {
  source       = "git::https://github.com/dhc4mens/daihou-sre.git//terraform/modules/ecs-fargate-taskdef?ref=main"
  project_name = "daihou-gbp"
  service_name = "benchmark"

  task_execution_role_arn = module.ecs_cluster.task_execution_role_arn

  create_ecr_repository = false
  ecr_repository_url    = "182803334083.dkr.ecr.ap-northeast-1.amazonaws.com/benchmark"

  container_definitions = [
    { name = "benchmark", image = "182803334083.dkr.ecr.ap-northeast-1.amazonaws.com/benchmark:v1.0", essential = true }
  ]
}
```

### Task Role に S3 書き込み権限を追加

```hcl
module "svc" {
  source = "git::https://github.com/dhc4mens/daihou-sre.git//terraform/modules/ecs-fargate-taskdef?ref=main"
  # ... 省略 ...

  task_role_policies = {
    s3-outputs = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject"]
        Resource = "arn:aws:s3:::daihou-gbp-outputs/*"
      }]
    })
  }
}
```

### ARM64（Graviton）で動かす

```hcl
module "svc" {
  source           = "git::https://github.com/dhc4mens/daihou-sre.git//terraform/modules/ecs-fargate-taskdef?ref=main"
  # ... 省略 ...
  cpu_architecture = "ARM64"
}
```

## 入力変数

| 変数 | 型 | デフォルト | 説明 |
|:---|:---|:---|:---|
| `project_name` | string | （必須） | IAM プレフィックス |
| `service_name` | string | （必須） | ECR / Log / TaskDef family 名 |
| `task_execution_role_arn` | string | （必須） | cluster モジュールの出力を渡す |
| `cpu` | string | `"512"` | Fargate vCPU 値 |
| `memory` | string | `"1024"` | Fargate メモリ（MB） |
| `container_definitions` | any | （必須） | container def のリスト |
| `cpu_architecture` | string | `X86_64` | `X86_64` / `ARM64` |
| `create_ecr_repository` | bool | `true` | ECR をモジュール内で作成 |
| `ecr_repository_url` | string | `null` | 外部 ECR 利用時 |
| `ecr_image_tag` | string | `latest` | 参照する image タグ（予約、現状未使用） |
| `ecr_keep_image_count` | number | `10` | ECR で保持する世代 |
| `log_retention_days` | number | `30` | CloudWatch Logs 保持日数 |
| `task_role_policies` | map(string) | `{}` | Task Role inline policy（name -> JSON） |
| `auto_inject_log_config` | bool | `true` | logConfiguration 自動注入 |
| `aws_region` | string | `ap-northeast-1` | awslogs 用リージョン |
| `client_tag` | string | `null` | Client タグ（マルチテナント時） |
| `data_classification` | string | `null` | `public / internal / confidential / pii` |
| `extra_tags` | map(string) | `{}` | 追加タグ |

## 出力

| 出力 | 説明 |
|:---|:---|
| `task_definition_arn` | 最新リビジョン込みの ARN |
| `task_definition_family` | family 名 |
| `task_definition_revision` | リビジョン番号 |
| `task_role_arn` / `task_role_name` | Task Role |
| `ecr_repository_url` | ECR URL（作成 or 渡された値） |
| `ecr_repository_arn` | ECR ARN（作成時のみ） |
| `log_group_name` / `log_group_arn` | CloudWatch Log Group |

## ECR への push（参考）

```bash
AWS_PROFILE=daihou-prod aws ecr get-login-password --region ap-northeast-1 | \
  docker login --username AWS --password-stdin \
  $(terraform output -raw ecr_url_base)

docker build -t takatsuen-csv:latest .
docker tag takatsuen-csv:latest <ecr_repository_url>:latest
docker push <ecr_repository_url>:latest
```

## 既存 daihou-gbp からの移行

`daihou-gbp/infrastructure/ecs.tf` (TaskDef 部分) + `ecr.tf` + `iam.tf` (task role 部分) をこのモジュール呼び出しに置換可能。
