# Build Flutter web for production with HTML renderer
# Usage: .\scripts\build-web-prod.ps1

Write-Host "Building Flutter web for production with HTML renderer..." -ForegroundColor Green

# Build web
flutter build web --dart-define=FLUTTER_WEB_RENDERER=html --dart-define-from-file=.env --no-wasm-dry-run

if (-not (Test-Path "build/web")) {
    Write-Host "Error: Build failed - build/web directory not found" -ForegroundColor Red
    exit 1
}

# Remove canvaskit directory (not needed with HTML renderer)
$canvaskitPath = "build/web/canvaskit"
if (Test-Path $canvaskitPath) {
    Write-Host "Removing canvaskit directory..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $canvaskitPath
} else {
    Write-Host "Canvaskit directory not found (already removed?)" -ForegroundColor Yellow
}

# Patch flutter_bootstrap.js to use HTML renderer
$bootstrapPath = "build/web/flutter_bootstrap.js"
if (Test-Path $bootstrapPath) {
    Write-Host "Patching flutter_bootstrap.js for HTML renderer..." -ForegroundColor Yellow
    (Get-Content $bootstrapPath) -replace '"renderer":"canvaskit"', '"renderer":"html"' | Set-Content $bootstrapPath
    Write-Host "Bootstrap patched successfully." -ForegroundColor Green
} else {
    Write-Host "Error: flutter_bootstrap.js not found at $bootstrapPath" -ForegroundColor Red
    exit 1
}

Write-Host "`nBuild completed successfully!" -ForegroundColor Green
Write-Host "To test locally:" -ForegroundColor Cyan
Write-Host "  1. Install a local server if needed: npm install -g serve" -ForegroundColor Cyan
Write-Host "  2. Serve the build: serve -s build/web" -ForegroundColor Cyan
Write-Host "  3. Open http://localhost:3000 in Chrome" -ForegroundColor Cyan
Write-Host "" -ForegroundColor Cyan
Write-Host "To deploy to Vercel:" -ForegroundColor Cyan
Write-Host "  1. Copy build/web contents to Vercel deployment directory" -ForegroundColor Cyan
Write-Host "  2. Or run: vercel --prod build/web" -ForegroundColor Cyan