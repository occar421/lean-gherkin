# Lean Gherkin 設計プラン

## 1. 目的

本プロジェクトでは、Lean4 の `macro` および `elab` 機構を用いて、Lean 上で Gherkin 記法に近い仕様記述 DSL を実現する。

目標は以下の通りである。

- Lean ファイル内に Gherkin 風の `Feature` / `Scenario` / `Given` / `When` / `Then` を記述できるようにする
- Gherkin 記述を Lean の構文として受理する
- 各ステップを Lean の命題、定義、テスト、証明、またはユーザー定義の処理へ接続できるようにする
- 最初は最小 DSL として実装し、段階的に Lean の証明・実行機構と統合する

## 2. 想定する記法

初期段階では、以下のような Lean 内 DSL を想定する。

```lean4
feature "Calculator" do
  scenario "addition" do
    given "a calculator"
    when "I add 1 and 2"
    then "the result should be 3"
```

より Lean らしい構文として、将来的には以下も検討する。

```lean4
gherkin Feature: Calculator
  Scenario: addition Given a calculator
    When I add 1 and 2
    Then the result should be 3
```

ただし、後者は Lean の構文制約との相性を慎重に検討する必要があるため、初期実装では文字列ベース DSL を優先する。

## 3. 設計方針

### 3.1 段階的実装

実装は以下の段階に分ける。

1. 構文を受理するだけの DSL
2. Gherkin AST への変換
3. Lean コマンドとしての登録
4. ステップ定義との対応付け
5. 検証・実行・証明との統合

### 3.2 Lean の機能の使い分け

| 用途 | 使用する Lean 機能 |
|---|---|
| DSL 構文の追加 | `syntax`, `macro` |
| 構文から内部表現への変換 | `macro_rules` または elaborator |
| コマンドレベルの処理 | `elab command` |
| 環境への登録 | `EnvironmentExtension` |
| エラー報告 | `throwError`, `logInfo`, `logWarning` |
| ステップ定義の探索 | 名前空間、属性、環境拡張 |
| 証明との統合 | theorem / example / tactic elaboration |

## 4. コア概念

### 4.1 Feature

`Feature` は仕様全体を表す。

保持する情報:

- feature 名
- description
- scenarios
- tags
- source position

### 4.2 Scenario

`Scenario` は具体的な振る舞いの例を表す。

保持する情報:

- scenario 名
- steps
- tags
- source position

### 4.3 Step

`Step` は `Given` / `When` / `Then` / `And` / `But` を表す。

保持する情報:

- kind
- text
- source position
- 対応する step definition
- 実行・検証結果

```lean4
inductive StepKind where
  | given
  | when
  | then
  | and
  | but
```

### 4.4 Step Definition

Gherkin の自然言語ステップを Lean の関数・命題・検証ロジックに対応付ける。

例:

```lean4
step_def "I add {x:Int} and {y:Int}" => do -- Lean 側の処理
```

または、より単純な初期設計として:

```lean4
def addStep : StepHandler := StepHandler.ofString "I add 1 and 2" (...)
```

## 5. 構文設計

### 5.1 初期構文

初期実装では、Lean の構文として扱いやすい以下の形を採用する。

```lean4
feature "Feature name" do
  scenario "Scenario name" do
    given "precondition"
    when "action"
    then "expected result"
```

### 5.2 Lean syntax 定義案

```lean4
syntax "given " str : gherkinStep
syntax "when " str : gherkinStep
syntax "then " str : gherkinStep
syntax "and " str : gherkinStep
syntax "but " str : gherkinStep

syntax "scenario " str " do " gherkinStep* : gherkinScenario
syntax "feature " str " do " gherkinScenario* : command

```

### 5.3 コマンドとして処理する理由

`feature` は Lean ファイルのトップレベルに置く仕様記述であるため、`command` として定義する。

これにより以下が可能になる。

- Lean 環境への Feature 登録
- ビルド時の検証
- `#check_feature` のような補助コマンドの提供
- 将来的な test runner 連携

## 6. 内部表現

内部的には、Gherkin 記述を以下のような AST に変換する。

```lean4
namespace LeanGherkin
  inductive StepKind where
    | given
    | when
    | then
    | and
    | but
  deriving Repr, BEq, Inhabited
  
  structure Step where kind : StepKind text : String deriving Repr, Inhabited
  
  structure Scenario where name : String steps : Array Step deriving Repr, Inhabited
  
  structure Feature where name : String scenarios : Array Scenario deriving Repr, Inhabited
end LeanGherkin
```

初期段階では最小限の情報のみを持たせる。

将来的には以下を追加する。

- tags
- description
- source reference
- examples
- background
- rule
- doc string
- data table

## 7. Elaborator 設計

### 7.1 Feature 登録

`feature` コマンドを elaboration し、Lean の環境拡張に登録する。

処理の流れ:

1. 構文木から feature 名を取得
2. scenario 群を取得
3. 各 scenario から step 群を取得
4. `Feature` 構造体を構築
5. 環境拡張へ登録
6. 必要に応じてログ出力

### 7.2 エラー検出

初期段階で検出するエラー:

- `scenario` が 1 つもない `feature`
- `step` が 1 つもない `scenario`
- `then` が存在しない `scenario`
- `when` より前に `then` が現れるケース
- 不明な step kind

将来的に検出するエラー:

- 対応する step definition が存在しない
- step definition が複数一致する
- Examples の列名と step placeholder が一致しない
- Background の重複・不正配置

## 8. Step Definition 設計

### 8.1 初期方式

最初は step text の完全一致で対応付ける。

```lean4
step_def "a calculator" => ...
step_def "I add 1 and 2" => ...
step_def "the result should be 3" => ...
```

完全一致方式の利点:

- 実装が単純
- Lean の elaborator 実装に集中できる
- エラー表示が分かりやすい

### 8.2 次段階: プレースホルダ対応

次に、以下のようなパラメータ付きステップを扱う。

```lean4
step_def "I add {x:Int} and {y:Int}" => ...
```

必要な処理:

- パターン文字列のパース
- placeholder の型解決
- 実際の step text とのマッチング
- 文字列から Lean 値への変換
- handler への引数渡し

### 8.3 型安全性

Lean 上で実装する利点を活かし、step definition には型を持たせる。

例:

```lean4
def addStep (x y : Int) : GherkinM Unit := do ...
```

パターンと関数の引数型の整合性を elaboration 時に検証することを目指す。

## 9. 実行モデル

### 9.1 仕様登録モード

初期実装では、`feature` は仕様を登録するだけにする。

```lean4
feature "Calculator" do
  scenario "addition" do
    given "a calculator"
    when "I add 1 and 2"
    then "the result should be 3"
```

この段階では、Lean のコンパイル時に構文が検証される。

### 9.2 検証モード

次段階では、すべての step に対応する step definition が存在するかを検証する。

```lean4
#check_gherkin
```

または feature 単位で:

```lean4
lean #check_feature "Calculator"
```

### 9.3 実行モード

さらに進めて、step definition を順に実行する。

```lean4
#run_feature "Calculator"
#run_scenario "Calculator" "addition"
```

実行状態は以下のような monad で表す。

```lean4
abbrev GherkinM := StateT GherkinWorld IO
```

ただし、Lean のコンパイル時実行と通常の IO 実行の境界には注意する。

## 10. 証明との統合

Lean らしい価値を出すため、Gherkin の `Then` を命題や theorem に接続する設計を検討する。

例:

```lean4
then_proves "the result should be 3" by decide
```

または:

```lean4
step_theorem "the result should be 3" : actual = 3 := by rfl
```

検討事項:

- Gherkin scenario を theorem に変換できるか
- `Given` を仮定、`When` を変換、`Then` を結論として扱えるか
- scenario 全体を `Prop` として表現できるか
- tactic script と連携できるか

## 11. ディレクトリ構成案

```text
LeanGherkin/
  Basic.lean
  Syntax.lean
  Ast.lean
  Elab.lean
  StepDef.lean
  Registry.lean
  Runner.lean
  Diagnostics.lean
  Examples.lean
  LeanGherkin.lean
  design.md
```

### 各ファイルの責務

| ファイル | 責務 |
|---|---|
| `Basic.lean` | 共通 import |
| `Ast.lean` | Feature / Scenario / Step の内部表現 |
| `Syntax.lean` | DSL 構文定義 |
| `Elab.lean` | `feature` / `scenario` / `step` の elaboration |
| `Registry.lean` | 環境拡張による feature / step definition 管理 |
| `StepDef.lean` | step definition DSL |
| `Runner.lean` | feature / scenario 実行 |
| `Diagnostics.lean` | エラー・警告・pretty print |
| `Examples.lean` | 使用例・動作確認 |

## 12. 実装マイルストーン

### Milestone 1: AST と構文の最小実装

目的:

- `feature` / `scenario` / `given` / `when` / `then` を Lean 構文として受理する

成果物:

- `Ast.lean`
- `Syntax.lean`
- 簡単なサンプル

完了条件:

```lean4
feature "Calculator" do
  scenario "addition" do
  given "a calculator"
  when "I add 1 and 2"
  then "the result should be 3"
```

が Lean に受理される。

### Milestone 2: Elaborator と Feature 登録

目的:

- Gherkin 記述を `Feature` AST に変換し、環境へ登録する

成果物:

- `Elab.lean`
- `Registry.lean`
- `#print_features` コマンド

完了条件:

```lean4
#print_features
```

で登録済み feature が表示される。

### Milestone 3: 静的検証

目的:

- scenario の構造的な妥当性を検査する

検証例:

- scenario に step が存在する
- `then` が存在する
- step の順序が自然である

成果物:

- `Diagnostics.lean`
- エラー表示の改善

### Milestone 4: Step Definition

目的:

- step text と Lean 側 handler を対応付ける

成果物:

- `StepDef.lean`
- `step_def` 構文
- 完全一致ベースの step 解決

完了条件:

- 未定義 step を検出できる
- 重複 step definition を検出できる

### Milestone 5: Runner

目的:

- scenario を順に実行する

成果物:

- `Runner.lean`
- `#run_feature`
- `#run_scenario`

完了条件:

- step definition が順に呼ばれる
- 成功・失敗が表示される

### Milestone 6: パラメータ付き Step Definition

目的:

- `{x:Int}` のような placeholder をサポートする

成果物:

- pattern parser
- matcher
- typed argument conversion

完了条件:

```lean4
step_def "I add {x:Int} and {y:Int}" => ...
```

が利用できる。

### Milestone 7: Lean 証明との統合

目的:

- `Then` を Lean の命題・証明と接続する

成果物:

- `then_proves`
- `step_theorem`
- theorem 生成の検討

完了条件:

- Gherkin scenario から検証可能な Lean 命題を導ける

## 13. 優先して避けるべき複雑性

初期実装では以下を避ける。

- 自然言語そのものの高度な解析
- 本家 Gherkin の完全互換
- 複雑な indentation-sensitive parser
- 多言語キーワード対応
- Examples / Scenario Outline の完全実装
- 非同期実行
- 外部プロセスとの統合

まずは Lean 上で安定して扱える DSL を作ることを優先する。

## 14. 将来的な拡張

### 14.1 Gherkin 互換性の向上

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
  when "I add and "
  then "the result should be "
  examples
    | x | y | z |
    | 1 | 2 | 3 |
```

### 14.2 日本語 DSL

日本語 Gherkin 風の構文も検討する。

```lean4
機能 "計算機" do
  シナリオ "足し算" do
    前提 "計算機がある"
    もし "1 と 2 を足す"
    ならば "結果は 3 である"
```

ただし、Lean の識別子・構文ルールとの相性を確認する必要がある。

### 14.3 レポート出力

将来的に以下を出力できるようにする。

- text report
- JSON report
- JUnit XML
- Markdown report

## 15. リスクと検討事項

### 15.1 Lean 構文との衝突

`feature`, `scenario`, `given`, `when`, `then` などのキーワード風構文が既存構文や将来の Lean 構文と衝突する可能性がある。

対策:

- namespace を設ける
- `gherkin` ブロック内限定にする
- prefix を導入する

例:

```lean4
gherkin_feature "Calculator" do ...
```

### 15.2 Indentation と構文パース

Gherkin は本来 indentation に依存した読みやすい構文だが、Lean の parser と完全に同じ感覚では扱えない可能性がある。

対策:

- 初期実装では `do` ブロックと文字列を使う
- 本家 Gherkin 風構文は後回しにする

### 15.3 実行とコンパイルの境界

Lean の elaboration 時に IO 実行を行う設計は慎重に扱う必要がある。

対策:

- 仕様登録と実行を分離する
- `#run_feature` のような明示的コマンドで実行する
- 通常の import 時に副作用を起こさない

### 15.4 エラーメッセージ品質

DSL ではユーザーが自然言語的に記述するため、エラー箇所が分かりにくくなりやすい。

対策:

- source position を保持する
- 未定義 step の候補を表示する
- 重複定義の位置を表示する
- feature / scenario 名を含めて報告する

## 16. 最小実装のゴール

最初の実装で目指す状態は以下である。

```lean4
import LeanGherkin

feature "Calculator" do
  scenario "addition" do
    given "a calculator"
    when "I add 1 and 2"
    then "the result should be 3"

#print_features
```

期待する動作:

- `feature` 構文が Lean に受理される
- `Feature` AST が生成される
- Lean 環境に登録される
- `#print_features` で内容を確認できる
- 構造的に不正な scenario にはエラーを出せる

## 17. 推奨実装順序

1. `LeanGherkin/Ast.lean` を作成する
2. `LeanGherkin/Syntax.lean` を作成する
3. `feature` コマンドを最小 elaborator で受理する
4. `Feature` を環境拡張へ登録する
5. `#print_features` を実装する
6. scenario / step の静的検証を追加する
7. `step_def` を追加する
8. step 解決を追加する
9. `#run_scenario` を追加する
10. パラメータ付き step を検討する

## 18. まとめ

本プロジェクトでは、まず Lean4 の構文拡張機構を使って、文字列ベースの Gherkin 風 DSL を実装する。

初期段階では、本家 Gherkin の完全互換よりも以下を優先する。

- Lean 上で自然に書けること
- AST として安定して扱えること
- elaborator による検証が可能であること
- 将来的に step definition や theorem と接続できること

最小実装の成功後、step definition、runner、パラメータ展開、証明統合へと段階的に拡張する。
