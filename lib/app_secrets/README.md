# App Secrets

This directory contains sensitive application secrets that should **never be committed** to version control.

## Files

- **`app_secrets.dart.example`** - Template file with placeholder values (committed to Git)
- **`app_secrets.dart`** - Actual secrets file (git-ignored, **DO NOT COMMIT**)

## Setup for New Contributors

1. Copy the example file:

   ```bash
   Copy-Item lib/app_secrets/app_secrets.dart.example lib/app_secrets/app_secrets.dart
   ```

2. Fill in the real values in `app_secrets.dart`

3. Verify it's ignored by Git:

   ```bash
   git check-ignore lib/app_secrets/app_secrets.dart
   ```

   This should output the file path, confirming it's ignored.

## Current Secrets

### Google Drive Media Folder ID

- **Purpose**: The Google Drive folder ID where app attachments (images, voice notes) are stored
- **How to get**:
  1. Open your Google Drive folder
  2. Copy the folder ID from the URL: `https://drive.google.com/drive/folders/FOLDER_ID`
  3. Paste it into `app_secrets.dart` as `googleDriveMediaFolderId`

## Security Notes

- The `app_secrets.dart` file is listed in `.gitignore` and will not be committed
- Never share your actual secrets file with others
- If secrets are accidentally committed, rotate them immediately
- The example file (`app_secrets.dart.example`) is safe to commit as it only contains placeholders
