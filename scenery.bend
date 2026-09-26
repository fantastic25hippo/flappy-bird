import Base
import ./state.bend as S
import ./text.bend as Txt

# Background atmosphere (decorative only, never colliding): three sky
# bands covering y 0..496, mountains and hills sitting on the ground
# line behind the pipes, the sea band y 480..496 with its lighter foam
# line y 480..484, and two green field patches on the ground line. The
# ground is two-tone:
# grass y 496..504 over dirt y 504..512, with floor death strictly at
# y >= 496 (the sea never changes it).
def SKY_TOP() -> U32: 4223160
def SKY_MID() -> U32: 6856920
def SKY_PALE() -> U32: 11589872
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

# Mountains: two taller stepped ranges (left and right) of static
# quads whose bases sit on the ground line y 496, drawn in a darker
# tint than the hills behind the sea and the hills. Decorative: no
# hitbox.
def Game.mountains(+x: U32, +y: U32) -> Bool:
  Txt.Game.bar(x, y, 0, 432, 64, 64) || Txt.Game.bar(x, y, 64, 408, 64, 88)
    || Txt.Game.bar(x, y, 128, 424, 64, 72) || Txt.Game.bar(x, y, 192, 448, 64, 48)
    || Txt.Game.bar(x, y, 288, 440, 64, 56) || Txt.Game.bar(x, y, 352, 400, 64, 96)
    || Txt.Game.bar(x, y, 416, 384, 64, 112) || Txt.Game.bar(x, y, 480, 424, 32, 72)

# Distant hills: two static stepped silhouettes whose bases sit on the
# ground line y 496, drawn behind the pipes.
def Game.hills(+x: U32, +y: U32) -> Bool:
  Txt.Game.bar(x, y, 80, 448, 32, 16) || Txt.Game.bar(x, y, 48, 464, 96, 16)
    || Txt.Game.bar(x, y, 16, 480, 160, 16) || Txt.Game.bar(x, y, 400, 448, 32, 16)
    || Txt.Game.bar(x, y, 368, 464, 96, 16) || Txt.Game.bar(x, y, 336, 480, 160, 16)

# Sea: the named blue water band y 480..496 across the full width 512,
# with the lighter foam / shore line y 480..484 on top. Purely
# decorative: floor death stays strictly at y >= 496.
def Game.sea(+x: U32, +y: U32) -> Bool:
  Txt.Game.bar(x, y, 0, 480, 512, 16)

def Game.foam(+x: U32, +y: U32) -> Bool:
  Txt.Game.bar(x, y, 0, 480, 512, 4)

# Fields: two named green patches sitting on the ground line y 496
# (left and right, never the full width), in front of the sea and the
# mountains and behind the pipes. Decorative: no hitbox.
def Game.fields(+x: U32, +y: U32) -> Bool:
  Txt.Game.bar(x, y, 24, 484, 128, 12) || Txt.Game.bar(x, y, 360, 484, 128, 12)

# One cloud cluster: CLOUD_W wide in [right - CLOUD_W, right], three
# filled quads (crown over middle slab over bottom slab) around a y
# origin in the upper third. `u` is the distance left of the
# cluster's right edge with a U32-safe clamp, so the cluster slides
# cleanly out of the window. Decorative: no hitbox.
def Game.cloud(+x: U32, +y: U32, +rx: U32, +oy: U32) -> Bool:
  +u = S.Game.pick((rx < x : U32), 0, (rx - x : U32))
  ((x < rx) && (u < S.CLOUD_W()) : U32)
    && (Txt.Game.bar(u, y, 24, oy, 32, 8) || Txt.Game.bar(u, y, 8, (oy + 8 : U32), 64, 16)
      || Txt.Game.bar(u, y, 0, (oy + 24 : U32), S.CLOUD_W(), 8))

# Tiny distant bird right edge from the weather clock `wt`: the
# silhouette slides left one px per tick (slower than the near clouds)
# with its right edge wrapping to 600 once it leaves the window;
# index `i` picks the phase (0 and 300) so the two silhouettes never
# lock together. Frozen when dead because `wt` freezes. Wrap-safe:
# 600 - (wt + phase) % 600 is always in 1..600. Decorative: no
# hitbox.
def Game.birdx(+wt: U32, +i: U32) -> U32:
  +ph = S.Game.pick(U32.is_eq(i, 0), 0, 300)
  (600 - U32.mod((wt + ph : U32), 600) : U32)

# One tiny distant bird silhouette: a 6x3 body with a 4x2 wing in the
# 12-wide slot [right - 12, right] at a y origin in the upper third.
# `u` is the distance left of the bird's right edge with a U32-safe
# clamp, so the silhouette slides cleanly out of the window.
# Decorative: no hitbox.
def Game.bird(+x: U32, +y: U32, +rx: U32, +oy: U32) -> Bool:
  +u = S.Game.pick((rx < x : U32), 0, (rx - x : U32))
  ((x < rx) && (u < 12) : U32)
    && (Txt.Game.bar(u, y, 3, oy, 6, 3) || Txt.Game.bar(u, y, 4, (oy + 2 : U32), 4, 2))

# Five named distinct pillar colors: green, orange-red, blue, magenta,
# yellow.
def COLOR_0() -> U32: 3189308
def COLOR_1() -> U32: 14703136
def COLOR_2() -> U32: 2646240
def COLOR_3() -> U32: 13121736
def COLOR_4() -> U32: 15257664

# Pillar color lookup by pipe pair color index 0..4.
def Game.pillar_color(+c: U32) -> U32:
  S.Game.pick(U32.is_eq(c, 0), COLOR_0(),
    S.Game.pick(U32.is_eq(c, 1), COLOR_1(),
      S.Game.pick(U32.is_eq(c, 2), COLOR_2(),
        S.Game.pick(U32.is_eq(c, 3), COLOR_3(), COLOR_4()))))

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
