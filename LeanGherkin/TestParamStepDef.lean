import LeanGherkin.StepDef
import LeanGherkin.Elab

namespace LeanGherkin.TestParam

-- 型の解決を確認するための定義
instance : FromGherkinArg Int where
  fromGherkinArg s := s.toInt?

step_def "I add {x:Int} and {y:Int}" => fun (x y : Int) => do
  IO.println s!"[HANDLER] Adding {x} and {y}, sum is {x + y}"

step_def "the result should be {z:Int}" => fun (z : Int) => do
  IO.println s!"[HANDLER] Checking if result is {z}"

step_def "I say {msg:String}" => fun (msg : String) => do
  IO.println s!"[HANDLER] Saying: {msg}"

feature "Addition with parameters" do
  scenario "Add two numbers" do
    given "I add 10 and 20"
    then "the result should be 30"
    and "I say Hello"

#run_feature "Addition with parameters"

end LeanGherkin.TestParam
