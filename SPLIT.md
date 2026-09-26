# Bend 2 Module Split Report: Flappy Bird

## 1. Overview
In this sitting, `projects/flappy-bird/main.bend` (originally 968 lines) was refactored into a modular Bend 2 architecture across 9 files using the one-way import DAG. All code refactoring in Bend was performed by Pi (`mimo-v2.6-pro` via provider `mimo`) under Loop B supervision. No logic, numbers, colors, draw order, physics, or UI behavior were changed.

## 2. Files Created & Def Distribution

### `state.bend` (Import Alias: `S`)
- **Imports:** `import Base`
- **Tuning Constants:**
  - `GRAVITY`, `FLAP`, `MAX_FALL`, `HIT_PAD`, `BODY_W`, `BODY_H`, `BIRD_X`
  - `GAP_H`, `GAP_H_MID`, `GAP_H_TIGHT`, `GAP_TOP_MIN`, `GAP_TOP_MAX`, `GAP_SPAN`
  - `PIPE_W`, `PIPE_CAP_W`, `PIPE_CAP_H`, `PIPE_SPACING`
  - `CLOUD_SPD_NEAR`, `CLOUD_SPD_FAR`, `CLOUD_W`
- **Data Types:**
  - `type Game is Data: Game{...}` (24 fields)
- **Functions:**
  - `Game.init`
  - `Game.rekey`
  - `Game.restart`
  - `Game.pick`
  - `Game.pickb`
  - `Game.sel`

### `input.bend` (Import Alias: `In`)
- **Imports:** `import Base`, `import ./state.bend as S`
- **Functions:**
  - `Game.press_space`
  - `Game.press_r`
  - `Game.event`
  - `Game.events`

### `physics.bend` (Import Alias: `Phys`)
- **Imports:** `import Base`, `import ./state.bend as S`
- **Functions:**
  - `Game.fall`
  - `Game.dir`
  - `Game.travel`
  - `Game.pipex`
  - `Game.pipew`
  - `Game.capx`
  - `Game.capw`
  - `Game.mix`

### `difficulty.bend` (Import Alias: `Diff`)
- **Imports:** `import Base`, `import ./state.bend as S`
- **Functions:**
  - `Game.speed_of`
  - `Game.gap_of`
  - `Game.remix_ty`
  - `Game.remix_gy`

### `step.bend` (Import Alias: `Step`)
- **Imports:** `import Base`, `import ./state.bend as S`, `import ./input.bend as In`, `import ./physics.bend as Phys`, `import ./difficulty.bend as Diff`
- **Functions:**
  - `Game.step`
  - `Game.tick`

### `text.bend` (Import Alias: `Txt`)
- **Imports:** `import Base`, `import ./state.bend as S`
- **Functions & Constants:**
  - Hit/geometry helpers: `Game.inside`, `Game.outside`, `Game.bar`
  - Glyphs: `Game.glyph_f`, `Game.glyph_l`, `Game.glyph_a`, `Game.glyph_p`, `Game.glyph_y`, `Game.glyph_s`, `Game.glyph_c`, `Game.glyph_e`, `Game.glyph_g`, `Game.glyph_m`, `Game.glyph_o`, `Game.glyph_v`, `Game.glyph_r`, `Game.glyph_t`, `Game.glyph_x`, `Game.glyph_i`
  - Text tables & words: `Game.letter`, `Game.title_code`, `Game.space_code`, `Game.title`, `Game.space_word`, `Game.over_code`, `Game.retry_code`, `Game.rhint_code`, `Game.exit_code`, `Game.esc_code`, `Game.text_code`, `Game.text`, `Game.text4`
  - 7-segment digits: `Game.seg`, `Game.digit`, `Game.digit_mask`, `Game.digit_at`, `Game.digit_c`, `Game.digit_c_at`, `Game.dead_score`
  - In-play HUD: `HUD_X`, `HUD_Y`, `HUD_W`, `HUD_H`, `Game.hud_score`

### `scenery.bend` (Import Alias: `Sc`)
- **Imports:** `import Base`, `import ./state.bend as S`, `import ./text.bend as Txt`
- **Palette Constants:**
  - `SKY_TOP`, `SKY_MID`, `SKY_PALE`, `HILLS_TINT`, `MOUNT_TINT`, `SEA_BLUE`, `SEA_FOAM`
  - `FIELD_GREEN`, `GRASS_GREEN`, `DIRT_BROWN`, `CLOUD_WHITE`, `BIRD_TINT`
  - `COLOR_0`, `COLOR_1`, `COLOR_2`, `COLOR_3`, `COLOR_4`
  - `HUD_FRAME`, `HUD_FACE`, `HUD_DIGIT`
  - `PANEL_BLUE`, `PANEL_GREEN`, `PANEL_RED`, `PANEL_DARK`
- **Functions:**
  - `Game.mountains`
  - `Game.hills`
  - `Game.sea`
  - `Game.foam`
  - `Game.fields`
  - `Game.cloud`
  - `Game.birdx`
  - `Game.bird`
  - `Game.pillar_color`

### `render.bend` (Import Alias: `R`)
- **Imports:** `import Base`, `import ./state.bend as S`, `import ./physics.bend as Phys`, `import ./difficulty.bend as Diff`, `import ./text.bend as Txt`, `import ./scenery.bend as Sc`
- **Functions:**
  - `Game.color`
  - `Game.flat`

### `main.bend` (Entry Point, 51 lines)
- **Imports:** `import Base`, `import ./state.bend as S`, `import ./step.bend as Step`, `import ./render.bend as R`
- **Retained Entry Definitions:**
  - File header comments
  - `Game.draw` (calls `R.Game.color`, `R.Game.flat`)
  - `Game.view` (calls `Game.draw`, `R.Game.flat`)
  - `main` (`App.run(~S.Game, ~App{Game.view, Step.Game.tick}, "Flappy Bird", 512, 512, S.Game.init())`)

## 3. Cleanliness of Split & Dependency Structure
- **Were any defs unable to split cleanly?** None. All 126 definitions, data types, and constants from original `main.bend` were cleanly partitioned into their target modules without duplication or omission.
- **Inter-module dependency note:** `scenery.bend` draws shapes using `Txt.Game.bar`, so it cleanly imports `./text.bend as Txt`. The import graph is strictly a Directed Acyclic Graph (DAG) with zero cycles:
```
state <- input, physics, difficulty, text
state + text <- scenery
state + input + physics + difficulty <- step
state + physics + difficulty + text + scenery <- render
state + step + render <- main
```

## 4. Compiler Verification
- `bend main.bend --check-only`:
  - **Result:** `All terms check.`
  - **Exit code:** 0
- `bend main.bend -o flappy`:
  - **Result:** Native executable binary compiled successfully (`./flappy`, 1,154,240 bytes).
  - **Exit code:** 0
- **Execution constraint:** `./flappy` was **NOT** launched.

## 5. Invariant Protection & Verification
- `LAWS.bend`: Not modified. `laws-check` verified SHA-256 matches frozen snapshot `c05fb14dcd219834f9f94e03d3d7502f21b282da6bf232beb62ab303d488e6cf` and permissions `444` intact.
- `LAWS.bend.sha256`: Not modified.
- `LAWS.bend.snapshot`: Not modified.
- `objectives.json` (atmosphere): Not modified.
- `objectives_frozen.json` (atmosphere): Not modified.
- All sitting objectives managed in sitting-local path `sittings/split-modules-objectives*.json`.
