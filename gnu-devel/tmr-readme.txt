                         ━━━━━━━━━━━━━━━━━━━━━━
                              TMR MAY RING

                              Protesilaos
                          info@protesilaos.com
                         ━━━━━━━━━━━━━━━━━━━━━━


This manual, written by Protesilaos, describes the customization options
for `tmr' (or TMR, TMR May Ring, …), and provides every other piece of
information pertinent to it.  The name of the package is pronounced as
“timer” or “T-M-R”.

The documentation furnished herein corresponds to stable version 1.3.0,
released on 2026-01-25.  Any reference to a newer feature which does not
yet form part of the latest tagged commit, is explicitly marked as such.

Current development target is 1.4.0-dev.

⁃ Package name (GNU ELPA): `tmr'
⁃ Official manual: <https://protesilaos.com/emacs/tmr>
⁃ Change log: <https://protesilaos.com/emacs/tmr-changelog>
⁃ Git repositories:
  ⁃ GitHub: <https://github.com/protesilaos/tmr>
  ⁃ GitLab: <https://gitlab.com/protesilaos/tmr>
⁃ Video demonstration:
  <https://protesilaos.com/codelog/2026-01-19-emacs-timers-tmr-demo/>
⁃ Backronym: TMR May Ring; Timer Must Run.

Table of Contents
─────────────────

1. COPYING
2. Installation
.. 1. GNU ELPA package
.. 2. Manual installation
3. Sample configuration
4. How to specify the duration of a new timer
5. Create a new timer
6. Commands that act on timers
7. Grid or tabulated view
.. 1. Control how frequently the tabulated view is refreshed for the remaining time
.. 2. Specify how the tabulated view is displayed in a window
.. 3. Control the visible columns of the tabulated view
.. 4. Faces specifically used in the tabulated view
8. Display timers on the mode line
9. Hooks
10. The timer prompt
11. Sound and desktop notifications
12. Minibuffer histories
13. Integration with Embark
14. Acknowledgements
15. GNU Free Documentation License
16. Indices
.. 1. Function index
.. 2. Variable index
.. 3. Concept index


1 COPYING
═════════

  Copyright (C) 2021-2026 Free Software Foundation, Inc.

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


2 Installation
══════════════

2.1 GNU ELPA package
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


2.2 Manual installation
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


3 Sample configuration
══════════════════════

  ┌────
  │ (use-package tmr
  │   :ensure t
  │   :config
  │   (define-key global-map (kbd "C-c t") #'tmr-prefix-map)
  │   (setq tmr-sound-file "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"
  │         tmr-notification-urgency 'normal
  │         tmr-description-list 'tmr-description-history))
  └────


4 How to specify the duration of a new timer
════════════════════════════════════════════

  TMR is an Emacs package that provides facilities for setting timers
  using a convenient notation and then for managing them with ease.

  Commands that create timers prompt for a duration ([Create a new
  timer]).  In its basic form it is represented as a number and,
  optionally, a single character suffix which specifies the unit of
  time. Without a suffix, the number is interpreted as a count in
  minutes. Valid input formats are the following:

  ━━━━━━━━━━━━━━━━━━
   Input  Meaning   
  ──────────────────
   5      5 Minutes 
   5m     5 Minutes 
   5s     5 Seconds 
   5h     5 Hours   
  ━━━━━━━━━━━━━━━━━━

  The input can be a floating point:

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Input  Meaning                  
  ─────────────────────────────────
   1.5    1.5 Minutes (90 Seconds) 
   1.5h   1.5 Hours (90 Minutes)   
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  The input can also be an hour using the 24-hour clock notation, such
  as `16:00' or `16:00:30'. This sets a timer from the present time
  until the one specified.


[Create a new timer] See section 5


5 Create a new timer
════════════════════

  All of the commands that create a timer read time input in the same
  way ([How to specify the duration of a new timer]).

  The command `tmr' is the most common way to create a new timer. By
  default, it only prompts for a timer duration and creates the timer
  accordingly.

  If `tmr' is called with an optional prefix argument (`C-u' with
  default keybindings), it asks for a description to be associated with
  the given timer and whether to acknowledge the timer after it has
  elapsed (the acknowledgement is useful for those who do not want to
  miss a timer or who want to perform a follow-up action).

  An alternative to the `tmr' command is `tmr-with-details'.  The
  difference between the two is that the latter always prompts for a
  description and whether the timer should be acknowledged or not.

  The `tmr-repeat' is like `tmr' though also prompts for a number of
  repetitions repeat count. This means that the specified timer will run
  that many times. [ Part of 1.4.0-dev. ] When called with a prefix
  argument (`C-u' with default keybindings) it asks for a description
  and whether timer should be acknowledged or not once all repetitions
  are done.

  When the timer is set, a message is sent to the echo area recording
  the current time and the point in the future when the timer elapses.
  Echo area messages can be reviewed with the `view-echo-area-messages'
  which is bound to `C-h e' by default. To check all timers, use the
  command `tmr-tabulated-view', which has more features than the generic
  `*Messages*' buffer ([Grid view]).

  Once timers are available it is possible to act on them ([Commands
  that act on timers]).

  TMR does not specify global keybindings. Instead, it sets up the
  `tmr-prefix-map', which specifies keys for the relevant commands. The
  user has the option to either bind the map to a prefix key, such as
  `C-c t' (so `tmr' is `C-c t t'), or bind individual commands to the
  desired keys ([Sample configuration]).


[How to specify the duration of a new timer] See section 4

[Grid view] See section 7

[Commands that act on timers] See section 6

[Sample configuration] See section 3


6 Commands that act on timers
═════════════════════════════

  All of the following commands act on existing timers by prompting to
  select one among them ([Create a new timer]).

  The command `tmr-edit-description' can change the description a given
  timer object.

  The command `tmr-edit-repeat-count' sets the repeat count of the given
  timer. When the repeat count is set to `0', then the timer is no
  longer considered repeatable. [ The command `tmr-edit-repeat-count' is
  part of 1.4.0-dev. ]

  The command `tmr-toggle-acknowledge' toggles the acknowledge flag of a
  given timer object. A timer that needs to be acknowledged prompts for
  confirmation after it elapses. The user can either confirm and thus
  dismiss the timer, or set a new duration for the next reminder, using
  the familiar TMR input. The confirmation text to be provided at the
  minibuffer prompt (`ack' by default) can be configured via the user
  option `tmr-acknowledge-timer-text'.

  The command `tmr-toggle-pause' pauses the given timer. The tabulated
  view has a column to show when a timer is paused ([Grid or tabulated
  view]).  Similarly, the mode line indicator adapts the text of the
  timer to tell that it is paused ([Display timers on the mode line]).

  The `tmr-cancel' command cancels running timers without erasing them
  from the list of created timer objects.  Timers at the completion
  prompt are described by the exact time they were set and the input
  that was used to create them, including the optional description that
  `tmr' and derivative commands have.

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

  Timers have hooks associated with their creation, cancellation, and
  completion ([Hooks]).  TMR can also integrate with the desktop
  environment to send notifications ([Sound and desktop notifications]).


[Create a new timer] See section 5

[Grid or tabulated view] See section 7

[Display timers on the mode line] See section 8

[Hooks] See section 9

[Sound and desktop notifications] See section 11


7 Grid or tabulated view
════════════════════════

  Timers can be viewed in a grid with `tmr-tabulated-view' (alias
  `tmr-list-timers'). The data is placed in the `*tmr-tabulated-view*'
  buffer and looks like this ([Control the visible columns of the
  tabulated view]):

  ┌────
  │ Start      End        Duration   Remaining  Paused?  Acknowledge?   Description
  │ 
  │ 08:49:41   09:19:46   30m        29m 17s    Yes                     Work on TMR for 30 minutes
  │ 08:49:31   08:54:31   5m         3m 53s                             Prepare tea
  │ 08:49:21   08:59:21   10m        8m 42s              Yes            Edit the description with this one instead
  └────

  If a timer has elapsed, it has a check mark associated with it,
  otherwise the `Remaining' column shows the time left ([Control how
  frequently the tabulated view is refreshed for the remaining time]).
  A `Description' is shown only if it is provided while setting the
  timer, otherwise the field is left blank.

  Inside this grid view, all TMR commands that operate on timer objects,
  such as for pausing or rescheduling, automatically target the one at
  point. Whereas the global behaviour is to use minibuffer completion to
  pick a timer to operate on.

  The `tmr-tabulated-view' command relies on Emacs’
  `tabulated-list-mode'.  From the `*tmr-tabulated-view*' buffer, one
  can invoke the command `describe-mode' (`C-h m' with standard
  keybindings) to learn about the applicable functionality, such as how
  to expand/contract columns and toggle sorting.

  While in this grid view, one can perform all the operations on timers
  we have already covered herein (the `describe-mode' (`C-h m') will
  show you their keybindings in this mode).


[Control the visible columns of the tabulated view] See section 7.3

[Control how frequently the tabulated view is refreshed for the
remaining time] See section 7.1

7.1 Control how frequently the tabulated view is refreshed for the remaining time
─────────────────────────────────────────────────────────────────────────────────

  By default, the `tmr-tabulated-view' buffer is updated automatically
  every 5 seconds ([Grid or tabulated view]).

  Users can change the number of seconds by modifying the user option
  `tmr-tabulated-refresh-interval'. A `nil' value means to never refresh
  that buffer automatically: users can update it manually by invoking
  the command `revert-buffer', which is bound to `g' by default.


[Grid or tabulated view] See section 7


7.2 Specify how the tabulated view is displayed in a window
───────────────────────────────────────────────────────────

  The user option `tmr-list-timers-action-alist' controls how the
  command `tmr-tabulated-view' displays its buffer ([Grid or tabulated
  view]).  Its default behaviour is to (i) place the buffer at the
  bottom of the Emacs frame, (ii) resize the window to match the height
  of the buffer, and (iii) select that window.

  The value of this user option is the same data that is passed to
  `display-buffer-alist'. It is meant to be customised by advanced
  users. Evaluate `(info "(elisp) Displaying Buffers")' to read the
  relevant entry in the manual.

  The `tmr-list-timers-action-alist' is relevant only when the command
  `tmr-tabulated-view' is called interactively. In Lisp, the
  `tmr-tabulated-view' requires the buffer it should use and the
  concomitant action alist.


[Grid or tabulated view] See section 7


7.3 Control the visible columns of the tabulated view
─────────────────────────────────────────────────────

  [ The `tmr-tabulated-columns' is part of 1.4.0-dev. ]

  The user option `tmr-tabulated-columns' controls which columns are
  displayed by `tmr-tabulated-view' ([Grid or tabulated view]). The
  default value shows all the available columns. The columns are
  specified as a list of the following symbols:

  `start'
        the start time;
  `end'
        the end time;
  `duration'
        the duration of the timer;
  `remaining'
        how much time is left in the timer;
  `paused'
        whether the timer is paused or not;
  `repeatable'
        whether the timer is set to repeat or not;
  `remaining-repeats'
        the number of repeats left;
  `total-repeats'
        the total repeats specified originally;
  `ackonwledge'
        whether the timer should stop only after being acknowledged;
  `description'
        the description of the timer.

  The order of symbols in the list is exactly how they will be displayed
  by `tmr-tabulated-view'. Duplicates are removed.


[Grid or tabulated view] See section 7


7.4 Faces specifically used in the tabulated view
─────────────────────────────────────────────────

  The following faces are applied in the buffer produced by the command
  `tmr-tabulated-view' ([Grid or tabulated view]).

  `tmr-tabulated-start-time'
        The time the timer started.
  `tmr-tabulated-end-time'
        The time the timer will end.
  `tmr-tabulated-remaining-time'
        The timer’s remaining time.
  `tmr-tabulated-paused'
        Whether the timer is paused or not.
  `tmr-tabulated-acknowledgement'
        Whether the timer needs to be acknowledged.
  `tmr-tabulated-description'
        The description of the timer.


[Grid or tabulated view] See section 7


8 Display timers on the mode line
═════════════════════════════════

  The `tmr-mode-line-mode' is a minor mode that displays running timers
  on the mode line. Specifically, the timers are shown as part of the
  `global-mode-string'. This means that they may be displayed on the
  `tab-bar-mode' instead of the mode line if the user option
  `tab-bar-format' is configured accordingly.

  The user option `tmr-mode-line-format' controls how the timers are
  rendered. This is a string that treats specially the `%r' and `%d'
  specifiers. The `%r' represents the remaining time, while `%d' is the
  description of the timer.

  The user option `tmr-mode-line-max-desc-length' sets the maximum
  length of a timers description, when the `tmr-mode-line-format' is
  configured to show descriptions.

  The user option `tmr-mode-line-max-timers' sets the maximum number of
  running timers that are shown on the mode line at any one time.

  The user option `tmr-mode-line-separator' specifies a string that is
  inserted between timers on the mode line to visually separate them.

  The user option `tmr-mode-line-prefix' specifies a string that is
  prepended to the indicator with all the running timers.

  Applicable faces for this case are:

  `tmr-mode-line-active'
        Any active timer.
  `tmr-mode-line-soon'
        A timer that expires within 2 minutes.
  `tmr-mode-line-urgent'
        A timer that expires within 30 seconds.


9 Hooks
═══════

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

        This hook can be used as an extension point for custom
        notification mechanisms. To replace or augment the default
        desktop notification, remove `tmr-notification-notify' and add
        your own function:

        ┌────
        │ (remove-hook 'tmr-timer-finished-functions #'tmr-notification-notify)
        │ (add-hook 'tmr-timer-finished-functions #'my-custom-notify-function)
        └────

        The function receives a timer.

        Below is an example of how a macOS notification could be
        produced:

        ┌────
        │ (defun my-macos-notify (timer)
        │   (let* ((description (or (tmr--timer-description timer) ""))
        │          (sanitized-body (substring-no-properties description))
        │          (script (format "display notification %S with title %S sound name %S"
        │                              sanitized-body
        │                              (format-time-string "Emacs TMR: %R" (tmr--timer-end-date timer))
        │                              "Hero")))
        │     (call-process "osascript" nil 0 nil "-e" script)))
        │ 
        │ (remove-hook 'tmr-timer-finished-functions #'tmr-notification-notify)
        │ (add-hook 'tmr-timer-finished-functions #'my-macos-notify)
        └────
  `tmr-timer-cancelled-functions'
        This is called by `tmr-cancel'.  By default, it prints a message
        in the echo area describing the timer that was cancelled.


[Sound and desktop notifications] See section 11


10 The timer prompt
═══════════════════

  [ The `tmr-read-timer' and `tmr-completion-metadata' are both part of
    1.4.0-dev. ]

  For commands that act on timers, the function `tmr-read-timer' is
  involved in the minibuffer completion phase: it is how the user picks
  one among the relevant timers.

  The `tmr-read-timer' applies the variable `tmr-completion-metadata'.
  Experienced users can modify this variable to affect how timers are
  sorted, how they are annotated, and, in principle, anything else
  implied by the `completion-metadata' function.


11 Sound and desktop notifications
══════════════════════════════════

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


12 Minibuffer histories
═══════════════════════

  TMR defines two variables that store user input:
  `tmr-duration-history' and `tmr-description-history'.  Minibuffer
  histories can persist between sessions if the user enables the
  built-in `savehist' library.  Sample configuration:

  ┌────
  │ (use-package savehist
  │   :ensure nil
  │   :config
  │   (setq savehist-file (locate-user-emacs-file "savehist"))
  │   (setq history-length 500)
  │   (setq history-delete-duplicates t)
  │   (setq savehist-save-minibuffer-history t)
  │   (savehist-mode 1))
  └────


13 Integration with Embark
══════════════════════════

  The `embark' package provides standards-compliant infrastructure to
  run context-dependent actions on all sorts of targets (symbol at
  point, current completion candidate, etc.). TMR is set up to make its
  timer objects recognisable by Embark and registers the
  `tmr-action-map' in Embark.


14 Acknowledgements
═══════════════════

  TMR is meant to be a collective effort.  Every bit of help matters.

  Authors
        Protesilaos (maintainer), Carlos Pajuelo Rojo, Damien Cassou,
        Daniel Mendler, Óscar Fuentes, Pavlo Lysov, Steven Allen.

  Contributions to the code or manual
        Christian Tietze, Ed Tavinor, Eugene Mikhaylov, Karol Mróz,
        Lucas Quintana, Mirko Hernandez, Nathan R. DeGruchy, Pavlo
        Lysov, f6p, jpg.


15 GNU Free Documentation License
═════════════════════════════════


16 Indices
══════════

16.1 Function index
───────────────────


16.2 Variable index
───────────────────


16.3 Concept index
──────────────────
