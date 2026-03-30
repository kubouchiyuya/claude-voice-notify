import { execFile } from 'child_process';
import { writeFile, unlink } from 'fs/promises';
import { tmpdir } from 'os';
import { join } from 'path';
import { platform } from 'process';

export async function playAudio(audioBuffer: Buffer, volume: number = 1.0): Promise<void> {
  const tmpPath = join(tmpdir(), `claude-voice-${Date.now()}.wav`);
  await writeFile(tmpPath, audioBuffer);

  try {
    await new Promise<void>((resolve, reject) => {
      const os = platform;
      let cmd: string;
      let args: string[];

      if (os === 'darwin') {
        cmd = 'afplay';
        args = ['-v', String(volume), tmpPath];
      } else if (os === 'win32') {
        // Windows: PowerShell の Media.SoundPlayer で再生
        // パスのエスケープを考慮して変数展開を使用
        cmd = 'powershell';
        args = [
          '-NoProfile',
          '-ExecutionPolicy', 'Bypass',
          '-Command',
          `Add-Type -AssemblyName presentationCore; $p = New-Object System.Windows.Media.MediaPlayer; $p.Open([Uri]'${tmpPath.replace(/'/g, "''")}'); $p.Volume = ${volume}; $p.Play(); Start-Sleep -Milliseconds 100; while ($p.Position -lt $p.NaturalDuration.TimeSpan) { Start-Sleep -Milliseconds 100 }; $p.Close()`,
        ];
      } else {
        // Linux: aplay (ALSA), paplay (PulseAudio), or play (SoX) in fallback order
        cmd = 'aplay';
        args = ['-q', tmpPath];
      }

      execFile(cmd, args, (error) => {
        if (error) {
          // Linux fallback: try paplay
          if (os === 'linux') {
            execFile('paplay', [tmpPath], (err2) => {
              if (err2) reject(error);
              else resolve();
            });
          } else {
            reject(error);
          }
        } else {
          resolve();
        }
      });
    });
  } finally {
    await unlink(tmpPath).catch(() => {});
  }
}
