#!/bin/bash
# claude-voice-notify 自動アップデートスクリプト
# クローンした人が最新版に更新できる

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo ""
echo "🔄 claude-voice-notify アップデート"
echo ""

# 現在のバージョン
CURRENT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
echo "  現在: $CURRENT"

# リモートの最新を取得
git fetch origin main --quiet 2>/dev/null

# 差分チェック
LOCAL=$(git rev-parse HEAD 2>/dev/null)
REMOTE=$(git rev-parse origin/main 2>/dev/null)

if [ "$LOCAL" = "$REMOTE" ]; then
  echo "  ✅ 最新版です。更新はありません。"
  exit 0
fi

# 更新内容を表示
echo ""
echo "  📋 更新内容:"
git log --oneline HEAD..origin/main 2>/dev/null | while read line; do
  echo "    $line"
done

echo ""
read -p "  更新しますか？ [Y/n]: " CONFIRM
CONFIRM="${CONFIRM:-Y}"

if [ "$CONFIRM" = "n" ] || [ "$CONFIRM" = "N" ]; then
  echo "  キャンセルしました"
  exit 0
fi

# pull & rebuild
echo ""
echo "  📥 ダウンロード中..."
git pull origin main --quiet

echo "  🔨 リビルド中..."
npm install --silent 2>/dev/null
npm run build --silent 2>/dev/null

NEW=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
echo ""
echo "  ✅ アップデート完了！ $CURRENT → $NEW"
echo ""

# 更新通知を音声で
if [ -f "$SCRIPT_DIR/notify.sh" ]; then
  "$SCRIPT_DIR/notify.sh" "アップデートが完了しました" complete 2>/dev/null || true
fi
