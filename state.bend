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
  Game{256, 0, True{}, 552, 160, 0, 0, False{}, 832, 224, 1, 0, False{}, 123456789, 0, 0, 3, False{}, False{}, 120, 220, 400, 500, 0}

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
