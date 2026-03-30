#!/bin/bash
# claude-voice-notify - スタンドアロン通知スクリプト
# Hooks から直接呼べる。VOICEVOX → macOS say の順でフォールバック。
#
# 使い方: ./notify.sh "メッセージ" [type]
#   type: complete | confirm | error (省略時: complete)

MESSAGE="${1:-タスクが完了しました}"
TYPE="${2:-complete}"
VOICEVOX_URL="${VOICEVOX_URL:-http://localhost:50021}"
VOICEVOX_SPEAKER="${VOICEVOX_SPEAKER:-1}"
SAY_VOICE="${SAY_VOICE:-Kyoko}"

# タイプ別デフォルトメッセージ
if [ -z "$1" ]; then
  case "$TYPE" in
    complete) MESSAGE="タスクが完了しました" ;;
    confirm)  MESSAGE="確認をお願いします" ;;
    error)    MESSAGE="エラーが発生しました" ;;
  esac
fi

# --- VOICEVOX を試す ---
try_voicevox() {
  # VOICEVOX が起動しているか確認（0.5秒タイムアウト）
  if ! curl -s --max-time 0.5 "$VOICEVOX_URL/version" > /dev/null 2>&1; then
    return 1
  fi

  # audio_query
  QUERY=$(curl -s --max-time 3 -X POST \
    "$VOICEVOX_URL/audio_query?text=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$MESSAGE'))")&speaker=$VOICEVOX_SPEAKER")

  if [ -z "$QUERY" ]; then
    return 1
  fi

  # synthesis → 一時ファイルに保存して再生
  TMPFILE=$(mktemp /tmp/claude-voice-XXXXXX.wav)
  HTTP_CODE=$(curl -s -o "$TMPFILE" -w "%{http_code}" --max-time 10 -X POST \
    -H "Content-Type: application/json" \
    -d "$QUERY" \
    "$VOICEVOX_URL/synthesis?speaker=$VOICEVOX_SPEAKER")

  if [ "$HTTP_CODE" = "200" ] && [ -s "$TMPFILE" ]; then
    afplay "$TMPFILE" 2>/dev/null &
    # バックグラウンド再生して即戻る（Hookのブロックを防ぐ）
    sleep 0.1
    rm -f "$TMPFILE" 2>/dev/null &
    return 0
  else
    rm -f "$TMPFILE" 2>/dev/null
    return 1
  fi
}

# --- macOS say フォールバック ---
try_macos_say() {
  if command -v say > /dev/null 2>&1; then
    say -v "$SAY_VOICE" "$MESSAGE" &
    return 0
  fi
  return 1
}

# --- メイン ---
try_voicevox || try_macos_say || echo "[claude-voice-notify] 音声再生に失敗しました" >&2
