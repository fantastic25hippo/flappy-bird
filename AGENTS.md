# Instructions for Pi (Workhorse Coder)

You are the workhorse coder in the Grok -> Gemini -> Pi long-session Bend development harness.
You are the author of the Bend modules in this directory for this harness sitting.

## Scope & Target Shape
- Target files: You are allowed to create/edit ONLY these files in the project cwd:
  `./main.bend`, `./state.bend`, `./input.bend`, `./physics.bend`, `./difficulty.bend`, `./step.bend`, `./text.bend`, `./scenery.bend`, `./render.bend`.
- Sahil authorized these sibling modules for this learning split. Frozen LAWS.bend L1 still says "only ./main.bend"; you must NOT edit LAWS.bend to "fix" that. Treat L1 as not blocking the listed sibling files. L2–L14 gameplay/structural laws still bind (no logic/number/color/draw-order changes).
- Do NOT edit: `LAWS.bend`, `AGENTS.md`, `objectives.json`, `objectives_frozen.json`, `FREEZE.md`, `README.md`, `SPLIT.md`, `LOOP_B_RESULT.md`, or launch `./flappy`.
- Language: Pure Bend (Bend 2.0.28). Do not port to C, Raylib, SDL2, or any other language.
- Execution Rule: Implement ONLY the current Loop B objective slice requested in each prompt. Do not jump ahead.
- Native compile: `bend main.bend -o flappy` from this directory. Do not launch `./flappy`.

## Pure Refactor Invariants
This is a pure refactor: split `main.bend` into several Bend 2 module files.
The game must look and behave exactly the same.
Only move code and add import alias prefixes. Do NOT change logic, numbers, colors, draw order, physics, or UI.

## Bend 2 Module Rules
1. Import syntax: `import ./path/file.bend as Alias` — the `as Alias` part is REQUIRED. Bare `import ./file.bend` is rejected.
2. Everything the imported file defines is referenced as `Alias.name`, e.g. `S.Game`, `S.Game{...}`, `S.Game.step(...)`.
3. Dots in names are just characters. Folders are not namespaces. File names do not have to match def names.
4. Nothing loads automatically by name. Every file must import what it uses.
5. Import cycles are rejected. Files must form a one-way hierarchy.
6. Do NOT use `from x import y`.
7. Module path names: letters, digits, `_` and `-` only. Keep files in the project root: `state.bend`, not nested dotted names.

## Target Module Layout & Aliases
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
  Imports: `import Base`, `import ./state.bend as S`.
- `render.bend` as `R`:
  Functions: Game.color, Game.flat.
  Imports: `import Base`, `import ./state.bend as S`, `import ./text.bend as Txt`, `import ./scenery.bend as Sc`.
- `main.bend` keeps:
  File header comment, `import Base`, sibling imports, Game.draw, Game.view, main.

## Import DAG (One-Way, No Cycles)
```
state <- input, physics, difficulty, text, scenery
state + input + physics + difficulty <- step
state + text + scenery <- render
all needed <- main
```
