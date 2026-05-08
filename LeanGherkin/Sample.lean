import LeanGherkin.Syntax

open LeanGherkin

feature "Calculator" do
  scenario "addition" do
    given "a calculator"
    when "I add 1 and 2"
    then "the result should be 3"