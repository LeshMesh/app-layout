#!/usr/bin/env python3
"""Regenerate the original geometric icon. Optional art tool: pip install Pillow."""
import json
from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parent.parent / "Resources/Assets.xcassets"
destination = root / "AppIcon.appiconset"
destination.mkdir(parents=True, exist_ok=True)
scale = 2
image = Image.new("RGBA", (1024 * scale, 1024 * scale))
draw = ImageDraw.Draw(image)

def box(rect, radius, fill):
    draw.rounded_rectangle(tuple(round(x * scale) for x in rect), radius=radius * scale, fill=fill)

box((72, 72, 952, 952), 202, "#175CBA")
box((185, 356, 839, 746), 66, "#113E81")
box((185, 338, 839, 716), 66, "#F1F6FF")
for row in range(3):
    for column in range(7):
        x = 230 + column * 82
        y = 384 + row * 76
        box((x, y, x + 64, y + 53), 12, "#175CBA")
box((348, 612, 676, 663), 14, "#175CBA")
# Two opposing arrows: a layout follows a change of application.
draw.line([(325 * scale, 236 * scale), (699 * scale, 236 * scale)], fill="#FFFFFF", width=22 * scale)
draw.polygon([(661 * scale, 197 * scale), (711 * scale, 236 * scale), (661 * scale, 275 * scale)], fill="#FFFFFF")
draw.line([(325 * scale, 809 * scale), (699 * scale, 809 * scale)], fill="#C2DDFF", width=22 * scale)
draw.polygon([(363 * scale, 770 * scale), (313 * scale, 809 * scale), (363 * scale, 848 * scale)], fill="#C2DDFF")

images = []
for points in (16, 32, 128, 256, 512):
    for factor in (1, 2):
        pixels = points * factor
        name = f"icon_{points}x{points}@{factor}x.png"
        image.resize((pixels, pixels), Image.Resampling.LANCZOS).save(destination / name)
        images.append({"idiom": "mac", "size": f"{points}x{points}", "scale": f"{factor}x", "filename": name})
(destination / "Contents.json").write_text(json.dumps({"images": images, "info": {"author": "xcode", "version": 1}}, indent=2) + "\n")
(root / "Contents.json").write_text('{"info":{"author":"xcode","version":1}}\n')
print("Generated app icon assets")
