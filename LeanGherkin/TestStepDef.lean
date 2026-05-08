import LeanGherkin.StepDef
import LeanGherkin.Elab
import LeanGherkin.Runner

namespace LeanGherkin.TestNewStepDef

step_def "I add {x:Int} and {y:Int}" (x y : Int) => do
  IO.println s!"[HANDLER] Adding {x} and {y}, sum is {x + y}"

step_def "the result should be {z:Int}" (z : Int) => do
  IO.println s!"[HANDLER] Checking if result is {z}"

feature "New step_def syntax" do
  scenario "Add two numbers" do
    given "I add 10 and 20"
    then "the result should be 30"

step_def "no parameters" => do
  IO.println "[HANDLER] No parameters"

feature "Mixed syntax" do
  scenario "Test mixed" do
    given "I add 5 and 5"
    then "the result should be 10"
    and "no parameters"

step_def "sum of {x:Int} and {y:Int} is {z:Int}" (x y z : Int) => do
  if x + y == z then
    IO.println s!"[HANDLER] Correct: {x} + {y} = {z}"
  else
    IO.println s!"[HANDLER] Incorrect: {x} + {y} != {z}"

feature "Multiple binders" do
  scenario "Check sum" do
    given "sum of 1 and 2 is 3"

#run_feature "Multiple binders"

end LeanGherkin.TestNewStepDef
