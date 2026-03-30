#!/bin/bash
# claude-voice-notify セットアップスクリプト
# ⭐ Star確認 → VOICEVOX インストール → ビルド → Hooks登録 を一括で行う

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NOTIFY_SCRIPT="$SCRIPT_DIR/notify.sh"
REPO_OWNER="kubouchiyuya"
REPO_NAME="claude-voice-notify"
REPO_URL="https://github.com/$REPO_OWNER/$REPO_NAME"

echo "=========================================="
echo "  claude-voice-notify セットアップ"
echo "=========================================="
echo ""

# ============================================
# 0. ⭐ Star ゲート
# ============================================
echo "⭐ Star 確認..."
echo "   このツールを使うには、リポジトリに Star が必要です。"
echo "   $REPO_URL"
echo ""
read -p "   GitHubユーザー名を入力してください: " GITHUB_USER

if [ -z "$GITHUB_USER" ]; then
  echo "   ❌ ユーザー名が入力されませんでした"
  exit 1
fi

# GitHub APIでStar確認
STAR_CHECK=$(curl -s -o /dev/null -w "%{http_code}" \
  "https://api.github.com/users/$GITHUB_USER/starred/$REPO_OWNER/$REPO_NAME" 2>/dev/null)

if [ "$STAR_CHECK" = "204" ]; then
  echo "   ✅ Star 確認OK！ @$GITHUB_USER さん、ありがとうございます！"
else
  echo ""
  echo "   ❌ @$GITHUB_USER のStar が確認できませんでした。"
  echo ""
  echo "   以下の手順でStarしてください："
  echo "   1. $REPO_URL を開く"
  echo "   2. 右上の ☆ Star ボタンをクリック"
  echo "   3. もう一度このスクリプトを実行"
  echo ""

  # ブラウザで開くか確認
  read -p "   今すぐブラウザで開きますか？ [y/N]: " OPEN_BROWSER
  if [ "$OPEN_BROWSER" = "y" ] || [ "$OPEN_BROWSER" = "Y" ]; then
    if command -v open > /dev/null 2>&1; then
      open "$REPO_URL"
    elif command -v xdg-open > /dev/null 2>&1; then
      xdg-open "$REPO_URL"
    fi
    echo ""
    echo "   Starした後、再度実行してください: ./setup.sh"
  fi
  exit 1
fi

echo ""

# ============================================
# 1. Node.js 確認
# ============================================
echo "🔍 Node.js を確認..."
if command -v node > /dev/null 2>&1; then
  echo "   ✅ Node.js $(node -v)"
else
  echo "   ❌ Node.js が見つかりません。インストールしてください。"
  echo "      https://nodejs.org/"
  exit 1
fi

# ============================================
# 2. VOICEVOX 確認 & インストール
# ============================================
echo ""
echo "🔍 VOICEVOX を確認..."

VOICEVOX_INSTALLED=false
VOICEVOX_RUNNING=false

# インストール確認（macOS）
if [ -d "/Applications/VOICEVOX.app" ] || mdfind "kMDItemCFBundleIdentifier == 'jp.hiroshiba.voicevox'" 2>/dev/null | grep -q . 2>/dev/null; then
  VOICEVOX_INSTALLED=true
  echo "   ✅ VOICEVOX がインストールされています"
fi

# 起動確認
if curl -s --max-time 1 "http://localhost:50021/version" > /dev/null 2>&1; then
  VOICEVOX_RUNNING=true
  VERSION=$(curl -s --max-time 1 "http://localhost:50021/version" 2>/dev/null | tr -d '"')
  echo "   ✅ VOICEVOX が起動しています (v$VERSION)"
fi

if [ "$VOICEVOX_INSTALLED" = false ]; then
  echo "   ⚠️  VOICEVOX が見つかりません"
  echo ""
  echo "   VOICEVOXをインストールしますか？"
  echo "   1) 自動ダウンロード＆インストール (推奨)"
  echo "   2) 公式サイトからダウンロード"
  echo "   3) スキップ"
  echo ""
  read -p "   選択 [1/2/3]: " choice

  case "$choice" in
    1)
      echo "   📦 VOICEVOX を GitHub Releases からダウンロード中..."
      ARCH=$(uname -m)
      OS=$(uname -s)

      if [ "$OS" = "Darwin" ]; then
        if [ "$ARCH" = "arm64" ]; then
          ZIP_NAME="voicevox-macos-cpu-arm64"
        else
          ZIP_NAME="voicevox-macos-cpu-x64"
        fi
      else
        echo "   ⚠️  Linux への自動インストールは未対応です。"
        echo "   公式サイトからダウンロードしてください: https://voicevox.hiroshiba.jp/"
        ZIP_NAME=""
      fi

      if [ -n "$ZIP_NAME" ]; then
        LATEST_TAG=$(curl -sL "https://api.github.com/repos/VOICEVOX/voicevox/releases/latest" | python3 -c "import json,sys; print(json.load(sys.stdin)['tag_name'])" 2>/dev/null)
        if [ -z "$LATEST_TAG" ]; then
          LATEST_TAG="0.25.1"
        fi
        DL_URL="https://github.com/VOICEVOX/voicevox/releases/download/${LATEST_TAG}/${ZIP_NAME}-${LATEST_TAG}.zip"
        echo "   URL: $DL_URL"
        echo "   (約1.8GB - 数分かかります)"
        curl -L -o /tmp/voicevox-macos.zip "$DL_URL"
        if [ $? -eq 0 ]; then
          echo "   📂 展開中..."
          unzip -o -q /tmp/voicevox-macos.zip -d /tmp/voicevox-extract
          cp -R /tmp/voicevox-extract/VOICEVOX/VOICEVOX.app /Applications/
          rm -rf /tmp/voicevox-macos.zip /tmp/voicevox-extract
          VOICEVOX_INSTALLED=true
          echo "   ✅ /Applications/VOICEVOX.app にインストール完了"
        else
          echo "   ❌ ダウンロードに失敗しました"
          echo "   公式サイトからダウンロードしてください: https://voicevox.hiroshiba.jp/"
        fi
      fi
      ;;
    2)
      echo "   🌐 公式サイトを開きます..."
      if command -v open > /dev/null 2>&1; then
        open "https://voicevox.hiroshiba.jp/"
      elif command -v xdg-open > /dev/null 2>&1; then
        xdg-open "https://voicevox.hiroshiba.jp/"
      fi
      echo "   ダウンロード・インストール後、再度このスクリプトを実行してください。"
      exit 0
      ;;
    3)
      echo "   ⏭️  スキップ。VOICEVOXなしでは音声通知が動作しません。"
      echo "   後からインストールして再度 ./setup.sh を実行してください。"
      ;;
  esac
fi

# ============================================
# 3. VOICEVOX 起動
# ============================================
if [ "$VOICEVOX_INSTALLED" = true ] && [ "$VOICEVOX_RUNNING" = false ]; then
  echo ""
  echo "🚀 VOICEVOX を起動しています..."
  open -a VOICEVOX 2>/dev/null || true
  echo "   起動中... (APIが利用可能になるまで数秒かかります)"
  for i in $(seq 1 20); do
    if curl -s --max-time 1 "http://localhost:50021/version" > /dev/null 2>&1; then
      VOICEVOX_RUNNING=true
      echo "   ✅ VOICEVOX 起動完了"
      break
    fi
    sleep 2
  done
  if [ "$VOICEVOX_RUNNING" = false ]; then
    echo "   ⚠️  VOICEVOX の起動に時間がかかっています。手動で起動してください。"
  fi
fi

# ============================================
# 4. npm build
# ============================================
echo ""
echo "🔨 プロジェクトをビルド..."
cd "$SCRIPT_DIR"
if [ ! -d "node_modules" ]; then
  npm install
fi
npm run build
echo "   ✅ ビルド完了"

# ============================================
# 5. キャラクター選択
# ============================================
if [ "$VOICEVOX_RUNNING" = true ]; then
  echo ""
  echo "🎤 デフォルトキャラクターを選んでください:"
  echo ""

  # 主要キャラを表示
  curl -s "$VOICEVOX_URL/speakers" 2>/dev/null | python3 -c "
import json, sys
speakers = json.load(sys.stdin)
popular = [3, 1, 7, 8, 2, 10, 13, 14, 20, 46]
print('   人気キャラクター:')
for s in speakers:
    for st in s['styles']:
        if st['id'] in popular:
            print(f'     {st[\"id\"]:3d}: {s[\"name\"]}（{st[\"name\"]}）')
print(f'')
print(f'   全{sum(len(s[\"styles\"]) for s in speakers)}キャラの一覧: ./notify.sh list')
" 2>/dev/null || true

  echo ""
  read -p "   スピーカーID [3=ずんだもん(ノーマル)]: " SELECTED_SPEAKER
  SELECTED_SPEAKER="${SELECTED_SPEAKER:-3}"

  "$NOTIFY_SCRIPT" set-speaker "$SELECTED_SPEAKER"
fi

# ============================================
# 6. Claude Code 設定
# ============================================
echo ""
echo "🔧 Claude Code の設定..."
CLAUDE_SETTINGS="$HOME/.claude/settings.json"

if [ -f "$CLAUDE_SETTINGS" ]; then
  if grep -q "voice-notify" "$CLAUDE_SETTINGS" 2>/dev/null; then
    echo "   ✅ Hooks は既に設定されています"
  else
    echo "   ⚠️  以下を $CLAUDE_SETTINGS の hooks に追加してください:"
    echo ""
    cat <<HOOKEOF
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$NOTIFY_SCRIPT '確認をお願いします' confirm"
          }
        ]
      }
    ]
HOOKEOF
  fi
else
  echo "   ⚠️  Claude Code の設定ファイルが見つかりません"
fi

# ============================================
# 7. テスト
# ============================================
if [ "$VOICEVOX_RUNNING" = true ]; then
  echo ""
  echo "🔊 音声テスト..."
  "$NOTIFY_SCRIPT" "セットアップが完了しました。音声通知が正常に動作しています。" complete
  echo "   音声が聞こえましたか？"
fi

echo ""
echo "=========================================="
echo "  ⭐ セットアップ完了！"
echo "=========================================="
echo ""
if [ "$VOICEVOX_RUNNING" = true ]; then
  echo "  🎉 VOICEVOX で音声通知が有効になりました"
else
  echo "  ⚠️  VOICEVOXを起動してから再度テストしてください"
fi
echo ""
echo "  使い方:"
echo "  - ./notify.sh \"メッセージ\"          読み上げ"
echo "  - ./notify.sh list                   キャラ一覧"
echo "  - ./notify.sh set-speaker <ID>       キャラ変更"
echo "  - ./notify.sh on / off               オン/オフ"
echo ""
echo "  CLAUDE.md に templates/CLAUDE.md の内容を追加すると"
echo "  Claude Code が自動的に音声通知を使うようになります"
echo ""
