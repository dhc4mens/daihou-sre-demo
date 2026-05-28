# DynamoDB バックアップ・PITR 運用 Runbook

重要度: Medium
対象テーブル: 全本番 DynamoDB テーブル

---

## PITR（ポイントインタイムリカバリ）現状

| テーブル | PITR | 管理方法 | 備考 |
|:---|:---:|:---|:---|
| `cloudlogai-customers` | ✅ ENABLED | Terraform（CloudLogAI repo） | 最古復元可能: 35日前〜 |
| `DaihouContacts-Production` | ❌ DISABLED | CDK（daihou-corporate-site repo） | **要対応** |
| `daihou-gbp-jobs` | ❌ DISABLED | Terraform（daihou-gbp repo） | 要対応 |
| `daihou-gbp-terraform-state-lock` | — | Terraform | ロック管理のみ、PITR不要 |
| `daihou-terraform-locks` | — | Terraform | ロック管理のみ、PITR不要 |

> **注意:** `DaihouContacts-Production` は CDK 管理（`ManagedBy: cdk`）のため、
> daihou-sre Terraform から import すると CDK/TF 競合が発生する。
> PITR 有効化は CDK スタックまたは CLI で行うこと。

---

## PITR 有効化手順

### DaihouContacts-Production（CLI即時対応）

```bash
aws dynamodb update-continuous-backups \
  --table-name DaihouContacts-Production \
  --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true \
  --region ap-northeast-1 \
  --profile daihou-prod
```

有効化確認:

```bash
aws dynamodb describe-continuous-backups \
  --table-name DaihouContacts-Production \
  --region ap-northeast-1 \
  --profile daihou-prod \
  --query 'ContinuousBackupsDescription.PointInTimeRecoveryDescription'
```

期待出力: `"PointInTimeRecoveryStatus": "ENABLED"`

### 恒久的管理（CDK対応 — daihou-corporate-site repo）

daihou-corporate-site の CDK スタックに以下を追加:

```typescript
// ContactsTable に PITR を有効化
const contactsTable = new dynamodb.Table(this, 'ContactsTable', {
  // ... 既存設定 ...
  pointInTimeRecovery: true,  // ← 追加
});
```

---

## PITR 状態の定期確認

全本番テーブルの PITR 状態を一括確認するスクリプト:

```bash
#!/bin/bash
PROFILE="daihou-prod"
REGION="ap-northeast-1"
TABLES=("cloudlogai-customers" "DaihouContacts-Production" "daihou-gbp-jobs")

for TABLE in "${TABLES[@]}"; do
  STATUS=$(aws dynamodb describe-continuous-backups \
    --table-name "$TABLE" \
    --region "$REGION" \
    --profile "$PROFILE" \
    --query 'ContinuousBackupsDescription.PointInTimeRecoveryDescription.PointInTimeRecoveryStatus' \
    --output text 2>/dev/null)
  echo "$TABLE: $STATUS"
done
```

---

## PITR による復元手順

### 前提

- 復元先は**新しいテーブル名**（既存テーブルへの上書き不可）
- 復元後にアプリ側の接続先テーブル名を切り替えるか、データを移行する

### 復元実行

```bash
# 復元ポイントを指定して新テーブルに復元
aws dynamodb restore-table-to-point-in-time \
  --source-table-name DaihouContacts-Production \
  --target-table-name DaihouContacts-Production-Restored-$(date +%Y%m%d) \
  --restore-date-time "2026-04-25T12:00:00Z" \
  --region ap-northeast-1 \
  --profile daihou-prod
```

### 復元後の確認

```bash
# 復元テーブルのステータス確認（CREATING → ACTIVE になるまで待つ）
aws dynamodb describe-table \
  --table-name DaihouContacts-Production-Restored-$(date +%Y%m%d) \
  --region ap-northeast-1 \
  --profile daihou-prod \
  --query 'Table.TableStatus'

# アイテム数確認
aws dynamodb scan \
  --table-name DaihouContacts-Production-Restored-$(date +%Y%m%d) \
  --select COUNT \
  --region ap-northeast-1 \
  --profile daihou-prod
```

### データ切り替えフロー

```
1. 復元テーブル作成・確認
2. アプリ（Lambda contact-handler）の環境変数 TABLE_NAME を変更
   → Lambda コンソール or Terraform 変数更新
3. 動作確認（お問い合わせフォーム疎通テスト）
4. 旧テーブルをバックアップ扱いで保持（不要確認後に削除）
```

---

## 関連 Issue

- #41 DynamoDB バックアップポリシー確認（PITR 有効化）
- #26 Terraform カバレッジ調査
