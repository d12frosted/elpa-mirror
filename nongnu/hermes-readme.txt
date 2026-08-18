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
  with `C-u' it always creates another.  `M-x hermes-chat' always opens
  a new chat buffer:
  • `RET' to send.
  • `/' for slash commands.
  • `C-c C-o' for the actions menu.
  • Chats propose the launching buffer's `default-directory' when
    creating a session; the gateway returns the authoritative workspace.
    Use “Set directory” to browse the owning instance and change an idle
    chat's gateway workspace and buffer-local `default-directory'
    together.
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
  already own one.  Chat buffers remain attached to their original
  instance, so chats against different dashboards can stay open at the
  same time.  Browser views retain their chosen instance until
  explicitly reopened for another one.  With zero or one named instance,
  existing single-dashboard behavior is unchanged.


3 Dashboard authentication
══════════════════════════

  `hermes-dashboard-transport-remote-auth-method' defaults to `auto':

  • Loopback dashboards (`127.0.0.1' / `localhost') can spawn or attach
    without extra credentials when the dashboard is not gated.
  • Remote or gated dashboards probe `/api/status' and choose one of the
    supported attach paths below.

  Supported gated attach paths:

  1. *Native PKCE OAuth* — when `/api/status' advertises `native_pkce',
      Emacs opens the system browser, completes the official
      `/auth/native/*' loopback flow, stores access/refresh tokens in
      auth-source under login/port `hermes-dashboard-native',
      authenticates REST with `Authorization: Bearer', and mints a
      short-lived WebSocket ticket. Failed or cancelled login does not
      overwrite prior stored tokens.
  2. *Basic/password* — auth-source entry with port
      `hermes-dashboard-basic', login `username', and password
      secret. Emacs posts password-login cookies and mints a WebSocket
      ticket.
  3. *Legacy session token* — auth-source entry with login/port
      `hermes-dashboard-token' and the token as secret, or environment
      variable `HERMES_DASHBOARD_SESSION_TOKEN'. Used for ungated
      dashboards and forced `token' mode.

  Force a path with:

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
