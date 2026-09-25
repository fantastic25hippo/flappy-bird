# Flappy Bird Rules & Specifications

This document defines the player mechanics, game laws, and architectural rules for the Bend Flappy Bird implementation. It reflects the intended and verified behavior adhering to `LAWS.bend` (L6–L14).

---

## 1. Controls & Lifecycle

The game operates across three distinct modes: **Ready** (`mode = 0`), **Playing** (`mode = 1`), and **Dead** (`mode = 2`).

- **Space Bar (Keycode 32):**
  - **Ready Screen:** Starts the game (`mode 0 -> 1`) and executes an initial flap.
  - **Playing:** Sets upward vertical speed magnitude to `FLAP` (rising-edge only; holding Space does not flap every tick).
  - **Dead Screen:** Ignored. Space **never** restarts the game after death.
- **R Key (Keycodes 114, 82):**
  - **Dead Screen:** Restarts the game on rising edge (`mode 2 -> 0/1` via `Game.restart`), restoring initial state while rekeying inputs so a held Space cannot trigger an accidental flap.
  - **Ready & Playing:** Only tracks key state without triggering actions.
- **Escape Key (Keycode 27) / Window Close:**
  - Terminates the application immediately from any state (`App.run` tick returns `None`).

---

## 2. Physics & Motion Constants

- **Gravity (`GRAVITY = 1`):** Applied every tick while playing, accelerating downward speed by 1 unit/tick.
- **Flap (`FLAP = 8`):** Rising-edge Space instantly sets upward speed to 8 units/tick.
- **Terminal Fall Speed (`MAX_FALL = 12`):** Downward speed clamps to a maximum of 12 units/tick.
- **Coordinate Space:** Screen dimensions are 512x512. $y$ grows downward ($y = 0$ is ceiling, $y = 512$ is bottom).
- **State Invariance:** Ready and dead birds freeze vertical motion and physics updates.

---

## 3. Bird Geometry & Collision

- **Bird Rendering:** Rendered at $x = 128$ (`BIRD_X`) as three axis-aligned rectangles:
  - Body: 24x16 (`BODY_W = 24`, `BODY_H = 16`) at `(128, by)`.
  - Beak: 8x6 at `(152, by + 6)`.
  - Wing: 10x6 at `(134, by + 8)`.
- **Hitbox (`HIT_PAD = 2`):**
  - Collision tests use **only** the body rectangle inset by 2 pixels on each side (effective hitbox: $[130, 150] \times [by + 2, by + 14]$).
  - Beak and wing are purely visual and do not have hitboxes.
- **Boundaries & Hazards:**
  - **Floor Collision:** Contact with ground line $y \ge 496$ triggers immediate death.
  - **Ceiling Collision:** $y \le 0$ triggers death.
  - **Pipe Collision:** Collision with any active pipe shaft or cap marks the bird dead.
- **Decorative Elements (Zero Collision):**
  - Sky bands, sun, mountains, distant hills, sea ($y = 480..496$), foam line ($y = 480..484$), ground field patches, drifting clouds, distant birds, and rain shower streaks do **not** have hitboxes and never collide with the bird.

---

## 4. Pipes, Wrapping & Scoring

- **Two Pipe Pairs:** Exactly two pairs (A and B) active at any time.
- **Shaft & Cap Geometry:**
  - Shaft width: `PIPE_W = 40`.
  - Cap width: `PIPE_CAP_W = 56` (extends 8px on each side of shaft).
  - Cap height: `PIPE_CAP_H = 16`.
- **Spacing:** Horizontal right-edge separation `PIPE_SPACING = 280`. Initial positions: Pair A `px = 552`, Pair B `qx = 832`.
- **Passable Gap:** Opening spans from gap top `gy` to `gy + gap_height`.
- **Pipe Collision Model:** Union of four axis-aligned bounding boxes per pair:
  1. Top shaft: $[px - 40, px] \times [0, gy - 16]$
  2. Bottom shaft: $[px - 40, px] \times [gy + gap, 496]$
  3. Top cap: $[px - 48, px + 8] \times [gy - 16, gy]$
  4. Bottom cap: $[px - 48, px + 8] \times [gy + gap, gy + gap + 16]$
  Overhang regions outside caps are passable.
- **Wrap & Remixing:**
  - When a pair's right edge scrolls off-screen ($edge < spd$), it wraps to `sibling + 280` (always $\ge 560$, landing off-screen).
  - The deterministic LCG PRNG (`Game.mix`) advances: $seed_{next} = (seed \times 1664525 + 1013904223) \pmod{2^{32}}$.
  - The wrapped pair remixes its gap top $gy$, gap type, and pillar color index (cycling through 5 distinct colors).
- **Scoring:**
  - Each pipe pair contains a latch (`scored`, `qscored`).
  - Crossing $x = 128$ (`BIRD_X`) latches that pair and increments the score by 1.
  - HUD displays `score % 1000` via compact 3-digit 7-segment display at $(220, 8)$ with contrasting frame and face.

---

## 5. Difficulty Staging (4 Stages)

Difficulty dynamically scales with score across 4 stages:

| Stage | Score Range | Scroll Speed (`spd`) | Gap Type | Gap Height (`GAP_H`) | Vertical Gap Variation |
|:-----:|:-----------:|:--------------------:|:--------:|:--------------------:|:-----------------------|
| **0** | $0 \le score < 8$ | 2 px/tick | Type 0 | 128 px | Stays within 48 px of sibling $gy$ |
| **1** | $8 \le score < 16$ | 3 px/tick | Type 0 | 128 px | Stays within 96 px of sibling $gy$ |
| **2** | $16 \le score < 24$ | 4 px/tick | Type 1 | 112 px | Full mixer range $[64, 304]$ |
| **3** | $score \ge 24$ | 4 px/tick | Type 1 or 2 | 112 px or 96 px (`nseed & 1`) | Full mixer range $[64, 304]$ |

- Gap top $gy$ is strictly clamped to $[\text{GAP\_TOP\_MIN}=64, \text{GAP\_TOP\_MAX}=304]$, with $gy + gap \le 480$.

---

## 6. Atmosphere & Weather System

- **Parallax Clouds:**
  - Four clouds with right edges $cx, dx$ (near layer, speed 2 px/tick) and $ex, fx$ (far layer, speed 1 px/tick), width 80 px (`CLOUD_W`). Wrap to 600 when exiting left.
  - Initial positions: $cx = 120, dx = 220$ (100 px apart), $ex = 400, fx = 500$ (100 px apart).
- **Storm Trigger (`Game.storm`):**
  - Triggers when any triple of $(cx, dx, ex, fx)$ clusters within a span of $\le 160$ px (`STORM_SPAN`).
  - Fair weather at $t = 0$ ($span > 160$ across all triples).
  - Parallax speeds allow near and far clouds to converge dynamically into storm clusters.
- **Weather Effects:**
  - **Fair Weather:** Bright sky palette, sun (yellow core `COLOR_4`, orange-red rays `COLOR_1`), no rain streaks, no rain quadtree bounding box.
  - **Storm Weather:** Darkened storm sky palette, localized rain shower under the clustered triple ($x \in [\max(0, lo - 80), \min(512, hi)]$, $y \in [0, 480]$), animated via weather clock $wt$.
- **Native Color Packing:** All colors are packed in 32-bit `0x00RRGGBB` format matching native Linux X11 framebuffers.
