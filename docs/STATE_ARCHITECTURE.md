# State architecture

Status: built (sections 1-7; see "Implementation notes" at the end). Scope: where each piece of an app's state lives, who can read
and write it, and how the engine keeps the client and the backend in sync.
First use case: the my-own.app waitlist (section 6).

## Idea

An app's state is split into **five scopes**. Each scope is declared once, under
`state:` in `app.yaml`, and everything else follows from it: where a field is stored, who
can read it, who can write it, and whether the engine syncs it. Syncing is the
engine's job, never the app's: the app has no code for fetching, pushing,
caching or reconnecting.

Code runs in two places:

- **Local actions** (`app/actions/*.dart`, today's actions) run on the client.
- **Remote actions** (`app/actions/remote/*.dart`) run on the backend. A local
  action calls them; each one is an endpoint. Always "remote", never "server".

The backend is part of Metacode: it compiles the same project folder, so its
code changes without a deploy.

## 1. The five scopes

| # | scope | lives in | client reads | local actions write | remote actions read / write |
|---|---|---|---|---|---|
| 1 | `ephemeral` | client memory | yes | yes | no / no |
| 2 | `local` | client `.state/` | yes | yes | no / no |
| 3 | `remote` | backend, per user; mirrored on the client | yes | yes (local first, then synced up) | yes / yes (the caller's) |
| 4 | `system` | backend only | **no** | **no** | yes / yes |
| 5 | `shared` | backend, one copy; mirrored on every client | yes | **no** | yes / yes |

- **Ephemeral:** form input, loading flags, animation steps. Gone on reload.
- **Local:** preferences and progress that belong to this device only.
- **Remote:** the user's own data, backed up on the backend (and on every
  device they use, once login exists; section 3). The client is
  the user's agent: it may change its own remote fields freely, so nothing in
  `remote` is trusted for anything beyond that user.
- **System:** the backend's private data (the waitlist's emails, counters
  that must not be forged). Never leaves the backend.
- **Shared:** one copy everyone sees (the waitlist count). Only remote
  actions change it, so every change goes through the app's own validation.

The general rule: **the client writes what is its own; anything trusted or
seen by others is written only by a remote action.**

## 2. Declaring the scopes

`app.yaml` keeps its `state:` key; under it, one key per scope. Each holds
the initial values of that scope's fields. A scope with no fields is left out.

```yaml
name: metacode
start: playExample
state:
  ephemeral:
    email: ''
    waitlistStatus: idle
    chatStage: 0
    buildStep: 0
    tweaking: false
    exampleIndex: 0
  local:
    idea: ''
    appKind: custom
    appColor: orange
    appPhotos: false
    appStreak: false
  remote:
    waitlistEmail: ''
  system:
    waitlist: []
  shared:
    waitlistCount: 0
    config:
      astrology: false
```

`config` (the site's feature toggles, like the hidden astrology example) is
`shared`: one value for every visitor, read-only on clients. It's turned on
by editing `.state/shared.yaml` on the backend (or later by an admin remote
action), and the change reaches every open client over the sync stream, with
no deploy. The `app.yaml` value is only the seed.

The types stay in the reserved model `app/models/state.yaml`, with the same
shape:

```yaml
state:
  ephemeral:
    email: string
    waitlistStatus: waitlistStatus
    chatStage: number
    ...
  local:
    idea: string
    ...
  remote:
    waitlistEmail: string
  system:
    waitlist: list(string)
  shared:
    waitlistCount: number
    config: config
```

For `remote`, `system` and `shared`, the `app.yaml` values are the seed: what
a new user (remote) or an empty backend store (system, shared) starts with.

**Code still sees one flat `State`.** Field names are unique across all five
scopes (the compiler checks), so actions and values read `state.email` and
`state.waitlistCount` as they do today. The scope only decides which fields
each generated `State` and `StateDelta` has (section 4).

## 3. The backend's global state

The backend holds one global state per app (root and each module):

```
system:  { waitlist: [...] }                       # keys from system.yaml
shared:  { waitlistCount: 1285 }                   # keys from shared.yaml
users:
  <userId>: { waitlistEmail: 'ada@example.com' }   # keys from remote.yaml
  <userId>: { ... }
```

For now these are plain documents: `.state/system.yaml`, `.state/shared.yaml`
and `.state/users/<userId>.yaml` under the app's folder on the backend
(modules under `modules/<name>/.state/`). This moves to a database later
without changing anything in the app.

On the client, `.state/` keeps `local` as today (`state.yaml`), plus a cache
of the user's `remote` fields, the last `shared` snapshot (so the app opens
offline with the last known values) and the outbox of remote changes not yet
sent (section 5, "Offline first"). `ephemeral` and `system` are never written on the client.

### Users: anonymous for now

There is no login yet. Every user is anonymous:

- On first launch the engine creates a random user id (a UUID) and saves it
  in `.state/user.yaml` (localStorage on web), so it survives refreshes, new
  tabs and restarts. Every request carries it as a header. The id is shared
  by the root app and its modules: one user, one id.
- **The id is engine state, not app state.** It's saved with the state files
  but isn't a field of any scope: it's not in `State`, no action or value can
  read or emit it, and it's never declared in `app.yaml`. Remote actions don't
  need it either: they act on "the caller's `remote`" and the backend picks
  the document from the header. Keeping it out of app code is what keeps it
  secret: no value can show it, and no action can copy it into `shared` or a
  remote call's argument. If an app ever needs to tell users apart (an
  author name on a shared post), the engine will expose a separate public id
  derived from it, never the id itself.
- **Users are created lazily.** The id exists on the client from the first
  launch, but the backend creates `users/<id>.yaml` (from the `remote` seed)
  only on that user's first write: the first `remote` change sent from the
  outbox, or the first remote call. Until then the sync stream sends `shared`
  and the `remote` seed. Visitors who only look around never create a user;
  the backend stores only people who did something.
- The id is the only credential, so it's a bearer secret: it never appears
  in shared state, URLs or logs.
- **One anonymous id is one browser or device.** Until login exists,
  `remote` behaves like `local` that is backed up on the backend: the same
  data on every tab of the same browser, but a second device, a private
  window or cleared storage is a new user with fresh `remote` fields. That's
  fine for the waitlist: at worst someone joins twice, and the dedupe in
  `system` keeps the count right.
- **Later, login** links an account to the current anonymous id: the first
  device keeps its id, and other devices that sign in switch to that id (the
  engine replaces the saved id and opens a new sync stream, which sends a new
  snapshot). Only then does `remote` really follow the user across devices.
  Nothing changes in the app's files.

## 4. Actions, and what each can touch

### Local actions

Unchanged signature, plus one optional parameter, `Remote remote`, whose
methods call the remote actions:

```dart
Future<void> name(State state, [emit], [Core core], [Remote remote], [Labels labels], [int index], [T value])
```

They import `.generated/state.dart`:

- `State` has `ephemeral`, `local`, `remote` and `shared` fields (`shared`
  read-only). It has no `system` fields at all.
- `StateDelta` has `ephemeral`, `local` and `remote` parameters. Emitting a
  `shared` field doesn't compile: there is no such parameter.

Values see the same `State` as local actions.

### Remote actions

`app/actions/remote/<name>.dart`. One action, one endpoint. They take the
state and an optional single argument, the input sent by the local action:

```dart
Future<void> name(State state, [void Function(StateDelta) emit], [T value])
```

They import `.generated/remote_state.dart`:

- `State` has the caller's `remote` fields, `shared` and `system`. Not
  `ephemeral` or `local`: those stay on the device; anything a remote action
  needs from them is passed as its argument.
- `StateDelta` has `remote` (the caller's), `shared` and `system` parameters.

The argument is the only input from the client, and it's untrusted: the
action validates it. Remote actions for one app run one at a time on the
backend, so read-modify-write on `shared` and `system` (`count + 1`, append
to a list) can't race.

### Calling one

`remote.<name>(value)` returns a `Future<RemoteError?>` that completes once
the backend has run the action **and its changes are applied to this
client's state**, with null. So after `await remote.joinWaitlist(email)`,
`state` already has the new `waitlistCount`: no fetch, no polling. If the
action refuses (`throw RemoteError('code')`), the backend can't be reached
(`offline`) or the action crashed (`failed`), it completes with that
`RemoteError`. It's returned, not thrown: dart_eval breaks `try`/`catch`
around an `await` that doesn't throw.

### Compiler bundles

The compiler builds two programs from the same files:

- **Client:** local actions, values, and a generated `Remote` whose methods
  send the call. No remote action bodies, no `system` fields.
- **Backend:** remote actions only, with their `State`/`StateDelta`.

In tests (`test_app`), remote calls run in-process against the sample state,
so `app.joinWaitlist(sample(...))` runs the local action and the remote
action it calls, and the result shows both.

## 5. Sync (engine only; part 2)

None of this is visible to the app. It lives in the engine
(`lib/engine/sync/`) and a backend (`lib/backend/`, served by the Dart Frog
project in `server/`).

### Offline first

The device's copy is the one the app runs on; the backend only updates it.
Today every app already starts from `.state/state.yaml` on the device and
never waits for anything. That stays true for every scope:

- **Start:** the engine loads `local` and the cached `remote` and `shared`
  from `.state/` (falling back to the `app.yaml` seeds) and shows the app
  right away. The sync stream connects in the background; its snapshot
  arrives as an ordinary state change, like an `emit`.
- **Offline or backend down:** the app keeps running on the cached values.
  `shared` shows the last known values. `remote` changes apply locally and
  wait in the outbox. The engine retries the stream with backoff and, once
  connected, sends the outbox and applies the new snapshot.
- **Pending changes win locally.** When a snapshot arrives while the outbox
  still has changes, the engine applies the snapshot and then the outbox on
  top of it, so a change the user made offline never flickers back to the old
  value. When the backend acknowledges them, they leave the outbox.
- **Remote calls need the backend.** They aren't queued: their result
  depends on `shared` and `system` at the moment they run, and the UI is
  waiting on them (the loading state). Offline, `remote.<name>()` throws
  `RemoteError('offline')` at once, and the local action handles it like any
  other error (the waitlist shows `failed`: a "try again" message). Anything that must happen even offline belongs in `remote`
  fields, which do sync later.
- **No backend at all** (no `backend:` in `app.yaml`, which is how apps run
  today, in the layout check and in the editor): the engine runs everything
  on the device. Remote actions run in-process, as in `test_app`, against a
  local `system` and `shared` saved in `.state/`, and there's one user. The
  app behaves the same; it just isn't shared with anyone. So an app can be
  built and tried end to end before it has a backend.

### Down: SSE, backend to client

On start, each running app (root and each module) opens one SSE stream:

```
GET /sync/<app path>         header: user id
event: snapshot  { version, remote: {...}, shared: {...} }
event: delta     { version, remote?: {...}, shared?: {...} }
```

- The first event is a snapshot of the user's `remote` fields and `shared`.
- After that, every change the backend makes is pushed as a delta: a `shared`
  change to every connected client, a `remote` change to that user's
  connections (all their devices).
- The client merges each delta into its state (the same merge as `emit`) and
  saves it to the cache. Values and widgets update as they do for any state
  change.
- Versions are increasing per app. A delta the client already has (same or
  older version) is dropped. On reconnect the backend sends a new snapshot.

### Up: local first, then synced

When a local action emits a `remote` field:

1. The engine applies it to the local state immediately, like any field.
2. It adds the field to the **outbox** (saved in `.state/`, so it survives a
   reload or being offline).
3. It sends the outbox: `POST /state/<app path>` with the changed fields. The
   backend checks each against `remote.yaml` (known field, right type), saves
   them to the user's document and pushes them to the user's other devices.
4. Once acknowledged, the fields leave the outbox. Offline, it retries when
   the connection comes back. Same field changed twice: the last one wins.

Only `remote` fields go up this way. The endpoint rejects anything else, so
a modified client still can't touch `shared` or `system`.

### Remote calls

```
POST /call/<app path>/<name>    header: user id    body: { value, locale }
-> { version, remote?: {...}, shared?: {...} }
```

1. The engine sends the outbox first, so the action sees the user's latest
   `remote` fields.
2. The backend queues the call (one at a time per app), loads `system`,
   `shared` and the caller's `remote`, and runs the action.
3. It splits the resulting delta by scope: saves `system` (never sent),
   saves `shared` and pushes it to everyone, saves `remote` and pushes it to
   the caller's devices.
4. The response carries the same `remote` and `shared` delta and its
   version. The engine applies it before the `remote.<name>()` future
   completes, and the SSE copy is dropped as already seen.

### Where the backend is

`backend: https://api.my-own.app` in the root `app.yaml`, or a dart-define
for local development.

### Changing code without deploying

The backend is a headless `AppRuntime` per app: it holds a `ProjectFiles` on
a folder and recompiles with `LiveProject` on every change, as the desktop
app does. To update it, push files (a git webhook that pulls, or an
authenticated `PUT /files`). The code folder and the data (`.state/`) are
separate, so a code push never touches data.

## 6. First use case: the waitlist

The dialog has an email field. Tapping "Join waitlist" sends the email, the
button shows loading while it's sent, and when it's done the dialog shows
"You're on the list" with the new count, and the footer's count is updated
too, on every open client.

### State

```yaml
state:
  ephemeral:
    email: ''             # the text field
    waitlistStatus: idle  # idle | invalid | sending | failed
  remote:
    waitlistEmail: ''     # set once joined: survives reloads, on the backend
  system:
    waitlist: []          # every email, backend only
  shared:
    waitlistCount: 0      # what everyone sees
```

`waitlistStatus` gains `sending` and `failed` and loses `joined`: being joined is now
`waitlistEmail` being set, which is the user's remote state.

### Local action: `app/actions/join_waitlist.dart`

Validates the input, shows loading the same way `togglePhotos` shows
"Updating", and calls the remote action:

```dart
Future<void> joinWaitlist(State state, void Function(StateDelta) emit, Remote remote) async {
  if (state.waitlistStatus == WaitlistStatus.sending || state.waitlistEmail.isNotEmpty) return;
  final email = state.email.trim();
  if (!looksLikeEmail(email)) return emit(StateDelta(waitlistStatus: WaitlistStatus.invalid));
  emit(StateDelta(waitlistStatus: WaitlistStatus.sending));
  final error = await remote.joinWaitlist(email);
  emit(StateDelta(
    waitlistStatus: error == null ? WaitlistStatus.idle : WaitlistStatus.failed, // offline or rejected: "try again"
  ));
}
```

### Remote action: `app/actions/remote/join_waitlist.dart`

Validates again (the argument is untrusted), adds the email to the list,
increments the shared count and marks the caller as joined:

```dart
Future<void> joinWaitlist(State state, void Function(StateDelta) emit, String value) async {
  final email = value.trim().toLowerCase();
  if (!looksLikeEmail(email)) throw RemoteError('invalidEmail');
  if (state.waitlist.contains(email)) return emit(StateDelta(waitlistEmail: email));
  emit(StateDelta(
    waitlist: [...state.waitlist, email],     // system: saved, never sent
    waitlistCount: state.waitlistCount + 1,   // shared: saved, pushed to everyone
    waitlistEmail: email,                     // remote: saved, pushed to this user
  ));
}
```

`looksLikeEmail` is in `app/actions/shared/`, used by both. A local and a
remote action may share a name; they're in different bundles.

### Views

- `waitlistJoined`: `state.waitlistEmail.isNotEmpty`.
- `waitlistSending`: `state.waitlistStatus == WaitlistStatus.sending`.
- `joinButtonText`: "Joining…" while sending, else "Join waitlist" (the
  button has no loading prop).
- `waitlistFailed`: shows "Couldn't reach the list... try again"; typing
  again clears it (`updateEmail`).
- `waitlistCountText` and `joinedText` don't change, other than `joinedText`
  reading `waitlistEmail`.

### What happens

1. The user types: `updateEmail` emits `email` (ephemeral).
2. They tap Join: `joinWaitlist` emits `sending`, the button shows loading.
3. `remote.joinWaitlist(email)` posts the call. The backend appends to
   `waitlist`, sets `waitlistCount` to 1285 and `waitlistEmail`, and saves.
4. The response is applied: the dialog switches to "You're on the list" and
   the count reads 1,285. `joinWaitlist` emits `idle`.
5. Every other open client gets `waitlistCount: 1285` over SSE and its
   footer updates. The user's other tabs also get `waitlistEmail` and show
   "joined".

## 7. What to build, in order

1. **Compiler:** the five scopes under `state:` in `app.yaml` and
   `app/models/state.yaml`; unique field
   names across scopes; the client and backend `State`/`StateDelta`; remote
   actions in `app/actions/remote/`; the generated `Remote`; two bundles;
   `test_app` running remote calls in-process.
2. **Client state:** `StateBloc` split by scope (ephemeral not saved, local
   as today, remote and shared cached), and the outbox.
3. **Backend (`lib/backend/`, served by Dart Frog in `server/`):** the global state documents, the
   per-app call queue, `/call`, `/state`, `/sync` (SSE), the anonymous id,
   and the file watcher.
4. **Client sync:** SSE connection and reconnect, applying snapshots and
   deltas by version, sending the outbox, remote calls.
5. **Fixture app:** one field of each scope and one remote action, plus
   engine tests.
6. **my_own_app:** the waitlist as in section 6.

## Implementation notes

What was built, and where it differs from the design above.

- **Compiler** (`lib/compiler/`): `stateScopes`, `flattenState` and
  `stateModelsFor` in `models.dart`; `AppProject.scopes`, `remoteActions`,
  `clientModels`/`remoteModels` and the scope checks (`_checkScopes`: no
  `system` read and no `shared`/`system` write from local code; no
  `ephemeral`/`local` in remote actions) in `project.dart`. A flat
  `state:` still works: every field is `local`. Generated per app:
  `state.dart` (client), `remote_state.dart` (backend), `remote.dart`
  (`Remote`), `remote_main.dart`, and `remote_program.evc` when the app has
  remote actions. The backend program holds only the shared helpers the
  remote actions call. The bundle has `scopes`, `backend` and `remote:
  {program, system, fields}`.
- **Remote calls return their error** (`Future<RemoteError?>`), see
  "Calling one". Remote actions still refuse with `throw RemoteError(...)`;
  the engine reads its `code` from the interpreter.
- **Client** (`lib/engine/`): `StateBloc` saves by scope (`state.yaml`,
  `remote.yaml`, `shared.yaml`; never `ephemeral`). `AppRuntime` gives each
  app with `remote`/`shared` state or remote actions a `RemoteBackend`:
  `LocalBackend` without `backend:` (also tests, the editor, the layout
  check), else `HttpBackend` (`lib/engine/sync/`).
  `--dart-define=METACODE_BACKEND=<url>` overrides `backend:` (`none`: no
  backend). `core.modules.reset` keeps a module's `remote` and `shared`
  fields.
- **Ordering**: instead of one version per client, the client keeps the
  version each field was last set at, so a delta that arrives after a
  newer call response (or twice) changes nothing.
- **Backend**: `lib/backend/backend.dart` (`MetacodeBackend`, pure Dart),
  `api.dart` (the HTTP API, framework-free), `handler.dart` (a shelf
  handler, for the engine's tests), `io_backend.dart` (watched folders).
  The server is the Dart Frog project in `server/`:
  `cd server && flutter pub get && dart_frog dev` (port 8080;
  `METACODE_CODE`, default `../examples/my_own_app`; `METACODE_DATA`,
  default `.backend`). Versions start from the clock, so they keep growing
  across restarts. User ids must look like the engine's UUIDs (they name
  files).
- **Not done yet**: `dart_frog build` can't bundle the `path: ..`
  dependency on the Flutter `metacode` package (it copies path
  dependencies into `build/`). Deploying needs the pure-Dart parts
  (`lib/compiler`, `lib/backend`, `lib/files`, the pure engine files) in
  their own package. There's no `PUT /files` and no git webhook: the
  server watches its code folder, so a `git pull` there is the deploy.
  Login is not built (section 3).
- **Tests**: `test/sync_test.dart` (scopes, `LocalBackend`, a real backend
  on localhost with several clients, offline and the outbox, hand-edited
  `shared.yaml`, new code without a restart), `engine_test.dart` (the
  fixture's Vote button), the fixture's own `vote` tests.
