#!/usr/bin/env python3
import os
import re
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except Exception as e:
    raise SystemExit("Pillow is required. Install with: python3 -m pip install --user pillow")


REPO_ROOT = Path(__file__).resolve().parents[1]
GO_CARD_FILE = REPO_ROOT / "backend/internal/repository/card_repository.go"
ART_DIR = REPO_ROOT / "assets/cards/art"
OVERLAYS_DIR = REPO_ROOT / "assets/cards/overlays"
BACKS_DIR = REPO_ROOT / "assets/cards/backs"
FRAMES_DIR = REPO_ROOT / "assets/cards/frames"
PLACEHOLDER_PATH = REPO_ROOT / "assets/images/placeholder_card_art.jpg"


def parse_cards_from_go() -> list[dict]:
    text = GO_CARD_FILE.read_text(encoding="utf-8")
    # Matches blocks like:
    # {
    #   ID:          "red_pawn_goblin",
    #   ...
    #   Color:       domain.CardColorRed,
    # }
    cards: list[dict] = []
    block_pattern = re.compile(r"\{[^\{\}]*?ID:\s*\"([^\"]+)\"[^\{\}]*?Color:\s*domain\.CardColor(\w+)[^\{\}]*?\}", re.DOTALL)
    for match in block_pattern.finditer(text):
        card_id = match.group(1)
        color = match.group(2).lower()
        cards.append({"id": card_id, "color": color})
    # Ensure unique by id
    unique = {}
    for c in cards:
        unique[c["id"]] = c
    return list(unique.values())


COLOR_MAP: dict[str, tuple[tuple[int, int, int], tuple[int, int, int]]] = {
    "red": ((211, 47, 47), (183, 28, 28)),
    "orange": ((251, 140, 0), (239, 108, 0)),
    "yellow": ((251, 192, 45), (245, 127, 23)),
    "green": ((67, 160, 71), (46, 125, 50)),
    "blue": ((30, 136, 229), (21, 101, 192)),
    "purple": ((142, 36, 170), (106, 27, 154)),
}


def draw_vertical_gradient(size: tuple[int, int], top_rgb: tuple[int, int, int], bottom_rgb: tuple[int, int, int]) -> Image.Image:
    width, height = size
    base = Image.new("RGB", (width, height), top_rgb)
    top = Image.new("RGB", (width, height), top_rgb)
    bottom = Image.new("RGB", (width, height), bottom_rgb)
    mask = Image.linear_gradient("L").resize((width, height))
    return Image.composite(bottom, top, mask)


def add_label(img: Image.Image, text: str) -> None:
    draw = ImageDraw.Draw(img)
    # Try to find a default font; fallback to simple bitmap font
    try:
        font = ImageFont.truetype("DejaVuSans.ttf", max(12, img.width // 18))
    except Exception:
        font = ImageFont.load_default()
    text = text.replace("_", " ")
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    padding = img.width // 20
    x = padding
    y = img.height - th - padding
    # Shadow
    draw.text((x+2, y+2), text, font=font, fill=(0, 0, 0, 160))
    # Text
    draw.text((x, y), text, font=font, fill=(255, 255, 255))


def ensure_dirs():
    ART_DIR.mkdir(parents=True, exist_ok=True)
    OVERLAYS_DIR.mkdir(parents=True, exist_ok=True)
    BACKS_DIR.mkdir(parents=True, exist_ok=True)
    FRAMES_DIR.mkdir(parents=True, exist_ok=True)


def save_webp(img: Image.Image, path: Path, quality: int = 88):
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, format="WEBP", quality=quality, method=6)


def generate_card_art(card_id: str, color: str):
    gradients = COLOR_MAP.get(color, COLOR_MAP["red"])  # default to red if unknown
    sizes = {
        "low": (140, 200),
        "medium": (280, 400),
        "high": (560, 800),
    }
    for res, size in sizes.items():
        canvas = draw_vertical_gradient(size, gradients[0], gradients[1])
        add_label(canvas, card_id)
        out_path = ART_DIR / f"{card_id}_standard_{res}.webp"
        save_webp(canvas, out_path)


def generate_overlays():
    # Holographic pattern placeholder: diagonal rainbow stripes with transparency
    w, h = 280, 400
    base = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(base)
    colors = [(255, 0, 0, 60), (255, 165, 0, 60), (255, 255, 0, 60), (0, 128, 0, 60), (0, 0, 255, 60), (75, 0, 130, 60), (238, 130, 238, 60)]
    step = 20
    for i in range(-h, w + h, step):
        c = colors[(i // step) % len(colors)]
        draw.polygon([(i, 0), (i + step, 0), (i - h + step, h), (i - h, h)], fill=c)
    save_webp(base.convert("RGB"), OVERLAYS_DIR / "holographic_pattern.webp")

    # Foil etched texture placeholder: grayscale crisscross pattern
    size = 512
    tex = Image.new("L", (size, size), 128)
    draw = ImageDraw.Draw(tex)
    for i in range(0, size, 8):
        draw.line((i, 0, 0, i), fill=170, width=1)
        draw.line((size, i, i, size), fill=85, width=1)
    save_webp(tex.convert("RGB"), OVERLAYS_DIR / "foil_etched_texture.webp")

    # Premium shine placeholder: radial gradient
    shine = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    dr = ImageDraw.Draw(shine)
    cx, cy = int(w*0.25), int(h*0.25)
    max_r = int((w**2 + h**2) ** 0.5 / 2)
    for r in range(max_r, 0, -8):
        alpha = max(0, int(80 * (1 - r / max_r)))
        dr.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(255, 255, 255, alpha))
    save_webp(shine.convert("RGB"), OVERLAYS_DIR / "premium_shine.webp")

    # Promo stamp placeholder: gold circle with star
    stamp = Image.new("RGBA", (80, 80), (0, 0, 0, 0))
    d = ImageDraw.Draw(stamp)
    d.ellipse((0, 0, 80, 80), fill=(255, 215, 0, 255), outline=(230, 180, 0, 255), width=3)
    # simple star
    star_points = [(40, 12), (47, 32), (68, 32), (51, 44), (58, 64), (40, 52), (22, 64), (29, 44), (12, 32), (33, 32)]
    d.polygon(star_points, fill=(255, 255, 255, 220))
    stamp.save(OVERLAYS_DIR / "promo_stamp.png")


def generate_back():
    w, h = 280, 400
    back = draw_vertical_gradient((w, h), (40, 40, 40), (10, 10, 10))
    d = ImageDraw.Draw(back)
    # border pattern
    d.rectangle((10, 10, w-10, h-10), outline=(200, 200, 200), width=2)
    d.rectangle((18, 18, w-18, h-18), outline=(120, 120, 120), width=2)
    # center shield
    d.ellipse((w//2-50, h//2-50, w//2+50, h//2+50), outline=(220, 220, 220), width=4)
    save_webp(back, BACKS_DIR / "default_back.webp")


def generate_placeholder_jpg():
    if PLACEHOLDER_PATH.exists():
        return
    img = draw_vertical_gradient((560, 800), (90, 90, 90), (30, 30, 30))
    add_label(img, "Placeholder Art")
    PLACEHOLDER_PATH.parent.mkdir(parents=True, exist_ok=True)
    img.save(PLACEHOLDER_PATH, format="JPEG", quality=88)


def main():
    ensure_dirs()
    cards = parse_cards_from_go()
    if not cards:
        raise SystemExit("No cards parsed from repository. Aborting.")
    for c in cards:
        generate_card_art(c["id"], c["color"])
    generate_overlays()
    generate_back()
    generate_placeholder_jpg()
    print(f"Generated art for {len(cards)} cards.")


if __name__ == "__main__":
    main()

