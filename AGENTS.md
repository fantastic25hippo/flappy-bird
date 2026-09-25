# Instructions for Pi (Workhorse Coder)

You are the workhorse coder in the Grok -> Gemini -> Pi long-session Bend development harness.
You are the author of `main.bend` in this directory (`./main.bend`) for this harness sitting.

## Scope & Target Shape
- Target file: `./main.bend` only (in this directory). Target path is always `./main.bend` (cwd is already this project directory). Never write `projects/flappy-bird/main.bend`.
- Language: Pure Bend only. Do not port to C, Raylib, SDL2, or any other language.
- Shape: Follow `examples/demos/app_pong_game_2d/main.bend` using `App.run`, `view`, `tick`, and the `Image` quadtree (`Pix` / `Qua`).
- Goal: Extend live `./main.bend` to implement Flappy Bird atmosphere and bug fixes. Keep core physics, modes, `HIT_PAD() = 2`, LCG mixer `Game.mix`, two pipe pairs, and spacing 280.
- Execution Rule: Implement ONLY the current Loop B objective slice requested in each prompt. Do not attempt to implement all features in a single objective prompt.

## Six Product Items & Tactical Notes (Atmosphere-and-Fixes Sitting)

1. **Dead restart is R only (114, 82):**
   - In `Game.press_space`, drop the dead-mode `reset` arm. Fresh Space while `mode == 2` only updates `space_held`. Space while dead does NOT restart.
   - Fresh Space while ready still launches with one flap. Fresh Space while playing still sets `FLAP` upward speed.
   - `Game.press_r` restarts on rising-edge R (keycodes 114 and 82) while dead, via `Game.restart(space_held, down)` so a held Space cannot instantly flap upon restart.
   - Ready and playing R only tracks `r_held`.
   - Dead overlay RETRY hint must read as R, not Space/R. Replace the dead-screen Space-word row under RETRY with a short R hint. Do not remove the RETRY panel.

2. **Remove the useless top white rectangle; smaller framed 72x32 HUD:**
   - Do NOT paint the full HUD rect as white. Fix the live bug where `hud_white` ORs the full bar.
   - Smaller in-play HUD: named box 72x32 at (220, 8).
   - Thin 2px frame, inner face, and digits are three distinct contrasting colors (not white-on-white).
   - In-play digits use compact 14x22 cells (new helper, three digits of `score % 1000` fit inside the face), NOT the large 24x40 cells which would clip into the sky. Dead overlay keeps 24x40 `Game.dead_score`. Digits computed in view helpers, not extra Game fields.
   - `Game.flat` in-play HUD box matches 72x32, gated `mode == 1`.
   - Playing view has no pip strip.

3. **Sun is yellow, not purple:**
   - Replace `SUN_GOLD` and `SUN_ORANGE` with pipe color constants that already render correctly on this host:
     - Core uses `COLOR_4()` (yellow).
     - Rays use `COLOR_1()` (orange-red).
   - Keep the static cluster around `(420, 64)`. One extra 8px gold square in the 2x2 core is allowed.
   - Sun never collides with the bird. No decoration hitboxes.

4. **Richer non-colliding landscape (mountains, sea, fields):**
   - Drawn behind pipes, in front of sky bands, zero collision.
   - Mountains: taller static peaks sitting on the ground line, at least two ranges (left and right), stepped quads, darker tint than `HILLS_TINT`. One `Game.flat` box for mountains.
   - Sea: named blue water band `y = 480..496`, full width 512, with lighter foam/shore line `y = 480..484`. Sea is purely decorative. Floor collision strictly remains at `y >= 496` (sea must NOT change floor death).
   - Fields: two named green patches on the ground line in front of mountains and behind pipes (left and right, not covering full 512). Decorative only.
   - Draw order (front to back in `Game.color`): dead UI > bird > ready UI > in-play HUD > pipes > distant birds > clouds > sun > fields > sea > mountains/hills > ground > sky.

5. **Four parallax clouds + tiny distant birds:**
   - Four cloud clusters with state fields `cx, dx, ex, fx` as right edges, `CLOUD_W = 80`, wrap to 600.
   - Near clusters `cx` and `dx`: `CLOUD_SPD_NEAR() = 2`, wrap when right edge `< 2`.
   - Far clusters `ex` and `fx`: `CLOUD_SPD_FAR() = 1`, wrap when right edge `< 1`.
   - Parallax speeds break the static lock so the four clouds drift at two distinct rates.
   - Init all four on-screen and spaced (e.g. `cx = 160`, `dx = 400`, `ex = 280`, `fx = 520`). Upper half y bands.
   - Drift in ready and playing, freeze in dead. Four `Game.flat` boxes. Zero collision.
   - `wt: U32` increments by 1 each tick while ready or playing (`wt + 1`). Dead does not increment `wt`. Init `wt = 0`.
   - Tiny distant birds: two small silhouettes (e.g. body 6x3 plus wing 4x2), drawn in upper third, slower than near clouds. Right edges derived from `wt` via `Game.birdx(wt, 0)` and `Game.birdx(wt, 1)`, width 12, wrap to 600. Zero collision. One `Game.flat` box per bird. Frozen in dead.

6. **Smaller colorful UI:**
   - In-play HUD: 72x32 at (220, 8) with compact 14x22 digits.
   - Ready SPACE start panel: shrink to 200x56 at (156, 338). Title `FLAPPY` stays. `SPACE` word uses scaled glyphs (5px unit / 30px pitch, 150px span) centered in the 200px panel, not the old 232px word which would clip.
   - Dead panels: shrink GAME OVER banner, RETRY, and EXIT each by about one-quarter. RETRY panel a green-leaning fill with R hint; EXIT a red-leaning fill with Esc hint; GAME OVER banner a dark fill; text light.
   - `Game.flat` ready UI and dead UI boxes shrink to match new bounds, gated on mode 0 / 2.

## Architectural Rules & State Arity
- **State Arity Expansion (21 -> 24):**
  - In `obj-3`, adding `ex: U32`, `fx: U32`, and `wt: U32` expands `Game` from 21 to 24 positional fields.
  - You MUST update EVERY `Game{...}` constructor and pattern-matching site together in `obj-3`:
    `init`, `rekey`, `press_space` (all match arms), `press_r`, `event`, `step`, `color`, `flat`, and any helper unpacking `Game`.
  - Missing any single pattern arm will produce an arity mismatch compilation error.
- **Mixer Algorithm:**
  - Wrap-safe 32-bit LCG `Game.mix`: `next_seed = ((seed * 1664525 : U32) + 1013904223 : U32)`.
  - No `IO.random_u32` or external PRNG.
- **Native Compile:**
  - `bend main.bend -o flappy` must compile cleanly and produce binary `./flappy`.
  - Do not launch `./flappy`.

## Strict Prohibitions
- Pi creates and edits ONLY `./main.bend` (in this directory). Never write `projects/flappy-bird/main.bend`.
- Never edit or attempt to edit `LAWS.bend`, `AGENTS.md`, `objectives.json`, `objectives_frozen.json`, `FREEZE.md`, `PROOF.bend`, or any file outside this directory.
- Never write or import `PROOF.bend`.
- Never import `LAWS.bend`.
- Do not use `@unsafe` or leave unresolved `?TODO` holes.
- Do not use `IO.random_u32` or import any Hub PRNG package.
- Do not add audio, networking, file I/O, sprites, rotation/pitch, or sine hover.
- Do not retune `GRAVITY = 1`, `FLAP = 8`, or `MAX_FALL = 12`.
- Do not add a third pipe pair (keep `PIPE_SPACING = 280`, exactly two pairs).
- Do not add hitboxes to any decorative elements (sun, mountains, sea, fields, clouds, birds).
- Do not change floor death `y >= 496`.
- Do not create or edit any `.c`, Raylib, SDL2, or Makefile files.
- Do not launch `./flappy`.

## Invariant Laws
Follow all candidate laws encoded in `LAWS.bend`:
- L1: Pi may create/edit only ./main.bend (the main.bend in this project directory). Pi must not edit LAWS.bend, AGENTS.md, PROOF.bend, snapshot docs, examples/, grok-agy-pi?, projects/smoke-test-for-bend/, or any .c / Raylib / SDL2 file.
- L2: main.bend must not import LAWS.bend or PROOF.bend.
- L3: No @unsafe. No leftover ?TODO holes in main.bend.
- L4: Windowed 2D App.run game: title Flappy Bird, size 512x512, main : IO(Unit). main calls App.run. No Window.open preflight. No CUDA, sockets, file writes, audio, C backends, Raylib, or SDL2. View/tick/Image quadtree follow the official pong demo.
- L5: Esc key-down (code 27) or Close{} makes tick answer None (quit), whatever the rest of the event list and whatever the state. Collision/death/restart must not answer None.
- L6: Alive playing-bird motion is the existing speed model. State keeps y and a vertical speed (U32 magnitude plus direction, or equivalent wrap-safe encoding). Named U32 constants GRAVITY, FLAP, and MAX_FALL keep the current values (1, 8, 12). Each tick while playing: gravity changes speed toward down by GRAVITY; downward speed is clamped to MAX_FALL; y is updated from speed with U32 clamp. y grows downward. Rising-edge Space (Key{32, True{}} while space_held was false) while playing sets upward speed to FLAP. Held space does not flap every tick. Ready and dead birds do not apply gravity, flap-as-motion, or pipe scroll.
- L7: Exactly two pipe pairs of filled rectangles. Each pair has right-edge x, gap top, color index, type, and a pass latch. Pipe width PIPE_W = 40. Horizontal spacing PIPE_SPACING = 280 (init right-edges 552 and 832). While playing, each right-edge decreases by spd. When a pair leaves the left (edge < spd), it wraps to sibling + PIPE_SPACING, seed is stepped with Game.mix, and that pair's gap/type/color remix per L11–L12. Wrap must land off-screen (sibling at left edge plus 280 is >= 560). No IO.random_u32. No Hub PRNG. Ready and dead do not scroll or remix pipes. Game.init starts first-pair gy = 160, seed = 123456789, spd = 3.
- L8: Bird view is at least three axis-aligned quads (body, beak, wing). Named BODY_W = 24, BODY_H = 16, BIRD_X = 128. Collision uses the body rectangle inset by named HIT_PAD = 2 on each side. Beak and wing do not add hitboxes. Each pipe pair draws a shaft of width PIPE_W and a cap of named PIPE_CAP_W = 56 and PIPE_CAP_H = 16 at each gap edge. Collision against a pair is the union of four AABBs: top shaft, bottom shaft, top cap (y = gy-16 .. gy, x = shaft x expanded 8px), bottom cap (y = gy+gap .. gy+gap+16, same expanded x). A bird in the 8px overhang that is above the top cap or below the bottom cap does not collide. The passable hole for a pair is gy .. gy+gap using that pair's gap height. Overlapping either pair's shaft or cap, y at the floor strip, or y at the ceiling marks the bird dead. Dead bird no longer flaps or moves. Esc/Close still quit. View draws pipes from each pair's gy / gy+gap, not hardcoded 160/288/224.
- L9: Space launches ready and flaps in play. Dead restart is rising-edge R only (114, 82). Space while dead does not restart. Rekey so held Space cannot instantly flap. Ready: FLAPPY + SPACE panel 200x56 at (156, 338) with SPACE glyphs 5px/30px pitch 150px span centered. Dead: GAME OVER, 7-segment score % 1000 (24x40 cells), RETRY (R), EXIT (Esc). Game.flat one box each gated on mode.
- L10: Score unchanged (latches). Playing HUD 72x32 at (220, 8) with compact 14x22 3-digit cells of score % 1000, NOT a solid white 96x48 slab. Digits, frame, face three distinct colors. Game.flat HUD box gated mode == 1. Digits in view.
- L11: Five named distinct RGB pillar colors. Each pair stores an index 0..4. Init indices 0 and 1. On wrap, that pair advances through the five-color set so successive pillars differ. Draw uses the pair's color (shaft and cap).
- L12: Difficulty is staged from score. Game.gap_of maps type 0 to GAP_H = 128, type 1 to GAP_H_MID = 112, type 2 to GAP_H_TIGHT = 96, and does not take score. Game.remix_ty returns 0 when score < 16, 1 when 16 <= score < 24, and (1 + (nseed AND 1)) when score >= 24. Stage 0 (score < 8): spd = 3, wrap remix of gy stays within 48 of the sibling gy then clamped to [GAP_TOP_MIN, GAP_TOP_MAX] with gy + gap <= 480, using U32-safe pick-clamp (no underflow when sibling_gy < 48). Stage 1 (8 <= score < 16): spd = 3, wrap remix of gy stays within 96 of the sibling gy with U32-safe pick-clamp (no underflow when sibling_gy < 96), then the same min/max/480 clamp. Stage 2 (16 <= score < 24): spd = 4, full mixer span for gy. Stage 3 (score >= 24): spd = 4, full span for gy with the chosen hole. An on-screen pair keeps its stored type until wrap. GAP_TOP_MIN = 64, GAP_TOP_MAX = 304. No IO.random_u32.
- L13: No PROOF.bend, no second window, no sprites/audio/pitch/rotation. Ground y=496..512 two-tone. Decorative required: sky bands (uniform fair SKY_TOP/SKY_MID/SKY_PALE bands), yellow sun (core COLOR_4, rays COLOR_1), mountains, sea band y=480..496 with foam 480..484, field patches, four cloud clusters, tiny distant birds. None collide. Floor death stays y >= 496 (sea is decorative). In-play compact 7-segment HUD allowed. Game-over 24x40 7-segment allowed.
- L14: Four clouds cx,dx,ex,fx right edges, CLOUD_W=80, wrap to 600. cx/dx CLOUD_SPD_NEAR=2 wrap edge<2. ex/fx CLOUD_SPD_FAR=1 wrap edge<1. Drift ready+playing, freeze dead. wt advances ready+playing, frozen dead. Distant birds from wt. No storm detection, no rain, no storm sky palette. Collision ignores clouds, birds, sun, mountains, sea, fields.
