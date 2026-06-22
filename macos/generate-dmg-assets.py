#!/usr/bin/env python3
from pathlib import Path
import subprocess
import math

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
ASSETS = ROOT / "assets"
ASSETS.mkdir(parents=True, exist_ok=True)

BG_PATH = ASSETS / "dmg-background.png"
ICON_PNG_PATH = ASSETS / "dmg-volume-icon.png"
ICON_ICNS_PATH = ASSETS / "dmg-volume-icon.icns"
COMPANY_LOGO_PATH = ASSETS / "WhatsApp Image 2026-05-30 at 09.04.04.jpeg"

# Brand palette (JORNALPRO)
NAVY = (35, 49, 78)          # Deep professional blue
TEAL = (95, 150, 130)         # Main agricultural green/teal
TEAL_LIGHT = (138, 184, 168)   # Light accent teal
TEAL_VERY_LIGHT = (220, 235, 230) # Soft card border/fill
GRAY_TEXT = (72, 84, 102)     # Readable body text
GRAY_LIGHT = (140, 150, 165)   # Subtitles
WHITE = (255, 255, 255)

# Agricultural landscape colors
SKY_TOP = (235, 244, 248)     # Soft pastel sky blue
SKY_BOTTOM = (255, 255, 255)  # Fades to pure white
HILL_BACK = (175, 205, 192)   # Distant soft green hill
HILL_MID = (135, 175, 158)    # Mid-ground green hill
HILL_FRONT = (95, 150, 130)   # Foreground rich green hill
GOLD_WHEAT = (225, 185, 100)  # Golden accent for wheat stalks


def load_font(size: int, bold: bool = False):
    candidates = [
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/SFNSDisplay.ttf",
        "/System/Library/Fonts/Supplemental/Arial.ttf",
    ]
    if bold:
        candidates = [
            "/System/Library/Fonts/SFNSDisplay-Bold.otf",
            "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        ] + candidates

    for candidate in candidates:
        p = Path(candidate)
        if p.exists():
            try:
                return ImageFont.truetype(str(p), size=size)
            except Exception:
                pass
    return ImageFont.load_default()


def crop_logo_whitespace(img: Image.Image) -> Image.Image:
    rgb = img.convert("RGB")
    px = rgb.load()
    w, h = rgb.size
    min_x, min_y, max_x, max_y = w, h, 0, 0
    found = False

    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            if r < 245 or g < 245 or b < 245:
                found = True
                min_x = min(min_x, x)
                min_y = min(min_y, y)
                max_x = max(max_x, x)
                max_y = max(max_y, y)

    if not found:
        return img

    pad = 8
    min_x = max(0, min_x - pad)
    min_y = max(0, min_y - pad)
    max_x = min(w - 1, max_x + pad)
    max_y = min(h - 1, max_y + pad)
    return img.crop((min_x, min_y, max_x + 1, max_y + 1))


def draw_cloud(draw, cx, cy, scale=1.0):
    s = scale
    c1 = (255, 255, 255, 180)
    c2 = (255, 255, 255, 230)
    
    # Elegant fluffy vector cloud
    draw.ellipse((cx - 35 * s, cy - 10 * s, cx + 15 * s, cy + 20 * s), fill=c1)
    draw.ellipse((cx - 15 * s, cy - 22 * s, cx + 25 * s, cy + 15 * s), fill=c2)
    draw.ellipse((cx + 5 * s, cy - 15 * s, cx + 45 * s, cy + 15 * s), fill=c1)
    draw.ellipse((cx - 5 * s, cy - 5 * s, cx + 35 * s, cy + 20 * s), fill=c2)


def get_hill_points(y_base, amplitude, frequency, phase, w=500, h=500):
    points = []
    for x in range(0, w + 1, 4):
        y = y_base + amplitude * math.sin(x * frequency + phase)
        points.append((x, y))
    points.append((w, h))
    points.append((0, h))
    return points


def draw_wheat_stalk(draw, x, y_base, height, color):
    # Draw curved stem
    points = []
    for i in range(height + 1):
        t = i / height
        # Slight curve to the right or left depending on x position
        offset_x = 8 * (t ** 2) if x < 250 else -8 * (t ** 2)
        points.append((x + offset_x, y_base - i))
    
    draw.line(points, fill=color, width=2)
    
    # Draw grains along the top half of the stem
    top_x, top_y = points[-1]
    grain_count = 6
    for i in range(grain_count):
        idx = int(len(points) - 1 - (i * (len(points) // 2) // grain_count))
        if idx < 0:
            idx = 0
        gx, gy = points[idx]
        
        # Draw left grain
        draw.ellipse((gx - 6, gy - 3, gx - 1, gy + 1), fill=color)
        # Draw right grain
        draw.ellipse((gx + 1, gy - 3, gx + 6, gy + 1), fill=color)
        
    # Top grain tip
    draw.ellipse((top_x - 2, top_y - 5, top_x + 2, top_y), fill=color)


def draw_step(draw, x, y, number, text, font_body):
    circle_r = 11
    cx = x + 15
    cy = y + 10
    # Draw step number circle
    draw.ellipse((cx - circle_r, cy - circle_r, cx + circle_r, cy + circle_r), fill=TEAL)
    
    num_font = load_font(11, bold=True)
    bbox = draw.textbbox((0, 0), str(number), font=num_font)
    nw = bbox[2] - bbox[0]
    nh = bbox[3] - bbox[1]
    draw.text((cx - nw // 2, cy - nh // 2 - 1), str(number), font=num_font, fill=WHITE)
    
    # Draw step text
    draw.text((cx + 18, y + 2), text, font=font_body, fill=GRAY_TEXT)


def build_background():
    w, h = 500, 500
    img = Image.new("RGB", (w, h), WHITE)
    draw = ImageDraw.Draw(img, "RGBA")

    # 1. Sky Gradient (top to middle)
    for y in range(0, 300):
        t = y / 300
        r = int(SKY_TOP[0] + (SKY_BOTTOM[0] - SKY_TOP[0]) * t)
        g = int(SKY_TOP[1] + (SKY_BOTTOM[1] - SKY_TOP[1]) * t)
        b = int(SKY_TOP[2] + (SKY_BOTTOM[2] - SKY_TOP[2]) * t)
        draw.line([(0, y), (w, y)], fill=(r, g, b))

    # 2. Fluffy Clouds
    draw_cloud(draw, 65, 45, 0.8)
    draw_cloud(draw, 180, 35, 1.1)
    draw_cloud(draw, 410, 48, 0.9)

    # 3. Rolling Hills (Campo Agrícola) at the bottom
    # Back hill
    back_hill = get_hill_points(y_base=410, amplitude=12, frequency=0.012, phase=0.5)
    draw.polygon(back_hill, fill=(*HILL_BACK, 255))
    
    # Middle hill
    mid_hill = get_hill_points(y_base=435, amplitude=10, frequency=0.018, phase=2.5)
    draw.polygon(mid_hill, fill=(*HILL_MID, 255))
    
    # Front hill
    front_hill = get_hill_points(y_base=455, amplitude=8, frequency=0.022, phase=4.8)
    draw.polygon(front_hill, fill=(*HILL_FRONT, 255))

    # Cultivation rows (perspective lines on the front hill)
    # Draw beautiful perspective lines to make it look like a cultivated field
    for i in range(-5, 6):
        start_x = 250 + i * 45
        end_x = 250 + i * 90
        draw.line([(start_x, 455), (end_x, 500)], fill=(*TEAL_LIGHT, 60), width=3)

    # 4. Golden Wheat Stalks framing the sides
    # Left side stalks
    draw_wheat_stalk(draw, 18, 460, 55, GOLD_WHEAT)
    draw_wheat_stalk(draw, 34, 470, 45, GOLD_WHEAT)
    # Right side stalks
    draw_wheat_stalk(draw, 465, 475, 50, GOLD_WHEAT)
    draw_wheat_stalk(draw, 482, 465, 60, GOLD_WHEAT)

    # 5. Header Area (Company Logo & Title)
    if COMPANY_LOGO_PATH.exists():
        logo = Image.open(COMPANY_LOGO_PATH).convert("RGBA")
        logo = crop_logo_whitespace(logo)
        target_w = 170
        ratio = target_w / logo.width
        target_h = max(1, int(logo.height * ratio))
        logo = logo.resize((target_w, target_h), Image.Resampling.LANCZOS)
        x = (w - target_w) // 2
        y = 24
        img.paste(logo, (x, y), logo)

    subtitle_font = load_font(10, bold=False)
    sub = "NFC Service  ·  Instalador macOS"
    bbox = draw.textbbox((0, 0), sub, font=subtitle_font)
    sw = bbox[2] - bbox[0]
    draw.text(((w - sw) // 2, 114), sub, font=subtitle_font, fill=GRAY_LIGHT)

    # Elegant separator line under header
    draw.line([(40, 132), (460, 132)], fill=(*TEAL_LIGHT, 120), width=1)

    # ── SIDE-BY-SIDE LAYOUT (y = 150 to 370) ──
    # Left side: Professional Instruction Card
    card_left, card_top = 24, 155
    card_right, card_bottom = 265, 365
    
    # Semi-transparent white card with a soft shadow and teal border
    # Soft shadow
    draw.rounded_rectangle(
        (card_left + 2, card_top + 2, card_right + 2, card_bottom + 2),
        radius=12,
        fill=(0, 0, 0, 15),
    )
    # Main card
    draw.rounded_rectangle(
        (card_left, card_top, card_right, card_bottom),
        radius=12,
        fill=(255, 255, 255, 245),
        outline=(*TEAL_LIGHT, 200),
        width=1,
    )

    # Card header
    title_font = load_font(11, bold=True)
    body_font = load_font(11, bold=False)
    
    draw.text((38, card_top + 12), "PASOS DE INSTALACIÓN", font=title_font, fill=NAVY)
    draw.line([(38, card_top + 28), (card_right - 14, card_top + 28)], fill=(*TEAL_LIGHT, 80), width=1)

    # Steps inside the card
    draw_step(draw, card_left + 4, card_top + 38, 1, "Doble clic en INSTALAR", body_font)
    draw_step(draw, card_left + 4, card_top + 84, 2, "Autoriza los permisos\ncuando se soliciten", body_font)
    draw_step(draw, card_left + 4, card_top + 142, 3, "Espera la confirmación\nen la Terminal", body_font)

    # Right side: Elegant Target Zone for the Icon
    # Center of target zone: x = 370, y = 240
    target_x, target_y = 370, 240
    
    # Draw a soft glowing background circle for the icon
    for r in range(54, 30, -6):
        alpha = int(15 + (54 - r) * 2)
        draw.ellipse((target_x - r, target_y - r, target_x + r, target_y + r), fill=(255, 255, 255, alpha))
        
    # Elegant dashed/dotted target circle
    draw.ellipse(
        (target_x - 46, target_y - 46, target_x + 46, target_y + 46),
        outline=(*TEAL, 120),
        width=1,
    )
    
    # Draw subtle arrow and label above the target zone
    label_font = load_font(10, bold=True)
    label_text = "Doble clic para instalar"
    l_bbox = draw.textbbox((0, 0), label_text, font=label_font)
    l_w = l_bbox[2] - l_bbox[0]
    draw.text((target_x - l_w // 2, target_y - 68), label_text, font=label_font, fill=TEAL)
    
    # Small downward triangle arrow
    draw.polygon(
        [(target_x - 5, target_y - 52), (target_x + 5, target_y - 52), (target_x, target_y - 47)],
        fill=(*TEAL, 200)
    )

    img.save(BG_PATH, "PNG", optimize=True)


def build_icon_png():
    size = 1024
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")

    draw.rounded_rectangle(
        (72, 72, 952, 952),
        radius=220,
        fill=(255, 255, 255, 255),
        outline=(TEAL_LIGHT[0], TEAL_LIGHT[1], TEAL_LIGHT[2], 255),
        width=12,
    )
    draw.ellipse((130, 130, 760, 760), fill=(TEAL_LIGHT[0], TEAL_LIGHT[1], TEAL_LIGHT[2], 40))

    if COMPANY_LOGO_PATH.exists():
        logo = Image.open(COMPANY_LOGO_PATH).convert("RGBA")
        logo = crop_logo_whitespace(logo)
        target_w = 580
        ratio = target_w / logo.width
        target_h = max(1, int(logo.height * ratio))
        logo = logo.resize((target_w, target_h), Image.Resampling.LANCZOS)
        x = (size - target_w) // 2
        y = (size - target_h) // 2
        img.paste(logo, (x, y), logo)

    img.save(ICON_PNG_PATH, "PNG", optimize=True)


def build_icns():
    iconset = ASSETS / "dmg-volume-icon.iconset"
    if iconset.exists():
        for p in iconset.iterdir():
            p.unlink()
        iconset.rmdir()
    iconset.mkdir(parents=True, exist_ok=True)

    src = Image.open(ICON_PNG_PATH).convert("RGBA")
    sizes = {
        "icon_16x16.png": 16,
        "icon_16x16@2x.png": 32,
        "icon_32x32.png": 32,
        "icon_32x32@2x.png": 64,
        "icon_128x128.png": 128,
        "icon_128x128@2x.png": 256,
        "icon_256x256.png": 256,
        "icon_256x256@2x.png": 512,
        "icon_512x512.png": 512,
        "icon_512x512@2x.png": 1024,
    }
    for name, px in sizes.items():
        src.resize((px, px), Image.Resampling.LANCZOS).save(iconset / name, "PNG")

    subprocess.run(["iconutil", "-c", "icns", str(iconset), "-o", str(ICON_ICNS_PATH)], check=True)


def main():
    build_background()
    build_icon_png()
    build_icns()
    print(f"Generated: {BG_PATH}")
    print(f"Generated: {ICON_PNG_PATH}")
    print(f"Generated: {ICON_ICNS_PATH}")


if __name__ == "__main__":
    main()
