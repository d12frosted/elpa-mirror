1 Codex IDE integration for GNU Emacs
═════════════════════════════════════

1.1 About
─────────

  ⁃ [codex] native integration for Emacs via [eat]
    ⁃ Run Codex in a project-scoped eat buffer.
    ⁃ Resume, switch, cycle, and stop multiple live Codex sessions.
    ⁃ Optional IDE context provider and local Emacs MCP tools bridge.


[codex] <https://github.com/openai/codex>

[eat] <https://codeberg.org/akib/emacs-eat>


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

  ⁃ `C-c C-e' enters Eat's read-only Emacs mode for ordinary scrolling,
    movement, search, and selection.
  ⁃ `C-c C-j' restores terminal input and jumps to the live Codex frame.


1.4 Context provider
────────────────────

  ⁃ With `codex-ide-context-auto-start' non-nil (default), new sessions
    enable the IDE context IPC automatically.
  ⁃ Disable with `(setq codex-ide-context-auto-start nil)'.


1.5 MCP tools
─────────────

  ⁃ When `codex-ide-mcp-enabled' is non-nil (default), session start
    registers a transient local MCP URL via Codex `-c' overrides.
  ⁃ Commands: `codex-ide-mcp-start', `codex-ide-mcp-stop',
    `codex-ide-mcp-status', `codex-ide-mcp-install-codex-config'.
  ⁃ Default port is ephemeral (`codex-ide-mcp-port' 0). Persistent Codex
    config only stays reliable with a fixed port.
  ⁃ Disable auto registration with `(setq codex-ide-mcp-enabled nil)'.


1.6 Useful knobs
────────────────

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Variable                        Default intent                       
  ──────────────────────────────────────────────────────────────────────
   `codex-ide-cli-path'            Codex executable                     
   `codex-ide-ask-for-approval'    Optional `--ask-for-approval' policy 
   `codex-ide-cli-extra-args'      Extra CLI args                       
   `codex-ide-no-alt-screen'       Inline TUI mode                      
   `codex-ide-mcp-enabled'         Auto-register local MCP bridge       
   `codex-ide-mcp-port'            0 = ephemeral port                   
   `codex-ide-context-auto-start'  Auto-start context IPC               
   `codex-ide-debug'               Debug logging                        
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Menu *Save configuration* persists the documented symbol set only
  (CLI/display/approval/no-alt-screen/extra-args/config-overrides/debug/MCP
  host-port-enable/context-auto-start).


1.7 Installation
────────────────

  ⁃ Using `:vc'
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
