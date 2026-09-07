package ir

// IR is the single internal representation produced from the raw specs.
type IR struct {
	Project   Project
	Stores    []Store
	Models    []Model
	Enums     []Enum
	UI        []UIComponent
	Behaviors []BehaviorScenario
	Symbols   SymbolTable
	Warnings  []string
}
