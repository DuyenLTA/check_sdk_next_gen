#!/bin/bash
# Test devices only: the "AdMob native ad validator" popup is not in the uiautomator tree and can cover
# app buttons (Next / Go to Home / btnSkip). Find its blue "Dismiss" button on a screenshot and tap it.
# exit 0 = tapped, 1 = no popup found.
f=$(mktemp --suffix=.png); adb exec-out screencap -p > "$f"
xy=$(python3 -I - "$f" <<'PY'
import sys
from PIL import Image
im = Image.open(sys.argv[1]).convert("RGB"); W, H = im.size; px = im.load()
# Dismiss button fill is Google blue (~#1a73e8); find the largest dense blue row band
best = None
for y in range(0, H, 4):
    xs = [x for x in range(0, W, 4) if (lambda r, g, b: b > 200 and r < 60 and 90 < g < 140)(*px[x, y])]
    if len(xs) > 30 and max(xs) - min(xs) < W * 0.4:
        best = (best or []) + [(y, min(xs), max(xs))]
if best:
    ys = [b[0] for b in best]; x0 = min(b[1] for b in best); x1 = max(b[2] for b in best)
    if max(ys) - min(ys) < 200: print((x0 + x1) // 2, (min(ys) + max(ys)) // 2)
PY
)
rm -f "$f"; [ -z "$xy" ] && exit 1
adb shell input tap $xy; echo "validator dismiss @ $xy"
