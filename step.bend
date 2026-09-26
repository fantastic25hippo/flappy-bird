import Base
import ./state.bend as S
import ./input.bend as In
import ./physics.bend as Phys
import ./difficulty.bend as Diff

# Motion
# ------

# Physics step while playing: gravity, travel, dithered-speed scroll of
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
def Game.step(+g: S.Game) -> S.Game:
  S.Game{by, sp, dn, px, gy, pc, pt, scored, qx, qy, qc, qt, qscored, seed, mode, score, spd, space_held, r_held, cx, dx, ex, fx, wt} = g
  +play = ((0 < mode) && (mode < 2) : U32)
  +nsp = S.Game.pick(play, Phys.Game.fall(sp, dn), sp)
  +ndn = S.Game.pickb(play, Phys.Game.dir(sp, dn), dn)
  +ny = S.Game.pick(play, Phys.Game.travel(by, nsp, ndn), by)
  +cur_spd = S.Game.pick(play, Diff.Game.speed_of(score, wt), spd)
  +spx = S.Game.pick(play, (px - cur_spd : U32), px)
  +sqx = S.Game.pick(play, (qx - cur_spd : U32), qx)
  +awrap = (play && (px < cur_spd) : U32)
  +bwrap = (play && (qx < cur_spd) : U32)
  +npx = S.Game.pick(awrap, (sqx + S.PIPE_SPACING() : U32), spx)
  +nqx = S.Game.pick(bwrap, (spx + S.PIPE_SPACING() : U32), sqx)
  +wrap = (awrap || bwrap : U32)
  +nseed = S.Game.pick(wrap, Phys.Game.mix(seed), seed)
  +nty = Diff.Game.remix_ty(nseed, score)
  +ngap = Diff.Game.gap_of(nty)
  +npt = S.Game.pick(awrap, nty, pt)
  +nqt = S.Game.pick(bwrap, nty, qt)
  +ngy = S.Game.pick(awrap, Diff.Game.remix_gy(qy, nseed, score, ngap), gy)
  +nqy = S.Game.pick(bwrap, Diff.Game.remix_gy(gy, nseed, score, ngap), qy)
  +npc = S.Game.pick(awrap, U32.mod((pc + 2 : U32), 5), pc)
  +nqc = S.Game.pick(bwrap, U32.mod((qc + 2 : U32), 5), qc)
  +prx = Phys.Game.pipex(npx)
  +prw = Phys.Game.pipew(npx)
  +qrx = Phys.Game.pipex(nqx)
  +qrw = Phys.Game.pipew(nqx)
  +pcx = Phys.Game.capx(npx)
  +pcw = Phys.Game.capw(npx)
  +qcx = Phys.Game.capx(nqx)
  +qcw = Phys.Game.capw(nqx)
  +inx0 = (S.BIRD_X() + S.HIT_PAD() : U32)
  +inx1 = ((S.BIRD_X() + S.BODY_W() : U32) - S.HIT_PAD() : U32)
  +iny0 = (ny + S.HIT_PAD() : U32)
  +iny1 = ((ny + S.BODY_H() : U32) - S.HIT_PAD() : U32)
  +gapa = Diff.Game.gap_of(npt)
  +gapb = Diff.Game.gap_of(nqt)
  +aby = (ngy + gapa : U32)
  +bby = (nqy + gapb : U32)
  +sh_a = ((inx0 < (prx + prw : U32)) && (prx < inx1) : U32)
  +sh_b = ((inx0 < (qrx + qrw : U32)) && (qrx < inx1) : U32)
  +cp_a = ((inx0 < (pcx + pcw : U32)) && (pcx < inx1) : U32)
  +cp_b = ((inx0 < (qcx + qcw : U32)) && (qcx < inx1) : U32)
  +hit_a = ((sh_a && (iny0 < ngy))
    || (sh_a && (aby < iny1))
    || (cp_a && (iny0 < ngy) && ((ngy - S.PIPE_CAP_H() : U32) < iny1))
    || (cp_a && (iny0 < (aby + S.PIPE_CAP_H() : U32)) && (aby < iny1))
    : U32)
  +hit_b = ((sh_b && (iny0 < nqy))
    || (sh_b && (bby < iny1))
    || (cp_b && (iny0 < nqy) && ((nqy - S.PIPE_CAP_H() : U32) < iny1))
    || (cp_b && (iny0 < (bby + S.PIPE_CAP_H() : U32)) && (bby < iny1))
    : U32)
  +hit = (hit_a || hit_b : U32)
  +fallen = (hit || (ny < 1) || (496 <= ny) : U32)
  +dead = (play && fallen : U32)
  +nmode = S.Game.pick(dead, 2, mode)
  +pass_a = (play && Bool.not(scored) && (npx < S.BIRD_X()) : U32)
  +pass_b = (play && Bool.not(qscored) && (nqx < S.BIRD_X()) : U32)
  +s1 = S.Game.pick(pass_a, (score + 1 : U32), score)
  +nscore = S.Game.pick(pass_b, (s1 + 1 : U32), s1)
  +nscored = S.Game.pickb(awrap, False{}, S.Game.pickb(pass_a, True{}, scored))
  +nqscored = S.Game.pickb(bwrap, False{}, S.Game.pickb(pass_b, True{}, qscored))
  +nspd = S.Game.pick(play, Diff.Game.speed_of(nscore, wt), spd)
  +drift = (mode < 2 : U32)
  +ncx = S.Game.pick((drift && (cx < S.CLOUD_SPD_NEAR()) : U32), 600,
    S.Game.pick(drift, (cx - S.CLOUD_SPD_NEAR() : U32), cx))
  +ndx = S.Game.pick((drift && (dx < S.CLOUD_SPD_NEAR()) : U32), 600,
    S.Game.pick(drift, (dx - S.CLOUD_SPD_NEAR() : U32), dx))
  +nex = S.Game.pick((drift && (ex < S.CLOUD_SPD_FAR()) : U32), 600,
    S.Game.pick(drift, (ex - S.CLOUD_SPD_FAR() : U32), ex))
  +nfx = S.Game.pick((drift && (fx < S.CLOUD_SPD_FAR()) : U32), 600,
    S.Game.pick(drift, (fx - S.CLOUD_SPD_FAR() : U32), fx))
  +nwt = S.Game.pick(drift, (wt + 1 : U32), wt)
  S.Game{ny, nsp, ndn, npx, ngy, npc, npt, nscored, nqx, nqy, nqc, nqt, nqscored, nseed, nmode, nscore, nspd, space_held, r_held, ncx, ndx, nex, nfx, nwt}

def Game.tick(events: List<Event>, g: S.Game) -> IO(Maybe<S.Game>):
  IO.pure(Maybe<S.Game>, Maybe.bind(&1, S.Game, S.Game, In.Game.events(events, g),
    g2 => Some{Game.step(g2)}))
