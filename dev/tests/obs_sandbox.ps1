# (Re)start the isolated portable OBS sandbox (C:\Temp\obs-portable) whose scene
# collection loads the repo script directly, then print the Lumetric log lines.
#
#   pwsh dev/tests/obs_sandbox.ps1 [-WaitSeconds 60] [-Stop]
param(
    [string]$Root = "C:\Temp\obs-portable",
    [int]$WaitSeconds = 60,
    [switch]$Stop
)
$ErrorActionPreference = "Stop"
$exe = Join-Path $Root "bin\64bit\obs64.exe"
$logDir = Join-Path $Root "config\obs-studio\logs"

Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class SandboxClose {
    public delegate bool EnumProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lParam);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hWnd, StringBuilder sb, int max);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);
    public static int CloseAll(uint pid) {
        int sent = 0;
        EnumWindows((h, l) => {
            uint wp; GetWindowThreadProcessId(h, out wp);
            if (wp == pid && IsWindowVisible(h)) { PostMessage(h, 0x0010, IntPtr.Zero, IntPtr.Zero); sent++; }
            return true;
        }, IntPtr.Zero);
        return sent;
    }
}
"@

# Only ever touch the sandbox process (matched by executable path), never the user's OBS.
$running = Get-Process obs64 -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $exe }
if ($running) {
    $sent = [SandboxClose]::CloseAll([uint32]$running.Id)
    Write-Output "sandbox OBS: WM_CLOSE sent to $sent window(s)"
    $deadline = (Get-Date).AddSeconds(40)
    while (-not $running.HasExited -and (Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 500 }
    if (-not $running.HasExited) {
        $running | Stop-Process -Force
        Write-Output "sandbox OBS killed (pid $($running.Id))"
    } else {
        Write-Output "sandbox OBS exited cleanly"
    }
    Start-Sleep -Seconds 2
}
# A killed sandbox leaves a sentinel (a directory in OBS 32) that would trigger the
# crash dialog on the next start.
$sentinel = Join-Path $Root "config\obs-studio\.sentinel"
if (Test-Path -LiteralPath $sentinel) { Remove-Item -LiteralPath $sentinel -Recurse -Force -ErrorAction SilentlyContinue }
Get-ChildItem (Join-Path $Root "config\obs-studio\crashes") -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
if (Test-Path -LiteralPath $sentinel) { Write-Output "WARNING: sentinel still present" } else { Write-Output "sentinel cleared" }
if ($Stop) { exit 0 }

$before = @(Get-ChildItem $logDir -ErrorAction SilentlyContinue | ForEach-Object { $_.Name })
Start-Process -FilePath $exe -WorkingDirectory (Split-Path $exe) -ArgumentList "--disable-shutdown-check", "--disable-updater", "--disable-missing-files-check"
$deadline = (Get-Date).AddSeconds($WaitSeconds)
$log = $null
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 2
    $candidates = Get-ChildItem $logDir -ErrorAction SilentlyContinue | Where-Object { $before -notcontains $_.Name -and $_.Length -gt 0 }
    if ($candidates) {
        $log = $candidates | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        $text = Get-Content -LiteralPath $log.FullName -Raw
        if ($text -match "shader ready|Shader-Parameter geladen|Failed to load|not found|Scene collection loaded|Loaded scenes:") { break }
    }
}
if (-not $log) { Write-Output "no new log within $WaitSeconds s"; exit 3 }
Write-Output "log: $($log.FullName)"
Select-String -LiteralPath $log.FullName -Pattern "Lumetric|\[Lua\]|lua script|Render error|scripting|websocket\] \[WebSocketServer::Start|Loaded scenes|LumetricTest|shader" -CaseSensitive:$false | ForEach-Object { $_.Line } | Select-Object -First 40
