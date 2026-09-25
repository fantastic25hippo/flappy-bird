# Confirmed Bugs & Resolution Log

This document tracks the diagnosis, root causes, and resolutions for four confirmed issues in `./main.bend`. All four bugs have been resolved, verified against `LAWS.bend` (L6–L14), and validated via `bend main.bend --check-only` and `bend main.bend -o flappy`.

---

### Bug 1: Rain in Fair Weather (Fixed)

- **Description:**
  Vertical rain streaks were rendering during fair weather when no storm was active. Rain streaks only survived in regions where the renderer rasterizes pixel-by-pixel (title/SPACE box, ground strip, cloud boxes, sun box), or caused large sky quadtree tiles to render pale when a top-left sample pixel intersected an active rain streak.
- **Root Cause & Sites:**
  1. `Game.color` (~line 931): `Game.pick(Game.rain(x, y, rx0, rx1, wt), RAIN_TINT(), ...)` evaluated rain pixels without gating on `Game.storm(cx, dx, ex, fx)`.
  2. `Game.rain_lo` / `Game.rain_hi` (~lines 798–812): Only tested conditions `c1`, `c2`, and `c3`. If none held, they fell through to `Game.min3(dx, ex, fx)` / `Game.max3(dx, ex, fx)` unconditionally rather than checking `c4` or returning an empty range, leaving a live rain x-interval active at all times.
  3. `Game.flat` (~line 1011): Correctly gated the rain bounding box on `storm`, which accounted for rain only appearing in non-flat subdivided blocks during fair weather.
- **Fix Applied:**
  - Gated the rain streak color picker in `Game.color` with `(storm && Game.rain(x, y, rx0, rx1, wt) : U32)`. When `storm` is false, no rain pixels are produced.
  - Added condition `c4 = (Game.span3(dx, ex, fx) <= STORM_SPAN() : U32)` in `Game.rain_lo` and `Game.rain_hi`, returning `0` if no triple satisfies the storm threshold.
- **Pointers:**
  - `main.bend`: `Game.rain_lo`, `Game.rain_hi`, and `Game.color`.
- **Status:** **FIXED**.

---

### Bug 2: Incorrect Color Format (0xRRGGBBAA vs 0x00RRGGBB) (Fixed)

- **Description:**
  All named color constants and inline color literals were packed in `0xRRGGBBAA` format with alpha `0xFF`. The Linux X11 window renderer reads 32-bit pixel values in `0x00RRGGBB` format. This byte offset shifted all color channels left by one byte: red was interpreted as green, green as blue, and the alpha channel (`0xFF`) saturated the blue component. Yellows appeared blue/magenta (e.g. sun core and bird body), oranges appeared purple, and greens appeared cyan.
- **Root Cause & Sites:**
  - Atmosphere palette: `SKY_TOP`, `SKY_MID`, `SKY_PALE`, `STORM_TOP`, `STORM_MID`, `STORM_PALE`, `HILLS_TINT`, `MOUNT_TINT`, `SEA_BLUE`, `SEA_FOAM`, `FIELD_GREEN`, `GRASS_GREEN`, `DIRT_BROWN`, `CLOUD_WHITE`, `BIRD_TINT`, `RAIN_TINT` (~lines 670–692).
  - Pillar colors: `COLOR_0` through `COLOR_4` (~lines 828–836).
  - HUD and Panel colors: `HUD_FACE`, `HUD_DIGIT`, `PANEL_BLUE`, `PANEL_GREEN`, `PANEL_RED`, `PANEL_DARK` (~lines 847–857).
  - Inline bird body (`4208740095`), beak (`4034404607`), wing (`4294967295`), and UI text/digit literals in `Game.color` (~lines 902–910).
- **Fix Applied:**
  - Converted every color literal using unsigned right shift 8 (`val >> 8`), converting `0xRRGGBBAA` to `0x00RRGGBB`.
  - Represented all converted values using decimal numeric literals as required by Bend (e.g. `COLOR_4` yellow core is `15257664` / `0x00E8D040`, `COLOR_1` orange-red rays is `14703136` / `0x00E05A20`, bird body is `16440390` / `0x00FADC46`, beak is `15759392` / `0x00F07820`).
- **Pointers:**
  - `main.bend`: `SKY_*`, `STORM_*`, `COLOR_0`..`COLOR_4`, `HUD_*`, `PANEL_*`, and inline literals in `Game.color`.
- **Status:** **FIXED**.

---

### Bug 3: Storm Weather Never Triggered (Fixed)

- **Description:**
  The storm weather event and localized rain shower never triggered during game sessions.
- **Root Cause & Sites:**
  - `Game.storm` (~lines 792–796) evaluates whether any triple among the four clouds $(cx, dx, ex, fx)$ clusters within `STORM_SPAN = 160`.
  - In `Game.init` (~lines 92–95), clouds were initialized at $cx = 160, dx = 400, ex = 280, fx = 520$.
  - Same-speed pairs maintained fixed distances: $dx - cx = 240$ px and $fx - ex = 240$ px. Because any selection of 3 clouds from a set of 4 must contain at least two clouds of the same speed, every triple's span was mathematically bounded below by $240 > 160$. Wrap offsets only increased cloud separation.
- **Fix Applied:**
  - Updated `Game.init` cloud coordinates to $cx = 120, dx = 220, ex = 400, fx = 500$.
  - Same-speed pairs now start 100 px apart ($< 160$ px).
  - At $t = 0$, near clouds ($[120, 220]$) and far clouds ($[400, 500]$) are separated by 180 px, guaranteeing fair weather on the title screen.
  - As clouds drift with parallax speeds (near at 2 px/tick, far at 1 px/tick), near clouds overtake far clouds, allowing triples to bunch within $\le 160$ px to trigger storms and showers periodically.
- **Pointers:**
  - `main.bend`: `Game.init` and doc comment.
- **Status:** **FIXED**.

---

### Bug 4: Rain Resembles a Solid Wall (Fixed)

- **Description:**
  When a storm triggered, the localized rain shower rendered as a dense, solid wall of pixels rather than sparse falling streaks. This obscured clouds and background elements because rain renders in front of clouds starting at $y = 0$.
- **Root Cause & Sites:**
  - `Game.rain` (~lines 823–828):
    1. **Excessive density:** 3 out of every 5 columns were designated as rain lanes (`lane < 1` and `1 < lane && lane < 4`), and each lane was lit for 16 out of every 24 rows (`fall < 16`), filling ~40% of all pixels in the shower band.
    2. **Hard rectangular edges:** Flat cutoff at the horizontal boundaries (`x0 <= x && x < x1`) with no edge tapering or thinning towards the sides.
    3. **Full vertical span ($y = 0..480$):** Starting at $y = 0$ in front of clouds (`Game.color` evaluates rain before clouds, as required by L14/AGENTS.md). Because the rain was excessively dense, clouds were obscured rather than showing through.
- **Fix Applied:**
  - Kept rain and thinned it under existing L13/L14 rules without changing the $y \in [0, 480]$ range or the draw order in front of clouds:
    - Thinned interior streaks to 1px wide lanes spaced 12px apart (`U32.mod(u, 12) < 1`).
    - Shortened dash length from 16/24 rows to 6/24 rows (`fall < 6`), letting sky, clouds, and landscape show through clearly.
    - Added a soft 2-tier side fade in the outer 32px of each edge: widened streak period to 24px (`U32.mod(u, 24) < 1`) and shortened dashes to 3–4px (`edge_dist < 16 -> 3`, `edge_dist < 32 -> 4`) to eliminate hard rectangular borders.
    - Preserved the mild slant `U32.div(u, 4)` and $wt$-driven fall/freezing.
- **Pointers:**
  - `main.bend`: `Game.rain` (lines ~822–836).
- **Status:** **FIXED**.

