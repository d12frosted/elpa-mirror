	    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	     CURSORY.EL: MANAGE CURSOR STYLES USING PRESETS

			  Protesilaos Stavrou
			  info@protesilaos.com
	    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


This manual, written by Protesilaos Stavrou, describes the customization
options for `cursory' (or `cursory.el'), and provides every other piece
of information pertinent to it.

The documentation furnished herein corresponds to stable version 0.1.0,
released on 2022-04-21.  Any reference to a newer feature which does not
yet form part of the latest tagged commit, is explicitly marked as such.

Current development target is 0.2.0-dev.

⁃ Homepage: <https://protesilaos.com/emacs/cursory>.
⁃ Git repository: <https://git.sr.ht/~protesilaos/cursory>.
⁃ Mailing list: <https://lists.sr.ht/~protesilaos/cursory>.

Table of Contents
─────────────────

1. COPYING
2. Overview
3. Installation
4. GNU ELPA package
.. 1. Manual installation
5. Sample configuration
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

  Cursory provides a thin wrapper around built-in variables that affect
  the style of the Emacs cursor.  The intent is to allow the user to
  define preset configurations such as “block with slow blinking” or
  “bar with fast blinking” and set them on demand.

  Users can define their preferences in the option `cursory-presets'.
  The command `cursory-set-preset' can then be used to select one such
  style.  Selection uses minibuffer completion.

  The function `cursory-store-latest-preset' can be used to save the
  last selected style in the `cursory-latest-state-file'.  The value can
  then be restored with the `cursory-restore-latest-preset' function.


3 Installation
══════════════


4 GNU ELPA package
══════════════════

  The package is available as `cursory'.  Simply do:

  ┌────
  │ M-x package-refresh-contents
  │ M-x package-install
  └────


  And search for it.


4.1 Manual installation
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
  │ # Clone this repo, naming it "cursory"
  │ git clone https://git.sr.ht/~protesilaos/cursory cursory
  └────

  Finally, in your `init.el' (or equivalent) evaluate this:

  ┌────
  │ ;; Make Elisp files in that directory available to the user.
  │ (add-to-list 'load-path "~/.emacs.d/manual-packages/cursory")
  └────

  Everything is in place to set up the package.


5 Sample configuration
══════════════════════

  Remember to read the doc string of each of these variables or
  functions.

  ┌────
  │ (require 'cursory)
  │ 
  │ (setq cursory-presets
  │       '((bar . ( :cursor-type (bar . 2)
  │ 		 :cursor-in-non-selected-windows hollow
  │ 		 :blink-cursor-blinks 10
  │ 		 :blink-cursor-interval 0.5
  │ 		 :blink-cursor-delay 0.2))
  │ 
  │ 	(box  . ( :cursor-type box
  │ 		  :cursor-in-non-selected-windows hollow
  │ 		  :blink-cursor-blinks 10
  │ 		  :blink-cursor-interval 0.5
  │ 		  :blink-cursor-delay 0.2))
  │ 
  │ 	(underscore . ( :cursor-type (hbar . 3)
  │ 			:cursor-in-non-selected-windows hollow
  │ 			:blink-cursor-blinks 50
  │ 			:blink-cursor-interval 0.2
  │ 			:blink-cursor-delay 0.2))))
  │ 
  │ (setq cursory-latest-state-file (locate-user-emacs-file "cursory-latest-state"))
  │ 
  │ (cursory-restore-latest-preset)
  │ 
  │ ;; Set `cursory-recovered-preset' or fall back to desired style from
  │ ;; `cursory-presets'.
  │ (if cursory-recovered-preset
  │     (cursory-set-preset cursory-recovered-preset)
  │   (cursory-set-preset 'bar))
  │ 
  │ ;; The other side of `cursory-restore-latest-preset'.
  │ (add-hook 'kill-emacs-hook #'cursory-store-latest-preset)
  │ 
  │ ;; We have to use the "point" mnemonic, because C-c c is often the
  │ ;; suggested binding for `org-capture'.
  │ (define-key global-map (kbd "C-c p") #'cursory-set-preset)
  └────


6 Acknowledgements
══════════════════

  Cursory is meant to be a collective effort.  Every bit of help
  matters.

  Author/maintainer
        Protesilaos Stavrou.

  Contributions to the code or manual
        Philip Kaludercic, Stefan Monnier.


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
