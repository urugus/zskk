#!/usr/bin/env zsh
set -uo pipefail
setopt pipefail

BASE_DIR=${0:A:h}/..
source "${BASE_DIR}/tests/lib/setup.zsh"
source "${BASE_DIR}/tests/lib/assert.zsh"

zskk::input-init
if ! zskk::dict-init; then
  print -u2 -- 'FAIL: dict-init failed'
  exit 1
fi
zskk::engine-init

# --- Begin conversion after building reading ---
zskk::input-reset
for ch in n i h o n; do
  zskk::input-feed hiragana ${ch}
done
assert_eq "${ZSKK_STATE[preedit]}" "にほ" "preedit accumulates converted kana"
assert_eq "${ZSKK_STATE[composing]}" "n" "pending n stored before flush"

if ! zskk::conversion-begin; then
  fail "conversion begin should succeed for にほん"
fi
assert_eq "${REPLY}" "日本" "conversion begin returns first candidate"
assert_eq "${ZSKK_STATE[lookup_key]}" "にほん" "lookup key recorded"
assert_eq "${ZSKK_STATE[current_candidate]}" "日本" "current candidate tracked"
assert_eq "${ZSKK_STATE[preedit]}" "日本" "preedit shows current candidate"
assert_eq "${ZSKK_STATE[candidate_count]}" "2" "candidate count stored"
assert_eq "${ZSKK_STATE[candidate_index]}" "0" "candidate index initialized"
assert_eq "${ZSKK_STATE[composing]}" "" "composing cleared after conversion begin"

zskk::conversion-next
assert_eq "${REPLY}" "二本" "conversion next cycles candidate"
assert_eq "${ZSKK_STATE[current_candidate]}" "二本" "current candidate updated"
assert_eq "${ZSKK_STATE[preedit]}" "二本" "preedit follows current candidate"
assert_eq "${ZSKK_STATE[candidate_index]}" "1" "candidate index increments"

if ! zskk::conversion-list; then
  fail "conversion list should succeed when candidates exist"
fi
typeset candidate_summary="${(j:, :)reply}"
assert_eq "${candidate_summary}" "日本, 二本" "conversion list returns formatted candidates"

if ! zskk::conversion-commit; then
  fail "conversion commit should succeed with current candidate"
fi
assert_eq "${REPLY}" "二本" "conversion commit yields selected candidate"
assert_eq "${ZSKK_STATE[last_commit]}" "二本" "last commit stored"
assert_eq "${ZSKK_STATE[current_candidate]}" "" "current candidate cleared after commit"
assert_eq "${ZSKK_STATE[preedit]}" "" "preedit cleared after commit"
assert_eq "${ZSKK_STATE[candidate_count]}" "0" "candidate count reset"
assert_eq "${ZSKK_STATE[candidate_index]}" "-1" "candidate index reset"
assert_eq "${ZSKK_STATE[lookup_key]}" "" "lookup key cleared"
assert_eq "${ZSKK_STATE[composing]}" "" "composing remains cleared"

# --- Fallback when no candidates ---
zskk::input-reset
if zskk::conversion-begin ほげ; then
  fail "conversion begin should fail for missing entry"
fi
assert_eq "${REPLY}" "ほげ" "fallback returns reading"
assert_eq "${ZSKK_STATE[current_candidate]}" "ほげ" "fallback stored as current candidate"
assert_eq "${ZSKK_STATE[preedit]}" "ほげ" "fallback reflected in preedit"
assert_eq "${ZSKK_STATE[candidate_count]}" "0" "candidate count zero on fallback"

zskk::conversion-cancel
assert_eq "${REPLY}" "ほげ" "conversion cancel returns original reading"
assert_eq "${ZSKK_STATE[current_candidate]}" "" "current candidate cleared after cancel"
assert_eq "${ZSKK_STATE[preedit]}" "ほげ" "preedit restored after cancel"
assert_eq "${ZSKK_STATE[lookup_key]}" "" "lookup key cleared after cancel"

print -- "All ${ASSERT_COUNT} assertions passed."
