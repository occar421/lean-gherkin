import LeanGherkin

namespace Test.Option

-- デフォルトでは警告 (warning) になるはず
Feature: Default warning
  Scenario: Should warn
    Given undefined step 1
    Then dummy

set_option LeanGherkin.undefinedStepSeverity "info"

Feature: Info level
  Scenario: Should info
    Given undefined step 2
    Then dummy

set_option LeanGherkin.undefinedStepSeverity "none"

Feature: None level
  Scenario: Should be silent
    Given undefined step 3
    Then dummy

set_option LeanGherkin.undefinedStepSeverity "error"

/-
Feature: Error level
  Scenario: Should error
    Given undefined step 4
    Then dummy
-/

set_option LeanGherkin.undefinedStepSeverity "warning"

Feature: Warning level
  Scenario: Should warn again
    Given undefined step 5
    Then dummy

end Test.Option
