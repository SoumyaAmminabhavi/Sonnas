# Build Flutter web for production with WebAssembly (WASM)
# Usage: .\scripts\build-web-prod.ps1
#
# Requires .env file with:
#   SUPABASE_URL=https://...
#   SUPABASE_ANON_KEY=eyJ...

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
param(
    [switch]$NoWasm   # Pass -NoWasm to fall back to standard JS release build
)

# ── Load env vars from .env ───────────────────────────────────────────────────
$envFile = ".env"
if (-not (Test-Path $envFile)) {
    Write-Host "Error: .env file not found. Create one with SUPABASE_URL and SUPABASE_ANON_KEY." -ForegroundColor Red
    exit 1
}

$supabaseUrl = ""
$supabaseKey = ""       
$backendUrl = ""
foreach ($line in Get-Content $envFile) {
    if ($line -match "^SUPABASE_URL=(.+)$")      { $supabaseUrl = $Matches[1].Trim() }
    if ($line -match "^SUPABASE_ANON_KEY=(.+)$") { $supabaseKey = $Matches[1].Trim() }
    if ($line -match "^BACKEND_URL=(.+)$")       { $backendUrl = $Matches[1].Trim() }
}

# Remove any double quotes surrounding the value
$supabaseUrl = $supabaseUrl.Trim('"')
$supabaseKey = $supabaseKey.Trim('"')
$backendUrl = $backendUrl.Trim('"')

if (-not $supabaseUrl -or -not $supabaseKey) {
    Write-Host "Error: SUPABASE_URL or SUPABASE_ANON_KEY missing from .env" -ForegroundColor Red
    exit 1
}

# ── Build ─────────────────────────────────────────────────────────────────────
if ($NoWasm) {
    Write-Host "`nBuilding Flutter Web (release / JS)..." -ForegroundColor Green
    flutter build web --release `
        --dart-define=SUPABASE_URL="$supabaseUrl" `
        --dart-define=SUPABASE_ANON_KEY="$supabaseKey" `
        --dart-define=BACKEND_URL="$backendUrl"
} else {
    Write-Host "`nBuilding Flutter Web (WASM)..." -ForegroundColor Green
    flutter build web --wasm `
        --dart-define=SUPABASE_URL="$supabaseUrl" `
        --dart-define=SUPABASE_ANON_KEY="$supabaseKey" `
        --dart-define=BACKEND_URL="$backendUrl"
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nError: Flutter build failed." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path "build/web")) {
    Write-Host "Error: build/web directory not found after build." -ForegroundColor Red
    exit 1
}

# ── Size summary ──────────────────────────────────────────────────────────────
Write-Host "`nBuild size summary:" -ForegroundColor Cyan
$totalBytes = (Get-ChildItem "build/web" -Recurse -File | Measure-Object -Property Length -Sum).Sum
$totalMB    = [math]::Round($totalBytes / 1MB, 2)
Write-Host "  Total: $totalMB MB" -ForegroundColor Cyan

$mainJs = Get-ChildItem "build/web" -Filter "main.dart.*" -Recurse | Select-Object -First 1
if ($mainJs) {
    $mainKB = [math]::Round($mainJs.Length / 1KB, 1)
    Write-Host "  $($mainJs.Name): $mainKB KB" -ForegroundColor Cyan
}

# ── Copy to public/ directory for Next.js hosting ──────────────────────────────
Write-Host "`nCopying Flutter build files to public/ for Next.js deployment..." -ForegroundColor Cyan
if (-not (Test-Path "public")) {
    New-Item -ItemType Directory -Path "public" | Out-Null
}
Copy-Item -Path "build/web/*" -Destination "public" -Recurse -Force
Write-Host "Copy completed! Ready to deploy." -ForegroundColor Green

# ── Done ──────────────────────────────────────────────────────────────────────
Write-Host "`nBuild completed successfully!" -ForegroundColor Green
Write-Host "`nTo test locally:" -ForegroundColor Yellow
Write-Host "  npm run dev" -ForegroundColor White
Write-Host "  Open http://localhost:3000 in Chrome (both Next.js backend and Flutter app are live!)" -ForegroundColor White
Write-Host "`nTo deploy to Vercel:" -ForegroundColor Yellow
Write-Host "  vercel --prod" -ForegroundColor White