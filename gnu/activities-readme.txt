                            ━━━━━━━━━━━━━━━
                             ACTIVITIES.EL
                            ━━━━━━━━━━━━━━━


[file:https://elpa.gnu.org/packages/activities.svg]

Inspired by Genera's and KDE's concepts of "activities", this Emacs
library allows the user to manage frames/tabs, windows, and buffers
according to their purpose.  An "activity" comprises a frame or tab, its
window configuration, and the buffers displayed in them–its "state";
this state would be related to a certain task the user performs at
various times, such as developing a certain software project, reading
and writing email, working with one's Org mode system, etc.

"Suspending" an activity saves the activity's state and closes its
frame/tab; the user would do this when finished with the activity's task
for the time being.  "Resuming" the activity restores its buffers and
windows to its frame/tab; the user would do this when ready to resume
the task at a later time.  This saves the user from having to manually
arrange the same windows and buffers each time the task is to be done.

Each activity saves two states: the default state, set when the activity
is defined by the user, and the last-used state, which was how the user
left it when the activity was suspended (or when Emacs exited, etc).
This allows the user to resume the activity where the task was left off,
while also allowing it to be reverted to the default state, providing a
consistent entry point into the activity.

Internally, the Emacs `bookmark' library is used to save and restore
buffers' states–that is, any major mode that supports the bookmark
system is compatible.  A buffer whose major mode does not support the
bookmark system (or does not support it well enough to restore useful
state) is not compatible and can't be fully restored, or perhaps not at
all; but solving that is as simple as implementing bookmark support for
the mode, which is often trivial.

Various hooks are (or will be–feedback is welcome) provided, both
globally and per-activity, so that the user can define functions to be
called when an activity is saved, restored, or switched from/to.  For
example, this could be used to limit the set of buffers offered for
switching to within an activity, or to track the time spent in an
activity.


[file:https://elpa.gnu.org/packages/activities.svg]
<https://elpa.gnu.org/packages/activities.html>


1 Installation
══════════════

1.1 GNU ELPA
────────────

  `activities' may be installed into Emacs versions 29.1 or later from
  [GNU ELPA] by using the command `M-x package-install RET activities
  RET'.  This will install the latest stable release, which is
  recommended.


[GNU ELPA] <https://elpa.gnu.org/packages/activities.html>


1.2 Quelpa
──────────

  To install directly from git (e.g. to test a pre-release version),
  it's recommended to use [Quelpa]:

  1. Install [quelpa-use-package] (which can be installed directly from
     MELPA).
  2. Add this form to your init file (see [Configuration] for more
     details):

  ┌────
  │ (use-package activities
  │   :quelpa (activities :fetcher github :repo "alphapapa/activities.el"))
  └────

  If you choose to install it otherwise, please note that the author
  can't offer help with manual installation problems.


[Quelpa] <https://framagit.org/steckerhalter/quelpa>

[quelpa-use-package]
<https://framagit.org/steckerhalter/quelpa-use-package#installation>

[Configuration] See section 2


2 Configuration
═══════════════

  This is the recommended configuration, in terms of a `use-package'
  form to be placed in the user's init file:

  ┌────
  │ (use-package activities
  │   :init
  │   (activities-mode)
  │   (activities-tabs-mode)
  │   ;; Prevent `edebug' default bindings from interfering.
  │   (setq edebug-inhibit-emacs-lisp-mode-bindings t)
  │ 
  │   :bind
  │   (("C-x C-a C-n" . activities-new)
  │    ("C-x C-a C-d" . activities-define)
  │    ("C-x C-a C-a" . activities-resume)
  │    ("C-x C-a C-s" . activities-suspend)
  │    ("C-x C-a C-k" . activities-kill)
  │    ("C-x C-a RET" . activities-switch)
  │    ("C-x C-a b" . activities-switch-buffer)
  │    ("C-x C-a g" . activities-revert)
  │    ("C-x C-a l" . activities-list)))
  └────


3 Usage
═══════

3.1 Activities
──────────────

  For the purposes of this library, an "activity" is a window
  configuration and its associated buffers.  When an activity is
  "resumed," its buffers are recreated and loaded into the window
  configuration, which is loaded into a frame or tab.

  From the user's perspective, an "activity" should be thought of as
  something like, "reading my email," "working on my Emacs library,"
  "writing my book," "working for this client," etc.  The user arranges
  a set of windows and buffers according to what's needed, then saves it
  as a new activity.  Later, when the user wants to return to doing that
  activity, the activity is "resumed," which restores the activity's
  last-seen state, allowing the user to pick up where the activity was
  left off; but the user may also revert the activity to its default
  state, which may be used as a kind of entry point to doing the
  activity in general.


3.2 Compatibility
─────────────────

  This library is designed to not interfere with other workflows and
  tools; it is intended to coexist and allow integration with them.  For
  example, when `activities-tabs-mode' is enabled, non-activity-related
  tabs are not affected by it; and the user may close any tab using
  existing tab commands, regardless of whether it is associated with an
  activity.


3.3 Modes
─────────

  `activities-mode'
        Automatically saves activities' states when Emacs is idle and
        when Emacs exits.  Should be enabled while using this package
        (otherwise you would have to manually call
        `activities-save-all', which would defeat much of the purpose of
        this library).
  `activities-tabs-mode'
        Causes activities to be managed as `tab-bar' tabs rather than
        frames (the default).  (/This is what the author uses; bugs
        present when this mode is not enabled are less likely to be
        found, so please report them./)


3.4 Workflow
────────────

  An example of a workflow using activities:

  1. Arrange windows in a tab according to an activity you're
     performing.
  2. Call `activities-define' (`C-x C-a C-d') to save the activity under
     a name.
  3. Perform the activity for a while.
  4. Change window configuration, change tab, close the tab, or even
     restart Emacs.
  5. Call `activities-resume' (`C-x C-a C-a') to resume the activity
     where you left off.
  6. Return to the original activity state with `activities-revert'
     (`C-x C-a g').
  7. Rearrange windows and buffers.
  8. Call `activities-define' with a universal prefix argument (`C-u C-x
     C-a C-d') to redefine an activity's default state.
  9. Suspend the activity with `activities-suspend' (`C-x C-a s') (which
     saves its last state and closes its frame/tab).


3.5 Bindings
────────────

  Key bindings are, as always, ultimately up to the user.  However, in
  [Configuration], we suggest a set of bindings with a simple philosophy
  behind them:

  ⁃ A binding ending in a `C'-prefixed key is expected to result in the
    set of active activities being changed (e.g. defining a new
    activity, switching to one, or suspending one).
  ⁃ A binding not ending in a `C'-prefixed key is expected to modify an
    activity (e.g. reverting it) or do something else (like listing
    activities.)


[Configuration] See section 2


3.6 Commands
────────────

  /With the recommended bindings:/

  `activities-list' (`C-x C-a l')
        List activities in a `vtable' buffer in which they can be
        managed with various commands.
  `activities-new' (`C-x C-a C-n')
        Switch to a new, empty activity (i.e. one showing a new
        frame/tab).
  `activities-define' (`C-x C-a C-d')
        Define a new activity whose default state is the current frame's
        or tab's window configuration.  With prefix argument, redefine
        an existing activity (thereby updating its default state to the
        current state).
  `activities-suspend' (`C-x C-a C-s')
        Save an activity's state and close its frame or tab.
  `activities-kill' (`C-x C-a C-k')
        Discard an activity's last state (so when it is resumed, its
        default state will be used), and close its frame or tab.
  `activities-resume' (`C-x C-a C-a')
        Resume an activity, switching to a new frame or tab for its
        window configuration, and restoring its buffers.  With prefix
        argument, restore its default state rather than its last.
  `activities-revert' (`C-x C-a g')
        Revert an activity to its default state.
  `activities-switch' (`C-x C-a RET')
        Switch to an already-active activity.
  `activities-switch-buffer' (`C-x C-a b')
        Switch to a buffer associated with the current activity (or,
        with prefix argument, another activity).
  `activities-rename'
        Rename an activity.
  `activities-discard'
        Discard an activity permanently.
  `activities-save-all'
        Save all active activities' states.  (`activities-mode' does
        this automatically, so this command should rarely be needed.)


3.7 Bookmarks
─────────────

  When option `activities-bookmark-store' is enabled, an Emacs bookmark
  is stored when a new activity is made.  This allows the command
  `bookmark-jump' (`C-x r b') to be used to resume an activity (helping
  to universalize the bookmark system).


4 FAQ
═════

  How is this different from [Burly.el] or [Bufler.el]?
        Burly is a well-polished tool for restoring window and frame
        configurations, which could be considered an incubator for some
        of the ideas furthered here.  Bufler's `bufler-workspace'
        library uses Burly to provide some similar functionality, which
        is at an exploratory stage.  `activities' hopes to provide a
        longer-term solution more suitable for integration into Emacs.

  How does this differ from "workspace" packages?
        Yes, there are many Emacs packages that provide "workspace"-like
        features in one way or another.  To date, only Burly and Bufler
        seem to offer the ability to restore one across Emacs sessions,
        including non-file-backed buffers.  As mentioned, `activities'
        is intended to be more refined and easier to use
        (e.g. automatically saving activities' states when
        `activities-mode' is enabled).  Comparisons to other packages
        are left to the reader; suffice to say that `activities' is
        intended to provide what other tools haven't, in an idiomatic,
        intuitive way.  (Feedback is welcome.)

  How does this differ from the built-in `desktop-mode'?
        As best this author can tell, `desktop-mode' saves and restores
        one set of buffers, with various options to control its
        behavior.  It does not use `bookmark' internally, which prevents
        it from restoring non-file-backed buffers.  As well, it is not
        intended to be used on-demand to switch between sets of buffers,
        windows, or frames (i.e. "activities").

  "Activities" haven't seemed to pan out for KDE.  Why would they in Emacs?
        KDE Plasma's Activities system requires applications that can
        save and restore their state through Plasma, which only (or
        mostly only?) KDE apps can do, limiting the usefulness of the
        system.  However, Emacs offers a coherent environment, similar
        to Lisp machines of yore, and its `bookmark' library offers a
        way for any buffer's major mode to save and restore state, if
        implemented (which many already are).

  Why did a buffer not restore correctly?
        Most likely because that buffer's major mode does not support
        Emacs bookmarks (which `activities' uses internally to save and
        restore buffer state).  But many, if not most, major modes do;
        and for those that don't, implementing such support is usually
        trivial (and thereby benefits Emacs as a whole, not just
        `activities').  So contact the major mode's maintainer and ask
        that `bookmark' support be implemented.

  Why did I get an error?
        Because `activities' is at an early stage of development and
        some of these features are not simple to implement.  But it's
        based on Burly, which has already been through much bug-fixing,
        so it should proceed smoothly.  Please report any bugs you find.


[Burly.el] <https://github.com/alphapapa/burly.el>

[Bufler.el] <https://github.com/alphapapa/bufler.el/>


5 Changelog
═══════════

5.1 v0.7.1
──────────

  *Fixes*
  ⁃ Race condition when restoring multiple activities in rapid
    succession from user code.  ([#98].  Thanks to [JD Smith].)
  ⁃ Command `activities-resume' resets when called with a universal
    prefix argument.  ([#75].  Thanks to [Joseph Turner].)
  ⁃ Refreshing activities list.  ([#77].  Thanks to [Joseph Turner].)
  ⁃ Autoload bookmark handler.  ([#114].  Thanks to [Joseph Turner].)


[#98] <https://github.com/alphapapa/activity.el/pull/98>

[JD Smith] <https://github.com/jdtsmith>

[#75] <https://github.com/alphapapa/activities.el/pull/75>

[Joseph Turner] <https://breatheoutbreathe.in>

[#77] <https://github.com/alphapapa/activities.el/pull/77>

[#114] <https://github.com/alphapapa/activity.el/pull/114>


5.2 v0.7
────────

  *Additions*
  ⁃ Command `activities-new' switches to a new, "empty" activity.  (See
    [#46].)

  *Changes*
  ⁃ Command `activities-new' renamed to `activities-define', with new
    binding `C-x C-a C-d'.  (See [#46].)
  ⁃ Improve error message when jumping to a buffer's bookmark signals an
    error.

  *Fixes*
  ⁃ Suspending/killing an activity when only one frame/tab is open.
  ⁃ Generation of Info manual on GNU ELPA.  (Thanks to Stefan Monnier.)
  ⁃ Ignore minimum window sizes and fixed size restrictions.  ([#56].
    Thanks to [Jelle Licht].)


[#46] <https://github.com/alphapapa/activities.el/issues/46>

[#56] <https://github.com/alphapapa/activity.el/issues/56>

[Jelle Licht] <https://github.com/jellelicht>


5.3 v0.6
────────

  *Additions*
  ⁃ Command `activities-switch-buffer' switches to a buffer associated
    with the current activity (or, with prefix argument, another
    activity).  (A buffer is considered to be associated with an
    activity if it has been displayed in its tab.  Note that this
    feature currently requires `activities-tabs-mode'.)
  ⁃ Command `activities-rename' renames an activity.
  ⁃ Option `activities-after-switch-functions', a hook called after
    switching to an activity.
  ⁃ Option `activities-set-frame-name' sets the frame name after
    switching to an activity.  ([#33].  Thanks to [JD Smith].)
  ⁃ Option `activities-kill-buffers', when suspending an activity, kills
    buffers that were only shown in that activity.

  *Changes*
  ⁃ Default time format in activities list.
  ⁃ When saving all activities, don't persist to disk for each activity.
    ([#34].  Thanks to [Al M.] for reporting.)


[#33] <https://github.com/alphapapa/activities.el/issues/33>

[JD Smith] <https://github.com/jdtsmith>

[#34] <https://github.com/alphapapa/activities.el/issues/34>

[Al M.] <https://github.com/yrns>


5.4 v0.5.1
──────────

  *Fixes*
  ⁃ Listing activities without last-saved states.


5.5 v0.5
────────

  *Additions*
  ⁃ Suggest setting variable `edebug-inhibit-emacs-lisp-mode-bindings'
    to avoid conflicts with suggested keybindings.
  ⁃ Option `activities-bookmark-warnings' enables warning messages when
    a non-file-visiting buffer can't be bookmarked (for debugging
    purposes).
  ⁃ Option `activities-resume-into-frame' controls whether resuming an
    activity opens a new frame or uses the current one (when
    `activities-tabs-mode' is disabled).  ([#22].  Thanks to
    [Icy-Thought] for suggesting.)

  *Changes*
  ⁃ Command `activities-kill' now discards an activity's last state
    (while `activities-suspend' saves its last state), and closes its
    frame or tab.
  ⁃ Face `activities-tabs-face' is renamed to `activities-tabs', and now
    inherits from another face by default, which allows it to adjust
    with the loaded theme.  ([#24].  Thanks to [Karthik Chikmagalur] for
    suggesting.)

  *Fixes*
  ⁃ Show a helpful error if a bookmark's target file is missing.
    ([#17].  Thanks to [JD Smith] for reporting.)
  ⁃ Sort order in `activities-list'.
  ⁃ When discarding an inactive activity, don't switch to it first.
    ([#18].  Thanks to [JD Smith] for reporting.)
  ⁃ Don't signal an error when `debug-on-error' is enabled and a buffer
    is not visiting a file.  ([#25].  Thanks to [Karthik Chikmagalur]
    for reporting.)


[#22] <https://github.com/alphapapa/activities.el/issues/22>

[Icy-Thought] <https://github.com/Icy-Thought>

[#24] <https://github.com/alphapapa/activities.el/issues/24>

[Karthik Chikmagalur] <https://github.com/karthink>

[#17] <https://github.com/alphapapa/activities.el/issues/17>

[JD Smith] <https://github.com/jdtsmith>

[#18] <https://github.com/alphapapa/activity.el/issues/18>

[#25] <https://github.com/alphapapa/activity.el/issues/25>


5.6 v0.4
────────

  *Additions*
  ⁃ Option `activities-anti-save-predicates' prevents saving activity
    states at inappropriate times.

  *Fixes*
  ⁃ Don't save activity state if a minibuffer is active.
  ⁃ Offer only active activities for suspending.
  ⁃ Don't raise frame when saving activity states.  (See [#4].  Thanks
    to [JD Smith] for reporting.)


[#4] <https://github.com/alphapapa/activities.el/issues/4>

[JD Smith] <https://github.com/jdtsmith>


5.7 v0.3.3
──────────

  *Fixes*
  ⁃ Command `activities-list' shows a helpful message if no activities
    are defined.  ([#11].  Thanks to [fuzy112] for reporting.)
  ⁃ Link in documentation (which works locally but not on GNU ELPA at
    the moment).


[#11] <https://github.com/alphapapa/activities.el/issues/11>

[fuzy112] <https://github.com/fuzy112>


5.8 v0.3.2
──────────

  Updated documentation, etc.


5.9 v0.3.1
──────────

  *Fixes*
  ⁃ Handle case in which `activities-tabs-mode' is enabled again without
    having been disabled (which caused an error in
    `tab-bar-mode'). ([#7])


[#7] <https://github.com/alphapapa/activities.el/issues/7>


5.10 v0.3
─────────

  *Additions*
  ⁃ Command `activities-list' lists activities in a `vtable' buffer in
    which they can be managed.
  ⁃ Offer current activity name by default when redefining an activity
    with `activities-new'.
  ⁃ Record times at which activities' states were updated.


5.11 v0.2
─────────

  *Additions*
  ⁃ Offer current `project' name by default for new activities.  (Thanks
    to [Joseph Turner].)
  ⁃ Use current activity as default for various completions.  (Thanks to
    [Joseph Turner].)

  *Fixes*
  ⁃ Raise frame after selecting it.  (Thanks to [JD Smith] for
    suggesting.)


[Joseph Turner] <https://breatheoutbreathe.in>

[JD Smith] <https://github.com/jdtsmith>


5.12 v0.1.3
───────────

  *Fixes*
  ⁃ Autoloads.
  ⁃ Command aliases.


5.13 v0.1.2
───────────

  *Fixes*
  ⁃ Some single-window configurations were not restored properly.


5.14 v0.1.1
───────────

  *Fixes*
  ⁃ Silence message about non-file-visiting buffers.


5.15 v0.1
─────────

  Initial release.


6 Development
═════════════

  `activities' is developed on [GitHub].  Suggestions, bug reports, and
  patches are welcome.


[GitHub] <https://github.com/alphapapa/activities.el>

6.1 Copyright assignment
────────────────────────

  This package is part of [GNU Emacs], being distributed in [GNU ELPA].
  Contributions to this project must follow GNU guidelines, which means
  that, as with other parts of Emacs, patches of more than a few lines
  must be accompanied by having assigned copyright for the contribution
  to the FSF.  Contributors who wish to do so may contact
  [emacs-devel@gnu.org] to request the assignment form.


[GNU Emacs] <https://www.gnu.org/software/emacs/>

[GNU ELPA] <https://elpa.gnu.org/>

[emacs-devel@gnu.org] <mailto:emacs-devel@gnu.org>
