#!/usr/bin/env python3
"""Generate the Phase 4 Reaper assets from preserved AquaDot source sheets.

The Phase 4 authenticity closure restores the special Night/Reaper path recovered
from the original `setupEnemy` switch. The 64px "Original"
files produced here are reconstructed static runtime composites from the preserved
component sheets; they are NOT claimed to be recovered historical flattened PNGs.
The 512px Remastered files use the same source components with higher-resolution
resampling and restrained cleanup, matching the Phase 4D art direction.
"""
from __future__ import annotations

from PIL import Image, ImageOps, ImageChops, ImageEnhance, ImageFilter
from pathlib import Path
import argparse
import math

MAPPING = {
    "Reaper": "Night-Bugs.png",
}

BODY_FRAME = 15
BODY_W, BODY_H = 32, 64
WING_W, WING_H = 64, 32
CANVAS = 512
BODY_OUT = (256, 512)
WING_OUT = (512, 256)


def args():
    p = argparse.ArgumentParser()
    p.add_argument("--source-dir", required=True)
    p.add_argument("--output-dir", required=True)
    return p.parse_args()


def black_shape_alpha(mask_l: Image.Image) -> Image.Image:
    return ImageOps.invert(mask_l.convert("L"))


def scaled_alpha(mask: Image.Image, scale: float) -> Image.Image:
    return mask.point(lambda p: max(0, min(255, int(p * scale))))


def layer_from_mask(mask: Image.Image, rgb, alpha_scale=1.0):
    layer = Image.new("RGBA", mask.size, tuple(rgb) + (0,))
    layer.putalpha(scaled_alpha(mask, alpha_scale))
    return layer


def radial_mask(size, center, radii, power=2.0):
    w, h = size
    cx, cy = center
    rx, ry = radii
    im = Image.new("L", size, 0)
    px = im.load()
    for y in range(h):
        dy = (y - cy) / ry
        for x in range(w):
            dx = (x - cx) / rx
            d = math.sqrt(dx * dx + dy * dy)
            px[x, y] = int(255 * (max(0.0, 1.0 - d) ** power))
    return im


def source_body_rgba(source_dir: Path, source_filename: str, alpha_strip: Image.Image) -> Image.Image:
    strip = Image.open(source_dir / source_filename).convert("RGB")
    rgb = strip.crop((BODY_FRAME * BODY_W, 0, (BODY_FRAME + 1) * BODY_W, BODY_H))
    alpha = black_shape_alpha(
        alpha_strip.crop((BODY_FRAME * BODY_W, 0, (BODY_FRAME + 1) * BODY_W, BODY_H))
    )
    out = rgb.convert("RGBA")
    out.putalpha(alpha)
    return out


def source_wing_rgba(wings_strip: Image.Image, frame: int) -> Image.Image:
    mask = black_shape_alpha(
        wings_strip.crop((0, frame * WING_H, WING_W, (frame + 1) * WING_H))
    )
    out = Image.new("RGBA", (WING_W, WING_H), (42, 44, 50, 0))
    out.putalpha(scaled_alpha(mask, 0.92))
    return out


def build_original(source_dir: Path, source_filename: str, alpha_strip: Image.Image, wings_strip: Image.Image) -> Image.Image:
    # Source-native 64x64 static composite. Two opposing source wing phases create
    # the same four-wing read used by the modern runtime without enlarging source art.
    vertical = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    for frame in (0, 7):
        wing = source_wing_rgba(wings_strip, frame)
        vertical.alpha_composite(wing, (0, 16))
    body = source_body_rgba(source_dir, source_filename, alpha_strip)
    vertical.alpha_composite(body, (16, 0))
    return vertical.transpose(Image.Transpose.ROTATE_270)


def wing_layer(wings_strip: Image.Image, frame_index: int) -> Image.Image:
    src = wings_strip.crop((0, frame_index * WING_H, WING_W, (frame_index + 1) * WING_H))
    mask = black_shape_alpha(src).resize(WING_OUT, Image.Resampling.LANCZOS)
    mask = mask.filter(ImageFilter.MaxFilter(19)).filter(ImageFilter.GaussianBlur(0.85))
    base = layer_from_mask(mask, (40, 43, 49), 0.92)
    core = mask.point(lambda p: max(0, min(255, (p - 80) * 2))).filter(ImageFilter.GaussianBlur(3.0))
    return Image.alpha_composite(base, layer_from_mask(core, (205, 210, 220), 0.20))


def body_layer(source_dir: Path, source_filename: str, alpha_strip: Image.Image) -> Image.Image:
    small = source_body_rgba(source_dir, source_filename, alpha_strip)
    body = small.resize(BODY_OUT, Image.Resampling.LANCZOS)

    r, g, b, a = body.split()
    rgb_hi = Image.merge("RGB", (r, g, b))
    rgb_hi = ImageEnhance.Color(rgb_hi).enhance(1.06)
    rgb_hi = ImageEnhance.Contrast(rgb_hi).enhance(1.07)
    rgb_hi = rgb_hi.filter(ImageFilter.GaussianBlur(0.28))
    rgb_hi = rgb_hi.filter(ImageFilter.UnsharpMask(radius=1.25, percent=90, threshold=2))
    body = rgb_hi.convert("RGBA")
    a = a.filter(ImageFilter.GaussianBlur(0.35))
    body.putalpha(a)

    gloss = ImageChops.multiply(radial_mask(BODY_OUT, (92, 160), (105, 150), power=2.5), a)
    body = Image.alpha_composite(body, layer_from_mask(gloss, (255, 255, 255), 0.10))
    shade = ImageChops.multiply(radial_mask(BODY_OUT, (176, 365), (165, 220), power=1.8), a)
    body = Image.alpha_composite(body, layer_from_mask(shade, (0, 0, 0), 0.07))

    outer = a.filter(ImageFilter.MaxFilter(11))
    inner = a.filter(ImageFilter.MinFilter(5))
    edge = ImageChops.subtract(outer, inner)
    merged = Image.new("RGBA", BODY_OUT, (0, 0, 0, 0))
    merged = Image.alpha_composite(merged, layer_from_mask(edge, (13, 15, 19), 0.18))
    merged = Image.alpha_composite(merged, body)
    return merged


def build_remastered(source_dir: Path, source_filename: str, alpha_strip: Image.Image, wings_strip: Image.Image) -> Image.Image:
    vertical = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    for frame in (0, 7):
        vertical.alpha_composite(wing_layer(wings_strip, frame), (0, (CANVAS - WING_OUT[1]) // 2))
    body = body_layer(source_dir, source_filename, alpha_strip)
    vertical.alpha_composite(body, ((CANVAS - BODY_OUT[0]) // 2, 0))
    result = vertical.transpose(Image.Transpose.ROTATE_270)
    alpha = result.getchannel("A").point(lambda p: 0 if p < 3 else p)
    result.putalpha(alpha)
    return result


def main():
    ns = args()
    source_dir = Path(ns.source_dir).resolve()
    output_dir = Path(ns.output_dir).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    alpha_strip = Image.open(source_dir / "Alpha-Bugs.gif").convert("L")
    wings_strip = Image.open(source_dir / "Bug-Wings.gif").convert("L")

    for personality, source_filename in MAPPING.items():
        original = build_original(source_dir, source_filename, alpha_strip, wings_strip)
        remastered = build_remastered(source_dir, source_filename, alpha_strip, wings_strip)
        op = output_dir / f"P2_Bug_{personality}_Original.png"
        rp = output_dir / f"P2_Bug_{personality}_Remastered.png"
        original.save(op, optimize=True)
        remastered.save(rp, optimize=True)
        print(op)
        print(rp)


if __name__ == "__main__":
    main()
