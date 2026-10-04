import Base
import ./difficulty.bend as Diff
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

def run_speed(res: TestRes, score: U32, wt: U32, +want: U32) -> TestRes:
  match res:
    case R{lines, passed}:
      +got = Diff.Game.speed_of(score, wt)
      eq = U32.is_eq(got, want)
      nl = lines ++ check("speed_of", got, want)
      np = (passed + S.Game.pick(eq, 1, 0) : U32)
      R{nl, np}

def run_gap(res: TestRes, t: U32, +want: U32) -> TestRes:
  match res:
    case R{lines, passed}:
      +got = Diff.Game.gap_of(t)
      eq = U32.is_eq(got, want)
      nl = lines ++ check("gap_of", got, want)
      np = (passed + S.Game.pick(eq, 1, 0) : U32)
      R{nl, np}

def all_tests() -> TestRes:
  r1 = run_speed(R{"", 0}, 0, 0, 3)
  r2 = run_speed(r1, 0, 1, 3)
  r3 = run_speed(r2, 0, 7, 3)
  r4 = run_speed(r3, 0, 8, 3)
  r5 = run_speed(r4, 1, 0, 4)
  r6 = run_speed(r5, 1, 1, 3)
  r7 = run_speed(r6, 1, 7, 3)
  r8 = run_speed(r7, 1, 8, 4)
  r9 = run_speed(r8, 8, 0, 4)
  r10 = run_speed(r9, 8, 3, 4)
  r11 = run_speed(r10, 8, 7, 4)
  r12 = run_speed(r11, 39, 0, 8)
  r13 = run_speed(r12, 39, 6, 8)
  r14 = run_speed(r13, 39, 7, 7)
  r15 = run_speed(r14, 39, 15, 7)
  r16 = run_speed(r15, 40, 0, 8)
  r17 = run_speed(r16, 40, 7, 8)
  r18 = run_speed(r17, 41, 0, 8)
  r19 = run_speed(r18, 41, 7, 8)
  r20 = run_speed(r19, 1000, 0, 8)
  r21 = run_speed(r20, 1000, 7, 8)

  r22 = run_gap(r21, 0, 128)
  r23 = run_gap(r22, 1, 112)
  r24 = run_gap(r23, 2, 96)
  r25 = run_gap(r24, 3, 128)
  r26 = run_gap(r25, 7, 128)

  r26

def print_result(res: TestRes) -> IO(Unit):
  match res:
    case R{lines, passed}:
      IO.print(lines ++ "TESTS: " ++ U32.show(passed) ++ "/" ++ "26" ++ "\n")

def main() -> IO(Unit):
  print_result(all_tests())
