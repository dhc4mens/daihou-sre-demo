#!/usr/bin/env bash
# dhc4mens 標準ラベル一括作成スクリプト
#
# 使い方:
#   cd <your-repo>
#   bash /path/to/setup-labels.sh
#
# または直接 curl で取得して実行:
#   curl -sL https://raw.githubusercontent.com/dhc4mens/repo-setup-template/main/scripts/setup-labels.sh | bash

set -eu

# gh CLI が使えるか確認
if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: gh CLI が必要です"
  exit 1
fi

create_label() {
  local name=$1 color=$2 desc=$3
  if gh label create "$name" --color "$color" --description "$desc" 2>/dev/null; then
    echo "  created: $name"
  else
    echo "  skipped: $name (already exists)"
  fi
}

echo "Creating labels..."

# type/*
create_label "type/bug"      "d73a4a" "バグ"
create_label "type/feature"  "a2eeef" "新機能"
create_label "type/chore"    "cfd3d7" "雑務・リファクタ・依存更新"
create_label "type/docs"     "0075ca" "ドキュメント"

# priority/*
create_label "priority/high"   "b60205" "優先度 高"
create_label "priority/medium" "fbca04" "優先度 中"
create_label "priority/low"    "cccccc" "優先度 低"

# status/*
create_label "status/ready"    "0e8a16" "着手可能"
create_label "status/wip"      "fbca04" "作業中"
create_label "status/blocked"  "b60205" "ブロック中"

echo "Done."
