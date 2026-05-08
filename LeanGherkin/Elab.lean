import Lean
import LeanGherkin.Registry
import LeanGherkin.Syntax
import LeanGherkin.Diagnostics
import LeanGherkin.StepDef

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

private def elabScenario (scenariosName : Syntax) : Syntax → CommandElabM Scenario
  | `(gherkinScenario| scenario $name:str do $steps:gherkinStep*) => do
      let steps ← steps.mapM elabStep
      let gherkinScenario : Scenario := { name := ← syntaxString name, steps }
      
      -- Milestone 3 validation
      let errors := validateScenario gherkinScenario
      for err in errors do
        logWarningAt name err
      
      -- Milestone 4: Step Resolution
      let env ← getEnv
      for step in steps do
        if (findStepDefinition env step.text).isNone then
          logWarningAt scenariosName s!"undefined step: {step.text}"
          
      pure gherkinScenario
  | stx => throwErrorAt stx "unsupported gherkin scenario"

@[command_elab featureSyntax]
def elabFeature : CommandElab := fun stx => do
  match stx with
  | `(feature $name:str do $scenarios:gherkinScenario*) => do
      let scenarios ← scenarios.mapM (elabScenario stx)
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

@[command_elab stepDefSyntax]
def elabStepDef : CommandElab := fun stx => do
  match stx with
  | `(step_def $textStx:str => $handlerStx:term) => do
      let text ← syntaxString textStx
      let env ← getEnv
      
      -- Check for duplicate step definitions
      if (findStepDefinition env text).isSome then
        logWarningAt textStx s!"duplicate step definition: {text}"
      
      -- Define a unique name for the handler
      let baseName := s!"stepHandler_{Hashable.hash text}"
      let handlerName := (← getCurrNamespace) ++ Name.mkSimple baseName
      
      -- Declare the handler in the environment
      let handlerType := mkConst ``StepHandler
      let elabHandler ← liftTermElabM <| do
        let e ← Term.elabTerm handlerStx (some handlerType)
        Term.synthesizeSyntheticMVarsNoPostponing
        instantiateMVars e
      
      -- Check if there are still metavariables
      if elabHandler.hasMVar then
        throwErrorAt handlerStx "handler contains metavariables"
      
      if env.contains handlerName then
        -- This can happen if the same text is used for multiple step_defs in the same file
        -- We already warned about duplicate step definitions, but we must ensure unique declaration names.
        -- We don't really need to declare it again if it's identical, but for now we just skip the declaration if it exists.
        modifyEnv fun env => addStepDefinition env { text, handlerName }
      else
        let decl := Declaration.defnDecl {
          name := handlerName
          levelParams := []
          type := handlerType
          value := elabHandler
          hints := ReducibilityHints.regular (maxRecDepth.get (← getOptions)).toUInt32
          safety := DefinitionSafety.safe
        }
        
        liftCoreM <| addDecl decl
        modifyEnv fun env => addStepDefinition env { text, handlerName }
  | _ => throwUnsupportedSyntax

syntax (name := printFeatures) "#print_features" : command

@[command_elab printFeatures]
def elabPrintFeatures : CommandElab := fun _ => do
  let features := getFeatures (← getEnv)
  if features.isEmpty then
    logInfo "no registered features"
  else
    logInfo <| String.intercalate "\n\n" (features.map formatFeature).toList

end LeanGherkin