1 Codex IDE integration for GNU Emacs
═════════════════════════════════════

1.1 About
─────────

  ⁃ [codex] native integration for Emacs via [Eat] by default
    ⁃ Run Codex in a project-scoped terminal buffer.
    ⁃ Optionally use [vterm] when it is installed separately.
    ⁃ Resume, switch, cycle, and stop multiple live Codex sessions.
    ⁃ Optional IDE context provider and local Emacs MCP tools bridge.
  ⁃ Requires Emacs 29.1 or newer.


[codex] <https://github.com/openai/codex>

[Eat] <https://codeberg.org/akib/emacs-eat>

[vterm] <https://github.com/akermu/emacs-libvterm>


1.2 Commands
────────────

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Command                                Purpose                                                               
  ──────────────────────────────────────────────────────────────────────────────────────────────────────────────
   `M-x codex-ide'                        Start or toggle the active project session (`C-u' starts another)     
   `M-x codex-ide-new-session'            Start another live session for the project                            
   `M-x codex-ide-resume-last'            `codex resume --last'                                                 
   `M-x codex-ide-resume'                 Pick a saved session id, then `codex resume <id>'                     
   `M-x codex-ide-rename-session'         Label a live session; empty input restores automatic naming           
   `M-x codex-ide-stop'                   Stop only the *active* project session                                
   `M-x codex-ide-toggle'                 Cycle live project sessions                                           
   `M-x codex-ide-toggle-panel'           Hide or restore project session windows in this tab                   
   `M-x codex-ide-show-project-sessions'  Show all project sessions in separate side windows                    
   `M-x codex-ide-list-project-sessions'  Switch among project sessions                                         
   `M-x codex-ide-list-sessions'          Switch among any live sessions                                        
   `M-x codex-ide-attach-source'          Attach region or current line to one session draft without submitting 
   `M-x codex-ide-send-prompt'            Send a minibuffer prompt into the active session                      
   `M-x codex-ide-menu'                   Popup menu (sessions, config, MCP, debug)                             
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


1.3 Saved sessions
──────────────────

  ⁃ `codex-ide-resume-session-scan-limit' limits matching unique
    sessions offered by the picker (default 200), after filtering by
    project.
  ⁃ If the project has no saved sessions, the picker offers other
    projects.
  ⁃ Metadata lines larger than one MiB produce an explicit error.


1.4 Terminal scrolling
──────────────────────

  ⁃ With Eat, `C-c C-e' enters its read-only Emacs mode for ordinary
    scrolling, movement, search, and selection.
  ⁃ With vterm, use `M-x vterm-copy-mode' for transcript navigation.
  ⁃ `C-c C-j' restores terminal input and jumps to the live Codex frame
    with either backend.


1.5 Context provider
────────────────────

  ⁃ With `codex-ide-context-auto-start' non-nil (default), new sessions
    enable the IDE context IPC automatically.
  ⁃ Disable with `(setq codex-ide-context-auto-start nil)'.


1.6 MCP tools
─────────────

  ⁃ Supports stateless MCP `2026-07-28' requests and the `2025-06-18'
    initialization flow for existing clients, on the same endpoint.
  ⁃ Modern clients can discover capabilities with `server/discover' or
    call tools directly, with protocol metadata and matching routing
    headers.
  ⁃ When `codex-ide-mcp-enabled' is non-nil (default), session start
    registers a transient local MCP URL via Codex `-c' overrides.
  ⁃ The bridge can evaluate Elisp, edit buffers, and run shell
    commands. It exposes those control tools by default and only accepts
    loopback bind addresses.
  ⁃ Commands: `codex-ide-mcp-start', `codex-ide-mcp-stop',
    `codex-ide-mcp-status', `codex-ide-mcp-install-codex-config'.
  ⁃ Structured edits require an explicit `buffer' name or open file
    `path'.  Supplied tool arguments must match their advertised types;
    for example, positions are integers and `indent' is a JSON boolean.
  ⁃ Default port is ephemeral (`codex-ide-mcp-port' 0). Persistent Codex
    config only stays reliable with a fixed port.
  ⁃ Disable auto registration with `(setq codex-ide-mcp-enabled nil)'.


1.6.1 Custom tools
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


1.7 Ediff review
────────────────

  `codex-ide-diff-review' takes old text, proposed text, a path label,
  and a callback.  It returns immediately with an owner for
  `codex-ide-diff-cancel'.  Edit the proposed buffer, then use `C-c C-a'
  in the Ediff control buffer to accept, or `q' to reject.  The callback
  receives `(accepted final-text)', `(rejected nil)', or `(cancelled
  nil)'.  Only one review can be active.

  Review never changes the target file or its visiting buffer.  The
  caller owns applying accepted text.  `codex-ide-diff-preview' remains
  a synchronous boolean preview with both buffers read-only.

  Codex can call `emacs_review_start' with `buffer' (the live terminal
  name), `token' (a unique retry token), `path', `old', and `new'.  It
  receives a `review_id' promptly; `emacs_review_result' retrieves the
  decision on a new connection, optionally with `cancel=true'.
  Disconnecting HTTP does not cancel a review.  Identical owner/token
  retries return the same ID; changed input with that token is rejected.
  These arguments route the proposal to a session; they are not an
  authentication boundary.

  Apply only the accepted `content', after checking that the original
  base has not changed.  Changed bases require another review.  The
  tools do not intercept or enforce approval of other file writes.  One
  review may be queued or open, with at most 16 retained receipts and
  one MiB of combined UTF-8 input text.  Pending reviews expire after 30
  minutes; final results remain available for another 30 minutes.
  Session or server shutdown cancels pending UI while retaining results
  until that retention expires.


1.8 Useful knobs
────────────────

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Variable                        Default intent                            
  ───────────────────────────────────────────────────────────────────────────
   `codex-ide-cli-path'            Codex executable                          
   `codex-ide-terminal-backend'    `eat'; optionally set to `vterm'          
   `codex-ide-ask-for-approval'    Optional `--ask-for-approval' policy      
   `codex-ide-cli-extra-args'      Extra CLI args                            
   `codex-ide-no-alt-screen'       Inline TUI mode                           
   `codex-ide-yolo'                Full control without approvals or sandbox 
   `codex-ide-mcp-enabled'         Auto-register local MCP bridge            
   `codex-ide-mcp-port'            0 = ephemeral port                        
   `codex-ide-context-auto-start'  Auto-start context IPC                    
   `codex-ide-debug'               Debug logging                             
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Menu *Save configuration* persists the documented symbol set only
  (CLI/terminal/display/approval/YOLO/no-alt-screen/extra-args/config-overrides/
  debug/MCP host-port-enable/context-auto-start).


1.9 Optional vterm backend
──────────────────────────

  Install vterm separately, then select it for new sessions:
  ┌────
  │ (use-package vterm
  │   :ensure t)
  │ 
  │ (setq codex-ide-terminal-backend 'vterm)
  └────

  Eat remains a required dependency and the default.  Changing the
  option does not alter already running sessions.


1.10 Changelog
──────────────

  See [NEWS.org] for release notes.


[NEWS.org] <file:NEWS.org>


1.11 Installation
─────────────────

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


1.12 Source attachments
───────────────────────

  `codex-ide-attach-source' snapshots the region (or current line),
  source path or buffer name, and line range before choosing a project
  session.  It inserts one literal bracketed paste on Eat or vterm
  without pressing Return.  Review the draft in the Codex terminal
  before submitting it.  Unicode, TAB and LF are supported; other
  control characters and drafts larger than 1 MiB of UTF-8 text are
  rejected without changing the draft or kill ring.  This command
  targets the Codex TUI, not a shell prompt.
