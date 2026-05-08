# Lean Gherkin ロードマップ

この文書は `design.md` から将来的な拡張候補を分離したものである。

## 1. Gherkin 互換性の向上

将来的には以下を追加する。

- `Background`
- `Rule`
- `Scenario Outline`
- `Examples`
- `DataTable`
- `DocString`
- tags
- comments
- 日本語キーワード

例:

```lean4
feature "Calculator" do
  background do
    given "a calculator"

  scenario_outline "addition" do
    when "I add <x> and <y>"
    then "the result should be <z>"
    examples
      | x | y | z |
      | 1 | 2 | 3 |
```

## 2. 日本語 DSL

日本語 Gherkin 風の構文も検討する。

```lean4
機能 "計算機" do
  シナリオ "足し算" do
    前提 "計算機がある"
    もし "1 と 2 を足す"
    ならば "結果は 3 である"
```

ただし、Lean の識別子・構文ルールとの相性を確認する必要がある。

## 3. レポート出力

将来的に以下を出力できるようにする。

- text report
- JSON report
- JUnit XML
- Markdown report
