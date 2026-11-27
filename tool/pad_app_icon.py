#!/usr/bin/env python3
"""Inset the approved app icon on a transparent canvas for platform icon generation.

This runs in CI after checkout, so the repository's master artwork is never changed.
"""
from pathlib import Path
from PIL import Image
import argparse
import os


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, default=Path("assets/branding/app_icon.png"))
    parser.add_argument("--scale", type=float, default=0.91,
                        help="Artwork scale relative to the original canvas (default: 0.91)")
    args = parser.parse_args()

    if not 0 < args.scale < 1:
        parser.error("--scale must be greater than 0 and less than 1")
    if not args.input.is_file():
        raise SystemExit(f"Icon not found: {args.input}")

    with Image.open(args.input) as source:
        original = source.convert("RGBA")
        width, height = original.size
        new_size = (max(1, round(width * args.scale)),
                    max(1, round(height * args.scale)))
        artwork = original.resize(new_size, Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    position = ((width - new_size[0]) // 2, (height - new_size[1]) // 2)
    canvas.alpha_composite(artwork, dest=position)

    temporary = args.input.with_name(args.input.stem + ".padded.tmp.png")
    canvas.save(temporary, format="PNG", optimize=True)
    os.replace(temporary, args.input)
    print(f"Inset app icon artwork to {args.scale:.0%} within {width}x{height} transparent canvas.")


if __name__ == "__main__":
    main()
