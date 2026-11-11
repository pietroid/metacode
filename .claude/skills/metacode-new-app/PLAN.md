# plan.yaml: the format

`<app>/plan.yaml` is the **only file you write**. It decides every type, state field, text, route and work unit before any is filled, so agents can work in parallel without talking to each other. `scaffold` turns it into the contract files (app.yaml, app/models/, labels, navigation; don't edit those, edit the plan and scaffold again) and a compiling stub per unit.

```yaml
plan:
  summary: >-
    One paragraph: what the app is for and how it feels. Every agent reads it;
    it is also app.yaml's description.
  style: >-
    Warm sand page, teal primary, terracotta accent, Plus Jakarta Sans, round corners.
  start: loadRate                      # optional: an action run when the app opens

  # --- the contract ---------------------------------------------------------
  models:
    category: [transport, stay, food, activity]          # an enum
    item:                                                # a model: field: type
      day: number
      title: string
      category: category
      cost: number
    trip:                                                # with a purpose (for the index)
      purpose: a planned trip and its itinerary
      fields: {destination: string, budget: number, favorite: boolean, items: list(item)}
  state:                               # by scope; each field `type = initial`
    ephemeral:                         # memory only: form input, loading flags
      draftTitle: string = ''
      rateStatus: rateStatus           # no `= ...`: '' / 0 / false / [] / null / the enum's first value
    local:                             # this device
      selectedTrip: number = 0
      trips:                           # rich initial data: {type, initial}
        type: list(trip)
        initial:
        - {destination: Lisbon, budget: 3000, favorite: true, items: [{day: 1, title: Flight, category: transport, cost: 640}]}
        - {destination: Kyoto, budget: 4500, favorite: false, items: []}
    remote: {sharedTrips: list(string)}                  # the user's, on the backend
    system: {shareLog: list(string)}                     # backend only
    shared:                                              # everyone's, read-only on the client
      popular:
        type: list(popular)
        initial: [{destination: Lisbon, count: 42}]
  labels:                              # every text the UI shows
    appTitle: Trips
    noTrips: No trips yet.
  routes:                              # the first opens first
    home: MainPage
    trip: TripPage
    addItem: {bottomSheet: AddItemSheet}                 # or {dialog: Page}

  # --- the work units --------------------------------------------------------
  pages:
    MainPage:
      purpose: The trip list under an app bar; a + button runs openNewTrip.
      uses: [TripList, openNewTrip, appTitle]            # components, values, actions, labels
  components:
    TripCard:
      purpose: One trip row (index), tap opens it.
      uses: [tripName, tripBudgetText, openTrip]
    StatTile:
      purpose: A small stat, `.label` over `.amount`.
      params: {label: text, amount: text}                # .name -> text, icon, action, color, number, node, literal
  actions:
    openTrip:
      purpose: Selects trip `index` and pushes the trip route.
      params: [emit, core, index]                        # emit, core, remote, labels, index, value
      test: selectedTrip becomes 1 and navigation is ['push trip'].
    updateDraft:
      purpose: Keeps the typed title.
      params: [emit]
      value: String
      test: draftTitle is the value.
    shareTrip:
      purpose: Shares the selected trip via the remote shareTrip; offline -> shareStatus failed.
      params: [emit, remote]
      uses: [shareTrip]                                  # remote actions and shared helpers it calls
  remote:
    shareTrip:
      purpose: Counts the destination in popular; refuses an empty one.
      value: String
  values:
    tripName:
      purpose: Trip index's destination.
      returns: String
      params: [index]
      test: index 1 -> Kyoto.
  shared:
    formatMoney:
      purpose: 1234.5 -> "$1,234.50".
      signature: String formatMoney(num amount)
      in: values                                         # or actions
  tests:                               # layout states the initial state never shows
    tripOpen: {state: {selectedTrip: 1}, route: trip}
    noTrips: {state: {trips: []}}
```

Types: `string`, `number`, `boolean`, `datetime`, `list(x)`, `x?`, a model, an enum. Dart names are capitalized (`trip` -> `Trip`). Scopes (see REFERENCE.md "State scopes"): the client writes `ephemeral`/`local`/`remote`; only remote actions write `shared`/`system`. A flat `state:` (no scopes) is all `local`.

## Rules

- **YAML: block style for units, and quote prose.** Never `{...}` flow style for a unit (a comma in a purpose breaks it). Quote any text containing `: `, starting with a quote, backtick, `[`, `{`, or holding `#`; or use `purpose: >-` with the text below. Flow style is fine for data (`initial:` rows, `tests:`).
- **Names are the contract.** Files follow names (`TripCard` -> `app/views/components/trip_card.yaml`). Pages and components `ThisCase`; actions, values, labels, helpers `thisCase`. Actions, values and labels never share a name (a remote action may share its local action's name).
- **`uses` is complete**: every component, value, action and label a view shows or runs. The scaffold rejects a name that isn't planned. Purposes say *what* and *from where* (which state field, which label), not how.
- **Values do the logic, views only place.** Anything computed (a sum, a filter, a formatted date, "3 trips", a color, an icon name, whether a button is enabled) is a value.
- `returns:` a Dart type: `String`, `bool`, `num`, `List<Trip>`, `Trip?`, an enum. Prefer `num` over `double`. A list value feeds `listView.data`; items get `index`.
- Actions: `index` for list items / a component's `index:`; `value` (type in `value:`) for inputs (`textField` String, `toggle` bool, `slider` num, `dropdown` String).
- `test:` one sentence; every action and value gets one.
- Network: a keyless endpoint, its exact URL and JSON path in the purpose, and a status enum in state.
- `tests:` one per screen the initial state doesn't show, with only the fields that differ.
- A component is one visual piece (~5-40 lines). Split big screens.
