# ADR-002: dev コンテナイメージのレジストリを GHCR から ECR に変更する

> Architecture Decision Record — 作成: 2026-05-03 / ステータス: Accepted

---

## ステータス

**Accepted** — Issue [#110](https://github.com/dhc4mens/daihou-sre/issues/110) にて採択

---

## コンテキスト

Issue #106 で dev コンテナイメージ（`Dockerfile.dev`）を GHCR（GitHub Container Registry）に publish する仕組みを導入した。しかし以下の問題が発覚した。

- daihou-sre リポジトリはプライベートのため、GHCR パッケージもデフォルトでプライベートになる
- ローカルから `docker pull` するには `read:packages` スコープを持つトークンが必要
- `gh auth token` のデフォルトスコープには `read:packages` が含まれないため、追加の認証ステップが必要になる
- GHCR パッケージを public にすると「dev ツールの構成情報を公開する」ことになり、セキュリティポリシーとの整合性が必要

一方、daihou-sre のインフラはすでに AWS 上にあり、GitHub Actions との OIDC 認証も確立済みである。

---

## 決定

dev コンテナイメージのレジストリを **Amazon ECR（Elastic Container Registry）** に変更する。

- ECR リポジトリ: `daihou-sre-dev`（ap-northeast-1）
- GitHub Actions → ECR push: OIDC 認証（既存 IAM ロールを拡張）
- ローカル pull: `aws ecr get-login-password` + AWS CLI（既存の `~/.aws` 設定を流用）

---

## 理由

| 観点 | GHCR（却下） | ECR（採用） |
|:---|:---|:---|
| 認証 | `read:packages` スコープ追加が必要 | `~/.aws` 設定のみ（既存） |
| CI との統合 | GitHub token（スコープ管理が煩雑） | OIDC（既存ロールを拡張するだけ） |
| プライベート維持 | パッケージを public にしないと pull できない | プライベートのまま IAM で制御 |
| AWS 学習価値 | 低 | 高（ECR・IAM ポリシー・OIDC の実践） |
| 既存インフラとの親和性 | △ | ◎（Terraform 管理・AWS 統一） |
| コスト | 無料（public）/ スコープ問題あり | 月 500MB 無料・超過 $0.10/GB |

---

## 却下した選択肢

| 案 | 却下理由 |
|:---|:---|
| GHCR パッケージを public にする | dev ツール構成情報が公開される・リポジトリの private 方針と不整合 |
| GHCR のままスコープ追加で対応 | 新環境セットアップのたびに `gh auth refresh` が必要でオペレーションが煩雑 |
| Docker Hub | 別サービスへの依存追加・認証管理の分散 |

---

## 影響・対処

| 項目 | 内容 |
|:---|:---|
| Terraform | ECR リポジトリ・IAM ポリシーを追加（`terraform/environments/prod/infra`） |
| GitHub Actions | `publish-dev-image.yml` の push 先を ECR に変更・OIDC ロールに `ecr:*` 権限追加 |
| Makefile | `make pull` の認証コマンドを `aws ecr get-login-password` に変更 |
| GHCR | 既存の GHCR パッケージは削除 |

---

## 参照

- [Issue #106 — dev コンテナを GHCR に publish（初回実装・置き換え対象）](https://github.com/dhc4mens/daihou-sre/issues/106)
- [Issue #110 — dev コンテナイメージを ECR に移行](https://github.com/dhc4mens/daihou-sre/issues/110)
