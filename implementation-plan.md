# Lean Gherkin 実装計画

この文書は `design.md` から実装順序・マイルストーン・最小実装の完了条件を分離したものである。

## 1. 最小実装のゴール

最初の実装では、`spec.md` に定義した初期記法を Lean に受理させ、登録済み feature を `#print_features` で確認できる状態を目指す。

期待する動作:

- `feature` 構文が Lean に受理される
- `Feature` AST が生成される
- Lean 環境に登録される
- `#print_features` で内容を確認できる
- 構造的に不正な scenario にはエラーを出せる

## 2. 実装マイルストーン

### Milestone 1: AST と構文の最小実装

目的:

- `spec.md` に定義した初期記法を Lean 構文として受理する

成果物:

- `Ast.lean`
- `Syntax.lean`
- 簡単なサンプル

完了条件:

- `spec.md` の初期記法例が Lean に受理される。

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

## 3. 推奨実装順序

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
