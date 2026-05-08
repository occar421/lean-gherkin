import LeanGherkin.StepDef
import LeanGherkin.Elab

namespace LeanGherkin.TestStepDef

-- 1. Define some steps
step_def "a calculator" => (IO.println "Initializing calculator..." : IO Unit)

step_def "I add 1 and 2" => (IO.println "Adding 1 and 2..." : IO Unit)

step_def "the result should be 3" => (IO.println "Checking result..." : IO Unit)

-- 2. Define a feature using these steps
feature "Calculator Addition" do
  scenario "Add two numbers" do
    given "a calculator"
    when "I add 1 and 2"
    then "the result should be 3"

-- 3. Check for undefined step warning
feature "Undefined Step Test" do
  scenario "Missing step" do
    given "a non-existent step"

-- 4. Check for duplicate step definition warning
step_def "a calculator" => (IO.println "Duplicate definition" : IO Unit)

#print_features

end LeanGherkin.TestStepDef
