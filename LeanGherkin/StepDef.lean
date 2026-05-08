import Lean

namespace LeanGherkin

open Lean

def StepHandler := List String → IO Unit

inductive StepPart where
  | literal : String → StepPart
  | parameter : Name → Name → StepPart -- name and type name
  deriving Inhabited, Repr

structure StepPattern where
  parts : List StepPart
  deriving Inhabited, Repr

structure StepDefinition where
  pattern : StepPattern
  handlerName : Name

instance : Inhabited StepDefinition where
  default := { pattern := { parts := [] }, handlerName := Name.anonymous }

/--
A typeclass for types that can be parsed from a Gherkin step argument string.
-/
class FromGherkinArg (α : Type) where
  fromGherkinArg : String → Option α

instance : FromGherkinArg Int where
  fromGherkinArg s := s.toInt?

instance : FromGherkinArg String where
  fromGherkinArg s := some s

instance : FromGherkinArg Nat where
  fromGherkinArg s := s.toNat?

-- We store step definitions in an Array.
-- For Milestone 6, we can't use a simple PHashMap String StepDefinition because we need to match patterns.
initialize stepDefExt : SimplePersistentEnvExtension StepDefinition (Array StepDefinition) ←
  registerSimplePersistentEnvExtension {
    name := `LeanGherkin.stepDefExt
    addEntryFn := fun arr defn => arr.push defn
    addImportedFn := fun imported => 
      imported.foldl (fun acc array => acc ++ array) #[]
  }

def addStepDefinition (env : Environment) (defn : StepDefinition) : Environment :=
  stepDefExt.addEntry env defn

def getStepDefinitions (env : Environment) : Array StepDefinition :=
  stepDefExt.getState env

/--
Parses a step definition pattern string like "I add {x:Int} and {y:Int}".
-/
partial def parseStepPattern (s : String) : StepPattern :=
  let rec consumeParam (chars : List Char) (current : String) : StepPart × List Char :=
    match chars with
    | [] => (StepPart.literal ("{" ++ current), [])
    | '}' :: rest =>
      match current.splitOn ":" with
      | [name, type] => (StepPart.parameter name.trimAscii.toName type.trimAscii.toName, rest)
      | [name] => (StepPart.parameter name.trimAscii.toName `String, rest)
      | _ => (StepPart.literal ("{" ++ current ++ "}"), rest)
    | c :: rest => consumeParam rest (current.push c)
  
  let rec loop (chars : List Char) (acc : List StepPart) (current : String) : List StepPart :=
    match chars with
    | [] => if current.isEmpty then acc.reverse else (StepPart.literal current :: acc).reverse
    | '{' :: rest =>
      let acc' := if current.isEmpty then acc else StepPart.literal current :: acc
      let (param, rest') := consumeParam rest ""
      loop rest' (param :: acc') ""
    | c :: rest => loop rest acc (current.push c)

  { parts := loop s.toList [] "" }

/--
Attempts to match a step text against a pattern.
Returns a list of argument strings if matched.
-/
def matchStep (pattern : StepPattern) (text : String) : Option (List String) :=
  let rec findSubstring (chars : List Char) (sub : List Char) : Option Nat :=
    if sub.isEmpty then some 0
    else
      let rec go (cs : List Char) (idx : Nat) : Option Nat :=
        match cs with
        | [] => none
        | _ :: rest =>
          if cs.take sub.length == sub then some idx
          else go rest (idx + 1)
      go chars 0
  
  let rec loop (parts : List StepPart) (input : List Char) (args : List String) : Option (List String) :=
    match parts with
    | [] => if input.isEmpty then some args.reverse else none
    | StepPart.literal s :: rest =>
      let sChars := s.toList
      if input.take sChars.length == sChars then
        loop rest (input.drop sChars.length) args
      else
        none
    | StepPart.parameter _ _ :: rest =>
      match rest with
      | [] => some (args.reverse ++ [String.ofList input])
      | StepPart.literal s :: _ =>
        let sChars := s.toList
        match findSubstring input sChars with
        | none => none
        | some pos =>
          let val := input.take pos
          loop rest (input.drop pos) (String.ofList val :: args)
      | StepPart.parameter _ _ :: _ => none
  
  loop pattern.parts text.toList []

def findStepDefinition (env : Environment) (text : String) : Option (StepDefinition × List String) :=
  let defs := getStepDefinitions env
  defs.findSome? fun defn =>
    match matchStep defn.pattern text with
    | some args => some (defn, args)
    | none => none

end LeanGherkin
