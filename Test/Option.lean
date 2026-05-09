import LeanGherkin

namespace Test.Option

set_option LeanGherkin.undefinedStepSeverity "info" in
Feature: Info level
  Scenario: Should info
    Given undefined step 1
    Then dummy

set_option LeanGherkin.undefinedStepSeverity "none" in
Feature: None level
  Scenario: Should be silent
    Given undefined step 2
    Then dummy

--

set_option LeanGherkin.validationSeverity "info" in
Feature: No steps
  Scenario: Should warn

set_option LeanGherkin.validationSeverity "none" in
Feature: No steps but OK
  Scenario: Should be silent

end Test.Option
