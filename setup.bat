@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ==========================================
echo   claude-voice-notify セットアップ (Windows)
echo ==========================================
echo.

REM ============================================
REM 0. Star ゲート
REM ============================================
echo [0/5] Star 確認...
echo    このツールを使うには、リポジトリに Star が必要です。
echo    https://github.com/kubouchiyuya/claude-voice-notify
echo.
set /p GITHUB_USER="   GitHubユーザー名を入力してください: "

if "%GITHUB_USER%"=="" (
    echo    ユーザー名が入力されませんでした。
    pause
    exit /b 1
)

curl -s -o nul -w "%%{http_code}" "https://api.github.com/users/%GITHUB_USER%/starred/kubouchiyuya/claude-voice-notify" > %TEMP%\starcheck.txt 2>nul
set /p STAR_CODE=<%TEMP%\starcheck.txt
del %TEMP%\starcheck.txt >nul 2>&1

if "%STAR_CODE%"=="204" (
    echo    OK: Star 確認OK！ @%GITHUB_USER% さん、ありがとうございます！
) else (
    echo.
    echo    @%GITHUB_USER% のStar が確認できませんでした。
    echo.
    echo    以下の手順でStarしてください：
    echo    1. https://github.com/kubouchiyuya/claude-voice-notify を開く
    echo    2. 右上の Star ボタンをクリック
    echo    3. もう一度このスクリプトを実行
    echo.
    set /p OPEN_BROWSER="   今すぐブラウザで開きますか？ [y/N]: "
    if /i "!OPEN_BROWSER!"=="y" (
        start https://github.com/kubouchiyuya/claude-voice-notify
    )
    pause
    exit /b 1
)

echo.

REM ============================================
REM 1. Node.js 確認
REM ============================================
echo [1/5] Node.js を確認...
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo    Node.js が見つかりません。
    echo    https://nodejs.org/ からインストールしてください。
    pause
    exit /b 1
)
for /f "tokens=*" %%i in ('node -v') do echo    OK: Node.js %%i

REM ============================================
REM 2. VOICEVOX 確認
REM ============================================
echo.
echo [2/5] VOICEVOX を確認...
set VOICEVOX_FOUND=0
set VOICEVOX_RUNNING=0

curl -s --max-time 1 http://localhost:50021/version >nul 2>&1
if %errorlevel% equ 0 (
    set VOICEVOX_RUNNING=1
    echo    OK: VOICEVOX が起動しています
    goto :build
)

if exist "%LOCALAPPDATA%\Programs\VOICEVOX\VOICEVOX.exe" (
    set VOICEVOX_FOUND=1
    echo    OK: VOICEVOX がインストールされています
    goto :start_voicevox
)
if exist "%ProgramFiles%\VOICEVOX\VOICEVOX.exe" (
    set VOICEVOX_FOUND=1
    echo    OK: VOICEVOX がインストールされています
    goto :start_voicevox
)

echo    VOICEVOX が見つかりません。
echo.
echo    インストール方法を選択してください:
echo    1) winget でインストール (推奨)
echo    2) 公式サイトからダウンロード
echo    3) スキップ
echo.
set /p CHOICE="   選択 [1/2/3]: "

if "%CHOICE%"=="1" (
    echo    winget で VOICEVOX をインストール中...
    winget install Hiroshiba.VOICEVOX
    if !errorlevel! equ 0 (
        set VOICEVOX_FOUND=1
        echo    OK: インストール完了
    ) else (
        echo    winget でのインストールに失敗しました。
        echo    公式サイトからダウンロードしてください: https://voicevox.hiroshiba.jp/
    )
)
if "%CHOICE%"=="2" (
    echo    公式サイトを開きます...
    start https://voicevox.hiroshiba.jp/
    echo    ダウンロード・インストール後、再度このスクリプトを実行してください。
    pause
    exit /b 0
)
if "%CHOICE%"=="3" (
    echo    スキップ。
    goto :build
)

:start_voicevox
if %VOICEVOX_RUNNING% equ 0 (
    echo.
    echo [3/5] VOICEVOX を起動しています...
    if exist "%LOCALAPPDATA%\Programs\VOICEVOX\VOICEVOX.exe" (
        start "" "%LOCALAPPDATA%\Programs\VOICEVOX\VOICEVOX.exe"
    ) else if exist "%ProgramFiles%\VOICEVOX\VOICEVOX.exe" (
        start "" "%ProgramFiles%\VOICEVOX\VOICEVOX.exe"
    )
    echo    起動待機中...
    for /L %%i in (1,1,20) do (
        timeout /t 2 /nobreak >nul
        curl -s --max-time 1 http://localhost:50021/version >nul 2>&1
        if !errorlevel! equ 0 (
            set VOICEVOX_RUNNING=1
            echo    OK: VOICEVOX 起動完了
            goto :build
        )
    )
    echo    VOICEVOX の起動に時間がかかっています。手動で起動してください。
)

:build
REM ============================================
REM 4. npm build
REM ============================================
echo.
echo [4/5] プロジェクトをビルド...
cd /d "%~dp0"
if not exist "node_modules" npm install
npm run build
echo    OK: ビルド完了

REM ============================================
REM 5. テスト
REM ============================================
echo.
echo [5/5] 音声テスト...
powershell -ExecutionPolicy Bypass -File "%~dp0notify.ps1" "セットアップが完了しました" complete

echo.
echo ==========================================
echo   セットアップ完了！
echo ==========================================
echo.
echo   使い方:
echo   - notify.ps1 "メッセージ"          読み上げ
echo   - notify.sh list                   キャラ一覧
echo   - notify.sh set-speaker ID         キャラ変更
echo   - notify.sh on / off               オン/オフ
echo.
pause
