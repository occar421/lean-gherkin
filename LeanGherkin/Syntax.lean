import Lean
import LeanGherkin.Ast

namespace LeanGherkin

open Lean Parser Term PrettyPrinter

def rawTextUntilLineEnd : Parser :=
{ fn := fun c s =>
    let startPos := s.pos
    dbg_trace startPos
    let s := takeUntilFn (fun c => c == '\n') c s
    let str := startPos.extract c.inputString s.pos
    dbg_trace str
    s.pushSyntax (Syntax.atom SourceInfo.none str)
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

-- TODO FIXME: Feature の次に Scenario が来るとおかしくなる
-- syntax (name := scenarioSyntax) scenarioSyntaxOpening gherkinText ppLine gherkinStep* : gherkinScenario
syntax (name := scenarioSyntax) scenarioSyntaxOpening: gherkinScenario
syntax (name := featureSyntax) featureSyntaxOpening gherkinText ppLine gherkinScenario+ : command
-- syntax (name := featureSyntax) featureSyntaxOpening gherkinText: command -- TODO FIXME: これでもエラーになる
-- error: Test/Diagnostics.lean:13:2: unexpected token 'Scenario:'; expected command なので、 scenario の定義方法か何かがおがしい
-- gherkinScenario 単体や gherkinScenario+ だと先にエラーが出て、gherkinScenario* だと後にエラーが出る。
-- TODO: いっきに parse するのでなく、context や monad に押しやってしまうのが良いかもしれない

syntax (name := stepDefSyntax) "step_def " str (ppSpace funBinder)* " => " term : command
syntax (name := runFeatureSyntax) "#run_feature " gherkinText : command
syntax (name := runScenarioSyntax) "#run_scenario " gherkinText : command

end LeanGherkin