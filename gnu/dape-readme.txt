               ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                DAPE - DEBUG ADAPTER PROTOCOL FOR EMACS
               ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


Use `dape-configs' to set up your debug adapter configurations.  To
initiate debugging sessions, use the command `dape'.

For complete functionality, activate `eldoc-mode' in your source buffers
and enable `repeat-mode' for ergonomics.


1 Features
══════════

  ⁃ Log breakpoints
  ⁃ Conditional breakpoints
  ⁃ Variable explorer
  ⁃ Variable watch
  ⁃ Variable hover with `eldoc'
  ⁃ REPL
  ⁃ gdb-mi like interface
  ⁃ Memory viewer with `hexl'
  ⁃ `compile' integration
  ⁃ Debug adapter configuration ergonomics
  ⁃ No dependencies

  <https://raw.githubusercontent.com/svaante/dape/resources/c-light-left.png>
  And with `(setq dape-buffer-window-arrangment 'gud)' + `corfu' as
  `completion-in-region-function'.
  <https://raw.githubusercontent.com/svaante/dape/resources/js-light-gud.png>
  Screenshots taken with [modus-operandi-tinted].


[modus-operandi-tinted] <https://git.sr.ht/~protesilaos/modus-themes>


2 Configuration
═══════════════

  Currently `Dape' does not come with any debug adapter configuration.

  ┌────
  │ (use-package dape
  │   ;; To use window configuration like gud (gdb-mi)
  │   ;; :init
  │   ;; (setq dape-buffer-window-arrangment 'gud)
  │   :config
  │   ;; Info buffers to the right
  │   ;; (setq dape-buffer-window-arrangment 'right)
  │ 
  │   ;; To not display info and/or buffers on startup
  │   ;; (remove-hook 'dape-on-start-hooks 'dape-info)
  │   ;; (remove-hook 'dape-on-start-hooks 'dape-repl)
  │ 
  │   ;; To display info and/or repl buffers on stopped
  │   ;; (add-hook 'dape-on-stopped-hooks 'dape-info)
  │   ;; (add-hook 'dape-on-stopped-hooks 'dape-repl)
  │ 
  │   ;; By default dape uses gdb keybinding prefix
  │   ;; (setq dape-key-prefix "\C-x\C-a")
  │ 
  │   ;; Kill compile buffer on build success
  │   ;; (add-hook 'dape-compile-compile-hooks 'kill-buffer)
  │ 
  │   ;; Save buffers on startup, useful for interpreted languages
  │   ;; (add-hook 'dape-on-start-hooks
  │   ;;           (defun dape--save-on-start ()
  │   ;;             (save-some-buffers t t)))
  │ 
  │   ;; Projectile users
  │   ;; (setq dape-cwd-fn (lambda (&optional skip-tramp-trim)
  │   ;;                     (let ((root (projectile-project-root)))
  │   ;;                       (if (and (not skip-tramp-trim) (tramp-tramp-file-p root))
  │   ;;                           (tramp-file-name-localname (tramp-dissect-file-name root))
  │   ;;                         root))))
  │   )
  └────


3 Differences with dap-mode
═══════════════════════════

  [dap-mode] is the most popular alternative and is of course much more
  mature and probably more feature rich (have not used `dap-mode'
  extensively).

  Dape has no dependencies outside of packages included in emacs, and
  tries to use get as much out of them possible.

  Dape takes a slightly different approach to configuration.
  ⁃ Dape does not support `launch.json' files, if per project
    configuration is needed use `dir-locals'.
  ⁃ Tries to simplify configuration, by having just a plist.
  ⁃ Dape tries to improve config ergonomics in `dape' completing-read by
    using options to change/add plist entries in an already existing
    config, example:
    `adapter-config :program ＂/home/user/b.out＂ compile ＂gcc -g -o
    b.out main.c＂'.
  ⁃ No magic, no special variables. Instead, functions and variables are
    resolved before starting a new session.
  ⁃ Tries to be envision to how debug adapter configuration would be
    implemented in emacs if vscode never existed.


[dap-mode] <https://github.com/emacs-lsp/dap-mode>


4 Supported debug adapters
══════════════════════════

  In theory all debug adapters should be compatible with `Dape'.


4.1 Javascript - vscode-js-*
────────────────────────────

  1. Install `node`
  2. Visit <https://github.com/microsoft/vscode-js-debug/releases/> and
     download the asset `js-debug-dap-<version>.tar.gz`
  3. Unpack `mkdir -p ~/.emacs.d/debug-adapters && tar -xvzf
     js-debug-dap-<version>.tar.gz -C ~/.emacs.d/debug-adapters`

  For more information see [OPTIONS.md].


[OPTIONS.md]
<https://github.com/microsoft/vscode-js-debug/blob/main/OPTIONS.md>


4.2 Go - dlv
────────────

  See [delve installation].  For more information see [documentation].


[delve installation]
<https://github.com/go-delve/delve/tree/master/Documentation/installation>

[documentation]
<https://github.com/go-delve/delve/blob/master/Documentation/usage/dlv_dap.md>


4.3 C, C++ and Rust - codelldb
──────────────────────────────

  1. Download latest `vsix' [release] for your platform
     `codelldb-<platform>-<os>.vsix`
  2. Unpack `mkdir -p ~/.emacs.d/debug-adapters && unzip
     codelldb-<platform>-<os>.vsix -d
     ~/.emacs.d/debug-adapters/codelldb`

  See [manual] for more information.


[release] <https://github.com/vadimcn/codelldb/releases>

[manual] <https://github.com/vadimcn/codelldb/blob/v1.10.0/MANUAL.md>


4.4 C and C++ - cpptools
────────────────────────

  Download latesnd unpack `vsix' file with your favorite unzipper.

  1. Download latest `vsix' [release] for your platform
     `cpptools-<platform>-<os>.vsix`
  2. Unpack `mkdir -p ~/.emacs.d/debug-adapters && unzip
     cpptools-<os>-<platform>.vsix -d
     ~/.emacs.d/debug-adapters/cpptools`
  3. Then `chmod +x
     ~/.emacs.d/debug-adapters/cpptools/extension/debugAdapters/bin/OpenDebugAD7`
  4. And `chmod +x
     ~/.emacs.d/debug-adapters/cpptools/extension/debugAdapters/lldb-mi/bin/lldb-mi`

  See [options].


[release] <https://github.com/microsoft/vscode-cpptools/releases>

[options] <https://code.visualstudio.com/docs/cpp/launch-json-reference>


4.5 Python - debugpy
────────────────────

  Install debugpy with pip `pip install debugpy`

  See [options].


[options]
<https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings>


4.6 Godot
─────────

  Configure debug adapter port under "Editor" -> "Editor Settings" ->
  "Debug Adapter".


4.7 Dart - flutter
──────────────────

  See for installation <https://docs.flutter.dev/get-started/install>


4.8 C# - netcoredbg
───────────────────

  See <https://github.com/Samsung/netcoredbg> for installation


4.9 Ruby - rdbg
───────────────

  Install with `gem install debug'.

  See <https://github.com/ruby/debug> for more information


4.10 Other untested adapters
────────────────────────────

  If you find a working configuration for any other debug adapter please
  submit a PR.

  See [microsofts list] for other adapters, your mileage will vary.


[microsofts list]
<https://microsoft.github.io/debug-adapter-protocol/implementors/adapters/>


5 Roadmap
═════════

  ⁃ More options for indicator placement
  ⁃ Improving completion in REPL
  ⁃ Usage of "setVariable" inside of `*dape-info*' buffer
  ⁃ Improve memory reader with auto reload and write functionality
  ⁃ Individual thread controls
  ⁃ Variable values displayed in source buffer, this seams to require
    integration with lsp-mode and eglot


6 Bugs and issues
═════════════════

  Before reporting any issues take a look at `*dape-debug*' buffer with
  all debug messages enabled.  `(setq dape--debug-on '(io info error
  std-server))'.
