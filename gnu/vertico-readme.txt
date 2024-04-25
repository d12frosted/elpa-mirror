             ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              VERTICO.EL - VERTICAL INTERACTIVE COMPLETION
             ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


Vertico provides a performant and minimalistic vertical completion UI
based on the default completion system. The focus of Vertico is to
provide a UI which behaves /correctly/ under all circumstances. By
reusing the built-in facilities system, Vertico achieves /full
compatibility/ with built-in Emacs completion commands and completion
tables. Vertico only provides the completion UI but aims to be highly
flexible, extendable and modular. Additional enhancements are available
as [extensions] or [complementary packages]. The code base is small and
maintainable. The main `vertico.el' package is only about 600 lines of
code without white space and comments.

Table of Contents
─────────────────

1. Features
2. Installation
3. Key bindings
4. Configuration
.. 1. Completion styles and TAB completion
.. 2. Completion-at-point and completion-in-region
5. Extensions
.. 1. Configure Vertico per command or completion category
6. Complementary packages
7. Child frames and Popups
8. Alternatives
9. Resources
10. Contributions
11. Debugging Vertico
12. Problematic completion commands
.. 1. `org-refile'
.. 2. `org-agenda-filter' and `org-tags-view'
.. 3. `tmm-menubar'
.. 4. `ffap-menu'
.. 5. `completion-table-dynamic'
.. 6. Submitting the empty string
.. 7. Tramp hostname and username completion


[extensions] See section 5

[complementary packages] See section 6


1 Features
══════════

  • Vertical display with arrow key navigation. Many additional display
    modes are provided as [extensions].
  • Prompt shows the current candidate index and the total number of
    candidates.
  • The current candidate is inserted with `TAB' and selected with
    `RET'.
  • Non-existing candidates can be submitted with `M-RET' or by moving
    the point to the prompt.
  • Efficient sorting by history position, length and alphabetically.
  • Long candidates with newlines are formatted to take up less space.
  • Lazy completion candidate highlighting for performance.
  • Annotations are displayed next to the candidates (`annotation-' and
    `affixation-function').
  • Support for candidate grouping and group cycling commands
    (`group-function').

  <https://github.com/minad/vertico/blob/screenshots/vertico-mx.png?raw=true>


[extensions] See section 5


2 Installation
══════════════

  Vertico is available from [GNU ELPA]. You can install it directly via
  `M-x package-install RET vertico RET'.  After installation, activate
  the global minor mode with `M-x vertico-mode RET'.


[GNU ELPA] <https://elpa.gnu.org/packages/vertico.html>


3 Key bindings
══════════════

  Vertico defines its own local keymap in the minibuffer which is
  derived from `minibuffer-local-map'. The keymap keeps most of the
  `fundamental-mode' keybindings intact and remaps and binds only a
  handful of commands.

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Binding/Remapping                                        Vertico command          
  ───────────────────────────────────────────────────────────────────────────────────
   `beginning-of-buffer', `minibuffer-beginning-of-buffer'  `vertico-first'          
   `end-of-buffer'                                          `vertico-last'           
   `scroll-down-command'                                    `vertico-scroll-down'    
   `scroll-up-command'                                      `vertico-scroll-up'      
   `next-line', `next-line-or-history-element'              `vertico-next'           
   `previous-line', `previous-line-or-history-element'      `vertico-previous'       
   `forward-paragraph'                                      `vertico-next-group'     
   `backward-paragraph'                                     `vertico-previous-group' 
   `exit-minibuffer'                                        `vertico-exit'           
   `kill-ring-save'                                         `vertico-save'           
   `M-RET'                                                  `vertico-exit-input'     
   `TAB'                                                    `vertico-insert'         
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Note in particular the binding of `TAB' to `vertico-insert', which
  inserts the currently selected candidate, and the binding of `RET' and
  `M-RET' to `vertico-exit' and `vertico-exit-input' respectively.

  `vertico-exit' exits with the currently selected candidate, while
  `vertico-exit-input' exits with the minibuffer input instead. Exiting
  with the current input is needed when you want to create a new buffer
  or a new file with `find-file' or `switch-to-buffer'. As an
  alternative to pressing `M-RET', move the selection up to the input
  prompt by pressing the `up' arrow key and then press `RET'.


4 Configuration
═══════════════

  In order to configure Vertico and other packages in your init.el, you
  may want to take advantage of `use-package'. Here is an example
  configuration:

  ┌────
  │ ;; Enable vertico
  │ (use-package vertico
  │   :init
  │   (vertico-mode)
  │ 
  │   ;; Different scroll margin
  │   ;; (setq vertico-scroll-margin 0)
  │ 
  │   ;; Show more candidates
  │   ;; (setq vertico-count 20)
  │ 
  │   ;; Grow and shrink the Vertico minibuffer
  │   ;; (setq vertico-resize t)
  │ 
  │   ;; Optionally enable cycling for `vertico-next' and `vertico-previous'.
  │   ;; (setq vertico-cycle t)
  │   )
  │ 
  │ ;; Persist history over Emacs restarts. Vertico sorts by history position.
  │ (use-package savehist
  │   :init
  │   (savehist-mode))
  │ 
  │ ;; A few more useful configurations...
  │ (use-package emacs
  │   :init
  │   ;; Add prompt indicator to `completing-read-multiple'.
  │   ;; We display [CRM<separator>], e.g., [CRM,] if the separator is a comma.
  │   (defun crm-indicator (args)
  │     (cons (format "[CRM%s] %s"
  │ 		  (replace-regexp-in-string
  │ 		   "\\`\\[.*?]\\*\\|\\[.*?]\\*\\'" ""
  │ 		   crm-separator)
  │ 		  (car args))
  │ 	  (cdr args)))
  │   (advice-add #'completing-read-multiple :filter-args #'crm-indicator)
  │ 
  │   ;; Do not allow the cursor in the minibuffer prompt
  │   (setq minibuffer-prompt-properties
  │ 	'(read-only t cursor-intangible t face minibuffer-prompt))
  │   (add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)
  │ 
  │   ;; Support opening new minibuffers from inside existing minibuffers.
  │   (setq enable-recursive-minibuffers t)
  │ 
  │   ;; Emacs 28 and newer: Hide commands in M-x which do not work in the current
  │   ;; mode.  Vertico commands are hidden in normal buffers. This setting is
  │   ;; useful beyond Vertico.
  │   (setq read-extended-command-predicate #'command-completion-default-include-p))
  └────

  I recommend to give Orderless completion a try, which is different
  from the prefix TAB completion used by the basic default completion
  system or in shells.

  ┌────
  │ ;; Optionally use the `orderless' completion style.
  │ (use-package orderless
  │   :init
  │   ;; Configure a custom style dispatcher (see the Consult wiki)
  │   ;; (setq orderless-style-dispatchers '(+orderless-consult-dispatch orderless-affix-dispatch)
  │   ;;       orderless-component-separator #'orderless-escapable-split-on-space)
  │   (setq completion-styles '(orderless basic)
  │ 	completion-category-defaults nil
  │ 	completion-category-overrides '((file (styles partial-completion)))))
  └────

  The `basic' completion style is specified as fallback in addition to
  `orderless' in order to ensure that completion commands which rely on
  dynamic completion tables, e.g., `completion-table-dynamic' or
  `completion-table-in-turn', work correctly. See the [Consult wiki] for
  my advanced Orderless configuration with style
  dispatchers. Additionally enable `partial-completion' for file path
  expansion. `partial-completion' is important for file wildcard support
  in `find-file'. In order to open multiple files with a wildcard at
  once, you have to submit the prompt with `M-RET'. Alternative first
  move to the prompt and then press `RET'.

  See also the [Vertico Wiki] for additional configuration tips. For
  more general documentation read the chapter about completion in the
  [Emacs manual]. If you want to create your own completion commands,
  you can find documentation about completion in the [Elisp manual].


[Consult wiki]
<https://github.com/minad/consult/wiki#minads-orderless-configuration>

[Vertico Wiki] <https://github.com/minad/vertico/wiki>

[Emacs manual]
<https://www.gnu.org/software/emacs/manual/html_node/emacs/Completion.html>

[Elisp manual]
<https://www.gnu.org/software/emacs/manual/html_node/elisp/Completion.html>

4.1 Completion styles and TAB completion
────────────────────────────────────────

  The bindings of the `minibuffer-local-completion-map' are not
  available in Vertico by default. This means that `TAB' works
  differently from what you may expect from shells like Bash or the
  default Emacs completion system. In Vertico `TAB' inserts the
  currently selected candidate.

  If you prefer to have the default completion commands available you
  can add new bindings or even replace the Vertico bindings. For example
  you can use `M-TAB' to expand the prefix of candidates (TAB complete)
  or cycle between candidates if `completion-cycle-threshold' is
  non-nil.

  ┌────
  │ ;; Option 1: Additional bindings
  │ (keymap-set vertico-map "?" #'minibuffer-completion-help)
  │ (keymap-set vertico-map "M-RET" #'minibuffer-force-complete-and-exit)
  │ (keymap-set vertico-map "M-TAB" #'minibuffer-complete)
  │ 
  │ ;; Option 2: Replace `vertico-insert' to enable TAB prefix expansion.
  │ ;; (keymap-set vertico-map "TAB" #'minibuffer-complete)
  └────

  The `orderless' completion style does not support expansion of a
  common candidate prefix, as supported by shells or the basic default
  completion system. The reason is that the Orderless input string is
  usually not a prefix. In order to support completing prefixes, combine
  `orderless' with `substring' in your `completion-styles'
  configuration.

  ┌────
  │ (setq completion-styles '(substring orderless basic))
  └────

  Alternatively you can use the built-in completion-styles, e.g.,
  `partial-completion', `flex' or `initials'. The `partial-completion'
  style is important if you want to open multiple files at once with
  `find-file' using wildcards. In order to open multiple files with a
  wildcard at once, you have to submit the prompt with
  `M-RET'. Alternative first move to the prompt and then press `RET'.

  ┌────
  │ (setq completion-styles '(basic substring partial-completion flex))
  └────

  Because Vertico is fully compatible with Emacs default completion
  system, further customization of completion behavior can be achieved
  by setting the designated Emacs variables. For example, one may wish
  to disable case-sensitivity for file and buffer matching when built-in
  completion styles are used instead of `orderless':

  ┌────
  │ (setq read-file-name-completion-ignore-case t
  │       read-buffer-completion-ignore-case t
  │       completion-ignore-case t)
  └────


4.2 Completion-at-point and completion-in-region
────────────────────────────────────────────────

  The tab completion command `completion-at-point' command is usually
  bound to `M-TAB' or `TAB'. Tab completion is also used in the
  minibuffer by `M-:' (`eval-expression').  In case you want to use
  Vertico to show the completion candidates of `completion-at-point' and
  `completion-in-region', you can use the function
  `consult-completion-in-region' provided by the Consult package.

  ┌────
  │ ;; Use `consult-completion-in-region' if Vertico is enabled.
  │ ;; Otherwise use the default `completion--in-region' function.
  │ (setq completion-in-region-function
  │       (lambda (&rest args)
  │ 	(apply (if vertico-mode
  │ 		   #'consult-completion-in-region
  │ 		 #'completion--in-region)
  │ 	       args)))
  └────

  You may also want to look into my [Corfu] package, which provides a
  minimal completion system for `completion-in-region' in a child frame
  popup. Corfu is a narrowly focused package and developed in the same
  spirit as Vertico. You can even use Corfu in the minibuffer.


[Corfu] <https://github.com/minad/corfu>


5 Extensions
════════════

  We maintain small extension packages to Vertico in this repository in
  the subdirectory [extensions/]. The extensions are installed together
  with Vertico if you pull the package from ELPA. The extensions are
  inactive by default and can be enabled manually if
  desired. Furthermore it is possible to install all of the files
  separately, both `vertico.el' and the `vertico-*.el'
  extensions. Currently the following extensions come with the Vertico
  ELPA package:

  • [vertico-buffer]: `vertico-buffer-mode' to display Vertico like a
    regular buffer.
  • [vertico-directory]: Commands for Ido-like directory navigation.
  • [vertico-flat]: `vertico-flat-mode' to enable a flat, horizontal
    display.
  • [vertico-grid]: `vertico-grid-mode' to enable a grid display.
  • [vertico-indexed]: `vertico-indexed-mode' to select indexed
    candidates with prefix arguments.
  • [vertico-mouse]: `vertico-mouse-mode' to support for scrolling and
    candidate selection.
  • [vertico-multiform]: Configure Vertico modes per command or
    completion category.
  • [vertico-quick]: Commands to select using Avy-style quick keys.
  • [vertico-repeat]: The command `vertico-repeat' repeats the last
    completion session.
  • [vertico-reverse]: `vertico-reverse-mode' to reverse the display.
  • [vertico-suspend]: The command `vertico-suspend' suspends and
    restores the current session.
  • [vertico-unobtrusive]: `vertico-unobtrusive-mode' displays only the
    topmost candidate.

  See the commentary of those files for configuration details. With
  these extensions it is possible to adapt Vertico such that it matches
  your preference or behaves similar to other familiar UIs. For example,
  the combination `vertico-flat' plus `vertico-directory' resembles Ido
  in look and feel. For an interface similar to Helm, the extension
  `vertico-buffer' allows you to configure freely where the completion
  buffer opens, instead of growing the minibuffer.  Furthermore
  `vertico-buffer' will adjust the number of displayed candidates
  according to the buffer height.

  Configuration example for `vertico-directory':

  ┌────
  │ ;; Configure directory extension.
  │ (use-package vertico-directory
  │   :after vertico
  │   :ensure nil
  │   ;; More convenient directory navigation commands
  │   :bind (:map vertico-map
  │ 	      ("RET" . vertico-directory-enter)
  │ 	      ("DEL" . vertico-directory-delete-char)
  │ 	      ("M-DEL" . vertico-directory-delete-word))
  │   ;; Tidy shadowed file names
  │   :hook (rfn-eshadow-update-overlay . vertico-directory-tidy))
  └────


[extensions/] <https://github.com/minad/vertico/tree/main/extensions>

[vertico-buffer]
<https://github.com/minad/vertico/blob/main/extensions/vertico-buffer.el>

[vertico-directory]
<https://github.com/minad/vertico/blob/main/extensions/vertico-directory.el>

[vertico-flat]
<https://github.com/minad/vertico/blob/main/extensions/vertico-flat.el>

[vertico-grid]
<https://github.com/minad/vertico/blob/main/extensions/vertico-grid.el>

[vertico-indexed]
<https://github.com/minad/vertico/blob/main/extensions/vertico-indexed.el>

[vertico-mouse]
<https://github.com/minad/vertico/blob/main/extensions/vertico-mouse.el>

[vertico-multiform]
<https://github.com/minad/vertico/blob/main/extensions/vertico-multiform.el>

[vertico-quick]
<https://github.com/minad/vertico/blob/main/extensions/vertico-quick.el>

[vertico-repeat]
<https://github.com/minad/vertico/blob/main/extensions/vertico-repeat.el>

[vertico-reverse]
<https://github.com/minad/vertico/blob/main/extensions/vertico-reverse.el>

[vertico-suspend]
<https://github.com/minad/vertico/blob/main/extensions/vertico-suspend.el>

[vertico-unobtrusive]
<https://github.com/minad/vertico/blob/main/extensions/vertico-unobtrusive.el>

5.1 Configure Vertico per command or completion category
────────────────────────────────────────────────────────

  <https://github.com/minad/vertico/blob/screenshots/vertico-ripgrep.png?raw=true>

  Vertico offers the `vertico-multiform-mode' which allows you to
  configure Vertico per command or per completion category. The
  `vertico-buffer-mode' enables a Helm-like buffer display, which takes
  more space but also displays more candidates. This verbose display
  mode is useful for commands like `consult-imenu' or `consult-outline'
  since the buffer display allows you to get a better overview over the
  entire current buffer. But for other commands you want to keep using
  the default Vertico display. `vertico-multiform-mode' solves this
  configuration problem.

  ┌────
  │ ;; Enable vertico-multiform
  │ (vertico-multiform-mode)
  │ 
  │ ;; Configure the display per command.
  │ ;; Use a buffer with indices for imenu
  │ ;; and a flat (Ido-like) menu for M-x.
  │ (setq vertico-multiform-commands
  │       '((consult-imenu buffer indexed)
  │ 	(execute-extended-command unobtrusive)))
  │ 
  │ ;; Configure the display per completion category.
  │ ;; Use the grid display for files and a buffer
  │ ;; for the consult-grep commands.
  │ (setq vertico-multiform-categories
  │       '((file grid)
  │ 	(consult-grep buffer)))
  └────

  Temporary toggling between the different display modes is
  possible. The following commands are bound by default in the
  `vertico-multiform-map'. You can of course change these bindings if
  you like.

  • `M-B' -> `vertico-multiform-buffer'
  • `M-F' -> `vertico-multiform-flat'
  • `M-G' -> `vertico-multiform-grid'
  • `M-R' -> `vertico-multiform-reverse'
  • `M-U' -> `vertico-multiform-unobtrusive'
  • `M-V' -> `vertico-multiform-vertical'

  For special configuration you can use your own functions or even
  lambdas to configure the completion behavior per command or per
  completion category.  Functions must have the calling convention of a
  mode, i.e., take a single argument, which is either 1 to turn on the
  mode and -1 to turn off the mode.

  ┌────
  │ ;; Configure `consult-outline' as a scaled down TOC in a separate buffer
  │ (setq vertico-multiform-commands
  │       `((consult-outline buffer ,(lambda (_) (text-scale-set -1)))))
  └────

  Furthermore you can tune buffer-local settings per command or
  category.

  ┌────
  │ ;; Change the default sorting function.
  │ ;; See `vertico-sort-function' and `vertico-sort-override-function'.
  │ (setq vertico-multiform-commands
  │       '((describe-symbol (vertico-sort-function . vertico-sort-alpha))))
  │ 
  │ (setq vertico-multiform-categories
  │       '((symbol (vertico-sort-function . vertico-sort-alpha))
  │ 	(file (vertico-sort-function . sort-directories-first))))
  │ 
  │ ;; Sort directories before files
  │ (defun sort-directories-first (files)
  │   (setq files (vertico-sort-history-length-alpha files))
  │   (nconc (seq-filter (lambda (x) (string-suffix-p "/" x)) files)
  │ 	 (seq-remove (lambda (x) (string-suffix-p "/" x)) files)))
  └────

  Combining these features allows us to fine-tune the completion display
  even more by adjusting the `vertico-buffer-display-action'. We can for
  example reuse the current window for commands of the `consult-grep'
  category (`consult-grep', `consult-git-grep' and
  `consult-ripgrep'). Note that this configuration is incompatible with
  Consult preview, since the previewed buffer is usually shown in
  exactly this window. Nevertheless this snippet demonstrates the
  flexibility of the configuration system.

  ┌────
  │ ;; Configure the buffer display and the buffer display action
  │ (setq vertico-multiform-categories
  │       '((consult-grep
  │ 	 buffer
  │ 	 (vertico-buffer-display-action . (display-buffer-same-window)))))
  │ 
  │ ;; Disable preview for consult-grep commands
  │ (consult-customize consult-ripgrep consult-git-grep consult-grep :preview-key nil)
  └────

  As another example, the following code uses `vertico-flat' and
  `vertico-cycle' to emulate `(ido-mode 'buffer)', i.e., Ido when it is
  enabled only for completion of buffer names. `vertico-cycle' set to
  `t' is necessary here to prevent completion candidates from
  disappearing when they scroll off-screen to the left.

  ┌────
  │ (setq vertico-multiform-categories
  │       '((buffer flat (vertico-cycle . t))))
  └────


6 Complementary packages
════════════════════════

  Vertico integrates well with complementary packages, which enrich the
  completion UI. These packages are fully supported:

  • [Marginalia]: Rich annotations in the minibuffer
  • [Consult]: Useful search and navigation commands
  • [Embark]: Minibuffer actions and context menu
  • [Orderless]: Advanced completion style

  In order to get accustomed with the package ecosystem, I recommend the
  following quick start approach:

  1. Start with plain Emacs (`emacs -Q').
  2. Install and enable Vertico to get incremental minibuffer
     completion.
  3. Install Orderless and/or configure the built-in completion styles
     for more flexible minibuffer filtering.
  4. Install Marginalia if you like rich minibuffer annotations.
  5. Install Embark and add two keybindings for `embark-dwim' and
     `embark-act'.  I am using the mnemonic keybindings `M-.' and `C-.'
     since these commands allow you to act on the object at point or in
     the minibuffer.
  6. Install Consult if you want additional featureful completion
     commands, e.g., the buffer switcher `consult-buffer' with preview
     or the line-based search `consult-line'.
  7. Install Embark-Consult and Wgrep for export from `consult-line' to
     `occur-mode' buffers and from `consult-grep' to editable
     `grep-mode' buffers.
  8. Fine tune Vertico with [extensions].

  The ecosystem is modular. You don't have to use all of these
  components. Use only the ones you like and the ones which fit well
  into your setup. The steps 1.  to 4. introduce no new commands over
  plain Emacs. Step 5. introduces the new commands `embark-act' and
  `embark-dwim'. In step 6. you get the Consult commands, some offer new
  functionality not present in Emacs already (e.g., `consult-line') and
  some are substitutes (e.g., `consult-buffer' for `switch-to-buffer').


[Marginalia] <https://github.com/minad/marginalia>

[Consult] <https://github.com/minad/consult>

[Embark] <https://github.com/oantolin/embark>

[Orderless] <https://github.com/oantolin/orderless>

[extensions] See section 5


7 Child frames and Popups
═════════════════════════

  An often requested feature is the ability to display the completions
  in a child frame popup. Personally I am critical of using child frames
  for minibuffer completion. From my experience it introduces more
  problems than it solves. Most importantly child frames hide the
  content of the underlying buffer. Furthermore child frames do not play
  well together with changing windows and entering recursive minibuffer
  sessions. On top, child frames can feel slow and sometimes flicker. A
  better alternative is the `vertico-buffer' display which can even be
  configured individually per command using `vertico-multiform'. On the
  plus side of child frames, the completion display appears at the
  center of the screen, where your eyes are focused. Please give the
  following packages a try and judge for yourself.

  • [mini-frame]: Display the entire minibuffer in a child frame.
  • [mini-popup]: Slightly simpler alternative to mini-frame.
  • [vertico-posframe]: Display only the Vertico minibuffer in a child
    frame using the posframe library.


[mini-frame] <https://github.com/muffinmad/emacs-mini-frame>

[mini-popup] <https://github.com/minad/mini-popup>

[vertico-posframe] <https://github.com/tumashu/vertico-posframe>


8 Alternatives
══════════════

  There are many alternative completion UIs, each UI with its own
  advantages and disadvantages.

  Vertico aims to be 100% compliant with all Emacs commands and achieves
  that with a minimal code base, relying purely on `completing-read'
  while avoiding to invent its own APIs. Inventing a custom API as Helm
  or Ivy is explicitly avoided in order to increase flexibility and
  package reuse. Due to its small code base and reuse of the Emacs
  built-in facilities, bugs and compatibility issues are less likely to
  occur in comparison to completion UIs or monolithic completion
  systems.

  Since Vertico only provides the UI, you may want to combine it with
  some of the complementary packages, to give a full-featured completion
  experience similar to Helm or Ivy. The idea is to have smaller
  independent components, which one can add and understand step by
  step. Each component focuses on its niche and tries to be as
  non-intrusive as possible. Vertico targets users interested in
  crafting their Emacs precisely to their liking - completion plays an
  integral part in how the users interacts with Emacs.

  There are other interactive completion UIs, which follow a similar
  philosophy:

  • [Mct]: Minibuffer and Completions in Tandem. Mct reuses the default
    `*Completions*' buffer and enhances it with automatic updates and
    additional keybindings, to select a candidate and move between
    minibuffer and completions buffer. Since Mct uses a fully functional
    buffer you can use familiar buffer commands inside the completions
    buffer. The main distinction to Vertico's approach is that
    `*Completions*' buffer displays all matching candidates. This has
    the advantage that you can interact freely with the candidates and
    jump around with Isearch or Avy. On the other hand it necessarily
    causes a slowdown.
  • [Selectrum]: Selectrum is the predecessor of Vertico has been
    deprecated in favor of Vertico. Read the [migration guide] when
    migrating from Selectrum.  Vertico was designed specifically to
    address the technical shortcomings of Selectrum. Selectrum is not
    fully compatible with every Emacs completion command and dynamic
    completion tables, since it uses its own filtering infrastructure,
    which deviates from the standard Emacs completion facilities.
  • Icomplete: Emacs 28 comes with a builtin `icomplete-vertical-mode',
    which is a more bare-bone than Vertico. Vertico offers additional
    flexibility thanks to its [extensions].


[Mct] <https://git.sr.ht/~protesilaos/mct>

[Selectrum] <https://github.com/radian-software/selectrum>

[migration guide]
<https://github.com/minad/vertico/wiki/Migrating-from-Selectrum-to-Vertico>

[extensions] See section 5


9 Resources
═══════════

  If you want to learn more about Vertico and minibuffer completion,
  check out the following resources:

  • Configurations which use Vertico and Corfu for completion:
    ⁃ [Doom Emacs Vertico Module]
    ⁃ [Crafted Emacs Completion Module]
    ⁃ [Prot's Emacs configuration]
  • Videos:
    ⁃ [Emacs Completion Explained] (2022-07-19) by Andrew Tropin.
    ⁃ [Emacs Minibuffer Completions] (2022-02-12) by Greg Yut.
    ⁃ [Vertico Extensions for Emacs] (2022-01-08) by Karthik
      Chikmagalur.
    ⁃ [Using Emacs Episode 80 - Vertico, Marginalia, Consult and Embark]
      (2021-10-26) by Mike Zamansky.
    ⁃ [System Crafters Live! - Replacing Ivy and Counsel with Vertico
      and Consult] (2021-05-21) by David Wilson.
    ⁃ [Streamline Your Emacs Completions with Vertico] (2021-05-17) by
      David Wilson.
    ⁃ [Modern Emacs: all those new tools that make Emacs better and
      faster] (2024-03-06) by Marie-Hélène Burle.


[Doom Emacs Vertico Module]
<https://github.com/doomemacs/doomemacs/tree/master/modules/completion/vertico>

[Crafted Emacs Completion Module]
<https://github.com/SystemCrafters/crafted-emacs/blob/master/modules/crafted-completion.el>

[Prot's Emacs configuration]
<https://git.sr.ht/~protesilaos/dotfiles/tree/master/item/emacs/.emacs.d/>

[Emacs Completion Explained]
<https://www.youtube.com/watch?v=fnE0lXoe7Y0>

[Emacs Minibuffer Completions]
<https://www.youtube.com/watch?v=w9hHMDyF9V4>

[Vertico Extensions for Emacs]
<https://www.youtube.com/watch?v=hPwDbx--Waw>

[Using Emacs Episode 80 - Vertico, Marginalia, Consult and Embark]
<https://youtu.be/5ffb2at2d7w>

[System Crafters Live! - Replacing Ivy and Counsel with Vertico and
Consult] <https://www.youtube.com/watch?v=UtqE-lR2HCA>

[Streamline Your Emacs Completions with Vertico]
<https://www.youtube.com/watch?v=J0OaRy85MOo>

[Modern Emacs: all those new tools that make Emacs better and faster]
<https://www.youtube.com/watch?v=SOxlQ7ogplA&t=1952s>


10 Contributions
════════════════

  Since this package is part of [GNU ELPA] contributions require a
  copyright assignment to the FSF.


[GNU ELPA] <https://elpa.gnu.org/packages/vertico.html>


11 Debugging Vertico
════════════════════

  When you observe an error in the `vertico--exhibit' post command hook,
  you should install an advice to enforce debugging. This allows you to
  obtain a stack trace in order to narrow down the location of the
  error. The reason is that post command hooks are automatically
  disabled (and not debugged) by Emacs. Otherwise Emacs would become
  unusable, given that the hooks are executed after every command.

  ┌────
  │ (setq debug-on-error t)
  │ 
  │ (defun force-debug (func &rest args)
  │   (condition-case e
  │       (apply func args)
  │     ((debug error) (signal (car e) (cdr e)))))
  │ 
  │ (advice-add #'vertico--exhibit :around #'force-debug)
  └────


12 Problematic completion commands
══════════════════════════════════

  Vertico is robust in most scenarios. However some completion commands
  make certain assumptions about the completion styles and the
  completion UI. Some of these assumptions may not hold in Vertico or
  other UIs and require minor workarounds.


12.1 `org-refile'
─────────────────

  `org-refile' uses `org-olpath-completing-read' to complete the outline
  path in steps, when `org-refile-use-outline-path' is non-nil.

  Unfortunately the implementation of this Org completion table assumes
  that the `basic' completion style is used. The table is incompatible
  with completion styles like `substring', `flex' or `orderless'. In
  order to fix the issue at the root, the completion table should make
  use of completion boundaries similar to the built-in file completion
  table. In your user configuration you can prioritize `basic' before
  `orderless'.

  ┌────
  │ ;; Alternative 1: Use the basic completion style
  │ (setq org-refile-use-outline-path 'file
  │       org-outline-path-complete-in-steps t)
  │ 
  │ (advice-add #'org-olpath-completing-read :around #'vertico-enforce-basic-completion)
  │ 
  │ (defun vertico-enforce-basic-completion (&rest args)
  │   (minibuffer-with-setup-hook
  │       (:append
  │        (lambda ()
  │ 	 (let ((map (make-sparse-keymap)))
  │ 	   (define-key map [tab] #'minibuffer-complete)
  │ 	   (use-local-map (make-composed-keymap (list map) (current-local-map))))
  │ 	 (setq-local completion-styles (cons 'basic completion-styles)
  │ 		     vertico-preselect 'prompt)))
  │     (apply args)))
  └────

  Alternatively you may want to disable the outline path completion in
  steps. The completion on the full path can be quicker since the input
  string matches directly against substrings of the full path, which is
  useful with Orderless.  However the list of possible completions
  becomes much more cluttered.

  ┌────
  │ ;; Alternative 2: Complete full paths
  │ (setq org-refile-use-outline-path 'file
  │       org-outline-path-complete-in-steps nil)
  └────


12.2 `org-agenda-filter' and `org-tags-view'
────────────────────────────────────────────

  Similar to `org-refile', the commands `org-agenda-filter' and
  `org-tags-view' do not make use of completion boundaries. The internal
  completion tables are `org-agenda-filter-completion-function' and
  `org-tags-completion-function'.  Unfortunately `TAB' completion
  (`minibuffer-complete') does not work for this reason with arbitrary
  completion styles like `substring', `flex' or `orderless'. This
  affects Vertico and also the Emacs default completion system. For
  example if you enter `+tag<0 TAB' the input is replaced with `0:10'
  which is not correct. With preserved completion boundaries, the
  expected result would be `+tag<0:10'. Completion boundaries are used
  for example by file completion, where each part of the path can be
  completed separately. Ideally this issue would be fixed in Org.

  ┌────
  │ (advice-add #'org-make-tags-matcher :around #'vertico-enforce-basic-completion)
  │ (advice-add #'org-agenda-filter :around #'vertico-enforce-basic-completion)
  └────


12.3 `tmm-menubar'
──────────────────

  The text menu bar works well with Vertico but always shows a
  `*Completions*' buffer, which is unwanted if you use the Vertico
  UI. This completion buffer can be disabled with an advice. If you
  disabled the standard GUI menu bar and prefer the Vertico interface
  you may also overwrite the default F10 keybinding.

  ┌────
  │ (keymap-global-set "<f10>" #'tmm-menubar)
  │ (advice-add #'tmm-add-prompt :after #'minibuffer-hide-completions)
  └────


12.4 `ffap-menu'
────────────────

  The command `ffap-menu' shows the `*Completions*' buffer by default
  like `tmm-menubar', which is unnecessary with Vertico. This completion
  buffer can be disabled as follows.

  ┌────
  │ (advice-add #'ffap-menu-ask :around
  │ 	    (lambda (&rest args)
  │ 	      (cl-letf (((symbol-function #'minibuffer-completion-help)
  │ 			 #'ignore))
  │ 		(apply args))))
  └────


12.5 `completion-table-dynamic'
───────────────────────────────

  Dynamic completion tables (`completion-table-dynamic',
  `completion-table-in-turn', …) should work well with Vertico. The only
  requirement is that the `basic' completion style is enabled. The
  `basic' style performs prefix filtering by passing the input to the
  completion table (or the dynamic completion table function). The
  `basic' completion style must not necessarily be configured with
  highest priority, it can also come after other completion styles like
  `orderless', `substring' or `flex', as is also recommended by the
  Orderless documentation because of `completion-table-dynamic'.

  ┌────
  │ (setq completion-styles '(basic))
  │ ;; (setq completion-styles '(orderless basic))
  │ (completing-read "Dynamic: "
  │ 		 (completion-table-dynamic
  │ 		  (lambda (str)
  │ 		    (list (concat str "1")
  │ 			  (concat str "2")
  │ 			  (concat str "3")))))
  └────


12.6 Submitting the empty string
────────────────────────────────

  The commands `multi-occur', `auto-insert', `bbdb-create' read multiple
  arguments from the minibuffer with `completing-read', one at a time,
  until you submit an empty string. You should type `M-RET'
  (`vertico-exit-input') to finish the loop. Directly pressing `RET'
  (`vertico-exit') does not work since the first candidate is
  preselected.

  The underlying issue is that `completing-read' always allows you to
  exit with the empty string, which is called the /null completion/,
  even if the `REQUIRE-MATCH' argument is non-nil. Try the following two
  calls to `completing-read' with `C-x C-e':

  ┌────
  │ (completing-read "Select: " '("first" "second" "third") nil 'require-match)
  │ (completing-read "Select: " '("first" "second" "third") nil 'require-match nil nil "")
  └────

  In both cases the empty string can be submitted. In the first case no
  explicit default value is specified and Vertico preselects the *first*
  candidate. In order to exit with the empty string, press `M-RET'. In
  the second case the explicit default value "" is specified and Vertico
  preselects the prompt, such that exiting with the empty string is
  possible by pressing `RET' only.


12.7 Tramp hostname and username completion
───────────────────────────────────────────

  *NOTE:* On upcoming Emacs 29.2 and Tramp 2.6.1.5 the workarounds
  described in this section are not necessary anymore, since the
  relevant completion tables have been improved.

  In combination with Orderless or other non-prefix completion styles
  like `substring' or `flex', host names and user names are not made
  available for completion after entering `/ssh:'. In order to avoid
  this problem, the `basic' completion style should be specified for the
  file completion category, such that `basic' is tried before
  `orderless'. This can be achieved by putting `basic' first in the
  completion style overrides for the file completion category.

  ┌────
  │ (setq completion-styles '(orderless basic)
  │       completion-category-defaults nil
  │       completion-category-overrides '((file (styles basic partial-completion))))
  └────

  If you are familiar with the `completion-style' machinery, you may
  also define a custom completion style which activates only for remote
  files. The custom completion style ensures that you can always match
  substrings within non-remote file names, since `orderless' will stay
  the preferred style for non-remote files.

  ┌────
  │ (defun basic-remote-try-completion (string table pred point)
  │   (and (vertico--remote-p string)
  │        (completion-basic-try-completion string table pred point)))
  │ (defun basic-remote-all-completions (string table pred point)
  │   (and (vertico--remote-p string)
  │        (completion-basic-all-completions string table pred point)))
  │ (add-to-list
  │  'completion-styles-alist
  │  '(basic-remote basic-remote-try-completion basic-remote-all-completions nil))
  │ (setq completion-styles '(orderless basic)
  │       completion-category-defaults nil
  │       completion-category-overrides '((file (styles basic-remote partial-completion))))
  └────
