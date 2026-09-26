import Base
import ./state.bend as S

# Keys
# ----

# A fresh Space press while ready launches the run with one flap and a
# fresh Space press while playing overrides the speed with FLAP up.
# Space while dead never restarts: it only tracks the key state.
# Restart after death is rising-edge R alone (see Game.press_r). Held
# Space never re-flaps. `space_held` just tracks the key state (down ->
# True, up -> False).
def Game.press_space(+down: Bool, +g: S.Game) -> S.Game:
  S.Game{by, sp, dn, px, gy, pc, pt, scored, qx, qy, qc, qt, qscored, seed, mode, score, spd, space_held, r_held, cx, dx, ex, fx, wt} = g
  +fresh = S.Game.pickb(down, Bool.not(space_held), False{})
  +flap = S.Game.pickb(fresh, ((0 < mode) && (mode < 2) : U32), False{})
  +launch = S.Game.pickb(fresh, (mode < 1 : U32), False{})
  S.Game.sel(launch, S.Game{by, S.FLAP(), False{}, px, gy, pc, pt, scored, qx, qy, qc, qt, qscored, seed, 1, score, spd, down, r_held, cx, dx, ex, fx, wt},
      S.Game.sel(flap, S.Game{by, S.FLAP(), False{}, px, gy, pc, pt, scored, qx, qy, qc, qt, qscored, seed, mode, score, spd, down, r_held, cx, dx, ex, fx, wt},
        S.Game{by, sp, dn, px, gy, pc, pt, scored, qx, qy, qc, qt, qscored, seed, mode, score, spd, down, r_held, cx, dx, ex, fx, wt}))

# A fresh R press while dead restarts; elsewhere R does nothing but
# track its key state. `r_held` gives the rising edge.
def Game.press_r(+down: Bool, +g: S.Game) -> S.Game:
  S.Game{by, sp, dn, px, gy, pc, pt, scored, qx, qy, qc, qt, qscored, seed, mode, score, spd, space_held, r_held, cx, dx, ex, fx, wt} = g
  +fresh = S.Game.pickb(down, Bool.not(r_held), False{})
  +reset = S.Game.pickb(fresh, (1 < mode : U32), False{})
  S.Game.sel(reset, S.Game.restart(space_held, down),
    S.Game{by, sp, dn, px, gy, pc, pt, scored, qx, qy, qc, qt, qscored, seed, mode, score, spd, space_held, down, cx, dx, ex, fx, wt})

def Game.event(e: Event, g: S.Game) -> Maybe<S.Game>:
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

def Game.events(events: List<Event>, g: S.Game) -> Maybe<S.Game>:
  match events:
    case []:
      Some{g}
    case e <> rest:
      Maybe.bind(&1, S.Game, S.Game, Game.event(e, g), g2 => Game.events(rest, g2))
