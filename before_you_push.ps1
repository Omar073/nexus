$ErrorActionPreference = "Stop"

Write-Host "========================================="
Write-Host "  Pre-push checks (Nexus)"
Write-Host "========================================="
Write-Host ""

# 1. Hygiene (auto-fix unused imports, deprecated APIs, etc.)
Write-Host "[1/4] Applying dart fixes..."
dart fix --apply
Write-Host "  ✔ Fixes applied"
Write-Host ""

# 2. Formatting
Write-Host "[2/4] Formatting..."
dart format .
dart format --output=none --set-exit-if-changed .
Write-Host "  ✔ Formatting OK"
Write-Host ""

# 3. Static analysis
Write-Host "[3/4] Analyzing..."
flutter analyze
Write-Host "  ✔ Analysis OK"
Write-Host ""

# 4. Tests
Write-Host "[4/4] Running tests..."
flutter test
Write-Host ""

Write-Host "========================================="
Write-Host "  All checks passed!"
Write-Host "========================================="
