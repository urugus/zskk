# zskk

## 概要
zskk は Zsh 向けの SKK ライクなかな漢字変換プラグインです。辞書検索・入力バッファ・ZLE ウィジェットを疎結合に設計し、軽量なスクリプトのみでインタラクティブな変換体験を提供します。

## 特徴
- `zskk-engine`, `zskk-input`, `zskk-widgets` が責務を分担し、エンジン状態とキー入力を明確に分離。
- 標準辞書 `jisyo/SKK-JISYO.sample` を同梱し、個人辞書は外部ファイルに保存可能。
- `zstyle` や環境変数経由でキー割り当て・初期モード・辞書パスを柔軟に調整。

## 前提条件
- Zsh 5.8 以降 (ZLE と `zsh/system` モジュールが利用可能なこと)
- SKK 形式辞書ファイル (同梱サンプルまたは任意の辞書)

## インストール
1. リポジトリを取得します。
   ```sh
   git clone https://github.com/urugus/zskk.git
   ```
2. プラグイン関数を `fpath` に追加し、エントリポイントを読み込みます。
   ```sh
   fpath=(/path/to/zskk/functions $fpath)
   source /path/to/zskk/zskk.plugin.zsh
   ```
3. zinit を利用する場合は、次の設定を `.zshrc` に追記します。
   ```zsh
   zinit ice wait lucid
   zinit light urugus/zskk
   # 辞書やウィジェット設定を zstyle で調整する場合はここに追記
   ```
   `zinit light` で読み込むと、`zskk.plugin.zsh` が自動的に source され、`functions/` 以下が `fpath` に追加されます。外部辞書を使う場合は同じファイル内で `export ZSKK_DICT_PATH=...` を定義してください。

## 使い始める
ターミナルで Zsh を起動した状態で `source zskk.plugin.zsh` を実行すると、`convert-next` などの ZLE ウィジェットがバインドされ、スペースキーで変換が開始されます。辞書未初期化時には警告が表示されるため、`ZSKK_DICT_PATH` か `zstyle ':zskk:dict' path` で辞書を指定してください。

## 操作方法
デフォルトバインディングは `AGENTS.md` と同じくスペースと制御キー中心です。主要操作は以下のとおりです。
- かな読みを入力してスペース (`convert-next`) を押すと最初の候補が表示されます。
- `Ctrl-K` (`convert-prev`) で前の候補、スペースで次の候補に移動します。
- `Ctrl-J` (`convert-commit`) で候補を確定、`Ctrl-G` (`convert-cancel`) で変換を取り消してプレーンな読みを残します。
- `Ctrl-]` (`toggle-mode`) でひらがな/カタカナモードを切り替えます。
- テキスト挿入中に `toggle-mode` を使うと、その後の `convert-next` がカタカナ候補を優先します。
これらの割り当ては `zstyle ':zskk:bindkey'` や `ZSKK_BINDKEY_*` 環境変数で変更可能です。

## 設定
- zstyle による例:
  ```sh
  zstyle ':zskk:dict' path "$HOME/.skk-jisyo"
  zstyle ':zskk:init' mode 'katakana'
  zstyle ':zskk:bindkey' convert-next ' ' '^J'
  ```
- 環境変数による例:
  ```sh
  export ZSKK_DICT_PATH=~/Library/SKK-JISYO
  export ZSKK_BINDKEY_CONVERT_COMMIT=$'\n'
  ```
設定後に `zskk-init` を再実行するか、新しいシェルでプラグインを読み込み直すと反映されます。

## 開発・テスト
開発フローやガイドラインは `AGENTS.md` を参照してください。テストは Zsh 製のシナリオベース仕様で、次のコマンドで全件が実行できます。
```sh
for spec in tests/*-spec.zsh; do zsh "$spec" || break; done
```
特定領域だけ検証したい場合は `zsh tests/engine-spec.zsh` のように個別実行が可能です。テストは一時辞書 `tests/tmp-personal-jisyo` を生成するため、終了後に削除してください。

## ディレクトリ構成
- `functions/` — オートロードされるコア関数群。
- `jisyo/` — サンプル辞書や辞書関連リソース。
- `tests/` — `*-spec.zsh` シナリオと共通ヘルパー。
- `docs/` — 設計メモや進捗レポート。
- `zskk.plugin.zsh` — プラグインの初期化スクリプト。

## ライセンス
現時点でライセンスファイルは同梱されていません。利用・配布ポリシーはリポジトリ管理者に確認してください。
