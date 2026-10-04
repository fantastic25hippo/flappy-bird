#!/bin/sh
BEND="${BEND:-bend}"

fail=0

echo "Running test_physics.bend..."
out_phys=$($BEND test_physics.bend 2>&1)
st_phys=$?
echo "$out_phys"

if [ $st_phys -ne 0 ]; then
  fail=1
elif echo "$out_phys" | grep -q "FAIL"; then
  fail=1
else
  p_phys=$(echo "$out_phys" | grep "TESTS:" | sed -n 's/.*TESTS: \([0-9]*\)\/.*/\1/p')
  t_phys=$(echo "$out_phys" | grep "TESTS:" | sed -n 's/.*TESTS: [0-9]*\/\([0-9]*\).*/\1/p')
  if [ "$p_phys" != "$t_phys" ] || [ -z "$p_phys" ]; then
    fail=1
  fi
fi

echo "Running test_difficulty.bend..."
out_diff=$($BEND test_difficulty.bend 2>&1)
st_diff=$?
echo "$out_diff"

if [ $st_diff -ne 0 ]; then
  fail=1
elif echo "$out_diff" | grep -q "FAIL"; then
  fail=1
else
  p_diff=$(echo "$out_diff" | grep "TESTS:" | sed -n 's/.*TESTS: \([0-9]*\)\/.*/\1/p')
  t_diff=$(echo "$out_diff" | grep "TESTS:" | sed -n 's/.*TESTS: [0-9]*\/\([0-9]*\).*/\1/p')
  if [ "$p_diff" != "$t_diff" ] || [ -z "$p_diff" ]; then
    fail=1
  fi
fi

[ $fail -eq 0 ]
