#!/usr/bin/env zsh
set -uo pipefail
setopt pipefail

BASE_DIR=${0:A:h}/..
source "${BASE_DIR}/tests/lib/setup.zsh"
source "${BASE_DIR}/tests/lib/assert.zsh"

if ! zskk::dict-init; then
  print -u2 -- 'FAIL: dict-init failed'
  exit 1
fi

zskk::engine-init

# --- Candidate lookup ---
if zskk::engine-begin にほん; then
  assert_eq "${REPLY}" "日本" "engine begin returns first candidate"
else
  fail "engine begin にほん should succeed"
fi
assert_eq "${ZSKK_STATE[candidate_count]}" "2" "candidate count tracked"
assert_eq "${ZSKK_STATE[candidate_index]}" "0" "candidate index initialized"

# --- Candidate cycling ---
zskk::engine-next
assert_eq "${REPLY}" "二本" "engine next cycles to second candidate"
zskk::engine-prev
assert_eq "${REPLY}" "日本" "engine prev wraps back to first candidate"

# --- Candidate selection ---
zskk::engine-select 1
assert_eq "${REPLY}" "二本" "engine select picks requested candidate"

# --- Candidate list export ---
zskk::engine-list
assert_eq "${(j:, :)reply}" "日本, 二本" "engine list returns formatted candidates"

# --- Okuri append ---
zskk::engine-begin にほん ご
assert_eq "${REPLY}" "日本ご" "engine begin appends okuri"
zskk::engine-list
assert_eq "${(j:, :)reply}" "日本ご, 二本ご" "engine list appends okuri"

# --- Fallback when no candidates ---
zskk::engine-begin ほげ
assert_eq "${REPLY}" "ほげ" "engine fallback returns reading"
if zskk::engine-has-candidates; then
  fail "engine-has-candidates should report false for missing entries"
fi

# --- Reset clears candidate state ---
zskk::engine-reset
assert_eq "${ZSKK_STATE[candidate_count]}" "0" "engine reset clears count"
assert_eq "${ZSKK_STATE[candidate_index]}" "-1" "engine reset clears index"
assert_eq "${ZSKK_STATE[lookup_key]}" "" "engine reset clears key"

print -- "All ${ASSERT_COUNT} assertions passed."
