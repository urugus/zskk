# Repository Guidelines

## プロジェクト構成とモジュール配置
zskk は Zsh のかな漢字変換プラグインで、状態管理と ZLE ウィジェットを分離して実装しています。
- `functions/`: `zskk-engine` や `zskk-input` などのオートロード関数を収録し、各ファイルが 1 モジュールを担当します。
- `jisyo/`: ベース辞書 `SKK-JISYO.sample` を提供し、テストでは一時ファイル `tests/tmp-personal-jisyo` を生成します。
- `tests/`: `*-spec.zsh` が挙動別シナリオを定義し、`lib/` フォルダに共通のセットアップとアサーション関数があります。
- `docs/`: 実装計画や進捗レポートを格納し、仕様更新時はここも同期してください。
- `zskk.plugin.zsh`: プラグインのエントリーポイントで、ZLE 依存モジュール読み込みと自動初期化を制御します。

## ビルド・テスト・ローカル実行コマンド
- `source zskk.plugin.zsh`: インタラクティブな Zsh でプラグインを読み込み、ウィジェットを登録します。
- `for spec in tests/*-spec.zsh; do zsh "$spec"; done`: すべての仕様テストを実行し、最初の失敗で終了します。
- `zsh tests/engine-spec.zsh`: エンジン周辺のみ再確認したいときの最小コマンドです。
- `ZSKK_DICT_PATH=./jisyo/SKK-JISYO.sample zsh -i -c 'source zskk.plugin.zsh'`: リポジトリ同梱辞書で手動動作をスモークテストします。

## コーディングスタイルと命名規約
インデントは 2 スペースを基本とし、`emulate -L zsh -o extended_glob` を最初に宣言します。状態と設定は `typeset -gA ZSKK_STATE` のように連想配列で保持し、副作用のある関数は `zskk::engine-reset` のように `zskk::領域-動詞` 形式で命名します。テストヘルパーは `zskk::test-reset-*` プレフィックスに揃えてください。

## テスト指針
新しい振る舞いを追加する際は対応する `*-spec.zsh` にシナリオを追加し、`assert_eq` や `fail` を使って期待値を明示します。辞書を更新するテストは `tests/tmp-personal-jisyo` を削除してから実行し、副作用を残さないこと。コメントでセクションを区切り、準備・操作・検証の順番を保って読みやすさを維持してください。

## コミットとプルリクエスト
`git log` に倣い、"Handle okuri input during conversion" のように 50 文字以内の英語命令形サマリを用い、末尾ピリオドは付けません。プルリクエストでは目的、主要変更点、手元テスト結果 (`zsh tests/engine-spec.zsh` など) を箇条書きで記し、関連 Issue をリンクしてください。辞書や設定値を触る場合は再現手順とロールバック方法も添えましょう。

## 設定と辞書運用の注意
`zskk-init` は `ZSKK_CONFIG` に辞書パスや初期モードを取り込み、`zstyle` や環境変数 (`ZSKK_DICT_PATH`, `ZSKK_PERSONAL_DICT`) を優先します。本番運用では個人辞書をバージョン管理外に置き、テスト後は `tests/tmp-personal-jisyo` を削除して漏洩を防いでください。追加辞書を導入する場合は `docs/` に手順を追記し、レビュー時に共有します。
