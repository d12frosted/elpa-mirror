               ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                DAPE - DEBUG ADAPTER PROTOCOL FOR EMACS
               ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


`Dape' is a debug adapter client for Emacs. The debug adapter protocol,
much like its more well-known counterpart, the language server protocol,
aims to establish a common API for programming tools. However, instead
of functionalities such as code completions, it provides a standardized
interface for debuggers.

To begin a debugging session, invoke the `dape' command. In the
minibuffer prompt, enter a debug adapter configuration name from
`dape-configs'.

For complete functionality, make sure to enable `eldoc-mode' in your
source buffers and `repeat-mode' for more pleasant key mappings.


1 Features
══════════

  ⁃ Batteries included support (`describe-variable' `dape-configs')
  ⁃ Log breakpoints
  ⁃ Conditional breakpoints
  ⁃ Variable explorer
  ⁃ Variable watch
  ⁃ Variable hover with `eldoc'
  ⁃ REPL
  ⁃ gdb-mi.el like interface
  ⁃ Memory editor with `hexl'
  ⁃ Disassembly viewer
  ⁃ Integration with `compile'
  ⁃ Debug adapter configuration ergonomics
  ⁃ No external dependencies outside of core Emacs

  With `(setq dape-buffer-window-arrangement 'right)':
  <https://raw.githubusercontent.com/svaante/dape/resources/right_0_24_0.png>
  And with `(setq dape-buffer-window-arrangement 'gud)' + `corfu' as
  `completion-in-region-function':
  <https://raw.githubusercontent.com/svaante/dape/resources/gud_0_24_0.png>
  With "rich" REPL output:
  <https://raw.githubusercontent.com/svaante/dape/resources/repl_0_24_0.png>
  With `minibuffer' adapter configuration hints:
  <https://raw.githubusercontent.com/svaante/dape/resources/minibuffer_0_24_0.png>


2 Configuration
═══════════════

  `Dape' includes pre-defined debug adapter configurations for various
  programming languages. Refer to `dape-configs' for more details. If
  `dape' doesn't include a configuration suitable for your needs, you
  can implement your own.

  ┌────
  │ (use-package dape
  │   :preface
  │   ;; By default dape shares the same keybinding prefix as `gud'
  │   ;; If you do not want to use any prefix, set it to nil.
  │   ;; (setq dape-key-prefix "\C-x\C-a")
  │ 
  │   :hook
  │   ;; Save breakpoints on quit
  │   ;; (kill-emacs . dape-breakpoint-save)
  │   ;; Load breakpoints on startup
  │   ;; (after-init . dape-breakpoint-load)
  │ 
  │   :config
  │   ;; Turn on global bindings for setting breakpoints with mouse
  │   ;; (dape-breakpoint-global-mode)
  │ 
  │   ;; Info buffers to the right
  │   ;; (setq dape-buffer-window-arrangement 'right)
  │ 
  │   ;; Info buffers like gud (gdb-mi)
  │   ;; (setq dape-buffer-window-arrangement 'gud)
  │   ;; (setq dape-info-hide-mode-line nil)
  │ 
  │   ;; Pulse source line (performance hit)
  │   ;; (add-hook 'dape-display-source-hook 'pulse-momentary-highlight-one-line)
  │ 
  │   ;; Showing inlay hints
  │   ;; (setq dape-inlay-hints t)
  │ 
  │   ;; Save buffers on startup, useful for interpreted languages
  │   ;; (add-hook 'dape-start-hook (lambda () (save-some-buffers t t)))
  │ 
  │   ;; Kill compile buffer on build success
  │   ;; (add-hook 'dape-compile-hook 'kill-buffer)
  │ 
  │   ;; Projectile users
  │   ;; (setq dape-cwd-function 'projectile-project-root)
  │   )
  │ 
  │ ;; Enable repeat mode for more ergonomic `dape' use
  │ (use-package repeat
  │   :config
  │   (repeat-mode))
  └────


3 Differences with dap-mode
═══════════════════════════

  Dape has no dependencies outside of core Emacs packages, and tries to
  use get as much out of them possible.

  Dape takes a slightly different approach to configuration.
  ⁃ `Dape' does not support `launch.json' files, if per project
    configuration is needed use `dir-locals' and `dape-command'.
  ⁃ `Dape' enhances ergonomics within the minibuffer by allowing users
    to modify or add PLIST entries to an existing configuration using
    options. For example `dape-config :cwd
    default-directory :program ＂/home/user/b.out＂ compile ＂gcc -g -o
    b.out main.c＂'.
  ⁃ No magic, no special variables like `${workspaceFolder}'. Instead,
    functions and variables are resolved before starting a new session.
  ⁃ Tries to envision how debug adapter configurations would be
    implemented in Emacs if vscode never existed.


4 Supported debug adapters
══════════════════════════

  In theory all debug adapters should be compatible with `Dape'.


4.1 Javascript - vscode-js-*
────────────────────────────

  1. Install `node'
  2. Visit <https://github.com/microsoft/vscode-js-debug/releases/> and
     download the asset `js-debug-dap-<version>.tar.gz'
  3. Unpack `mkdir -p ~/.emacs.d/debug-adapters && tar -xvzf
     js-debug-dap-<version>.tar.gz -C ~/.emacs.d/debug-adapters'

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


4.3 C, C++, Rust, and more - GDB
────────────────────────────────

  Ensure that your GDB version is 14.1 or newer.  For further details,
  consult the [documentation].


[documentation]
<https://sourceware.org/gdb/current/onlinedocs/gdb.html/Debugger-Adapter-Protocol.html>


4.4 C, C++ and Rust - codelldb
──────────────────────────────

  1. Download latest `vsix' [release] for your platform
     `codelldb-<platform>-<os>.vsix'
  2. Unpack `mkdir -p ~/.emacs.d/debug-adapters && unzip
     codelldb-<platform>-<os>.vsix -d
     ~/.emacs.d/debug-adapters/codelldb'

  See [manual] for more information.


[release] <https://github.com/vadimcn/codelldb/releases>

[manual] <https://github.com/vadimcn/codelldb/blob/v1.10.0/MANUAL.md>


4.5 C and C++ - cpptools
────────────────────────

  Download latesnd unpack `vsix' file with your favorite unzipper.

  1. Download latest `vsix' [release] for your platform
     `cpptools-<platform>-<os>.vsix'
  2. Unpack `mkdir -p ~/.emacs.d/debug-adapters && unzip
     cpptools-<os>-<platform>.vsix -d
     ~/.emacs.d/debug-adapters/cpptools'
  3. Then `chmod +x
     ~/.emacs.d/debug-adapters/cpptools/extension/debugAdapters/bin/OpenDebugAD7'
  4. And `chmod +x
     ~/.emacs.d/debug-adapters/cpptools/extension/debugAdapters/lldb-mi/bin/lldb-mi'

  See [options].


[release] <https://github.com/microsoft/vscode-cpptools/releases>

[options] <https://code.visualstudio.com/docs/cpp/launch-json-reference>


4.6 C, C++ and Rust - lldb-dap
──────────────────────────────

  1. Install [lldb-dap] for your platform


[lldb-dap]
<https://github.com/helix-editor/helix/wiki/Debugger-Configurations#install-debuggers>

4.6.1 Example for MacOS using homebrew
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  1. Install the `llvm' keg: `brew install llvm'
  2. Prepend the `llvm' path to the `PATH' variable (`$(brew --prefix
     --installed llvm)/bin')
  3. `M-x dape' and pass in arguments of interest
     • To pass arguments, use `:args ["arg1" "arg2" ..]'
     • To pass environment variables, use `:env ["RUST_LOG=WARN"
       "FOO=BAR"]'
     • To use a different program instead of `a.out' (e.g., for Rust),
       use `:program "target/debug/<crate_name>"'


4.7 Python - debugpy
────────────────────

  Install debugpy with pip `pip install debugpy'

  See [options].


[options]
<https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings>


4.8 Godot
─────────

  Configure debug adapter port under "Editor" > "Editor Settings" >
  "Debug Adapter".


4.9 Dart - flutter
──────────────────

  See for installation <https://docs.flutter.dev/get-started/install>


4.10 C# - netcoredbg
────────────────────

  See <https://github.com/Samsung/netcoredbg> for installation


4.11 Ruby - rdbg
────────────────

  Install with `gem install debug'.

  See <https://github.com/ruby/debug> for more information


4.12 Java - JDTLS with Java Debug Server plugin
───────────────────────────────────────────────

  See <https://github.com/eclipse-jdtls/eclipse.jdt.ls> for installation
  of JDTLS.  See <https://github.com/microsoft/java-debug> for
  installation of the Java Debug Server plugin.  The Java config depends
  on Eglot running JDTLS with the plugin prior to starting Dape.  Either
  globally extend `eglot-server-programs' as follows to have JDTLS
  always load the plugin:
  ┌────
  │ (add-to-list 'eglot-server-programs
  │ 	     '((java-mode java-ts-mode) .
  │ 	       ("jdtls"
  │ 		:initializationOptions
  │ 		(:bundles ["/PATH/TO/java-debug/com.microsoft.java.debug.plugin/target/com.microsoft.java.debug.plugin-VERSION.jar"]))))
  └────

  Alternatively, set the variable `eglot-workspace-configuration' in the
  file `.dir-locals.el' in a project's root directory, to have JDTLS
  load the plugin for that project:
  ┌────
  │ ;; content of /project/.dir-locals.el
  │ ((nil . ((eglot-workspace-configuration
  │ 	  . (:jdtls (:initializationOptions
  │ 		     (:bundles ["/PATH/TO/java-debug/com.microsoft.java.debug.plugin/target/com.microsoft.java.debug.plugin-VERSION.jar"])))))))
  └────


4.13 PHP - Xdebug
─────────────────

  1. Install and setup `Xdebug' see [instructions]
  2. Install `node'
  3. Download latest `vsix' [release] of DAP adapter for `Xdebug'
     `php-debug-<version>.vsix'
  4. Unpack `mkdir -p ~/.emacs.d/debug-adapters && unzip
     php-debug-<version>.vsix -d ~/.emacs.d/debug-adapters/php-debug'


[instructions] <https://github.com/xdebug/vscode-php-debug>

[release] <https://github.com/xdebug/vscode-php-debug/releases>


4.14 OCaml - ocamlearlybird
───────────────────────────

  Install with `opam install earlybird'.
  1. Point `:program' to bytecode file
  2. Place breakpoints inside of `_build/default/*'

  See [ocamlearlybird] for more information.


[ocamlearlybird] <https://github.com/hackwaly/ocamlearlybird>


4.15 Bash - bash-debug
──────────────────────

  1. Install `node'
  2. Download latest `vsix' [release] of DAP adapter
     `bash-debug-<version>.vsix'
  3. Unpack `mkdir -p ~/.emacs.d/debug-adapters && unzip
     bash-debug-<version>.vsix -d ~/.emacs.d/debug-adapters/bash-debug'

  See [bash-debug] for more information.


[release] <https://github.com/rogalmic/vscode-bash-debug/releases>

[bash-debug] <https://github.com/rogalmic/vscode-bash-debug>


4.16 Other untested adapters
────────────────────────────

  If you find a working configuration for any other debug adapter please
  submit a PR.

  See [microsofts list] for other adapters, your mileage will vary.


[microsofts list]
<https://microsoft.github.io/debug-adapter-protocol/implementors/adapters/>


5 Contribute
════════════

  `dape' is subject to the same copyright assignment policy as GNU
  Emacs.

  Any legally [significant] contributions can only be merged after the
  author has completed their paperwork.  See [Contributor's Frequently
  Asked Questions (FAQ)] for more information.


[significant]
<https://www.gnu.org/prep/maintain/html_node/Legally-Significant.html#Legally-Significant>

[Contributor's Frequently Asked Questions (FAQ)]
<https://www.fsf.org/licensing/contributor-faq>


6 Performance
═════════════

  Some minor gains to performance in the debugger can be achieved in
  changing Emacs configuration values for process interaction and
  garbage collection.


6.1 `gc-cons-threshold'
───────────────────────

  This variable controls the frequency of garbage collection in Emacs.
  Too high a value will lead to increased system memory pressure and
  longer stalls, and too low a value will result in extra interruptions
  and context switches (poor performance).

  According to [GNU Emacs Maintainer Eli Zaretskii]:

  ┌────
  │ My suggestion is to repeatedly multiply gc-cons-threshold by 2 until you stop seeing significant improvements in
  │ responsiveness, and in any case not to increase by a factor larger than 100 or somesuch. If even a 100-fold increase
  │ doesn't help, there's some deeper problem with the Lisp code which produces so much garbage, or maybe GC is not the
  │ reason for slowdown.
  └────


  Abiding the upper end of that advice, you can try to set
  `gc-cons-threshold' to 100x the original value:

  ┌────
  │ (setq gc-cons-threshold 80000000) ;; original value * 100
  └────


[GNU Emacs Maintainer Eli Zaretskii]
<https://www.reddit.com/r/emacs/comments/brc05y/comment/eofulix/>


6.2 `read-process-output-max'
─────────────────────────────

  The default `read-process-output-max' of 4096 bytes may inhibit
  performance to some degree, also.


6.2.1 Linux
╌╌╌╌╌╌╌╌╌╌╌

  On Linux, you should be able to set it up to about `1mb'.  To check
  the max value, check the output of:

  ┌────
  │ cat /proc/sys/fs/pipe-max-size
  └────

  To set it:

  ┌────
  │ (setq read-process-output-max (* 1024 1024)) ;; 1mb
  └────


6.2.2 Mac OS
╌╌╌╌╌╌╌╌╌╌╌╌

  For Mac OS, there isn't an easy way to see the operating system
  pipe-max-size.  It's probably about `64kb'.

  ┌────
  │ (setq read-process-output-max (* 64 1024)) ;; 64k
  └────


6.2.3 Windows
╌╌╌╌╌╌╌╌╌╌╌╌╌

  There doesn't seem to be a limit for Windows.  You can try `1mb'.

  ┌────
  │ (setq read-process-output-max (* 1024 1024)) ;; 1mb
  └────


7 Bugs and issues
═════════════════

  Before reporting any issues `(setq dape-debug t)' and take a look at
  `*dape-repl*' buffer. Please share your `*dape-repl*' and
  `*dape-connection events*' in the buffer contents with the bug report.
  The `master' branch is used as an development branch and releases on
  elpa should be more stable so in the mean time use elpa if the bug is
  a breaking you workflow.


8 Acknowledgements
══════════════════

  Big thanks to João Távora for the input and jsonrpc; the project
  wouldn't be where it is without João.
