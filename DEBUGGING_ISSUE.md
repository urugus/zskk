# zskk Widget Call Issue - Debug Report

## 問題の概要

zskkプラグインで、`zskk::widgets-call-original`関数が元のウィジェットを呼び出す際に以下のエラーが発生し、入力が一切できなくなる。

```
No such widget `.zskk-orig-self-insert'
```

## 症状

1. **何も入力できない**: キーを押すと上記のエラーメッセージが表示されるのみ
2. **Enterキーも効かない**: コマンド実行不可
3. **モード切り替え(Ctrl-])も視覚的フィードバックなし**

## エラーの詳細

- エラーメッセージに**ドット(`.`)で始まるウィジェット名**が表示される
- `.zskk-orig-self-insert` となっているが、正しくは `zskk-orig-self-insert` (ドットなし)
- zshでドットで始まるウィジェット名は組み込みウィジェットを意味する

## 現在の実装

### functions/zskk-widgets

**問題の関数**: `zskk::widgets-call-original` (行47-62)

```zsh
function zskk::widgets-call-original {
  emulate -L zsh

  local logical=$1
  shift
  local original=${ZSKK_WIDGET_ORIGINAL[${logical}]:-}

  if [[ -z ${original} ]]; then
    print -u2 "zskk: no original widget registered for '${logical}'"
    return 1
  fi

  # Directly call the widget
  zle "${original}" -- "$@"
  return $?
}
```

**呼び出し元**: `zskk::widget-self-insert` (行471-478)

```zsh
function zskk::widget-self-insert {
  emulate -L zsh -o extended_glob

  local char=${KEYS:-}
  if ! zskk::widgets-handle-insert "${char}"; then
    zskk::widgets-call-original self-insert "$@"
  fi
}
```

### ウィジェットの登録 (functions/zskk-init 行157-171)

```zsh
local -A overrides=(
  self-insert zskk::widget-self-insert
  backward-delete-char zskk::widget-backspace
  accept-line zskk::widget-accept-line
)

local widget handler alias
for widget handler in ${(kv)overrides}; do
  alias="zskk-orig-${widget}"
  if zle -A "${widget}" "${alias}" 2>/dev/null; then
    zskk::widgets-register-original "${widget}" "${alias}"
    ZSKK_BOUND_WIDGETS+=("override:${widget}:${alias}")
    zle -N "${widget}" "${handler}"
  fi
done
```

## 確認された状態

### ウィジェットの存在確認

```bash
# zle -la の出力に以下が存在:
zskk-orig-self-insert
zskk-orig-accept-line
zskk-orig-backward-delete-char

# ZSKK_WIDGET_ORIGINAL の内容:
typeset -A ZSKK_WIDGET_ORIGINAL=(
  [accept-line]=zskk-orig-accept-line
  [backward-delete-char]=zskk-orig-backward-delete-char
  [self-insert]=zskk-orig-self-insert
)
```

**ウィジェット自体は正しく登録されている**

## 試した修正

### 修正1: ZLE_LINE_EDITOR チェックの削除
- `widgets-call-original`と`widgets-update-status`から`ZLE_LINE_EDITOR`チェックを削除
- 結果: エラーは継続

### 修正2: grep チェックの削除
- `zle -la | grep -Fxq`のチェックを削除し、直接`zle`コマンドを呼ぶように変更
- 結果: エラーは継続

### 修正3: self-insert ロジックの反転
- `if zskk::widgets-handle-insert`を`if ! zskk::widgets-handle-insert`に変更
- `direct`モードで`return 1`を返したときに元のウィジェットを呼ぶように修正
- 結果: ロジックは正しくなったがエラーは継続

## 疑問点

1. **なぜドット(`.`)が付くのか**
   - `zle "${original}" -- "$@"` を実行しているのに
   - エラーメッセージは`.zskk-orig-self-insert`と表示される
   - zleコマンドのパース方法に問題がある可能性

2. **`--` の使い方**
   - `zle widget-name -- "$@"` という呼び出しが正しいか
   - `--` の後に引数がない場合の動作は？

3. **`zle -A` によるウィジェットコピー**
   - `zle -A self-insert zskk-orig-self-insert` で正しくコピーされているか
   - コピーされたウィジェットが正しく呼び出せるか

## 環境情報

- Zsh バージョン: 5.9
- OS: macOS (Darwin 24.6.0)
- プラグインマネージャー: zinit
- 他のプラグイン: zsh-autosuggestions, zsh-syntax-highlighting など

## 一時的な対処

`/Users/urugus/.config/zsh/rc/pluginlist.zsh` でzskkを無効化:

```zsh
# zinit lucid \
#   if"(( ${ZSH_VERSION%%.*} > 4.4))" \
#   light-mode for urugus/zskk
```

## 期待される動作

1. **directモード(デフォルト)**: 通常の英字入力、スペースもそのまま入力
2. **Ctrl-]でモード切り替え**: `direct` ↔ `hiragana`
3. **hiraganaモード**: ローマ字→ひらがな変換、スペースで漢字変換

## 調査が必要な点

1. `zle`コマンドでウィジェットを呼び出す正しい方法
2. `zle -A`でコピーしたウィジェットの呼び出し方
3. エラーメッセージのドット(`.`)が付く原因
4. `emulate -L zsh`がウィジェット呼び出しに与える影響

## 参考情報

- リポジトリ: https://github.com/urugus/zskk
- 最新コミット: 8571ff9 (Simplify widgets-call-original and add debug message)
- 問題の関数: `functions/zskk-widgets` の `zskk::widgets-call-original`

## 次のステップ

新しいClaude セッションで以下を依頼:

1. `zle`コマンドでウィジェットを呼び出す正しい方法を調査
2. なぜドット(`.`)が付くのかを特定
3. 正しい修正方法を提案・実装

---

**重要**: この問題により、ユーザーは何も入力できない状態になります。早急な修正が必要です。
