# Multi-Target Generation

The MVP only generates Flutter/Dart. The README describes Metacode as a generic
tool, so the generator should eventually be pluggable.

## Future work

- Define a target-agnostic intermediate representation from the resolved graph.
- Implement generators for:
  - React / React Native / Next.js
  - SwiftUI / UIKit
  - Android (Jetpack Compose / XML)
  - Plain HTML/CSS/JS
- Move target-specific logic out of the parser/graph and into generator packages.
