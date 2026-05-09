import Lean
import LeanGherkin.Ast

namespace LeanGherkin

open Lean Parser Term PrettyPrinter

def rawTextUntilLineEnd : Parser :=
{ fn := fun context state =>
    let startPos := state.pos
    let newState := takeUntilFn (fun char => char == '\n') context state
    let str := startPos.extract context.inputString newState.pos
    if str.isEmpty then newState.mkError "end of description" -- taking care of eof
    else
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

def isGherkinDirectiveStart : Parser := symbol "Feature:" <|> "Scenario:" -- TODO 行頭のみにする

def DEBUG_SEP := String.ofList (List.replicate 40 '-')

def gherkinAdditionalLines : Parser :=
{ fn := fun context state =>
    let lookAheadState := isGherkinDirectiveStart.fn context state
    
    if lookAheadState.hasError then -- non-directive line
        rawTextUntilLineEnd.fn context state -- TODO multiple lines
    else
      state.mkError "end of description" -- エラーを出すことで * ループを抜ける
}

@[combinator_formatter gherkinAdditionalLines]
def gherkinAdditionalLine.formatter : Formatter := Formatter.visitAtom Name.anonymous
@[combinator_parenthesizer gherkinAdditionalLines]
def gherkinAdditionalLine.parenthesizer : Parenthesizer := Parenthesizer.visitToken

syntax (name := scenarioSyntax) scenarioSyntaxOpening gherkinText (colGt gherkinStep)*: gherkinScenario
syntax (name := featureSyntax) withPosition(
  featureSyntaxOpening gherkinText
  ((colGt gherkinAdditionalLines)? (colGt gherkinScenario))*
  ): command -- TODO: free-form text description

syntax (name := stepDefSyntax) "step_def " str (ppSpace funBinder)* " => " term : command
syntax (name := runFeatureSyntax) "#run_feature " gherkinText : command
syntax (name := runScenarioSyntax) "#run_scenario " gherkinText : command

end LeanGherkin