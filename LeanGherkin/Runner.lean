import Lean
import LeanGherkin.Ast
import LeanGherkin.StepDef
import LeanGherkin.Registry

namespace LeanGherkin

open Lean Meta

structure StepResult where
  step : Step
  success : Bool
  message : String

instance : Inhabited StepResult where
  default := { step := { kind := .given, text := "" }, success := false, message := "" }

structure ScenarioResult where
  name : String
  stepResults : Array StepResult

structure FeatureResult where
  name : String
  scenarioResults : Array ScenarioResult

def runStep (step : Step) : MetaM StepResult := do
  let env ← getEnv
  match findStepDefinition env step.text with
  | none => 
    return { step, success := false, message := s!"Undefined step: {step.text}" }
  | some (defn, args) =>
    match defn.defType with
    | .effect =>
      try
        let act ← unsafe evalConst StepHandler defn.handlerName
        let _ ← act args
        return { step, success := true, message := "Passed" }
      catch e =>
        return { step, success := false, message := s!"Eval Error: {← e.toMessageData.toString}" }
    | .theorem =>
      -- For theorem, we don't "run" it in the same way, 
      -- but we check if it exists and possibly verify it against args if it has parameters.
      -- In this simple implementation, if the theorem is compiled, it's considered "passed".
      -- Future: actually check the property if possible or use it in a larger proof.
      return { step, success := true, message := "Proved" }

def runScenario (scenario : Scenario) : MetaM ScenarioResult := do
  let mut stepResults := #[]
  for step in scenario.steps do
    let res ← runStep step
    stepResults := stepResults.push res
    if !res.success then
      break
  return { name := scenario.name, stepResults }

def runFeature (feature : Feature) : MetaM FeatureResult := do
  let mut scenarioResults := #[]
  for scenario in feature.scenarios do
    scenarioResults := scenarioResults.push (← runScenario scenario)
  return { name := feature.name, scenarioResults }

def formatStepResult (res : StepResult) : String :=
  let status := if res.success then "✅" else "❌"
  s!"  {status} {res.step.text}: {res.message}"

def formatScenarioResult (res : ScenarioResult) : String :=
  let header := s!"Scenario: {res.name}"
  let steps := res.stepResults.map formatStepResult
  String.intercalate "\n" (header :: steps.toList)

def formatFeatureResult (res : FeatureResult) : String :=
  let header := s!"Feature: {res.name}"
  let scenarios := res.scenarioResults.map formatScenarioResult
  String.intercalate "\n" (header :: scenarios.toList)

end LeanGherkin
