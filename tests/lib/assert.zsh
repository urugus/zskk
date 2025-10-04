typeset -gi ASSERT_COUNT=0

function fail {
  print -u2 -- "FAIL: $*"
  exit 1
}

function assert_eq {
  local actual="$1"
  local expect="$2"
  local message="$3"
  (( ASSERT_COUNT++ ))
  if [[ "${actual}" != "${expect}" ]]; then
    fail "${message}: expected '${expect}' but got '${actual}'"
  fi
}
