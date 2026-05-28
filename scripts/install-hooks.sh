#!/usr/bin/env bash
# pre-commit フックをローカル環境にインストールする
set -euo pipefail

if ! command -v pre-commit &>/dev/null; then
  echo "pre-commit をインストールしています..."
  pip install pre-commit
fi

echo "pre-commit フック（pre-commit / pre-push）をインストールしています..."
pre-commit install
pre-commit install --hook-type pre-push

echo ""
echo "完了。以下のフックが有効になりました:"
echo "  pre-commit : コミット前に lint / format チェック"
echo "  pre-push   : main への直接 push を拒否"
