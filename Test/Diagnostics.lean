import LeanGherkin

namespace Test.Diagnostics

set_option LeanGherkin.undefinedStepSeverity "none"
set_option LeanGherkin.validationSeverity "info"

-- 正常なシナリオ
feature "Valid Feature" do
  scenario "valid scenario" do
    given "something"
    when "I do something"
    then "something happens"

-- 警告が出るはずのシナリオ: ステップが空
feature "Empty Scenario" do
  scenario "empty" do
    -- 何も書かない

-- 警告が出るはずのシナリオ: then がない
feature "No Then" do
  scenario "missing then" do
    given "something"
    when "I do something"

-- 警告が出るはずのシナリオ: 順序が逆
feature "Bad Order" do
  scenario "wrong order" do
    then "something happens"
    when "I do something"
    given "something"

end Test.Diagnostics
