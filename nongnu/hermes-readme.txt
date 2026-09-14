                             ━━━━━━━━━━━━━━
                              EMACS-HERMES
                             ━━━━━━━━━━━━━━


<https://elpa.nongnu.org/nongnu/hermes.svg>

An Emacs front-end for Hermes Agent, driven over the dashboard/TUI
gateway.

⁃ `M-x hermes' dashboard with `keymap-popup' actions
⁃ ERC/emacs-jabber-style chat buffer with streaming replies
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
  • `M-x hermes-close' closes local connections and Hermes buffers for
    restart.

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


2.1 Headless prompts
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
  best effort and does not delete backend history.  The profile controls
  tools and instructions; choose a tool-less profile for evaluation that
  must not act on the host.


2.2 Output previews
───────────────────

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


2.3 Live tasks
──────────────

  Use /Workspace → Live tasks/ in the chat actions menu, or `M-x
  hermes-chat-show-todos', to open the session-owned checklist.  It
  follows backend task snapshots without changing the chat draft or
  moving focus.  The panel is read-only: pending tasks stay pending when
  a turn ends, with settled or stale labels rather than invented
  completion.  Backends without a restored task snapshot can still
  populate the panel from live tool results.


2.4 Session pins and named workspaces
─────────────────────────────────────

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


3 Dashboard authentication
══════════════════════════

  `hermes-dashboard-transport-remote-auth-method' defaults to `auto':

  • Loopback dashboards (`127.0.0.1' / `localhost') can spawn or attach
    without extra credentials when the dashboard is not gated.
  • Remote or gated dashboards probe `/api/status'.  Auto mode uses
    valid stored basic credentials first, otherwise native PKCE when
    advertised, and finally reports missing basic credentials for a
    basic-only dashboard.

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


4 Optional Emacs bridges
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
