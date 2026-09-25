# Flappy Bird: guide a multi-rect bird (body, beak, wing) through two
# scrolling pipe pairs spaced PIPE_SPACING apart. Three modes: ready (frozen, with a FLAPPY title
# and a SPACE start panel), playing (gravity, scroll, score), dead
# (frozen, with a GAME OVER banner, 7-segment score, and RETRY / EXIT
# panels). A fresh Space launches the run with one flap; only a
# fresh R restarts after death (Space never restarts). Collision uses
# only the body inset by
# HIT_PAD on each side. Sky bands, a sun, mountains, hills, a sea
# band, and field patches are pure decoration over a two-tone ground
# (grass over dirt) and never
# collide. Four cloud clusters drift at parallax speeds and two tiny
# distant birds slide across the upper third. Clustered clouds brew a
# storm: darker sky bands, all decorative.
# Score draws as a framed 3-digit 7-segment HUD at top-center while
# playing. Esc key-down or Close quits whatever the mode. Difficulty is
# staged from score: scroll speeds 2/3/4 and, from 16 pillars, mid
# then tight holes.
#
#   bend main.bend -o flappy && ./flappy

import Base

# Gravity added to the vertical speed every tick while playing.
def GRAVITY() -> U32: 1

# Upward speed magnitude set by a fresh Space press.
def FLAP() -> U32: 8

# Terminal speed: the downward speed clamps to MAX_FALL.
def MAX_FALL() -> U32: 12

# Collision inset: the body hitbox shrinks by HIT_PAD on each side.
def HIT_PAD() -> U32: 2

# Bird body size; the body is the only hitbox (inset by HIT_PAD). The
# beak and the wing are visual rects without hitboxes.
def BODY_W() -> U32: 24
def BODY_H() -> U32: 16

# Body left edge: the body spans x BIRD_X .. BIRD_X + BODY_W.
def BIRD_X() -> U32: 128

# Named gap heights between the pipe rects, chosen by the pair's
# stored type alone: the normal hole (type 0), the mid hole (type 1),
# and the tight hole (type 2).
def GAP_H() -> U32: 128
def GAP_H_MID() -> U32: 112
def GAP_H_TIGHT() -> U32: 96

# Gap top bounds for the mixer-derived `gy`. GAP_SPAN is the range of
# the `seed % GAP_SPAN` offset added to GAP_TOP_MIN.
def GAP_TOP_MIN() -> U32: 64
def GAP_TOP_MAX() -> U32: 304
def GAP_SPAN() -> U32: (GAP_TOP_MAX() - GAP_TOP_MIN() : U32)

# Pipe geometry: filled shaft rect width and the horizontal spacing
# between the two pairs' right edges. Each gap edge wears a cap of
# PIPE_CAP_W x PIPE_CAP_H: 8px wider than the shaft on each side and
# PIPE_CAP_H tall.
def PIPE_W() -> U32: 40
def PIPE_CAP_W() -> U32: 56
def PIPE_CAP_H() -> U32: 16
def PIPE_SPACING() -> U32: 280

# Cloud drift: each cluster's right edge moves left per tick while
# ready or playing and wraps to 600 when it leaves the left (so the
# left edge 520 > 512 re-enters with no pop). The near clusters cx /
# dx move CLOUD_SPD_NEAR and wrap when the right edge < CLOUD_SPD_NEAR;
# the far clusters ex / fx move CLOUD_SPD_FAR and wrap when the right
# edge < CLOUD_SPD_FAR: the parallax speeds and their wrap thresholds
# keep every subtraction U32-safe. A cluster is CLOUD_W wide in
# [right - CLOUD_W, right].
def CLOUD_SPD_NEAR() -> U32: 2
def CLOUD_SPD_FAR() -> U32: 1
def CLOUD_W() -> U32: 80

# Bird y `by`; vertical speed magnitude `sp` with direction `dn`
# (True = moving down); pipe pair A: right edge `px`, gap top `gy` with
# the passable hole at gy .. gy + that pair's gap height, color index `pc`, type `pt`,
# pass latch `scored`; pipe pair B: `qx`, `qy`, `qc`, `qt`, `qscored`;
# `seed` is the in-state mixer seed stepped on pipe wrap; `mode` is 0
# ready, 1 playing, 2 dead; `score` counts pipe passes with each pair's
# latch scoring one point per pass; `spd` is the staged scroll speed;
# `space_held` / `r_held` give rising-edge keys; `cx` / `dx` are the
# two near cloud clusters' right edges (CLOUD_W wide each, moving at
# CLOUD_SPD_NEAR), `ex` / `fx` the two far ones (CLOUD_SPD_FAR), and
# `wt` is the weather clock: +1 per tick while ready or playing,
# frozen when dead, driving the tiny distant birds.
type Game is Data:
  Game{by: U32, sp: U32, dn: Bool, px: U32, gy: U32, pc: U32, pt: U32, scored: Bool, qx: U32, qy: U32, qc: U32, qt: U32, qscored: Bool, seed: U32, mode: U32, score: U32, spd: U32, space_held: Bool, r_held: Bool, cx: U32, dx: U32, ex: U32, fx: U32, wt: U32}

# Init starts all four clouds on-screen and spaced (cx 120, dx 220,
# ex 400, fx 500) with the weather clock wt = 0.
def Game.init() -> Game:
  Game{256, 0, True{}, 552, 160, 0, 0, False{}, 832, 224, 1, 0, False{}, 123456789, 0, 0, 2, False{}, False{}, 120, 220, 400, 500, 0}

# Dead restart restores Game.init(), but keeps the live key states so
# a held Space can never instantly flap after the R restart.
def Game.rekey(g: Game, +sh: Bool, +rh: Bool) -> Game:
  Game{by, sp, dn, px, gy, pc, pt, scored, qx, qy, qc, qt, qscored, seed, mode, score, spd, space_held, r_held, cx, dx, ex, fx, wt} = g
  Game{by, sp, dn, px, gy, pc, pt, scored, qx, qy, qc, qt, qscored, seed, mode, score, spd, sh, rh, cx, dx, ex, fx, wt}

def Game.restart(+sh: Bool, +rh: Bool) -> Game:
  Game.rekey(Game.init(), sh, rh)

def Game.pick(c: Bool, a: U32, b: U32) -> U32:
  match c:
    case True{}:
      a
    case False{}:
      b

def Game.pickb(c: Bool, a: Bool, b: Bool) -> Bool:
  match c:
    case True{}:
      a
    case False{}:
      b

def Game.sel(+c: Bool, +a: Game, +b: Game) -> Game:
  match c:
    case True{}:
      a
    case False{}:
      b

# Keys
# ----

# A fresh Space press while ready launches the run with one flap and a
# fresh Space press while playing overrides the speed with FLAP up.
# Space while dead never restarts: it only tracks the key state.
# Restart after death is rising-edge R alone (see Game.press_r). Held
# Space never re-flaps. `space_held` just tracks the key state (down ->
# True, up -> False).
def Game.press_space(+down: Bool, +g: Game) -> Game:
  Game{by, sp, dn, px, gy, pc, pt, scored, qx, qy, qc, qt, qscored, seed, mode, score, spd, space_held, r_held, cx, dx, ex, fx, wt} = g
  +fresh = Game.pickb(down, Bool.not(space_held), False{})
  +flap = Game.pickb(fresh, ((0 < mode) && (mode < 2) : U32), False{})
  +launch = Game.pickb(fresh, (mode < 1 : U32), False{})
  Game.sel(launch, Game{by, FLAP(), False{}, px, gy, pc, pt, scored, qx, qy, qc, qt, qscored, seed, 1, score, spd, down, r_held, cx, dx, ex, fx, wt},
      Game.sel(flap, Game{by, FLAP(), False{}, px, gy, pc, pt, scored, qx, qy, qc, qt, qscored, seed, mode, score, spd, down, r_held, cx, dx, ex, fx, wt},
        Game{by, sp, dn, px, gy, pc, pt, scored, qx, qy, qc, qt, qscored, seed, mode, score, spd, down, r_held, cx, dx, ex, fx, wt}))

# A fresh R press while dead restarts; elsewhere R does nothing but
# track its key state. `r_held` gives the rising edge.
def Game.press_r(+down: Bool, +g: Game) -> Game:
  Game{by, sp, dn, px, gy, pc, pt, scored, qx, qy, qc, qt, qscored, seed, mode, score, spd, space_held, r_held, cx, dx, ex, fx, wt} = g
  +fresh = Game.pickb(down, Bool.not(r_held), False{})
  +reset = Game.pickb(fresh, (1 < mode : U32), False{})
  Game.sel(reset, Game.restart(space_held, down),
    Game{by, sp, dn, px, gy, pc, pt, scored, qx, qy, qc, qt, qscored, seed, mode, score, spd, space_held, down, cx, dx, ex, fx, wt})

def Game.event(e: Event, g: Game) -> Maybe<Game>:
  match e:
    case Key{27, True{}}:
      None{}
    case Key{32, down}:
      Some{Game.press_space(down, g)}
    case Key{114, down}:
      Some{Game.press_r(down, g)}
    case Key{82, down}:
      Some{Game.press_r(down, g)}
    case Close{}:
      None{}
    case _:
      Some{g}

def Game.events(events: List<Event>, g: Game) -> Maybe<Game>:
  match events:
    case []:
      Some{g}
    case e <> rest:
      Maybe.bind(&1, Game, Game, Game.event(e, g), g2 => Game.events(rest, g2))

# Motion
# ------

# Gravity shifts the speed toward down by GRAVITY; the falling speed
# clamps to MAX_FALL and running out of upward speed flips the
# direction to down.
def Game.fall(+sp: U32, +dn: Bool) -> U32:
  +s = (sp + GRAVITY() : U32)
  down_sp = Game.pick((MAX_FALL() < s : U32), MAX_FALL(), s)
  up_sp = Game.pick((GRAVITY() <= sp : U32), (sp - GRAVITY() : U32),
    (GRAVITY() - sp : U32))
  Game.pick(dn, down_sp, up_sp)

# Direction after gravity: falling stays down, rising flips at zero.
def Game.dir(+sp: U32, +dn: Bool) -> Bool:
  Game.pickb(dn, True{}, (sp < GRAVITY() : U32))

# y grows downward: falling adds the speed, rising subtracts it with
# the pong pick-clamp at 0; the floor clamp at 496 caps the fall.
def Game.travel(+by: U32, +sp: U32, +dn: Bool) -> U32:
  +ny = Game.pick(dn, (by + sp : U32),
    Game.pick((by < sp : U32), 0, (by - sp : U32)))
  Game.pick((496 < ny : U32), 496, ny)

# Pipe geometry: a PIPE_W wide pair at [prx, prx + prw], clamped so
# the visible width shrinks while the pair leaves or enters the window.
def Game.pipex(+px: U32) -> U32:
  Game.pick((px < PIPE_W() : U32), 0, (px - PIPE_W() : U32))

def Game.pipew(+px: U32) -> U32:
  Game.pick((px < PIPE_W() : U32), px, PIPE_W())

# Cap geometry: a PIPE_CAP_W wide lip at each gap edge, overhanging
# the shaft by 8px on each side. The cap left clamps at 0 while the
# pair leaves the window and the right edge px + 8 clamps at 512, so
# the width shrinks at either side and never exceeds PIPE_CAP_W.
def Game.capx(+px: U32) -> U32:
  Game.pick((px < 48 : U32), 0, (px - 48 : U32))

def Game.capw(+px: U32) -> U32:
  +cr = (px + 8 : U32)
  +rx = Game.pick((512 < cr : U32), 512, cr)
  +lx = Game.capx(px)
  +span = Game.pick((rx < lx : U32), 0, (rx - lx : U32))
  Game.pick((PIPE_CAP_W() < span : U32), PIPE_CAP_W(), span)

# 32-bit Linear Congruential Generator stepping the in-state mixer
# seed on pipe wrap (Numerical Recipes constants).
def Game.mix(+seed: U32) -> U32:
  ((seed * 1664525 : U32) + 1013904223 : U32)

# Staged scroll speed from score: 2 before 8 pillars, 3 before 16, 4
# after.
def Game.speed_of(+score: U32) -> U32:
  Game.pick((score < 8 : U32), 2, Game.pick((score < 16 : U32), 3, 4))

# Gap height of a pair from its stored type alone (never score): type
# 0 the normal hole, type 1 the mid hole, type 2 the tight hole.
def Game.gap_of(+t: U32) -> U32:
  Game.pick(U32.is_eq(t, 1), GAP_H_MID(),
    Game.pick(U32.is_eq(t, 2), GAP_H_TIGHT(), GAP_H()))

# Wrap remix of a pair's type: before 16 pillars keep type 0; 16..23
# locks type 1 (mid); 24+ lets the mixer low bit pick type 1 or 2.
def Game.remix_ty(+nseed: U32, +score: U32) -> U32:
  Game.pick((score < 16 : U32), 0,
    Game.pick((score < 24 : U32), 1, (1 + U32.and(nseed, 1) : U32)))

# Wrap remix of a pair's gap top. Stage 0 keeps it within 48 of the
# sibling gap top, stage 1 within 96, both with U32-safe bases; later
# stages use the full mixer span. Every stage clamps to [GAP_TOP_MIN,
# GAP_TOP_MAX] with gy + gap <= 480 (stage 2 clamps with the mid hole,
# stage 3 with the chosen hole).
def Game.remix_gy(+sib: U32, +nseed: U32, +score: U32, +gap: U32) -> U32:
  +base48 = Game.pick((sib < 48 : U32), 0, (sib - 48 : U32))
  +near48 = (base48 + U32.mod(nseed, 96) : U32)
  +base96 = Game.pick((sib < 96 : U32), 0, (sib - 96 : U32))
  +near96 = (base96 + U32.mod(nseed, 192) : U32)
  +full = (GAP_TOP_MIN() + U32.mod(nseed, GAP_SPAN()) : U32)
  +cand = Game.pick((score < 8 : U32), near48,
    Game.pick((score < 16 : U32), near96, full))
  +cgh = Game.pick((score < 16 : U32), gap,
    Game.pick((score < 24 : U32), GAP_H_MID(), gap))
  +limit = (480 - cgh : U32)
  +gcap = Game.pick((limit < GAP_TOP_MAX() : U32), limit, GAP_TOP_MAX())
  +hi = Game.pick((gcap < cand : U32), gcap, cand)
  Game.pick((hi < GAP_TOP_MIN() : U32), GAP_TOP_MIN(), hi)

# Physics step while playing: gravity, travel, staged-speed scroll of
# both pipe pairs, score, and the body inset hitbox test as four AABBs
# per pair: top/bottom shaft in the shaft x band and top/bottom cap in
# the wider cap x band, so the 8px overhang above the top cap or below
# the bottom cap carries no phantom hitbox. Ready and dead freeze the
# bird and the pipes: no gravity, no travel, no scroll, no score. The
# four cloud clusters drift in ready and playing (cx / dx at
# CLOUD_SPD_NEAR, ex / fx at CLOUD_SPD_FAR) and freeze when dead, as
# do the tiny distant birds driven by the wt weather clock, which
# ticks up (+1) while ready or playing and freezes when dead. A
# collision
# only ends the run (mode 2).
def Game.step(+g: Game) -> Game:
  Game{by, sp, dn, px, gy, pc, pt, scored, qx, qy, qc, qt, qscored, seed, mode, score, spd, space_held, r_held, cx, dx, ex, fx, wt} = g
  +play = ((0 < mode) && (mode < 2) : U32)
  +nsp = Game.pick(play, Game.fall(sp, dn), sp)
  +ndn = Game.pickb(play, Game.dir(sp, dn), dn)
  +ny = Game.pick(play, Game.travel(by, nsp, ndn), by)
  +spx = Game.pick(play, (px - spd : U32), px)
  +sqx = Game.pick(play, (qx - spd : U32), qx)
  +awrap = (play && (px < spd) : U32)
  +bwrap = (play && (qx < spd) : U32)
  +npx = Game.pick(awrap, (sqx + PIPE_SPACING() : U32), spx)
  +nqx = Game.pick(bwrap, (spx + PIPE_SPACING() : U32), sqx)
  +wrap = (awrap || bwrap : U32)
  +nseed = Game.pick(wrap, Game.mix(seed), seed)
  +nty = Game.remix_ty(nseed, score)
  +ngap = Game.gap_of(nty)
  +npt = Game.pick(awrap, nty, pt)
  +nqt = Game.pick(bwrap, nty, qt)
  +ngy = Game.pick(awrap, Game.remix_gy(qy, nseed, score, ngap), gy)
  +nqy = Game.pick(bwrap, Game.remix_gy(gy, nseed, score, ngap), qy)
  +npc = Game.pick(awrap, U32.mod((pc + 2 : U32), 5), pc)
  +nqc = Game.pick(bwrap, U32.mod((qc + 2 : U32), 5), qc)
  +prx = Game.pipex(npx)
  +prw = Game.pipew(npx)
  +qrx = Game.pipex(nqx)
  +qrw = Game.pipew(nqx)
  +pcx = Game.capx(npx)
  +pcw = Game.capw(npx)
  +qcx = Game.capx(nqx)
  +qcw = Game.capw(nqx)
  +inx0 = (BIRD_X() + HIT_PAD() : U32)
  +inx1 = ((BIRD_X() + BODY_W() : U32) - HIT_PAD() : U32)
  +iny0 = (ny + HIT_PAD() : U32)
  +iny1 = ((ny + BODY_H() : U32) - HIT_PAD() : U32)
  +gapa = Game.gap_of(npt)
  +gapb = Game.gap_of(nqt)
  +aby = (ngy + gapa : U32)
  +bby = (nqy + gapb : U32)
  +sh_a = ((inx0 < (prx + prw : U32)) && (prx < inx1) : U32)
  +sh_b = ((inx0 < (qrx + qrw : U32)) && (qrx < inx1) : U32)
  +cp_a = ((inx0 < (pcx + pcw : U32)) && (pcx < inx1) : U32)
  +cp_b = ((inx0 < (qcx + qcw : U32)) && (qcx < inx1) : U32)
  +hit_a = ((sh_a && (iny0 < ngy))
    || (sh_a && (aby < iny1))
    || (cp_a && (iny0 < ngy) && ((ngy - PIPE_CAP_H() : U32) < iny1))
    || (cp_a && (iny0 < (aby + PIPE_CAP_H() : U32)) && (aby < iny1))
    : U32)
  +hit_b = ((sh_b && (iny0 < nqy))
    || (sh_b && (bby < iny1))
    || (cp_b && (iny0 < nqy) && ((nqy - PIPE_CAP_H() : U32) < iny1))
    || (cp_b && (iny0 < (bby + PIPE_CAP_H() : U32)) && (bby < iny1))
    : U32)
  +hit = (hit_a || hit_b : U32)
  +fallen = (hit || (ny < 1) || (496 <= ny) : U32)
  +dead = (play && fallen : U32)
  +nmode = Game.pick(dead, 2, mode)
  +pass_a = (play && Bool.not(scored) && (npx < BIRD_X()) : U32)
  +pass_b = (play && Bool.not(qscored) && (nqx < BIRD_X()) : U32)
  +s1 = Game.pick(pass_a, (score + 1 : U32), score)
  +nscore = Game.pick(pass_b, (s1 + 1 : U32), s1)
  +nscored = Game.pickb(awrap, False{}, Game.pickb(pass_a, True{}, scored))
  +nqscored = Game.pickb(bwrap, False{}, Game.pickb(pass_b, True{}, qscored))
  +nspd = Game.pick(play, Game.speed_of(nscore), spd)
  +drift = (mode < 2 : U32)
  +ncx = Game.pick((drift && (cx < CLOUD_SPD_NEAR()) : U32), 600,
    Game.pick(drift, (cx - CLOUD_SPD_NEAR() : U32), cx))
  +ndx = Game.pick((drift && (dx < CLOUD_SPD_NEAR()) : U32), 600,
    Game.pick(drift, (dx - CLOUD_SPD_NEAR() : U32), dx))
  +nex = Game.pick((drift && (ex < CLOUD_SPD_FAR()) : U32), 600,
    Game.pick(drift, (ex - CLOUD_SPD_FAR() : U32), ex))
  +nfx = Game.pick((drift && (fx < CLOUD_SPD_FAR()) : U32), 600,
    Game.pick(drift, (fx - CLOUD_SPD_FAR() : U32), fx))
  +nwt = Game.pick(drift, (wt + 1 : U32), wt)
  Game{ny, nsp, ndn, npx, ngy, npc, npt, nscored, nqx, nqy, nqc, nqt, nqscored, nseed, nmode, nscore, nspd, space_held, r_held, ncx, ndx, nex, nfx, nwt}

def Game.tick(events: List<Event>, g: Game) -> IO(Maybe<Game>):
  IO.pure(Maybe<Game>, Maybe.bind(&1, Game, Game, Game.events(events, g),
    g2 => Some{Game.step(g2)}))

# Draw
# ----

def Game.inside(
  +x0: U32, +y0: U32, +s: U32, +rx: U32, +ry: U32, rw: U32, rh: U32
) -> Bool:
  ((rx <= x0) && (x0 + s <= rx + rw) && (ry <= y0) && (y0 + s <= ry + rh) : U32)

def Game.outside(
  +x0: U32, +y0: U32, +s: U32, +rx: U32, +ry: U32, rw: U32, rh: U32
) -> Bool:
  ((x0 + s <= rx) || (rx + rw <= x0) || (y0 + s <= ry) || (ry + rh <= y0) : U32)

# Axis-aligned filled rect test for block letters, bird rects, and
# panels: half-open [rx, rx + rw) x [ry, ry + rh).
def Game.bar(+x: U32, +y: U32, +rx: U32, +ry: U32, +rw: U32, +rh: U32) -> Bool:
  ((rx <= x) && (x < rx + rw) && (ry <= y) && (y < ry + rh) : U32)

# Block glyphs on a 5x7 unit grid as unions of axis-aligned bars:
# F L A P Y S C E. Outside a glyph reads as background.
def Game.glyph_f(+x: U32, +y: U32) -> Bool:
  Game.bar(x, y, 0, 0, 1, 7) || Game.bar(x, y, 0, 0, 5, 1)
    || Game.bar(x, y, 0, 3, 4, 1)

def Game.glyph_l(+x: U32, +y: U32) -> Bool:
  Game.bar(x, y, 0, 0, 1, 7) || Game.bar(x, y, 0, 6, 5, 1)

def Game.glyph_a(+x: U32, +y: U32) -> Bool:
  Game.bar(x, y, 0, 0, 1, 7) || Game.bar(x, y, 4, 0, 1, 7)
    || Game.bar(x, y, 0, 0, 5, 1) || Game.bar(x, y, 0, 3, 5, 1)

def Game.glyph_p(+x: U32, +y: U32) -> Bool:
  Game.bar(x, y, 0, 0, 1, 7) || Game.bar(x, y, 4, 0, 1, 4)
    || Game.bar(x, y, 0, 0, 5, 1) || Game.bar(x, y, 0, 3, 5, 1)

def Game.glyph_y(+x: U32, +y: U32) -> Bool:
  Game.bar(x, y, 0, 0, 1, 3) || Game.bar(x, y, 4, 0, 1, 3)
    || Game.bar(x, y, 1, 2, 3, 1) || Game.bar(x, y, 2, 2, 1, 5)

def Game.glyph_s(+x: U32, +y: U32) -> Bool:
  Game.bar(x, y, 0, 0, 5, 1) || Game.bar(x, y, 0, 0, 1, 4)
    || Game.bar(x, y, 0, 3, 5, 1) || Game.bar(x, y, 4, 3, 1, 4)
    || Game.bar(x, y, 0, 6, 5, 1)

def Game.glyph_c(+x: U32, +y: U32) -> Bool:
  Game.bar(x, y, 0, 0, 5, 1) || Game.bar(x, y, 0, 0, 1, 7)
    || Game.bar(x, y, 0, 6, 5, 1)

def Game.glyph_e(+x: U32, +y: U32) -> Bool:
  Game.bar(x, y, 0, 0, 5, 1) || Game.bar(x, y, 0, 3, 5, 1)
    || Game.bar(x, y, 0, 6, 5, 1) || Game.bar(x, y, 0, 0, 1, 7)

def Game.glyph_g(+x: U32, +y: U32) -> Bool:
  Game.bar(x, y, 0, 0, 5, 1) || Game.bar(x, y, 0, 0, 1, 7)
    || Game.bar(x, y, 0, 6, 5, 1) || Game.bar(x, y, 4, 3, 1, 4)
    || Game.bar(x, y, 2, 3, 3, 1)

def Game.glyph_m(+x: U32, +y: U32) -> Bool:
  Game.bar(x, y, 0, 0, 1, 7) || Game.bar(x, y, 4, 0, 1, 7)
    || Game.bar(x, y, 1, 1, 1, 1) || Game.bar(x, y, 3, 1, 1, 1)
    || Game.bar(x, y, 2, 2, 1, 2)

def Game.glyph_o(+x: U32, +y: U32) -> Bool:
  Game.bar(x, y, 0, 0, 5, 1) || Game.bar(x, y, 0, 6, 5, 1)
    || Game.bar(x, y, 0, 0, 1, 7) || Game.bar(x, y, 4, 0, 1, 7)

def Game.glyph_v(+x: U32, +y: U32) -> Bool:
  Game.bar(x, y, 0, 0, 1, 4) || Game.bar(x, y, 4, 0, 1, 4)
    || Game.bar(x, y, 1, 4, 1, 2) || Game.bar(x, y, 3, 4, 1, 2)
    || Game.bar(x, y, 2, 6, 1, 1)

def Game.glyph_r(+x: U32, +y: U32) -> Bool:
  Game.bar(x, y, 0, 0, 1, 7) || Game.bar(x, y, 0, 0, 5, 1)
    || Game.bar(x, y, 4, 0, 1, 4) || Game.bar(x, y, 0, 3, 5, 1)
    || Game.bar(x, y, 2, 4, 1, 1) || Game.bar(x, y, 3, 5, 1, 1)
    || Game.bar(x, y, 4, 6, 1, 1)

def Game.glyph_t(+x: U32, +y: U32) -> Bool:
  Game.bar(x, y, 0, 0, 5, 1) || Game.bar(x, y, 2, 1, 1, 6)

def Game.glyph_x(+x: U32, +y: U32) -> Bool:
  Game.bar(x, y, 0, 0, 1, 2) || Game.bar(x, y, 4, 0, 1, 2)
    || Game.bar(x, y, 1, 2, 1, 1) || Game.bar(x, y, 3, 2, 1, 1)
    || Game.bar(x, y, 2, 3, 1, 1) || Game.bar(x, y, 1, 4, 1, 1)
    || Game.bar(x, y, 3, 4, 1, 1) || Game.bar(x, y, 0, 5, 1, 2)
    || Game.bar(x, y, 4, 5, 1, 2)

def Game.glyph_i(+x: U32, +y: U32) -> Bool:
  Game.bar(x, y, 0, 0, 5, 1) || Game.bar(x, y, 0, 6, 5, 1)
    || Game.bar(x, y, 2, 1, 1, 5)

# Glyph lookup: code 0..15 selects F L A P Y S C E G M O V R T X I;
# higher codes are blank (word gaps).
def Game.letter(+c: U32, +x: U32, +y: U32) -> Bool:
  Game.pickb(U32.is_eq(c, 0), Game.glyph_f(x, y),
    Game.pickb(U32.is_eq(c, 1), Game.glyph_l(x, y),
      Game.pickb(U32.is_eq(c, 2), Game.glyph_a(x, y),
        Game.pickb(U32.is_eq(c, 3), Game.glyph_p(x, y),
          Game.pickb(U32.is_eq(c, 4), Game.glyph_y(x, y),
            Game.pickb(U32.is_eq(c, 5), Game.glyph_s(x, y),
              Game.pickb(U32.is_eq(c, 6), Game.glyph_c(x, y),
                Game.pickb(U32.is_eq(c, 7), Game.glyph_e(x, y),
                  Game.pickb(U32.is_eq(c, 8), Game.glyph_g(x, y),
                    Game.pickb(U32.is_eq(c, 9), Game.glyph_m(x, y),
                      Game.pickb(U32.is_eq(c, 10), Game.glyph_o(x, y),
                        Game.pickb(U32.is_eq(c, 11), Game.glyph_v(x, y),
                          Game.pickb(U32.is_eq(c, 12), Game.glyph_r(x, y),
                            Game.pickb(U32.is_eq(c, 13), Game.glyph_t(x, y),
                              Game.pickb(U32.is_eq(c, 14), Game.glyph_x(x, y),
                                Game.pickb(U32.is_eq(c, 15), Game.glyph_i(x, y),
                                  False{}))))))))))))))))

# Glyph codes for the FLAPPY title (F L A P P Y).
def Game.title_code(+i: U32) -> U32:
  Game.pick(U32.is_eq(i, 1), 1,
    Game.pick(U32.is_eq(i, 2), 2,
      Game.pick(U32.is_eq(i, 3), 3,
        Game.pick(U32.is_eq(i, 4), 3,
          Game.pick(U32.is_eq(i, 5), 4, 0)))))

# Glyph codes for the SPACE start panel (S P A C E).
def Game.space_code(+i: U32) -> U32:
  Game.pick(U32.is_eq(i, 1), 3,
    Game.pick(U32.is_eq(i, 2), 2,
      Game.pick(U32.is_eq(i, 3), 6,
        Game.pick(U32.is_eq(i, 4), 7, 5))))

# Title FLAPPY: six 5x7 glyphs at 8px per unit on a 48px pitch from
# (116, 48), in the upper third. Glyph gaps read as background.
def Game.title(+x: U32, +y: U32) -> Bool:
  +tx = Game.pick((x < 116 : U32), 0, (x - 116 : U32))
  +ty = Game.pick((y < 48 : U32), 0, (y - 48 : U32))
  +gx = U32.mod(tx, 48)
  +code = Game.title_code(U32.div(tx, 48))
  ((116 <= x) && (x < 396) && (48 <= y) && (y < 104) && (gx < 40)
    : U32)
    && Game.letter(code, U32.div(gx, 8), U32.div(ty, 8))

# Start panel text SPACE: five 5x7 glyphs at 5px per unit on a 30px
# pitch (a 150px span) from (181, 348), centered in the 200x56 start
# panel at (156, 338). Glyph gaps read as the start bar.
def Game.space_word(+x: U32, +y: U32) -> Bool:
  +tx = Game.pick((x < 181 : U32), 0, (x - 181 : U32))
  +ty = Game.pick((y < 348 : U32), 0, (y - 348 : U32))
  +gx = U32.mod(tx, 30)
  +code = Game.space_code(U32.div(tx, 30))
  ((181 <= x) && (tx < 150) && (348 <= y) && (ty < 35) && (gx < 25)
    : U32)
    && Game.letter(code, U32.div(gx, 5), U32.div(ty, 5))

# Glyph codes for the GAME OVER banner (G A M E _ O V E R).
def Game.over_code(+i: U32) -> U32:
  Game.pick(U32.is_eq(i, 0), 8,
    Game.pick(U32.is_eq(i, 1), 2,
      Game.pick(U32.is_eq(i, 2), 9,
        Game.pick(U32.is_eq(i, 3), 7,
          Game.pick(U32.is_eq(i, 4), 16,
            Game.pick(U32.is_eq(i, 5), 10,
              Game.pick(U32.is_eq(i, 6), 11,
                Game.pick(U32.is_eq(i, 7), 7, 12))))))))

# Glyph codes for the RETRY panel row (R E T R Y).
def Game.retry_code(+i: U32) -> U32:
  Game.pick(U32.is_eq(i, 0), 12,
    Game.pick(U32.is_eq(i, 1), 7,
      Game.pick(U32.is_eq(i, 2), 13,
        Game.pick(U32.is_eq(i, 3), 12, 4))))

# Glyph codes for the short R retry hint under the RETRY row: just R
# (the dead screen restarts on R only, never on Space).
def Game.rhint_code(+i: U32) -> U32:
  12

# Glyph codes for the EXIT panel row (E X I T).
def Game.exit_code(+i: U32) -> U32:
  Game.pick(U32.is_eq(i, 0), 7,
    Game.pick(U32.is_eq(i, 1), 14,
      Game.pick(U32.is_eq(i, 2), 15, 13)))

# Glyph codes naming the Esc key: E S C.
def Game.esc_code(+i: U32) -> U32:
  Game.pick(U32.is_eq(i, 0), 7,
    Game.pick(U32.is_eq(i, 1), 5, 6))

# Word id selects the per-slot glyph code table.
def Game.text_code(+w: U32, +i: U32) -> U32:
  Game.pick(U32.is_eq(w, 0), Game.over_code(i),
    Game.pick(U32.is_eq(w, 1), Game.retry_code(i),
      Game.pick(U32.is_eq(w, 2), Game.rhint_code(i),
        Game.pick(U32.is_eq(w, 3), Game.exit_code(i),
          Game.esc_code(i)))))

# One dead-screen text row: 5x7 glyphs at 5px per unit on a 30px
# pitch from (ox, oy), wd px wide. Slot gaps read as the world behind.
def Game.text(+w: U32, +ox: U32, +oy: U32, +wd: U32, +x: U32, +y: U32) -> Bool:
  +tx = Game.pick((x < ox : U32), 0, (x - ox : U32))
  +ty = Game.pick((y < oy : U32), 0, (y - oy : U32))
  +gx = U32.mod(tx, 30)
  +code = Game.text_code(w, U32.div(tx, 30))
  ((ox <= x) && (tx < wd) && (oy <= y) && (ty < 35) && (gx < 25)
    : U32)
    && Game.letter(code, U32.div(gx, 5), U32.div(ty, 5))

# One compact dead-screen hint row: 5x7 glyphs at 4px per unit on a
# 24px pitch from (ox, oy), wd px wide. Used for the short R / Esc
# hints that sit inside the shrunk RETRY / EXIT panels under the
# word rows. Slot gaps read as the world behind.
def Game.text4(+w: U32, +ox: U32, +oy: U32, +wd: U32, +x: U32, +y: U32) -> Bool:
  +tx = Game.pick((x < ox : U32), 0, (x - ox : U32))
  +ty = Game.pick((y < oy : U32), 0, (y - oy : U32))
  +gx = U32.mod(tx, 24)
  +code = Game.text_code(w, U32.div(tx, 24))
  ((ox <= x) && (tx < wd) && (oy <= y) && (ty < 28) && (gx < 20)
    : U32)
    && Game.letter(code, U32.div(gx, 4), U32.div(ty, 4))

# One 7-segment segment: bit 0 is a (top), 1 b, 2 c, 3 d, 4 e, 5 f,
# 6 g (middle).
def Game.seg(+m: U32, n: Nat) -> Bool:
  U32.is_eq(U32.and(U32.shrn(m, n), 1), 1)

# One 24x40 7-segment digit cell: segments as axis-aligned bars.
def Game.digit(+m: U32, +x: U32, +y: U32) -> Bool:
  +a = Game.seg(m, 0n)
  +b = Game.seg(m, 1n)
  +c = Game.seg(m, 2n)
  +d = Game.seg(m, 3n)
  +e = Game.seg(m, 4n)
  +f = Game.seg(m, 5n)
  +g = Game.seg(m, 6n)
  (a && Game.bar(x, y, 6, 0, 12, 6)) || (b && Game.bar(x, y, 18, 6, 6, 11))
    || (c && Game.bar(x, y, 18, 23, 6, 11)) || (d && Game.bar(x, y, 6, 34, 12, 6))
    || (e && Game.bar(x, y, 0, 23, 6, 11)) || (f && Game.bar(x, y, 0, 6, 6, 11))
    || (g && Game.bar(x, y, 4, 17, 16, 6))

# Segment mask for one decimal digit (bits 0..6 = a b c d e f g).
def Game.digit_mask(+d: U32) -> U32:
  Game.pick(U32.is_eq(d, 0), 63,
    Game.pick(U32.is_eq(d, 1), 6,
      Game.pick(U32.is_eq(d, 2), 91,
        Game.pick(U32.is_eq(d, 3), 79,
          Game.pick(U32.is_eq(d, 4), 102,
            Game.pick(U32.is_eq(d, 5), 109,
              Game.pick(U32.is_eq(d, 6), 125,
                Game.pick(U32.is_eq(d, 7), 7,
                  Game.pick(U32.is_eq(d, 8), 127, 111)))))))))

# One digit at cell origin (ox, oy); clamped coords fall outside it.
def Game.digit_at(+m: U32, +ox: U32, +oy: U32, +x: U32, +y: U32) -> Bool:
  +lx = Game.pick((x < ox : U32), 24, (x - ox : U32))
  +ly = Game.pick((y < oy : U32), 40, (y - oy : U32))
  Game.digit(m, lx, ly)

# One compact 14x22 7-segment digit cell for the in-play HUD:
# segments as thin axis-aligned bars, bits as in Game.digit.
def Game.digit_c(+m: U32, +x: U32, +y: U32) -> Bool:
  +a = Game.seg(m, 0n)
  +b = Game.seg(m, 1n)
  +c = Game.seg(m, 2n)
  +d = Game.seg(m, 3n)
  +e = Game.seg(m, 4n)
  +f = Game.seg(m, 5n)
  +g = Game.seg(m, 6n)
  (a && Game.bar(x, y, 3, 0, 8, 3)) || (b && Game.bar(x, y, 11, 3, 3, 7))
    || (c && Game.bar(x, y, 11, 12, 3, 7)) || (d && Game.bar(x, y, 3, 19, 8, 3))
    || (e && Game.bar(x, y, 0, 12, 3, 7)) || (f && Game.bar(x, y, 0, 3, 3, 7))
    || (g && Game.bar(x, y, 2, 9, 10, 3))

# One compact digit at cell origin (ox, oy); clamped coords fall
# outside the 14x22 cell.
def Game.digit_c_at(+m: U32, +ox: U32, +oy: U32, +x: U32, +y: U32) -> Bool:
  +lx = Game.pick((x < ox : U32), 14, (x - ox : U32))
  +ly = Game.pick((y < oy : U32), 22, (y - oy : U32))
  Game.digit_c(m, lx, ly)

# Dead-screen score: three 7-segment digits of score % 1000 computed
# here in the view (hundreds, tens, ones); no extra Game fields.
def Game.dead_score(+x: U32, +y: U32, +score: U32) -> Bool:
  +s = U32.mod(score, 1000)
  +d0 = U32.mod(s, 10)
  +d1 = U32.mod(U32.div(s, 10), 10)
  +d2 = U32.div(s, 100)
  Game.digit_at(Game.digit_mask(d2), 212, 108, x, y)
    || Game.digit_at(Game.digit_mask(d1), 244, 108, x, y)
    || Game.digit_at(Game.digit_mask(d0), 276, 108, x, y)

# In-play HUD box: a named 72x32 box at (220, 8) with a thin 2px
# frame, an inner face, and three compact digit cells.
def HUD_X() -> U32: 220
def HUD_Y() -> U32: 8
def HUD_W() -> U32: 72
def HUD_H() -> U32: 32

# In-play HUD score: three compact 14x22 7-segment digits of
# score % 1000 inside the HUD face, computed here in the view; no
# extra Game fields. The compact cells fit wholly inside the face and
# never clip into the sky (the dead overlay keeps 24x40 cells).
def Game.hud_score(+x: U32, +y: U32, +score: U32) -> Bool:
  +s = U32.mod(score, 1000)
  +d0 = U32.mod(s, 10)
  +d1 = U32.mod(U32.div(s, 10), 10)
  +d2 = U32.div(s, 100)
  Game.digit_c_at(Game.digit_mask(d2), 232, 13, x, y)
    || Game.digit_c_at(Game.digit_mask(d1), 249, 13, x, y)
    || Game.digit_c_at(Game.digit_mask(d0), 266, 13, x, y)

# Background atmosphere (decorative only, never colliding): three sky
# bands covering y 0..496 (a fair trio, or the darker STORM trio when
# Game.storm holds), a static sun cluster around (420, 64),
# mountains and hills sitting on the ground line behind the pipes, the
# sea band y 480..496 with its lighter foam line y 480..484, and two
# green field patches on the ground line. The ground is two-tone:
# grass y 496..504 over dirt y 504..512, with floor death strictly at
# y >= 496 (the sea never changes it).
def SKY_TOP() -> U32: 4223160
def SKY_MID() -> U32: 6856920
def SKY_PALE() -> U32: 11589872
# Darker storm sky palettes: the same three full-width uniform bands
# (still quadtree-flat), used whenever Game.storm holds.
def STORM_TOP() -> U32: 2243168
def STORM_MID() -> U32: 3428472
def STORM_PALE() -> U32: 4744840
def HILLS_TINT() -> U32: 4751480
# Mountains: darker than HILLS_TINT.
def MOUNT_TINT() -> U32: 2969685
# Sea band y 480..496 and its lighter foam / shore line y 480..484.
def SEA_BLUE() -> U32: 3176648
def SEA_FOAM() -> U32: 9885931
# Green field patches on the ground line.
def FIELD_GREEN() -> U32: 7913050
def GRASS_GREEN() -> U32: 4761664
def DIRT_BROWN() -> U32: 8937528
def CLOUD_WHITE() -> U32: 16777215
# Tiny distant bird silhouettes: a dark slate tint.
def BIRD_TINT() -> U32: 4476004

# Sun: a static cluster of filled 8px squares around (420, 64): a
# yellow (COLOR_4) 2x2 core with four orange-red (COLOR_1) ray squares
# (north, south, west, east). Decorative: no hitbox.
def Game.sun_core(+x: U32, +y: U32) -> Bool:
  Game.bar(x, y, 412, 56, 8, 8) || Game.bar(x, y, 420, 56, 8, 8)
    || Game.bar(x, y, 412, 64, 8, 8) || Game.bar(x, y, 420, 64, 8, 8)

def Game.sun_ray(+x: U32, +y: U32) -> Bool:
  Game.bar(x, y, 416, 40, 8, 8) || Game.bar(x, y, 416, 80, 8, 8)
    || Game.bar(x, y, 396, 60, 8, 8) || Game.bar(x, y, 436, 60, 8, 8)

# Mountains: two taller stepped ranges (left and right) of static
# quads whose bases sit on the ground line y 496, drawn in a darker
# tint than the hills behind the sea and the hills. Decorative: no
# hitbox.
def Game.mountains(+x: U32, +y: U32) -> Bool:
  Game.bar(x, y, 0, 432, 64, 64) || Game.bar(x, y, 64, 408, 64, 88)
    || Game.bar(x, y, 128, 424, 64, 72) || Game.bar(x, y, 192, 448, 64, 48)
    || Game.bar(x, y, 288, 440, 64, 56) || Game.bar(x, y, 352, 400, 64, 96)
    || Game.bar(x, y, 416, 384, 64, 112) || Game.bar(x, y, 480, 424, 32, 72)

# Distant hills: two static stepped silhouettes whose bases sit on the
# ground line y 496, drawn behind the pipes.
def Game.hills(+x: U32, +y: U32) -> Bool:
  Game.bar(x, y, 80, 448, 32, 16) || Game.bar(x, y, 48, 464, 96, 16)
    || Game.bar(x, y, 16, 480, 160, 16) || Game.bar(x, y, 400, 448, 32, 16)
    || Game.bar(x, y, 368, 464, 96, 16) || Game.bar(x, y, 336, 480, 160, 16)

# Sea: the named blue water band y 480..496 across the full width 512,
# with the lighter foam / shore line y 480..484 on top. Purely
# decorative: floor death stays strictly at y >= 496.
def Game.sea(+x: U32, +y: U32) -> Bool:
  Game.bar(x, y, 0, 480, 512, 16)

def Game.foam(+x: U32, +y: U32) -> Bool:
  Game.bar(x, y, 0, 480, 512, 4)

# Fields: two named green patches sitting on the ground line y 496
# (left and right, never the full width), in front of the sea and the
# mountains and behind the pipes. Decorative: no hitbox.
def Game.fields(+x: U32, +y: U32) -> Bool:
  Game.bar(x, y, 24, 484, 128, 12) || Game.bar(x, y, 360, 484, 128, 12)

# One cloud cluster: CLOUD_W wide in [right - CLOUD_W, right], three
# filled quads (crown over middle slab over bottom slab) around a y
# origin in the upper third. `u` is the distance left of the
# cluster's right edge with a U32-safe clamp, so the cluster slides
# cleanly out of the window. Decorative: no hitbox.
def Game.cloud(+x: U32, +y: U32, +rx: U32, +oy: U32) -> Bool:
  +u = Game.pick((rx < x : U32), 0, (rx - x : U32))
  ((x < rx) && (u < CLOUD_W()) : U32)
    && (Game.bar(u, y, 24, oy, 32, 8) || Game.bar(u, y, 8, (oy + 8 : U32), 64, 16)
      || Game.bar(u, y, 0, (oy + 24 : U32), CLOUD_W(), 8))

# Tiny distant bird right edge from the weather clock `wt`: the
# silhouette slides left one px per tick (slower than the near clouds)
# with its right edge wrapping to 600 once it leaves the window;
# index `i` picks the phase (0 and 300) so the two silhouettes never
# lock together. Frozen when dead because `wt` freezes. Wrap-safe:
# 600 - (wt + phase) % 600 is always in 1..600. Decorative: no
# hitbox.
def Game.birdx(+wt: U32, +i: U32) -> U32:
  +ph = Game.pick(U32.is_eq(i, 0), 0, 300)
  (600 - U32.mod((wt + ph : U32), 600) : U32)

# One tiny distant bird silhouette: a 6x3 body with a 4x2 wing in the
# 12-wide slot [right - 12, right] at a y origin in the upper third.
# `u` is the distance left of the bird's right edge with a U32-safe
# clamp, so the silhouette slides cleanly out of the window.
# Decorative: no hitbox.
def Game.bird(+x: U32, +y: U32, +rx: U32, +oy: U32) -> Bool:
  +u = Game.pick((rx < x : U32), 0, (rx - x : U32))
  ((x < rx) && (u < 12) : U32)
    && (Game.bar(u, y, 3, oy, 6, 3) || Game.bar(u, y, 4, (oy + 2 : U32), 4, 2))

# Storm maths over the four cloud right edges. `span3` is the spread
# (max - min) of three edges with U32-safe min/max. A storm brews when
# at least one triple of the four edges clusters within STORM_SPAN.
def STORM_SPAN() -> U32: 160

def Game.min2(+a: U32, +b: U32) -> U32:
  Game.pick((a < b : U32), a, b)

def Game.max2(+a: U32, +b: U32) -> U32:
  Game.pick((a < b : U32), b, a)

def Game.min3(+a: U32, +b: U32, +c: U32) -> U32:
  Game.min2(a, Game.min2(b, c))

def Game.max3(+a: U32, +b: U32, +c: U32) -> U32:
  Game.max2(a, Game.max2(b, c))

def Game.span3(+a: U32, +b: U32, +c: U32) -> U32:
  (Game.max3(a, b, c) - Game.min3(a, b, c) : U32)

def Game.storm(+cx: U32, +dx: U32, +ex: U32, +fx: U32) -> Bool:
  ((Game.span3(cx, dx, ex) <= STORM_SPAN())
    || (Game.span3(cx, dx, fx) <= STORM_SPAN())
    || (Game.span3(cx, ex, fx) <= STORM_SPAN())
    || (Game.span3(dx, ex, fx) <= STORM_SPAN()) : U32)

# Five named distinct pillar colors: green, orange-red, blue, magenta,
# yellow.
def COLOR_0() -> U32: 3189308
def COLOR_1() -> U32: 14703136
def COLOR_2() -> U32: 2646240
def COLOR_3() -> U32: 13121736
def COLOR_4() -> U32: 15257664

# Pillar color lookup by pipe pair color index 0..4.
def Game.pillar_color(+c: U32) -> U32:
  Game.pick(U32.is_eq(c, 0), COLOR_0(),
    Game.pick(U32.is_eq(c, 1), COLOR_1(),
      Game.pick(U32.is_eq(c, 2), COLOR_2(),
        Game.pick(U32.is_eq(c, 3), COLOR_3(), COLOR_4()))))

# In-play HUD colors: three distinct contrasting tones -- orange-red
# frame, dark face, white digits (never white-on-white).
def HUD_FRAME() -> U32: COLOR_1()
def HUD_FACE() -> U32: 2109520
def HUD_DIGIT() -> U32: 16777215

# Ready / dead panel fills: colorful and each distinct from the light
# text over it -- blue start panel, green RETRY panel (R hint), red
# EXIT panel (Esc hint), and a dark banner behind the dead score.
def PANEL_BLUE() -> U32: 2382004
def PANEL_GREEN() -> U32: 2919504
def PANEL_RED() -> U32: 11548728
def PANEL_DARK() -> U32: 2109520

# Pixel colors, front to back: dead UI (banner, digits, panels) over
# the frozen world, bird rects (wing over beak over body), ready UI
# (title, SPACE text over the start bar), the in-play HUD (frame,
# face, 3-digit score), each pipe pair
# in its pillar color (shaft and caps alike; collision ignores color),
# the tiny distant birds and the four cloud clusters (behind pipes),
# the sun, the field patches,
# the sea band (foam over water), the hills, the mountains, the
# two-tone ground (grass over dirt), and the three sky bands (the
# darker STORM trio whenever Game.storm holds). The
# background is decorative: no hitboxes.
def Game.color(+x: U32, +y: U32, +g: Game) -> U32:
  Game{by, sp, dn, px, gy, pc, pt, scored, qx, qy, qc, qt, qscored, seed, mode, score, spd, space_held, r_held, cx, dx, ex, fx, wt} = g
  +ready = (mode < 1 : U32)
  +dead = U32.is_eq(mode, 2)
  +hud_on = U32.is_eq(mode, 1)
  +ga = Game.gap_of(pt)
  +gb = Game.gap_of(qt)
  +ui_text = Game.pickb(ready, Game.title(x, y) || Game.space_word(x, y), False{})
  +ui_bar = Game.pickb(ready, Game.bar(x, y, 156, 338, 200, 56), False{})
  +over_text = Game.pickb(dead,
    Game.text(0, 124, 56, 265, x, y) || Game.text(1, 183, 218, 145, x, y)
      || Game.text4(2, 246, 253, 20, x, y) || Game.text(3, 199, 330, 115, x, y)
      || Game.text4(4, 222, 365, 68, x, y),
    False{})
  +over_digit = Game.pickb(dead, Game.dead_score(x, y, score), False{})
  +over_banner = Game.pickb(dead, Game.bar(x, y, 208, 104, 96, 48), False{})
  +over_retry = Game.pickb(dead, Game.bar(x, y, 169, 216, 174, 66), False{})
  +over_exit = Game.pickb(dead, Game.bar(x, y, 169, 328, 174, 66), False{})
  +hud_digit = Game.pickb(hud_on, Game.hud_score(x, y, score), False{})
  +hud_face = Game.pickb(hud_on,
    Game.bar(x, y, (HUD_X() + 2 : U32), (HUD_Y() + 2 : U32), 68, 28), False{})
  +hud_frame = Game.pickb(hud_on,
    Game.bar(x, y, HUD_X(), HUD_Y(), HUD_W(), HUD_H()), False{})
  +storm = Game.storm(cx, dx, ex, fx)
  +sky_top = Game.pick(storm, STORM_TOP(), SKY_TOP())
  +sky_mid = Game.pick(storm, STORM_MID(), SKY_MID())
  +sky_pale = Game.pick(storm, STORM_PALE(), SKY_PALE())
  Game.pick(over_text, 16777215,
    Game.pick(over_digit, 16777215,
      Game.pick(over_exit, PANEL_RED(),
        Game.pick(over_retry, PANEL_GREEN(),
          Game.pick(over_banner, PANEL_DARK(),
  Game.pick(Game.bar(x, y, (BIRD_X() + 6 : U32), (by + 8 : U32), 10, 6), 16777215,
    Game.pick(Game.bar(x, y, (BIRD_X() + BODY_W() : U32), (by + 6 : U32), 8, 6), 15759392,
      Game.pick(Game.bar(x, y, BIRD_X(), by, BODY_W(), BODY_H()), 16440390,
        Game.pick(ui_text, 16777215,
          Game.pick(ui_bar, PANEL_BLUE(),
            Game.pick(hud_digit, HUD_DIGIT(),
              Game.pick(hud_face, HUD_FACE(),
                Game.pick(hud_frame, HUD_FRAME(),
                Game.pick(Game.inside(x, y, 1, Game.pipex(px), 0, Game.pipew(px), gy)
                || Game.inside(x, y, 1, Game.capx(px), (gy - PIPE_CAP_H() : U32),
                  Game.capw(px), PIPE_CAP_H())
                || Game.inside(x, y, 1, Game.pipex(px), (gy + ga : U32),
                  Game.pipew(px), (496 - (gy + ga : U32) : U32))
                || Game.inside(x, y, 1, Game.capx(px), (gy + ga : U32),
                  Game.capw(px), PIPE_CAP_H()),
                Game.pillar_color(pc),
                Game.pick(Game.inside(x, y, 1, Game.pipex(qx), 0, Game.pipew(qx), qy)
                  || Game.inside(x, y, 1, Game.capx(qx), (qy - PIPE_CAP_H() : U32),
                    Game.capw(qx), PIPE_CAP_H())
                  || Game.inside(x, y, 1, Game.pipex(qx), (qy + gb : U32),
                    Game.pipew(qx), (496 - (qy + gb : U32) : U32))
                  || Game.inside(x, y, 1, Game.capx(qx), (qy + gb : U32),
                    Game.capw(qx), PIPE_CAP_H()),
                  Game.pillar_color(qc),
                  Game.pick(Game.bird(x, y, Game.birdx(wt, 0), 48)
                    || Game.bird(x, y, Game.birdx(wt, 1), 144), BIRD_TINT(),
                  Game.pick(Game.cloud(x, y, cx, 56) || Game.cloud(x, y, dx, 104)
                    || Game.cloud(x, y, ex, 16) || Game.cloud(x, y, fx, 152),
                    CLOUD_WHITE(),
                    Game.pick(Game.sun_core(x, y), COLOR_4(),
                      Game.pick(Game.sun_ray(x, y), COLOR_1(),
                        Game.pick(Game.fields(x, y), FIELD_GREEN(),
                          Game.pick(Game.foam(x, y), SEA_FOAM(),
                            Game.pick(Game.sea(x, y), SEA_BLUE(),
                              Game.pick(Game.hills(x, y), HILLS_TINT(),
                                Game.pick(Game.mountains(x, y), MOUNT_TINT(),
                          Game.pick(Game.bar(x, y, 0, 496, 512, 8), GRASS_GREEN(),
                            Game.pick(Game.bar(x, y, 0, 504, 512, 8), DIRT_BROWN(),
                              Game.pick(Game.bar(x, y, 0, 0, 512, 256), sky_top,
                                Game.pick(Game.bar(x, y, 0, 256, 512, 128), sky_mid,
                                  sky_pale))))))))))))))))))))))))))))

# True when the whole [x0, y0, s] cell is one flat color. The
# in-play HUD [220, 8, 72, 32] (2px frame, face, compact 3-digit
# score), the
# ready UI [116, 48, 280, 346] (FLAPPY title
# plus the 200x56 SPACE start panel), the dead UI [124, 56, 265, 338]
# (GAME OVER banner, score digits, RETRY / EXIT panels with their
# R / Esc hints), the whole bird
# [128, by, 32, 16] (body + beak + wing), the tiny distant birds
# [right - 12, right] x [48, 52) and x [144, 148), the four cloud
# clusters [right - CLOUD_W, right] x [16, 48), x [56, 88), x [104,
# 136) and x [152, 184), the sun
# [396, 40, 48, 48], the mountains [0, 384, 512, 112] (also bounding
# the sea band, its foam line, and the field patches under them),
# the hills [0, 448, 512, 48], and the floor box [0, 496, 512, 16]
# (two-tone ground) are single bounding boxes: cells completely
# outside a box skip its contents, anything touching one subdivides so
# Game.color can paint the parts. The in-play HUD box is gated on
# mode 1, the ready-UI box on mode 0, and the dead-UI box on mode 2.
# Each pipe
# pair's shaft and cap rects and each sky band are uniform-color
# boxes: fully inside one, the cell is that one flat color.
def Game.flat(d: Nat, +x0: U32, +y0: U32, +g: Game) -> Bool:
  Game{by, sp, dn, px, gy, pc, pt, scored, qx, qy, qc, qt, qscored, seed, mode, score, spd, space_held, r_held, cx, dx, ex, fx, wt} = g
  +s = U32.shln(1, d)
  +ga = Game.gap_of(pt)
  +gb = Game.gap_of(qt)
  +aty = (gy - PIPE_CAP_H() : U32)
  +aby = (gy + ga : U32)
  +abh = (496 - aby : U32)
  +bty = (qy - PIPE_CAP_H() : U32)
  +bby = (qy + gb : U32)
  +bbh = (496 - bby : U32)
  +acx = Game.capx(px)
  +acw = Game.capw(px)
  +bcx = Game.capx(qx)
  +bcw = Game.capw(qx)
  +clx = Game.pick((cx < CLOUD_W() : U32), 0, (cx - CLOUD_W() : U32))
  +dlx = Game.pick((dx < CLOUD_W() : U32), 0, (dx - CLOUD_W() : U32))
  +elx = Game.pick((ex < CLOUD_W() : U32), 0, (ex - CLOUD_W() : U32))
  +flx = Game.pick((fx < CLOUD_W() : U32), 0, (fx - CLOUD_W() : U32))
  +bl0 = Game.pick((Game.birdx(wt, 0) < 12 : U32), 0,
    (Game.birdx(wt, 0) - 12 : U32))
  +bl1 = Game.pick((Game.birdx(wt, 1) < 12 : U32), 0,
    (Game.birdx(wt, 1) - 12 : U32))
  +ready = (mode < 1 : U32)
  +dead = U32.is_eq(mode, 2)
  +hud = U32.is_eq(mode, 1)
  Game.pickb(hud, Game.outside(x0, y0, s, HUD_X(), HUD_Y(), HUD_W(), HUD_H()), True{})
    && Game.pickb(ready, Game.outside(x0, y0, s, 116, 48, 280, 346), True{})
    && Game.pickb(dead, Game.outside(x0, y0, s, 124, 56, 265, 338), True{})
    && Game.outside(x0, y0, s, BIRD_X(), by, 32, 16)
    && Game.outside(x0, y0, s, clx, 56, CLOUD_W(), 32)
    && Game.outside(x0, y0, s, dlx, 104, CLOUD_W(), 32)
    && Game.outside(x0, y0, s, elx, 16, CLOUD_W(), 32)
    && Game.outside(x0, y0, s, flx, 152, CLOUD_W(), 32)
    && Game.outside(x0, y0, s, bl0, 48, 12, 4)
    && Game.outside(x0, y0, s, bl1, 144, 12, 4)
    && Game.outside(x0, y0, s, 396, 40, 48, 48)
    && Game.outside(x0, y0, s, 0, 384, 512, 112)
    && Game.outside(x0, y0, s, 0, 448, 512, 48)
    && Game.outside(x0, y0, s, 0, 496, 512, 16)
      && (Game.inside(x0, y0, s, Game.pipex(px), 0, Game.pipew(px), gy)
        || Game.outside(x0, y0, s, Game.pipex(px), 0, Game.pipew(px), gy)
          && (Game.inside(x0, y0, s, acx, aty, acw, PIPE_CAP_H())
            || Game.outside(x0, y0, s, acx, aty, acw, PIPE_CAP_H())
              && (Game.inside(x0, y0, s, Game.pipex(px), aby, Game.pipew(px), abh)
                || Game.outside(x0, y0, s, Game.pipex(px), aby, Game.pipew(px), abh)
                  && (Game.inside(x0, y0, s, acx, aby, acw, PIPE_CAP_H())
                    || Game.outside(x0, y0, s, acx, aby, acw, PIPE_CAP_H())
                      && (Game.inside(x0, y0, s, Game.pipex(qx), 0, Game.pipew(qx), qy)
                        || Game.outside(x0, y0, s, Game.pipex(qx), 0, Game.pipew(qx), qy)
                          && (Game.inside(x0, y0, s, bcx, bty, bcw, PIPE_CAP_H())
                            || Game.outside(x0, y0, s, bcx, bty, bcw, PIPE_CAP_H())
                              && (Game.inside(x0, y0, s, Game.pipex(qx), bby, Game.pipew(qx), bbh)
                                || Game.outside(x0, y0, s, Game.pipex(qx), bby, Game.pipew(qx), bbh)
                                  && (Game.inside(x0, y0, s, bcx, bby, bcw, PIPE_CAP_H())
                                    || Game.outside(x0, y0, s, bcx, bby, bcw, PIPE_CAP_H())
                                      && (Game.inside(x0, y0, s, 0, 0, 512, 256)
                                        || Game.outside(x0, y0, s, 0, 0, 512, 256)
                                          && (Game.inside(x0, y0, s, 0, 256, 512, 128)
                                            || Game.outside(x0, y0, s, 0, 256, 512, 128)
                                              && Game.inside(x0, y0, s, 0, 384, 512, 112)))))))))))

def Game.draw(+d: Nat, flat: Bool, +x0: U32, +y0: U32, +g: Game) -> Image:
  match d:
    case 0n:
      Pix{Game.color(x0, y0, g)}
    case 1n+e:
      match flat:
        case True{}:
          Pix{Game.color(x0, y0, g)}
        case False{}:
          +h = U32.shln(1, e)
          +x1 = (x0 + h : U32)
          +y1 = (y0 + h : U32)
          tl tr bl br = Game.draw(e, Game.flat(e, x0, y0, g), x0, y0, g)
            Game.draw(e, Game.flat(e, x1, y0, g), x1, y0, g)
            Game.draw(e, Game.flat(e, x0, y1, g), x0, y1, g)
            Game.draw(e, Game.flat(e, x1, y1, g), x1, y1, g)
          Qua{tl, tr, bl, br}

def Game.view(g: Game) -> Game & Image:
  +g2 = g
  (g2, Game.draw(9n, Game.flat(9n, 0, 0, g2), 0, 0, g2))

def main() -> IO(Unit):
  App.run(~Game, ~App{Game.view, Game.tick}, "Flappy Bird", 512, 512, Game.init())
