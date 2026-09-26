# Behavioral and Structural Invariants (LAWS) for flappy-bird
# Locked 2026-09-25 in Loop A (2026-09-25-flappy-bird-atmosphere-fixes.md)
#
# L1: Pi may create/edit only these game files in this project directory: ./main.bend, ./state.bend, ./input.bend, ./physics.bend, ./difficulty.bend, ./step.bend, ./text.bend, ./scenery.bend, ./render.bend.
#     Pi must not edit LAWS.bend, AGENTS.md, PROOF.bend, snapshot docs, examples/, grok-agy-pi?, projects/smoke-test-for-bend/, or any .c / Raylib / SDL2 file.
# L2: Those game .bend files must not import LAWS.bend or PROOF.bend.
# L3: No @unsafe. No leftover ?TODO holes in those game .bend files.
# L4: Windowed 2D App.run game: title Flappy Bird, size 512x512, main : IO(Unit).
#     main calls App.run. No Window.open preflight.
#     No CUDA, sockets, file writes, audio, C backends, Raylib, or SDL2.
#     View/tick/Image quadtree follow the official pong demo.
# L5: Esc key-down (code 27) or Close{} makes tick answer None (quit), whatever the rest of the event list and whatever the state.
#     Collision/death/restart must not answer None.
# L6: Alive playing-bird motion is the existing speed model. State keeps y and a vertical speed (U32 magnitude plus direction, or equivalent wrap-safe encoding).
#     Named U32 constants GRAVITY, FLAP, and MAX_FALL keep the current values (1, 8, 12).
#     Each tick while playing: gravity changes speed toward down by GRAVITY; downward speed is clamped to MAX_FALL; y is updated from speed with U32 clamp. y grows downward.
#     Rising-edge Space (Key{32, True{}} while space_held was false) while playing sets upward speed to FLAP. Held space does not flap every tick.
#     Ready and dead birds do not apply gravity, flap-as-motion, or pipe scroll.
# L7: Exactly two pipe pairs of filled rectangles. Each pair has right-edge x, gap top, color index, type, and a pass latch.
#     Pipe width PIPE_W = 40. Horizontal spacing PIPE_SPACING = 280 (init right-edges 552 and 832).
#     While playing, each right-edge decreases by spd. spd is a U32 whole-pixel step from Game.speed_of(score, wt): base 3, plus extra pixels dithered from score and wt so average speed ramps smoothly, capped at 8. Same spd is used for that frame's scroll and wrap test (edge < spd). When a pair leaves the left (edge < spd), it wraps to sibling + PIPE_SPACING,
#     seed is stepped with Game.mix, and that pair's gap/type/color remix per L11–L12.
#     Wrap must land off-screen (sibling at left edge plus 280 is >= 560).
#     No IO.random_u32. No Hub PRNG. Ready and dead do not scroll or remix pipes.
#     Game.init starts first-pair gy = 160, seed = 123456789, spd = 3.
# L8: Bird view is at least three axis-aligned quads (body, beak, wing). Named BODY_W = 24, BODY_H = 16, BIRD_X = 128.
#     Collision uses the body rectangle inset by named HIT_PAD = 2 on each side. Beak and wing do not add hitboxes.
#     Each pipe pair draws a shaft of width PIPE_W and a cap of named PIPE_CAP_W = 56 and PIPE_CAP_H = 16 at each gap edge.
#     Collision against a pair is the union of four AABBs: top shaft, bottom shaft, top cap (y = gy-16 .. gy, x = shaft x expanded 8px), bottom cap (y = gy+gap .. gy+gap+16, same expanded x).
#     A bird in the 8px overhang that is above the top cap or below the bottom cap does not collide.
#     The passable hole for a pair is gy .. gy+gap using that pair's gap height.
#     Overlapping either pair's shaft or cap, y at the floor strip, or y at the ceiling marks the bird dead.
#     Dead bird no longer flaps or moves. Esc/Close still quit.
#     View draws pipes from each pair's gy / gy+gap, not hardcoded 160/288/224.
# L9: Space launches ready and flaps in play. Dead restart is rising-edge R only (114, 82). Space while dead does not restart. Rekey so held Space cannot instantly flap. Ready: FLAPPY + SPACE panel 200x56 at (156, 338) with SPACE glyphs 5px/30px pitch 150px span centered. Dead: GAME OVER, 7-segment score % 1000 (24x40 cells), RETRY (R), EXIT (Esc). Game.flat one box each gated on mode.
# L10: Score unchanged (latches). Playing HUD 72x32 at (220, 8) with compact 14x22 3-digit cells of score % 1000, NOT a solid white 96x48 slab. Digits, frame, face three distinct colors. Game.flat HUD box gated mode == 1. Digits in view.
# L11: Five named distinct RGB pillar colors. Each pair stores an index 0..4. Init indices 0 and 1.
#      On wrap, that pair advances through the five-color set so successive pillars differ. Draw uses the pair's color (shaft and cap).
# L12: Difficulty is staged from score.
#      Game.gap_of maps type 0 to GAP_H = 128, type 1 to GAP_H_MID = 112, type 2 to GAP_H_TIGHT = 96, and does not take score.
#      Game.remix_ty returns 0 when score < 16, 1 when 16 <= score < 24, and (1 + (nseed AND 1)) when score >= 24.
#      Stage 0 (score < 8): wrap remix of gy stays within 48 of the sibling gy then clamped to [GAP_TOP_MIN, GAP_TOP_MAX] with gy + gap <= 480, using U32-safe pick-clamp (no underflow when sibling_gy < 48).
#      Stage 1 (8 <= score < 16): wrap remix of gy stays within 96 of the sibling gy with U32-safe pick-clamp (no underflow when sibling_gy < 96), then the same min/max/480 clamp.
#      Stage 2 (16 <= score < 24): full mixer span for gy.
#      Stage 3 (score >= 24): full span for gy with the chosen hole.
#      Scroll speed is independent of these gap stages; see L7 Game.speed_of.
#      An on-screen pair keeps its stored type until wrap.
#      GAP_TOP_MIN = 64, GAP_TOP_MAX = 304. No IO.random_u32.
# L13: No PROOF.bend, no second window, no sprites/audio/pitch/rotation. Ground y=496..512 two-tone. Decorative required: sky bands (uniform fair SKY_TOP/SKY_MID/SKY_PALE bands), mountains, sea band y=480..496 with foam 480..484, field patches, four cloud clusters, tiny distant birds. None collide. Floor death stays y >= 496 (sea is decorative). In-play compact 7-segment HUD allowed. Game-over 24x40 7-segment allowed.
# L14: Four clouds cx,dx,ex,fx right edges, CLOUD_W=80, wrap to 600. cx/dx CLOUD_SPD_NEAR=2 wrap edge<2. ex/fx CLOUD_SPD_FAR=1 wrap edge<1. Drift ready+playing, freeze dead. wt advances ready+playing, frozen dead. Distant birds from wt. No storm detection, no rain, no storm sky palette. Collision ignores clouds, birds, mountains, sea, fields.
