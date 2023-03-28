	    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	     CORFU.EL - COMPLETION OVERLAY REGION FUNCTION
	    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


Corfu enhances completion at point with a small completion popup. The
current candidates are shown in a popup below or above the point. Corfu
is the minimalistic `completion-in-region' counterpart of the [Vertico]
minibuffer UI.

Corfu is a small package, which relies on the Emacs completion
facilities and concentrates on providing a polished completion
UI. Completions are either provided by commands like
`dabbrev-completion' or by pluggable backends
(`completion-at-point-functions', Capfs). Most programming language
major modes implement a Capf. Furthermore the language server packages,
Eglot and Lsp-mode, use Capfs which talk to the LSP server to retrieve
the completions. Corfu does not include its own completion backends. The
Emacs built-in Capfs and the Capfs provided by other programming
language packages are usually sufficient. A few additional Capfs and
completion utilities are provided by the [Cape] package.

*NOTE*: Corfu uses child frames to show the popup and falls back to the
default setting of the `completion-in-region-function' on non-graphical
displays. If you want to use Corfu in the terminal, install the package
[corfu-terminal], which provides an alternative overlay-based display.

Table of Contents
─────────────────

1. Features
2. Installation and Configuration
.. 1. Auto completion
.. 2. Completing in the minibuffer
.. 3. Completing in the Eshell or Shell
.. 4. Orderless completion
.. 5. TAB-and-Go completion
.. 6. Transfer completion to the minibuffer
3. Key bindings
4. Extensions
5. Complementary packages
6. Alternatives
7. Contributions


[Vertico] <https://github.com/minad/vertico>

[Cape] <https://github.com/minad/cape>

[corfu-terminal] <https://codeberg.org/akib/emacs-corfu-terminal>


1 Features
══════════

  • Timer-based auto-completions (/off/ by default, set `corfu-auto').
  • Popup display with scrollbar indicator and arrow key navigation.
  • The popup can be summoned explicitly by pressing `TAB' at any time.
  • The current candidate is inserted with `TAB' and selected with
    `RET'.
  • Candidates sorting by prefix, string length and alphabetically.
  • The selected candidate is previewed (configurable via
    `corfu-preview-current').
  • The selected candidate automatically committed on further input by
    default.  (configurable via `corfu-preview-current').
  • The [Orderless] completion style is supported. The filter string can
    contain arbitrary characters, after inserting a space via `M-SPC'
    (configurable via `corfu-quit-at-boundary' and `corfu-separator').
  • Deferred completion style highlighting for performance.
  • Support for candidate annotations (`annotation-function',
    `affixation-function').
  • Deprecated candidates are crossed out in the display.
  • Icons can be provided by an external package via margin formatter
    functions.
  • Rich set of extensions: Quick keys, Index keys, Sorting by history,
    Candidate documentation in echo area, popup or separate buffer


[Orderless] <https://github.com/oantolin/orderless>


2 Installation and Configuration
════════════════════════════════

  Corfu is available from [GNU ELPA], such that it can be installed
  directly via `package-install'. After installation, the global minor
  mode can be enabled with `M-x global-corfu-mode'. In order to
  configure Corfu and other packages in your init.el, you may want to
  use `use-package'.

  Corfu is highly flexible and customizable via `corfu-*' customization
  variables, such that you can adapt it precisely to your
  requirements. However in order to quickly try out the Corfu completion
  package, it should be sufficient to activate `global-corfu-mode'. You
  can experiment with manual completion for example in an Elisp buffer
  or in an Eshell or Shell buffer. For auto completion, set
  `corfu-auto=t' before turning on `global-corfu-mode'.

  Here is an example configuration:

  ┌────
  │ (use-package corfu
  │   ;; Optional customizations
  │   ;; :custom
  │   ;; (corfu-cycle t)                ;; Enable cycling for `corfu-next/previous'
  │   ;; (corfu-auto t)                 ;; Enable auto completion
  │   ;; (corfu-separator ?\s)          ;; Orderless field separator
  │   ;; (corfu-quit-at-boundary nil)   ;; Never quit at completion boundary
  │   ;; (corfu-quit-no-match nil)      ;; Never quit, even if there is no match
  │   ;; (corfu-preview-current nil)    ;; Disable current candidate preview
  │   ;; (corfu-preselect 'prompt)      ;; Preselect the prompt
  │   ;; (corfu-on-exact-match nil)     ;; Configure handling of exact matches
  │   ;; (corfu-scroll-margin 5)        ;; Use scroll margin
  │ 
  │   ;; Enable Corfu only for certain modes.
  │   ;; :hook ((prog-mode . corfu-mode)
  │   ;;        (shell-mode . corfu-mode)
  │   ;;        (eshell-mode . corfu-mode))
  │ 
  │   ;; Recommended: Enable Corfu globally.
  │   ;; This is recommended since Dabbrev can be used globally (M-/).
  │   ;; See also `corfu-exclude-modes'.
  │   :init
  │   (global-corfu-mode))
  │ 
  │ ;; A few more useful configurations...
  │ (use-package emacs
  │   :init
  │   ;; TAB cycle if there are only few candidates
  │   (setq completion-cycle-threshold 3)
  │ 
  │   ;; Emacs 28: Hide commands in M-x which do not apply to the current mode.
  │   ;; Corfu commands are hidden, since they are not supposed to be used via M-x.
  │   ;; (setq read-extended-command-predicate
  │   ;;       #'command-completion-default-include-p)
  │ 
  │   ;; Enable indentation+completion using the TAB key.
  │   ;; `completion-at-point' is often bound to M-TAB.
  │   (setq tab-always-indent 'complete))
  └────

  Dabbrev completion is based on `completion-in-region' and can be used
  with Corfu.  You may want to swap the `dabbrev-completion' with the
  `dabbrev-expand' key for easier access, if you prefer completion. Also
  take a look at the `cape-dabbrev' completion at point function
  provided by my [Cape] package.

  ┌────
  │ ;; Use Dabbrev with Corfu!
  │ (use-package dabbrev
  │   ;; Swap M-/ and C-M-/
  │   :bind (("M-/" . dabbrev-completion)
  │ 	 ("C-M-/" . dabbrev-expand))
  │   ;; Other useful Dabbrev configurations.
  │   :custom
  │   (dabbrev-ignored-buffer-regexps '("\\.\\(?:pdf\\|jpe?g\\|png\\)\\'")))
  └────

  If you start to configure the package more deeply, I recommend to give
  the Orderless completion style a try for filtering. Orderless
  completion is different from the familiar prefix TAB completion. Corfu
  can be used with the default completion styles. The use of Orderless
  is not a necessity.

  ┌────
  │ ;; Optionally use the `orderless' completion style.
  │ (use-package orderless
  │   :init
  │   ;; Configure a custom style dispatcher (see the Consult wiki)
  │   ;; (setq orderless-style-dispatchers '(+orderless-dispatch)
  │   ;;       orderless-component-separator #'orderless-escapable-split-on-space)
  │   (setq completion-styles '(orderless basic)
  │ 	completion-category-defaults nil
  │ 	completion-category-overrides '((file (styles . (partial-completion))))))
  └────

  The `basic' completion style is specified as fallback in addition to
  `orderless' in order to ensure that completion commands which rely on
  dynamic completion tables, e.g., `completion-table-dynamic' or
  `completion-table-in-turn', work correctly. See `+orderless-dispatch'
  in the [Consult wiki] for an advanced Orderless style
  dispatcher. Additionally enable `partial-completion' for file path
  expansion. `partial-completion' is important for file wildcard
  support. Multiple files can be opened at once with `find-file' if you
  enter a wildcard. You may also give the `initials' completion style a
  try.

  See also the [Corfu Wiki] and the [Cape manual] for additional Capf
  configuration tips. The Eglot and Lsp-mode configurations are
  documented in the wiki. For more general documentation read the
  chapter about completion in the [Emacs manual]. If you want to create
  your own Capfs, you can find documentation about completion in the
  [Elisp manual].


[GNU ELPA] <https://elpa.gnu.org/packages/corfu.html>

[Cape] <https://github.com/minad/cape>

[Consult wiki] <https://github.com/minad/consult/wiki>

[Corfu Wiki] <https://github.com/minad/corfu/wiki>

[Cape manual] <https://github.com/minad/cape>

[Emacs manual]
<https://www.gnu.org/software/emacs/manual/html_node/emacs/Completion.html>

[Elisp manual]
<https://www.gnu.org/software/emacs/manual/html_node/elisp/Completion.html>

2.1 Auto completion
───────────────────

  Auto completion is disabled by default, but can be enabled by setting
  `corfu-auto=t'. Furthermore you may want to configure Corfu to quit
  completion eagerly, such that the completion popup stays out of your
  way when it appeared unexpectedly.

  ┌────
  │ ;; Enable auto completion and configure quitting
  │ (setq corfu-auto t
  │       corfu-quit-no-match 'separator) ;; or t
  └────

  I recommend to experiment a bit with the various settings and key
  bindings to find a configuration which works for you. There is no one
  size fits all solution. Some people like auto completion, some like
  manual completion, some want to cycle with TAB and some with the arrow
  keys.

  In case you like aggressive auto completion settings, where the
  completion popup appears immediately, I recommend to use a cheap
  completion style like `basic', which performs prefix filtering. In
  this case Corfu completion should still be very fast in buffers with
  efficient completion backends. You can try the following settings in
  an Elisp buffer or the Emacs scratch buffer.

  ┌────
  │ ;; Aggressive completion, cheap prefix filtering.
  │ (setq-local corfu-auto t
  │ 	    corfu-auto-delay 0
  │ 	    corfu-auto-prefix 0
  │ 	    completion-styles '(basic))
  └────

  If you want to combine fast prefix filtering and Orderless filtering
  you can still do that by defining a custom Orderless completion style
  via `orderless-define-completion-style'. We use a custom style
  dispatcher, which enables prefix filtering for input shorter than 4
  characters. Note that such a setup is quite advanced. Please refer to
  the Orderless documentation and source code for further details.

  ┌────
  │ (defun orderless-fast-dispatch (word index total)
  │   (and (= index 0) (= total 1) (length< word 4)
  │        `(orderless-regexp . ,(concat "^" (regexp-quote word)))))
  │ 
  │ (orderless-define-completion-style orderless-fast
  │   (orderless-style-dispatchers '(orderless-fast-dispatch))
  │   (orderless-matching-styles '(orderless-literal orderless-regexp)))
  │ 
  │ (setq-local corfu-auto t
  │ 	    corfu-auto-delay 0
  │ 	    corfu-auto-prefix 0
  │ 	    completion-styles '(orderless-fast))
  └────


2.2 Completing in the minibuffer
────────────────────────────────

  Corfu can be used for completion in the minibuffer, since it relies on
  child frames to display the candidates. By default,
  `global-corfu-mode' does not activate `corfu-mode' in the minibuffer,
  to avoid interference with specialised minibuffer completion UIs like
  Vertico or Mct. However you may still want to enable Corfu completion
  for commands like `M-:' (`eval-expression') or `M-!'
  (`shell-command'), which read from the minibuffer. Activate
  `corfu-mode' only if `completion-at-point' is bound in the
  minibuffer-local keymap to achieve this effect.

  ┌────
  │ (defun corfu-enable-in-minibuffer ()
  │   "Enable Corfu in the minibuffer if `completion-at-point' is bound."
  │   (when (where-is-internal #'completion-at-point (list (current-local-map)))
  │     ;; (setq-local corfu-auto nil) ;; Enable/disable auto completion
  │     (setq-local corfu-echo-delay nil ;; Disable automatic echo and popup
  │ 		corfu-popupinfo-delay nil)
  │     (corfu-mode 1)))
  │ (add-hook 'minibuffer-setup-hook #'corfu-enable-in-minibuffer)
  └────

  You can also enable Corfu more generally for every minibuffer, as long
  as no completion UI is active. In the following example we check for
  Mct and Vertico.  Furthermore we ensure that Corfu is not enabled if a
  password is read from the minibuffer.

  ┌────
  │ (defun corfu-enable-always-in-minibuffer ()
  │   "Enable Corfu in the minibuffer if Vertico/Mct are not active."
  │   (unless (or (bound-and-true-p mct--active)
  │ 	      (bound-and-true-p vertico--input)
  │ 	      (eq (current-local-map) read-passwd-map))
  │     ;; (setq-local corfu-auto nil) ;; Enable/disable auto completion
  │     (setq-local corfu-echo-delay nil ;; Disable automatic echo and popup
  │ 		corfu-popupinfo-delay nil)
  │     (corfu-mode 1)))
  │ (add-hook 'minibuffer-setup-hook #'corfu-enable-always-in-minibuffer 1)
  └────


2.3 Completing in the Eshell or Shell
─────────────────────────────────────

  When completing in the Eshell I recommend conservative local settings
  without auto completion, such that the completion behavior is similar
  to widely used shells like Bash, Zsh or Fish.

  ┌────
  │ (add-hook 'eshell-mode-hook
  │ 	  (lambda ()
  │ 	    (setq-local corfu-auto nil)
  │ 	    (corfu-mode)))
  └────

  When pressing `RET' while the Corfu popup is visible, the
  `corfu-insert' command will be invoked. This command does inserts the
  currently selected candidate, but it does not send the prompt input to
  Eshell or the comint process. Therefore you often have to press `RET'
  twice which feels like an unnecessary double confirmation. Fortunately
  it is easy to improve this! In my configuration I define the advice
  `corfu-send-shell' which sends the candidate after insertion.

  ┌────
  │ (defun corfu-send-shell (&rest _)
  │   "Send completion candidate when inside comint/eshell."
  │   (cond
  │    ((and (derived-mode-p 'eshell-mode) (fboundp 'eshell-send-input))
  │     (eshell-send-input))
  │    ((and (derived-mode-p 'comint-mode)  (fboundp 'comint-send-input))
  │     (comint-send-input))))
  │ 
  │ (advice-add #'corfu-insert :after #'corfu-send-shell)
  └────

  Shell completion uses the flexible Pcomplete mechanism internally,
  which allows you to program the completions per shell command. If you
  want to know more, look into the [blog post], which shows how to
  configure Pcomplete for git commands.  Since Emacs 29, Pcomplete
  offers the `pcomplete-from-help' function which parses the `--help'
  output of a command and produces completions. This functionality is
  similar to the Fish shell, which also takes advantage of `--help' to
  dynamically generate completions.

  Unfortunately Pcomplete had a few technical issues on Emacs 28 and
  older. We can work around the issues with the [Cape] library
  (Completion at point extensions).  Cape provides wrappers which
  sanitize the Pcomplete function. If you use Emacs 28 or older
  installing these advices is strongly recommend such that Pcomplete
  works properly. On Emacs 29 the advices are not necessary anymore,
  since almost all of the related bugs have been fixed. I therefore
  recommend to remove the advices on Emacs 29 and eventually report any
  remaining Pcomplete issues upstream, such that they can be fixed at
  the root.

  ┌────
  │ ;; The advices are only needed on Emacs 28 and older.
  │ (when (< emacs-major-version 29)
  │   ;; Silence the pcomplete capf, no errors or messages!
  │   (advice-add 'pcomplete-completions-at-point :around #'cape-wrap-silent)
  │ 
  │   ;; Ensure that pcomplete does not write to the buffer
  │   ;; and behaves as a pure `completion-at-point-function'.
  │   (advice-add 'pcomplete-completions-at-point :around #'cape-wrap-purify))
  └────


[blog post]
<https://www.masteringemacs.org/article/pcomplete-context-sensitive-completion-emacs>

[Cape] <https://github.com/minad/cape>


2.4 Orderless completion
────────────────────────

  [Orderless] is an advanced completion style that supports
  multi-component search filters separated by a configurable character
  (space, by default). Normally, entering characters like space which
  lie outside the completion region boundaries (words, typically) causes
  Corfu to quit. This behavior is helpful with auto-completion, which
  may pop-up when not desired, e.g. on entering a new variable
  name. Just keep typing and Corfu will get out of the way.

  But orderless search terms can contain arbitrary characters; they are
  also interpreted as regular expressions. To use orderless, set
  `corfu-separator' (a space, by default) to the primary character of
  your orderless component separator.

  Then, when a new orderless component is desired, use `M-SPC'
  (`corfu-insert-separator') to enter the /first/ component separator in
  the input, and arbitrary orderless search terms and new separators can
  be entered thereafter.

  To treat the entire input as Orderless input, you can set the
  customization option `corfu-quit-at-boundary=t'. This disables the
  predicate which checks if the current completion boundary has been
  left. In contrast, if you /always/ want to quit at the boundary,
  simply set `corfu-quit-at-boundary=nil'. By default
  `corfu-quit-at-boundary' is set to `separator' which quits at
  completion boundaries as long as no separator has been inserted with
  `corfu-insert-separator'.

  Finally, there exists the user option `corfu-quit-no-match' which is
  set to `separator' by default. With this setting Corfu stays alive as
  soon as you start advanced filtering with a `corfu-separator' even if
  there are no matches, for example due to a typo. As long as no
  separator character has been inserted with `corfu-insert-separator',
  Corfu will still quit if there are no matches. This ensures that the
  Corfu popup goes away quickly if completion is not possible.

  In the following we show two configurations, one which works best with
  auto completion and one which may work better with manual completion
  if you prefer to always use `SPC' to separate the Orderless
  components.

  ┌────
  │ ;; Auto completion example
  │ (use-package corfu
  │   :custom
  │   (corfu-auto t)          ;; Enable auto completion
  │   ;; (corfu-separator ?_) ;; Set to orderless separator, if not using space
  │   :bind
  │   ;; Another key binding can be used, such as S-SPC.
  │   ;; (:map corfu-map ("M-SPC" . corfu-insert-separator))
  │   :init
  │   (global-corfu-mode))
  │ 
  │ ;; Manual completion example
  │ (use-package corfu
  │   :custom
  │   ;; (corfu-separator ?_) ;; Set to orderless separator, if not using space
  │   :bind
  │   ;; Configure SPC for separator insertion
  │   (:map corfu-map ("SPC" . corfu-insert-separator))
  │   :init
  │   (global-corfu-mode))
  └────


[Orderless] <https://github.com/oantolin/orderless>


2.5 TAB-and-Go completion
─────────────────────────

  You may be interested in configuring Corfu in TAB-and-Go
  style. Pressing TAB moves to the next candidate and further input will
  then commit the selection.  Note that further input will not expand
  snippets or templates, which may not be desired but which leads
  overall to a more predictable behavior. In order to force snippet
  expansion, confirm a candidate explicitly with `RET'.

  ┌────
  │ (use-package corfu
  │   ;; TAB-and-Go customizations
  │   :custom
  │   (corfu-cycle t)           ;; Enable cycling for `corfu-next/previous'
  │   (corfu-preselect 'prompt) ;; Always preselect the prompt
  │ 
  │   ;; Use TAB for cycling, default is `corfu-complete'.
  │   :bind
  │   (:map corfu-map
  │ 	("TAB" . corfu-next)
  │ 	([tab] . corfu-next)
  │ 	("S-TAB" . corfu-previous)
  │ 	([backtab] . corfu-previous))
  │ 
  │   :init
  │   (global-corfu-mode))
  └────


2.6 Transfer completion to the minibuffer
─────────────────────────────────────────

  Sometimes it is useful to transfer the Corfu completion session to the
  minibuffer, since the minibuffer offers richer interaction
  features. In particular, [Embark] is available in the minibuffer, such
  that you can act on the candidates or export/collect the candidates to
  a separate buffer. We could add Corfu support to Embark in the future,
  such that export/collect is possible directly from Corfu. But in my
  opinion having the ability to transfer the Corfu completion to the
  minibuffer is an even better feature, since further completion can be
  performed there.

  The command `corfu-move-to-minibuffer' is defined here in terms of
  `consult-completion-in-region', which uses the minibuffer completion
  UI via `completing-read'.

  ┌────
  │ (defun corfu-move-to-minibuffer ()
  │   (interactive)
  │   (let ((completion-extra-properties corfu--extra)
  │ 	completion-cycle-threshold completion-cycling)
  │     (apply #'consult-completion-in-region completion-in-region--data)))
  │ (keymap-set corfu-map "M-m" #'corfu-move-to-minibuffer)
  └────


[Embark] <https://github.com/oantolin/embark>


3 Key bindings
══════════════

  Corfu uses a transient keymap `corfu-map' which is active while the
  popup is shown. The keymap defines the following remappings and
  bindings:

  • `move-beginning-of-line' -> `corfu-prompt-beginning'
  • `move-end-of-line' -> `corfu-prompt-end'
  • `beginning-of-buffer' -> `corfu-first'
  • `end-of-buffer' -> `corfu-last'
  • `scroll-down-command' -> `corfu-scroll-down'
  • `scroll-up-command' -> `corfu-scroll-up'
  • `next-line', `down', `M-n' -> `corfu-next'
  • `previous-line', `up', `M-p' -> `corfu-previous'
  • `completion-at-point', `TAB' -> `corfu-complete'
  • `RET' -> `corfu-insert'
  • `M-g' -> `corfu-info-location'
  • `M-h' -> `corfu-info-documentation'
  • `M-SPC' -> `corfu-insert-separator'
  • `C-g' -> `corfu-quit'
  • `keyboard-escape-quit' -> `corfu-reset'


4 Extensions
════════════

  We maintain small extension packages to Corfu in this repository in
  the subdirectory [extensions/]. The extensions are installed together
  with Corfu if you pull the package from ELPA. The extensions are
  inactive by default and can be enabled manually if
  desired. Furthermore it is possible to install all of the files
  separately, both `corfu.el' and the `corfu-*.el' extensions. Currently
  the following extensions come with the Corfu ELPA package:

  • [corfu-echo]: `corfu-echo-mode' displays a brief candidate
    documentation in the echo area.
  • [corfu-history]: `corfu-history-mode' remembers selected candidates
    and sorts the candidates by their history position.
  • [corfu-indexed]: `corfu-indexed-mode' allows you to select indexed
    candidates with prefix arguments.
  • [corfu-info]: Actions to access the candidate location and
    documentation.
  • [corfu-popupinfo]: Display candidate documentation or source in a
    popup next to the candidate menu.
  • [corfu-quick]: Commands to select using Avy-style quick keys.

  See the Commentary of those files for configuration details.


[extensions/] <https://github.com/minad/corfu/tree/main/extensions>

[corfu-echo]
<https://github.com/minad/corfu/blob/main/extensions/corfu-echo.el>

[corfu-history]
<https://github.com/minad/corfu/blob/main/extensions/corfu-history.el>

[corfu-indexed]
<https://github.com/minad/corfu/blob/main/extensions/corfu-indexed.el>

[corfu-info]
<https://github.com/minad/corfu/blob/main/extensions/corfu-info.el>

[corfu-popupinfo]
<https://github.com/minad/corfu/blob/main/extensions/corfu-popupinfo.el>

[corfu-quick]
<https://github.com/minad/corfu/blob/main/extensions/corfu-quick.el>


5 Complementary packages
════════════════════════

  Corfu works well together with all packages providing code completion
  via the `completion-at-point-functions'. Many modes and packages
  already provide a Capf out of the box. Nevertheless you may want to
  look into complementary packages to enhance your setup.

  • [corfu-terminal]: The corfu-terminal package provides an
    overlay-based display for Corfu, such that you can use Corfu in
    terminal Emacs.

  • [Orderless]: Corfu supports completion styles, including the
    advanced [Orderless] completion style, where the filtering
    expressions are separated by spaces or another character (see
    `corfu-separator').

  • [Cape]: Additional Capf backends and `completion-in-region' commands
    are provided by the [Cape] package. Among others, the package
    supplies a file path and a Dabbrev completion backend. Cape provides
    the `cape-company-to-capf' adapter to reuse Company backends in
    Corfu. Furthermore the function `cape-super-capf' can merge multiple
    Capfs, such that the candidates of multiple Capfs are displayed
    together at the same time.

  • [kind-icon]: Icons are supported by Corfu via an external
    package. For example the [kind-icon] package provides beautifully
    styled SVG icons based on monochromatic icon sets like material
    design.

  • [Tempel]: Tiny template/snippet package with templates in Lisp
    syntax, which can be used in conjunction with Corfu.

  • [Vertico]: You may also want to look into my [Vertico]
    package. Vertico is the minibuffer completion counterpart of Corfu.


[corfu-terminal] <https://codeberg.org/akib/emacs-corfu-terminal>

[Orderless] <https://github.com/oantolin/orderless>

[Cape] <https://github.com/minad/cape>

[kind-icon] <https://github.com/jdtsmith/kind-icon>

[Tempel] <https://github.com/minad/tempel>

[Vertico] <https://github.com/minad/vertico>


6 Alternatives
══════════════

  • [Company]: Company is a widely used and mature completion package,
    which implements a similar interaction model and popup UI as
    Corfu. While Corfu relies exclusively on the standard Emacs
    completion API (Capfs), Company defines its own API for the
    backends. Company includes its completion backends, which are
    incompatible with the Emacs completion infrastructure. As a result
    of this design, Company is a more complex package than
    Corfu. Company by default uses overlays for the popup in contrast to
    the child frames used by Corfu. Overall both packages work well, but
    Company integrates less tightly with Emacs. The `completion-styles'
    support is more limited and the `completion-at-point' command and
    the `completion-in-region' function do not invoke Company.

  • [consult-completion-in-region]: The Consult package provides the
    function `consult-completion-in-region' which can be set as
    `completion-in-region-function' such that it handles
    `completion-at-point'. The function works by transferring the
    in-buffer completion to the minibuffer. In the minibuffer, the
    minibuffer completion UI, for example [Vertico] takes over. If you
    prefer to perform all your completions in the minibuffer
    `consult-completion-in-region' is your best option.


[Company] <https://github.com/company-mode/company-mode>

[consult-completion-in-region] <https://github.com/minad/consult>

[Vertico] <https://github.com/minad/vertico>


7 Contributions
═══════════════

  Since this package is part of [GNU ELPA] contributions require a
  copyright assignment to the FSF.


[GNU ELPA] <https://elpa.gnu.org/packages/corfu.html>
