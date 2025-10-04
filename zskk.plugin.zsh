# zskk.plugin.zsh -- entry point for the zskk zsh plugin

if [[ -n ${_ZSKK_PLUGIN_SOURCED:-} ]]; then
  return 0
fi

emulate -L zsh -o extended_glob

typeset -g _ZSKK_PLUGIN_SOURCED=1

# Determine plugin root directory and ensure autoload path is available.
local script_path=${${(%):-%N}:A}
typeset -g ZSKK_PLUGIN_ROOT=${script_path:h}
fpath=(${ZSKK_PLUGIN_ROOT}/functions $fpath)

# Load required zsh modules. Abort early if mandatory modules are missing.
local required_modules=(
  zsh/zle
  zsh/parameter
  zsh/system
)
for module in ${required_modules}; do
  if ! zmodload ${module} 2>/dev/null; then
    print -u2 -- "zskk: failed to load required module: ${module}"
    return 1
  fi
done

# Autoload public entry points.
autoload -Uz zskk-init zskk-unload

# Decide whether to run automatic initialization when the plugin is sourced.
function zskk::maybe-auto-init {
  emulate -L zsh

  local auto_init=${ZSKK_AUTO_INIT:-1}
  if zstyle -t ':zskk:init' auto; then
    auto_init=1
  elif zstyle -t ':zskk:init' no-auto; then
    auto_init=0
  fi

  if (( auto_init )); then
    zskk-init "$@"
  fi
}

zskk::maybe-auto-init "$@"
