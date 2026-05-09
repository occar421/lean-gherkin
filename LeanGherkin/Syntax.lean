import Lean
import LeanGherkin.Ast

namespace LeanGherkin

open Lean Parser Term PrettyPrinter

def rawTextUntilLineEnd : Parser :=
{ fn := fun context state =>
    let startPos := state.pos
    let newState := takeUntilFn (fun char => char == '\n') context state
    let str := startPos.extract context.inputString newState.pos
    
    let stateAfterNL := newState.next context newState.pos
    let finalState := whitespace context stateAfterNL
    
    finalState.pushSyntax (Syntax.atom SourceInfo.none str)
}

@[combinator_formatter rawTextUntilLineEnd]
def rawTextUntilLineEnd.formatter : Formatter := Formatter.visitAtom Name.anonymous
@[combinator_parenthesizer rawTextUntilLineEnd]
def rawTextUntilLineEnd.parenthesizer : Parenthesizer := Parenthesizer.visitToken

declare_syntax_cat gherkinStep
declare_syntax_cat gherkinScenario

abbrev gherkinText := rawTextUntilLineEnd

syntax "Given " gherkinText : gherkinStep
syntax "When " gherkinText : gherkinStep
syntax "Then " gherkinText : gherkinStep
syntax "And " gherkinText : gherkinStep
syntax "But " gherkinText : gherkinStep

syntax scenarioSyntaxOpening := "Scenario:"
syntax featureSyntaxOpening := "Feature:"

syntax (name := scenarioSyntax) scenarioSyntaxOpening gherkinText (colGt gherkinStep*): gherkinScenario
syntax (name := featureSyntax) featureSyntaxOpening gherkinText (colGt "#" gherkinText)* (colGt gherkinScenario)*: command

syntax (name := stepDefSyntax) "step_def " str (ppSpace funBinder)* " => " term : command
syntax (name := runFeatureSyntax) "#run_feature " gherkinText : command
syntax (name := runScenarioSyntax) "#run_scenario " gherkinText : command

end LeanGherkin