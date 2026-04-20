# Assets

Promotional images for README and Reddit/social posts.

## Files

- `pipeline.svg` — 10-phase pipeline overview (README hero)
- `before-after.svg` — manual vs. automated comparison (Reddit/Twitter)

## Converting SVG → PNG for Reddit

Reddit upload works better with PNG. Convert with any of these:

### Option 1: Browser (easiest)

1. Open the SVG file in Chrome/Safari
2. Zoom to 150-200% (for higher resolution)
3. Screenshot the whole page

### Option 2: macOS `qlmanage`

```bash
qlmanage -t -s 1600 -o . pipeline.svg
# Produces pipeline.svg.png
```

### Option 3: `rsvg-convert` (Homebrew)

```bash
brew install librsvg
rsvg-convert -w 1600 pipeline.svg -o pipeline.png
rsvg-convert -w 1600 before-after.svg -o before-after.png
```

### Option 4: `imagemagick`

```bash
brew install imagemagick
magick -density 300 pipeline.svg pipeline.png
```

## Reddit tips

- Upload as image post (not link), gets better visibility
- Primary image: `before-after.png` (stronger emotional hook)
- Secondary: `pipeline.png` (technical details)
- If Reddit allows a gallery: upload both, before-after first
