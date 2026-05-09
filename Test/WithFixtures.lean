import Lean
import LeanGherkin

open Lean Elab Command

namespace Test.WithFixtures

syntax (name := loadLean) "load_gherkin_files " str : command

@[command_elab loadLean]
def elabLoadLean : CommandElab := fun stx => do
  let `(command| load_gherkin_files $pathStx) := stx | throwUnsupportedSyntax
  let path := pathStx.getString
  let paths ← liftIO <| do
    let path := System.FilePath.mk path
    if ← path.isDir then
      let entries ← path.readDir
      pure <| entries.filterMap fun entry =>
        let p := entry.path
        if p.extension == some "feature" then some p else none
    else
      pure #[path]
  for path in paths do
    let content ← liftIO <| IO.FS.readFile path
    let env ← getEnv
    match Parser.runParserCategory env `command content with
    | Except.ok stx => elabCommand stx
    | Except.error err => throwError (m!"Error in {path}: {err}")

set_option LeanGherkin.enableGherkinSyntax true

load_gherkin_files "./Test/fixtures"

end Test.WithFixtures
