# Lean Gherkin 仕様

この文書は Lean Gherkin の仕様と、想定する記法をまとめる。

## 1. 目的

Lean ファイル内に Gherkin 風の仕様記述を埋め込み、`Feature` / `Scenario` / `Given` / `When` / `Then` に相当する構造を Lean の構文として扱えるようにする。

仕様記述は、最終的に以下へ接続できることを目指す。

- Lean の構文としての受理
- AST としての登録・参照
- step definition との対応付け
- 検証、実行、証明との統合

## 2. 初期記法

初期段階では、以下のような Lean 内 DSL を想定する。

```lean4
feature "Calculator" do
  scenario "addition" do
    given "a calculator"
    when "I add 1 and 2"
    then "the result should be 3"
```

初期記法では、本家 Gherkin の完全互換よりも Lean の構文として安定して扱えることを優先する。

## 3. 初期記法で扱う要素

初期実装で扱う要素は以下に限定する。

- `feature`: 仕様全体
- `scenario`: 具体的な振る舞いの例
- `given`: 前提条件
- `when`: 操作・イベント
- `then`: 期待結果
- `and`: 直前 step の補足
- `but`: 直前 step と対比される補足

## 4. 初期記法で扱わない要素

以下は初期仕様には含めず、将来拡張として扱う。

- `Background`
- `Rule`
- `Scenario Outline`
- `Examples`
- tag
- description
- doc string
- data table
- 多言語キーワード
- 本家 Gherkin ファイルの完全な import / export

## 5. 将来検討する記法

より Lean らしい構文として、将来的には以下も検討する。

```lean4
gherkin Feature: Calculator
  Scenario: addition Given a calculator
    When I add 1 and 2
    Then the result should be 3
```

ただし、この記法は Lean の構文制約との相性を慎重に検討する必要があるため、初期実装では正式採用しない。

## 6. 採用方針

初期段階では、文字列ベース DSL を優先する。

理由:

- Lean parser との相性を確認しやすい
- 自然言語風 step を文字列として安全に保持できる
- AST 変換と elaborator 実装に集中できる
- step definition の完全一致方式から始めやすい
- エラー診断の対象を限定しやすい

最小実装の成功後、`Feature:` 風構文や本家 Gherkin 互換記法を追加候補として再評価する。