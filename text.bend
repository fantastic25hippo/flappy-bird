import Base
import ./state.bend as S

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
  S.Game.pickb(U32.is_eq(c, 0), Game.glyph_f(x, y),
    S.Game.pickb(U32.is_eq(c, 1), Game.glyph_l(x, y),
      S.Game.pickb(U32.is_eq(c, 2), Game.glyph_a(x, y),
        S.Game.pickb(U32.is_eq(c, 3), Game.glyph_p(x, y),
          S.Game.pickb(U32.is_eq(c, 4), Game.glyph_y(x, y),
            S.Game.pickb(U32.is_eq(c, 5), Game.glyph_s(x, y),
              S.Game.pickb(U32.is_eq(c, 6), Game.glyph_c(x, y),
                S.Game.pickb(U32.is_eq(c, 7), Game.glyph_e(x, y),
                  S.Game.pickb(U32.is_eq(c, 8), Game.glyph_g(x, y),
                    S.Game.pickb(U32.is_eq(c, 9), Game.glyph_m(x, y),
                      S.Game.pickb(U32.is_eq(c, 10), Game.glyph_o(x, y),
                        S.Game.pickb(U32.is_eq(c, 11), Game.glyph_v(x, y),
                          S.Game.pickb(U32.is_eq(c, 12), Game.glyph_r(x, y),
                            S.Game.pickb(U32.is_eq(c, 13), Game.glyph_t(x, y),
                              S.Game.pickb(U32.is_eq(c, 14), Game.glyph_x(x, y),
                                S.Game.pickb(U32.is_eq(c, 15), Game.glyph_i(x, y),
                                  False{}))))))))))))))))

# Glyph codes for the FLAPPY title (F L A P P Y).
def Game.title_code(+i: U32) -> U32:
  S.Game.pick(U32.is_eq(i, 1), 1,
    S.Game.pick(U32.is_eq(i, 2), 2,
      S.Game.pick(U32.is_eq(i, 3), 3,
        S.Game.pick(U32.is_eq(i, 4), 3,
          S.Game.pick(U32.is_eq(i, 5), 4, 0)))))

# Glyph codes for the SPACE start panel (S P A C E).
def Game.space_code(+i: U32) -> U32:
  S.Game.pick(U32.is_eq(i, 1), 3,
    S.Game.pick(U32.is_eq(i, 2), 2,
      S.Game.pick(U32.is_eq(i, 3), 6,
        S.Game.pick(U32.is_eq(i, 4), 7, 5))))

# Title FLAPPY: six 5x7 glyphs at 8px per unit on a 48px pitch from
# (116, 48), in the upper third. Glyph gaps read as background.
def Game.title(+x: U32, +y: U32) -> Bool:
  +tx = S.Game.pick((x < 116 : U32), 0, (x - 116 : U32))
  +ty = S.Game.pick((y < 48 : U32), 0, (y - 48 : U32))
  +gx = U32.mod(tx, 48)
  +code = Game.title_code(U32.div(tx, 48))
  ((116 <= x) && (x < 396) && (48 <= y) && (y < 104) && (gx < 40)
    : U32)
    && Game.letter(code, U32.div(gx, 8), U32.div(ty, 8))

# Start panel text SPACE: five 5x7 glyphs at 5px per unit on a 30px
# pitch (a 150px span) from (181, 348), centered in the 200x56 start
# panel at (156, 338). Glyph gaps read as the start bar.
def Game.space_word(+x: U32, +y: U32) -> Bool:
  +tx = S.Game.pick((x < 181 : U32), 0, (x - 181 : U32))
  +ty = S.Game.pick((y < 348 : U32), 0, (y - 348 : U32))
  +gx = U32.mod(tx, 30)
  +code = Game.space_code(U32.div(tx, 30))
  ((181 <= x) && (tx < 150) && (348 <= y) && (ty < 35) && (gx < 25)
    : U32)
    && Game.letter(code, U32.div(gx, 5), U32.div(ty, 5))

# Glyph codes for the GAME OVER banner (G A M E _ O V E R).
def Game.over_code(+i: U32) -> U32:
  S.Game.pick(U32.is_eq(i, 0), 8,
    S.Game.pick(U32.is_eq(i, 1), 2,
      S.Game.pick(U32.is_eq(i, 2), 9,
        S.Game.pick(U32.is_eq(i, 3), 7,
          S.Game.pick(U32.is_eq(i, 4), 16,
            S.Game.pick(U32.is_eq(i, 5), 10,
              S.Game.pick(U32.is_eq(i, 6), 11,
                S.Game.pick(U32.is_eq(i, 7), 7, 12))))))))

# Glyph codes for the RETRY panel row (R E T R Y).
def Game.retry_code(+i: U32) -> U32:
  S.Game.pick(U32.is_eq(i, 0), 12,
    S.Game.pick(U32.is_eq(i, 1), 7,
      S.Game.pick(U32.is_eq(i, 2), 13,
        S.Game.pick(U32.is_eq(i, 3), 12, 4))))

# Glyph codes for the short R retry hint under the RETRY row: just R
# (the dead screen restarts on R only, never on Space).
def Game.rhint_code(+i: U32) -> U32:
  12

# Glyph codes for the EXIT panel row (E X I T).
def Game.exit_code(+i: U32) -> U32:
  S.Game.pick(U32.is_eq(i, 0), 7,
    S.Game.pick(U32.is_eq(i, 1), 14,
      S.Game.pick(U32.is_eq(i, 2), 15, 13)))

# Glyph codes naming the Esc key: E S C.
def Game.esc_code(+i: U32) -> U32:
  S.Game.pick(U32.is_eq(i, 0), 7,
    S.Game.pick(U32.is_eq(i, 1), 5, 6))

# Word id selects the per-slot glyph code table.
def Game.text_code(+w: U32, +i: U32) -> U32:
  S.Game.pick(U32.is_eq(w, 0), Game.over_code(i),
    S.Game.pick(U32.is_eq(w, 1), Game.retry_code(i),
      S.Game.pick(U32.is_eq(w, 2), Game.rhint_code(i),
        S.Game.pick(U32.is_eq(w, 3), Game.exit_code(i),
          Game.esc_code(i)))))

# One dead-screen text row: 5x7 glyphs at 5px per unit on a 30px
# pitch from (ox, oy), wd px wide. Slot gaps read as the world behind.
def Game.text(+w: U32, +ox: U32, +oy: U32, +wd: U32, +x: U32, +y: U32) -> Bool:
  +tx = S.Game.pick((x < ox : U32), 0, (x - ox : U32))
  +ty = S.Game.pick((y < oy : U32), 0, (y - oy : U32))
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
  +tx = S.Game.pick((x < ox : U32), 0, (x - ox : U32))
  +ty = S.Game.pick((y < oy : U32), 0, (y - oy : U32))
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
  S.Game.pick(U32.is_eq(d, 0), 63,
    S.Game.pick(U32.is_eq(d, 1), 6,
      S.Game.pick(U32.is_eq(d, 2), 91,
        S.Game.pick(U32.is_eq(d, 3), 79,
          S.Game.pick(U32.is_eq(d, 4), 102,
            S.Game.pick(U32.is_eq(d, 5), 109,
              S.Game.pick(U32.is_eq(d, 6), 125,
                S.Game.pick(U32.is_eq(d, 7), 7,
                  S.Game.pick(U32.is_eq(d, 8), 127, 111)))))))))

# One digit at cell origin (ox, oy); clamped coords fall outside it.
def Game.digit_at(+m: U32, +ox: U32, +oy: U32, +x: U32, +y: U32) -> Bool:
  +lx = S.Game.pick((x < ox : U32), 24, (x - ox : U32))
  +ly = S.Game.pick((y < oy : U32), 40, (y - oy : U32))
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
  +lx = S.Game.pick((x < ox : U32), 14, (x - ox : U32))
  +ly = S.Game.pick((y < oy : U32), 22, (y - oy : U32))
  Game.digit_c(m, lx, ly)

# The shared score%1000 digit split: hundreds, tens, and ones of
# score (left to right), computed here in the view; no extra Game
# fields. Used by both the dead-screen score and the in-play HUD
# score through Game.score_row: a Bend match can only take a pair
# apart on a parameter, so the split's pair is consumed there.
def Game.score3(+score: U32) -> U32 & (U32 & U32):
  +s = U32.mod(score, 1000)
  +d0 = U32.mod(s, 10)
  +d1 = U32.mod(U32.div(s, 10), 10)
  +d2 = U32.div(s, 100)
  (d2, (d1, d0))

# One three-digit 7-segment row from the shared split ms: cells at
# origins ox0, ox1, ox2 on row oy, drawn with the full 24x40 cells
# (compact = False, dead screen) or the compact 14x22 ones
# (compact = True, HUD).
def Game.score_row(ms: U32 & (U32 & U32), compact: Bool, +ox0: U32, +ox1: U32, +ox2: U32, +oy: U32, +x: U32, +y: U32) -> Bool:
  (d2, (d1, d0)) = ms
  match compact:
    case True{}:
      Game.digit_c_at(Game.digit_mask(d2), ox0, oy, x, y)
        || Game.digit_c_at(Game.digit_mask(d1), ox1, oy, x, y)
        || Game.digit_c_at(Game.digit_mask(d0), ox2, oy, x, y)
    case False{}:
      Game.digit_at(Game.digit_mask(d2), ox0, oy, x, y)
        || Game.digit_at(Game.digit_mask(d1), ox1, oy, x, y)
        || Game.digit_at(Game.digit_mask(d0), ox2, oy, x, y)

# Dead-screen score: the shared split in full 24x40 cells at (212,
# 108), (244, 108), (276, 108).
def Game.dead_score(+x: U32, +y: U32, +score: U32) -> Bool:
  Game.score_row(Game.score3(score), False{}, 212, 244, 276, 108, x, y)

# In-play HUD box: a named 72x32 box at (220, 8) with a thin 2px
# frame, an inner face, and three compact digit cells.
def HUD_X() -> U32: 220
def HUD_Y() -> U32: 8
def HUD_W() -> U32: 72
def HUD_H() -> U32: 32

# In-play HUD score: the shared split in compact 14x22 cells at (232,
# 13), (249, 13), (266, 13) inside the HUD face. The compact cells fit
# wholly inside the face and never clip into the sky (the dead
# overlay keeps 24x40 cells).
def Game.hud_score(+x: U32, +y: U32, +score: U32) -> Bool:
  Game.score_row(Game.score3(score), True{}, 232, 249, 266, 13, x, y)
