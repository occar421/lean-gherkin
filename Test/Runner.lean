import LeanGherkin

namespace Test.Runner

step_def "a calculator" => (IO.println "[HANDLER] Initializing calculator..." : IO Unit)
step_def "I add 1 and 2" => (IO.println "[HANDLER] Adding 1 and 2..." : IO Unit)
step_def "the result should be 3" => (IO.println "[HANDLER] Checking result..." : IO Unit)
step_def "I add 2 and 3" => (IO.println "[HANDLER] Adding 2 and 3..." : IO Unit)
step_def "the result should be 5" => (IO.println "[HANDLER] Checking result..." : IO Unit)

feature "Calculator Addition" do
  scenario "Add two numbers" do
    given "a calculator"
    when "I add 1 and 2"
    then "the result should be 3"
  scenario "Add another two numbers" do
    given "a calculator"
    when "I add 2 and 3"
    then "the result should be 5"

set_option LeanGherkin.validationSeverity "info"

feature "Failing Feature" do
  scenario "Scenario with missing step" do
    given "a non-existent step"
  scenario "Scenario with error" do
    given "a calculator"
    then "this step will fail if I throw an error"

step_def "this step will fail if I throw an error" => (throw (IO.userError "Simulated failure") : IO Unit)

#run_feature "Calculator Addition"
#run_scenario "Add two numbers"
-- #run_feature "Failing Feature"

end Test.Runner
