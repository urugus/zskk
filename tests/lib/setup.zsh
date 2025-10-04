set -uo pipefail
setopt pipefail

if [[ -z ${BASE_DIR:-} ]]; then
  typeset -g BASE_DIR=${0:A:h}/..
fi
cd "${BASE_DIR}"

source ./functions/zskk-dict
source ./functions/zskk-input
source ./functions/zskk-engine

typeset -g ZSKK_PLUGIN_ROOT=${BASE_DIR}

typeset -gA ZSKK_CONFIG
function zskk::test-reset-config {
  emulate -L zsh

  ZSKK_CONFIG=(
    dict_path "${BASE_DIR}/jisyo/SKK-JISYO.sample"
    personal_dict "${BASE_DIR}/tests/tmp-personal-jisyo"
    initial_mode "hiragana"
    keymap "main"
  )
}

function zskk::test-reset-state {
  emulate -L zsh

  typeset -gA ZSKK_STATE
  ZSKK_STATE=(
    mode "${ZSKK_CONFIG[initial_mode]}"
    composing ""
    preedit ""
    okuri ""
    candidates ""
    lookup_key ""
    candidate_count 0
    candidate_index -1
    current_candidate ""
    last_commit ""
  )

  typeset -gA ZSKK_CACHE
  ZSKK_CACHE=()
}

zskk::test-reset-config
zskk::test-reset-state
