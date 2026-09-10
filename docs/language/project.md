# project.yaml

The smallest file. It names the app.

```yaml
name: focus_app
description: The classic focus project but now with metacode.
```

`name` becomes the package name, so it follows the target's package rules:
lowercase, underscores, no spaces. `description` is carried into the generated
project's metadata.

Language, version, and target selection will land here when there is more than
one target.
