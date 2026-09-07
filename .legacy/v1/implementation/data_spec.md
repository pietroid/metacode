# Data Spec

This spec structures how data should be stored, retrieved and managed.

- Everything is managed data.yaml
- Each key is a store. The name is declared in the key name itself.

A store is a physical instance of where a data will be managed, preserved and changed.

## Store syntax

```yaml
storeName:
    value: string, number, boolean, datetime, list, model
    initialValue: # an actual instance matching the vlue format
    strategy: ephemeral, local, remote
```

- The data types of value follow the same structure of model spec

### Strategy

For now the strategies are really simple and we should have more detail about their implementation on other specs. But the general overview is:

- Ephemeral: lives only in the RAM memory of the device, not preserved across sessions
- Local: preserved locally on device storage.
- Remote: preserved to a database in a remote server.