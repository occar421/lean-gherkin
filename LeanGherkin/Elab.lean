import Lean
import LeanGherkin.Registry
import LeanGherkin.Syntax
import LeanGherkin.Diagnostics
import LeanGherkin.StepDef
import LeanGherkin.Runner

namespace LeanGherkin

open Lean Elab Command

register_option LeanGherkin.undefinedStepSeverity : String := {
  defValue := "warning"
  descr    := "severity level for undefined steps: 'info', 'warning', 'error', or 'none'"
}

register_option LeanGherkin.validationSeverity : String := {
  defValue := "warning"
  descr    := "severity level for scenario validation (empty steps, missing then, etc.): 'info', 'warning', 'error', or 'none'"
}

private def syntaxString (stx : Syntax) : CommandElabM String :=
  match stx.isStrLit? with
  | some value => pure value
  | none => throwErrorAt stx "expected string literal"

private def elabStep : Syntax → CommandElabM Step
  | `(gherkinStep| Given $text:str) => do
      let text ← syntaxString text
      pure { kind := .given, text }
  | `(gherkinStep| When $text:str) => do
      let text ← syntaxString text
      pure { kind := .when, text }
  | `(gherkinStep| Then $text:str) => do
      let text ← syntaxString text
      pure { kind := .then, text }
  | `(gherkinStep| And $text:str) => do
      let text ← syntaxString text
      pure { kind := .and, text }
  | `(gherkinStep| But $text:str) => do
      let text ← syntaxString text
      pure { kind := .but, text }
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

private def logWithSeverity (stx : Syntax) (msg : String) (severity : String) : CommandElabM Unit := do
  match severity with
  | "error"   => throwErrorAt stx msg
  | "warning" => logWarningAt stx msg
  | "info"    => logInfoAt stx msg
  | "none"    => pure ()
  | _         => logWarningAt stx s!"unknown severity '{severity}', defaulting to warning\n{msg}"

private def elabScenario (scenariosName : Syntax) : Syntax → CommandElabM Scenario
  | `(gherkinScenario| Scenario: $name:str $steps:gherkinStep*) => do
      let steps ← steps.mapM elabStep
      let gherkinScenario : Scenario := { name := ← syntaxString name, steps }
      
      let opts ← getOptions
      
      -- Milestone 3 validation
      let validationSeverity := LeanGherkin.validationSeverity.get opts
      let errors := validateScenario gherkinScenario
      for err in errors do
        logWithSeverity name err validationSeverity
      
      -- Milestone 4 & 6: Step Resolution
      let env ← getEnv
      let undefinedStepSeverity := LeanGherkin.undefinedStepSeverity.get opts
      for step in steps do
        if (findStepDefinition env step.text).isNone then
          let msg := s!"undefined step: {step.text}"
          logWithSeverity scenariosName msg undefinedStepSeverity
          
      pure gherkinScenario
  | `(gherkinScenario| scenario $name:str do $steps:gherkinStep*) => do
      let steps ← steps.mapM elabStep
      let gherkinScenario : Scenario := { name := ← syntaxString name, steps }
      
      let opts ← getOptions
      
      -- Milestone 3 validation
      let validationSeverity := LeanGherkin.validationSeverity.get opts
      let errors := validateScenario gherkinScenario
      for err in errors do
        logWithSeverity name err validationSeverity
      
      -- Milestone 4 & 6: Step Resolution
      let env ← getEnv
      let undefinedStepSeverity := LeanGherkin.undefinedStepSeverity.get opts
      for step in steps do
        if (findStepDefinition env step.text).isNone then
          let msg := s!"undefined step: {step.text}"
          logWithSeverity scenariosName msg undefinedStepSeverity
          
      pure gherkinScenario
  | stx => throwErrorAt stx "unsupported gherkin scenario"

@[command_elab featureSyntax]
def elabFeature : CommandElab := fun stx => do
  match stx with
  | `(Feature: $name:str $scenarios:gherkinScenario*) => do
      let scenarios ← scenarios.mapM (elabScenario stx)
      let name ← syntaxString name
      let gherkinFeature : Feature := { name, scenarios }
      modifyEnv fun env => addFeature env gherkinFeature
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
  | `(step_def $textStx:str $[$binders]* => $handlerStx:term) => do
      let text ← syntaxString textStx
      let pattern := parseStepPattern text
      let env ← getEnv
      
      -- Check for duplicate step definitions (using exact pattern string for now)
      let existingDefs := getStepDefinitions env
      if existingDefs.any (fun d => d.pattern.parts.length == pattern.parts.length) then
         -- We could do a more sophisticated check for overlapping patterns
         pure ()

      let baseName := s!"stepHandler_{Hashable.hash text}"
      let handlerName := (← getCurrNamespace) ++ Name.mkSimple baseName
      
      -- We need to construct a wrapper of type `List String -> IO Unit`
      -- that calls the user-provided handler with converted arguments.
      let params := pattern.parts.filterMap fun 
        | StepPart.parameter n t => some (n, t)
        | _ => none
      
      let handlerType := mkConst ``StepHandler
      
      let elabHandler ← liftTermElabM <| do
        -- Wrap handlerStx with binders if present
        let fullHandlerStx ← `(fun $[$binders]* => $handlerStx)
        
        let mut argMatches := #[]
        let mut argVars := #[]
        let mut fromGherkinArgCalls := #[]
        
        for (i, (_name, typeName)) in params.toArray.mapIdx (fun i p => (i, p)) do
          let argVar := mkIdent (Name.mkSimple s!"s{i}")
          argMatches := argMatches.push argVar
          let valVar := mkIdent (Name.mkSimple s!"v{i}")
          argVars := argVars.push valVar
          let typeExpr ← Term.elabTerm (mkIdent typeName) none
          let fromGherkinArgCall ← `(FromGherkinArg.fromGherkinArg (α := $(← Term.exprToSyntax typeExpr)) $argVar)
          fromGherkinArgCalls := fromGherkinArgCalls.push fromGherkinArgCall

        let argsListStx ← `([ $[$argMatches],* ])
        let fromGherkinArgCallsStx := fromGherkinArgCalls

        -- Use a recursive helper to build the nested match to avoid `matchDiscr` issues
        let rec buildMatch (i : Nat) (vars : List Ident) : TermElabM Term := do
          if i < fromGherkinArgCallsStx.size then
            let call := fromGherkinArgCallsStx[i]!
            let var := argVars[i]!
            let rest ← buildMatch (i + 1) (var :: vars)
            `(match $call:term with | some $var => $rest | none => IO.println "Type mismatch")
          else
            let vars := vars.reverse.toArray
            `($fullHandlerStx $vars*)

        let innerMatch ← buildMatch 0 []

        let wrapperStx ← `(fun (args : List String) => do
          match args with
          | $argsListStx => $innerMatch:term
          | _ => IO.println "Argument count mismatch"
        )

        let e ← Term.elabTerm wrapperStx (some handlerType)
        Term.synthesizeSyntheticMVarsNoPostponing
        instantiateMVars e
      
      if elabHandler.hasMVar then
        throwErrorAt handlerStx "handler contains metavariables"
      
      if env.contains handlerName then
        modifyEnv fun env => addStepDefinition env { pattern, handlerName }
      else
        let decl := Declaration.defnDecl {
          name := handlerName
          levelParams := []
          type := handlerType
          value := elabHandler
          hints := ReducibilityHints.regular (maxRecDepth.get (← getOptions)).toUInt32
          safety := DefinitionSafety.safe
        }
        
        liftCoreM <| Lean.addAndCompile decl
        modifyEnv fun env => addStepDefinition env { pattern, handlerName }
  | _ => throwUnsupportedSyntax

@[command_elab runFeatureSyntax]
def elabRunFeature : CommandElab := fun stx => do
  let name ← syntaxString stx[1]
  let env ← getEnv
  let features := getFeatures env
  let mut feature? : Option Feature := none
  for f in features do
    if f.name == name then
      feature? := some f
      break
  match feature? with
  | none => throwErrorAt stx[1] s!"feature not found: {name}"
  | some (f : Feature) =>
    let res ← liftTermElabM <| runFeature f
    -- Milestone 5: Output each step execution to console
    for sr in res.scenarioResults do
      for str in sr.stepResults do
        if str.success then
          logInfo s!"{str.step.text}: {str.message}"
        else
          logError s!"{str.step.text}: {str.message}"
    logInfo (formatFeatureResult res)

@[command_elab runScenarioSyntax]
def elabRunScenario : CommandElab := fun stx => do
  let name ← syntaxString stx[1]
  let env ← getEnv
  let features := getFeatures env
  let mut scenario? : Option Scenario := none
  for f in features do
    for s in f.scenarios do
      if s.name == name then
        scenario? := some s
        break
    if scenario?.isSome then break
  match scenario? with
  | none => throwErrorAt stx[1] s!"scenario not found: {name}"
  | some (s : Scenario) =>
    let res ← liftTermElabM <| runScenario s
    -- Milestone 5: Output each step execution to console
    for str in res.stepResults do
      if str.success then
        logInfo s!"{str.step.text}: {str.message}"
      else
        logError s!"{str.step.text}: {str.message}"
    logInfo (formatScenarioResult res)

end LeanGherkin