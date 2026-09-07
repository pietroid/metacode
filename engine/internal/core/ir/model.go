package ir

// Model represents a data model declared in data.yaml.
// Full generation is deferred; for the MVP we only detect declared models.
type Model struct {
	Name   string
	Fields map[string]string
}

// Enum represents an enumeration declared in data.yaml.
// Full generation is deferred; for the MVP we only detect declared enums.
type Enum struct {
	Name   string
	Values []string
}
