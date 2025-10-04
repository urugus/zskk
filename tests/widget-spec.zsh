#!/usr/bin/env zsh
set -uo pipefail
setopt pipefail

BASE_DIR=${0:A:h}/..
source "${BASE_DIR}/tests/lib/setup.zsh"
source "${BASE_DIR}/tests/lib/assert.zsh"
source "${BASE_DIR}/functions/zskk-widgets"

zskk::input-init
if ! zskk::dict-init; then
  print -u2 -- 'FAIL: dict-init failed'
  exit 1
fi
zskk::engine-init
zskk::widgets-init

typeset -g LBUFFER=""

function reset_state {
  zskk::test-reset-state
  zskk::input-reset
  zskk::engine-reset
  zskk::conversion-reset
  LBUFFER=""
  zskk::widgets-update-status
}

# --- Basic insertion and status message ---
reset_state
zskk::widgets-handle-insert k
assert_eq "${REPLY}" "" "self insert stage1 committed"
assert_eq "${LBUFFER}" "" "self insert stage1 buffer"
assert_eq "${ZSKK_STATE[composing]}" "k" "stage1 composing"
assert_eq "${ZSKK_WIDGET_LAST_MESSAGE}" "hiragana:k" "stage1 status"

zskk::widgets-handle-insert a
assert_eq "${LBUFFER}" "か" "stage2 buffer"
assert_eq "${ZSKK_STATE[preedit]}" "か" "stage2 preedit"
assert_eq "${ZSKK_STATE[composing]}" "" "stage2 composing"
assert_eq "${ZSKK_WIDGET_LAST_MESSAGE}" "hiragana:か" "stage2 status"

# --- Backspace removes preedit characters ---
zskk::widgets-handle-backspace
assert_eq "${LBUFFER}" "" "backspace buffer cleared"
assert_eq "${ZSKK_STATE[preedit]}" "" "backspace preedit cleared"
assert_eq "${ZSKK_STATE[composing]}" "" "backspace composing cleared"

# --- Conversion start, cycle, commit ---
reset_state
for ch in n i h o n; do
  zskk::widgets-handle-insert "${ch}"
done
assert_eq "${LBUFFER}" "にほ" "pre-conversion buffer"
assert_eq "${ZSKK_STATE[preedit]}" "にほ" "pre-conversion preedit"
assert_eq "${ZSKK_STATE[composing]}" "n" "pre-conversion composing"

zskk::widgets-start-conversion
assert_eq "${LBUFFER}" "日本" "conversion buffer after start"
assert_eq "${ZSKK_STATE[current_candidate]}" "日本" "current candidate after start"
assert_eq "${ZSKK_STATE[candidate_count]}" "2" "candidate count after start"
assert_eq "${ZSKK_WIDGET_LAST_MESSAGE}" "hiragana:候補(日本)" "status after start"

zskk::widgets-cycle-next
assert_eq "${LBUFFER}" "二本" "buffer after next"
assert_eq "${ZSKK_STATE[current_candidate]}" "二本" "current candidate after next"
assert_eq "${ZSKK_STATE[candidate_index]}" "1" "candidate index after next"

zskk::widgets-commit
assert_eq "${ZSKK_STATE[candidate_count]}" "0" "candidate count after commit"
assert_eq "${ZSKK_STATE[last_commit]}" "二本" "last commit after commit"
assert_eq "${ZSKK_WIDGET_LAST_MESSAGE}" "" "status cleared after commit"
assert_eq "${LBUFFER}" "二本" "buffer after commit"

# --- Okuri handling ---
reset_state
for ch in k a; do
  zskk::widgets-handle-insert "${ch}"
done
zskk::widgets-handle-insert K
zskk::widgets-handle-insert u
assert_eq "${ZSKK_STATE[preedit]}" "か" "okuri stem stored in preedit"
assert_eq "${ZSKK_STATE[okuri]}" "く" "okuri buffer stores kana"
assert_eq "${LBUFFER}" "かく" "buffer shows stem + okuri"

zskk::widgets-start-conversion
assert_eq "${LBUFFER}" "書く" "okuri conversion buffer"
assert_eq "${ZSKK_STATE[current_candidate]}" "書く" "current candidate with okuri"
assert_eq "${ZSKK_STATE[candidate_count]}" "1" "single candidate for okuri"

zskk::widgets-commit
assert_eq "${ZSKK_STATE[last_commit]}" "書く" "okuri commit recorded"
assert_eq "${ZSKK_STATE[okuri]}" "" "okuri cleared after commit"
assert_eq "${ZSKK_STATE[okuri_mode]}" "0" "okuri mode reset after commit"

reset_state
for ch in k a K u; do
  zskk::widgets-handle-insert "${ch}"
done
zskk::widgets-handle-backspace
assert_eq "${ZSKK_STATE[okuri]}" "" "okuri cleared after backspace"
assert_eq "${ZSKK_STATE[preedit]}" "か" "stem preserved after okuri backspace"
assert_eq "${LBUFFER}" "か" "buffer reflects removed okuri"

# --- Conversion cancel restores reading ---
# --- Conversion cancel restores reading ---
reset_state
for ch in n i h o n; do
  zskk::widgets-handle-insert "${ch}"
done
zskk::widgets-start-conversion
zskk::widgets-cancel
assert_eq "${LBUFFER}" "にほん" "buffer after cancel"
assert_eq "${ZSKK_STATE[preedit]}" "にほん" "preedit after cancel"
assert_eq "${ZSKK_STATE[candidate_count]}" "0" "candidate count after cancel"
assert_eq "${ZSKK_WIDGET_LAST_MESSAGE}" "hiragana:にほん" "status after cancel"

# --- Mode toggle switches states ---
reset_state
ZSKK_STATE[mode]=direct
zskk::widgets-toggle-mode
assert_eq "${ZSKK_STATE[mode]}" "hiragana" "toggle enters hiragana"
zskk::widgets-toggle-mode
assert_eq "${ZSKK_STATE[mode]}" "direct" "toggle returns to direct"

# --- Fallback conversion keeps reading ---
reset_state
for ch in h o g e; do
  zskk::widgets-handle-insert "${ch}"
done
RC=0
zskk::widgets-start-conversion || RC=$?
assert_eq "${RC}" "0" "fallback start handled"
assert_eq "${LBUFFER}" "ほげ" "fallback buffer"
assert_eq "${ZSKK_STATE[candidate_count]}" "0" "fallback candidate count"

print -- "All ${ASSERT_COUNT} assertions passed."
