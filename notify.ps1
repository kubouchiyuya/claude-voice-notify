# claude-voice-notify - Windows用スタンドアロン通知スクリプト
# Hooks から直接呼べる。VOICEVOX → Windows SAPI の順でフォールバック。
#
# 使い方: powershell -File notify.ps1 "メッセージ" [type]
#   type: complete | confirm | error (省略時: complete)

param(
    [string]$Message = "",
    [string]$Type = "complete"
)

$VoicevoxUrl = if ($env:VOICEVOX_URL) { $env:VOICEVOX_URL } else { "http://localhost:50021" }
$VoicevoxSpeaker = if ($env:VOICEVOX_SPEAKER) { $env:VOICEVOX_SPEAKER } else { "1" }

# タイプ別デフォルトメッセージ
if ([string]::IsNullOrEmpty($Message)) {
    switch ($Type) {
        "complete" { $Message = "タスクが完了しました" }
        "confirm"  { $Message = "確認をお願いします" }
        "error"    { $Message = "エラーが発生しました" }
        default    { $Message = "タスクが完了しました" }
    }
}

function Try-Voicevox {
    try {
        # VOICEVOX 起動確認
        $version = Invoke-RestMethod -Uri "$VoicevoxUrl/version" -Method Get -TimeoutSec 1 -ErrorAction Stop
        Write-Host "[claude-voice-notify] VOICEVOX v$version detected" -ForegroundColor Green

        # audio_query
        $encodedText = [System.Web.HttpUtility]::UrlEncode($Message)
        $query = Invoke-RestMethod -Uri "$VoicevoxUrl/audio_query?text=$encodedText&speaker=$VoicevoxSpeaker" -Method Post -TimeoutSec 5 -ErrorAction Stop

        # synthesis
        $queryJson = $query | ConvertTo-Json -Depth 10
        $tmpFile = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.wav'

        Invoke-RestMethod -Uri "$VoicevoxUrl/synthesis?speaker=$VoicevoxSpeaker" `
            -Method Post `
            -ContentType "application/json" `
            -Body $queryJson `
            -OutFile $tmpFile `
            -TimeoutSec 15 `
            -ErrorAction Stop

        if (Test-Path $tmpFile) {
            # Windows Media Player で再生
            $player = New-Object Media.SoundPlayer $tmpFile
            $player.PlaySync()
            Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue
            return $true
        }
    }
    catch {
        return $false
    }
    return $false
}

function Try-WindowsSAPI {
    try {
        Add-Type -AssemblyName System.Speech
        $synth = New-Object System.Speech.Synthesis.SpeechSynthesizer

        # 日本語音声を探す
        $jaVoice = $synth.GetInstalledVoices() | Where-Object {
            $_.VoiceInfo.Culture.Name -like "ja-*"
        } | Select-Object -First 1

        if ($jaVoice) {
            $synth.SelectVoice($jaVoice.VoiceInfo.Name)
        }

        $synth.Speak($Message)
        $synth.Dispose()
        return $true
    }
    catch {
        return $false
    }
}

# --- メイン ---
Add-Type -AssemblyName System.Web

if (-not (Try-Voicevox)) {
    if (-not (Try-WindowsSAPI)) {
        Write-Error "[claude-voice-notify] 音声再生に失敗しました"
    }
}
