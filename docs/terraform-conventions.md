# Terraform 命名・タグ規約（だいほう合同会社 共通）

> だいほう合同会社の全 Terraform コードに適用する横断規約。
> 各リポジトリ（daihou-gbp / CloudLogAI / その他）はこの規約に従う。
> 変更は本書を起点とし、各リポ側は参照するだけとする。

---

## 適用範囲

| リポジトリ | 適用 | 備考 |
|:---|:---:|:---|
| **daihou-gbp** | ✅ | `infrastructure/` 配下の Terraform |
| **CloudLogAI** | ✅ | `prototype/terraform/`, `iam/` |
| **daihou-sre** | ✅ | 本リポ `terraform/modules/`, `terraform/environments/` |
| daihou-corporate-site | - | CDK (TypeScript) のため対象外 |

---

## ファイル構成

```
<repo>/infrastructure/   or   daihou-sre/terraform/
├── main.tf          # provider, terraform block, locals, data sources
├── variables.tf     # 入力変数
├── outputs.tf       # 出力値
├── <feature>.tf     # 機能単位の1ファイル（vpc.tf, ecs.tf, iam.tf, ecr.tf, logs.tf …）
├── .gitignore       # tfstate 等を除外
├── .tflint.hcl      # TFLint ルール
├── terraform.tfvars.example  # 値サンプル（機密値はダミー）
└── README.md        # この環境の概要・使い方
```

**ルール:**
- 1リソース群 = 1ファイル（vpc 関連は vpc.tf、ecs 関連は ecs.tf 等）
- 複雑化したら `modules/` 配下へ切り出し
- 再利用可能なモジュールは **daihou-sre/terraform/modules/** に集約
- tfstate はローカル管理（チーム作業化したら S3 backend へ → [aws-account-baseline.md](aws-account-baseline.md) 参照）

---

## リソース命名

### プレフィックス
全リソース名は `${var.project_name}-<role>` 形式を基本とする。

| リソース種別 | パターン | 例 |
|:---|:---|:---|
| VPC / Subnet / IGW / NAT / RT / SG | `<project>-<component>` | `daihou-gbp-vpc`, `daihou-gbp-nat`, `daihou-gbp-public-rt`, `daihou-gbp-ecs-task-sg` |
| ECS Cluster | `<project>` | `daihou-gbp`, `cloudlogai` |
| ECS TaskDef (family) | パッケージ/サービス名 | `takatsuen-csv`, `benchmark` |
| ECR Repository | パッケージ/サービス名 | `takatsuen-csv`（Docker イメージタグの見た目を簡潔に） |
| CloudWatch Log Group | `/ecs/<service>` or `/aws/lambda/<name>` | `/ecs/takatsuen-csv`, `/aws/lambda/cloudlogai-ai-analyzer` |
| IAM Role（ECS実行用） | `<project>-ecs-task-execution` | `daihou-gbp-ecs-task-execution` |
| IAM Role（タスク固有） | `<project>-<service>-task` | `daihou-gbp-takatsuen-csv-task` |
| IAM Role（Lambda用） | `<project>-<function>` | `cloudlogai-ai-analyzer` |
| Secrets Manager Secret | `<project>/<client>/<service>` | `gbp/takatsuen/jaran` |
| Lambda Function | `<project>-<purpose>` | `daihou-gbp-dispatcher`, `cloudlogai-log-receiver` |
| S3 Bucket | `<project>-<purpose>` | `daihou-gbp-outputs`, `cloudlogai-logs-daihou-llc` |
| DynamoDB Table | `<project>-<purpose>` | `cloudlogai-customers`, `DaihouContacts-Production`（既存互換） |

### Terraform リソース ID（HCL 内）
- snake_case 固定（`aws_vpc.main`, `aws_ecs_cluster.main`）
- シングルインスタンスは `.main`、複数なら `.private` `.public` のように役割名

### モジュール呼び出し
- daihou-sre の共通モジュールを使う場合:
  ```hcl
  module "networking" {
    source       = "git::https://github.com/dhc4mens/daihou-sre.git//terraform/modules/networking?ref=main"
    project_name = "daihou-gbp"
    environment  = "production"
    # ...
  }
  ```
- バージョン固定は `?ref=<tag>` を使う（`main` は開発時）

---

## タグ規約

### ① 必須タグ（`default_tags` で自動付与、全リソース対象）

| キー | 値 | 用途 |
|:---|:---|:---|
| `Project` | `daihou-gbp` / `cloudlogai` 等 | システム名 |
| `Environment` | `production` / `staging` / `development` | 環境 |
| `ManagedBy` | `terraform` | 管理方式 |
| `Owner` | `daihou-llc` | 管理者（会社） |
| `Repository` | ソースリポ名 | 例: `daihou-gbp`, `CloudLogAI` |
| `CreatedDate` | `YYYY-MM-DD` | 初回作成日（運用識別目的） |

**実装:** `main.tf` の `locals.common_tags` → `provider "aws" { default_tags }` で注入。
変更は `locals.common_tags` を1箇所修正するだけで全リソースへ波及。

```hcl
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = "daihou-llc"
    Repository  = var.repository_name
    CreatedDate = var.created_date
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
  default_tags {
    tags = local.common_tags
  }
}
```

### ② リソース個別タグ（該当する場合のみ明示）

| キー | 値例 | 用途 |
|:---|:---|:---|
| `Name` | `daihou-gbp-vpc` | AWSコンソール表示名（IAMにも付与可） |
| `Component` | `network` / `compute` / `monitoring` / `iam` / `storage` / `data` | アーキテクチャ層（目的分類） |
| `Role` | `vpc` / `alb` / `ecs-cluster` / `ecs-service` / `lambda` / `s3` / `cloudwatch-alarm` / `log-group` / `nat-gateway` / `security-group` / `iam-role` / `iam-policy` / `secrets-manager` / `dynamodb` / `ecr` | リソース種別（Componentの2段目）。Cost Explorer・CloudWatch Insights での絞り込みに使用 |
| `ServiceCriticality` | `critical` / `high` / `medium` / `low` | 障害対応優先度。CloudWatchアラームSNS通知先・SLAの自動切り替え基準 |
| `Service` | `takatsuen-csv` / `benchmark` / `ai-analyzer` | サービス名（Componentより細かい粒度） |
| `Client` | `takatsuen` / `mishimaya` | クライアント別利用者（マルチテナントで必須） |
| `Tier` | `public` / `private` | サブネット等の区分 |
| `DataClassification` | `public` / `internal` / `confidential` / `pii` | データ分類（個人情報含むリソースに必須） |
| `CostCenter` | `gbp-takatsuen` / `cloudlogai-dev` | 請求按分の候補。Cost Explorer で使うには、組織の Management アカウントで**コスト配分タグとして有効化**する必要がある（付けただけでは集計に出ない） |
| `ExpiryDate` | `2026-12-31` / `none` | リソースのTTL。プロトタイプ・dev環境の放置防止。将来Lambda+EventBridgeで期限切れ通知に活用 |
| `BackupRequired` | `true` / `false` | AWS Backupのスコープ対象か否か |
| `BackupSchedule` | `daily` / `weekly` / `none` | バックアップ頻度（BackupRequired=true の場合に必須） |
| `Phase` | `Phase1` / `Phase2` 等 | 段階的デプロイのフェーズ（CloudLogAI等で利用） |

### ③ タグ運用ルール

- **DataClassification=pii** のリソースは削除・アクセス制御を厳格化
  - S3 出力バケット、予約情報を含むログ等
  - 個人情報保護法の対応文書で参照する
- **Client タグ** は複数クライアント対応時の必須識別子
  - 将来クライアント別コスト集計・削除対応で使う
- **CreatedDate** は初回作成日のみ。以降変更しない（監査証跡用）
- **共通リソース**（VPC/NAT等）は `Client` タグなし、`Component=network`
- **ServiceCriticality** の選定基準:
  - `critical`: 停止で即売上影響または個人情報漏洩リスク（本番ECSサービス、本番APIゲートウェイ等）
  - `high`: 停止で業務停止だが即時影響なし（バッチ処理、CloudWatch監視）
  - `medium`: 停止で不便が生じる（staging環境、開発補助ツール）
  - `low`: 停止しても運用継続可能（プロトタイプ、一時リソース）
- **ExpiryDate** はプロトタイプ・dev環境の新規リソース作成時に必須設定。無期限継続リソースは `none`
- **BackupRequired=true** のリソースは `BackupSchedule` も必須。S3/RDS/DynamoDB が主な対象

### ④ タグ付けしないもの

- IAM ポリシー（policy attachment、inline policy）
- ルートテーブル関連付け（route_table_association）
- 一部の AWS リソース（タグ非対応）

### ⑤ タグ強制の CI チェック

現状: `default_tags` により①の必須タグは**確実に付与される**（Terraform provider の仕組み）。

**②タグの強制方針（checkov カスタムルール）:**

| チェック対象 | 必須タグ | 対象リソース |
|:---|:---|:---|
| クライアント固有リソース | `Client` | `aws_ecs_task_definition`, `aws_lambda_function`, `aws_s3_bucket` |
| 個人情報含む可能性あり | `DataClassification` | `aws_s3_bucket`, `aws_secretsmanager_secret` |
| 本番リソース | `ServiceCriticality` | `aws_ecs_service`, `aws_lambda_function`（Environment=production 時） |

実装: `.checkov.yaml` にカスタムチェックを追加（Issue #50 で対応予定）。

---

## 変数命名

- snake_case 固定
- `description` 必須（AWS コンソール表示用）
- `type` 必須
- `default` 設定可能なものは可能な限り設定（再利用性）
- 機密値は `sensitive = true`
- 列挙型は `validation` ブロックで制約（例: `environment` は production/staging/development のみ）

---

## Outputs 命名

- `description` 必須（TFLint `terraform_documented_outputs` で強制）
- snake_case
- 他モジュール・スクリプトから参照されるものは意味のある名前に

---

## state 管理

- **初期段階: ローカル state**（個人開発、`terraform.tfstate`）
- **チーム化 or 本番ロック必要時: S3 backend + DynamoDB lock 移行**
- state 移行時は `terraform init -migrate-state` を使用
- 詳細: [aws-account-baseline.md](aws-account-baseline.md)

---

## 変更フロー（レビューチェック）

1. ブランチ切ってコード変更（`feature/XX-description` / `fix/XX-description` 等）
2. `terraform fmt -check -recursive` でフォーマット確認
3. `terraform validate` で構文チェック
4. `terraform plan` で意図通りの差分か確認（plan 結果を PR に添付）
5. PR 作成 → CI（fmt/validate/tflint/tfsec）自動実行
6. マージ後にローカルで `terraform apply`（将来 CI/CD 化検討）

---

## レビューチェックリスト（PR時）

- [ ] `terraform fmt` 実施済
- [ ] `terraform validate` Pass
- [ ] CI（tflint/tfsec）Pass
- [ ] `terraform plan` 差分が意図通り（PR 本文に添付）
- [ ] 新規リソースに①必須タグが付与される（default_tags で自動付与済）
- [ ] クライアント固有リソースに `Client` タグ付与
- [ ] 個人情報含む可能性あるリソースに `DataClassification` 付与
- [ ] ECS/Lambda に `ServiceCriticality` 付与（production 環境は必須）
- [ ] `Component` に対応する `Role` を付与（コスト集計・運用監視対象リソース）
- [ ] プロトタイプ・dev リソースに `ExpiryDate` を設定
- [ ] S3/DynamoDB/RDS に `BackupRequired` / `BackupSchedule` を設定
- [ ] リソース名が命名規約に沿う
- [ ] 機密値が state に平文で入らない（Secrets Manager 参照）
- [ ] destroy 時の影響範囲が把握できている（data が失われる場合は prevent_destroy）
- [ ] 月額コスト増分の見積り（特に NAT Gateway・NLB・RDS等の高額リソース）

---

## 非推奨パターン

- ハードコードされた ARN / ID（data source や variable で参照）
- `count` での複雑な制御（`for_each` + map 推奨）
- 複数環境をワンファイルで分岐（workspace or tfvars で分離）
- state の手動編集（`terraform state mv` 等 CLI 経由のみ）
- インライン IAM policy の乱用（再利用性なし、JSON 長い場合は `aws_iam_policy_document`）

---

## 参照

- [aws-account-baseline.md](aws-account-baseline.md) — AWSアカウント・プロファイル・リージョン等の基本情報
- [daihou-gbp/infrastructure/](https://github.com/dhc4mens/daihou-gbp/tree/main/infrastructure) — GBP の実装例
- [CloudLogAI/prototype/terraform/](https://github.com/dhc4mens/CloudLogAI/tree/main/prototype/terraform) — CloudLogAI の実装例

---

最終更新: 2026-04-21
