import Lean
import LeanGherkin.Ast

namespace LeanGherkin

open Lean

initialize featureExt : SimplePersistentEnvExtension Feature (Array Feature) ←
  registerSimplePersistentEnvExtension {
    name := `LeanGherkin.featureExt
    addEntryFn := fun features feature => features.push feature
    addImportedFn := fun imported => imported.foldl (· ++ ·) #[]
  }

def addFeature (env : Environment) (feature : Feature) : Environment :=
  featureExt.addEntry env feature

def getFeatures (env : Environment) : Array Feature :=
  featureExt.getState env

end LeanGherkin