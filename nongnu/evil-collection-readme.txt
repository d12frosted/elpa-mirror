                           ━━━━━━━━━━━━━━━━━
                            EVIL COLLECTION
                           ━━━━━━━━━━━━━━━━━


[file:https://github.com/emacs-evil/evil-collection/actions/workflows/build.yaml/badge.svg?branch=master]
[file:https://melpa.org/packages/evil-collection-badge.svg]
[file:https://stable.melpa.org/packages/evil-collection-badge.svg]

This is a collection of [Evil] bindings for /the parts of Emacs/ that
Evil does not cover properly by default, such as `help-mode', `M-x
calendar', Eshell and more.

*Warning:* Expect some default bindings to change in the future.


[file:https://github.com/emacs-evil/evil-collection/actions/workflows/build.yaml/badge.svg?branch=master]
<https://github.com/emacs-evil/evil-collection/actions>

[file:https://melpa.org/packages/evil-collection-badge.svg]
<https://melpa.org/#/evil-collection>

[file:https://stable.melpa.org/packages/evil-collection-badge.svg]
<https://stable.melpa.org/#/evil-collection>

[Evil] <https://github.com/emacs-evil/evil>


1 Preliminaries
═══════════════

  1. `evil-overriding-maps' is assumed as `nil' to reduce redundant
     `w/W/l/f/t' etc evil bindings. See [Fixup Info-mode] for example.


[Fixup Info-mode]
<https://github.com/emacs-evil/evil-collection/pull/501>


2 Goals
═══════

  1. Reduce context switching: As soon as "moving around" gets hardwired
     to `<hjkl>', it becomes frustratingly inefficient not to have it
     everywhere.

  2. Community work: setting up bindings is tremendous work and joining
     force can only save hours for all of Evil users out there.  While
     not everyone may agree on the chosen bindings, it helps to have
     something to start with rather than nothing at all.  In the end,
     users are free to override a subset of the proposed bindings to
     best fit their needs.

  3. Consistency: Having all bindings defined in one place allows for
     enforcing consistency across special modes and coordinating the
     community work to define a reference implementation.


3 Installation
══════════════

  • Get the package, either from MELPA:

    ┌────
    │ M-x package-install RET evil-collection RET
    └────


    Or clone / download this repository and modify your `load-path':

    ┌────
    │ (add-to-list 'load-path (expand-file-name "/path/to/evil-collection/" user-emacs-directory))
    └────

  • Register the bindings, either all at once with

    ┌────
    │ (evil-collection-init)
    └────


    or mode-by-mode, for instance:

    ┌────
    │ (with-eval-after-load 'calendar (evil-collection-calendar-setup))
    └────


    or by providing an argument to `evil-collection-init':

    ┌────
    │ (evil-collection-init 'calendar)
    └────


    a list can also be provided to `evil-collection-init':

    ┌────
    │ (evil-collection-init '(calendar dired calc ediff))
    └────


    The list of supported modes is configured by
    `evil-collection-mode-list'.

  `evil-collection' assumes `evil-want-keybinding' is set to `nil' and
  `evil-want-integration' is set to `t' before loading `evil' and
  `evil-collection'. Note some other packages may load evil
  (e.g. evil-leader) so bear that in mind when determining when to set
  the variables.

  See <https://github.com/emacs-evil/evil-collection/issues/60> and
  <https://github.com/emacs-evil/evil/pull/1087> for more details.

  For example:

  ┌────
  │ (setq evil-want-integration t) ;; This is optional since it's already set to t by default.
  │ (setq evil-want-keybinding nil)
  │ (require 'evil)
  │ (when (require 'evil-collection nil t)
  │   (evil-collection-init))
  └────

  Here's another full TLDR `use-package' example.

  ┌────
  │ (use-package evil
  │   :ensure t
  │   :init
  │   (setq evil-want-integration t) ;; This is optional since it's already set to t by default.
  │   (setq evil-want-keybinding nil)
  │   :config
  │   (evil-mode 1))
  │ 
  │ (use-package evil-collection
  │   :after evil
  │   :ensure t
  │   :config
  │   (evil-collection-init))
  └────

  NOTE: If you don't like surprises but still want to use
  `evil-collection-init', setting `evil-collection-mode-list' to nil and
  adding each mode manually might be a better option.


4 Configuration
═══════════════

  Modify `evil-collection-mode-list' to disable or add any modes that
  should be evilified by `evil-collection'.

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Variable                                    Default  Description                                                       
  ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   evil-collection-calendar-want-org-bindings  nil      Set up Org functions in calendar keymap.                          
   evil-collection-outline-bind-tab-p          nil      Enable <tab>-based bindings in Outline mode.                      
   evil-collection-term-sync-state-and-mode-p  t        Synchronize insert/normal state with char/line-mode in term-mode. 
   evil-collection-setup-minibuffer            nil      Set up Vim style bindings in the minibuffer.                      
   evil-collection-want-unimpaired-p           t        Set up unimpaired bindings globally.                              
   evil-collection-config                      *        List of mode specific configurations.                             
   evil-collection-binding-overrides           nil      Override key themes (see *Key Themes* below).                     
   evil-collection-key-whitelist               nil      List of keys Evil Collection is allowed to bind to.               
   evil-collection-key-blacklist               nil      List of keys Evil Collection is not allowed to bind to.           
   evil-collection-state-passlist              nil      List of Evil States Evil Collection is allowed to bind to.        
   evil-collection-state-denylist              nil      List of Evil States Evil Collection is not allowed to bind to.    
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  For example, if you want to enable Evil in the minibuffer, you'll have
  to turn it on explicitly by customizing
  `evil-collection-setup-minibuffer' to `t'.  Some minibuffer-related
  packages such as Helm rely on this option.

  `use-package' example:

  ┌────
  │ (use-package evil-collection
  │   :custom (evil-collection-setup-minibuffer t)
  │   :init (evil-collection-init))
  └────

  `evil-collection-config' can also be modified to configure specific
  modes.  At the moment, it can be used to defer binding keys to those
  specific modes in order to improve startup time.


5 Key Themes
════════════

  Some set of common keybindings can be configured. Look at
  `evil-collection-binding-defaults' for the existing list.

  For example, `vterm', `eat' and `ghostel' all need a way to send
  toggle sending ESC to Emacs or the underlying binary.

  To customize, override with `evil-collection-binding-overrides'.

  Each entry has the form `(ID . PLIST)' with these properties:

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Property    Accepts                                   Notes                                                            
  ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   `:enabled'  `t', `nil', or a function of no args      Missing -> `t'. Functions are funcalled at lookup time.          
   `:state'    symbol, list of symbols, or a function    Evil states. Singular form (e.g. `normal') is allowed. Optional. 
   `:key'      key string, list of strings, or function  Strings suitable for `kbd'. Singular form is allowed. Optional.  
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  `:state' and `:key' are optional. Entries with only `:enabled' act as
  pure feature toggles — the consumer-side code does the binding itself
  and asks the resolver whether the feature is on.

  Example:

  ┌────
  │ (term-toggle-escape :enabled t
  │                     :state (normal insert)
  │                     :key "C-c C-z")
  └────

  `vterm', `eat', and `evil-ghostel' each call `(evil-collection-bind
  'term-toggle-escape MAP CMD)' which binds CMD to `C-c C-z' in normal
  and insert state inside MAP.


5.1 Overrides merge per-property
────────────────────────────────

  An override only replaces properties it explicitly sets; anything it
  leaves out falls through to the defaults. So this:

  ┌────
  │ (setq evil-collection-binding-overrides
  │       '((term-toggle-escape :state normal)))
  └────

  restricts the toggle to `normal' state while leaving `:enabled' and
  `:key'.


5.2 Rebinding and disabling
───────────────────────────

  Rebind a feature across every mode that uses it:

  ┌────
  │ (setq evil-collection-binding-overrides
  │       '((term-toggle-escape :key "C-c j")))
  └────

  Or supply multiple keys:

  ┌────
  │ (setq evil-collection-binding-overrides
  │       '((term-toggle-escape :key ("C-c C-z" "C-c j"))))
  └────

  To disable a key theme.

  ┌────
  │ (setq evil-collection-binding-overrides
  │       '((term-toggle-escape :enabled nil)))
  └────

  `:enabled' can also take a predicate.

  ┌────
  │ (setq evil-collection-binding-overrides
  │       `((find-usages :enabled ,(lambda () evil-collection-want-find-usages-bindings))))
  └────


5.3 Configure the REPL
──────────────────────

  `:state' for `repl-submit~/~repl-newline' defaults to lambdas that
  read the (now-obsolete) `evil-collection-repl-submit-state' — flipping
  that var is equivalent to setting `:state' here.

  ┌────
  │ (setq evil-collection-binding-overrides
  │       '((repl-submit        :state normal         :key ("RET" "<return>" "C-m"))
  │         (repl-newline       :state insert         :key ("RET" "<return>" "C-m"))
  │         (repl-force-newline :state (normal insert) :key ("S-<return>" "S-RET"))))
  └────


5.4 Find usages
───────────────

  ┌────
  │ (setq evil-collection-binding-overrides
  │       '((find-usages :state normal :key "gr")))
  └────


5.5 Find / pop definition
─────────────────────────

  ┌────
  │ (setq evil-collection-binding-overrides
  │       '((find-definition :state normal :key "gd")
  │         (pop-definition  :state normal :key "C-t")))
  └────


5.6 Lookup documentation
────────────────────────

  ┌────
  │ (setq evil-collection-binding-overrides
  │       '((lookup-doc :state normal :key "K")))
  └────


5.7 Goto REPL
─────────────

  ┌────
  │ (setq evil-collection-binding-overrides
  │       '((goto-repl :state normal :key "gz")))
  └────


5.8 Find file
─────────────

  ┌────
  │ (setq evil-collection-binding-overrides
  │       '((find-file :state normal :key "gf")))
  └────


5.9 Quit
────────

  ┌────
  │ (setq evil-collection-binding-overrides
  │       '((quit :state normal :key "q")))
  └────


5.10 Quit save / cancel
───────────────────────

  Vim's `ZZ' (`:x' — save and quit) and `ZQ' (`:q!' — discard and quit),
  for editable buffers like `wgrep', `wdired', `message', `org-capture',
  `with-editor'.

  ┌────
  │ (setq evil-collection-binding-overrides
  │       '((quit-save   :state normal :key "ZZ")
  │         (quit-cancel :state normal :key "ZQ")))
  └────


5.11 Rename
───────────

  Rename the entry, file, or thing at point.  Both `r' and `R' are
  bound.

  ┌────
  │ (setq evil-collection-binding-overrides
  │       '((rename :state normal :key ("r" "R"))))
  └────


5.12 Edit
─────────

  Edit the entry / annotation / item at point.  Both `e' and `E' are
  bound.

  ┌────
  │ (setq evil-collection-binding-overrides
  │       '((edit :state normal :key ("e" "E"))))
  └────


5.13 Browse URL
───────────────

  Open the URL / link / page at point in an external browser (or
  whatever the mode considers "externally").  `gx' matches evil's own
  `browse-url-at-point' default in normal state.

  ┌────
  │ (setq evil-collection-binding-overrides
  │       '((browse-url :state normal :key "gx")))
  └────


5.14 Describe mode
──────────────────

  ┌────
  │ (setq evil-collection-binding-overrides
  │       '((describe-mode :state normal :key "g?")))
  └────


5.15 Refresh / refresh-all
──────────────────────────

  ┌────
  │ (setq evil-collection-binding-overrides
  │       '((refresh     :state normal :key "gr")
  │         (refresh-all :state normal :key "gR")))
  └────


5.16 Action
───────────

  `action' is the next logical action at point — usually opening or
  selecting the item, but more generally the mode's DTRT operation.
  `action-other' performs the related action in another window or
  target.  `action-stay' displays or previews the target while keeping
  focus in the current context.

  ┌────
  │ (setq evil-collection-binding-overrides
  │       '((action       :state normal :key ("RET" "<return>"))
  │         (action-other :state normal :key ("S-<return>" "S-RET" "go"))
  │         (action-stay  :state normal :key ("M-<return>" "M-RET" "gO"))))
  └────


5.17 Next / prev navigation
───────────────────────────

  Up to three tiers — `next-item~/~prev-item' is granular (e.g. next
  hunk, next prompt, next open message).  `next-section~/~prev-section'
  is coarser (next file, next thread, next group).
  `next-section-2~/~prev-section-2' is a third tier for the few modes
  that distinguish a yet-different layer (diff-mode's hunks vs files,
  sly-db's frames vs details, notmuch-tree's threads).  Modes that don't
  distinguish bind the same command to multiple tiers.

  ┌────
  │ (setq evil-collection-binding-overrides
  │       '((next-item      :state normal :key "gj")
  │         (prev-item      :state normal :key "gk")
  │         (next-section   :state normal :key ("]]" "C-j"))
  │         (prev-section   :state normal :key ("[[" "C-k"))
  │         (next-section-2 :state normal :key "C-j")
  │         (prev-section-2 :state normal :key "C-k")))
  └────


5.18 Debugger
─────────────

  `:enabled' defaults to a function that reads (now-obsolete)
  `evil-collection-setup-debugger-keys' — setting that to `nil' disables
  all of them at once.

  ┌────
  │ (setq evil-collection-binding-overrides
  │       '((debug-continue   :state normal :key ("c" "<f5>"))
  │         (debug-step-over  :state normal :key ("n" "<f10>"))
  │         (debug-step-into  :state normal :key ("i" "s" "<f11>"))
  │         (debug-step-out   :state normal :key ("o" "<S-f11>"))
  │         (debug-breakpoint :state normal :key ("b" "<f9>"))
  │         (debug-eval       :state normal :key "e")
  │         (debug-locals     :state normal :key "L")
  │         (debug-restart    :state normal :key "R")
  │         (debug-frame-up   :state normal :key "<")
  │         (debug-frame-down :state normal :key ">")))
  └────


5.19 Tab navigation
───────────────────

  Three semantics share the `<tab>' / `<backtab>' pair:

  • `next-button' / `previous-button' — for modes using Emacs's
    `forward-button' / `backward-button' (e.g. `man', `helpful',
    `devdocs').
  • `cycle-next' / `cycle-previous' — generic forward/back through
    mode-specific items (e.g. `eww' links, `elisp-refs' matches,
    `indium' inspector references).
  • `section-toggle' — TAB toggles fold/expand at point
    (e.g. `org-cycle', `outline-toggle-children').

  ┌────
  │ (setq evil-collection-binding-overrides
  │       '((next-button     :state normal :key ("<tab>" "TAB"))
  │         (previous-button :state normal :key ("<backtab>" "<S-tab>"))
  │         (cycle-next      :state normal :key ("<tab>" "TAB"))
  │         (cycle-previous  :state normal :key ("<backtab>" "<S-tab>"))
  │         (section-toggle  :state normal :key ("<tab>" "TAB"))))
  └────


5.20 Scroll
───────────

  `SPC' / `S-SPC' for paging in read-only buffers (e.g. `eww',
  `pdf-view', info-style modes).

  ┌────
  │ (setq evil-collection-binding-overrides
  │       '((scroll-down :state normal :key "SPC")
  │         (scroll-up   :state normal :key ("S-SPC" "S-<space>"))))
  └────


5.21 Jump (J)
─────────────

  Jump to a named/prompted item — buffer, article, group, chunk, branch,
  entry, date, etc.

  ┌────
  │ (setq evil-collection-binding-overrides
  │       '((jump :state normal :key "J")))
  └────


5.22 Zoom (+ / - / 0)
─────────────────────

  Increase, decrease, and reset zoom/scale.

  ┌────
  │ (setq evil-collection-binding-overrides
  │       '((zoom-in    :state normal :key ("+" "="))
  │         (zoom-out   :state normal :key "-")
  │         (zoom-reset :state normal :key "0")))
  └────


5.23 History / Completion (C-n / C-p)
─────────────────────────────────────

  Vim uses `C-n' / `C-p' in several "next/previous in some sequence"
  contexts.  We split them into two themes so the state matches the
  semantic:

  • `history-previous' / `history-next' — normal-state navigation of a
    buffer's input or page history (REPL prompts, shell history, doc
    back/forward).  Consumers: `comint', `eshell', `slime', `sly',
    `edbi', `rg', `devdocs'.

  • `completion-previous' / `completion-next' — insert-state navigation
    of the candidate list during an active minibuffer or popup
    completion.  Consumers: `ivy', `vertico', `selectrum', `corfu',
    `helm', `company'.

  Modes whose `C-n' / `C-p' blur both (e.g. `helm') opt into both
  themes.

  ┌────
  │ (setq evil-collection-binding-overrides
  │       '((history-previous     :state normal :key "C-p")
  │         (history-next         :state normal :key "C-n")
  │         (completion-previous  :state insert :key "C-p")
  │         (completion-next      :state insert :key "C-n")))
  └────


5.24 Marking
────────────

  Dired-style mark family for tabular-list modes (`ibuffer', `proced',
  `package-menu', `tablist' derivatives):

  • `mark' / `unmark' — mark / unmark entry at point (`m' / `u').
  • `mark-all' / `unmark-all' — bulk variants (`M' / `U').
  • `mark-toggle-all' — invert marks (`~') — mirrors vim's `~'
    invert-char.
  • `mark-delete' — flag entry for deletion (`d'), paired with
    `execute-marks' (`x').
  • `execute-marks' — execute pending marked actions (`x').

  ┌────
  │ (setq evil-collection-binding-overrides
  │       '((mark            :state normal :key "m")
  │         (mark-all        :state normal :key "M")
  │         (mark-toggle-all :state normal :key "~")
  │         (unmark          :state normal :key "u")
  │         (unmark-all      :state normal :key "U")
  │         (mark-delete     :state normal :key "d")
  │         (execute-marks   :state normal :key "x")))
  └────


5.25 Delete
───────────

  For modes whose `d' deletes immediately (no flag/execute step) —
  e.g. `docker' `rm', `realgud' breakpoint delete, `eww' buffer/bookmark
  kill, `org-agenda-kill', `ztree' file delete.

  ┌────
  │ (setq evil-collection-binding-overrides
  │       '((delete :state normal :key "d")))
  └────


6 Guidelines
════════════

  The following rules serve as guiding principles to define the set of
  standard Evil bindings for various modes.  Since special modes are by
  definition structurally incomparable, those rules cannot be expected
  to be applied universally.

  The rules are more-or-less sorted by priority.

  1. Don't bind anything to `:' nor `<escape>'.

  2. Keep the movement keys when possible and sensible.

     • `h', `j', `k', `l'
     • `w', `W', `b', `B', `e', `E', `ge', `gE'
     • `f', `F', `t', `T', `;', `,'
     • `gg', `G'
     • `|'
     • `(', `)'
     • `{', `}'
     • `%'
     • `+', `-', `0', `^', `$'
     • `C-i', `C-o'

  3. Keep the yanking and register keys when possible and sensible.

     • `y', `Y'
     • `"'

  4. Keep the search keys when possible and sensible.

     • `/', `?'
     • `#', `*'

  5. Keep the mark keys when possible and sensible.

     • `m'
     • `'', `~'

  6. Keep the windowing keys when possible and sensible.

     • `H', `L', `M'
     • `C-e', `C-y'
     • `C-f', `C-b'
     • `C-d', `C-u'
     • `C-w'-prefixed bindings.
     • Some `z'-prefixed bindings (see below).

  7. The following keys are free when insert state does not make sense
     in the current mode:

     • `a', `A', `i', `I'
     • `c', `C', `r', `R', `s', `S'
     • `d', `D', `x', `X'
     • `o', `O'
     • `p', `P'
     • `=', `<', `>'
     • `J'
     • `~'

     Any of those keys can be set to be a prefix key.

  8. Prefix keys: `g' and `z' are the ubiquitous prefix keys.

     • `g' generally stands for "go" and is best used for movements.
     • `z' is used for scrolling, folding, spell-checking and more.

  9. Macro and action keys

     • `@', `q'
     • `.'

  10. Ensure terminal compatibility without sacrificing GUI key
      bindings.
      • Tab key
        • Tab key is recognized as `<tab>' in GUI and `TAB' in terminal.
          `TAB' equals `C-i'.
        • `C-i' is bound to jumping forward for vim compatibility.  If
          Shift+Tab is not relevant, just bind `g TAB' to the function
          that Tab is bound to. If Shift+Tab is relevant, bind `g]' and
          `g TAB' to the function that Tab is bound to, and bind `g[' to
          the function that Shift+Tab is bound to for terminal
          compatibility.
      • Enter key
        • Enter key is recognized as `<return>' in GUI and `RET' in
          terminal.  `RET' equals `Ctrl+m'.
        • Bind only `RET' and `M-RET'. Or, bind `RET' and `M-RET' to the
          same functions `<return>' and `<M-return>' are bound to.
        • `S-RET' is impossible on terminal. Bind `<S-return>' and a
          vacant key to the same function for terminal compatibility.


7 Rationale
═══════════

  Many special modes share the same set of similar actions.  Those
  actions should share the same bindings across all modes whenever
  feasible.


7.1 Motion (`[', `]', `{', `}', `(', `)', `gj', `gk', `C-j', `C-k')
───────────────────────────────────────────────────────────────────

  • `[' and `]': Use `[-' and `]-' prefixed keys for navigation between
    sections.

    If the mode makes no difference between the end of a section and the
    beginning of the next, use `[' and `]'.

  • `gj' and `gk': synonym for `[' and `]'.  That's what [evil-magit]
    does.

    *Question:* Should `gj' / `gk' rather be synonyms for `C-j' / `C-k'?
    They cannot emulate the behaviour of `[]' or `]['.

    • `C-j', `C-k': If there is granularity, i.e. subsections, use `C-j'
      and `C-k' to browse them.  This reflects [evil-magit] and
      [evil-mu4e] default bindings.

    • `{', `}': If there is no paragraph structure, `{' and `}' can be
      used for sub-sectioning.

    • `(', `)': If there is no sentence structure, `(' and `)' can be
      used for sub-sectioning.

    • `HJKL': `hjkl' can be used for atomic movements, but `HJKL' can
      usually not be used because `H', `K' and `L' are all universal
      (`J' is `evil-join' and usually does not make sense in special
      modes).

    • `C-h' should not be remapped: Since we have `C-j' and `C-k' for
      vertical motion, it would make sense to use `C-h' and `C-l' for
      horizontal motion.  There are some shortcomings though:

      • In Vim, `C-h' works as backspace, but Evil does not follow that
        behaviour.

      • In Emacs, it is a prefix key for all help-related commands, and
        so is `<f1>'.

      • Most importantly, `C-h' is too widespread and ubiquitous to be
        replaced.  So we don't.

    • `C-l': As a consequence of the former point, `C-l' is available.

    • `M-<hjkl>': Those keys are usually free in Evil but still bound to
      their Emacs default (e.g. `M-l' is `downcase-word').  Besides, if
      `C-j' and `C-k' are already used, having `M-j' and `M-k' might add
      up to the confusion.


[evil-magit] <https://github.com/emacs-evil/evil-magit>

[evil-mu4e] <https://github.com/JorisE/evil-mu4e>


7.2 Quitting (`q', `ZQ', `ZZ')
──────────────────────────────

  In Vim, `q' is for recording macros.  Vim quits with `ZZ' or `ZQ'.  In
  most Emacs special modes, it stands for quitting while macros are
  recorded/played with `<f3>' and `<f4>'.

  A good rule of thumb would be:

  • Always bind `q', `ZZ' and `ZQ' to the mode specific quitting
    functions. If there is none,
  • Bind `q' and `ZZ' to `quit-window'
  • Bind `ZQ' to `evil-quit'
  • If macros don't make sense in current mode, then `@' is available.


7.3 Refreshing / Reverting (`gr')
─────────────────────────────────

  • `gr' is used for refreshing in [evil-magit], [evil-mu4e], and some
    Spacemacs configurations (org-agenda and neotree among others).

  • `C-l' is traditionally used to refresh the terminal screen. Since
    there does not seem to be any existing use of it, we leave the
    binding free for other uses.


[evil-magit] <https://github.com/emacs-evil/evil-magit>

[evil-mu4e] <https://github.com/JorisE/evil-mu4e>


7.4 Marking
───────────

  `m' defaults to `evil-set-marker' which might not be very useful in
  special modes.  `'' can still be used as it can jump to other buffers.

  • `m': Mark or toggle mark, depending on what the mode offers. In
    visual mode, always mark. With a numeric argument, toggle mark on
    that many following lines.

  • `u': Unmark current selection.

  • `U': Unmark all.

  • `~': Toggle all marks.  This mirrors the "invert-char" Vim command
    bound to `~' by default.

  • `M': Mark all, if available.  Otherwise use `U~'.

  • `*': Mark-prefix or mark all if current mode has no prefix. `*' is
    traditionally a wildcard.

  • `%': Mark regexp.

  • `x': Execute action on marks.  This mirrors Dired's binding of `x'.

  If `*' is used for marking, then `#' is free.

  Also note that Emacs inconsistently uses `u' and `U' to unmark.


7.5 Selecting / Filtering / Narrowing / Searching
─────────────────────────────────────────────────

  • `s' and `S' seem to be used in some places like [mu4e].

    • `s': [s]elect/[s]earch/filter candidates according to a pattern.
    • `S': Remove filter and select all.

  • `=' is usually free and its significance is obvious.  It's taken for
    zooming though.

  • `|' is not free but the pipe symbolic is very tantalizing.


[mu4e] <https://www.djcbsoftware.nl/code/mu/mu4e.html>


7.6 Sorting
───────────

  • `o': Change the sort [o]rder.
  • `O': Sort in reverse order.

    There is no real consensus around which key to bind to sorting.
    What others do by default:

    • `package-menu' uses `S'.

    • `M-x proced' and Dired use `s'.

    • `profiler' uses `A' and `D'.

    • [mu4e] uses `O'.

    • [ranger] uses `o', inspired from [Mutt].


[mu4e] <https://www.djcbsoftware.nl/code/mu/mu4e.html>

[ranger] <http://www.nongnu.org/ranger/>

[Mutt] <http://mutt.org>


7.7 Go to definition (`gd', `gD')
─────────────────────────────────

  • `gd': [g]o to [d]efinition.  This is mostly for programming modes.
    If there's a corresponding 'pop' action, use `C-t'.


7.8 Go to references, etc (`gr', `gA')
──────────────────────────────────────

  When `evil-collection-want-find-usages-bindings' is set to t:

  • `gr': [g] to [r]eferences. This binding is also used for
    refresh/reverting modes in non programming modes but is usually
    empty for programming modes.

  • `gA': [g]o to [A]ssignments.

  • Additional bindings: There may be additional binds under this
    category. Please file a Pull Request if so.


7.9 Go to current entity
────────────────────────

  • `.': go to current entity (day for calendar, playing track for
    [EMMS]).  Bind only if more relevant than `evil-repeat'.


[EMMS] <https://www.gnu.org/software/emms/>


7.10 Open thing at point (`RET', `S-RET', `M-RET', `go', `gO')
──────────────────────────────────────────────────────────────

  • `RET', `S-RET', `M-RET': Open thing at point in current window, open
    in other window and display in other window respectively.  The
    latter is like the former with the focus remaining on the current
    window.

  • `go', `gO': When available, same as `S-RET' and `M-RET'
    respectively.  This is useful in terminals where `S-RET' and `M-RET'
    might not work.


7.11 Emacs-style jumping (`J')
──────────────────────────────

  • `J': [mu4e] has `j' and uses `J', so we use `J' too.

    Some special modes like [mu4e] and ibuffer offer to "jump" to a
    different buffer.  This sometimes depends on the thing at point.

    This is not related to Evil jumps like `C-i' and `C-o', nor to "go
    to definition".


[mu4e] <https://www.djcbsoftware.nl/code/mu/mu4e.html>


7.12 Browse URL (`gx')
──────────────────────

  `gx': go to URL.  This is a default Vim binding.


7.13 Help (`?')
───────────────

  • `g?' : is the standard key for help related commands.
  • `?' in places where backward search is not very useful.


7.14 History browsing (`C-n', `C-p')
────────────────────────────────────

  `C-n' and `C-p' are standard bindings to browse the history elements.


7.15 Bookmarking
────────────────

  ?


7.16 REPL (`gz')
────────────────

  If the mode has a Go To REPL-type command, set it to `gz'.


7.17 Zooming (`+', `-', `=', `0')
─────────────────────────────────

  • `+' and `-' have obvious meanings.
  • `0' has a somewhat intuitive meaning, plus it is next to `+' and `-'
    on QWERTY.
  • `=' is useful as a synonym for `+' because it is the unshifted key
    of `+' on QWERTY.


7.18 Debugging
──────────────

  When debugging is on, debugger keys takes the most precedence.

  These keys will be set when there's an available command for them.

  • `n' : Step Over
  • `i' : Step Into
  • `o' : Step Out
  • `c' : Continue/Resume Execution
  • `L' : Locals
  • `t' : Tracing
  • `q' : Quit Debugging
  • `H' : Continue until Point
  • `e' : Evaluate Expression
  • `b' : Set Breakpoint
  • `u' : Unset Breakpoint
  • `>' : Navigate to Next Frame
  • `<' : Navigate to Previous Frame
  • `g?' : Help
  • `J' : Jump to debugger location
  • `R' : Restart

  For debugging outside of debugger being on (e.g. setting initial
  breakpoints), we use similar keys to [realgud].

  • `f5' Start/Continue/Resume Execution
  • `S-f5' Continue Execution
  • `Mouse-1' Toggle Breakpoint
  • `f9' Toggle Breakpoint
  • `f10' Step Over
  • `f11' Step Into
  • `S-f11' Step Out


[realgud] <https://github.com/realgud/realgud>


7.19 Editable Buffers
─────────────────────

  For buffers where insert-state doesn't make sense but buffer can be
  edited, (e.g. wdired or wgrep), pressing `i' will change into editable
  state.

  When this editable state is turned on,

  `ZQ' will abort and clear any changes.  `ZZ' will finish and save any
  changes.  `ESC' will exit editable state.


7.20 :q/:wq/etc
───────────────

  Modes with commands that can be bound to :q/:wq/etc will have those
  keys remapped.


8 Key Translation
═════════════════

  `evil-collection-translate-key' allows binding a key to the definition
  of another key in the same keymap (comparable to how Vim's keybindings
  work). Its arguments are the `states' and `keymaps' to bind/look up
  the key(s) in followed optionally by keyword arguments (currently only
  `:destructive') and key/replacement pairs. `states' should be nil for
  non-evil keymaps, and both `states' and `keymaps' can be a single
  symbol or a list of symbols.

  This function can be useful for making key swaps/cycles en masse. For
  example, someone who uses an alternate keyboard layout may want to
  retain the `hjkl' positions for directional movement in dired, the
  calendar, etc.

  Here's an example for Colemak of making swaps in a single keymap:

  ┌────
  │ (evil-collection-translate-key nil 'evil-motion-state-map
  │   ;; colemak hnei is qwerty hjkl
  │   "n" "j"
  │   "e" "k"
  │   "i" "l"
  │   ;; add back nei
  │   "j" "e"
  │   "k" "n"
  │   "l" "i")
  └────

  Here's an example of using `evil-collection-setup-hook' to cycle the
  keys for all modes in `evil-collection-mode-list':

  ┌────
  │ (defun my-hjkl-rotation (_mode mode-keymaps &rest _rest)
  │   (evil-collection-translate-key 'normal mode-keymaps
  │     "n" "j"
  │     "e" "k"
  │     "i" "l"
  │     "j" "e"
  │     "k" "n"
  │     "l" "i"))
  │ 
  │ ;; called after evil-collection makes its keybindings
  │ (add-hook 'evil-collection-setup-hook #'my-hjkl-rotation)
  │ 
  │ (evil-collection-init)
  └────

  A more common use case of `evil-collection-translate-key' would be for
  keeping the functionality of some keys that users may bind
  globally. For example, `SPC', `[', and `]' are bound in some modes. If
  you use these keys as global prefix keys that you never want to be
  overridden, you'll want to give them higher priority than other evil
  keybindings (e.g. those made by `(evil-define-key 'normal some-map
  ...)'). To do this, you can create an "intercept" map and bind your
  prefix keys in it instead of in `evil-normal-state-map':

  ┌────
  │ (defvar my-intercept-mode-map (make-sparse-keymap)
  │   "High precedence keymap.")
  │ 
  │ (define-minor-mode my-intercept-mode
  │   "Global minor mode for higher precedence evil keybindings."
  │   :global t)
  │ 
  │ (my-intercept-mode)
  │ 
  │ (dolist (state '(normal visual insert))
  │   (evil-make-intercept-map
  │    ;; NOTE: This requires an evil version from 2018-03-20 or later
  │    (evil-get-auxiliary-keymap my-intercept-mode-map state t t)
  │    state))
  │ 
  │ (evil-define-key 'normal my-intercept-mode-map
  │   (kbd "SPC f") 'find-file)
  │ ;; ...
  └────

  You can then define replacement keys:

  ┌────
  │ (defun my-prefix-translations (_mode mode-keymaps &rest _rest)
  │   (evil-collection-translate-key 'normal mode-keymaps
  │     "C-SPC" "SPC"
  │     ;; these need to be unbound first; this needs to be in same statement
  │     "[" nil
  │     "]" nil
  │     "[[" "["
  │     "]]" "]"))
  │ 
  │ (add-hook 'evil-collection-setup-hook #'my-prefix-translations)
  │ 
  │ (evil-collection-init)
  └────

  By default, the first invocation of `evil-collection-translate-key'
  will make a backup of the keymap. Each subsequent invocation will look
  up keys in the backup instead of the original. This means that a call
  to `evil-collection-translate-key' will always have the same behavior
  even if evaluated multiple times. When `:destructive t' is specified,
  keys are looked up in the keymap as it is currently. This means that a
  call to `evil-collection-translate-key' that swapped two keys would
  continue to swap/unswap them with each call. Therefore when
  `:destructive t' is used, all cycles/swaps must be done within a
  single call to `evil-collection-translate-key'. To make a comparison
  to Vim keybindings, `:destructive t' is comparable to Vim's `map', and
  `:destructive nil' is comparable to Vim's `noremap' (where the
  "original" keybindings are those that existed in the keymap when
  `evil-collection-translate-key' was first called).  You'll almost
  always want to use the default behavior (especially in your init
  file). The limitation of `:destructive nil' is that you can't
  translate a key to another key that was defined after the first
  `evil-collection-translate-key', so `:destructive t' may be useful for
  interactive experimentation.

  `evil-collection-swap-key' is also provided as a wrapper around
  `evil-collection-translate-key' that allows swapping keys:

  ┌────
  │ (evil-collection-swap-key nil 'evil-motion-state-map
  │   ";" ":")
  │ ;; is equivalent to
  │ (evil-collection-translate-key nil 'evil-motion-state-map
  │   ";" ":"
  │   ":" ";")
  └────

  In some cases, keys are bound through `evil-define-minor-mode-key` and
  may need to be translated using
  `evil-collection-translate-minor-mode-key' and/or
  `evil-collection-swap-minor-mode-key'.

  ┌────
  │ (evil-collection-swap-minor-mode-key '(normal motion)
  │   '(evil-snipe-local-mode evil-snipe-override-local-mode)
  │   "k" "s"
  │   ;; Set this to t to make this swap the keys everytime
  │   ;; this expression is evaluated.
  │   :destructive nil)
  │ 
  │ (evil-collection-translate-minor-mode-key
  │  '(normal motion)
  │  '(evil-snipe-local-mode evil-snipe-override-local-mode)
  │  "k" "s"
  │  "s" "k"
  │  ;; Set this to t to make this swap the keys everytime
  │  ;; this expression is evaluated.
  │  :destructive nil)
  └────


9 Third-party packages
══════════════════════

  Third-party packages are provided by several parties:

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Major mode  Evil bindings                
  ──────────────────────────────────────────
   ledger      [evil-ledger]                
   lispy       [lispyville] or [evil-lispy] 
   org         [org-evil] or [evil-org]     
   markdown    [evil-markdown]              
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Also `evil-collection' has minimal support (`TAB', `S-TAB' and
  sentence/paragraph forwarding) for `markdown' and `org' if you prefer
  less packages installed.

  Should you know any suitable package not mentioned in this list, let
  us know and file an issue.

  Other references:

  • [Spacemacs]
  • [Doom Emacs]


[evil-ledger] <https://github.com/atheriel/evil-ledger>

[lispyville] <https://github.com/noctuid/lispyville>

[evil-lispy] <https://github.com/sp3ctum/evil-lispy>

[org-evil] <https://github.com/GuiltyDolphin/org-evil>

[evil-org] <https://github.com/Somelauw/evil-org-mode>

[evil-markdown] <https://github.com/Somelauw/evil-markdown>

[Spacemacs]
<https://github.com/syl20bnr/spacemacs/blob/master/doc/CONVENTIONS.org#key-bindings-conventions>

[Doom Emacs]
<https://github.com/doomemacs/doomemacs/tree/master/modules/editor/evil>


10 FAQ
══════

10.1 Making SPC work similarly to [spacemacs].
──────────────────────────────────────────────

  `evil-collection' binds over SPC in many packages. To use SPC as a
  leader key with the [general] library:

  ┌────
  │ (use-package general
  │   :ensure t
  │   :init
  │   (setq general-override-states '(insert
  │                                   emacs
  │                                   hybrid
  │                                   normal
  │                                   visual
  │                                   motion
  │                                   operator
  │                                   replace))
  │   :config
  │   (general-define-key
  │    :states '(normal visual motion)
  │    :keymaps 'override
  │    "SPC" 'hydra-space/body))
  │ ;; Replace 'hydra-space/body with your leader function.
  └────

  See [noctuid's evil guide] for other approaches.

  • Unintialized mode maps in `evil-collection-setup-hook'.
    `evil-collection-setup-hook' is ran with a list of keymaps passed
    into it.  Some misconfigured modes may not have yet initialized
    their keymap at this time so the value of the variable may be
    nil. In that case, an alternative is to use a mode-hook to do any
    custom settings.

  ┌────
  │ (add-hook 'evil-collection-setup-hook
  │           (lambda (_mode keymaps)
  │             (add-hook 'ediff-mode-hook
  │                       (lambda ()
  │                         (... keymaps ...)))))
  └────

  View [196] for more info.


[spacemacs] <https://github.com/syl20bnr/spacemacs>

[general] <https://github.com/noctuid/general.el>

[noctuid's evil guide] <https://github.com/noctuid/evil-guide>

[196] <https://github.com/emacs-evil/evil-collection/issues/196>


10.2 Don't allow Evil-Collection to bind some keys.
───────────────────────────────────────────────────

  Look into `evil-collection-key-whitelist' and
  `evil-collection-key-blacklist'.

  For example:

  ┌────
  │ ;; Don't allow Evil Collection to bind to gfu and gfp.
  │ (setq evil-collection-key-blacklist '("gfu" "gfp"))
  └────


10.3 Modes left behind
──────────────────────

  Some modes might still remain unsupported by this package. Should you
  be missing your `<hjkl>', please feel free to do a pull request.


10.4 Writing a new binding
──────────────────────────

  This [yasnippet template] can be used to bootstrap a new binding.

  For example, if we were to want to add `evil-collection' support to
  `eldoc'.  (e.g.) There is a package that contains:

  ┌────
  │ (provide 'eldoc)
  └────

  Create a directory named eldoc under [modes/]. Create a file named
  evil-collection-eldoc.el under the newly created eldoc directory. Then
  use the above template as an example or, using [yasnippet],
  `yas-expand' the above template which will result in something like
  below:

  ┌────
  │ ;;; evil-collection-eldoc.el --- Bindings for `eldoc' -*- lexical-binding: t -*-
  │ 
  │ ;; Copyright (C) 2022 James Nguyen
  │ 
  │ ;; Author: James Nguyen <james@jojojames.com>
  │ ;; Maintainer: James Nguyen <james@jojojames.com>
  │ ;; URL: https://github.com/emacs-evil/evil-collection
  │ ;; Version: 0.0.2
  │ ;; Package-Requires: ((emacs "27.1"))
  │ ;; Keywords: evil, emacs, convenience, tools
  │ 
  │ ;; This program is free software; you can redistribute it and/or modify
  │ ;; it under the terms of the GNU General Public License as published by
  │ ;; the Free Software Foundation, either version 3 of the License, or
  │ ;; (at your option) any later version.
  │ 
  │ ;; This program is distributed in the hope that it will be useful,
  │ ;; but WITHOUT ANY WARRANTY; without even the implied warranty of
  │ ;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  │ ;; GNU General Public License for more details.
  │ 
  │ ;; You should have received a copy of the GNU General Public License
  │ ;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
  │ 
  │ ;;; Commentary:
  │ ;;; Bindings for eldoc.
  │ 
  │ ;;; Code:
  │ (require 'evil-collection)
  │ (require 'eldoc nil t)
  │ 
  │ (defvar eldoc-mode-map)
  │ (defconst evil-collection-eldoc-maps '(eldoc-mode-map))
  │ 
  │ (defun evil-collection-eldoc-setup ()
  │   "Set up `evil' bindings for eldoc."
  │   (evil-collection-define-key 'normal 'eldoc-mode-map
  │     ))
  │ 
  │ (provide 'evil-collection-eldoc)
  │ ;;; evil-collection-eldoc.el ends here
  └────

  Finally, add `eldoc' to `evil-collection--supported-modes'.

  ┌────
  │ (defvar evil-collection--supported-modes
  │   `(
  │     ;; ...
  │     eldoc
  │     ;; ...
  │     )
  │   "List of modes supported by evil-collection. Elements are
  │ either target mode symbols or lists which `car' is the mode
  │ symbol and `cdr' the packages to register.")
  └────


[yasnippet template]
<https://github.com/emacs-evil/evil-collection/blob/master/yasnippet_evil-collection>

[modes/]
<https://github.com/emacs-evil/evil-collection/tree/master/modes>

[yasnippet] <https://github.com/joaotavora/yasnippet>


11 Submitting Issues
════════════════════

  When reproducing issues, you can use this emacs -Q recipe.

  ┌────
  │ (setq user-emacs-directory "~/.emacs.1.d")
  │ (setq package-user-dir
  │       (format "%s/elpa/%s/" user-emacs-directory emacs-major-version))
  │ 
  │ (setq package-enable-at-startup nil
  │       package-archives
  │       '(("melpa" . "https://melpa.org/packages/")
  │         ("gnu" . "http://elpa.gnu.org/packages/")))
  │ 
  │ (require 'package)
  │ (package-initialize)
  │ (unless (package-installed-p 'use-package)
  │   (package-refresh-contents)
  │   (package-install 'use-package))
  │ (require 'use-package)
  │ (setq use-package-always-ensure t)
  │ 
  │ (use-package evil
  │   :ensure t
  │   :init
  │   (setq evil-want-keybinding nil)
  │   :config
  │   (evil-mode 1))
  │ 
  │ (use-package evil-collection
  │   :after evil
  │   :ensure t
  │   :config
  │   (evil-collection-init))
  └────


12 Contributing
═══════════════

  We welcome any additional modes that are not already supported.

  All bindings in `evil-collection' are open to change so if there's a
  better or more consistent binding, please [open an issue] or [submit a
  pull request].

  Follow [The Emacs Lisp Style Guide] for coding conventions.

  [Erlang/OTP] has a good read for helpful commit messages.


[open an issue] <https://github.com/emacs-evil/evil-collection/issues>

[submit a pull request]
<https://github.com/emacs-evil/evil-collection/pulls>

[The Emacs Lisp Style Guide]
<https://github.com/bbatsov/emacs-lisp-style-guide/>

[Erlang/OTP]
<https://github.com/erlang/otp/wiki/writing-good-commit-messages>
