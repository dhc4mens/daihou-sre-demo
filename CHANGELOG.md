# Changelog

このリポジトリの変更履歴。[Keep a Changelog](https://keepachangelog.com/ja/1.0.0/) 準拠。

## [Unreleased]

### Security
- 🔴 **AWS アカウントIDの露出を解消**（#5）。**PUBLIC リポジトリに実アカウントIDが17箇所**含まれていた（SNS トピック ARN・Secrets Manager パス・ECR リポジトリURL）
  - `terraform/modules/monitoring/` の直書き ARN 14箇所を**変数参照に置換**（`var.sns_topic_arn` / 新設した `var.ses_sns_topic_arn`）。もともと `sns_topic_arn` 変数は宣言されていたが `alarms_ecs.tf` でしか使われておらず、他6ファイルは ARN を直書きしていた
  - `variables.tf` の `sns_topic_arn` から **`default` を削除**。既定値として本番の SNS ARN が焼き込まれていた
  - モジュール README 3箇所の例示IDを、AWS ドキュメント用ダミー `123456789012` に統一（`alb/README.md` は元からこの値だった）
  - ⚠️ **git 履歴には残る**（初回コミット `eb4b53b`）。アカウントIDは資格情報ではなく、履歴書き換えは force push を要してブランチ保護と衝突するため、作業ツリーの是正にとどめた

### Added
- **README に「このリポの読み方（閲覧専用）」節を追加**（#5）。`terraform/` は `modules/` のみで `environments/` を持たず **`terraform apply` は通らない**こと、実値は読み手側で入れる前提であることを明記
- CLAUDE.md に **PUBLIC リポ向けの投稿前チェック**を追加（アカウントID・実ARN・実ドメインの grep コマンド）

### Fixed
- **CI で `.tf` を含む PR が必ず落ちていたのを修正**（#5）。`ci.yml` が Terraform をインストールしないまま pre-commit を実行しており、`terraform_fmt` フックが `exit 127`（`Neither Terraform nor OpenTofu binary could be found`）で失敗していた
  - 初回リリース以降 PR が1件も無かったため、**本 PR が初めて踏んだ**潜在バグ
  - `hashicorp/setup-terraform` を追加（daihou-portal の `ci.yml` から実態コピー）

### Changed
- CLAUDE.md をテンプレートのまま（差分8行）から実態に合わせて全面更新（#5）。構成の写しは持たず README を正本として参照する形にした
- TODO.md の `{{PROJECT_NAME}}` を置換し、手書きの「ピックアップ中のIssue」欄を GitHub のクエリリンクに置き換え（#5）

---

## [1.0.0] - 2026-05-29

### Added
- SRE基盤デモリポジトリ初回リリース
- runbooks/ — インシデント対応手順書7本
- terraform/modules/ — 再利用可能なTerraformモジュール5本（alb/ecs-fargate-cluster/ecs-fargate-taskdef/monitoring/networking）
- docs/adr/ — Architecture Decision Records 4本
- docs/terraform-conventions.md — Terraform命名・設計規約
- monitoring/slos/ — SLO定義2本（CloudLogAI / corporate-site）
- README.md — SRE思想・設計方針・面談用エビデンス
