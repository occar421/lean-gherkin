import Lean
import LeanGherkin

namespace Test.GherkinSyntax

set_option LeanGherkin.enableGherkinSyntax true

step_def "I have {x:Int} apples" (x : Int) => do
  IO.println s!"[HANDLER] I have {x} apples"

step_def "I eat {x:Int} apples" (x : Int) => do
  IO.println s!"[HANDLER] I eat {x} apples"

step_def "I eat 1 apple" => do
  IO.println "[HANDLER] I eat 1 apple"

step_def "I should have {x:Int} apples" (x : Int) => do
  IO.println s!"[HANDLER] I should have {x} apples"

Feature: Apple counting
  # This is a comment
  Scenario: Eating apples
    Given I have 10 apples
    When I eat 3 apples
    Then I should have 7 apples
  
  # This is another comment
  # This is another comment2
  Scenario: Eating apples2 w/ "Scenario: b"
    Given I have 10 apples
    When I eat 3 apples
    Then I should have 7 apples

Feature: Apple counting with and/but
  Scenario: Eating and buying apples
    Given I have 10 apples
    And I eat 2 apples
    But I eat 1 apple
    Then I should have 7 apples

#run_feature Apple counting
#run_feature Apple counting with and/but

end Test.GherkinSyntax
