"""Draws the Microsoft Store package's tile and logo images.

The Mac icon's plate, without the Mac padding and shadow, at each size and
scale Windows asks for. Needs Pillow; run from the repository root:

    python3 tool/windows/make_msix_assets.py
"""

from pathlib import Path

from PIL import Image, ImageDraw

SOURCE = Path("macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png")
OUT = Path("windows/msix/Assets")
# Where the plate sits in the 1024 px Mac icon, and its corner radius.
PLATE = (100, 100, 924, 924)
RADIUS = 0.225


def plate() -> Image.Image:
    icon = Image.open(SOURCE).convert("RGBA").crop(PLATE)
    size = icon.width * 4
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, size - 1, size - 1), radius=int(size * RADIUS), fill=255
    )
    mask = mask.resize(icon.size, Image.LANCZOS)
    alpha = Image.composite(icon.split()[3], Image.new("L", icon.size, 0), mask)
    icon.putalpha(alpha)
    return icon


def canvas(icon: Image.Image, width: int, height: int, fill: float) -> Image.Image:
    """[icon] centred on a clear [width] x [height] image, [fill] of its height."""
    side = round(min(width, height) * fill)
    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    image.alpha_composite(
        icon.resize((side, side), Image.LANCZOS),
        ((width - side) // 2, (height - side) // 2),
    )
    return image


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for old in OUT.glob("*.png"):
        old.unlink()
    icon = plate()
    for scale in (100, 125, 150, 200, 400):
        f = scale / 100
        side = round(44 * f)
        canvas(icon, side, side, 0.92).save(OUT / f"Square44x44Logo.scale-{scale}.png")
        side = round(150 * f)
        canvas(icon, side, side, 0.66).save(OUT / f"Square150x150Logo.scale-{scale}.png")
        canvas(icon, round(310 * f), round(150 * f), 0.66).save(
            OUT / f"Wide310x150Logo.scale-{scale}.png"
        )
        side = round(50 * f)
        canvas(icon, side, side, 1).save(OUT / f"StoreLogo.scale-{scale}.png")
    # The taskbar and Start list pick these by pixel size.
    for size in (16, 20, 24, 30, 32, 36, 40, 48, 60, 64, 72, 80, 96, 256):
        image = canvas(icon, size, size, 1 if size < 32 else 0.94)
        image.save(OUT / f"Square44x44Logo.targetsize-{size}.png")
        image.save(OUT / f"Square44x44Logo.altform-unplated_targetsize-{size}.png")
        image.save(OUT / f"Square44x44Logo.altform-lightunplated_targetsize-{size}.png")


if __name__ == "__main__":
    main()
