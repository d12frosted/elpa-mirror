			 ━━━━━━━━━━━━━━━━━━━━━━
			    TMR MUST RECCUR

			  Protesilaos Stavrou
			  info@protesilaos.com
			 ━━━━━━━━━━━━━━━━━━━━━━


This manual, written by Protesilaos Stavrou, describes the customization
options for `tmr' (or `tmr.el', tmr, TMR, …), and provides every other
piece of information pertinent to it.

The documentation furnished herein corresponds to stable version 0.2.0,
released on 2022-04-21.  Any reference to a newer feature which does not
yet form part of the latest tagged commit, is explicitly marked as such.

Current development target is 0.3.0-dev.

⁃ Homepage: <https://protesilaos.com/emacs/tmr>
⁃ Git repository: <https://git.sr.ht/~protesilaos/tmr>.
⁃ Mailing list: <https://lists.sr.ht/~protesilaos/tmr>.

Table of Contents
─────────────────

1. COPYING
2. Overview
3. Installation
.. 1. Manual installation
4. Sample configuration
5. GNU Free Documentation License
6. Indices
.. 1. Function index
.. 2. Variable index
.. 3. Concept index


1 COPYING
═════════

  Copyright (C) 2021-2022 Free Software Foundation, Inc.

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

  TMR is an Emacs package that provides facilities for setting timers
  using a convenient notation.  The point of entry is the `tmr' command.
  It prompts for a unit of time, which is represented as a string that
  consists of a number and, optionally, a single character suffix which
  specifies the unit of time.  Valid input formats:

  ━━━━━━━━━━━━━━━━━━
   Input  Meaning   
  ──────────────────
   5      5 minutes 
   5m     5 minutes 
   5s     5 seconds 
   5h     5 hours   
  ━━━━━━━━━━━━━━━━━━

  If `tmr' is called with an optional prefix argument (`C-u'), it also
  asks for a description which accompanies the given timer.
  Preconfigured candidates are specified in the user option
  `tmr-descriptions-list', though any arbitrary input is acceptable at
  the minibuffer prompt.

  When the timer is set, a message is sent to the echo area recording
  the current time and the point in the future when the timer elapses.
  Echo area messages can be reviewed with the `view-echo-area-messages'
  which is bound to `C-h e' by default.  Though TMR provides its own
  buffer for reviewing its log: it is named `*tmr-messages*' and can be
  accessed with the command `tmr-view-echo-area-messages'.

  Once the timer runs its course, it produces a desktop notification and
  plays an alarm sound.  The notification’s message is practically the
  same as that which is sent to the echo area.  The sound file for the
  alarm is defined in `tmr-sound-file', while the urgency of the
  notification can be set through the `tmr-notification-urgency' option.
  Note that it is up to the desktop environment or notification daemon
  to decide how to handle the urgency value.

  The `tmr-cancel' command is used to cancel running timers (as set by
  the `tmr' command).  If there is only one timer, it cancels it
  outright.  If there are multiple timers, it produces a minibuffer
  completion prompt which asks for one among them.  Timers at the
  completion prompt are described by the exact time they were set and
  the input that was used to create them, including the optional
  description that `tmr' accepts.


3 Installation
══════════════




3.1 Manual installation
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
  │ # Clone this repo, naming it "tmr"
  │ git clone https://git.sr.ht/~protesilaos/tmr tmr
  └────

  Finally, in your `init.el' (or equivalent) evaluate this:

  ┌────
  │ ;; Make Elisp files in that directory available to the user.
  │ (add-to-list 'load-path "~/.emacs.d/manual-packages/tmr")
  └────

  Everything is in place to set up the package.


4 Sample configuration
══════════════════════

  ┌────
  │ ;; Load the `tmr' library
  │ (require 'tmr)
  │ 
  │ ;; OPTIONALLY set global key bindings:
  │ (let ((map global-map))
  │   (define-key map (kbd "C-c t t") #'tmr)
  │   (define-key map (kbd "C-c t e") #'tmr-view-echo-area-messages) ; "e" to remind of C-h e
  │   (define-key map (kbd "C-c t c") #'tmr-cancel))
  │ 
  │ ;; Also check the user options `tmr-sound-file',
  │ ;; `tmr-notification-urgency' `tmr-descriptions-list'.
  └────


5 GNU Free Documentation License
════════════════════════════════


6 Indices
═════════

6.1 Function index
──────────────────


6.2 Variable index
──────────────────


6.3 Concept index
─────────────────
