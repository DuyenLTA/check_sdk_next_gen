"""HT-09 / HV-06: lay the OB3 frames from capture-ob3-fullscreen-native-frames.sh on one contact sheet.

usage: python3 -I ob3_frames_montage.py <out-dir> <tag> [cols=6]
Every frame is labelled '+x.x s' after ob3_view (device clock, from <tag>-ob3.txt), so one image shows
when the native appeared, whether an X / skip button ever showed, and when the page left for OB4.
Also prints how long OB3 stayed (ob3_view -> complete_ob3) and when BACK was pressed.
Writes <out-dir>/<tag>-montage.png.
"""
import glob
import os
import re
import sys

from PIL import Image, ImageDraw

out, tag = sys.argv[1], sys.argv[2]
cols = int(sys.argv[3]) if len(sys.argv) > 3 else 6
marks = {}
for line in open(os.path.join(out, f'{tag}-ob3.txt')):
    k, *v = line.split()
    if v:
        marks[k] = float(v[0])
ref = marks.get('ob3_view')
if ref is None:
    sys.exit('ob3_view epoch missing in %s-ob3.txt' % tag)
for k in ('complete_ob3', 'ob4_view', 'back_sent', 'back_done'):
    if k in marks:
        print(f'{k}: +{marks[k] - ref:.2f} s after ob3_view')

frames = sorted(glob.glob(os.path.join(out, f'{tag}-f*.png')))
W, H = 216, 480
rows = (len(frames) + cols - 1) // cols
sheet = Image.new('RGB', (W * cols, H * rows), 'white')
draw = ImageDraw.Draw(sheet)
for i, f in enumerate(frames):
    t = float(re.search(r'-f\d+-([\d.]+)\.png$', f).group(1)) - ref
    x, y = (i % cols) * W, (i // cols) * H
    sheet.paste(Image.open(f).convert('RGB').resize((W, H)), (x, y))
    draw.rectangle([x, y, x + 80, y + 18], fill='yellow')
    draw.text((x + 2, y + 2), f'+{t:.1f}s', fill='black')
dst = os.path.join(out, f'{tag}-montage.png')
sheet.save(dst)
print(dst, len(frames), 'frames')
