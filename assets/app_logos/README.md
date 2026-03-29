# App logos (branding)

This directory contains app logo and branding assets used by the splash screen and `flutter_launcher_icons`.

## Files

- `app_icon_black.png` — App icon (black variant)
- `app_icon_white.png` — App icon (white variant)
- `app_name_black.jpg` — App name image (splash, dark background)
- `app_name_white.jpg` — App name image (splash, light background)
- `app_icon_black_rounded.png` — Source for Android launcher / adaptive icons (optional; generate via `dart run scripts/generate_android_icons.dart` after placing `app_icon_black.png`)

## Git ignore

**This directory is git-ignored** so proprietary branding is not committed.

## For contributors

1. Obtain the logo files from the project maintainer (or use placeholders from CI / `scripts/run_ci_locally.ps1`).
2. Place them in **`assets/app_logos/`** (this folder).
3. Filenames must match the list above.

The app runs without real assets; splash and icons may show placeholders or fallbacks.
