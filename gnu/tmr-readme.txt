			 ━━━━━━━━━━━━━━━━━━━━━━
			      TMR MAY RING

			  Protesilaos Stavrou
			  info@protesilaos.com
			 ━━━━━━━━━━━━━━━━━━━━━━


This manual, written by Protesilaos Stavrou, describes the customization
options for `tmr' (or TMR, TMR May Ring, …), and provides every other
piece of information pertinent to it.  The name of the package is
pronounced as “timer” or “T-M-R”.

The documentation furnished herein corresponds to stable version 0.3.0,
released on 2022-05-17.  Any reference to a newer feature which does not
yet form part of the latest tagged commit, is explicitly marked as such.

Current development target is 0.4.0-dev.

⁃ Homepage: <https://protesilaos.com/emacs/tmr>.
⁃ Git repository: <https://git.sr.ht/~protesilaos/tmr>.
⁃ Mailing list: <https://lists.sr.ht/~protesilaos/tmr>.

Table of Contents
─────────────────

1. COPYING
2. Overview
.. 1. Grid view
.. 2. Hooks
.. 3. Sound and desktop notifications
3. Installation
.. 1. GNU ELPA package
.. 2. Manual installation
4. Sample configuration
5. Acknowledgements
6. GNU Free Documentation License
7. Indices
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
  using a convenient notation.  The first point of entry is the `tmr'
  command.  It prompts for a unit of time, which is represented as a
  string that consists of a number and, optionally, a single character
  suffix which specifies the unit of time.  Without a suffix, the number
  is interpreted as a count in minutes.  Valid input formats:

  ━━━━━━━━━━━━━━━━━━
   Input  Meaning   
  ──────────────────
   5      5 minutes 
   5m     5 minutes 
   5s     5 seconds 
   5h     5 hours   
  ━━━━━━━━━━━━━━━━━━

  The input can be a floating point:

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Input  Meaning                  
  ─────────────────────────────────
   1.5    1.5 minutes (90 seconds) 
   1.5h   1.5 hours (90 minutes)   
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  If `tmr' is called with an optional prefix argument (`C-u' with
  default key bindings), it asks for a description to be associated with
  the given timer.  Preconfigured candidates, as a list of strings, are
  specified in the user option `tmr-descriptions-list', though any
  arbitrary input is acceptable at the minibuffer prompt.

  An alternative to the `tmr' command is `tmr-with-description'.  The
  difference between the two is that the latter always prompts for a
  description.

  When the timer is set, a message is sent to the echo area recording
  the current time and the point in the future when the timer elapses.
  Echo area messages can be reviewed with the `view-echo-area-messages'
  which is bound to `C-h e' by default.  To check all timers, use the
  command `tmr-tabulated-view', which has more features than the generic
  `*Messages*' buffer ([Grid view]).

  The `tmr-cancel' command cancels running timers and erases them from
  the list of created timer objects.  If there is only one timer, it
  cancels it outright.  If there are multiple running timers, it
  produces a minibuffer completion prompt, asking for one among them.
  Timers at the completion prompt are described by the exact time they
  were set and the input that was used to create them, including the
  optional description that `tmr' and `tmr-with-description' accept.

  The `tmr-clone' command directly copies the duration and optional
  description of a timer into a new one.  With an optional prefix
  argument, this command prompts for a duration and, if the underlying
  timer had a description, for a description as well.  The default
  values of such prompts as those of the original timer.

  The `tmr-remove-finished' command deletes all elapsed timers from the
  list of timers.  This means that they can no longer be cloned.

  Timers have hooks associated with their creation, cancellation, and
  completion ([Hooks]).  TMR can also integrate with the desktop
  environment to send notifications ([Sound and desktop notifications]).

  TMR does not specify any global key bindings.  The user must configure
  their own ([Sample configuration]).


[Grid view] See section 2.1

[Hooks] See section 2.2

[Sound and desktop notifications] See section 2.3

[Sample configuration] See section 4

2.1 Grid view
─────────────

  Timers can be viewed in a grid with `tmr-tabulated-view'.  The data is
  placed in the `*tmr-tabulated-view*' buffer and looks like this:

  ┌────
  │ Start      End        Finished?  Description
  │ 09:22:43   09:32:43   ✔         Prepare tea
  │ 09:17:14   09:37:14              Boil water
  │ 09:07:03   09:57:03              Bake bread
  └────

  If a timer has elapsed, it has a check mark associated with it,
  otherwise the `Finished?' column is empty.  A `Description' is shown
  only if it is provided while setting the timer, otherwise the field is
  left blank.

  The `tmr-tabulated-view' command relies on Emacs’
  `tabulated-list-mode'.  From the `*tmr-tabulated-view*' buffer, invoke
  the command `describe-mode' (`C-h m' with standard key bindings) to
  learn about the applicable functionality, such as how to
  expand/contract columns and toggle their sort.

  While in this grid view, one can perform several operations on timers:

  ⁃ The `+' key creates a new timer by calling the standard `tmr'
    command.  As always, use a prefix argument to also prompt for a
    description.

  ⁃ The `c' key invokes the `tmr-tabulated-clone' command.  It is the
    same as `tmr-clone' plus some tweaks for the grid view.

  ⁃ The `k' key runs the `tmr-tabulated-cancel' command.  It immediately
    cancels the timer at point.

  ⁃ The `K' key uses `tmr-tabulated-remove-finished' to delete all
    elapsed timers.  This means that they no longer show up in the grid
    and cannot be cloned.

  ⁃ The `s' key runs the `tmr-tabulated-reschedule' command.  It
    effectively replaces the timer at point with a new one, using the
    aforementioned “cancel” and “clone” operations.  If the timer being
    rescheduled has a description, this command will also prompt for a
    description while creating the new timer, otherwise it will just ask
    for a duration.

  ⁃ The `w' key invokes the `tmr-tabulated-rewrite-description' command.
    It prompts for user input and uses it to rewrite the description of
    the timer at point.


2.2 Hooks
─────────

  TMR provides the following hooks:

  `tmr-timer-created-functions'
        This is triggered by the `tmr' command.  By default, it will
        print a message in the echo area showing the newly created
        timer’s start and end time as well as its optional description
        (if provided).

  `tmr-timer-completed-functions'
        This runs when a timer elapses.  By default, it will (i) produce
        a desktop notification which describes the timer’s start/end
        time and optional description (if available), (ii) play an alarm
        sound ([Sound and desktop notifications]), and (iii) print a
        message in the echo area which is basically the same as the
        desktop notification.

  `tmr-timer-cancelled-functions'
        This is called by `tmr-cancel'.  By default, it will print a
        message in the echo area describing the timer that was
        cancelled.


[Sound and desktop notifications] See section 2.3


2.3 Sound and desktop notifications
───────────────────────────────────

  Once the timer runs its course, it produces a desktop notification and
  plays an alarm sound.  The notification’s message is practically the
  same as that which is sent to the echo area.

  The sound file for the alarm is defined in `tmr-sound-file', while the
  urgency of the notification can be set through the user option
  `tmr-notification-urgency'.  Note that it is up to the desktop
  environment or notification daemon to decide how to handle the urgency
  value.

  If the `tmr-sound-file' is nil, or the file is not found, no sound
  will be played.

  Sound playback depends on the `ffplay' executable which is part of
  `ffmpeg'.


3 Installation
══════════════




3.1 GNU ELPA package
────────────────────

  The package is available as `tmr'.  Simply do:

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
  │ ;; set to nil to disable the sound
  │ (setq tmr-sound-file
  │       "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga")
  │ 
  │ (setq tmr-notification-urgency 'normal)
  │ (setq tmr-descriptions-list (list "Boil water" "Prepare tea" "Bake bread"))
  │ 
  │ ;; OPTIONALLY set global key bindings:
  │ (let ((map global-map))
  │   (define-key map (kbd "C-c t t") #'tmr)
  │   (define-key map (kbd "C-c t T") #'tmr-with-description)
  │   (define-key map (kbd "C-c t l") #'tmr-tabulated-view) ; "list timers" mnemonic
  │   (define-key map (kbd "C-c t c") #'tmr-clone)
  │   (define-key map (kbd "C-c t k") #'tmr-cancel)
  │   (define-key map (kbd "C-c t K") #'tmr-remove-finished))
  └────


5 Acknowledgements
══════════════════

  TMR is meant to be a collective effort.  Every bit of help matters.

  Authors
        Protesilaos Stavrou (maintainer), Damien Cassou.

  Contributions to the code or manual
        Christian Tietze, Damien Cassou, Nathan R. DeGruchy.


6 GNU Free Documentation License
════════════════════════════════


7 Indices
═════════

7.1 Function index
──────────────────


7.2 Variable index
──────────────────


7.3 Concept index
─────────────────
