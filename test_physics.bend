import Base
import ./physics.bend as Phys
import ./state.bend as S

def check_match(+name: String, +got: U32, +want: U32, eq: Bool) -> String:
  match eq:
    case True{}:
      "PASS " ++ name ++ "\n"
    case False{}:
      "FAIL " ++ name ++ " got=" ++ U32.show(got) ++ " want=" ++ U32.show(want) ++ "\n"

def check(+name: String, +got: U32, +want: U32) -> String:
  check_match(name, got, want, U32.is_eq(got, want))

type TestRes is Type:
  R{lines: String, passed: U32}

def run_travel(res: TestRes, by: U32, sp: U32, dn: Bool, +want: U32) -> TestRes:
  match res:
    case R{lines, passed}:
      +got = Phys.Game.travel(by, sp, dn)
      eq = U32.is_eq(got, want)
      nl = lines ++ check("travel", got, want)
      np = (passed + S.Game.pick(eq, 1, 0) : U32)
      R{nl, np}

def run_fall(res: TestRes, sp: U32, dn: Bool, +want: U32) -> TestRes:
  match res:
    case R{lines, passed}:
      +got = Phys.Game.fall(sp, dn)
      eq = U32.is_eq(got, want)
      nl = lines ++ check("fall", got, want)
      np = (passed + S.Game.pick(eq, 1, 0) : U32)
      R{nl, np}

def run_dir(res: TestRes, sp: U32, dn: Bool, +want: U32) -> TestRes:
  match res:
    case R{lines, passed}:
      +got_bool = Phys.Game.dir(sp, dn)
      +got = S.Game.pick(got_bool, 1, 0)
      eq = U32.is_eq(got, want)
      nl = lines ++ check("dir", got, want)
      np = (passed + S.Game.pick(eq, 1, 0) : U32)
      R{nl, np}

def run_capx(res: TestRes, px: U32, +want: U32) -> TestRes:
  match res:
    case R{lines, passed}:
      +got = Phys.Game.capx(px)
      eq = U32.is_eq(got, want)
      nl = lines ++ check("capx", got, want)
      np = (passed + S.Game.pick(eq, 1, 0) : U32)
      R{nl, np}

def run_capw(res: TestRes, px: U32, +want: U32) -> TestRes:
  match res:
    case R{lines, passed}:
      +got = Phys.Game.capw(px)
      eq = U32.is_eq(got, want)
      nl = lines ++ check("capw", got, want)
      np = (passed + S.Game.pick(eq, 1, 0) : U32)
      R{nl, np}

def run_mix(res: TestRes, seed: U32, +want: U32) -> TestRes:
  match res:
    case R{lines, passed}:
      +got = Phys.Game.mix(seed)
      eq = U32.is_eq(got, want)
      nl = lines ++ check("mix", got, want)
      np = (passed + S.Game.pick(eq, 1, 0) : U32)
      R{nl, np}

def all_tests() -> TestRes:
  r1 = run_travel(R{"", 0}, 100, 10, True{}, 110)
  r2 = run_travel(r1, 490, 10, True{}, 496)
  r3 = run_travel(r2, 495, 12, True{}, 496)
  r4 = run_travel(r3, 496, 5, True{}, 496)
  r5 = run_travel(r4, 0, 0, True{}, 0)
  r6 = run_travel(r5, 0, 12, True{}, 12)
  r7 = run_travel(r6, 484, 12, True{}, 496)
  r8 = run_travel(r7, 256, 8, True{}, 264)
  r9 = run_travel(r8, 100, 10, False{}, 90)
  r10 = run_travel(r9, 10, 10, False{}, 0)
  r11 = run_travel(r10, 5, 10, False{}, 0)
  r12 = run_travel(r11, 0, 8, False{}, 0)
  r13 = run_travel(r12, 8, 9, False{}, 0)
  r14 = run_travel(r13, 1, 1, False{}, 0)
  r15 = run_travel(r14, 256, 8, False{}, 248)
  r16 = run_travel(r15, 496, 12, False{}, 484)

  r17 = run_fall(r16, 0, True{}, 1)
  r18 = run_fall(r17, 1, True{}, 2)
  r19 = run_fall(r18, 11, True{}, 12)
  r20 = run_fall(r19, 12, True{}, 12)
  r21 = run_fall(r20, 0, False{}, 1)
  r22 = run_fall(r21, 1, False{}, 0)
  r23 = run_fall(r22, 2, False{}, 1)
  r24 = run_fall(r23, 11, False{}, 10)
  r25 = run_fall(r24, 12, False{}, 11)

  r26 = run_dir(r25, 0, True{}, 1)
  r27 = run_dir(r26, 1, True{}, 1)
  r28 = run_dir(r27, 12, True{}, 1)
  r29 = run_dir(r28, 0, False{}, 1)
  r30 = run_dir(r29, 1, False{}, 0)
  r31 = run_dir(r30, 8, False{}, 0)

  r32 = run_capx(r31, 0, 0)
  r33 = run_capx(r32, 47, 0)
  r34 = run_capx(r33, 48, 0)
  r35 = run_capx(r34, 49, 1)
  r36 = run_capx(r35, 100, 52)
  r37 = run_capx(r36, 600, 552)

  r38 = run_capw(r37, 0, 8)
  r39 = run_capw(r38, 8, 16)
  r40 = run_capw(r39, 47, 55)
  r41 = run_capw(r40, 48, 56)
  r42 = run_capw(r41, 100, 56)
  r43 = run_capw(r42, 504, 56)
  r44 = run_capw(r43, 505, 55)
  r45 = run_capw(r44, 511, 49)
  r46 = run_capw(r45, 512, 48)
  r47 = run_capw(r46, 600, 0)
  r48 = run_capw(r47, 1000, 0)

  r49 = run_mix(r48, 0, 1013904223)
  r50 = run_mix(r49, 1, 1015568748)
  r51 = run_mix(r50, 123456789, 920370032)
  r52 = run_mix(r51, 4294967295, 1012239698)

  r52

def print_result(res: TestRes) -> IO(Unit):
  match res:
    case R{lines, passed}:
      IO.print(lines ++ "TESTS: " ++ U32.show(passed) ++ "/" ++ "52" ++ "\n")

def main() -> IO(Unit):
  print_result(all_tests())
