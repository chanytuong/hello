param(
  [string]$Tag = "before",
  [string]$Mode = "record",
  [int]$CaptureSeconds = 26,
  [int]$StartDelayMs = 900,
  [int]$Fps = 60,
  [string]$Source = "desktop",
  [int]$OffsetX = 40,
  [int]$OffsetY = 40,
  [int]$Width = 1280,
  [int]$Height = 720,
  [string]$Ab = ""
)
$ErrorActionPreference = "Stop"
$godot = "C:\Users\Aloha\AppData\Local\Temp\opencode\godot\Godot_v4.7.2-stable_win64_console.exe"
$project = "E:\neverlookback"
$outdir = Join-Path $project "scripts\lab\m1_fps_debug"
$ff = (& python -c "import imageio_ffmpeg;print(imageio_ffmpeg.get_ffmpeg_exe())").Trim()
New-Item -ItemType Directory -Force -Path $outdir | Out-Null

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32Foreground {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
  [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr after, int x, int y, int cx, int cy, uint flags);
  [DllImport("user32.dll")] public static extern IntPtr WindowFromPoint(int x, int y);
  [DllImport("user32.dll")] public static extern IntPtr GetAncestor(IntPtr hWnd, uint flags);
}
"@

$raw = Join-Path $outdir "${Tag}_raw.mp4"
if (Test-Path $raw) { Remove-Item $raw -Force }
Get-Process -Name "Godot_v4.7.2-stable_win64*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500

$gameArgs = @(
  "--path", $project,
  "--resolution", "1280x720",
  "--position", "40,40",
  "res://scripts/lab/m1_fps_test.tscn",
  "--", "--mode=$Mode", "--tag=$Tag"
)
if ($Ab -ne "") { $gameArgs += "--ab=$Ab" }
$game = Start-Process -FilePath $godot -ArgumentList $gameArgs -PassThru

# Wait until the actual game window exists and carries the expected title.
$gameProc = $null
for ($i = 0; $i -lt 300; $i++) {
  $gameProc = Get-Process -Name "Godot_v4.7.2-stable_win64" -ErrorAction SilentlyContinue |
    Where-Object { $_.MainWindowTitle -eq "NEVERLOOKBACK (DEBUG)" } | Select-Object -First 1
  if ($gameProc) { break }
  Start-Sleep -Milliseconds 100
}
if (-not $gameProc) { throw "Game window did not appear" }
[Win32Foreground]::ShowWindow($gameProc.MainWindowHandle, 9) | Out-Null
[Win32Foreground]::SetForegroundWindow($gameProc.MainWindowHandle) | Out-Null
# If a maximized browser/editor covers the capture rectangle, minimize its
# top-level window for the duration of the recording and restore it afterwards.
$occluder = [Win32Foreground]::WindowFromPoint(100, 100)
$occluderRoot = [Win32Foreground]::GetAncestor($occluder, 2)
$minimized = [IntPtr]::Zero
if ($occluderRoot -ne [IntPtr]::Zero -and $occluderRoot -ne $gameProc.MainWindowHandle) {
  [Win32Foreground]::ShowWindow($occluderRoot, 6) | Out-Null
  $minimized = $occluderRoot
}
# Temporarily pin the game above other windows so a full-desktop crop records
# the game even when the user's browser/editor is maximized behind it.
[Win32Foreground]::SetWindowPos($gameProc.MainWindowHandle, [IntPtr](-1), 40, 40, 1280, 720, 0x0001 -bor 0x0002 -bor 0x0040) | Out-Null
Start-Sleep -Milliseconds $StartDelayMs

# External real-time capture: the HUD must show the real frame rate, so this
# intentionally records the actual window instead of using Movie Maker mode.
$captureStart = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$log = Join-Path $outdir "${Tag}_ffmpeg.log"
# Native stderr must not abort the script (gdigrab prints a harmless warning).
$ErrorActionPreference = "Continue"
if ($Source -eq "desktop") {
  & $ff -hide_banner -loglevel warning -f gdigrab -framerate $Fps `
    -offset_x $OffsetX -offset_y $OffsetY -video_size "${Width}x${Height}" -i desktop `
    -t $CaptureSeconds -c:v libx264 -preset veryfast -crf 20 -pix_fmt yuv420p -movflags +faststart -y $raw 2> $log
} else {
  & $ff -hide_banner -loglevel warning -f gdigrab -framerate $Fps -thread_queue_size 512 `
    -i "title=NEVERLOOKBACK (DEBUG)" `
    -t $CaptureSeconds -c:v libx264 -preset veryfast -crf 20 -pix_fmt yuv420p -movflags +faststart -y $raw 2> $log
}
$ffExit = $LASTEXITCODE
$captureEnd = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$ErrorActionPreference = "Stop"
[Win32Foreground]::SetWindowPos($gameProc.MainWindowHandle, [IntPtr](-2), 0, 0, 0, 0, 0x0001 -bor 0x0002) | Out-Null
if ($minimized -ne [IntPtr]::Zero) {
  [Win32Foreground]::ShowWindow($minimized, 9) | Out-Null
}
if (-not (Test-Path $raw)) { throw "ffmpeg produced no file: $(Get-Content $log -Raw)" }
if ((Get-Item $raw).Length -lt 200000) { throw "ffmpeg produced a tiny file ($ffExit): $(Get-Content $log -Raw)" }

# Let the fixed 15 s sequence finish (record mode stays open on the DONE frame).
for ($i = 0; $i -lt 120; $i++) {
  if (-not (Get-Process -Name "Godot_v4.7.2-stable_win64" -ErrorAction SilentlyContinue)) { break }
  Start-Sleep -Milliseconds 250
}
Get-Process -Name "Godot_v4.7.2-stable_win64*" -ErrorAction SilentlyContinue | Stop-Process -Force

$json = Join-Path $outdir "$Mode`_$Tag.json"
$result = [ordered]@{
  tag = $Tag
  capture_start_unix_ms = $captureStart
  capture_end_unix_ms = $captureEnd
  raw = $raw
  json = $json
}
if (Test-Path $json) {
  $data = Get-Content $json -Raw | ConvertFrom-Json
  $trimStart = [math]::Max(0.0, ($data.sequence_start_unix_ms - $captureStart) / 1000.0)
  $trimDuration = ($data.sequence_end_unix_ms - $data.sequence_start_unix_ms) / 1000.0
  $result.sequence_start_unix_ms = $data.sequence_start_unix_ms
  $result.sequence_end_unix_ms = $data.sequence_end_unix_ms
  $result.trim_start_s = [math]::Round($trimStart, 3)
  $result.trim_duration_s = [math]::Round($trimDuration, 3)
  $result.hits = $data.hits
  $result.strikes = $data.strikes

  $final = Join-Path $outdir ("M1_FPS_" + $Tag.ToUpper() + ".mp4")
  & $ff -hide_banner -loglevel warning -ss $trimStart -t $trimDuration -i $raw `
    -c:v libx264 -preset veryfast -crf 20 -pix_fmt yuv420p -movflags +faststart -y $final
  $result.final = $final
}
$result | ConvertTo-Json | Set-Content (Join-Path $outdir "$Tag`_capture.json")
$result | ConvertTo-Json
