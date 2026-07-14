# 🚀 AI Agent Study — Local Dev Server
# Run this script to start a local HTTP server, then open http://localhost:8080

$port = 8080
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$found = $false

# Method 1: Python
try {
  $v = python --version 2>&1
  if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Python $v" -ForegroundColor Green
    Write-Host "→ http://localhost:$port" -ForegroundColor Cyan
    python -m http.server $port -d $root
    $found = $true
  }
} catch {}

if (-not $found) {
  # Method 2: Node.js + serve
  try {
    $v = node --version 2>&1
    if ($LASTEXITCODE -eq 0) {
      # Try npx serve
      Write-Host "✅ Node.js $v" -ForegroundColor Green
      Write-Host "→ http://localhost:$port" -ForegroundColor Cyan
      npx -y serve $root -p $port --no-clipboard
      $found = $true
    }
  } catch {}
}

if (-not $found) {
  # Method 3: PowerShell .NET HttpListener
  Write-Host "⚡ Using PowerShell built-in server..." -ForegroundColor Yellow
  Write-Host "→ http://localhost:$port" -ForegroundColor Cyan
  $listener = New-Object System.Net.HttpListener
  $listener.Prefixes.Add("http://localhost:$port/")
  $listener.Start()
  Write-Host "Press Ctrl+C to stop" -ForegroundColor DarkGray
  while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    $req = $ctx.Request
    $path = $req.Url.LocalPath.TrimStart('/')
    if ([string]::IsNullOrEmpty($path)) { $path = "index.html" }
    $full = Join-Path $root $path
    $res = $ctx.Response
    if (Test-Path $full) {
      $bytes = [IO.File]::ReadAllBytes($full)
      $ext = [IO.Path]::GetExtension($full)
      $mime = @{
        '.html'='text/html';'.htm'='text/html';'.md'='text/markdown'
        '.js'='text/javascript';'.css'='text/css';'.json'='application/json'
        '.png'='image/png';'.jpg'='image/jpeg';'.svg'='image/svg+xml'
        '.py'='text/plain';'.ps1'='text/plain'
      }
      $res.ContentType = $mime[$ext] -replace '^$','text/plain'
      $res.ContentLength64 = $bytes.Length
      $res.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
      $res.StatusCode = 404
      $msg = [Text.Encoding]::UTF8.GetBytes("404 Not Found: $path")
      $res.OutputStream.Write($msg, 0, $msg.Length)
    }
    $res.OutputStream.Close()
  }
  $listener.Stop()
}
