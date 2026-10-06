# daihou-sre-demo — SRE基盤デモリポジトリ

> だいほう合同会社のSRE基盤（daihou-sre / private）から、設計思想・実装パターン・運用ドキュメントを公開用に抽出したデモリポジトリです。

**Portfolio:** https://dhc4mens.github.io/portfolio/

---

## このリポが証明できること

| 必要経験 | このリポの対応箇所 |
|:---|:---|
| AWS上でのWebサービスのインフラ構築・運用 | `terraform/modules/` — ECS Fargate・ALB・ネットワーク設計 |
| Terraform IaCでのインフラ管理 | `terraform/modules/` — 再利用可能なモジュール設計 |
| CloudWatch等モニタリングツールを使った監視 | `terraform/modules/monitoring/` — サービス横断のAlarm定義 |
| CI/CD環境の構築経験 | `docs/adr/` — ADR-001〜004でCI/CD設計判断を記録 |
| コンテナを用いたアプリケーション実行基盤構築 | `terraform/modules/ecs-fargate-*` — ECS Fargate完全IaC化 |
| SREとしての活動経験 | `runbooks/` + `monitoring/slos/` — 7本のRunbook・SLO定義・エラーバジェット管理 |
| 運用自動化のためのツールを自分で設計・実装 | `runbooks/error-budget.md` — エラーバジェット消費の自動検知・対応フロー |

---

## このリポの読み方（🔴 閲覧専用）

**これは読むためのリポジトリで、動かすためのものではありません。**

`terraform/` に入っているのは `modules/` だけで、`environments/`（root module）はありません。
バックエンド設定も変数の実値も持たないので、**`terraform apply` は通りません。設計と実装の
見せ方を読むための構成**です。動く本番環境は private リポ側にあります。

| 見るもの | どこ |
|:---|:---|
| モジュールの設計判断 | `terraform/modules/*/README.md` — 入出力と分割の基準 |
| 監視の考え方 | `terraform/modules/monitoring/` — サービス横断のアラーム定義 |
| 障害対応の手順 | `runbooks/` — 7本 |
| SLO とエラーバジェット | `monitoring/slos/` |
| 設計判断の記録 | `docs/adr/` |

### 公開にあたって伏せているもの

- **AWS アカウントIDは `123456789012`（AWS ドキュメント用のダミー）に置換**しています
- SNS トピック ARN は変数（`sns_topic_arn` / `ses_sns_topic_arn`）で受け取る形にしており、
  **既定値を持ちません**

そのため、コードをコピーしてもそのままでは動きません。**実値は読み手側で入れる前提**です。

---

## SREとしてのアプローチ

### 思想: 「トイルを仕組みで消す」

手作業（トイル）を放置せず、**検知→自動化→Runbook化**のサイクルで運用負荷を継続的に削減する。

```
手作業で対応 → 再発したら Runbook 化 → 頻発したら自動化 → SLO で計測
```

### 実装した仕組み

```
SLO/SLI定義
  └── エラーバジェット監視（CloudWatch Alarm）
        └── 超過時: Runbook 参照 → 対応手順が即座に引ける

週次 drift 検知（GitHub Actions）
  └── terraform plan の差分を Issue に自動起票
        └── インフラの意図しない変更をゼロにする

CloudWatch Alarm 16本（terraform/modules/monitoring/ の定義数）
  ├── ECS / Lambda / CloudFront / DynamoDB
  ├── WAF / API Gateway / SES を横断的に監視
  └── 全て Terraform モジュールで定義・再現可能
```

### 現場への持ち込み価値

- **即日適用可能**: Terraformモジュールはそのまま別環境に適用できる設計
- **チーム展開**: RunbookとADRをGitで管理することで属人化を排除
- **スケール**: モジュール設計により、サービス追加時の監視設定を数分で展開できる

---

## リポ構成

```
daihou-sre-demo/
├── runbooks/               # インシデント対応手順書（7本）
│   ├── ecs-service-down.md
│   ├── ecs-task-failed.md
│   ├── alb-5xx-spike.md
│   ├── dynamodb-backup.md
│   ├── error-budget.md
│   ├── fargate-image-pull-fail.md
│   └── terraform-state-migration.md
│
├── terraform/
│   └── modules/            # 再利用可能なTerraformモジュール（5本）
│       ├── alb/            # ALBリスナー・ターゲットグループ
│       ├── ecs-fargate-cluster/  # ECSクラスター
│       ├── ecs-fargate-taskdef/  # タスク定義
│       ├── monitoring/     # CloudWatch Alarm（サービスごとに1ファイル）
│       └── networking/     # VPC・サブネット・SG
│
├── docs/
│   ├── adr/                # Architecture Decision Records（4本）
│   │   ├── 001-terraform-state-layer-separation.md
│   │   ├── 002-ecr-for-dev-container-image.md
│   │   ├── ADR-003-changelog-version-release-trigger.md
│   │   └── ADR-004-iam-role-design.md
│   └── terraform-conventions.md  # Terraform命名・設計規約
│
└── monitoring/
    └── slos/               # SLO定義・エラーバジェット基準
        ├── cloudlogai.md
        └── corporate-site.md
```

---

## Runbook設計の考え方

各Runbookは以下の構成で統一しています:

1. **症状** — どのAlarmが発火したか / ユーザーへの影響
2. **原因候補** — 可能性の高い順にリスト化
3. **調査手順** — AWS CLI コマンド付きで即実行できる
4. **対応手順** — ケース別に分岐（rollback / 再起動 / スケールアップ等）
5. **自動化TODO** — 次のトイル削減候補を明示

**狙い**: アラート発火から5分以内に原因特定・対応着手できる状態を維持する。

---

## Terraform モジュール設計の考え方

### 層分離

```
infra層（VPC/IAM/ECR等）: 変更頻度低・リスク高
  ↕ tfstate を分離（誤った apply の影響範囲を限定）
app層（ECS/ALB/Lambda等）: 変更頻度高・デプロイ対象
```

### モジュール化の基準

「同じリソース構成を2回以上書いたらモジュール化する」
- variables で環境差分を吸収（prod/staging の違いはvariablesだけ）
- outputs で上位モジュールへ値を渡す（ARN/IDの直書きを禁止）

---

## SLO定義の考え方

```yaml
# 例: 可用性SLO（説明用のサンプル。値の正本は monitoring/slos/cloudlogai.md）
可用性目標: 99.5%（月間ダウンタイム上限 約3.6時間）
計測方法: CloudWatch → ALBの5xxレート
エラーバジェット: 0.5%/月
バジェット消費速度: 1時間で月間バジェットの2%以上を消費（通常の14.4倍速） → 即対応
```

SLOを定義することで「どこまでは許容してどこからは対応する」の判断基準をチームで共有できる。

---

## 技術スタック

| 領域 | 使用技術 |
|:---|:---|
| IaC | Terraform（infra/app層分離・モジュール設計） |
| コンテナ | ECS Fargate |
| 監視 | CloudWatch Alarm・SLI/SLO定義 |
| CI/CD | GitHub Actions（drift検知・terraform plan自動化） |
| セキュリティ | OIDC認証・IAMロール最小権限 |
| ドキュメント | ADR（意思決定記録）・Runbook・Terraform規約 |

---

## 関連リンク

- **Portfolio**: https://dhc4mens.github.io/portfolio/
- **プライベート本番リポ**: dhc4mens/daihou-sre（面談時に画面共有可）
