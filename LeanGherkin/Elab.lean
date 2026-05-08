import Lean
import LeanGherkin.Registry
import LeanGherkin.Syntax
import LeanGherkin.Diagnostics

namespace LeanGherkin

open Lean Elab Command

private def syntaxString (stx : Syntax) : CommandElabM String :=
  match stx.isStrLit? with
  | some value => pure value
  | none => throwErrorAt stx "expected string literal"

private def elabStep : Syntax → CommandElabM Step
  | `(gherkinStep| given $text:str) => do
      let text ← syntaxString text
      pure { kind := .given, text }
  | `(gherkinStep| when $text:str) => do
      let text ← syntaxString text
      pure { kind := .when, text }
  | `(gherkinStep| then $text:str) => do
      let text ← syntaxString text
      pure { kind := .then, text }
  | `(gherkinStep| and $text:str) => do
      let text ← syntaxString text
      pure { kind := .and, text }
  | `(gherkinStep| but $text:str) => do
      let text ← syntaxString text
      pure { kind := .but, text }
  | stx => throwErrorAt stx "unsupported gherkin step"

private def elabScenario : Syntax → CommandElabM Scenario
  | `(gherkinScenario| scenario $name:str do $steps:gherkinStep*) => do
      let steps ← steps.mapM elabStep
      let gherkinScenario : Scenario := { name := ← syntaxString name, steps }
      let errors := validateScenario gherkinScenario
      for err in errors do
        logWarningAt name err
      pure gherkinScenario
  | stx => throwErrorAt stx "unsupported gherkin scenario"

@[command_elab featureSyntax]
def elabFeature : CommandElab := fun stx => do
  match stx with
  | `(feature $name:str do $scenarios:gherkinScenario*) => do
      let scenarios ← scenarios.mapM elabScenario
      let name ← syntaxString name
      let gherkinFeature : Feature := { name, scenarios }
      modifyEnv fun env => addFeature env gherkinFeature
  | _ => throwUnsupportedSyntax

private def formatStepKind : StepKind → String
  | .given => "given"
  | .when => "when"
  | .then => "then"
  | .and => "and"
  | .but => "but"

private def formatStep (step : Step) : String :=
  s!"    {formatStepKind step.kind} {repr step.text}"

private def formatScenario (gherkinScenario : Scenario) : String :=
  let header := s!"  scenario {repr gherkinScenario.name} do"
  let steps := gherkinScenario.steps.map formatStep
  String.intercalate "\n" (header :: steps.toList)

private def formatFeature (gherkinFeature : Feature) : String :=
  let header := s!"feature {repr gherkinFeature.name} do"
  let scenarios := gherkinFeature.scenarios.map formatScenario
  String.intercalate "\n" (header :: scenarios.toList)

syntax (name := printFeatures) "#print_features" : command

@[command_elab printFeatures]
def elabPrintFeatures : CommandElab := fun _ => do
  let features := getFeatures (← getEnv)
  if features.isEmpty then
    logInfo "no registered features"
  else
    logInfo <| String.intercalate "\n\n" (features.map formatFeature).toList

end LeanGherkin