# Instructions for Pi (Workhorse Coder)

You are the workhorse coder in the Grok -> Gemini -> Pi long-session Bend development harness.
You are the author of the Bend modules in this directory (`./main.bend` and its sibling game modules).

## Scope & Target Shape
- Target files: You are allowed to create/edit ONLY these game files in the project cwd:
  `./main.bend`, `./state.bend`, `./input.bend`, `./physics.bend`, `./difficulty.bend`, `./step.bend`, `./text.bend`, `./scenery.bend`, `./render.bend`.
- Do NOT edit: `LAWS.bend`, `AGENTS.md`, `objectives.json`, `objectives_frozen.json`, `FREEZE.md`, `README.md`, `SPLIT.md`, `LOOP_B_RESULT.md`, `PROOF.bend`, or launch `./flappy`.
- Language: Pure Bend (Bend 2.0.28). Do not port to C, Raylib, SDL2, or any other language.
- Shape: Follow `examples/demos/app_pong_game_2d/main.bend` using `App.run`, `view`, `tick`, and the `Image` quadtree (`Pix` / `Qua`).
- Execution Rule: Implement ONLY the current Loop B objective slice requested in each prompt. Do not jump ahead.
- Native compile: `bend main.bend -o flappy` from this directory. Do not launch `./flappy`.

## Module Architecture & Future Invariants
- The game is split across 9 sibling module files in this directory. Future work must preserve the one-way DAG and must not change logic, numbers, colors, or draw order unless Sahil asks.
- State arity is 24 positional fields:
  `Game{by, sp, dn, px, gy, pc, pt, scored, qx, qy, qc, qt, qscored, seed, mode, score, spd, space_held, r_held, cx, dx, ex, fx, wt}`.
  Every `Game{...}` constructor and pattern-matching unpack site across all modules must match this 24-field arity.
- LCG mixer algorithm: wrap-safe 32-bit `Game.mix`: `next_seed = ((seed * 1664525 : U32) + 1013904223 : U32)`. No `IO.random_u32` or external PRNG.
- Pass latches and pipe wrap: `scored` and `qscored` reset to `False{}` when a pipe wraps.
- Key tracking: `space_held` tracks Space key down/up; `r_held` tracks R key down/up.
- In-play HUD: framed 72x32 at (220, 8) with compact 14x22 digits displaying `score % 1000`. Frame, face, and digits use 3 distinct colors.
- Restart: Dead restart is rising-edge R only (keycodes 114 and 82). Space while dead does NOT restart. Rekey preserves `space_held` across restart to prevent instant flap.
- Clouds: Four parallax clouds (`cx, dx` at speed 2; `ex, fx` at speed 1) wrapping at 600. `wt` ticks while ready and playing; frozen dead. Tiny distant birds derived from `wt`. No storm detection, no rain, no storm sky palette.

## Bend 2 Module Rules
1. Import syntax: `import ./path/file.bend as Alias` — the `as Alias` part is REQUIRED. Bare `import ./file.bend` is rejected.
2. Everything the imported file defines is referenced as `Alias.name`, e.g. `S.Game`, `S.Game{...}`, `S.Game.step(...)`.
3. Dots in names are just characters. Folders are not namespaces. File names do not have to match def names.
4. Nothing loads automatically by name. Every file must import what it uses.
5. Import cycles are rejected. Files must form a one-way hierarchy.
6. Do NOT use `from x import y`.
7. Module path names: letters, digits, `_` and `-` only. Keep files in the project root: `state.bend`, not nested dotted names.

## Live Module Layout & Imports
- `state.bend` as `S`:
  Constants: GRAVITY, FLAP, MAX_FALL, HIT_PAD, BODY_W, BODY_H, BIRD_X, GAP_H, GAP_H_MID, GAP_H_TIGHT, GAP_TOP_MIN, GAP_TOP_MAX, GAP_SPAN, PIPE_W, PIPE_CAP_W, PIPE_CAP_H, PIPE_SPACING, CLOUD_SPD_NEAR, CLOUD_SPD_FAR, CLOUD_W.
  Type: type Game.
  Functions: Game.init, Game.rekey, Game.restart, Game.pick, Game.pickb, Game.sel.
  Imports: `import Base`.
- `input.bend` as `In`:
  Functions: Game.press_space, Game.press_r, Game.event, Game.events.
  Imports: `import Base`, `import ./state.bend as S`.
- `physics.bend` as `Phys`:
  Functions: Game.fall, Game.dir, Game.travel, Game.pipex, Game.pipew, Game.capx, Game.capw, Game.mix.
  Imports: `import Base`, `import ./state.bend as S`.
- `difficulty.bend` as `Diff`:
  Functions: Game.speed_of, Game.gap_of, Game.remix_ty, Game.remix_gy.
  Imports: `import Base`, `import ./state.bend as S`.
- `step.bend` as `Step`:
  Functions: Game.step, Game.tick.
  Imports: `import Base`, `import ./state.bend as S`, `import ./input.bend as In`, `import ./physics.bend as Phys`, `import ./difficulty.bend as Diff`.
- `text.bend` as `Txt`:
  Functions & tables: Game.inside, Game.outside, Game.bar, glyph_* functions, Game.letter, title_code, space_code, title, space_word, over_code, retry_code, rhint_code, exit_code, esc_code, text_code, text, text4, seg, digit, digit_mask, digit_at, digit_c, digit_c_at, dead_score, HUD_X, HUD_Y, HUD_W, HUD_H, Game.hud_score.
  Imports: `import Base`, `import ./state.bend as S`.
- `scenery.bend` as `Sc`:
  Palette constants: SKY_TOP, SKY_MID, SKY_PALE, HILLS_TINT, MOUNT_TINT, SEA_BLUE, SEA_FOAM, FIELD_GREEN, GRASS_GREEN, DIRT_BROWN, CLOUD_WHITE, BIRD_TINT, COLOR_0..4, HUD_FRAME, HUD_FACE, HUD_DIGIT, PANEL_BLUE..DARK.
  Scenery functions: Game.mountains, hills, sea, foam, fields, cloud, birdx, bird, Game.pillar_color.
  Imports: `import Base`, `import ./state.bend as S`, `import ./text.bend as Txt` (for Game.bar).
- `render.bend` as `R`:
  Functions: Game.color, Game.flat.
  Imports: `import Base`, `import ./state.bend as S`, `import ./physics.bend as Phys`, `import ./difficulty.bend as Diff`, `import ./text.bend as Txt`, `import ./scenery.bend as Sc`.
- `main.bend`:
  Keeps file header comment, `import Base`, `import ./state.bend as S`, `import ./step.bend as Step`, `import ./render.bend as R`, Game.draw, Game.view, main.

## Import DAG (One-Way, No Cycles)
```
state <- input, physics, difficulty, text
state + text <- scenery
state + input + physics + difficulty <- step
state + physics + difficulty + text + scenery <- render
state + step + render <- main
```

## Strict Prohibitions
- Pi creates and edits ONLY `./main.bend`, `./state.bend`, `./input.bend`, `./physics.bend`, `./difficulty.bend`, `./step.bend`, `./text.bend`, `./scenery.bend`, `./render.bend` (in this directory). Never write `projects/flappy-bird/main.bend`.
- Never edit or attempt to edit `LAWS.bend`, `AGENTS.md`, `objectives.json`, `objectives_frozen.json`, `FREEZE.md`, `PROOF.bend`, or any file outside this directory.
- Never write or import `PROOF.bend`.
- Never import `LAWS.bend`.
- Do not use `@unsafe` or leave unresolved `?TODO` holes in any game module file.
- Do not use `IO.random_u32` or import any Hub PRNG package.
- Do not add audio, networking, file I/O, sprites, rotation/pitch, or sine hover.
- Do not retune `GRAVITY = 1`, `FLAP = 8`, or `MAX_FALL = 12`.
- Do not add a third pipe pair (keep `PIPE_SPACING = 280`, exactly two pairs).
- Do not add hitboxes to any decorative elements (mountains, sea, fields, clouds, birds).
- Do not change floor death `y >= 496`.
- Do not create or edit any `.c`, Raylib, SDL2, or Makefile files.
- Do not launch `./flappy`.

## Invariant Laws
Follow all candidate laws encoded in `LAWS.bend`:
- L1: Pi may create/edit only these game files in this project directory: ./main.bend, ./state.bend, ./input.bend, ./physics.bend, ./difficulty.bend, ./step.bend, ./text.bend, ./scenery.bend, ./render.bend. Pi must not edit LAWS.bend, AGENTS.md, PROOF.bend, snapshot docs, examples/, grok-agy-pi?, projects/smoke-test-for-bend/, or any .c / Raylib / SDL2 file.
- L2: Those game .bend files must not import LAWS.bend or PROOF.bend.
- L3: No @unsafe. No leftover ?TODO holes in those game .bend files.
- L4: Windowed 2D App.run game: title Flappy Bird, size 512x512, main : IO(Unit). main calls App.run. No Window.open preflight. No CUDA, sockets, file writes, audio, C backends, Raylib, or SDL2. View/tick/Image quadtree follow the official pong demo.
- L5: Esc key-down (code 27) or Close{} makes tick answer None (quit), whatever the rest of the event list and whatever the state. Collision/death/restart must not answer None.
- L6: Alive playing-bird motion is the existing speed model. State keeps y and a vertical speed (U32 magnitude plus direction, or equivalent wrap-safe encoding). Named U32 constants GRAVITY, FLAP, and MAX_FALL keep the current values (1, 8, 12). Each tick while playing: gravity changes speed toward down by GRAVITY; downward speed is clamped to MAX_FALL; y is updated from speed with U32 clamp. y grows downward. Rising-edge Space (Key{32, True{}} while space_held was false) while playing sets upward speed to FLAP. Held space does not flap every tick. Ready and dead birds do not apply gravity, flap-as-motion, or pipe scroll.
- L7: Exactly two pipe pairs of filled rectangles. Each pair has right-edge x, gap top, color index, type, and a pass latch. Pipe width PIPE_W = 40. Horizontal spacing PIPE_SPACING = 280 (init right-edges 552 and 832). While playing, each right-edge decreases by spd. spd is a U32 whole-pixel step from Game.speed_of(score, wt): base 3, plus extra pixels dithered from score and wt so average speed ramps smoothly, capped at 8. Same spd is used for that frame's scroll and wrap test (edge < spd). When a pair leaves the left (edge < spd), it wraps to sibling + PIPE_SPACING, seed is stepped with Game.mix, and that pair's gap/type/color remix per L11–L12. Wrap must land off-screen (sibling at left edge plus 280 is >= 560). No IO.random_u32. No Hub PRNG. Ready and dead do not scroll or remix pipes. Game.init starts first-pair gy = 160, seed = 123456789, spd = 3.
- L8: Bird view is at least three axis-aligned quads (body, beak, wing). Named BODY_W = 24, BODY_H = 16, BIRD_X = 128. Collision uses the body rectangle inset by named HIT_PAD = 2 on each side. Beak and wing do not add hitboxes. Each pipe pair draws a shaft of width PIPE_W and a cap of named PIPE_CAP_W = 56 and PIPE_CAP_H = 16 at each gap edge. Collision against a pair is the union of four AABBs: top shaft, bottom shaft, top cap (y = gy-16 .. gy, x = shaft x expanded 8px), bottom cap (y = gy+gap .. gy+gap+16, same expanded x). A bird in the 8px overhang that is above the top cap or below the bottom cap does not collide. The passable hole for a pair is gy .. gy+gap using that pair's gap height. Overlapping either pair's shaft or cap, y at the floor strip, or y at the ceiling marks the bird dead. Dead bird no longer flaps or moves. Esc/Close still quit. View draws pipes from each pair's gy / gy+gap, not hardcoded 160/288/224.
- L9: Space launches ready and flaps in play. Dead restart is rising-edge R only (114, 82). Space while dead does not restart. Rekey so held Space cannot instantly flap. Ready: FLAPPY + SPACE panel 200x56 at (156, 338) with SPACE glyphs 5px/30px pitch 150px span centered. Dead: GAME OVER, 7-segment score % 1000 (24x40 cells), RETRY (R), EXIT (Esc). Game.flat one box each gated on mode.
- L10: Score unchanged (latches). Playing HUD 72x32 at (220, 8) with compact 14x22 3-digit cells of score % 1000, NOT a solid white 96x48 slab. Digits, frame, face three distinct colors. Game.flat HUD box gated mode == 1. Digits in view.
- L11: Five named distinct RGB pillar colors. Each pair stores an index 0..4. Init indices 0 and 1. On wrap, that pair advances through the five-color set so successive pillars differ. Draw uses the pair's color (shaft and cap).
- L12: Difficulty is staged from score. Game.gap_of maps type 0 to GAP_H = 128, type 1 to GAP_H_MID = 112, type 2 to GAP_H_TIGHT = 96, and does not take score. Game.remix_ty returns 0 when score < 16, 1 when 16 <= score < 24, and (1 + (nseed AND 1)) when score >= 24. Stage 0 (score < 8): wrap remix of gy stays within 48 of the sibling gy then clamped to [GAP_TOP_MIN, GAP_TOP_MAX] with gy + gap <= 480, using U32-safe pick-clamp (no underflow when sibling_gy < 48). Stage 1 (8 <= score < 16): wrap remix of gy stays within 96 of the sibling gy with U32-safe pick-clamp (no underflow when sibling_gy < 96), then the same min/max/480 clamp. Stage 2 (16 <= score < 24): full mixer span for gy. Stage 3 (score >= 24): full span for gy with the chosen hole. Scroll speed is independent of these gap stages; see L7 Game.speed_of. An on-screen pair keeps its stored type until wrap. GAP_TOP_MIN = 64, GAP_TOP_MAX = 304. No IO.random_u32.
- L13: No PROOF.bend, no second window, no sprites/audio/pitch/rotation. Ground y=496..512 two-tone. Decorative required: sky bands (uniform fair SKY_TOP/SKY_MID/SKY_PALE bands), mountains, sea band y=480..496 with foam 480..484, field patches, four cloud clusters, tiny distant birds. None collide. Floor death stays y >= 496 (sea is decorative). In-play compact 7-segment HUD allowed. Game-over 24x40 7-segment allowed.
- L14: Four clouds cx,dx,ex,fx right edges, CLOUD_W=80, wrap to 600. cx/dx CLOUD_SPD_NEAR=2 wrap edge<2. ex/fx CLOUD_SPD_FAR=1 wrap edge<1. Drift ready+playing, freeze dead. wt advances ready+playing, frozen dead. Distant birds from wt. No storm detection, no rain, no storm sky palette. Collision ignores clouds, birds, mountains, sea, fields.
