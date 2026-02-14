---
description: Run pre-push hygiene checks after finishing major code changes
---

After completing any major code change (refactoring, new features, bug fixes spanning multiple files), run the pre-push script to verify code quality:

// turbo

1. Run the pre-push checks:

```powershell
powershell -ExecutionPolicy Bypass -File "before_you_push.ps1"
```

1. If any step fails, fix the issues before proceeding.
