# 長野県新型コロナウイルス感染警戒レベル通知

長野県 圏域ごとの新型コロナウイルス感染警戒レベルを通知するRubyスクリプトです。

## 動作環境

- Ruby
  > [asdf](https://asdf-vm.com/#/core-manage-asdf) を参考にしてインストールしてください。

## 環境構築

1. 動作環境を満たした上で `bin/setup` を実行してください。
2. `config/config.yml` の内容を環境に合わせて適宜調整してください。

## 開発コマンド一覧

```sh
# スクリプトを手動実行する
bin/run
# RuboCopによる静的解析を実行する
bundle exec rubocop
# 最新でないgemのリストを表示する
bundle outdated
```

## Copyright

(c) 2021 Hideki Miyamoto
