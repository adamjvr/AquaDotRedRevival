#!/usr/bin/env python3
"""
AquaDotRed Revival - Phase 4H main-menu AquaDot remaster generator.

This is NEW remastered artwork, not a recovered historical flattened master.
The large spot placement is based on the recovered Aquadot-Spots-Alpha source
and the color/material language follows the Phase 4C remastered normal AquaDot.
"""
from __future__ import annotations
from pathlib import Path
import argparse
import math
from PIL import Image, ImageDraw, ImageFilter, ImageChops

SIZE = 1024
SS = 2

def S(v: float) -> int:
    return int(round(v * SS))

def ellipse_box(cx, cy, rx, ry):
    return (S(cx-rx), S(cy-ry), S(cx+rx), S(cy+ry))

def generate(output: Path) -> None:
    W = H = SIZE * SS
    cx = cy = W // 2
    radius = S(405)

    # Transparent compositing canvas.
    canvas = Image.new("RGBA", (W, H), (0,0,0,0))

    # Broad cool halo helps the red AquaDot live behind the cyan title/menu.
    halo = Image.new("RGBA", (W,H), (0,0,0,0))
    hd = ImageDraw.Draw(halo)
    for r, a, color in [
        (468, 28, (18, 225, 255)),
        (438, 42, (255, 35, 52)),
        (420, 74, (42, 232, 255)),
    ]:
        hd.ellipse((cx-S(r), cy-S(r), cx+S(r), cy+S(r)), fill=(*color, a))
    halo = halo.filter(ImageFilter.GaussianBlur(S(42)))
    canvas.alpha_composite(halo)

    # Circular mask with a feathered antialiased boundary.
    mask = Image.new("L", (W,H), 0)
    md = ImageDraw.Draw(mask)
    md.ellipse((cx-radius, cy-radius, cx+radius, cy+radius), fill=255)

    # Build a spherical crimson body from per-pixel radial + light gradients.
    body = Image.new("RGBA", (W,H), (0,0,0,0))
    pix = body.load()
    # Only iterate the circle's bounding box.
    light_x, light_y = cx - S(155), cy - S(185)
    for y in range(cy-radius, cy+radius+1):
        dy = (y-cy)/radius
        for x in range(cx-radius, cx+radius+1):
            dx = (x-cx)/radius
            rr = dx*dx + dy*dy
            if rr > 1.0:
                continue
            z = math.sqrt(max(0.0, 1.0-rr))
            # Diffuse lighting from upper-left + strong rim falloff.
            lx = (x-light_x)/radius
            ly = (y-light_y)/radius
            highlight = math.exp(-((lx*lx + ly*ly) / 0.18))
            edge = max(0.0, min(1.0, z))
            # Deep red material consistent with the normal/player identity.
            r = int(65 + 118*edge + 63*highlight)
            g = int(3 + 14*edge + 25*highlight)
            b = int(12 + 24*edge + 26*highlight)
            # Cooler lower-right bounce from the cyan interface.
            bounce = max(0.0, (dx + dy - 0.15)) * 0.33
            g = min(255, int(g + 48*bounce))
            b = min(255, int(b + 74*bounce))
            pix[x,y] = (min(255,r), g, b, 255)

    # Add a soft inner crimson bloom.
    bloom = Image.new("RGBA",(W,H),(0,0,0,0))
    bd=ImageDraw.Draw(bloom)
    bd.ellipse(ellipse_box(424, 388, 235, 210), fill=(255,52,62,78))
    bloom = bloom.filter(ImageFilter.GaussianBlur(S(76)))
    bloom.putalpha(ImageChops.multiply(bloom.getchannel("A"), mask))
    body.alpha_composite(bloom)

    # Spots: placements/scale intentionally echo recovered Aquadot-Spots-Alpha.
    # They are silver/white pads, not holes, matching the recovered player layers.
    spot_specs = [
        (360, 328, 128, 118, -8),   # upper-left
        (628, 290, 124, 78, 22),    # upper/right grazing the crown
        (705, 476, 126, 126, 0),    # right
        (472, 655, 133, 128, 0),    # lower center
        (695, 704, 145, 82, -34),   # lower-right edge
        (205, 500, 82, 143, -7),    # left edge
    ]

    spots = Image.new("RGBA",(W,H),(0,0,0,0))
    for scx, scy, rx, ry, angle in spot_specs:
        # Draw each pad on its own layer so oblique edge pads can rotate.
        pad_sz = S(max(rx,ry)*3)
        p = Image.new("RGBA",(pad_sz,pad_sz),(0,0,0,0))
        pd=ImageDraw.Draw(p)
        pc=pad_sz//2
        pd.ellipse((pc-S(rx), pc-S(ry), pc+S(rx), pc+S(ry)), fill=(232,240,242,232))
        # Internal glow and lower-right contour for some depth.
        inner = Image.new("RGBA", p.size, (0,0,0,0))
        idr=ImageDraw.Draw(inner)
        idr.ellipse((pc-S(rx*0.78), pc-S(ry*0.78), pc+S(rx*0.78), pc+S(ry*0.78)),
                    fill=(255,255,255,72))
        inner=inner.filter(ImageFilter.GaussianBlur(S(16)))
        p.alpha_composite(inner)
        edge_shadow=Image.new("RGBA",p.size,(0,0,0,0))
        ed=ImageDraw.Draw(edge_shadow)
        ed.ellipse((pc-S(rx),pc-S(ry),pc+S(rx),pc+S(ry)), outline=(132,155,160,48), width=S(5))
        edge_shadow=edge_shadow.filter(ImageFilter.GaussianBlur(S(2)))
        p.alpha_composite(edge_shadow)
        if angle:
            p=p.rotate(angle, resample=Image.Resampling.BICUBIC, expand=False)
        px=S(scx)-p.width//2; py=S(scy)-p.height//2
        spots.alpha_composite(p,(px,py))
    spots.putalpha(ImageChops.multiply(spots.getchannel("A"), mask))
    body.alpha_composite(spots)

    # Specular sheen across the face.
    sheen = Image.new("RGBA",(W,H),(0,0,0,0))
    sd=ImageDraw.Draw(sheen)
    sd.ellipse(ellipse_box(383, 304, 232, 128), fill=(255,255,255,46))
    sheen=sheen.filter(ImageFilter.GaussianBlur(S(45)))
    sheen.putalpha(ImageChops.multiply(sheen.getchannel("A"), mask))
    body.alpha_composite(sheen)

    # Strong outside/inside ring recalls original ring-alpha component.
    ring = Image.new("RGBA",(W,H),(0,0,0,0))
    rd=ImageDraw.Draw(ring)
    rd.ellipse((cx-radius,cy-radius,cx+radius,cy+radius),
               outline=(205,250,255,172), width=S(8))
    rd.ellipse((cx-radius+S(18),cy-radius+S(18),cx+radius-S(18),cy+radius-S(18)),
               outline=(255,104,116,92), width=S(5))
    ring_blur=ring.filter(ImageFilter.GaussianBlur(S(8)))
    canvas.alpha_composite(ring_blur)
    body.putalpha(mask)
    canvas.alpha_composite(body)
    canvas.alpha_composite(ring)


    canvas = canvas.resize((SIZE,SIZE), Image.Resampling.LANCZOS)
    # Ensure exact RGBA8 output.
    canvas = canvas.convert("RGBA")
    output.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(output, format="PNG", optimize=True)

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--output", type=Path, required=True)
    args=ap.parse_args()
    generate(args.output)

if __name__=="__main__":
    main()
