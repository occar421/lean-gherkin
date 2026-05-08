import Lean

namespace LeanGherkin

open Lean

/--
A step handler is a function that takes no arguments and returns `IO Unit`.
In the future, this might become more complex (e.g., returning results or taking state).
-/
def StepHandler := IO Unit

structure StepDefinition where
  text : String
  handlerName : Name

-- We store step definitions in an Array initially for the SimplePersistentEnvExtension.
-- The state will be a Map for fast lookup.
initialize stepDefExt : SimplePersistentEnvExtension StepDefinition (PHashMap String StepDefinition) ←
  registerSimplePersistentEnvExtension {
    name := `LeanGherkin.stepDefExt
    addEntryFn := fun map defn => map.insert defn.text defn
    addImportedFn := fun imported => 
      imported.foldl (fun acc array => array.foldl (fun acc2 defn => acc2.insert defn.text defn) acc) {}
  }

def addStepDefinition (env : Environment) (defn : StepDefinition) : Environment :=
  stepDefExt.addEntry env defn

def getStepDefinitions (env : Environment) : PHashMap String StepDefinition :=
  stepDefExt.getState env

def findStepDefinition (env : Environment) (text : String) : Option StepDefinition :=
  (getStepDefinitions env).find? text

end LeanGherkin
