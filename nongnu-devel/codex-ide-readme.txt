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

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Command                                Purpose                                                           
  ──────────────────────────────────────────────────────────────────────────────────────────────────────────
   `M-x codex-ide'                        Start or toggle the active project session (`C-u' starts another) 
   `M-x codex-ide-new-session'            Start another live session for the project                        
   `M-x codex-ide-resume-last'            `codex resume --last'                                             
   `M-x codex-ide-resume'                 Pick a saved session id, then `codex resume <id>'                 
   `M-x codex-ide-stop'                   Stop only the *active* project session                            
   `M-x codex-ide-toggle'                 Cycle live project sessions                                       
   `M-x codex-ide-list-project-sessions'  Switch among project sessions                                     
   `M-x codex-ide-list-sessions'          Switch among any live sessions                                    
   `M-x codex-ide-send-prompt'            Send a minibuffer prompt into the active session                  
   `M-x codex-ide-menu'                   Popup menu (sessions, config, MCP, debug)                         
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


1.3 Terminal scrolling
──────────────────────

  ⁃ With Eat, `C-c C-e' enters its read-only Emacs mode for ordinary
    scrolling, movement, search, and selection.
  ⁃ With vterm, use `M-x vterm-copy-mode' for transcript navigation.
  ⁃ `C-c C-j' restores terminal input and jumps to the live Codex frame
    with either backend.


1.4 Context provider
────────────────────

  ⁃ With `codex-ide-context-auto-start' non-nil (default), new sessions
    enable the IDE context IPC automatically.
  ⁃ Disable with `(setq codex-ide-context-auto-start nil)'.


1.5 MCP tools
─────────────

  ⁃ When `codex-ide-mcp-enabled' is non-nil (default), session start
    registers a transient local MCP URL via Codex `-c' overrides.
  ⁃ The bridge can evaluate Elisp, edit buffers, and run shell
    commands. It exposes those control tools by default and only accepts
    loopback bind addresses.
  ⁃ Commands: `codex-ide-mcp-start', `codex-ide-mcp-stop',
    `codex-ide-mcp-status', `codex-ide-mcp-install-codex-config'.
  ⁃ Default port is ephemeral (`codex-ide-mcp-port' 0). Persistent Codex
    config only stays reliable with a fixed port.
  ⁃ Disable auto registration with `(setq codex-ide-mcp-enabled nil)'.


1.6 Useful knobs
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


1.7 Optional vterm backend
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


1.8 Changelog
─────────────

  See [NEWS.org] for release notes.


[NEWS.org] <file:NEWS.org>


1.9 Installation
────────────────

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
