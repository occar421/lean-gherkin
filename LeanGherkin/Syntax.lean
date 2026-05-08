import LeanGherkin.Ast

namespace LeanGherkin

declare_syntax_cat gherkinStep
declare_syntax_cat gherkinScenario

syntax "given " str : gherkinStep
syntax "when " str : gherkinStep
syntax "then " str : gherkinStep
syntax "and " str : gherkinStep
syntax "but " str : gherkinStep

syntax (name := scenarioSyntax) "scenario " str " do" ppLine gherkinStep* : gherkinScenario
syntax (name := featureSyntax) "feature " str " do" ppLine gherkinScenario* : command

syntax (name := stepDefSyntax) "step_def " str " => " term : command
syntax (name := runFeatureSyntax) "#run_feature " str : command
syntax (name := runScenarioSyntax) "#run_scenario " str : command

end LeanGherkin