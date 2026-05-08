# Lean Gherkin 設計プラン

※ 初期記法の採用理由や対象範囲は `spec.md` に委ね、この文書では AST、elaborator、登録、step definition、runner、証明統合の設計上の接続点を扱う。

## 1. 目的

本プロジェクトでは、Lean4 の `macro` および `elab` 機構を用いて、Lean 上で Gherkin 記法に近い仕様記述 DSL を実現する。

目標は以下の通りである。

- Lean ファイル内に Gherkin 風の `Feature` / `Scenario` / `Given` / `When` / `Then` を記述できるようにする
- Gherkin 記述を Lean の構文として受理する
- 各ステップを Lean の命題、定義、テスト、証明、またはユーザー定義の処理へ接続できるようにする
- 最初は最小 DSL として実装し、段階的に Lean の証明・実行機構と統合する

## 2. 設計方針

### 2.1 段階的実装

実装は以下の段階に分ける。

1. 構文を受理するだけの DSL
2. Gherkin AST への変換
3. Lean コマンドとしての登録
4. ステップ定義との対応付け
5. 検証・実行・証明との統合

### 2.2 Lean の機能の使い分け

| 用途 | 使用する Lean 機能 |
|---|---|
| DSL 構文の追加 | `syntax`, `macro` |
| 構文から内部表現への変換 | `macro_rules` または elaborator |
| コマンドレベルの処理 | `elab command` |
| 環境への登録 | `EnvironmentExtension` |
| エラー報告 | `throwError`, `logInfo`, `logWarning` |
| ステップ定義の探索 | 名前空間、属性、環境拡張 |
| 証明との統合 | theorem / example / tactic elaboration |

## 3. コア概念

### 3.1 Feature

`Feature` は仕様全体を表す。

保持する情報:

- feature 名
- description
- scenarios
- tags
- source position

### 3.2 Scenario

`Scenario` は具体的な振る舞いの例を表す。

保持する情報:

- scenario 名
- steps
- tags
- source position

### 3.3 Step

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

### 3.4 Step Definition

Gherkin の自然言語ステップを Lean の関数・命題・検証ロジックに対応付ける。

例:

```lean4
step_def "I add {x:Int} and {y:Int}" => do -- Lean 側の処理
```

または、より単純な初期設計として:

```lean4
def addStep : StepHandler := StepHandler.ofString "I add 1 and 2" (...)
```

## 4. 構文設計

### 4.1 初期構文

初期実装では、Lean の構文として扱いやすい文字列ベース DSL を採用する。記法仕様、採用方針、初期対象範囲は [`spec.md`](spec.md) に分離し、この文書では構文を Lean 側でどう扱うかに絞る。

### 4.2 Lean syntax 定義案

```lean4
syntax "given " str : gherkinStep
syntax "when " str : gherkinStep
syntax "then " str : gherkinStep
syntax "and " str : gherkinStep
syntax "but " str : gherkinStep

syntax "scenario " str " do " gherkinStep* : gherkinScenario
syntax "feature " str " do " gherkinScenario* : command

```

### 4.3 コマンドとして処理する理由

`feature` は Lean ファイルのトップレベルに置く仕様記述であるため、`command` として定義する。

これにより以下が可能になる。

- Lean 環境への Feature 登録
- ビルド時の検証
- `#check_feature` のような補助コマンドの提供
- 将来的な test runner 連携

## 5. 内部表現

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

## 6. Elaborator 設計

### 6.1 Feature 登録

`feature` コマンドを elaboration し、Lean の環境拡張に登録する。

処理の流れ:

1. 構文木から feature 名を取得
2. scenario 群を取得
3. 各 scenario から step 群を取得
4. `Feature` 構造体を構築
5. 環境拡張へ登録
6. 必要に応じてログ出力

### 6.2 エラー検出

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

## 7. Step Definition 設計

### 7.1 初期方式

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

### 7.2 次段階: プレースホルダ対応

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

### 7.3 型安全性

Lean 上で実装する利点を活かし、step definition には型を持たせる。

例:

```lean4
def addStep (x y : Int) : GherkinM Unit := do ...
```

パターンと関数の引数型の整合性を elaboration 時に検証することを目指す。

## 8. 実行モデル

### 8.1 仕様登録モード

初期実装では、`feature` は仕様を登録するだけにする。

この段階では、Lean のコンパイル時に構文が検証される。

### 8.2 検証モード

次段階では、すべての step に対応する step definition が存在するかを検証する。

```lean4
#check_gherkin
```

または feature 単位で:

```lean4
lean #check_feature "Calculator"
```

### 8.3 実行モード

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

## 9. 証明との統合

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

## 10. まとめ

本プロジェクトでは、まず Lean4 の構文拡張機構を使って、文字列ベースの Gherkin 風 DSL を実装する。
