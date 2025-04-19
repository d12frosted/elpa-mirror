                         ━━━━━━━━━━━━━━━━━━━━━━
                              TMR MAY RING

                          Protesilaos Stavrou
                          info@protesilaos.com
                         ━━━━━━━━━━━━━━━━━━━━━━


This manual, written by Protesilaos Stavrou, describes the customization
options for `tmr' (or TMR, TMR May Ring, …), and provides every other
piece of information pertinent to it.  The name of the package is
pronounced as “timer” or “T-M-R”.

The documentation furnished herein corresponds to stable version 1.1.0,
released on 2025-04-18.  Any reference to a newer feature which does not
yet form part of the latest tagged commit, is explicitly marked as such.

Current development target is 1.2.0-dev.

⁃ Package name (GNU ELPA): `tmr'
⁃ Official manual: <https://protesilaos.com/emacs/tmr>
⁃ Change log: <https://protesilaos.com/emacs/tmr-changelog>
⁃ Git repositories:
  ⁃ GitHub: <https://github.com/protesilaos/tmr>
  ⁃ GitLab: <https://gitlab.com/protesilaos/tmr>
⁃ Backronym: TMR May Ring; Timer Must Run.

Table of Contents
─────────────────

1. COPYING
2. Overview
.. 1. Grid or tabulated view
.. 2. Hooks
.. 3. Sound and desktop notifications
.. 4. Minibuffer histories
3. Installation
.. 1. GNU ELPA package
.. 2. Manual installation
4. Sample configuration
5. Integration with Embark
6. Acknowledgements
7. GNU Free Documentation License
8. Indices
.. 1. Function index
.. 2. Variable index
.. 3. Concept index


1 COPYING
═════════

  Copyright (C) 2021-2025 Free Software Foundation, Inc.

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

  The input can also be an absolute time, such as `16:00' or `16:00:30'.
  It sets a timer from present time until the one specified.

  If `tmr' is called with an optional prefix argument (`C-u' with
  default key bindings), it asks for a description to be associated with
  the given timer.

  An alternative to the `tmr' command is `tmr-with-details'.  The
  difference between the two is that the latter always prompts for a
  description and if the timer should be acknowledged.

  The command `tmr-edit-description' can change the description a given
  timer object.

  The command `tmr-toggle-acknowledge' toggles the acknowledge flag of a
  given timer object.  A timer that needs to be acknowledged prompts for
  confirmation after it elapses.  The user can either confirm and thus
  dismiss the timer, or set a new duration for the next reminder, using
  the familiar TMR input.

  The user option `tmr-descriptions-list' defines the completion
  candidates that are shown at the description prompt.  Its value can be
  either a list of strings or the symbol of a variable that holds a list
  of strings.  The default value of `tmr-description-history', is the
  name of a variable that contains input provided by the user at the
  relevant prompt of the `tmr' and `tmr-with-details' commands.

  When the timer is set, a message is sent to the echo area recording
  the current time and the point in the future when the timer elapses.
  Echo area messages can be reviewed with the `view-echo-area-messages'
  which is bound to `C-h e' by default.  To check all timers, use the
  command `tmr-tabulated-view', which has more features than the generic
  `*Messages*' buffer ([Grid view]).

  The `tmr-cancel' command cancels running timers without erasing them
  from the list of created timer objects.  Timers at the completion
  prompt are described by the exact time they were set and the input
  that was used to create them, including the optional description that
  `tmr' and `tmr-with-details' accept.

  The `tmr-remove' command is like `tmr-cancel', except it is not
  limited to active timers: it can target elapsed ones as well.

  The `tmr-clone' command directly copies the duration and optional
  description of a timer into a new one.  With an optional prefix
  argument (`C-u' by default), this command prompts for a duration.  If
  a double prefix argument is supplied (`C-u C-u'), the command asks for
  a duration and then a description.  The default values of such prompts
  are those of the original timer.

  The command `tmr-reschedule' changes the duration of the given timer
  to a new one provided at the prompt.  In practice this is a shortcut
  to (i) cloning the timer, (ii) prompting for duration, and (iii)
  cancelling the original timer.

  The `tmr-remove-finished' command deletes all elapsed timers from the
  list of timers.  This means that they can no longer be cloned.

  By default, TMR uses minibuffer completion to pick a timer object in
  operations such as cloning and cancelling.  If the user option
  `tmr-confirm-single-timer' is set to nil, TMR will not use completion
  when there is only one timer available: it will perform the specified
  command outright.

  Timers have hooks associated with their creation, cancellation, and
  completion ([Hooks]).  TMR can also integrate with the desktop
  environment to send notifications ([Sound and desktop notifications]).

  TMR does not specify global key bindings. Instead, it sets up the
  `tmr-prefix-map', which specifies keys for the relevant commands. The
  user has the option to either bind the map to a prefix key, such as
  `C-c t' (so `tmr' is `C-c t t'), or bind individual commands to the
  desired keys ([Sample configuration]).


[Grid view] See section 2.1

[Hooks] See section 2.2

[Sound and desktop notifications] See section 2.3

[Sample configuration] See section 4

2.1 Grid or tabulated view
──────────────────────────

  Timers can be viewed in a grid with `tmr-tabulated-view' (alias
  `tmr-list-timers'). The data is placed in the `*tmr-tabulated-view*'
  buffer and looks like this:

  ┌────
  │ Start      End        Remaining  Description
  │ 10:11:49   10:11:54   ✔
  │ 10:11:36   10:31:36   19m 35s
  │ 10:11:32   10:26:32   14m 31s    Yet another test
  │ 10:11:16   10:21:16   9m 14s     Testing how it works
  └────

  If a timer has elapsed, it has a check mark associated with it,
  otherwise the `Remaining' column shows the time left.  A `Description'
  is shown only if it is provided while setting the timer, otherwise the
  field is left blank.

  Inside this grid view, all TMR commands that operate on timer objects
  automatically target the one at point.  Whereas the global behaviour
  is to use minibuffer completion to pick a timer to operate on.

  The `tmr-tabulated-view' command relies on Emacs’
  `tabulated-list-mode'.  From the `*tmr-tabulated-view*' buffer, one
  can invoke the command `describe-mode' (`C-h m' with standard key
  bindings) to learn about the applicable functionality, such as how to
  expand/contract columns and toggle sorting.

  While in this grid view, one can perform all the operations on timers
  we have already covered herein (the `C-h m' will show you their key
  bindings in this mode).

  The user option `tmr-list-timers-action-alist' controls how the
  command `tmr-tabulated-view' displays its buffer. Its default
  behaviour is to (i) place the buffer at the bottom of the Emacs frame,
  (ii) resize the window to match the height of the buffer, and (iii)
  select that window.

  The value of this user option is the same data that is passed to
  `display-buffer-alist'. It is meant to be customised by advanced
  users. Evaluate `(info "(elisp) Displaying Buffers")' to read the
  relevant entry in the manual.

  The `tmr-list-timers-action-alist' is relevant only when the command
  `tmr-tabulated-view' is called interactively. In Lisp, the
  `tmr-tabulated-view' requires the buffer it should use and the
  concomitant action alist.


2.2 Hooks
─────────

  TMR provides the following hooks:

  `tmr-timer-created-functions'
        This is triggered by the `tmr' command.  By default, it prints a
        message in the echo area showing the newly created timer’s start
        and end time as well as its optional description (if provided).

  `tmr-timer-finished-functions'
        This runs when a timer elapses.  By default, it (i) produces a
        desktop notification which describes the timer’s start/end time
        and optional description (if available), (ii) plays an alarm
        sound ([Sound and desktop notifications]), and (iii) prints a
        message in the echo area which is basically the same as the
        desktop notification.

  `tmr-timer-cancelled-functions'
        This is called by `tmr-cancel'.  By default, it prints a message
        in the echo area describing the timer that was cancelled.


[Sound and desktop notifications] See section 2.3


2.3 Sound and desktop notifications
───────────────────────────────────

  Once the timer has run its course, it produces a desktop notification
  and plays an alarm sound.  The notification’s message is practically
  the same as that which is sent to the echo area.

  The sound file for the alarm is defined in `tmr-sound-file', while the
  urgency of the notification can be set through the user option
  `tmr-notification-urgency'.  Note that it is up to the desktop
  environment or notification daemon to decide how to handle the urgency
  value.

  If the `tmr-sound-file' is nil, or the file is not found, no sound
  will be played.

  Sound playback depends on the `ffplay' executable which is part of
  `ffmpeg'.

  Desktop notifications work only if Emacs is built with DBus
  functionality.  This is the norm.  If such functionality is not
  available, TMR will issue a warning informing the user accordingly.


2.4 Minibuffer histories
────────────────────────

  TMR defines two variables that store user input:
  `tmr-duration-history' and `tmr-description-history'.  Minibuffer
  histories can persist between sessions if the user enables the
  built-in `savehist' library.  Sample configuration:

  ┌────
  │ (require 'savehist)
  │ (setq savehist-file (locate-user-emacs-file "savehist"))
  │ (setq history-length 500)
  │ (setq history-delete-duplicates t)
  │ (setq savehist-save-minibuffer-history t)
  │ (add-hook 'after-init-hook #'savehist-mode)
  └────


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
  │ git clone https://github.com/protesilaos/tmr tmr
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
  │ ;; Set to nil to disable the sound
  │ (setq tmr-sound-file "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga")
  │ 
  │ ;; Desktop notification urgency level
  │ (setq tmr-notification-urgency 'normal)
  │ 
  │ ;; Read the `tmr-descriptions-list' doc string
  │ (setq tmr-descriptions-list 'tmr-description-history)
  │ 
  │ ;; Set global prefix bindings (autoloaded):
  │ (define-key global-map "\C-ct" 'tmr-prefix-map)
  │ 
  │ ;; Alternatively bind tmr command (autoloaded):
  │ (define-key global-map "\C-ct" 'tmr)
  └────


5 Integration with Embark
═════════════════════════

  The `embark' package provides standards-compliant infrastructure to
  run context-dependent actions on all sorts of targets (symbol at
  point, current completion candidate, etc.). TMR is set up to make its
  timer objects recognisable by Embark and registers the
  `tmr-action-map' in Embark.


6 Acknowledgements
══════════════════

  TMR is meant to be a collective effort.  Every bit of help matters.

  Authors
        Protesilaos Stavrou (maintainer), Damien Cassou, Daniel Mendler.

  Contributions to the code or manual
        Christian Tietze, Ed Tavinor, Nathan R. DeGruchy.


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
