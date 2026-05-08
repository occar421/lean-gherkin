import LeanGherkin.Ast

namespace LeanGherkin

declare_syntax_cat gherkinStep
declare_syntax_cat gherkinScenario

syntax "given " str : gherkinStep
syntax "when " str : gherkinStep
syntax "then " str : gherkinStep
syntax "and " str : gherkinStep
syntax "but " str : gherkinStep

syntax "scenario " str " do" ppLine gherkinStep* : gherkinScenario
syntax "feature " str " do" ppLine gherkinScenario* : command

end LeanGherkin