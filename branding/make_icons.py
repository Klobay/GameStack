import os, sys
from PIL import Image, ImageDraw, ImageFilter

PALETTES = {
    'game': dict(bg=(16, 18, 17), accent=(185, 243, 90), glow2=(45, 212, 191)),
    'movie': dict(bg=(14, 12, 13), accent=(244, 185, 66), glow2=(192, 48, 74)),
}
SS = 4

def logo_layers(w, h):
    out = []
    for top, alpha in ((h * 0.56, 0.45), (h * 0.28, 0.75), (0.0, 1.0)):
        pts = [(w / 2, top), (w - 1, top + h * 0.18), (w / 2, top + h * 0.36), (1, top + h * 0.18)]
        out.append((pts, alpha))
    return out

def foreground(size, accent, logo_frac=0.5, stroke=2.7):
    big = size * SS
    img = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    lw = big * logo_frac
    k = lw / 25.0
    lh = 28 * k
    ox = (big - lw) / 2
    oy = (big - lh * 0.92) / 2
    for pts, alpha in logo_layers(25, 28):
        layer = Image.new('RGBA', (big, big), (0, 0, 0, 0))
        d = ImageDraw.Draw(layer)
        sp = [(ox + x * k, oy + y * k) for x, y in pts]
        sw = max(2, int(stroke * k))
        d.line(sp + [sp[0], sp[1]], fill=accent + (int(255 * alpha),), width=sw, joint='curve')
        r = sw / 2
        for x, y in sp:
            d.ellipse((x - r, y - r, x + r, y + r), fill=accent + (int(255 * alpha),))
        img = Image.alpha_composite(img, layer)
    return img.resize((size, size), Image.LANCZOS)

def background(size, bg, accent, glow2):
    big = size
    img = Image.new('RGBA', (big, big), bg + (255,))
    def blob(cx, cy, r, color, a):
        layer = Image.new('RGBA', (big, big), (0, 0, 0, 0))
        d = ImageDraw.Draw(layer)
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=color + (int(255 * a),))
        return layer.filter(ImageFilter.GaussianBlur(r * 0.55))
    img = Image.alpha_composite(img, blob(big * 0.32, big * 0.30, big * 0.34, accent, 0.20))
    img = Image.alpha_composite(img, blob(big * 0.78, big * 0.80, big * 0.34, glow2, 0.22))
    return img

def build(name, out_dir):
    p = PALETTES[name]
    dens = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
    for d, m in dens.items():
        folder = os.path.join(out_dir, f'mipmap-{d}')
        os.makedirs(folder, exist_ok=True)
        s108 = int(108 * m)
        fg = foreground(s108, p['accent'])
        bgimg = background(s108, p['bg'], p['accent'], p['glow2'])
        fg.save(os.path.join(folder, 'ic_launcher_foreground.png'))
        bgimg.convert('RGB').save(os.path.join(folder, 'ic_launcher_background.png'))
        comp = Image.alpha_composite(bgimg, foreground(s108, p['accent'], logo_frac=0.62))
        crop = comp.crop((int(s108 * 18 / 108), int(s108 * 18 / 108), int(s108 * 90 / 108), int(s108 * 90 / 108)))
        s48 = int(48 * m)
        legacy = crop.resize((s48, s48), Image.LANCZOS)
        mask = Image.new('L', (s48 * 4, s48 * 4), 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, s48 * 4 - 1, s48 * 4 - 1), radius=int(s48 * 4 * 0.22), fill=255)
        mask = mask.resize((s48, s48), Image.LANCZOS)
        legacy.putalpha(mask)
        legacy.save(os.path.join(folder, 'ic_launcher.png'))
        rnd = crop.resize((s48, s48), Image.LANCZOS)
        cm = Image.new('L', (s48 * 4, s48 * 4), 0)
        ImageDraw.Draw(cm).ellipse((0, 0, s48 * 4 - 1, s48 * 4 - 1), fill=255)
        rnd.putalpha(cm.resize((s48, s48), Image.LANCZOS))
        rnd.save(os.path.join(folder, 'ic_launcher_round.png'))
    any_dir = os.path.join(out_dir, 'mipmap-anydpi-v26')
    os.makedirs(any_dir, exist_ok=True)
    xml = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
    <monochrome android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
'''
    open(os.path.join(any_dir, 'ic_launcher.xml'), 'w').write(xml)
    open(os.path.join(any_dir, 'ic_launcher_round.xml'), 'w').write(xml)
    prev = Image.alpha_composite(background(512, p['bg'], p['accent'], p['glow2']), foreground(512, p['accent'], logo_frac=0.62))
    m = Image.new('L', (2048, 2048), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, 2047, 2047), radius=450, fill=255)
    prev.putalpha(m.resize((512, 512), Image.LANCZOS))
    prev.save(os.path.join(out_dir, '..', f'preview_{name}.png'))

for n in ('game', 'movie'):
    build(n, f'/home/claude/icons/{n}/res')
