package lock

import "gopkg.in/yaml.v3"

// parseYAML is the tests' way of writing a spec file as text. Production code
// reaches YAML through core/spec, which reads files.
func parseYAML(text string) (map[string]any, error) {
	var out map[string]any
	if err := yaml.Unmarshal([]byte(text), &out); err != nil {
		return nil, err
	}
	if out == nil {
		out = map[string]any{}
	}
	return out, nil
}
