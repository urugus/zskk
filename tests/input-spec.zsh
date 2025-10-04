#!/usr/bin/env zsh
set -uo pipefail
setopt pipefail

BASE_DIR=${0:A:h}/..
cd "${BASE_DIR}"

source ./functions/zskk-dict
source ./functions/zskk-input

typeset -g ZSKK_PLUGIN_ROOT=${BASE_DIR}

typeset -gA ZSKK_CONFIG
ZSKK_CONFIG=(
  dict_path "${BASE_DIR}/jisyo/SKK-JISYO.sample"
  personal_dict "${BASE_DIR}/tests/tmp-personal-jisyo"
  initial_mode "hiragana"
  keymap "main"
)

typeset -gA ZSKK_STATE
ZSKK_STATE=(
  mode "hiragana"
  composing ""
  preedit ""
  okuri ""
  candidates ""
)

typeset -gA ZSKK_CACHE
ZSKK_CACHE=()

zskk::input-init
if ! zskk::dict-init; then
  print -u2 -- 'FAIL: dict-init failed'
  exit 1
fi

integer ASSERT_COUNT=0

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

# --- Basic hiragana conversion ---
zskk::input-reset
zskk::input-feed hiragana k
assert_eq "${REPLY}" "" "hiragana ka stage1 commit"
assert_eq "${ZSKK_STATE[preedit]}" "k" "hiragana ka stage1 preedit"
zskk::input-feed hiragana a
assert_eq "${REPLY}" "か" "hiragana ka stage2 commit"
assert_eq "${ZSKK_STATE[preedit]}" "" "hiragana ka stage2 preedit"

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
assert_eq "${ZSKK_STATE[preedit]}" "" "double consonant clears preedit"

# --- 'n' handling ---
zskk::input-reset
zskk::input-feed hiragana n
assert_eq "${REPLY}" "" "single n commits nothing"
assert_eq "${ZSKK_STATE[preedit]}" "n" "single n preedit"
zskk::input-feed hiragana n
assert_eq "${REPLY}" "ん" "double n commits syllabic n"
assert_eq "${ZSKK_STATE[preedit]}" "n" "double n leaves pending n"
zskk::input-flush hiragana
assert_eq "${REPLY}" "ん" "flush converts pending n"
assert_eq "${ZSKK_STATE[preedit]}" "" "flush clears preedit"

# --- Katakana mode ---
ZSKK_STATE[mode]=katakana
zskk::input-reset
zskk::input-feed katakana k
zskk::input-feed katakana a
assert_eq "${REPLY}" "カ" "katakana conversion"
assert_eq "${ZSKK_STATE[preedit]}" "" "katakana preedit cleared"

# --- Dictionary loading ---
if ! zskk::dict-get あい; then
  fail "dictionary lookup for あい"
fi
typeset joined_candidates="${(j:, :)reply}"
assert_eq "${joined_candidates}" "愛, 相" "dictionary candidates match sample"

assert_eq "${ZSKK_DICT_STATS[entries]}" "4" "dictionary entry count from sample"

print -- "All ${ASSERT_COUNT} assertions passed."
