import LeanGherkin.StepDef
import LeanGherkin.Elab
import LeanGherkin.Runner

namespace LeanGherkin.TestTheorem

-- Simple theorem step
step_theorem "1 plus 1 is 2" : 1 + 1 = 2 := rfl

-- Parameterized theorem step
step_theorem "{n:Nat} is equal to itself" : n = n := rfl

feature "Theorem Feature" do
  scenario "Verify simple math" do
    then "1 plus 1 is 2"
  scenario "Verify reflexivity" do
    then "5 is equal to itself"

#run_feature "Theorem Feature"
#run_scenario "Verify simple math"
#run_scenario "Verify reflexivity"

-- Test failing theorem (should fail at compile time)
-- step_theorem "this will fail" : 1 + 1 = 3 := by simp

end LeanGherkin.TestTheorem
