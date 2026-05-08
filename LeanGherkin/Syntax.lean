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

syntax scenarioSyntaxOpening := "Scenario:"
syntax featureSyntaxOpening := "Feature:"

syntax (name := scenarioSyntax) scenarioSyntaxOpening str ppLine gherkinStep* : gherkinScenario
syntax (name := featureSyntax) featureSyntaxOpening str ppLine gherkinScenario* : command

syntax (name := stepDefSyntax) "step_def " str (ppSpace funBinder)* " => " term : command
syntax (name := runFeatureSyntax) "#run_feature " str : command
syntax (name := runScenarioSyntax) "#run_scenario " str : command

end LeanGherkin