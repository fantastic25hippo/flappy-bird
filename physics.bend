import Base
import ./state.bend as S

# Gravity shifts the speed toward down by GRAVITY; the falling speed
# clamps to MAX_FALL and running out of upward speed flips the
# direction to down.
def Game.fall(+sp: U32, +dn: Bool) -> U32:
  +s = (sp + S.GRAVITY() : U32)
  down_sp = S.Game.pick((S.MAX_FALL() < s : U32), S.MAX_FALL(), s)
  up_sp = S.Game.pick((S.GRAVITY() <= sp : U32), (sp - S.GRAVITY() : U32),
    (S.GRAVITY() - sp : U32))
  S.Game.pick(dn, down_sp, up_sp)

# Direction after gravity: falling stays down, rising flips at zero.
def Game.dir(+sp: U32, +dn: Bool) -> Bool:
  S.Game.pickb(dn, True{}, (sp < S.GRAVITY() : U32))

# y grows downward: falling adds the speed, rising subtracts it with
# the pong pick-clamp at 0; the floor clamp at 496 caps the fall.
def Game.travel(+by: U32, +sp: U32, +dn: Bool) -> U32:
  +ny = S.Game.pick(dn, (by + sp : U32),
    S.Game.pick((by < sp : U32), 0, (by - sp : U32)))
  S.Game.pick((496 < ny : U32), 496, ny)

# Pipe geometry: a PIPE_W wide pair at [prx, prx + prw], clamped so
# the visible width shrinks while the pair leaves or enters the window.
def Game.pipex(+px: U32) -> U32:
  S.Game.pick((px < S.PIPE_W() : U32), 0, (px - S.PIPE_W() : U32))

def Game.pipew(+px: U32) -> U32:
  S.Game.pick((px < S.PIPE_W() : U32), px, S.PIPE_W())

# Cap geometry: a PIPE_CAP_W wide lip at each gap edge, overhanging
# the shaft by 8px on each side. The cap left clamps at 0 while the
# pair leaves the window and the right edge px + 8 clamps at 512, so
# the width shrinks at either side and never exceeds PIPE_CAP_W.
def Game.capx(+px: U32) -> U32:
  S.Game.pick((px < 48 : U32), 0, (px - 48 : U32))

def Game.capw(+px: U32) -> U32:
  +cr = (px + 8 : U32)
  +rx = S.Game.pick((512 < cr : U32), 512, cr)
  +lx = Game.capx(px)
  +span = S.Game.pick((rx < lx : U32), 0, (rx - lx : U32))
  S.Game.pick((S.PIPE_CAP_W() < span : U32), S.PIPE_CAP_W(), span)

# 32-bit Linear Congruential Generator stepping the in-state mixer
# seed on pipe wrap (Numerical Recipes constants).
def Game.mix(+seed: U32) -> U32:
  ((seed * 1664525 : U32) + 1013904223 : U32)
