1 Codex IDE integration for Emacs and Neomacs
═════════════════════════════════════════════

1.1 About
─────────

  ⁃ [codex] native integration for Emacs via [Eat] by default
    ⁃ Run Codex in a project-scoped terminal buffer.
    ⁃ Optionally use [vterm] when it is installed separately.
    ⁃ Resume, switch, cycle, and stop multiple live Codex sessions.
    ⁃ Optional IDE context provider and local Emacs MCP tools bridge.
  ⁃ Requires GNU Emacs 29.1 or newer, or Neomacs with the native APIs
    below.


[codex] <https://github.com/openai/codex>

[Eat] <https://codeberg.org/akib/emacs-eat>

[vterm] <https://github.com/akermu/emacs-libvterm>


1.2 Commands
────────────

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Command                                 Purpose                                                               
  ───────────────────────────────────────────────────────────────────────────────────────────────────────────────
   `M-x codex-ide'                         Start or toggle the active project session (`C-u' starts another)     
   `M-x codex-ide-new-session'             Start another live session for the project                            
   `M-x codex-ide-resume-last'             `codex resume --last'                                                 
   `M-x codex-ide-resume'                  Pick a saved session id, then `codex resume <id>'                     
   `M-x codex-ide-rename-session'          Label a live session; empty input restores automatic naming           
   `M-x codex-ide-stop'                    Stop only the *active* project session                                
   `M-x codex-ide-cycle-session'           Cycle live project sessions                                           
   `M-x codex-ide-toggle-panel'            Hide or restore project session windows in this tab                   
   `M-x codex-ide-show-project-sessions'   Show all project sessions in separate side windows                    
   `M-x codex-ide-switch-project-session'  Switch among project sessions                                         
   `M-x codex-ide-switch-session'          Switch among any live sessions                                        
   `M-x codex-ide-list-sessions'           Browse live sessions in `*Codex Sessions*'                            
   `M-x codex-ide-attach-source'           Attach region or current line to one session draft without submitting 
   `M-x codex-ide-send-prompt'             Send a minibuffer prompt into the active session                      
   `M-x codex-ide-menu'                    Popup menu (sessions, config, MCP, debug)                             
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  The session list shows project, label or buffer, backend, status, and
  directory.  Use `n=/=p' to move, `RET' to switch using the configured
  display policy, `k' to kill the selected session after confirmation,
  `r' to set or clear its label, `g' to refresh while keeping the
  selected row, and `?' for popup help.  The old `codex-ide-toggle' and
  `codex-ide-list-project-sessions' names remain obsolete aliases for
  `codex-ide-cycle-session' and `codex-ide-switch-project-session'.

  The popup groups Session, Switch, Send, Context, and Config in two
  columns.  Use `l' for project session completion, `L' for all-session
  completion, and `B' for the session list.  `q' closes the popup or
  returns from a submenu; `k' kills a session and `K' stops MCP in its
  submenu.  Unavailable actions are dimmed.  Configuration shows current
  backend, approval, and sandbox overrides for new sessions; `CLI
  default' means the CLI chooses that value.  Save configuration
  persists options that differ from their defaults, and removes saved
  overrides for options restored to their defaults.  Explicit terminal
  backend choices are also saved, including Eat, so they retain their
  meaning after restarting Neomacs.


1.3 Saved sessions
──────────────────

  ⁃ `codex-ide-resume-session-scan-limit' limits matching unique
    sessions offered by the picker (default 200), after filtering by
    project.
  ⁃ Resume always creates another live session, preserving existing
    sessions.
  ⁃ Saved sessions are shown newest first, with dates and abbreviated
    paths.  Metadata is cached until a rollout's modification time or
    size changes.
  ⁃ If the project has no saved sessions, the prompt says "all
    projects"; selecting one starts it in its recorded working
    directory.
  ⁃ Metadata lines larger than one MiB produce an explicit error.

  Saved sessions launch in their recorded directory and belong to that
  directory's project root, so project commands include resumed sessions
  from subdirectories.


1.4 Session display and exit
────────────────────────────

  ⁃ `codex-ide-display-buffer-function' and `display-buffer-alist'
    control placement.  Switching selects the session; source attachment
    displays it without selecting.  Existing-window lookup and hiding
    use the selected frame. Hiding restores the window layout where
    possible.
  ⁃ `codex-ide-kill-buffer-on-exit' defaults to `success': clean exits
    with status 0 close the terminal buffer. Failed exits retain
    readable output and an exit notice.  Exiting sessions revoke their
    MCP credentials even when output is retained.  Set it to `nil' to
    retain every exit, or `t' to close on every exit.
  ⁃ Interactive `codex-ide-stop' asks for confirmation. Calls from Lisp
    do not.
  ⁃ The mode line shows the live session label or number and terminal
    backend.
  ⁃ `S-<return>' sends Ctrl+J to insert a literal newline in the Codex
    prompt.  Minibuffer prompts use `codex-ide-prompt-history'.


1.5 Terminal scrolling
──────────────────────

  ⁃ With Eat, `C-c C-e' enters its read-only Emacs mode for ordinary
    scrolling, movement, search, and selection.
  ⁃ With vterm, use `M-x vterm-copy-mode' for transcript navigation.
  ⁃ `C-c C-j' restores terminal input and jumps to the live Codex frame
    with any backend.


1.6 Context provider
────────────────────

  ⁃ With `codex-ide-context-auto-start' non-nil (default), new GNU Emacs
    sessions enable the IDE context IPC automatically.  Neomacs skips
    this legacy `/ide' server autostart; explicit context commands
    remain available.  Optional context startup failures are logged and
    do not prevent Codex startup.
  ⁃ Disable with `(setq codex-ide-context-auto-start nil)'.


1.7 MCP tools
─────────────

  ⁃ Supports stateless MCP `2026-07-28' requests and the `2025-06-18'
    initialization flow for existing clients, on the same endpoint.
  ⁃ Modern clients can discover capabilities with `server/discover' or
    call tools directly, with protocol metadata and matching routing
    headers.
  ⁃ When `codex-ide-mcp-enabled' is non-nil (default), session start
    registers a transient local MCP URL via Codex `-c' overrides. GNU
    sessions authenticate with a private per-session bearer token passed
    only through `CODEX_IDE_MCP_TOKEN' in the terminal
    environment. Requests without the exact token are refused; session
    exit or killing the terminal buffer revokes it.
  ⁃ The bridge can evaluate Elisp, edit buffers, and run shell
    commands. It exposes those control tools by default and only accepts
    loopback bind addresses. Set `codex-ide-mcp-disabled-tools' to a
    list of tool names to hide and refuse them. Tool execution can be
    interrupted with `C-g'.
  ⁃ Commands: `codex-ide-mcp-start', `codex-ide-mcp-stop',
    `codex-ide-mcp-status', `codex-ide-mcp-install-codex-config'.
  ⁃ Structured edits require an explicit `buffer' name or open file
    `path'.  Supplied tool arguments must match their advertised types;
    for example, positions are integers and `indent' is a JSON boolean.
  ⁃ Default port is ephemeral (`codex-ide-mcp-port' 0). GNU persistent
    HTTP installation is refused because it cannot supply session
    credentials; start the session with `M-x codex-ide'. Native Neomacs
    installation is unchanged.
  ⁃ `emacs_context' accepts only already-open file
    paths. `emacs_review_start' can omit `buffer' for an authenticated
    GNU session. `emacs_review_result' returns its complete result,
    including accepted text, in `structuredContent'; its text content is
    a short status message. Read `structuredContent.content' when
    applying the accepted edit.
  ⁃ Disable auto registration with `(setq codex-ide-mcp-enabled nil)'.


1.7.1 Custom tools
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Register tools before starting Codex, and restart sessions after
  catalog changes because clients may cache discovery. Built-in tools
  cannot be replaced or removed.  Handlers receive positional arguments
  in schema order and return a JSON-encodable value as MCP text
  content. Omitted optional arguments become `nil'; JSON booleans are
  `t' and `:json-false'. Supported types: `string', `integer', `number',
  `boolean'.  Handlers run synchronously and must return promptly.

  ┌────
  │ (require 'codex-ide-mcp-tools)
  │ (codex-ide-mcp-register-tool
  │  "greet" "Return a greeting."
  │  '((:name "name" :type string :description "Name to greet."))
  │  (lambda (name) (concat "Hello, " name)))
  │ ;; Remove with (codex-ide-mcp-unregister-tool "greet").
  └────


1.8 Ediff review
────────────────

  `codex-ide-diff-review' takes old text, proposed text, a path label,
  and a callback.  It returns immediately with an owner for
  `codex-ide-diff-cancel'.  Edit the proposed buffer, then use `C-c C-a'
  in the Ediff control buffer to accept, or `q' to reject.  The callback
  receives `(accepted final-text)', `(rejected nil)', or `(cancelled
  nil)'.  Only one review can be active.

  Review never changes the target file or its visiting buffer.  The
  caller owns applying accepted text.  `codex-ide-diff-preview' remains
  a synchronous programmatic boolean preview with both buffers
  read-only.  Proposal buffers use the target file's major mode with
  core syntax and fontification setup, without user mode hooks or
  file-local settings. A header shows the project-relative target and
  current accept, reject, and help keys.

  Codex can call `emacs_review_start' with `buffer' (the live terminal
  name), `token' (a unique retry token), `path', `old', and `new'.  It
  receives a `review_id' promptly.  The proposal always waits for `M-x
  codex-ide-diff-show', even when the owning session is selected.  A
  message and a warning-faced mode-line indicator announce the pending
  review; notification timers never change the selected frame, tab, or
  window.  The command opens the review in the frame and tab where it is
  invoked, after minibuffer input has finished.  `emacs_review_result'
  retrieves the decision on a new connection, optionally with
  `cancel=true'.  Disconnecting HTTP does not cancel a review.
  Identical owner/token retries return the same ID; changed input with
  that token is rejected.  These arguments route the proposal to a
  session; they are not an authentication boundary.

  Apply only the accepted `content', after checking that the original
  base has not changed.  Changed bases require another review.  The
  tools do not intercept or enforce approval of other file writes.  One
  review may be queued or open, with at most 16 retained receipts and
  one MiB of combined UTF-8 input text.  Pending reviews expire after 30
  minutes; final results remain available for another 30 minutes.
  Session or server shutdown cancels pending UI while retaining results
  until that retention expires.


1.9 Context and debug output
────────────────────────────

  The `/ide' context provider remembers source buffers across both
  window and same-window buffer changes.  It collects at most 100 open
  tabs by default and bounds selection text before copying it.  Native
  JSON is used when available, with the same wire format as the json.el
  fallback.

  `codex-ide-send-selection' broadcasts context for the project root.  A
  broadcast does not mean the Codex TUI consumed the selection; invoke
  `/ide' there to request context.  With no connected client, the
  command keeps its selection-copy fallback.

  Debug output uses a read-only `special-mode' buffer.
  `codex-ide-debug-max-size' limits retained text to 262144 characters
  by default.  `codex-ide-clear-debug' clears it.


1.10 Useful knobs
─────────────────

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Variable                         Default intent                                                 
  ─────────────────────────────────────────────────────────────────────────────────────────────────
   `codex-ide-cli-path'             Codex executable                                               
   `codex-ide-terminal-backend'     GNU Emacs: `eat'; Neomacs: native unless explicitly customized 
   `codex-ide-ask-for-approval'     Optional `--ask-for-approval' policy                           
   `codex-ide-cli-extra-args'       Extra CLI args                                                 
   `codex-ide-no-alt-screen'        Inline TUI mode                                                
   `codex-ide-yolo'                 Full control without approvals or sandbox                      
   `codex-ide-mcp-enabled'          Auto-register local MCP bridge                                 
   `codex-ide-mcp-port'             GNU MCP: 0 = ephemeral port                                    
   `codex-ide-neomacs-mcp-command'  Native `neomacs-mcp' stdio relay executable                    
   `codex-ide-context-auto-start'   Auto-start context IPC                                         
   `codex-ide-debug'                Debug logging                                                  
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Menu *Save configuration* persists the documented symbol set only
  (CLI/terminal/display/approval/YOLO/no-alt-screen/extra-args/config-overrides/
  debug/MCP host-port-enable/context-auto-start).


1.11 Optional vterm backend
───────────────────────────

  Install vterm separately, then select it for new sessions:
  ┌────
  │ (use-package vterm
  │   :ensure t)
  │ 
  │ (setq codex-ide-terminal-backend 'vterm)
  └────

  Eat is the GNU Emacs default and a package dependency, so installing
  codex-ide also installs Eat 0.9.4 or newer from NonGNU ELPA.  It is
  loaded only when an Eat session starts.  Changing the option does not
  alter already running sessions.


1.12 Native Neomacs support
───────────────────────────

  When `(featurep 'neomacs)' is non-nil, an uncustomized `eat' default
  selects `neo-term' for new sessions. This also works when upgrading an
  already-loaded copy: the option itself is not overwritten, and
  existing sessions keep their backend. `setq' to the historical `eat'
  default is treated as automatic in Neomacs. Use Customize or
  `(customize-set-variable 'codex-ide-terminal-backend 'eat)' to
  explicitly retain Eat there. Explicit `vterm' and `neo-term'
  selections are respected.

  The native backend requires `neo-term-exec', `neomacs-terminal-spawn',
  `neo-term-settled-functions' and
  `neo-term-create-failed-functions'. Older Neomacs builds without the
  exact-command API are not supported. It launches Codex with exact
  argv, cwd and environment, without a shell script. Input, resizing and
  teardown use the native terminal API, not an Emacs pipe process.
  Prompts and source attachments remain literal UTF-8 bracketed pastes;
  Return and Escape are separate key bytes. Native terminal exits,
  creation failures, buffer kills and mode changes remove only the
  owning session.

  With MCP enabled, start Neomacs' owner-controlled endpoint using `M-x
  neomacs-mcp-start' and an explicit private socket location. Codex IDE
  reads that active listener's actual socket and registers the native
  `neomacs-mcp' stdio relay transiently under `mcp_servers.neomacs'. The
  native editor and companion libraries supply the native catalog,
  including unrestricted owner evaluation; Codex IDE does not substitute
  GNU `emacs_tools', hide native tools or add an evaluation
  restriction. Native tools are exposed in Codex's `mcp__neomacs'
  namespace, for example `mcp__neomacs__neomacs_identity'.

  Before native session launch, Codex IDE asks `codex mcp list --json'
  to inspect effective configuration in the session's working directory,
  including `codex-ide-config-overrides'. An inherited `emacs_tools'
  entry is disabled for that session only, unless
  `codex-ide-config-overrides' explicitly sets
  `mcp_servers.emacs_tools.enabled' to `true' or `false'. An explicit
  `true' deliberately retains the GNU bridge alongside native MCP. Other
  server entries are left alone. Native stdio `enabled', `enabled_tools'
  and `disabled_tools' policy remains inherited; registration does not
  enable a disabled native server or widen its tool policy.  Codex
  0.155.1 recursively merges even whole-table `-c' overrides, so an
  existing HTTP transport under `mcp_servers.neomacs' cannot be safely
  replaced that way.  Launch refuses that conflict before opening a
  terminal, with instructions to rename the conflicting entry,
  explicitly replace it with stdio, or disable automatic MCP
  registration. Inspection failures also refuse launch rather than
  guessing the effective configuration. No persistent entry is
  rewritten.

  Native automatic MCP registration refuses `-p=/'–profile=,
  `-c=/'–config=, `-C=/'–cd= and remote-route options (`--remote',
  `--remote-auth-token-env') in `codex-ide-cli-extra-args', including
  joined short and `--option=value' forms, before creating a
  terminal. Those options can select uninspected config layers, override
  the inspected settings later, or bypass the local server.  Put
  equivalent session settings in `codex-ide-config-overrides' and select
  the project directory in Emacs. To use these CLI options directly,
  disable `codex-ide-mcp-enabled' and manage MCP yourself. GNU sessions
  and native sessions without automatic MCP retain the verbatim
  extra-argument escape hatch.

  The relay must be available on Emacs' `exec-path'. If necessary,
  customize `codex-ide-neomacs-mcp-command' to its absolute executable
  filename. Missing native libraries, listener or relay fail explicitly
  rather than silently starting GNU MCP. `codex-ide-mcp-start' verifies
  the native endpoint and `codex-ide-mcp-status' reports its socket and
  catalog. `codex-ide-mcp-stop' refuses to stop the shared native
  listener; use `neomacs-mcp-stop' explicitly if that is
  intended. Disable session registration with `(setq
  codex-ide-mcp-enabled nil)'. No Codex configuration file is written
  except by the existing confirmed `codex-ide-mcp-install-codex-config'
  command.  Persistent native setup targets that exact socket and must
  be updated if it moves. Its confirmation warns that `codex mcp add
  neomacs' can replace an existing entry and discard `enabled',
  `enabled_tools' and `disabled_tools' policy. Inspect and restore those
  restrictions after deliberate installation.  GNU HTTP host/port and
  custom tool registration apply only to GNU MCP.


1.13 Development checks
───────────────────────

  `make dev' runs warning-fatal source compilation, checkdoc,
  package-lint and all ERT suites through the Nix development
  shell. Eat/vterm PTY tests run locally; sandbox checks may skip PTY
  tests. `make load' is live activation, not a read-only check.

  The opt-in config-merge suite exercises the installed Codex CLI
  against disposable configuration, checks that the fixture bytes remain
  unchanged, and never contacts an editor endpoint. To include it in GNU
  and native checks, set `CODEX_IDE_TEST_CODEX' to the absolute
  installed Codex executable (not a shim whose resolution depends on
  HOME). Without that variable those four tests are explicitly
  skipped. For example:
  ┌────
  │ CODEX_IDE_TEST_CODEX="$CODEX" make dev
  │ CODEX_IDE_TEST_CODEX="$CODEX" make neomacs-check NEOMACS="$NEOMACS" \
  │   COMPAT="$COMPAT" KEYMAP_POPUP="$KEYMAP_POPUP"
  └────

  `make neomacs-check' exercises an installed Neomacs without its init,
  in a disposable HOME, through source and byte-compiled package
  loads. Supply `NEOMACS' as the installed executable, `COMPAT' and
  `KEYMAP_POPUP' as explicit dependency directories, and optionally
  `NEOMACS_LISP' for native libraries:
  ┌────
  │ make neomacs-check NEOMACS="$NEOMACS" COMPAT="$COMPAT" \
  │   KEYMAP_POPUP="$KEYMAP_POPUP" NEOMACS_LISP="$NEOMACS_LISP"
  └────
  This inexpensive lane compiles every shipped Lisp source without Eat
  or vterm on its load path, including their optional adapters. It needs
  no Rust rebuild or GPU launch. Its deterministic native host fixtures
  verify session and input routing, not a real PTY or a real Codex tool
  call. Verify those journeys in an interactive native runtime too.  The
  optional installed GNU runtime lane can use `make ENV=host
  EMACS_CMD'…= with dependency load paths; Thanos uses his own Emacs
  fork (*Thanos Emacs fork*), which is distinct from Neomacs and from
  the pinned Nix GNU runtime.


1.14 Changelog
──────────────

  See [NEWS.org] for release notes.


[NEWS.org] <file:NEWS.org>


1.15 Installation
─────────────────

  For GNU Emacs' default backend, install Eat separately:
  ┌────
  │ (use-package eat :ensure t)
  └────
  Neomacs native sessions need neither Eat nor vterm at runtime.  Every
  package source can also be byte-compiled without Eat. Selecting Eat
  without installing it produces an actionable error before buffer
  creation; errors from loading an installed backend are preserved for
  diagnosis.

  ⁃ Emacs 29.1 using `package-vc-install'
  ┌────
  │ (unless (package-installed-p 'codex-ide)
  │   (package-vc-install
  │    '(codex-ide :url "https://git.thanosapollo.org/emacs-codex-ide"
  │                :lisp-dir "lisp")))
  └────

  ⁃ Emacs 30 or newer using `use-package :vc'
  ┌────
  │ (use-package codex-ide
  │   :vc (:url "https://git.thanosapollo.org/emacs-codex-ide"
  │        :lisp-dir "lisp"
  │        :rev :newest))
  └────

  ⁃ Using `straight.el'
  ┌────
  │ (straight-use-package
  │  '(codex-ide :type git
  │              :host nil
  │              :repo "https://git.thanosapollo.org/emacs-codex-ide"
  │              :files ("lisp/*.el" "LICENSE")))
  └────


1.16 Source attachments
───────────────────────

  `codex-ide-attach-source' snapshots the region (or current line),
  source project-relative path or buffer name, and line range before
  choosing a project session.  It displays the target session without
  moving focus from the source buffer.  It inserts one literal bracketed
  paste on Eat, vterm or neo-term without pressing Return.  Review the
  draft in the Codex terminal before submitting it.  Unicode, TAB and LF
  are supported; other control characters and drafts larger than 1 MiB
  of UTF-8 text are rejected without changing the draft or kill ring.
  This command targets the Codex TUI, not a shell prompt.
