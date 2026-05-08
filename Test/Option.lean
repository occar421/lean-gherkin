import LeanGherkin

namespace Test.Option

-- デフォルトでは警告 (warning) になるはず
feature "Default warning" do
  scenario "Should warn" do
    given "undefined step 1"
    then "dummy"

set_option LeanGherkin.undefinedStepSeverity "info"

feature "Info level" do
  scenario "Should info" do
    given "undefined step 2"
    then "dummy"

set_option LeanGherkin.undefinedStepSeverity "none"

feature "None level" do
  scenario "Should be silent" do
    given "undefined step 3"
    then "dummy"

set_option LeanGherkin.undefinedStepSeverity "error"

/-
feature "Error level" do
  scenario "Should error" do
    given "undefined step 4"
    then "dummy"
-/

set_option LeanGherkin.undefinedStepSeverity "warning"

feature "Warning level" do
  scenario "Should warn again" do
    given "undefined step 5"
    then "dummy"

end Test.Option
