import Base
import ./state.bend as S

# Average scroll speed ramps from 3.0 at score 0 to 8.0 at score 40,
# in 1/8 px steps, dithered across frames with wt. Integer spd is
# floor(avg) most frames and floor(avg)+1 on some frames so the
# long-run mean matches. Cap 8 so wrap stays off-screen.
def Game.speed_of(+score: U32, +wt: U32) -> U32:
  +add = S.Game.pick((40 < score : U32), 40, score)
  +units = (24 + add : U32)
  +base = U32.div(units, 8)
  +frac = U32.mod(units, 8)
  +phase = U32.mod(wt, 8)
  +raw = (base + S.Game.pick((phase < frac : U32), 1, 0) : U32)
  S.Game.pick((8 < raw : U32), 8, raw)

# Gap height of a pair from its stored type alone (never score): type
# 0 the normal hole, type 1 the mid hole, type 2 the tight hole.
def Game.gap_of(+t: U32) -> U32:
  S.Game.pick(U32.is_eq(t, 1), S.GAP_H_MID(),
    S.Game.pick(U32.is_eq(t, 2), S.GAP_H_TIGHT(), S.GAP_H()))

# Wrap remix of a pair's type: before 16 pillars keep type 0; 16..23
# locks type 1 (mid); 24+ lets the mixer low bit pick type 1 or 2.
def Game.remix_ty(+nseed: U32, +score: U32) -> U32:
  S.Game.pick((score < 16 : U32), 0,
    S.Game.pick((score < 24 : U32), 1, (1 + U32.and(nseed, 1) : U32)))

# Wrap remix of a pair's gap top. Stage 0 keeps it within 48 of the
# sibling gap top, stage 1 within 96, both with U32-safe bases; later
# stages use the full mixer span. Every stage clamps to [GAP_TOP_MIN,
# GAP_TOP_MAX] with gy + gap <= 480 (stage 2 clamps with the mid hole,
# stage 3 with the chosen hole).
def Game.remix_gy(+sib: U32, +nseed: U32, +score: U32, +gap: U32) -> U32:
  +base48 = S.Game.pick((sib < 48 : U32), 0, (sib - 48 : U32))
  +near48 = (base48 + U32.mod(nseed, 96) : U32)
  +base96 = S.Game.pick((sib < 96 : U32), 0, (sib - 96 : U32))
  +near96 = (base96 + U32.mod(nseed, 192) : U32)
  +full = (S.GAP_TOP_MIN() + U32.mod(nseed, S.GAP_SPAN()) : U32)
  +cand = S.Game.pick((score < 8 : U32), near48,
    S.Game.pick((score < 16 : U32), near96, full))
  +cgh = S.Game.pick((score < 16 : U32), gap,
    S.Game.pick((score < 24 : U32), S.GAP_H_MID(), gap))
  +limit = (480 - cgh : U32)
  +gcap = S.Game.pick((limit < S.GAP_TOP_MAX() : U32), limit, S.GAP_TOP_MAX())
  +hi = S.Game.pick((gcap < cand : U32), gcap, cand)
  S.Game.pick((hi < S.GAP_TOP_MIN() : U32), S.GAP_TOP_MIN(), hi)
