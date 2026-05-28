# ADR-004: プロジェクト別 IAM プロファイル設計

## ステータス

承認済み（2026-05-05）

## コンテキスト

### 現状の問題

`daihou-prod` プロファイルの実体は IAM ユーザー `daihou-admin` であり、
`AdministratorAccess` が直接アタッチされている（フルアクセス）。
つまり prod/admin の区別が実質なく、日常のデプロイ操作も全権限で実行されている。

```
daihou-prod プロファイル
  → IAM ユーザー: daihou-admin
  → アタッチポリシー: AdministratorAccess（全権限）
```

### 課題

- 最小権限原則（Principle of Least Privilege）が守られていない
- 誤操作・認証情報漏洩時の影響範囲が最大になる
- プロジェクト間の権限境界がない（daihou-gbp 操作で CloudLogAI リソースにアクセス可能な状態）

## 決定

プロジェクト・環境ごとに IAM ユーザーを分割し、最小権限ポリシーをアタッチする。

### プロファイル一覧（確定）

| プロファイル名 | IAM ユーザー名 | 用途 | スコープ |
|-------------|-------------|------|---------|
| `daihou-web-prod` | daihou-web-prod | コーポレートサイト 本番操作 | S3, CloudFront, Lambda, API GW, DynamoDB, SES, WAF |
| `daihou-web-stg` | daihou-web-stg | コーポレートサイト STG 操作 | 同上（STG リソースのみ） |
| `daihou-gbp` | daihou-gbp | GBP ツール群操作 | S3, ECS, ECR, Lambda, DynamoDB, EventBridge, SES |
| `daihou-sre` | daihou-sre | SRE 基盤操作 | CloudWatch, S3（tfstate）, IAM（読み取り）, ECS/Lambda（読み取り） |
| `daihou-cloudlogai` | daihou-cloudlogai | CloudLogAI 操作 | S3, Athena, Bedrock, Lambda, CloudFront, DynamoDB, SES |
| `admin` | daihou-admin | 緊急時・IAM 操作・初期構築のみ | AdministratorAccess（変更なし） |

### admin の位置づけ（sudo 相当）

- 普段使い禁止
- 使用するケース: IAM ポリシー変更、初期リソース構築、緊急障害対応のみ
- 操作前に意図を意識する（sudo を打つ感覚）
- CloudTrail で利用ログを定期確認

### daihou-prod プロファイルの廃止

移行完了後に廃止する。廃止前に以下を確認:
- 全リポジトリのコード・設定ファイル・ドキュメントでの参照
- GitHub Actions ワークフロー内の参照
- CDK / Terraform コード内の参照

### 対象外

- `dotfiles`: AWS 使用なし
- `portfolio`: GitHub Pages のみ、AWS 使用なし

## GitHub Actions との関係

ローカル CLI 用の IAM ユーザーとは別に、GitHub Actions 用の OIDC ロールをプロジェクトごとに設ける。

| プロジェクト | OIDC ロール名 | 既存状況 |
|------------|-------------|---------|
| daihou-corporate-site | daihou-corporate-github-actions-deploy | 未作成 → #139 で実装 |
| daihou-gbp | daihou-gbp-github-actions-deploy | 未作成 → #139 で実装 |
| CloudLogAI | daihou-cloudlogai-github-actions-plan / deploy | 作成済み |
| daihou-sre | daihou-sre-github-actions-plan / deploy | 作成済み |

## 実装フェーズ

| フェーズ | Issue | 内容 |
|---------|-------|------|
| 1（本 ADR） | #138 | 設計・命名規約策定 |
| 2 | #139 | Terraform で IAM ユーザー/ポリシー実装 |
| 3 | #140 | 各プロジェクトを新プロファイルに移行 |
| 4 | #141 | daihou-prod（daihou-admin）の権限縮退・廃止 |
