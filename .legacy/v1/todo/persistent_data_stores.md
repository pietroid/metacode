# Persistent Data Stores

Currently `type: ephemeral` is the only supported data-store type. Values live only
in memory while the app is running.

## Future work

- `type: persistent` backed by `shared_preferences` or Hive.
- `type: cloud` backed by Firestore or a REST backend.
- Generate serialization/deserialization code.
- Generate migration scripts when fields change.
- Load persisted initial values on startup.
