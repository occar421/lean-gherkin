# lean-gherkin

Lean Gherkin is a PoC Lean 4 library that interprets Gherkin code with Lean 4 (native) parser. 

## PoC Results

The initial Proof of Concept (PoC) successfully demonstrates that Lean 4's powerful macro and elaboration system can support a natural Gherkin DSL.

### Key Achievements
- **Natural Gherkin Syntax**: Implemented a custom parser that supports the classic Gherkin structure (`Feature`, `Scenario`, `Given`, `When`, `Then`, `And`, `But`) without requiring quotes for step descriptions.
- **Type-Safe Step Definitions**: Developed the `step_def` macro, which extracts parameters from step text (e.g., `{x:Int}`) and passes them as typed arguments to Lean handlers.
- **Interactive Feedback**: Integrated `#run_feature` and `#run_scenario` commands, allowing developers to execute and verify scenarios directly within the Lean editor during elaboration.
- **Solid Foundation**: Established a modular architecture for AST representation, elaboration, step registration, and execution, providing a clear path for future extensions like proof integration.

### Example

```lean
import LeanGherkin

set_option LeanGherkin.enableGherkinSyntax true

step_def "I have {x:Int} apples" (x : Int) => do
  IO.println s!"Current apple count: {x}"

Feature: Simple Addition
  Scenario: Adding apples
    Given I have 10 apples
    And I eat 3 apples
    Then I should have 7 apples

#run_feature Simple Addition
```

### Restrictions

- Strict Indentation: It limits free-indentation because the ordinal Lean commands are also interpreted as Gherkin directives. See [Gherkin test data](https://github.com/cucumber/gherkin/blob/main/testdata/good/descriptions.feature).
- Unimplemented Features (just because this is PoC):
  - Localisation: Takes time to implement but possible.
  - Rule: Maybe easy to implement.
  - Example, Examples, and Background : Easy to implement.
  - `*`: Easy to implement. Validation is challenging.
  - Scenario Outline: Possible.
  - Secondary keywords: Possible.

## Reference

- [Reference | Cucumber](https://cucumber.io/docs/gherkin/reference/): Gherkin keywords.
- [Gherkin Berp](https://github.com/cucumber/gherkin/blob/main/gherkin.berp): Gherkin grammar.
