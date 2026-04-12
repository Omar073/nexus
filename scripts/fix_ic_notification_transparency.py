#!/usr/bin/env python3
"""Make ic_notification.png usable as an Android notification small icon.

Android treats the drawable as a template: only the alpha channel matters for
the silhouette; opaque areas are tinted (often all white in the status bar).
Solid black backgrounds become a single opaque blob → white rounded square.

This script makes dark pixels transparent and normalizes light pixels to white.
Requires: pip install Pillow

Usage (from repo root):
  python scripts/fix_ic_notification_transparency.py
"""

from __future__ import annotations

import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Install Pillow: python -m pip install Pillow", file=sys.stderr)
    sys.exit(1)

# Pixels darker than this (max RGB) become fully transparent.
DARK_MAX = 55
# Pixels lighter than this (min RGB) become opaque white.
LIGHT_MIN = 200


def process_rgba(img: Image.Image) -> Image.Image:
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            mx = max(r, g, b)
            mn = min(r, g, b)
            if mx <= DARK_MAX and mn <= DARK_MAX + 15:
                px[x, y] = (255, 255, 255, 0)
            elif mn >= LIGHT_MIN:
                px[x, y] = (255, 255, 255, 255)
            else:
                # Anti-aliased edge: fade alpha, keep white for template tinting.
                lum = (r + g + b) / 3.0
                if lum < DARK_MAX:
                    px[x, y] = (255, 255, 255, 0)
                else:
                    alpha = int(min(255, max(0, (lum - DARK_MAX) / (255 - DARK_MAX) * 255)))
                    px[x, y] = (255, 255, 255, alpha)
    return img


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    res = root / "android" / "app" / "src" / "main" / "res"
    paths = sorted(res.glob("drawable-*/ic_notification.png"))
    loose = res / "ic_notification.png"
    if loose.is_file():
        paths = sorted({*paths, loose})
    if not paths:
        print(f"No ic_notification.png under {res}", file=sys.stderr)
        sys.exit(1)
    for path in paths:
        im = Image.open(path)
        out = process_rgba(im)
        out.save(path, format="PNG", optimize=True)
        print(f"OK {path.relative_to(root)}")


if __name__ == "__main__":
    main()
