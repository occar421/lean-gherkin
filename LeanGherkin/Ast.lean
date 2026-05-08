namespace LeanGherkin

inductive StepKind where
  | given
  | when
  | then
  | and
  | but
  deriving BEq, Repr

structure Step where
  kind : StepKind
  text : String
  deriving BEq, Repr

structure Scenario where
  name : String
  steps : Array Step
  deriving BEq, Repr

structure Feature where
  name : String
  scenarios : Array Scenario
  deriving BEq, Repr

end LeanGherkin