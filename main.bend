# Flappy Bird: guide a multi-rect bird (body, beak, wing) through two
# scrolling pipe pairs spaced PIPE_SPACING apart. Three modes: ready (frozen, with a FLAPPY title
# and a SPACE start panel), playing (gravity, scroll, score), dead
# (frozen, with a GAME OVER banner, 7-segment score, and RETRY / EXIT
# panels). A fresh Space launches the run with one flap; only a
# fresh R restarts after death (Space never restarts). Collision uses
# only the body inset by
# HIT_PAD on each side. Sky bands, mountains, hills, a sea
# band, and field patches are pure decoration over a two-tone ground
# (grass over dirt) and never
# collide. Four cloud clusters drift at parallax speeds and two tiny
# distant birds slide across the upper third, all decorative.
# Score draws as a framed 3-digit 7-segment HUD at top-center while
# playing. Esc key-down or Close quits whatever the mode. Scroll speed
# starts at 3 and ramps toward 8 by score 40 via wt dither. Difficulty
# stages gap height from 16 pillars: mid then tight holes.
#
#   bend main.bend -o flappy && ./flappy

import Base
import ./state.bend as S
import ./step.bend as Step
import ./render.bend as R

# Draw
# ----

def Game.draw(+d: Nat, flat: Bool, +x0: U32, +y0: U32, +g: S.Game) -> Image:
  match d:
    case 0n:
      Pix{R.Game.color(x0, y0, g)}
    case 1n+e:
      match flat:
        case True{}:
          Pix{R.Game.color(x0, y0, g)}
        case False{}:
          +h = U32.shln(1, e)
          +x1 = (x0 + h : U32)
          +y1 = (y0 + h : U32)
          tl tr bl br = Game.draw(e, R.Game.flat(e, x0, y0, g), x0, y0, g)
            Game.draw(e, R.Game.flat(e, x1, y0, g), x1, y0, g)
            Game.draw(e, R.Game.flat(e, x0, y1, g), x0, y1, g)
            Game.draw(e, R.Game.flat(e, x1, y1, g), x1, y1, g)
          Qua{tl, tr, bl, br}

def Game.view(g: S.Game) -> S.Game & Image:
  +g2 = g
  (g2, Game.draw(9n, R.Game.flat(9n, 0, 0, g2), 0, 0, g2))

def main() -> IO(Unit):
  App.run(~S.Game, ~App{Game.view, Step.Game.tick}, "Flappy Bird", 512, 512, S.Game.init())
