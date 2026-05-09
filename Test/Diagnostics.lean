import LeanGherkin

namespace Test.Diagnostics

set_option LeanGherkin.enableGherkinSyntax true

set_option LeanGherkin.undefinedStepSeverity "none"
set_option LeanGherkin.validationSeverity "info"

-- 正常なシナリオ
Feature: Valid Feature
  Scenario: valid scenario
    Given something
    When I do something
    Then something happens

-- 警告が出るはずのシナリオ: ステップが空
Feature: Empty Scenario
  Scenario: empty
    -- 何も書かない

-- 警告が出るはずのシナリオ: then がない
Feature: No Then
  Scenario: missing then
    Given something
    When I do something

-- 警告が出るはずのシナリオ: 順序が逆
Feature: Bad Order
  Scenario: wrong order
    Then something happens
    When I do something
    Given something

end Test.Diagnostics
