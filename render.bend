import Base
import ./state.bend as S
import ./physics.bend as Phys
import ./difficulty.bend as Diff
import ./text.bend as Txt
import ./scenery.bend as Sc

# Pixel colors, front to back: dead UI (banner, digits, panels) over
# the frozen world, bird rects (wing over beak over body), ready UI
# (title, SPACE text over the start bar), the in-play HUD (frame,
# face, 3-digit score), each pipe pair
# in its pillar color (shaft and caps alike; collision ignores color),
# the tiny distant birds and the four cloud clusters (behind pipes),
# the field patches, the sea band (foam over water), the hills, the
# mountains, the two-tone ground (grass over dirt), and the three sky
# bands. The background is decorative: no hitboxes.
def Game.color(+x: U32, +y: U32, +g: S.Game) -> U32:
  S.Game{by, sp, dn, px, gy, pc, pt, scored, qx, qy, qc, qt, qscored, seed, mode, score, spd, space_held, r_held, cx, dx, ex, fx, wt} = g
  +ready = (mode < 1 : U32)
  +dead = U32.is_eq(mode, 2)
  +hud_on = U32.is_eq(mode, 1)
  +ga = Diff.Game.gap_of(pt)
  +gb = Diff.Game.gap_of(qt)
  +bx0 = Sc.Game.birdx(wt, 0)
  +bx1 = Sc.Game.birdx(wt, 1)
  +ui_text = S.Game.pickb(ready, Txt.Game.title(x, y) || Txt.Game.space_word(x, y), False{})
  +ui_bar = S.Game.pickb(ready, Txt.Game.bar(x, y, 156, 338, 200, 56), False{})
  +over_text = S.Game.pickb(dead,
    Txt.Game.text(0, 124, 56, 265, x, y) || Txt.Game.text(1, 183, 218, 145, x, y)
      || Txt.Game.text4(2, 246, 253, 20, x, y) || Txt.Game.text(3, 199, 330, 115, x, y)
      || Txt.Game.text4(4, 222, 365, 68, x, y),
    False{})
  +over_digit = S.Game.pickb(dead, Txt.Game.dead_score(x, y, score), False{})
  +over_banner = S.Game.pickb(dead, Txt.Game.bar(x, y, 208, 104, 96, 48), False{})
  +over_retry = S.Game.pickb(dead, Txt.Game.bar(x, y, 169, 216, 174, 66), False{})
  +over_exit = S.Game.pickb(dead, Txt.Game.bar(x, y, 169, 328, 174, 66), False{})
  +hud_digit = S.Game.pickb(hud_on, Txt.Game.hud_score(x, y, score), False{})
  +hud_face = S.Game.pickb(hud_on,
    Txt.Game.bar(x, y, (Txt.HUD_X() + 2 : U32), (Txt.HUD_Y() + 2 : U32), 68, 28), False{})
  +hud_frame = S.Game.pickb(hud_on,
    Txt.Game.bar(x, y, Txt.HUD_X(), Txt.HUD_Y(), Txt.HUD_W(), Txt.HUD_H()), False{})
  S.Game.pick(over_text, 16777215,
    S.Game.pick(over_digit, 16777215,
      S.Game.pick(over_exit, Sc.PANEL_RED(),
        S.Game.pick(over_retry, Sc.PANEL_GREEN(),
          S.Game.pick(over_banner, Sc.PANEL_DARK(),
  S.Game.pick(Txt.Game.bar(x, y, (S.BIRD_X() + 6 : U32), (by + 8 : U32), 10, 6), 16777215,
    S.Game.pick(Txt.Game.bar(x, y, (S.BIRD_X() + S.BODY_W() : U32), (by + 6 : U32), 8, 6), 15759392,
      S.Game.pick(Txt.Game.bar(x, y, S.BIRD_X(), by, S.BODY_W(), S.BODY_H()), 16440390,
        S.Game.pick(ui_text, 16777215,
          S.Game.pick(ui_bar, Sc.PANEL_BLUE(),
            S.Game.pick(hud_digit, Sc.HUD_DIGIT(),
              S.Game.pick(hud_face, Sc.HUD_FACE(),
                S.Game.pick(hud_frame, Sc.HUD_FRAME(),
                S.Game.pick(Txt.Game.inside(x, y, 1, Phys.Game.pipex(px), 0, Phys.Game.pipew(px), gy)
                || Txt.Game.inside(x, y, 1, Phys.Game.capx(px), (gy - S.PIPE_CAP_H() : U32),
                  Phys.Game.capw(px), S.PIPE_CAP_H())
                || Txt.Game.inside(x, y, 1, Phys.Game.pipex(px), (gy + ga : U32),
                  Phys.Game.pipew(px), (496 - (gy + ga : U32) : U32))
                || Txt.Game.inside(x, y, 1, Phys.Game.capx(px), (gy + ga : U32),
                  Phys.Game.capw(px), S.PIPE_CAP_H()),
                Sc.Game.pillar_color(pc),
                S.Game.pick(Txt.Game.inside(x, y, 1, Phys.Game.pipex(qx), 0, Phys.Game.pipew(qx), qy)
                  || Txt.Game.inside(x, y, 1, Phys.Game.capx(qx), (qy - S.PIPE_CAP_H() : U32),
                    Phys.Game.capw(qx), S.PIPE_CAP_H())
                  || Txt.Game.inside(x, y, 1, Phys.Game.pipex(qx), (qy + gb : U32),
                    Phys.Game.pipew(qx), (496 - (qy + gb : U32) : U32))
                  || Txt.Game.inside(x, y, 1, Phys.Game.capx(qx), (qy + gb : U32),
                    Phys.Game.capw(qx), S.PIPE_CAP_H()),
                  Sc.Game.pillar_color(qc),
                  S.Game.pick(Sc.Game.bird(x, y, bx0, 48)
                    || Sc.Game.bird(x, y, bx1, 144), Sc.BIRD_TINT(),
                  S.Game.pick(Sc.Game.cloud(x, y, cx, 56) || Sc.Game.cloud(x, y, dx, 104)
                    || Sc.Game.cloud(x, y, ex, 16) || Sc.Game.cloud(x, y, fx, 152),
                    Sc.CLOUD_WHITE(),
                    S.Game.pick(Sc.Game.fields(x, y), Sc.FIELD_GREEN(),
                      S.Game.pick(Sc.Game.foam(x, y), Sc.SEA_FOAM(),
                        S.Game.pick(Sc.Game.sea(x, y), Sc.SEA_BLUE(),
                          S.Game.pick(Sc.Game.hills(x, y), Sc.HILLS_TINT(),
                            S.Game.pick(Sc.Game.mountains(x, y), Sc.MOUNT_TINT(),
                      S.Game.pick(Txt.Game.bar(x, y, 0, 496, 512, 8), Sc.GRASS_GREEN(),
                        S.Game.pick(Txt.Game.bar(x, y, 0, 504, 512, 8), Sc.DIRT_BROWN(),
                          S.Game.pick(Txt.Game.bar(x, y, 0, 0, 512, 256), Sc.SKY_TOP(),
                            S.Game.pick(Txt.Game.bar(x, y, 0, 256, 512, 128), Sc.SKY_MID(),
                              Sc.SKY_PALE()))))))))))))))))))))))))))

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
# 136) and x [152, 184), the eight mountain bars, the sea band
# [0, 480, 512, 16] (also covering its foam line, the field patches,
# and the two hills bars hidden under the sea and foam; the visible
# hills silhouettes lie wholly inside the mountain bars), and the
# floor box [0, 496, 512, 16]
# (two-tone ground) are single bounding boxes: cells completely
# outside a box skip its contents, anything touching one subdivides so
# Game.color can paint the parts. The in-play HUD box is gated on
# mode 1, the ready-UI box on mode 0, and the dead-UI box on mode 2.
# Each pipe
# pair's shaft and cap rects and each sky band are uniform-color
# boxes: fully inside one, the cell is that one flat color. The
# SKY_PALE background of the band y 384..480 is covered by eight
# disjoint uniform-color rects at the end of the chain, each proved
# free of mountains, hills, sea, foam, and fields: fully inside one,
# the cell is that one flat color.
def Game.flat(d: Nat, +x0: U32, +y0: U32, +g: S.Game) -> Bool:
  S.Game{by, sp, dn, px, gy, pc, pt, scored, qx, qy, qc, qt, qscored, seed, mode, score, spd, space_held, r_held, cx, dx, ex, fx, wt} = g
  +s = U32.shln(1, d)
  +ga = Diff.Game.gap_of(pt)
  +gb = Diff.Game.gap_of(qt)
  +aty = (gy - S.PIPE_CAP_H() : U32)
  +aby = (gy + ga : U32)
  +abh = (496 - aby : U32)
  +bty = (qy - S.PIPE_CAP_H() : U32)
  +bby = (qy + gb : U32)
  +bbh = (496 - bby : U32)
  +acx = Phys.Game.capx(px)
  +acw = Phys.Game.capw(px)
  +bcx = Phys.Game.capx(qx)
  +bcw = Phys.Game.capw(qx)
  +clx = S.Game.pick((cx < S.CLOUD_W() : U32), 0, (cx - S.CLOUD_W() : U32))
  +dlx = S.Game.pick((dx < S.CLOUD_W() : U32), 0, (dx - S.CLOUD_W() : U32))
  +elx = S.Game.pick((ex < S.CLOUD_W() : U32), 0, (ex - S.CLOUD_W() : U32))
  +flx = S.Game.pick((fx < S.CLOUD_W() : U32), 0, (fx - S.CLOUD_W() : U32))
  +bl0 = S.Game.pick((Sc.Game.birdx(wt, 0) < 12 : U32), 0,
    (Sc.Game.birdx(wt, 0) - 12 : U32))
  +bl1 = S.Game.pick((Sc.Game.birdx(wt, 1) < 12 : U32), 0,
    (Sc.Game.birdx(wt, 1) - 12 : U32))
  +ready = (mode < 1 : U32)
  +dead = U32.is_eq(mode, 2)
  +hud = U32.is_eq(mode, 1)
  S.Game.pickb(hud, Txt.Game.outside(x0, y0, s, Txt.HUD_X(), Txt.HUD_Y(), Txt.HUD_W(), Txt.HUD_H()), True{})
    && S.Game.pickb(ready, Txt.Game.outside(x0, y0, s, 116, 48, 280, 346), True{})
    && S.Game.pickb(dead, Txt.Game.outside(x0, y0, s, 124, 56, 265, 338), True{})
    && Txt.Game.outside(x0, y0, s, S.BIRD_X(), by, 32, 16)
    && Txt.Game.outside(x0, y0, s, clx, 56, S.CLOUD_W(), 32)
    && Txt.Game.outside(x0, y0, s, dlx, 104, S.CLOUD_W(), 32)
    && Txt.Game.outside(x0, y0, s, elx, 16, S.CLOUD_W(), 32)
    && Txt.Game.outside(x0, y0, s, flx, 152, S.CLOUD_W(), 32)
    && Txt.Game.outside(x0, y0, s, bl0, 48, 12, 4)
    && Txt.Game.outside(x0, y0, s, bl1, 144, 12, 4)
    && Txt.Game.outside(x0, y0, s, 0, 432, 64, 64)
    && Txt.Game.outside(x0, y0, s, 64, 408, 64, 88)
    && Txt.Game.outside(x0, y0, s, 128, 424, 64, 72)
    && Txt.Game.outside(x0, y0, s, 192, 448, 64, 48)
    && Txt.Game.outside(x0, y0, s, 288, 440, 64, 56)
    && Txt.Game.outside(x0, y0, s, 352, 400, 64, 96)
    && Txt.Game.outside(x0, y0, s, 416, 384, 64, 112)
    && Txt.Game.outside(x0, y0, s, 480, 424, 32, 72)
    && Txt.Game.outside(x0, y0, s, 0, 480, 512, 16)
    && Txt.Game.outside(x0, y0, s, 0, 496, 512, 16)
      && (Txt.Game.inside(x0, y0, s, Phys.Game.pipex(px), 0, Phys.Game.pipew(px), gy)
        || Txt.Game.outside(x0, y0, s, Phys.Game.pipex(px), 0, Phys.Game.pipew(px), gy)
          && (Txt.Game.inside(x0, y0, s, acx, aty, acw, S.PIPE_CAP_H())
            || Txt.Game.outside(x0, y0, s, acx, aty, acw, S.PIPE_CAP_H())
              && (Txt.Game.inside(x0, y0, s, Phys.Game.pipex(px), aby, Phys.Game.pipew(px), abh)
                || Txt.Game.outside(x0, y0, s, Phys.Game.pipex(px), aby, Phys.Game.pipew(px), abh)
                  && (Txt.Game.inside(x0, y0, s, acx, aby, acw, S.PIPE_CAP_H())
                    || Txt.Game.outside(x0, y0, s, acx, aby, acw, S.PIPE_CAP_H())
                      && (Txt.Game.inside(x0, y0, s, Phys.Game.pipex(qx), 0, Phys.Game.pipew(qx), qy)
                        || Txt.Game.outside(x0, y0, s, Phys.Game.pipex(qx), 0, Phys.Game.pipew(qx), qy)
                          && (Txt.Game.inside(x0, y0, s, bcx, bty, bcw, S.PIPE_CAP_H())
                            || Txt.Game.outside(x0, y0, s, bcx, bty, bcw, S.PIPE_CAP_H())
                              && (Txt.Game.inside(x0, y0, s, Phys.Game.pipex(qx), bby, Phys.Game.pipew(qx), bbh)
                                || Txt.Game.outside(x0, y0, s, Phys.Game.pipex(qx), bby, Phys.Game.pipew(qx), bbh)
                                  && (Txt.Game.inside(x0, y0, s, bcx, bby, bcw, S.PIPE_CAP_H())
                                    || Txt.Game.outside(x0, y0, s, bcx, bby, bcw, S.PIPE_CAP_H())
                                      && (Txt.Game.inside(x0, y0, s, 0, 0, 512, 256)
                                        || Txt.Game.outside(x0, y0, s, 0, 0, 512, 256)
                                          && (Txt.Game.inside(x0, y0, s, 0, 256, 512, 128)
                                            || Txt.Game.outside(x0, y0, s, 0, 256, 512, 128)
                                              && (Txt.Game.inside(x0, y0, s, 0, 384, 352, 24)
                                                || Txt.Game.outside(x0, y0, s, 0, 384, 352, 24)
                                                  && (Txt.Game.inside(x0, y0, s, 352, 384, 64, 16)
                                                    || Txt.Game.outside(x0, y0, s, 352, 384, 64, 16)
                                                      && (Txt.Game.inside(x0, y0, s, 480, 384, 32, 40)
                                                        || Txt.Game.outside(x0, y0, s, 480, 384, 32, 40)
                                                          && (Txt.Game.inside(x0, y0, s, 0, 408, 64, 24)
                                                            || Txt.Game.outside(x0, y0, s, 0, 408, 64, 24)
                                                              && (Txt.Game.inside(x0, y0, s, 128, 408, 224, 16)
                                                                || Txt.Game.outside(x0, y0, s, 128, 408, 224, 16)
                                                                  && (Txt.Game.inside(x0, y0, s, 192, 424, 160, 16)
                                                                    || Txt.Game.outside(x0, y0, s, 192, 424, 160, 16)
                                                                      && (Txt.Game.inside(x0, y0, s, 192, 440, 96, 8)
                                                                        || Txt.Game.outside(x0, y0, s, 192, 440, 96, 8)
                                                                      && Txt.Game.inside(x0, y0, s, 256, 448, 32, 32))))))))))))))))))
