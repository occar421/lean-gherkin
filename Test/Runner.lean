import LeanGherkin

namespace Test.Runner

step_def "a calculator" => (IO.println "[HANDLER] Initializing calculator..." : IO Unit)
step_def "I add 1 and 2" => (IO.println "[HANDLER] Adding 1 and 2..." : IO Unit)
step_def "the result should be 3" => (IO.println "[HANDLER] Checking result..." : IO Unit)
step_def "I add 2 and 3" => (IO.println "[HANDLER] Adding 2 and 3..." : IO Unit)
step_def "the result should be 5" => (IO.println "[HANDLER] Checking result..." : IO Unit)

Feature: "Calculator Addition"
  Scenario: "Add two numbers"
    Given "a calculator"
    When "I add 1 and 2"
    Then "the result should be 3"
  Scenario: "Add another two numbers"
    Given "a calculator"
    When "I add 2 and 3"
    Then "the result should be 5"

set_option LeanGherkin.validationSeverity "info"

Feature: "Failing Feature"
  Scenario: "Scenario with missing step"
    Given "a non-existent step"
  Scenario: "Scenario with error"
    Given "a calculator"
    Then "this step will fail if I throw an error"

step_def "this step will fail if I throw an error" => (throw (IO.userError "Simulated failure") : IO Unit)

#run_feature "Calculator Addition"
#run_scenario "Add two numbers"
-- #run_feature "Failing Feature"

end Test.Runner
