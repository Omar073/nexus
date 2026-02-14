#!/bin/bash
set -e

echo "========================================="
echo "  Pre-push checks (Nexus)"
echo "========================================="
echo ""

# 1. Hygiene (auto-fix unused imports, deprecated APIs, etc.)
echo "[1/4] Applying dart fixes..."
dart fix --apply
echo "  ✔ Fixes applied"
echo ""

# 2. Formatting
echo "[2/4] Formatting..."
dart format .
dart format --output=none --set-exit-if-changed .
echo "  ✔ Formatting OK"
echo ""

# 3. Static analysis
echo "[3/4] Analyzing..."
flutter analyze
echo "  ✔ Analysis OK"
echo ""

# 4. Tests
echo "[4/4] Running tests..."
flutter test
echo ""

echo "========================================="
echo "  All checks passed!"
echo "========================================="
