## New proposal
 
Metacode is the engine behind my-own.app

Very simply put, we will simplify both metacode and my-own.app for a simple thing: create any app in instants, very cheaply.

### The UI

Not using A2UI anymore. We will just use metacode's UI.

### Bindings

Instead of using wrappers, we just call functions that are called bindings. 

When we see something like 

```yaml
defaultState:
  column:
    - text: "Minhas tarefas"
    - listView:
        data: taskList
```

taskList is a binding.

### Data

Data is precisely what we need to store for the user. Bindings connect it with the UI.

### Variables

If there is no binding available for taskList, it becomes a free variable and thus a state

### Architecture of metacode engine running

It is a circular architecture, where actions have direct access to data state

State (yaml) <-> Bindings (Dart) <-> UI (yaml) <-> Actions (Dart) <-> State (yaml)

### Action <-> State connection

For actions to work properly, we need them to be able to change the data state.

So a connection is a function of a state machine, where F is the function responsible for giving the next state based on the current. So a event is like a transfer function.

NextState = event(CurrentState)

## Example: a tiny task-list app

A concrete example that ties the four pieces together lives under
`examples/new_proposal_app/`. Here is the gist.

### Models (`models.yaml`)

```yaml
task:
  title: string
  done: boolean
```

### State (`data.yaml`)

```yaml
state:
  taskStore:
    value: list(task)
    initialValue: []
    strategy: local

  draftStore:
    value: string
    initialValue: ""
    strategy: ephemeral
```

### UI (`ui.yaml`)

```yaml
homePage:
  scaffold:
    appBar:
      title: "Task List"
    body:
      column:
        - taskInput
        - taskList

taskInput:
  row:
    - expanded:
        draftField
    - addButton

draftField:
  textField:
    value: draftStore
    hint: "What needs to be done?"
    onChanged: updateDraft

addButton:
  iconButton:
    icon: add
    onPressed: addTask

taskList:
  listView:
    data: taskList
    empty: emptyState
    itemBuilder: taskTile

taskTile:
  listTile:
    title: taskTitle
    leading: taskCheckbox

taskCheckbox:
  checkbox:
    value: taskDone
    onChanged: toggleTask

emptyState:
  center:
    text: "No tasks yet"
```

`taskList`, `taskTitle`, `taskDone` and `draftStore` are bindings. The engine
derives them from the state and the widget shape.

### Actions (`actions.yaml`)

```yaml
actions:
  updateDraft:
    params:
      value: string
    nextState:
      draftStore.value: value

  addTask:
    nextState:
      taskStore.value: append(taskStore.value, {title: draftStore.value, done: false})
      draftStore.value: ""

  toggleTask:
    params:
      index: int
    nextState:
      taskStore.value[index].done: not(taskStore.value[index].done)
```

Each action is a transfer function: given the current state (and any event
payload), it returns the next state.

### Behaviors (`behaviors.yaml`)

```yaml
empty state is shown when there are no tasks:
  given: taskStore.value is []
  when: # always
  then: taskList = emptyState

typing updates the draft:
  given: draftStore.value is ""
  when: draftField.onChanged
  then: draftStore.value should be "Buy milk"

adding a task appends it:
  given: taskStore.value is []
  when: addButton.onPressed
  then: taskStore.value.length should be 1

toggling marks a task done:
  given: taskStore.value is [{title: "Buy milk", done: false}]
  when: taskCheckbox.onChanged
  then: taskStore.value[0].done should be true
```

One scenario, one whole-app test — same rule as today.

