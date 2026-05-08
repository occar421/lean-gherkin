import Lean
import LeanGherkin.Ast

namespace LeanGherkin

open Lean Parser Term

declare_syntax_cat gherkinStep
declare_syntax_cat gherkinScenario

syntax "Given " str : gherkinStep
syntax "When " str : gherkinStep
syntax "Then " str : gherkinStep
syntax "And " str : gherkinStep
syntax "But " str : gherkinStep
syntax "given " str : gherkinStep
syntax "when " str : gherkinStep
syntax "then " str : gherkinStep
syntax "and " str : gherkinStep
syntax "but " str : gherkinStep

syntax (name := scenarioSyntax) "Scenario: " str ppLine gherkinStep* : gherkinScenario
syntax "scenario " str " do" ppLine gherkinStep* : gherkinScenario
syntax (name := featureSyntax) "Feature: " str ppLine gherkinScenario* : command
syntax "feature " str " do" ppLine gherkinScenario* : command

syntax (name := stepDefSyntax) "step_def " str (ppSpace funBinder)* " => " term : command
syntax (name := runFeatureSyntax) "#run_feature " str : command
syntax (name := runScenarioSyntax) "#run_scenario " str : command

end LeanGherkin