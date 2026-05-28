# Terraform State Migration: infra/app 層分離

> ADR-001 / Issue #71 に基づく tfstate 分割手順
> **本手順は本番環境の state を操作するため、必ず手動で実行し各ステップを確認すること**

---

## 前提条件

- AWS CLI プロファイル `daihou-prod` が使用可能
- Terraform 1.5 以上がインストール済み
- `terraform/environments/prod/infra/` と `terraform/environments/prod/app/` のディレクトリが作成済み

---

## Step 1: infra 層の初期化とリソース import

```bash
cd terraform/environments/prod/infra

# S3 バックエンドに接続（新規の空 state が作成される）
terraform init

# IAM ロールを infra state に import
terraform import aws_iam_role.github_actions_plan daihou-sre-tf-plan-readonly
terraform import aws_iam_role_policy_attachment.github_actions_plan_readonly \
  daihou-sre-tf-plan-readonly/arn:aws:iam::aws:policy/ReadOnlyAccess
terraform import aws_iam_role.github_actions_deploy daihou-sre-tf-deploy
terraform import aws_iam_role_policy_attachment.github_actions_deploy_admin \
  daihou-sre-tf-deploy/arn:aws:iam::aws:policy/AdministratorAccess

# no-changes になることを確認
terraform plan
```

**期待する plan 出力:** `No changes. Your infrastructure matches the configuration.`

---

## Step 2: app 層の初期化（既存 state を再利用）

```bash
cd terraform/environments/prod/app

# 既存の prod state（daihou-sre/prod/terraform.tfstate）に接続
# app/backend.tf のキーは旧 prod と同一なので既存 state をそのまま使用
terraform init

# IAM OIDC リソースを app state から除去（infra 層に移管済み）
terraform state rm aws_iam_role.github_actions_plan
terraform state rm aws_iam_role_policy_attachment.github_actions_plan_readonly
terraform state rm aws_iam_role.github_actions_deploy
terraform state rm aws_iam_role_policy_attachment.github_actions_deploy_admin

# no-changes になることを確認
terraform plan
```

**期待する plan 出力:** `No changes. Your infrastructure matches the configuration.`

---

## Step 3: CI/CD ワークフローの更新

移行確認後、`.github/workflows/` を更新して各レイヤーを独立したジョブで実行する。

| ワークフロー | トリガーパス | 対象ディレクトリ |
|:---|:---|:---|
| `terraform-infra-ci.yml` | `terraform/environments/prod/infra/**` | `prod/infra` |
| `terraform-app-ci.yml` | `terraform/environments/prod/app/**` | `prod/app` |

---

## Step 4: 旧ファイルの削除

```bash
cd terraform/environments/prod

# infra 層に移管したファイル
rm github_oidc.tf

# app 層に移管したファイル
rm auth_edge.tf cognito.tf dashboard.tf monitoring.tf outputs.tf variables.tf backend.tf main.tf

# 旧 staging backend は別途対応
```

---

## ロールバック手順

infra 層の import が失敗した場合:

```bash
cd terraform/environments/prod/infra

# import したリソースを state から除去（AWS リソースは削除されない）
terraform state rm aws_iam_role.github_actions_plan
terraform state rm aws_iam_role_policy_attachment.github_actions_plan_readonly
terraform state rm aws_iam_role.github_actions_deploy
terraform state rm aws_iam_role_policy_attachment.github_actions_deploy_admin
```

app 層の `state rm` が失敗した場合:
- `terraform state push` で旧 state を復元（事前に `terraform state pull > backup.tfstate` でバックアップ）

---

## 参照

- [ADR-001](../docs/adr/001-terraform-state-layer-separation.md)
- [Issue #71](https://github.com/dhc4mens/daihou-sre/issues/71)
