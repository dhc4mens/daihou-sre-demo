# networking モジュール

VPC + シングルAZ（Public/Private subnet）+ オプションで NAT Gateway + 汎用 ECS Task SG。

Fargate サービスや Lambda VPC 配置など、だいほう合同会社の標準ネットワーク構成。

## 作成されるリソース

- VPC（DNSサポート有効）
- Internet Gateway
- Public Subnet（`map_public_ip_on_launch = true`）
- Private Subnet
- NAT Gateway + EIP（オプション。月額約$32）
- Route Table × 2（public / private）
- Security Group（ECS Task 用、outbound only。オプション）

## 使い方

### 最小構成

```hcl
module "networking" {
  source       = "git::https://github.com/dhc4mens/daihou-sre.git//terraform/modules/networking?ref=main"
  project_name = "daihou-gbp"
}
```

デフォルトで ap-northeast-1a に 10.10.0.0/16 VPC、Public/Private subnet、NAT Gateway、ECS Task 用 SG を作成。

### NAT 不要時（コスト削減）

```hcl
module "networking" {
  source             = "git::https://github.com/dhc4mens/daihou-sre.git//terraform/modules/networking?ref=main"
  project_name       = "my-project"
  enable_nat_gateway = false
}
```

Private subnet からの outbound は不可になるので、ECS Task は Public subnet に配置するか、VPC Endpoint を別途追加する設計が必要。

### CIDR をカスタマイズ

```hcl
module "networking" {
  source              = "git::https://github.com/dhc4mens/daihou-sre.git//terraform/modules/networking?ref=main"
  project_name        = "cloudlogai"
  availability_zone   = "ap-northeast-1c"
  vpc_cidr            = "10.20.0.0/16"
  public_subnet_cidr  = "10.20.0.0/24"
  private_subnet_cidr = "10.20.1.0/24"
}
```

### 汎用 SG を作らない（サービス毎に個別定義したい場合）

```hcl
module "networking" {
  source                 = "git::https://github.com/dhc4mens/daihou-sre.git//terraform/modules/networking?ref=main"
  project_name           = "my-project"
  create_default_task_sg = false
}
```

## 入力変数

| 変数 | 型 | デフォルト | 説明 |
|:---|:---|:---|:---|
| `project_name` | string | （必須） | リソース名のプレフィックス |
| `availability_zone` | string | `ap-northeast-1a` | シングルAZ構成で使用するAZ |
| `vpc_cidr` | string | `10.10.0.0/16` | VPC の CIDR |
| `public_subnet_cidr` | string | `10.10.0.0/24` | Public subnet の CIDR |
| `private_subnet_cidr` | string | `10.10.1.0/24` | Private subnet の CIDR |
| `enable_nat_gateway` | bool | `true` | NAT Gateway を作成するか |
| `create_default_task_sg` | bool | `true` | 汎用 ECS Task SG を作成するか |
| `extra_tags` | map(string) | `{}` | 全リソース追加タグ |

## 出力

| 出力 | 説明 |
|:---|:---|
| `vpc_id` | VPC の ID |
| `vpc_cidr_block` | VPC の CIDR |
| `public_subnet_id` | Public subnet の ID（シングル） |
| `private_subnet_id` | Private subnet の ID（シングル） |
| `public_subnet_ids` | Public subnet ID の list（将来の Multi-AZ 対応） |
| `private_subnet_ids` | Private subnet ID の list（同上） |
| `internet_gateway_id` | IGW の ID |
| `nat_gateway_id` | NAT Gateway の ID（`enable_nat_gateway=false` なら null） |
| `ecs_task_security_group_id` | 汎用 ECS Task SG の ID（`create_default_task_sg=false` なら null） |
| `availability_zone` | 使用している AZ |

## 前提・注意

- **シングルAZ構成。** Multi-AZ にするには現状モジュール外で複数回呼ぶか、将来 `for_each` 対応版を作る
- **default_tags で必須タグ注入が前提。** `Project / Environment / ManagedBy / Owner / Repository / CreatedDate` は呼び出し側の provider で設定すること
- 詳細: [terraform-conventions.md](../../../docs/terraform-conventions.md)

## コスト

- **NAT Gateway**: 固定 約$32/月 + データ処理 $0.045/GB
- **EIP**（NAT紐付け時は課金なし）
- **VPC / Subnet / IGW / Route Table**: 無料
- **EIP（未紐付け）**: $3.6/月

## 既存 daihou-gbp からの移行

`daihou-gbp/infrastructure/vpc.tf` をこのモジュール呼び出しに置き換える予定（別PR）。
