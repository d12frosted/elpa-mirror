                             ━━━━━━━━━━━━━━
                              EMACS-HERMES
                             ━━━━━━━━━━━━━━


<https://elpa.nongnu.org/nongnu/hermes.svg>

An Emacs front-end for Hermes Agent, driven over the dashboard/TUI
gateway.

⁃ `M-x hermes' dashboard with `keymap-popup' actions
⁃ ERC/emacs-jabber-style chat buffer with streaming replies
⁃ Completed paragraphs, closed code fences and complete pipe-table rows
  render while replies stream; unfinished fragments stay literal.  The
  regular timer is throttled by `hermes-chat-stream-format-delay'
  (default 0.1 seconds), so typing does not postpone formatting until
  idle.  Streaming tables use compact content-aware columns and reflow
  with the narrowest displaying window; stable-width single-grid rows
  append without repainting completed output.  Very narrow column panels
  repaint only the active table, reusing fontified rows to keep values
  with their headers; this layout work grows with table size.  Final
  completion uses the full formatter, including source-copy buttons,
  images and diff links.  Formatting does not change the backend-owned
  Running state or retained source.
⁃ Slash commands, approvals, clarify/sudo/secret prompts, interrupts,
  and steering
⁃ Markdown-rendered replies; diffs open as `[View Diff]' in `diff-mode'
⁃ *Kanban*, sessions, profiles, MCP, cron, inventory, and rollback
   browsers
⁃ Configurable desktop notifications with click-to-open actions
⁃ Provider onboarding (API keys and provider accounts) from Emacs
⁃ /Optional/ local eval endpoint (`hermes-exec') for the Hermes Emacs
  MCP bridge


1 Installation
══════════════

  Hermes Agent with dashboard/TUI gateway support is required.
  • See the [Hermes Agent quickstart] for installation and initial
    setup.


[Hermes Agent quickstart]
<https://hermes-agent.nousresearch.com/docs/getting-started/quickstart>

1.1 NonGNU ELPA
───────────────

  `hermes' is available via [NonGNU ELPA].

  Install it with `M-x package-install RET hermes'.


[NonGNU ELPA] <https://elpa.nongnu.org/nongnu/hermes.html>


1.2 package-vc (Emacs 30+)
──────────────────────────

  ┌────
  │ (use-package hermes
  │   :vc (:url "https://git.thanosapollo.org/emacs-hermes" :lisp-dir "lisp")
  │   :custom (hermes-dashboard-transport-url "http://127.0.0.1:9119"))
  └────


2 Usage
═══════

  `M-x hermes' opens the dashboard.  `M-x hermes-project-chat' switches
  to a live chat for the current project or creates one at its root;
  with `C-u' it always creates another.  Project-chat names stay
  anchored to that launching project while the header reports the
  gateway working directory.  Customize
  `hermes-chat-buffer-name-function' to replace the default complete
  naming convention.  A direct or resumed remote chat uses the editor
  directory in its initial buffer name while its gateway cwd is unknown.
  Its header stays detached, and the editor path is not sent to the
  gateway.  `M-x hermes-chat' always opens a new chat buffer:
  • `RET' to send.
  • `/' for slash commands.
  • `C-c C-o' for the actions menu.
  • Each chat pins its resolved spawned or remote transport mode.  A
    spawned chat starts from the editor's `default-directory'; a remote
    chat does not.
  • Passive gateway cwd updates change the header and a direct chat's
    buffer name, but leave `default-directory' alone.
  • “Set directory” browses or accepts a path in the gateway's
    namespace.  On success, the backend-returned path becomes both the
    gateway cwd and the buffer's `default-directory'; a project chat
    keeps its launch-root name.
  • `C-c C-o M m' (or bare `/model') fetches model choices from the
    owning dashboard each time.  `/model' argument completion stays
    cached and nonblocking; opening the picker refreshes that cache
    after backend changes.  The profile browser's model picker also
    fetches fresh choices each time.  Failed fetches do not offer stale
    cached choices.  The dashboard may maintain its own provider
    catalogue cache.
  • `M-x hermes-close' closes local connections and Hermes buffers for
    restart, discarding the frontend model catalogue cache.
    Reconnecting alone retains completion data; the picker still fetches
    anew.

  Hermes commands declare their buffer contexts for native `M-x'
  completion.  To filter completion candidates by context, set
  `read-extended-command-predicate' to
  `command-completion-default-include-p'.  Hermes leaves this user
  option unchanged; with `nil', all commands remain listed.  Dashboard,
  chat, browser-opening and setup entry points stay available globally.
  Context filtering does not change key bindings or prevent direct
  invocation; commands retain their existing runtime checks.

  Point `hermes-dashboard-transport-url' at your running dashboard:

  ┌────
  │ hermes dashboard --no-open --tui --host 127.0.0.1 --port 9119
  └────

  To use more than one dashboard, configure named instances:

  ┌────
  │ (setq hermes-instances
  │       '(("local" . "http://127.0.0.1:9119")
  │         ("remote" . "https://dashboard.example.org")))
  └────

  Commands prompt for an instance only when the current buffer does not
  already own one.  Chat buffers retain their original instance and
  resolved transport mode, so later configuration changes cannot reroute
  them.  Chats against different dashboards can stay open at the same
  time.  Browser views retain their chosen instance until explicitly
  reopened for another one.


2.1 Kanban task bodies
──────────────────────

  Use `E' in a Kanban board or task detail to open the selected task's
  body in an independent multiline draft.  `C-c C-c' saves only the body
  and reads the same task back; `C-c C-k' discards the draft.  Empty
  bodies and Unicode are preserved.  Saving uses the backend's
  last-write-wins behavior and can overwrite concurrent body edits; it
  does not resend title, status or assignee fields.

  The draft retains its original board, task and backend.  Changing or
  closing that source view retires save authority; copy the retained
  draft into a newly opened editor if needed.  Failed or unverified
  saves retain the text and are never automatically retried.  Check the
  board before manually retrying an uncertain update.  A deleted task is
  not recreated.

  Task details display literal Markdown with guarded
  programming-language highlighting.  Fence labels cannot select
  arbitrary minor or global modes; copying preserves markup, and outline
  navigation remains available.


2.2 Agent plugins
─────────────────

  `M-x hermes-list-plugins' opens the installed agent-plugin inventory.
  Use `C' for the curated catalog, `RET' for details, `a' to install the
  selected catalog entry, and `I' to return to installed plugins.  The
  existing `i' command still accepts a plugin identifier or Git URL.

  Details show repository, subdirectory, tier, full catalog pin,
  declared tools/hooks/middleware, environment requirements, and
  supported platforms.  Tier describes provenance, not a safety
  guarantee.  Installation can install dependencies and run code on the
  backend.  It targets that dashboard's launch-profile home, not a
  profile selected in another view or chat.

  Catalog installation resolves the entry again on the backend.  The
  displayed pin is informational: Hermes Agent 0.21.4 does not honor
  `ref' for catalog installs, so Emacs does not send an override.  Check
  the returned `Installed SHA' in details after installation.  Emacs
  reads back both the catalog and installed inventory; it does not force
  replacement or automatically enable the plugin.  Existing enablement
  can persist.  Configured state is not proof of runtime activation.

  If Update reports that new capabilities need consent, the Plugins
  header shows `Awaiting capability consent'.  `RET' displays an inert
  handoff with the candidate SHA and declared additions.  The receipt
  reports that the update was not applied.  Emacs sends no consent
  retry: review the fresh candidate using the backend's native workflow,
  or leave the review to decline.  Use `g' to refresh explicitly; a
  refresh never replays the update.


2.3 Named custom endpoints
──────────────────────────

  `M-x hermes-endpoints' lists named endpoints on the owning dashboard.
  It retains the profile of a chat or onboarding view; other origins use
  the dashboard's launch profile.  Use `c' for a new draft or `RET' to
  edit a saved row, then `e' to edit individual fields and `k' to choose
  Preserve, Replace or Clear for the API key.  Keys use masked input,
  never minibuffer history or list text.  Preserve omits the key from
  Save; only Clear sends an empty key.  Stored keys are not fetched.
  Replace refuses values that would become empty under Hermes Agent
  0.21.4 storage: boundary whitespace is stripped, then CR/LF and
  non-ASCII characters are removed.  Refusal retains the previous key
  policy and draft.  Accepted keys are sent literally, but backend
  storage can still change them; saved metadata is not proof of a usable
  credential or successful authentication.

  In a draft, `t' requests explicit consent before Test.  The dashboard
  sends the entered credential to the destination, may probe alternate
  `/v1' paths, and may perform chargeable inference: one output token
  for Chat Completions or Messages, or up to 16 for Responses.  Test
  neither saves nor activates.  Its observations are not proof of
  successful inference or authentication: the transport check accepts
  401/429 responses and inconclusive timeouts.  The resolved URL is
  shown without changing the draft; `u' explicitly adopts it and the
  advertised model metadata.

  `s' confirms Save with `make_default:false'.  This is last-write-wins
  upsert, not an atomic edit: it can recreate a concurrently deleted
  endpoint.  The backend merges unknown settings and existing model
  metadata.  Unedited API mode and context length are omitted to
  preserve them; model discovery is sent explicitly.  Editing an
  already-active provider can affect future runtime use even without
  Activate.  Inspect the saved list and active model configuration read
  back below the retained draft; backend normalization can change names,
  URLs, IDs and model aliases.

  Back in the list, `a' separately confirms Activate; `d' confirms
  Delete and possible detachment of the active provider's URL and
  credentials.  `g' reconciles state, including after a failed or
  uncertain write; writes are never automatically retried.  `?' shows
  actions in either view.

  Legacy/direct-config rows remain read-only.  Stored IDs such as
  `has.dot', `-edge' and `edge_' support Activate/Delete and are sent
  unchanged.  Hermes Agent 0.21.4 can leave the active-model mirror
  attached for IDs containing ASCII spaces (for example `Mixed
  endpoint') or beginning with `custom:' (case-insensitive).  Boundary
  whitespace can select a different stored key; slash-containing IDs and
  the whole IDs `.' and `..' are not addressable by this route.
  Activate/Delete refuse those hazards before confirmation.  The client
  does not rename IDs or repair backend configuration silently.


2.4 Gateway restart handoff
───────────────────────────

  `H' in Configuration, Agent plugins, Messaging, or Status/Logs opens
  `hermes-system-restart-handoff'.  It is also in the dashboard's System
  menu.  The handoff retains the selected backend and explains the
  external operator action; it does not save, restart, run a shell
  command, or replay a configuration write.

  Saved-value readback and runtime adoption are separate.  Adoption and
  actual service/profile impact remain unverified: a named profile may
  share a multiplexer with other profiles and active sessions.  Open the
  displayed dashboard URL separately and use its gateway controls, or
  ask that backend's operator to identify the service and arrange a safe
  restart.

  The handoff's `s' (Status) and `l' (Logs) open read-only observations
  for the captured endpoint.  After external action, `g' explicitly
  refreshes them; reported fields are not proof of a scoped restart or
  configuration adoption.  If the originating view or handoff is
  replaced or retargeted, reopen the handoff rather than using its stale
  actions.  Observation actions attach to the captured URL; they never
  auto-start a local service, even for loopback addresses.


2.5 Foreign histories
─────────────────────

  In Sessions, `F' opens the serving backend's Claude Code and Codex
  histories.  Choose the destination profile and source.  This does not
  scan the Emacs host.  `>' requests the next page, including after an
  unreadable-only page.  `RET' opens an inert tail preview, bounded by
  the backend to 40 turns and 8000 characters per turn; backend
  directory labels are not local links.

  Previewing never imports.  `i' asks for confirmation before importing
  into the displayed destination.  Only after the returned stored
  session is read back from that profile does `RET' offer native resume.
  Preview refresh and canceling another import confirmation preserve
  that verified session; changing the preview's backend, destination or
  history does not.  If the legacy default backend URL changes, reopen
  from Sessions before previewing or importing again.  Once resume opens
  a chat, acquisition and reconnect retain that chat's selected backend,
  even if a mode or display hook changes the legacy default URL.  An
  interrupted import can have an uncertain outcome: use `g' to inspect
  before explicitly retrying.  There is no automatic import retry.


2.6 Context budget
──────────────────

  From a connected chat, `C-c C-o X b' (or `M-x hermes-chat-context')
  opens an on-demand context snapshot for that exact runtime session.
  `g' explicitly refreshes it; there is no polling.  Computing a
  snapshot can rebuild backend prompt blocks and invoke memory hooks,
  even when computation fails.

  The view keeps backend category estimates separate from reported usage
  and its source.  Unbuilt categories and missing file information
  remain unknown, not zero-cost claims.  Context-file paths are inert
  backend labels; they are not visited on the Emacs host.


2.7 Local dictation and read-aloud
──────────────────────────────────

  `C-c C-o A' opens local audio actions in an attached chat: `r'
  records, `s' stops and transcribes, `c' cancels, and `a' reads a
  chosen settled assistant reply aloud.  Nothing listens or plays
  automatically.

  Configure `hermes-audio-recorder-command' and
  `hermes-audio-player-command' with trusted local foreground programs.
  Both default to `nil'; chat works without them.  The recorder must
  write audio to stdout and finalize on SIGINT.  The player receives a
  private local file in place of its `%f' argument.  For example, with
  ALSA and ffplay installed on the Emacs machine:

  ┌────
  │ (setq hermes-audio-recorder-command
  │       '("arecord" "-q" "-t" "wav" "-f" "S16_LE" "-r" "16000")
  │       hermes-audio-recording-mime-type "audio/wav"
  │       hermes-audio-player-command
  │       '("ffplay" "-nodisp" "-autoexit" "-loglevel" "quiet" "%f"))
  └────

  Recording and read-aloud ask consent and identify the backend and
  profile.  Devices belong to the Emacs machine, even with a remote
  dashboard.  Audio bytes, not local paths, go to that chat's backend
  transcription relay.  The result is a draft, never an automatic
  message.  If you edit the draft while waiting, the transcript opens
  separately for manual copying.  Silence leaves the draft unchanged.
  Read-aloud uploads only the reply you choose and plays the returned
  bytes locally; it does not retrieve provider credentials.

  The defaults allow 8 MiB and 120 seconds per recording or playback.
  WAV, FLAC, Ogg, MPEG and WebM are supported; the recorder's MIME must
  match its output and the player must support the returned format.  A
  time limit cancels rather than uploads.  Stop gives the recorder two
  seconds to finalize.  Cancellation or chat retirement stops owned
  local processes, removes private playback files and ignores late
  replies.  It cannot revoke an upload or cancel a provider request
  already running.  Limits need Emacs event-loop progress; response size
  is checked only after HTTP retrieval.  Audio captures an absolute,
  local `temporary-file-directory' before consent.  Later changes to
  that option cannot redirect recording or playback.  Handler-managed
  scratch is refused, including when a file-name handler appears while
  waiting.  Backend audio providers must be configured separately.
  These relays require Hermes Agent 0.21.4 or a compatible API.


2.8 Browser-vault prompts
─────────────────────────

  Hermes Agent 0.21.4 browser-vault requests use native minibuffers:
  masked password-manager unlock, save-login password and verification
  code readers, plus an identifier reader without input history.  Use
  `C-c C-a' to answer a pending request.  Each reader shows the owning
  backend endpoint and the site/origin or password manager supplied by
  that backend.  Empty password/code or `C-g' declines a current
  request; expired or disconnected requests cannot send or recover an
  answer.

  Credentials go directly to the original backend request, never to chat
  input.  The backend owns origin verification, credential storage and
  browser filling; Emacs does not run a local password manager or
  control its local browser.  Minibuffer input, including indirect
  aliases sharing its text, is excluded from capability listings and
  reads even when the optional buffer-denial policy is disabled.  Native
  kill/copy operations use a private kill ring and yank menu.  Expiry
  revokes response authority immediately; an unrelated nested reader or
  recursive edit can finish before the expired vault reader is
  dismissed.  This is not memory zeroization or a sandbox against
  trusted Emacs Lisp.  Card/address collection is unsupported.


2.9 Headless prompts
────────────────────

  `(hermes-request REQUEST RESOLVE REJECT)' returns a cancellation
  thunk.  Require `hermes-request' for use without the UI.  For example:

  ┌────
  │ (hermes-request '(:prompt "Explain spaced repetition." :profile "study-eval")
  │                 (lambda (text) (message "%s" text))
  │                 (lambda (reason) (message "Request failed: %s" reason)))
  └────

  The profile must exist in the selected backend catalogue with a
  configured model and provider.  Each request captures those exact
  choices from a fresh catalogue read, overriding backend launch
  defaults without changing profile configuration.  Missing or malformed
  choices fail before session creation; credentials and any configured
  fallback policy remain backend-owned.  Each call creates a fresh
  hidden session; no current chat history is used.  Only a successfully
  completed final response reaches `RESOLVE'; cancellation, timeout,
  disconnect, or required interaction reaches `REJECT'.
  `hermes-request-timeout' bounds the request.  Closing the session is
  best effort and does not delete backend history.  A fresh session and
  profile/model selection isolate conversation context, not tools or
  filesystem access.  This client does not verify the agent's effective
  tool set; an empty configured tool selection is not a no-tools
  guarantee on the supported gateway.  For evaluation that must not
  affect the host, use an independently isolated backend.  Profile
  configuration alone is not a sandbox.


2.10 Local text/source attachments
──────────────────────────────────

  Use /Compose → Attachments → Upload text\/source/ or `M-x
  hermes-chat-attach-file' in an already connected, attached chat.  This
  separate action leaves image attachment and path completion unchanged.
  It accepts up to 2 MiB of local UTF-8 text/source with a supported
  suffix; PDF extraction and arbitrary binary files are unsupported.
  Local reads are bounded; the underlying HTTP response retrieval is not
  streaming-bounded.

  The command captures the owning session's gateway-host working
  directory, requires managed Files policy admission, and asks before
  attempting a write there.  Upload checks write permission.  This does
  not establish equivalence with a remote terminal backend.  A generated
  filename reduces collisions but `overwrite:false' is a non-atomic
  backend precheck, not exclusive creation.  Exact byte readback
  precedes the owning session's `file.attach(path)' call.  Only its
  validated reference is appended to an unchanged composer; nothing is
  sent.  Paths refer to current content and can change before a later
  Send.

  A native recovery view retains the original literal draft, bounded
  bytes and any returned reference.  Oversized files retain only an
  explicitly labelled incomplete prefix of 2 MiB plus one byte; the
  unread tail is not recovered.  Newer draft edits, cancellation,
  ownership changes and uncertain failures never replace text, retry an
  upload, or delete a remote file.  Use `s' in recovery to save exact
  bytes to a *new* local file, then copy a reference manually if
  appropriate.  /Attachments → Reopen retained recovery/ opens retained
  data afresh without repainting a view reused for notes.  Data is
  retained in memory only: save it before closing recovery views or
  Emacs.  At most eight live recovery views are retained per chat.
  Uploaded files may remain after failure or cancellation; cleanup is a
  separate explicit action.


2.11 Output previews
────────────────────

  Completed tool outputs with published file paths, and closed HTML/SVG
  code blocks in assistant replies, offer `[Preview]' buttons.  The chat
  actions menu also provides /Workspace → Preview output/.  Previewing
  never reads a backend path from the local filesystem: it requests
  current bytes from the owning chat's managed-files API, with a 4 MiB
  limit.  The server's file policy may refuse paths outside its managed
  root.  Failed reads offer retry and copy-target commands; remote URLs
  are copyable but never fetched automatically.

  Previews are inert.  HTML loses scripts, links, forms, attributes and
  external resources; SVG renders only an explicitly supported passive
  subset.  Use `v' to switch to retained source, `s' to save the exact
  bytes to a *new* local file, `g' to retry, `y' to copy the target, and
  `q' to quit.  Raster display depends on Emacs image support;
  unavailable previews retain source or binary metadata and the save
  action.  For rendered raster images and passive SVG, `+' and `-' zoom
  between 10% and 400% of the initial displayed size; `0' restores that
  size.  Zoom requires native image scaling and never fetches or changes
  saved bytes.  Source toggling and zoom wait for a pending read; use
  `C-g' to cancel it first.  File paths refer to current content, not
  historical versions: the backend does not publish reliable artifact
  revisions.


2.12 Skills: installed content and Hub previews
───────────────────────────────────────────────

  In the Skills inventory, `RET' or `f' opens the selected skill's
  `SKILL.md' from that backend's launch profile.  The text is read-only
  until `C-c C-e' (Edit).  Use `C-c C-c' to save, `C-c C-k' to discard
  local edits, and `C-c C-h' for help.  Save replaces the whole
  document: it can overwrite concurrent changes.  A matching backend
  readback confirms the save; errors, validation refusals and uncertain
  outcomes leave your draft intact.  Nothing retries a write
  automatically.  `C-c C-g' reads again after local edits have been
  saved or discarded.  Backend paths are labels, not local file targets.
  These controls do not create skills or edit supporting files, and
  saving does not claim to activate changes in a running session.

  `H' in inventory, or `M-x hermes-skills-hub', opens the separate
  optional Skill Hub.  Use `n/p' to move, `f' or `RET' to preview, `b'
  to return, `s' to search configured sources, `S' to inspect source
  availability, and `P' to choose a backend profile.  Rows retain their
  source and identifier, even when names match.  Search is bounded;
  timed-out sources are reported as partial results.  Preview shows
  inert `SKILL.md' text and supporting file names only—not a review of
  those files.

  In a preview, `S' requests a scan only after confirmation.  Scanning
  can fetch and quarantine files on the backend and run an optional
  external scanner.  Allow, ask and block are policy results, not safety
  guarantees; an absent or failed advisory scan is not a pass.  Browsing
  and previewing never install, enable or execute a skill.  These views
  require backend REST support and have no local command fallback.


2.13 Live tasks
───────────────

  Use /Workspace → Live tasks/ in the chat actions menu, or `M-x
  hermes-chat-show-todos', to open the session-owned checklist.  It
  follows backend task snapshots without changing the chat draft or
  moving focus.  The panel is read-only: pending tasks stay pending when
  a turn ends, with settled or stale labels rather than invented
  completion.  Backends without a restored task snapshot can still
  populate the panel from live tool results.


2.14 Conversation commands and file references
──────────────────────────────────────────────

  `/btw QUESTION' asks a side question over the current conversation
  without changing its main history.  `/bg TASK' (also `/background')
  instead starts an independent background task.  Both deliver
  persistent result links while the main turn can continue.  A rejected
  or uncertain side question is retained in a separate `*Hermes side
  question*' buffer, never in the send queue.  Inspect results before
  manually copying it into a new `/btw' command; recovery does not retry
  the question or replace a newer draft.

  `/branch [NAME]' branches the attached, idle conversation through the
  backend and opens the child with its history in a separate chat.  The
  parent and its draft remain available.  If a branch fails after
  backend creation, the child may still exist; inspect Sessions before
  retrying.

  Composer `@' completion reads the attached session's backend
  workspace, not Emacs's local project.  Try `@src/mo', `@file:src/mo'
  or `@folder:src' and invoke completion again after the asynchronous
  lookup finishes.  Accepted candidates become explicit, quoted backend
  references.  Paths that cannot be represented by the backend parser
  are not offered.  This is reference completion, not a local-file
  upload; literal bare `@path' text does not attach file contents.

  New remote chats with no selected directory inherit the selected
  profile's backend workspace.  Emacs records the returned directory
  without changing its own `default-directory'.  Deliberately selected
  directories remain explicit.


2.15 Session pins and named workspaces
──────────────────────────────────────

  In `M-x hermes-list-sessions', `k' toggles the selected session's
  server pin.  If the pin is unknown, the first press reads it without
  changing it.  The same action is available in session details; `M-x
  hermes-sessions-pin' and `M-x hermes-sessions-unpin' set it
  explicitly.  Emacs reads the stored session back after each change.  A
  failed read leaves the pin unknown.  Use `l' for a profile's stored
  catalogue and `>' to load its next window.

  `M-x hermes-list-projects' opens the backend's named, multi-folder
  workspaces in that dashboard's launch profile, also available from the
  dashboard and command palette.  Use `RET' for details, `P' to change
  backend profile, and `?' for create, rename, archive/restore, folder,
  and active-project actions.  Explicit profile names must match that
  backend's current profile catalogue exactly; unavailable catalogues
  block those scoped requests.  This preflight cannot prevent a profile
  from being deleted on the backend during dispatch.  Folder prompts
  accept backend paths, without local file completion.  Grouped sessions
  come from the backend's bounded subset, not a complete session
  archive.

  Projects are metadata: selecting an active project does not move
  sessions, and deleting a project keeps its directories and sessions.
  Named backend projects are separate from the editor project used by
  `hermes-project-chat'.  To change an attached chat's working
  directory, use its Set directory command.  Stored-session moves are
  unavailable because the backend can confuse live sessions with the
  same stored ID in different profiles.  Older backends without project
  methods show an unsupported status; ordinary session browsing remains
  available.


2.16 Hosted Group Chats
───────────────────────

  `M-x hermes-list-groups' reads rooms hosted by the selected backend.
  The dashboard's Browse menu also offers `H' for Group Chats.  Use
  `RET' or `f' to open a room, `m' for the next list page, and `g' to
  refresh or reconnect.  Public messages show their speakers in sequence
  order; member activity, task counts, and pending approvals appear
  separately.  With a ready hosted driver, `c' creates a room from two
  to six existing profiles on that same backend.  Open the room and use
  `s' to send a literal message in a named thread.  The roster shows
  mention handles; the backend owns mention policy, rounds, member
  sessions and durable work, not Emacs.

  Send acceptance is separate from completed member turns.  If a receipt
  is lost, `R' reconciles the retained submission against the room log
  before offering an explicit retry with the same event ID.  No
  submission or task is retried automatically on reconnect.  Keep the
  view open to retain an uncertain message's recovery identity; closing
  it discards that local copy.

  `a' answers an exact pending approval (once or deny).  `x' requests
  cancellation for this room and reads state back; it does not terminate
  the gateway or claim that every process stopped.  `r' explicitly
  retries a named uncertain task, including work the backend has
  deferred, after warning that the prior execution may have had effects.
  Before offering or answering an approval, Emacs reads complete room
  history and excludes retired tasks and executions, so historical
  failures do not block fresh requests.  Incomplete history, ambiguous
  task authority, or stopping work refuses approval; use `g' to continue
  reading.  State, history and approval are separate backend calls, not
  an atomic transaction with other clients.  Closing the view or Emacs
  only stops local monitoring: backend work can continue.

  The backend must advertise the protocol-2 room-reading methods and
  features.  Driver availability is shown separately: stored history can
  remain readable when the worker is unavailable.  `F' toggles
  five-second activity refresh and keeps its own connection reference,
  even without an open chat.  Turning it off, closing or repurposing the
  view, transport retirement, terminal room state, or three consecutive
  read failures releases that reference.  `g' resumes from the last
  rendered cursor; failed rendering retains the accepted text and
  cursor.  Each refresh reads at most 20 log pages; `g' continues larger
  histories.

  Authority changes restart replay explicitly.  A sequence gap triggers
  a state check, not a skipped range.  Disbanded history stays marked as
  such; expired history is a retained local snapshot, never a revived
  room.  These are gateway-owned rooms, not the desktop's legacy
  localStorage rooms.


3 Bot Chats and routines
════════════════════════

  In `M-x hermes-list-profiles', `RET' opens the selected profile's
  canonical `Bot Chat'.  Emacs looks up that exact title on the selected
  backend, including hidden history and its compression continuation.
  Only confirmed absence offers creation.  A new conversation stays
  hidden and follows profile configuration; its title must be persisted
  and read back before the chat opens.  Failed or contradictory lookup
  never creates another conversation.  Opening sends no introduction,
  though the backend can prewarm the agent and discover MCP tools.

  `N' opens a separate ordinary scratch chat.  Within a canonical Bot
  Chat, `/new' offers compression or explicit scratch creation; it does
  not silently replace the relationship.  Ordinary chats retain their
  existing `/new' behavior.  `m' still edits the profile's default
  model.

  `R' opens that backend/profile's existing cron jobs in the ordinary
  cron editor.  Opening or refreshing Routines only reads jobs.
  Creating, editing, pausing and running a job remain explicit cron
  actions; there is no separate scheduler or automatic Bot Chat delivery
  preset.

  Canonical chats, scratch chats explicitly opened by their `/new'
  command, and Routines retain the backend selected when opened,
  including after reconnect or changes to the default dashboard URL.
  Routines actions and run transcripts stay on that backend.  Reopen
  from Profiles to choose another backend; ordinary chats and the
  all-jobs cron browser keep their existing endpoint-selection policy.


4 Dashboard authentication
══════════════════════════

  `hermes-dashboard-transport-remote-auth-method' defaults to `auto':

  • With `auto' start mode, loopback dashboards spawn without extra
    credentials.
  • With `remote' start mode, an ungated dashboard at `127.0.0.1' can
    supply its session token automatically. Emacs reads the dashboard's
    HTML asynchronously; no shell command or environment change is
    needed.
  • Remote or gated dashboards probe `/api/status'. Auto authentication
    uses valid stored basic credentials first, otherwise native PKCE
    when advertised, and reports missing basic credentials for a
    basic-only dashboard.

  Automatic discovery accepts only `127.0.0.1', never DNS names
  (including `localhost'), other addresses, or redirects. Use
  `127.0.0.1' rather than `localhost' for credential-free
  attach. Explicit token arguments, auth-source entries, and
  `HERMES_DASHBOARD_SESSION_TOKEN' take precedence, in that order.
  Discovered tokens stay in memory for their dashboard
  endpoint. Reconnect reads a fresh token after a backend restart; a
  REST GET rejected with HTTP 401 may retry once. Writes are never
  replayed automatically. Failed basic/native login never falls back to
  discovery.

  Supported gated attach paths:

  1. *Basic/password* — auth-source entry with port
      `hermes-dashboard-basic', login `username', and password
      secret. Emacs posts password-login cookies and mints a WebSocket
      ticket.
  2. *Native PKCE OAuth* — when `/api/status' advertises `native_pkce',
      Emacs opens the system browser, completes the official
      `/auth/native/*' loopback flow, stores access/refresh tokens in
      auth-source under login/port `hermes-dashboard-native',
      authenticates REST with `Authorization: Bearer', and mints a
      short-lived WebSocket ticket. Failed or cancelled login does not
      overwrite prior stored tokens.
  3. *Legacy session token* — auth-source entry with login/port
      `hermes-dashboard-token' and the token as secret, or environment
      variable `HERMES_DASHBOARD_SESSION_TOKEN'. Used for ungated
      dashboards and forced `token' mode.

  Force `native', `basic', or `token' to bypass auto selection:

  ┌────
  │ (setq hermes-dashboard-transport-remote-auth-method 'native) ; or 'basic / 'token / 'auto
  └────

  Generic auth-source examples (replace host/port/values; never commit
  real secrets):

  ┌────
  │ machine https://dashboard.example.org:9119 login hermes-dashboard-native password {"access_token":"…","refresh_token":"…","expires_at":0,"provider":"oauth","user_id":""}
  │ machine https://dashboard.example.org:9119 login admin password s3cret port hermes-dashboard-basic
  │ machine https://dashboard.example.org:9119 login hermes-dashboard-token password SESSIONTOKEN port hermes-dashboard-token
  └────

  If a gated dashboard advertises neither `native_pkce' nor a basic
  provider, Emacs refuses attach with an actionable error. Cookie-only
  browser OAuth without `native_pkce' remains unsupported.


5 Optional Emacs bridges
════════════════════════

  The dashboard/TUI connection above drives chat and management.  Two
  separate, optional paths let Hermes call into Emacs:

  • `hermes-capabilities' is the native dashboard capability-provider
    path.
  • `hermes-exec' is the HTTP eval endpoint used by the external stdio
    MCP bridge, [hermes-emacs-plugin].

  To use the stdio MCP bridge, install it from Git, enable the endpoint,
  then copy its registration command:

  ┌────
  │ pipx install git+https://git.thanosapollo.org/hermes-emacs-plugin
  └────

  ┌────
  │ (require 'hermes-exec)
  │ (setq hermes-exec-enabled t
  │       hermes-exec-host "127.0.0.1"
  │       hermes-exec-require-approval t)
  │ (hermes-exec-start)
  │ ;; M-x hermes-exec-show-bridge-command
  └────

  The generated command registers the packaged `hermes-emacs-mcp' entry
  point.  For a non-loopback private address, also set the same
  `EMACS_EXEC_TOKEN' for Emacs and the bridge.  Do not expose the eval
  endpoint on a public interface.

  Desktop notifications default to completed chat replies, terminal chat
  errors, input requests, background-task results, and Kanban states
  that need attention.  Cron failures use the same policy when cron
  failure monitoring is enabled.  They are suppressed when the target
  buffer is already visible on the focused frame. Customize the event
  set, or set it to `nil' to disable notifications:

  ┌────
  │ (setq hermes-notifications-events
  │       '(chat-reply chat-error prompt background
  │         kanban-attention cron-failure kanban-done))
  └────


[hermes-emacs-plugin] <https://git.thanosapollo.org/hermes-emacs-plugin>
