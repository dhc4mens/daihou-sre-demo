# daihou-sre-demo — このリポで毎ターン要る事実

## 事実

- 🔴 リポは **PUBLIC**（この CLAUDE.md も公開される）。daihou-sre（private）から、設計と実装の見せ方を抜き出した面談・ポートフォリオ用
- `terraform/` にあるのは `modules/` だけで、root module・backend・変数の実値が無い。plan / apply はしない（通らない）
- ADR 4本・Runbook 7本・SLO 定義 2本は daihou-sre からのコピーで、本体の更新に追随しない（陳腐化の扱いは dotfiles#310）

## 作法

- AWS アカウント ID はダミーの `123456789012` を使う。ARN・ドメイン・バケット名・Secrets Manager のパスは変数で受け取り、既定値を持たせない（`monitoring` モジュールの `sns_topic_arn` がその形）
- daihou-sre から抜き出す時は差分を見る（抽出元の実値がそのまま入る事故が起きやすい）
- コミットの前に、実値が入っていないかを確かめる（どちらも0件が正しい）:
  ```bash
  grep -rnE "[0-9]{12}" . --exclude-dir=.git | grep -v 123456789012
  grep -rn "daihou-llc\.com" . --exclude-dir=.git
  grep -rnE "100\.[0-9]+\.[0-9]+\.[0-9]+" . --exclude-dir=.git   # Tailscale などの IP
  ```

## やらないこと

- 実アカウント ID・実 ARN・実ドメイン・実バケット名・Secrets Manager のパス・IP（Tailscale の 100.x を含む）・CloudFront などのリソース ID を書かない
