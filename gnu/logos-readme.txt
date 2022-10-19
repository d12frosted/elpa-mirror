	   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	    LOGOS.EL: SIMPLE FOCUS MODE FOR EMACS WITH PAGE
			   BREAKS OR OUTLINES

			  Protesilaos Stavrou
			  info@protesilaos.com
	   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


This manual, written by Protesilaos Stavrou, describes the customization
options for `logos' (or `logos.el'), and provides every other piece of
information pertinent to it.

The documentation furnished herein corresponds to stable version 1.0.0,
released on 2022-10-19.  Any reference to a newer feature which does not
yet form part of the latest tagged commit, is explicitly marked as such.

Current development target is 1.1.0-dev.

⁃ Package name (GNU ELPA): `logos'
⁃ Official manual: <https://protesilaos.com/emacs/logos>
⁃ Change log: <https://protesilaos.com/emacs/logos-changelog>
⁃ Git repo on SourceHut: <https://git.sr.ht/~protesilaos/logos>
  • Mirrors:
    ⁃ GitHub: <https://github.com/protesilaos/logos>
    ⁃ GitLab: <https://gitlab.com/protesilaos/logos>
⁃ Mailing list: <https://lists.sr.ht/~protesilaos/logos>
⁃ Backronyms: `^L' Only Generates Ostensible Slides; Logos Optionally
  Goes through Outline Sections

Table of Contents
─────────────────

1. COPYING
2. Overview
3. Installation
.. 1. GNU ELPA package
.. 2. Manual installation
4. Sample configuration
5. Extra tweaks
.. 1. Center the buffer in its window
.. 2. Make EWW look like the rest of Emacs
.. 3. Automatically reveal Org or Outline subtree
.. 4. Recenter at the top upon page motion
.. 5. Use outlines and page breaks
.. 6. Leverage logos-focus-mode-extra-functions
..... 1. Conditionally toggle org-indent-mode
..... 2. Disable menu-bar and tool-bar
.. 7. Update fringe color on theme switch
6. Acknowledgements
7. GNU Free Documentation License
8. Indices
.. 1. Function index
.. 2. Variable index
.. 3. Concept index


1 COPYING
═════════

  Copyright (C) 2022 Free Software Foundation, Inc.

        Permission is granted to copy, distribute and/or modify
        this document under the terms of the GNU Free
        Documentation License, Version 1.3 or any later version
        published by the Free Software Foundation; with no
        Invariant Sections, with the Front-Cover Texts being “A
        GNU Manual,” and with the Back-Cover Texts as in (a)
        below.  A copy of the license is included in the section
        entitled “GNU Free Documentation License.”

        (a) The FSF’s Back-Cover Text is: “You have the freedom to
        copy and modify this GNU manual.”


2 Overview
══════════

  This package provides a simple “focus mode” which can be applied to
  any buffer for reading, writing, or even doing a presentation.  The
  buffer can be divided in pages using the `page-delimiter', outline
  structure, or any other pattern.  Commands are provided to move
  between those pages.  These motions work even when narrowing is in
  effect (and they preserve it).  `logos.el' is designed to be simple by
  default and easy to extend.  This manual provides concrete examples to
  that end.

  What constitutes a page delimiter is determined by the user options
  `logos-outlines-are-pages' and `logos-outline-regexp-alist'.  By
  default, this only corresponds to the `^L' character (which can be
  inserted using the standard keys with `C-q C-l').

  Logos does not define any key bindings.  Try something like this, if
  you want:

  ┌────
  │ (let ((map global-map))
  │   (define-key map [remap narrow-to-region] #'logos-narrow-dwim)
  │   (define-key map [remap forward-page] #'logos-forward-page-dwim)
  │   (define-key map [remap backward-page] #'logos-backward-page-dwim))
  └────

  On standard Emacs, those key bindings are: `C-x n n', `C-x ]', `C-x
  ['.  The `logos-narrow-dwim' is not necessary for users who already
  know how to narrow effectively.  Such users may still want to bind it
  to a key.

  For users running Emacs version 28 or higher, Logos defines the
  `logos-repeat-map' which is activated when `repeat-mode' is enabled.
  This means that page motions, `C-x ]' and `C-x [', can be repeated by
  following them up with either `]' or `['.  The repetition stops when
  another command is invoked.

  Logos provides some optional aesthetic tweaks which come into effect
  when the buffer-local `logos-focus-mode' is enabled.  These will hide
  the cursor (`logos-hide-cursor'), hide the mode line
  (`logos-hide-mode-line'), disable the buffer boundary indicators
  (`indicate-buffer-boundaries'), enable `scroll-lock-mode'
  (`logos-scroll-lock'), use `variable-pitch-mode' in non-programming
  buffers (`logos-variable-pitch'), make the buffer read-only
  (`logos-buffer-read-only'), center the buffer in its window if the
  `olivetti' package is installed (`logos-olivetti'), and hide the
  `fringe' face (`logos-hide-fringe').  All these variables are
  buffer-local.

  Furthermore, the `logos-focus-mode' establishes a bespoke keymap,
  which can be used to, for example, bind the arrow keys to page
  motions.  The keymap is `logos-focus-mode-map' and is empty by default
  (we do not define any keys and trust the user to pick their own).

  Logos is the familiar word derived from Greek (watch my presentation
  on philosophy about Cosmos, Logos, and the living universe:
  <https://protesilaos.com/books/2022-02-05-cosmos-logos-living-universe/>),
  though it also stands for these two perhaps equally insightful
  backronyms about the mechanics of this package:

  1. `^L' Only Generates Ostensible Slides
  2. Logos Optionally Goes through Outline Sections


3 Installation
══════════════




3.1 GNU ELPA package
────────────────────

  The package is available as `logos'.  Simply do:

  ┌────
  │ M-x package-refresh-contents
  │ M-x package-install
  └────


  And search for it.

  GNU ELPA provides the latest stable release.  Those who prefer to
  follow the development process in order to report bugs or suggest
  changes, can use the version of the package from the GNU-devel ELPA
  archive.  Read:
  <https://protesilaos.com/codelog/2022-05-13-emacs-elpa-devel/>.


3.2 Manual installation
───────────────────────

  Assuming your Emacs files are found in `~/.emacs.d/', execute the
  following commands in a shell prompt:

  ┌────
  │ cd ~/.emacs.d
  │ 
  │ # Create a directory for manually-installed packages
  │ mkdir manual-packages
  │ 
  │ # Go to the new directory
  │ cd manual-packages
  │ 
  │ # Clone this repo, naming it "logos"
  │ git clone https://git.sr.ht/~protesilaos/logos logos
  └────

  Finally, in your `init.el' (or equivalent) evaluate this:

  ┌────
  │ ;; Make Elisp files in that directory available to the user.
  │ (add-to-list 'load-path "~/.emacs.d/manual-packages/logos")
  └────

  Everything is in place to set up the package.


4 Sample configuration
══════════════════════

  Logos does not bind its own keys and does not make any opinionated
  changes out-of-the-box ([Extra tweaks]):

  ⁃ To get the do-what-I-mean page motions add your own key bindings.
    In the example below, they take the stead of `forward-page' (`C-x
    ]') and `backward-page' (`C-x [').  The command `logos-narrow-dwim'
    need not be bound, especially if you are already familiar with the
    various narrowing commands (otherwise it maps to `C-x n n' in this
    example, assuming the default keys).

  ⁃ To have quick access to `logos-focus-mode', bind it to a key.  This
    mode checks the variables `logos-hide-cursor',
    `logos-hide-mode-line', `logos-scroll-lock', `logos-variable-pitch',
    `logos-hide-buffer-boundaries', `logos-buffer-read-only',
    `logos-olivetti' (requires `olivetti' package) and applies their
    effects if they are non-nil.  Note that everything is buffer-local,
    so it is possible to use file variables as described in the Emacs
    manual.

  ┌────
  │ (require 'logos)
  │ 
  │ ;; If you want to use outlines instead of page breaks (the ^L):
  │ (setq logos-outlines-are-pages t)
  │ 
  │ ;; This is the default value for the outlines:
  │ (setq logos-outline-regexp-alist
  │       `((emacs-lisp-mode . "^;;;+ ")
  │ 	(org-mode . "^\\*+ +")
  │ 	(markdown-mode . "^\\#+ +")))
  │ 
  │ ;; These apply when `logos-focus-mode' is enabled.  Their value is
  │ ;; buffer-local.
  │ (setq-default logos-hide-cursor nil
  │ 	      logos-hide-mode-line t
  │ 	      logos-hide-buffer-boundaries t
  │ 	      logos-hide-fringe t
  │ 	      logos-variable-pitch nil
  │ 	      logos-buffer-read-only nil
  │ 	      logos-scroll-lock nil
  │ 	      logos-olivetti nil)
  │ 
  │ ;; Also check this manual for `logos-focus-mode-extra-functions'.  It is
  │ ;; a hook that lets you extend `logos-focus-mode'.
  │ 
  │ (let ((map global-map))
  │   (define-key map [remap narrow-to-region] #'logos-narrow-dwim)
  │   (define-key map [remap forward-page] #'logos-forward-page-dwim)
  │   (define-key map [remap backward-page] #'logos-backward-page-dwim)
  │   (define-key map (kbd "<f9>") #'logos-focus-mode))
  │ 
  │ ;; Also consider adding keys to `logos-focus-mode-map'.  They will take
  │ ;; effect when `logos-focus-mode' is enabled.
  └────


[Extra tweaks] See section 5


5 Extra tweaks
══════════════

  This section contains snippets of code that extend the functionality
  of `logos'.  These either apply to `logos-focus-mode' or enhance the
  page motions through the `logos-page-motion-hook'.


5.1 Center the buffer in its window
───────────────────────────────────

  Install the excellent `olivetti' package by Paul W. Rankin.  Then set
  `logos-olivetti' to non-nil.

  The present author’s favourite settings given a `fill-column' of `72':

  ┌────
  │ (setq olivetti-body-width 0.7
  │       olivetti-minimum-body-width 80
  │       olivetti-recall-visual-line-mode-entry-state t)
  └────

  Though note that Olivetti works well even without a `fill-column' and
  `auto-fill-mode' disabled.


5.2 Make EWW look like the rest of Emacs
────────────────────────────────────────

  By default, all `M-x eww' buffers use the `shr-max-width' which is set
  to 120 characters.  This is above the standard value of `fill-column'
  and thus does not let text flow nicely while using `olivetti' package
  ([Center the buffer in its window]).

  For a general customization, the user can evaluate this:

  ┌────
  │ (setq shr-max-width fill-column)
  └────

  EWW buffers also default to `variable-pitch' typography by default (as
  opposed to whatever the font family of the `default' face is).  This
  too can be made consistent with the rest of Emacs:

  ┌────
  │ (setq shr-use-fonts nil)
  └────

  [ For font-related customizations check the `fontaine' package on GNU
    ELPA (by Protesilaos). ]

  Note that all variables with the `shr-' prefix are about the built-in
  Simple HTML Renderer, so they will affect any other package that
  relies on them beside EWW (in principle, the aforementioned should not
  pose any problem).


[Center the buffer in its window] See section 5.1


5.3 Automatically reveal Org or Outline subtree
───────────────────────────────────────────────

  The Logos page motions normally jump between positions.  Though Org
  and Outline require that Logos also reveals the headings’ contents.
  This is necessary to avoid invisible motions inside a folded heading
  that contains subheadings.  The unfolding only applies to the current
  entry.  This is the relevant snippet from `logos.el':

  ┌────
  │ (defun logos--reveal-entry ()
  │   "Reveal Org or Outline entry."
  │   (cond
  │    ((and (eq major-mode 'org-mode)
  │ 	 (org-at-heading-p))
  │     (org-show-entry))
  │    ((or (eq major-mode 'outline-mode)
  │ 	(bound-and-true-p outline-minor-mode))
  │     (outline-show-entry))))
  │ 
  │ (add-hook 'logos-page-motion-hook #'logos--reveal-entry)
  └────

  Users may prefer to reveal the entire subtree instead of the current
  entry: the heading at point and all of its subheadings.  In this case,
  one may override the definition of `logos--reveal-entry':

  ┌────
  │ ;; glue code to expand an Org/Outline heading
  │ (defun logos--reveal-entry ()
  │   "Reveal Org or Outline entry."
  │   (cond
  │    ((and (eq major-mode 'org-mode)
  │ 	 (org-at-heading-p))
  │     (org-show-subtree))
  │    ((or (eq major-mode 'outline-mode)
  │ 	(bound-and-true-p outline-minor-mode))
  │     (outline-show-subtree))))
  └────


5.4 Recenter at the top upon page motion
────────────────────────────────────────

  Page motions normally reposition the point at the centre of the window
  if necessary (this is standard Emacs behaviour).  To always change the
  placement invoke the `recenter' function with a numeric argument.

  ┌────
  │ ;; place point at the top when changing pages
  │ (defun my-logos--recenter-top ()
  │   "Use `recenter' to reposition the view at the top."
  │   (recenter 0))
  │ 
  │ (add-hook 'logos-page-motion-hook #'my-logos--recenter-top)
  └────

  The `0' argument refers to the topmost line.  So `1' points to the
  line below and so on.

  If the recentering should not affect specific modes, tweak the
  function accordingly:

  ┌────
  │ (defvar my-logos-no-recenter-top-modes 
  │   '(emacs-lisp-mode lisp-interaction-mode))
  │ 
  │ (defun my-logos--recenter-top ()
  │   "Use `recenter' to reposition the view at the top."
  │   (unless (memq major-mode my-logos-no-recenter-top-modes)
  │     (recenter 0)))
  └────

  Or simply exclude all programming modes:

  ┌────
  │ (defun my-logos--recenter-top ()
  │   "Use `recenter' to reposition the view at the top."
  │   (unless (derived-mode-p 'prog-mode)
  │     (recenter 0)))
  └────


5.5 Use outlines and page breaks
────────────────────────────────

  By default, the page motions only move between the `^L' delimiters.
  While the option `logos-outlines-are-pages' changes the behaviour to
  move between outline headings instead.  What constitutes an “outline
  heading” is determined by the `logos-outline-regexp-alist' with an
  automatic fallback to either `outline-regexp' or `page-delimiter'
  (Logos handles this fallback condition internally).

  Provided this:

  ┌────
  │ (setq logos-outlines-are-pages t)
  └────

  The default value of `logos-outline-regexp-alist' will affect
  `org-mode', `emacs-lisp-mode', and any of their derivatives
  (e.g. `lisp-interaction-mode' (the standard scratch buffer) is based
  on `emacs-lisp-mode').  Its fallback value is whatever the major mode
  sets as an outline, else the standard `^L'.

  ┌────
  │ (setq logos-outline-regexp-alist
  │       `((emacs-lisp-mode . "^;;;+ ")
  │ 	(org-mode . "^\\*+ +")))
  └────

  It is possible to tweak those regular expressions to target both the
  outline and the page delimiters:

  ┌────
  │ (setq logos-outline-regexp-alist
  │       `((emacs-lisp-mode . ,(format "\\(^;;;+ \\|%s\\)" (default-value 'page-delimiter)))
  │ 	(org-mode . ,(format "\\(^\\*+ +\\|%s\\)" (default-value 'page-delimiter)))))
  └────

  The form `,(format "\\(^;;;+ \\|%s\\)" logos--page-delimiter)' expands
  to `"\\(^;;;+ \\|^\\)"'.

  For Org it may be better to either not target the `^L' or to also
  target the horizontal rule (five hyphens on a line, else the
  `^-\\{5\\}$' pattern).  Putting it all together:

  ┌────
  │ (setq logos-outline-regexp-alist
  │       `((emacs-lisp-mode . ,(format "\\(^;;;+ \\|%s\\)" logos--page-delimiter))
  │ 	(org-mode . ,(format "\\(^\\*+ +\\|^-\\{5\\}$\\|%s\\)" logos--page-delimiter))))
  └────

  Another Org-specific tweak is to use heading levels up to a specific
  number.  The idea would be that anything below that number is not
  significant.  For example, `^\\* +' only applies to top-level
  headings, while `^\\*\\{1,3\\} +' covers heading levels 1 through 3.
  Accounting for the aforementiond horizontal rule and generic page
  delimiter, the end result can look like this:

  ┌────
  │ (setq logos-outline-regexp-alist
  │       `((emacs-lisp-mode . ,(format "\\(^;;;+ \\|%s\\)" logos--page-delimiter))
  │ 	(org-mode . ,(format "\\(^\\*\\{1,3\\} +\\|^-\\{5\\}$\\|%s\\)" logos--page-delimiter))))
  └────


5.6 Leverage logos-focus-mode-extra-functions
─────────────────────────────────────────────

  The `logos-focus-mode-extra-functions' is a normal hook that runs when
  `logos-focus-mode' is enabled.  Each function is run without an
  argument and looks like those in `logos.el'.  An example that sets a
  variable is `logos--buffer-read-only'; one that sets a mode is
  `logos--scroll-lock'; another that sets the mode of an external
  package is `logos--olivetti'; while `logos--hide-fringe' provides yet
  another useful sample.

  If a function cannot be like the aforementioned though still needs to
  set its state both when `logos-focus-mode' is enabled and disabled,
  then use the `logos-focus-mode-hook' instead.


5.6.1 Conditionally toggle org-indent-mode
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Here is a snippet that relies on `logos-focus-mode-extra-functions' to
  extend the functionality of `logos-focus-mode' at the user level
  ([Leverage logos-focus-mode-extra-functions]).

  ┌────
  │ (defvar my-logos-org-indent nil
  │   "When t, disable `org-indent-mode' during `logos-focus-mode'.")
  │ 
  │ (defun my-logos-org-indent ()
  │   "Set `my-logos-org-indent' in `logos-focus-mode'."
  │   (when my-logos-org-indent
  │     ;; Disable `org-indent-mode' when `logos-focus-mode' is enabled and
  │     ;; restore it when `logos-focus-mode' is disabled.  The
  │     ;; `logos--mode' function takes care of the technicalities.
  │     (logos--mode 'org-indent-mode -1)))
  │ 
  │ (add-hook 'logos-focus-mode-extra-functions #'my-logos-org-indent)
  └────

  The `my-logos-org-indent' variable lets the user opt in and out of
  this feature, by setting it to t or nil, respectively.  If such a
  toggle is not needed, the following will suffice:

  ┌────
  │ (defun my-logos-org-indent ()
  │   "Set `my-logos-org-indent' in `logos-focus-mode'."
  │   ;; Disable `org-indent-mode' when `logos-focus-mode' is enabled and
  │   ;; restore it when `logos-focus-mode' is disabled.  The
  │   ;; `logos--mode' function takes care of the technicalities.
  │   (logos--mode 'org-indent-mode -1))
  │ 
  │ (add-hook 'logos-focus-mode-extra-functions #'my-logos-org-indent)
  └────


[Leverage logos-focus-mode-extra-functions] See section 5.6


5.6.2 Disable menu-bar and tool-bar
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Continuing with the examples in this section of the manual, this is
  how to disable the `menu-bar-mode' and `tool-bar-mode' when activating
  the `logos-focus-mode'.

  ┌────
  │ ;; Assuming the `menu-bar-mode' is enabled by default...
  │ (defun my-logos-hide-menu-bar ()
  │   (logos--mode 'menu-bar-mode -1))
  │ 
  │ (add-hook 'logos-focus-mode-extra-functions #'my-logos-hide-menu-bar)
  │ 
  │ ;; Assuming the `tool-bar-mode' is enabled by default...
  │ (defun my-logos-hide-tool-bar ()
  │   (logos--mode 'tool-bar-mode -1))
  │ 
  │ (add-hook 'logos-focus-mode-extra-functions #'my-logos-hide-tool-bar)
  └────

  If those modes are already disabled, the following have no effect.
  Otherwise they toggle the bars off while `logos-focus-mode' is enabled
  and then restore them back on when `logos-focus-mode' is disabled.


5.7 Update fringe color on theme switch
───────────────────────────────────────

  The user option `logos-hide-fringe' does not actually remove the
  fringe, as that would change the user’s preference for `fringe-mode'.
  Instead, it remaps its background color to be the same as that of the
  `default' face.  For example, if the main background is white while
  the fringe is gray, the fringe will become white as well.

  The problem with this approach is that the color is not automatically
  updated upon switching to a new theme, such as by toggling between one
  with a light background to another with a dark one.  The solution is
  to assign the `logos-update-fringe-in-buffers' function to a hook that
  is triggered by the theme-loading operation.

  Some themes provide such a hook.  For example, the `modus-themes'
  package has the `modus-themes-after-load-theme-hook' (the themes
  `modus-operandi' and `modus-vivendi' are built into Emacs version 28
  or higher).

  ┌────
  │ (add-hook 'modus-themes-after-load-theme-hook #'logos-update-fringe-in-buffers)
  └────

  A user-defined, theme-agnostic setup for such a hook can be configured
  thus:

  ┌────
  │ (defvar after-enable-theme-hook nil
  │   "Normal hook run after enabling a theme.")
  │ 
  │ (defun run-after-enable-theme-hook (&rest _args)
  │   "Run `after-enable-theme-hook'."
  │   (run-hooks 'after-enable-theme-hook))
  │ 
  │ (advice-add 'enable-theme :after #'run-after-enable-theme-hook)
  └────

  Then use it like this:

  ┌────
  │ (add-hook 'after-enable-theme-hook #'logos-update-fringe-in-buffers)
  └────


6 Acknowledgements
══════════════════

  Logos is meant to be a collective effort.  Every bit of help matters.

  Author/maintainer
        Protesilaos Stavrou.

  Contributions to code or the manual
        Daniel Mendler, Lucy McPhail, Omar Antolín Camarena, Philip
        Kaludercic, Remco van ’t Veer, and user Ypot.

  Ideas and/or user feedback
        Daniel Mendler, Marcel Ventosa, Xiaoduan, Ypot.


7 GNU Free Documentation License
════════════════════════════════


8 Indices
═════════

8.1 Function index
──────────────────


8.2 Variable index
──────────────────


8.3 Concept index
─────────────────
