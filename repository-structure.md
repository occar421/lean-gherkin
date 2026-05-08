# リポジトリ構成案

この文書では、Lean Gherkin のリポジトリ構成案と各ファイルの責務を整理する。

## ディレクトリ構成案

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

## 各ファイルの責務

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