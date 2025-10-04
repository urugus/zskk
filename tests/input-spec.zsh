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

# --- Basic hiragana conversion ---
zskk::input-reset
zskk::input-feed hiragana k
assert_eq "${REPLY}" "" "hiragana ka stage1 commit"
assert_eq "${ZSKK_STATE[preedit]}" "" "hiragana ka stage1 preedit"
assert_eq "${ZSKK_STATE[composing]}" "k" "hiragana ka stage1 composing"
zskk::input-feed hiragana a
assert_eq "${REPLY}" "か" "hiragana ka stage2 commit"
assert_eq "${ZSKK_STATE[preedit]}" "か" "hiragana ka stage2 preedit"
assert_eq "${ZSKK_STATE[composing]}" "" "hiragana ka stage2 composing"

# --- Double consonant small tsu ---
zskk::input-reset
typeset accum=""
zskk::input-feed hiragana k
accum+="${REPLY}"
zskk::input-feed hiragana k
accum+="${REPLY}"
zskk::input-feed hiragana a
accum+="${REPLY}"
assert_eq "${accum}" "っか" "double consonant outputs small tsu"
assert_eq "${ZSKK_STATE[preedit]}" "っか" "double consonant preedit accumulates"
assert_eq "${ZSKK_STATE[composing]}" "" "double consonant clears composing"

# --- 'n' handling ---
zskk::input-reset
zskk::input-feed hiragana n
assert_eq "${REPLY}" "" "single n commits nothing"
assert_eq "${ZSKK_STATE[preedit]}" "" "single n preedit"
assert_eq "${ZSKK_STATE[composing]}" "n" "single n composing"
zskk::input-feed hiragana n
assert_eq "${REPLY}" "ん" "double n commits syllabic n"
assert_eq "${ZSKK_STATE[preedit]}" "ん" "double n preedit"
assert_eq "${ZSKK_STATE[composing]}" "n" "double n leaves pending n"
zskk::input-flush hiragana
assert_eq "${REPLY}" "ん" "flush converts pending n"
assert_eq "${ZSKK_STATE[preedit]}" "ん" "flush keeps preedit reading"
assert_eq "${ZSKK_STATE[composing]}" "" "flush clears composing"

# --- Katakana mode ---
ZSKK_STATE[mode]=katakana
zskk::input-reset
zskk::input-feed katakana k
zskk::input-feed katakana a
assert_eq "${REPLY}" "カ" "katakana conversion"
assert_eq "${ZSKK_STATE[preedit]}" "カ" "katakana preedit"
assert_eq "${ZSKK_STATE[composing]}" "" "katakana composing cleared"

# --- Dictionary loading ---
if ! zskk::dict-get あい; then
  fail "dictionary lookup for あい"
fi
typeset joined_candidates="${(j:, :)reply}"
assert_eq "${joined_candidates}" "愛, 相" "dictionary candidates match sample"

assert_eq "${ZSKK_DICT_STATS[entries]}" "4" "dictionary entry count from sample"

print -- "All ${ASSERT_COUNT} assertions passed."
