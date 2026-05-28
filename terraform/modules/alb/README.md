# terraform/modules/alb

HTTPS 前提・複数サービス対応の Application Load Balancer モジュール。

## 設計方針

- **internet-facing** ALB を 1 つ作成（複数サービスで共有）
- HTTP 80 → HTTPS 443 リダイレクトを自動設定
- HTTPS リスナーのデフォルトアクションは `404 fixed-response`
- サービスごとに `aws_lb_listener_rule` を追加してルーティングを拡張
- ACM 証明書 ARN は呼び出し側から渡す（モジュール内では作成しない）

## 使用例

```hcl
module "alb" {
  source = "../../modules/alb"

  project_name        = "daihou-gbp"
  vpc_id              = module.networking.vpc_id
  subnet_ids          = module.networking.public_subnet_ids
  acm_certificate_arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/xxxx"

  enable_deletion_protection = true  # 本番環境
  extra_tags = {
    Environment = "prod"
  }
}

# サービス側でリスナールールを追加
resource "aws_lb_listener_rule" "my_service" {
  listener_arn = module.alb.https_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_service.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}
```

## インプット

| 変数 | 型 | 必須 | デフォルト | 説明 |
|:---|:---|:---:|:---|:---|
| `project_name` | string | ✅ | - | プロジェクト名（小文字英数字・ハイフン） |
| `vpc_id` | string | ✅ | - | ALB を配置する VPC ID |
| `subnet_ids` | list(string) | ✅ | - | パブリックサブネット ID リスト（2AZ 以上） |
| `acm_certificate_arn` | string | ✅ | - | HTTPS 用 ACM 証明書 ARN |
| `name` | string | | `<project_name>-alb` | ALB 名（上書き可） |
| `allowed_cidr_blocks` | list(string) | | `["0.0.0.0/0"]` | インバウンド許可 CIDR |
| `ssl_policy` | string | | `ELBSecurityPolicy-TLS13-1-2-2021-06` | SSL ポリシー |
| `enable_deletion_protection` | bool | | `false` | 削除保護（本番 true 推奨） |
| `idle_timeout` | number | | `60` | アイドルタイムアウト（秒） |
| `access_logs_bucket` | string | | `null` | アクセスログ S3 バケット（null=無効） |
| `access_logs_prefix` | string | | `"alb"` | アクセスログ S3 プレフィックス |
| `extra_tags` | map(string) | | `{}` | 追加タグ |

## アウトプット

| 出力 | 説明 |
|:---|:---|
| `alb_arn` | ALB ARN |
| `alb_arn_suffix` | ARN サフィックス（CloudWatch メトリクス用） |
| `alb_dns_name` | DNS 名（Route 53 エイリアス用） |
| `alb_zone_id` | ホストゾーン ID（Route 53 エイリアス用） |
| `alb_name` | ALB 名 |
| `http_listener_arn` | HTTP リスナー ARN |
| `https_listener_arn` | HTTPS リスナー ARN（サービス側でルール追加） |
| `alb_security_group_id` | ALB SG ID（ECS タスク SG の ingress 設定用） |
