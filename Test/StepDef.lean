import LeanGherkin

namespace Test.StepDef

step_def "I add {x:Int} and {y:Int}" (x y : Int) => do
  IO.println s!"[HANDLER] Adding {x} and {y}, sum is {x + y}"

step_def "the result should be {z:Int}" (z : Int) => do
  IO.println s!"[HANDLER] Checking if result is {z}"

Feature: "New step_def syntax"
  Scenario: "Add two numbers"
    Given "I add 10 and 20"
    Then "the result should be 30"

step_def "no parameters" => do
  IO.println "[HANDLER] No parameters"

Feature: "Mixed syntax"
  Scenario: "Test mixed"
    Given "I add 5 and 5"
    Then "the result should be 10"
    And "no parameters"

step_def "sum of {x:Int} and {y:Int} is {z:Int}" (x y z : Int) => do
  if x + y == z then
    IO.println s!"[HANDLER] Correct: {x} + {y} = {z}"
  else
    IO.println s!"[HANDLER] Incorrect: {x} + {y} != {z}"

Feature: "Multiple binders"
  Scenario: "Check sum"
    Given "sum of 1 and 2 is 3"

#run_feature "Multiple binders"

end Test.StepDef
