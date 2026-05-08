import Lean
import LeanGherkin.Ast

namespace LeanGherkin

open Lean

def validateScenario (scenario : Scenario) : Array String := Id.run do
  let mut errors := #[]
  
  -- 1. シナリオにステップが存在すること
  if scenario.steps.isEmpty then
    errors := errors.push s!"scenario '{scenario.name}' has no steps"
  
  -- 2. then が存在すること
  let hasThen := scenario.steps.any (fun s => s.kind == .then)
  if !scenario.steps.isEmpty && !hasThen then
    errors := errors.push s!"scenario '{scenario.name}' must have at least one 'then' step"
  
  -- 3. ステップの順序の検証 (簡易的)
  -- 一般的な Gherkin の順序: Given -> When -> Then
  -- But/And はどこでも使える
  let mut seenWhen := false
  let mut seenThen := false
  
  for step in scenario.steps do
    match step.kind with
    | .given =>
      if seenWhen || seenThen then
        errors := errors.push s!"'given' step found after 'when' or 'then' in scenario '{scenario.name}'"
    | .when =>
      seenWhen := true
      if seenThen then
        errors := errors.push s!"'when' step found after 'then' in scenario '{scenario.name}'"
    | .then =>
      seenThen := true
    | .and | .but =>
      continue

  errors

end LeanGherkin
