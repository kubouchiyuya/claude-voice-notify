#!/bin/bash
# claude-voice-notify - スタンドアロン通知スクリプト
# Hooks / Claude Code (Bash) から直接呼べる。
# VOICEVOX → macOS say の順でフォールバック。
#
# 使い方:
#   ./notify.sh "メッセージ"                       # ずんだもん(デフォルト)で読み上げ
#   ./notify.sh "メッセージ" complete               # タイプ指定
#   ./notify.sh "メッセージ" complete 1             # スピーカーID指定
#   ./notify.sh "メッセージ" complete 1 1.2         # 速度指定(1.2倍速)
#
# スピーカーID一覧 (VOICEVOX):
#   0: 四国めたん(あまあま)    1: ずんだもん(ノーマル)  2: 四国めたん(ノーマル)
#   3: ずんだもん(あまあま)    5: ずんだもん(ツンツン)  6: ずんだもん(セクシー)
#   7: ずんだもん(ささやき)    8: 春日部つむぎ          9: 雨晴はう
#  10: 波音リツ              11: 玄野武宏             14: 冥鳴ひまり

MESSAGE="${1:-}"
TYPE="${2:-complete}"
VOICEVOX_SPEAKER="${3:-${VOICEVOX_SPEAKER:-1}}"
SPEED="${4:-1.0}"
VOICEVOX_URL="${VOICEVOX_URL:-http://localhost:50021}"
SAY_VOICE="${SAY_VOICE:-Kyoko}"

# タイプ別デフォルトメッセージ（第1引数が空の場合のみ）
if [ -z "$MESSAGE" ]; then
  case "$TYPE" in
    complete) MESSAGE="タスクが完了しました" ;;
    confirm)  MESSAGE="確認をお願いします" ;;
    error)    MESSAGE="エラーが発生しました" ;;
    explain)  MESSAGE="解説を開始します" ;;
    *)        MESSAGE="お知らせがあります" ;;
  esac
fi

# --- VOICEVOX を試す ---
try_voicevox() {
  # VOICEVOX が起動しているか確認
  if ! curl -s --max-time 0.5 "$VOICEVOX_URL/version" > /dev/null 2>&1; then
    return 1
  fi

  # audio_query
  ENCODED_TEXT=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$MESSAGE" 2>/dev/null)
  QUERY=$(curl -s --max-time 5 -X POST \
    "$VOICEVOX_URL/audio_query?text=${ENCODED_TEXT}&speaker=$VOICEVOX_SPEAKER")

  if [ -z "$QUERY" ]; then
    return 1
  fi

  # 速度調整
  if [ "$SPEED" != "1.0" ]; then
    QUERY=$(echo "$QUERY" | python3 -c "
import json,sys
q = json.load(sys.stdin)
q['speedScale'] = float(sys.argv[1])
print(json.dumps(q))
" "$SPEED" 2>/dev/null || echo "$QUERY")
  fi

  # synthesis → 一時ファイルに保存して再生
  TMPFILE=$(mktemp /tmp/claude-voice-XXXXXX.wav)
  HTTP_CODE=$(curl -s -o "$TMPFILE" -w "%{http_code}" --max-time 30 -X POST \
    -H "Content-Type: application/json" \
    -d "$QUERY" \
    "$VOICEVOX_URL/synthesis?speaker=$VOICEVOX_SPEAKER")

  if [ "$HTTP_CODE" = "200" ] && [ -s "$TMPFILE" ]; then
    afplay "$TMPFILE" 2>/dev/null
    rm -f "$TMPFILE" 2>/dev/null
    return 0
  else
    rm -f "$TMPFILE" 2>/dev/null
    return 1
  fi
}

# --- macOS say フォールバック ---
try_macos_say() {
  if command -v say > /dev/null 2>&1; then
    say -v "$SAY_VOICE" "$MESSAGE"
    return 0
  fi
  return 1
}

# --- メイン ---
try_voicevox || try_macos_say || echo "[claude-voice-notify] 音声再生に失敗しました" >&2
