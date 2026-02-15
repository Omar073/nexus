---
description: Run pre-push hygiene checks after finishing major code changes
---

After completing any major code change (refactoring, new features, bug fixes spanning multiple files), run the full local CI pipeline to verify code quality:

// turbo

1. Run the local CI checks:

```powershell
powershell -ExecutionPolicy Bypass -File "scripts/run_ci_locally.ps1"
```

1. If any step fails, fix the issues before proceeding.
