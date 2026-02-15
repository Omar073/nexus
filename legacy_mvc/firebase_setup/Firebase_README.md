# Firebase API Keys Security Setup

## Overview

This directory contains Firebase configuration files with a secure pattern that prevents API keys from being committed to version control.

## File Structure

```text
lib/firebase_setup/
├── apiKeys.dart.example    ✅ Committed to Git (template)
├── apiKeys.dart            ❌ Git-ignored (real keys)
├── firebase_options.dart   ✅ Committed to Git (references apiKeys.dart)
└── README.md               ✅ This file
```

## Quick Setup

### For New Team Members

1. **Copy the template file**:

   ```bash
   # Windows (PowerShell)
   Copy-Item lib/firebase_setup/apiKeys.dart.example lib/firebase_setup/apiKeys.dart

   # macOS/Linux
   cp lib/firebase_setup/apiKeys.dart.example lib/firebase_setup/apiKeys.dart
   ```

2. **Get Firebase credentials** from [Firebase Console](https://console.firebase.google.com/):
   - Go to Project Settings → Your apps
   - Copy API Key and App ID for each platform (Web, Android, iOS, Windows)

3. **Fill in the keys** in `apiKeys.dart` with your actual values

4. **Verify Git ignore**:

   ```bash
   git status
   # apiKeys.dart should NOT appear in the list
   ```

## How It Works

- `apiKeys.dart.example` - Template file with placeholders (safe to commit)
- `apiKeys.dart` - Actual keys file (git-ignored, local only)
- `firebase_options.dart` - Imports keys and configures Firebase

## Environment Switching

The setup supports both **Test** and **Live** environments:

**Run in Test Mode**:

```bash
flutter run --dart-define=TESTING=true
```

**Run in Live Mode** (default):

```bash
flutter run
```

## Security Notes

- ✅ **Never commit** `apiKeys.dart` to Git
- ✅ Always use `apiKeys.dart.example` as a template
- ✅ Verify `.gitignore` includes `lib/firebase_setup/apiKeys.dart`
- ✅ Use different keys for test and production if possible

## Troubleshooting

### Error: "Target of URI doesn't exist: 'apiKeys.dart'"

- Solution: Copy `apiKeys.dart.example` to `apiKeys.dart`

### Error: "Undefined name 'webLiveApiKey'"

- Solution: Check that all constants are defined in `apiKeys.dart`

### File is being tracked by Git

- Solution: Run `git rm --cached lib/firebase_setup/apiKeys.dart`

For more details, see the main project documentation.
