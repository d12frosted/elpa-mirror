           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            BUFFERLO.EL - FRAME/TAB LOCAL BUFFER LISTS WITH
                              PERSISTENCE
           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


Easy-to-use buffer management and workspace persistence tools for Emacs
workflow management. Headbutt your way to productivity and moove ahead
with bufferlo.


Introduction
════════════

  With bufferlo, every frame and tab (i.e., `tab-bar-mode' tab) has an
  additional manageable local buffer list. A buffer is added to the
  local buffer list when displayed in the frame/tab (e.g., by opening a
  new file in the tab or by switching to the buffer from the global
  buffer list).

  Using Emacs's built-in buffer-list frame parameter, bufferlo
  integrates seamlessly with all standard frame and tab management
  facilities, including undeletion of frames and tabs, tab duplication
  and moving, frame cloning, and session persistence with desktop.el
  (though bufferlo frame and tab bookmarks offer an alternative
  persistence method).

  Bufferlo provides extensive management functions for its local lists
  and offers features on top of switch-buffer functions, buffer menu,
  and `ibuffer'. You can configure any command that selects a buffer to
  use the local buffer list via `bufferlo-anywhere-mode'.

  In addition, bufferlo offers lightweight Emacs bookmarks-based
  persistence for frames, tabs, and sets of frames/tabs to help you
  manage your transient workflows. Bufferlo bookmarks are compatible
  with built-in features such as `bookmark-bmenu-list' and third-party
  packages such as [consult] which offers consult-bookmark for
  interactive bookmark selection.


[consult] <https://github.com/minad/consult>


Installation
════════════

  Bufferlo is available in [GNU ELPA].  Install it via `package-install'
  and enable `bufferlo-mode'
  ┌────
  │ (bufferlo-mode)
  └────

  Or via `use-package' (see below for a comprehensive configuration
  example)
  ┌────
  │ (use-package bufferlo
  │   :ensure t
  │   :init
  │   (bufferlo-mode))
  └────

  Note: Although the Emacs `tab-bar-mode' is fully supported, you do not
  have to use tabs to benefit from bufferlo; you can stick to a
  frame-only workflow. If you use `tab-line-mode' without
  `tab-bar-mode', your bufferlo experience will be the same as a
  frame-only user. Tab-oriented functions are active even if the tab-bar
  is hidden.

  The following code examples use `setq' to customize options. You may
  also use `M-x customize-group bufferlo'. Emacs 29 introduced `setopt'
  which works correctly in the presence of `defcustom'
  setters. Currently the only bufferlo option with such a setter is
  `bufferlo-bookmarks-auto-save-interval' so be sure to set that
  interval timer in advance of enabling `bufferlo-mode'.

  Many bufferlo commands have short-hand aliases to accommodate the
  helpful `which-key' display (now a built-in for Emacs 30+). Bufferlo's
  menu references these aliases and not the main commands. We recommend
  that you use the short-hand aliases when binding your preferred keys
  to ensure the bufferlo menu reflects your key bindings.


[GNU ELPA] <https://elpa.gnu.org/packages/bufferlo.html>


Usage
═════

Buffer selection
────────────────

  Use bufferlo buffer-list commands as local-buffer alternatives to
  built-in global-buffer commands:

  • `bufferlo-switch-to-buffer': The command `switch-to-buffer' filtered
    for local buffers. Call it with a prefix argument to get the global
    list (all buffers).

  • `bufferlo-ibuffer': The command `ibuffer' filtered for local
    buffers. Alternatively, use "/ l" in ibuffer.

  • `bufferlo-ibuffer-orphans': The command `ibuffer' filtered for
    orphan buffers. Orphan buffers are buffers that are not in any
    frame/tab's local buffer list. Alternatively, use "/ L" in ibuffer.

  • `bufferlo-list-buffers': Display a list of local buffers in a
    buffer-menu buffer.

  • `bufferlo-list-orphan-buffers': Display a list of orphan buffers in
    a `buffer-menu' buffer. Orphan buffers are buffers that are not in
    any frame/tab's local buffer list.


Manage local buffer lists
─────────────────────────

  • `bufferlo-clear': Clear the frame/tab's local buffer list, retaining
    the current buffer. This is non-destructive to the buffers
    themselves.

  • `bufferlo-remove': Remove a buffer from the frame/tab's buffer list.

  • `ibuffer': Bufferlo adds the "-" key binding in `ibuffer-mode' to
    invoke `bufferlo-remove' on marked buffers.

  • `bufferlo-remove-non-exclusive-buffers': Remove all buffers from the
    local list that are not exclusive to this frame/tab.

  • `bufferlo-bury': Bury and remove the current buffer from the
    frame/tab's buffer list.

  • `bufferlo-kill-buffers': Kill all buffers on the frame/tab local
    list.

  • `bufferlo-kill-orphan-buffers': Kill all buffers that are *not* on
    any frame/tab local list.

  • `bufferlo-delete-frame-kill-buffers': Delete the frame and kill all
    its local buffers.

  • `bufferlo-tab-close-kill-buffers': Close the tab and kill its local
    buffers.

  • `bufferlo-isolate-project': Isolate a project.el project in the
    frame or tab. This removes non-project buffers from the local buffer
    list. Use a prefix argument to further restrict the retained buffers
    to only those that are visiting files.

  • `bufferlo-find-buffer': Switch to a frame/tab that contains the
    buffer in its local list.

  • `bufferlo-find-buffer-switch': Switch to a frame/tab that contains
    the buffer in its local list, and select the buffer.


Bookmark management for frames, tabs, and sets
──────────────────────────────────────────────

  Bufferlo can bookmark the buffers and windows belonging to individual
  frames and tabs for later recall between Emacs sessions or within a
  long-running session. Sets can be defined as collections of frames
  and/or tabs to be recalled as a group. All you need to do is provide a
  name for a bookmark and save it for later recall.

  A tab bookmark includes the tab's window configuration, the state (not
  the contents) of all bookmarkable local buffers, and the bufferlo
  local buffer list. Tabs can be restored into any frame.

  A frame bookmark saves every tab on a frame, each with the tab
  contents stated above. Frames can be restored into the current frame,
  replacing all tabs, into a new frame, or merged with the current
  frame's tabs. Frames can also store their geometry for later
  restoration.

  A bookmark set saves a list of frame and tab bookmark names, where
  constituent bookmarks behave as above, and can optionally restore each
  frame's geometry. Bufferlo frame and tab bookmarks may be referenced
  in multiple bookmark sets which can be useful for buffers that are
  common across workflows.


General bookmark commands
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  The first three of these commands accept multiple selected bookmarks.
  This can be made easier by leveraging Emacs completion packages such
  as [orderless] which adds regexp matching. This is even more
  convenient in combination with a package like [vertico].

  • `bufferlo-bookmarks-load-interactive' (alias `bufferlo-bms-load'):
    Load one or more stored saved bufferlo frame or tab bookmarks.

  • `bufferlo-bookmarks-load': load stored bufferlo bookmarks that match
    your load predicates, or load all when using a prefix argument or
    when you call the function using passing t as its sole argument.
    Bookmarks already loaded are ignored.

  • `bufferlo-bookmarks-save-interactive' (alias `bufferlo-bms-save'):
    Save one or more currently active bufferlo frame or tab bookmarks.

  • `bufferlo-bookmarks-save': save active bufferlo bookmarks that match
    your save predicates, or save all when using a prefix argument or
    when you call the function using passing t as its sole argument.

  • `bufferlo-bookmarks-close-interactive' (alias `bufferlo-bms-close'):
    Close one or more currently active bufferlo frame or tab bookmarks,
    killing the buffers from each local buffer list. You will not be
    prompted to save bookmarks or further confirm buffer kills except
    where their content requires saving or contain active processes;
    e.g., `*shell*' buffers.

  • `bufferlo-bookmarks-close': Close all active bufferlo frame and tab
    bookmarks and kill their buffers. You will be prompted to save
    bookmarks using filter predicates or all unless a prefix argument is
    specified to inhibit the prompt and rely on your default policy.

  • `bufferlo-bookmark-raise' (alias `bufferlo-bm-raise'): Select the
    frame and/or frame/tab of the chosen active bookmark. Note: If you
    have duplicate active bookmarks, the first one found wins.

  • `bufferlo-clear-active-bookmarks' Clear all active bufferlo frame
    and tab bookmarks. This leaves frames and tabs intact, content
    untouched, and does not impact stored bookmarks. You will be
    prompted to confirm clearing (which cannot be undone) unless a
    prefix argument is specified to inhibit the prompt.

    This is useful when you have accumulated a complex working set of
    frames, tabs, buffers and want to save new bookmarks without
    disturbing existing bookmarks, or where auto-saving is enabled and
    you want to avoid overwriting stored bookmarks, perhaps with
    transient work.

  • `bufferlo-maybe-clear-active-bookmark' Clear the current frame
    and/or tab bufferlo bookmark. By default, this clears the active
    bookmark name only if there is another active bufferlo bookmark with
    the same name. Use a prefix argument or call the function with t to
    force clear the bookmark even if it is currently unique.

    This is useful if an active bookmark has been loaded more than once,
    and especially if you use the auto-save feature and want to ensure
    that only one bookmark is active.

  • `bookmark-bmenu-list': Typically bound to `C-x r l', this loads the
    standard Emacs bookmark menu to select a bookmark and manage the
    bookmark list including non-bufferlo bookmarks. Bufferlo frame
    bookmarks are identified as "B-Frame", tab bookmarks as "B-Tab", and
    bookmark sets as "B-Set".

  • `bookmark-rename': Invoke this command to rename a bookmark. This
    command will refuse to rename an active bufferlo bookmark (close or
    clear it and then rename). This function is also available via
    `bookmark-bmenu-list'.

  • `bookmark-delete': Invoke this command to delete a bookmark. This
    command will refuse to delete an active bufferlo bookmark (close or
    clear it and then delete). This function is also available via
    `bookmark-bmenu-list'.

  Note: Renaming or deleting a bufferlo tab or frame bookmark does not
  rename or delete references to those bookmarks within bookmark sets.


[orderless] <https://github.com/oantolin/orderless>

[vertico] <https://github.com/minad/vertico>


Frame bookmark commands
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  • `bufferlo-bookmark-frame-save' (alias `bufferlo-bm-frame-save'):
    Save a bookmark for the current frame under a new name or pick an
    existing name to reuse.

  • `bufferlo-bookmark-frame-save-current' (alias
    `bufferlo-bm-frame-save-curr'): Update the existing bookmark for the
    current frame.

  • `bufferlo-bookmark-frame-load' (alias `bufferlo-bm-frame-load'):
    Load a frame bookmark. This will overwrite your current frame
    content (no buffers are killed). Use a prefix argument to inhibit
    creating a new frame.

  • `bufferlo-bookmark-frame-load-current' (alias
    `bufferlo-bm-frame-load-curr'): Reload the existing bookmark for the
    current frame. This will overwrite your current frame content (no
    buffers are killed).

  • `bufferlo-bookmark-frame-load-merge' (alias
    `bufferlo-bm-frame-load-merge'): Load a frame bookmark, but instead
    of creating a new frame or overwriting the current frame content,
    this adds the loaded tabs into the current frame.


Tab bookmark commands
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  • `bufferlo-bookmark-tab-save' (alias `bufferlo-bm-tab-save'): Save a
    bookmark for the current tab under a new name or pick an existing
    name to reuse.

  • `bufferlo-bookmark-tab-save-current' (alias
    `bufferlo-bm-tab-save-curr'): Update the existing bookmark for the
    current tab (no buffers are killed).

  • `bufferlo-bookmark-tab-load' (alias `bufferlo-bm-tab-load'): Load a
    tab bookmark. This will overwrite your current tab content (no
    buffers are killed). Use a prefix argument to inhibit creating a new
    tab.

  • `bufferlo-bookmark-tab-load-current' (alias
    `bufferlo-bm-tab-load-curr'): Reload the existing bookmark for the
    current tab. This will overwrite your current tab content (no
    buffers are killed).


Bookmark set commands
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  • `bufferlo-set-save-interactive' (alias `bufferlo-set-save'): Save a
    bufferlo bookmark set for the specified active bookmarks. Frame
    bookmark names are stored along with their geometry for optional
    restoration. Tab bookmark names are grouped based on their shared
    frames along with each frame's geometry.

  • `bufferlo-set-save-current-interactive' (alias
    `bufferlo-set-save-curr'): Update the content of all active
    constituent bookmarks in selected bookmark sets.

  • `bufferlo-set-load-interactive' (alias `bufferlo-set-load'): Prompt
    to load bufferlo set bookmarks. This will restore each set's
    constituent frame and tab bookmarks along with the tab bookmarks'
    shared frames. Frame geometry is optionally restored.

  • `bufferlo-set-clear-interactive' (alias `bufferlo-set-clear'): Clear
    the specified bookmark sets. This has the effect of leaving the
    set's constituent frame and tab bookmarks in place while indicating
    that the bookmark sets are no longer active.

  • `bufferlo-set-close-interactive' (alias `bufferlo-set-close'): Close
    the specified bookmark sets. This closes their constituent bookmarks
    and kills their buffers.

  • `bufferlo-set-list-interactive' (alias `bufferlo-set-list'): List
    the constituent bookmarks of the selected active sets in a
    `special-mode' buffer and pop to it. The display shows each
    bookmark's name, its type, the frame it's currently on, and, if a
    tab bookmark, its tab number. Typing `<RET>' or clicking `mouse-1'
    will raise the selected bookmark. Type "q" to quit.

  Notes:

  • To curate a saved bookmark set, invoke
    `bufferlo-set-save-interactive' and save a new set of active
    bookmarks, replacing the existing bookmark set.
  • Bookmark sets are unaware of constituent frame and tab bookmark
    renames or deletes.
  • Bookmark sets are Emacs bookmarks and can be deleted or renamed
    using Emacs bookmark commands; e.g., via `bookmark-bmenu-list'.
  • While bookmark sets can be auto loaded, just as individual frame and
    tab bookmarks can be, bookmark sets cannot themselves be auto-saved.
    Constituent bookmarks are saved individually based on your auto-save
    predicates.


DWIM commands
╌╌╌╌╌╌╌╌╌╌╌╌╌

  These do-what-I-mean aka DWIM commands are conveniences that detect an
  active frame or tab bookmark avoiding the need to to specify the frame
  or tab variants of the equivalent commands.

  Note: Bufferlo DWIM commands prioritize frame bookmarks over tab
  bookmarks should both exist.

  • `bufferlo-bookmark-save-curr' (alias `bufferlo-bm-save'): Save the
    current frame or tab bookmark. This does not prompt to save a new
    bookmark if no bookmark is established.

  • `bufferlo-bookmark-load-curr' (alias `bufferlo-bm-load'): Reload the
    current frame or tab bookmark. This does not prompt to load a new
    bookmark if no bookmark is established.

  • `bufferlo-bookmark-close-curr' (alias `bufferlo-bm-close'): Close
    current frame or tab bookmark and kill its buffers.


Bufferlo buffer killing policies
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  To control bufferlo confirmation prompts when killing local or orphan
  buffers:
  ┌────
  │ (setq bufferlo-kill-buffers-prompt t) ; default nil
  └────

  To control bufferlo behavior when closing frame or tab bookmarks and
  killing their local modified buffers or process buffers such as
  `shell-mode' or `eshell-mode':
  ┌────
  │ (setq bufferlo-kill-modified-buffers-policy nil) ; use normal Emacs prompting behavior
  │ (setq bufferlo-kill-modified-buffers-policy 'retain-modified) ; kill just unmodified
  │ (setq bufferlo-kill-modified-buffers-policy 'retain-modified-kill-without-file-name) ; kill unmodified and buffers without files
  │ (setq bufferlo-kill-modified-buffers-policy 'kill-modified) ; kill local buffers without prompting; the default
  └────


Automatic bookmark saving
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  You can configure bufferlo to automatically save some or all bookmarks
  based on an interval timer and/or at Emacs exit. Similarly, you can
  configure bufferlo to automatically load some or all bookmarks at
  Emacs startup.

  To set the automatic save timer, set the number of whole integer
  seconds between saves that you prefer, or 0, the default, to disable
  the timer:
  ┌────
  │ (setq bufferlo-bookmarks-auto-save-interval 120) ; do this in advance of enabling `bufferlo-mode'
  │ (setopt bufferlo-bookmarks-auto-save-interval 120) ; or use setopt, to invoke the custom setter
  └────

  By default, bufferlo will save all active bookmarks. To select the
  subset of bookmarks you want to save, write one or more predicate
  tests that accept a bookmark name as its argument; it should return t
  to indicate to save the bookmark, or nil otherwise.

  Example auto-save predicate:

  ┌────
  │ (defun my/bufferlo-bookmarks-save-p (bookmark-name)
  │   "Auto save bufferlo bookmarks that contain \"=as\" for autosave."
  │   (string-match-p (rx "=as") bookmark-name))
  │ (setq bufferlo-bookmarks-save-predicate-functions nil) ; clear the default #'bufferlo-bookmarks-save-all-p
  │ (add-hook 'bufferlo-bookmarks-save-predicate-functions #'my/bufferlo-bookmarks-save-p)
  └────

  You can control messages produced when bufferlo saves bookmarks:

  ┌────
  │ (setq bufferlo-bookmarks-auto-save-messages nil) ; inhibit messages (default)
  │ (setq bufferlo-bookmarks-auto-save-messages t) ; messages when saving and when there are no bookmarks to save
  │ (setq bufferlo-bookmarks-auto-save-messages 'saved) ; message only when bookmarks are saved
  │ (setq bufferlo-bookmarks-auto-save-messages 'notsaved) ; message only when there are no bookmarks to save
  └────

  To save your bufferlo bookmarks when frames and tabs are closed:

  ┌────
  │ (setq bufferlo-bookmark-frame-save-on-delete 'if-current)
  │ (setq bufferlo-bookmark-tab-save-on-close 'if-current)
  │ ;; See the variables' documentation for more options
  └────

  To save your bufferlo bookmarks at Emacs exit (set in advance of
  enabling `bufferlo-mode'):

  ┌────
  │ (setq bufferlo-bookmarks-save-at-emacs-exit 'nosave) ; inhibit saving at exit (default)
  │ (setq bufferlo-bookmarks-save-at-emacs-exit 'pred) ; save active bookmark names that match your predicates
  │ (setq bufferlo-bookmarks-save-at-emacs-exit 'all) ; save all active bookmarks
  └────

  Workflow tip: If you would like to be able to restore a bookmark's
  original state and still benefit from auto-saving its current state,
  simply save two copies. The first one with a base name; e.g.,
  "bufferlo", and the second, which you should save immediately after
  the first, called; e.g., "bufferlo=as". You can restore "bufferlo" and
  get back to your original any time while the "=as" bookmark will save
  your context as you work. Switch between them as you see fit.


Automatic bookmark loading
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  To automatically load some or all bufferlo bookmarks at Emacs startup
  time (bufferlo uses `window-setup-hook' to load bookmarks after your
  init.el has completed to maximize the chances for successful loading):
  ┌────
  │ (setq bufferlo-bookmarks-load-at-emacs-startup 'noload) ; inhibit loading at startup (default)
  │ (setq bufferlo-bookmarks-load-at-emacs-startup 'pred) ; load bookmark names that match your predicates
  │ (setq bufferlo-bookmarks-load-at-emacs-startup 'all) ; load all bufferlo bookmarks
  └────

  To make a new frame to hold restored tabs at startup, or reuse the
  initial frame:
  ┌────
  │ (setq bufferlo-bookmarks-load-at-emacs-startup-tabs-make-frame nil) ; reuse the initial frame (default)
  │ (setq bufferlo-bookmarks-load-at-emacs-startup-tabs-make-frame t) ; make a new frame
  └────

  Example auto-load predicate:
  ┌────
  │ (setq 'bufferlo-bookmarks-load-predicate-functions #'bufferlo-bookmarks-load-all-p) ; loads all bookmarks
  │ 
  │ (defun my/bufferlo-bookmarks-load-p (bookmark-name)
  │   "Auto load bufferlo bookmarks that contain \"=al\"for autoload"
  │   (string-match-p (rx "=al") bookmark-name))
  │ (add-hook 'bufferlo-bookmarks-load-predicate-functions #'my/bufferlo-bookmarks-load-p)
  └────

  If you have configured bufferlo to load bookmarks at Emacs startup,
  you can inhibit bookmark loading without changing your configuration
  by either using the command line or a semaphore file in your
  `user-emacs-directory':
  ┌────
  │ $ emacs --bufferlo-noload
  │ $ touch ~/.emacs.d/bufferlo-noload # remove it to reenable automatic loading
  └────


Filter saved bookmark buffers
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  By default, bufferlo will save all buffers in the local frame/tab
  buffer list, using Emacs facilities to bookmark what's bookmarkable
  for restoration. You might want to exclude transient buffers
  `*Completions*' or `*Help*' or those which may not have bookmark
  support such as `*shell*' buffers. To do that, combine the following
  two variables, the first to exclude what you want to filter, and the
  second to ensure that the buffers you want to keep from the first
  filter are added back. For example:
  ┌────
  │ (setq bufferlo-bookmark-buffers-exclude-filters
  │       (list
  │        (rx bos " " (1+ anything)) ; ignores "invisible" buffers; e.g., " *Minibuf...", " markdown-code-fontification:..."
  │        (rx bos "*" (1+ anything) "*") ; ignores "special" buffers; e.g;, "*Messages*", "*scratch*", "*occur*"
  │        ))
  │ 
  │ (setq bufferlo-bookmark-buffers-include-filters
  │       (list
  │        (rx bos "*shell*") ; if you have shell bookmark support
  │        (rx bos "*" (1+ anything) "-shell*") ; project.el shell buffers
  │        (rx bos "*eshell*")
  │        (rx bos "*" (1+ anything) "-eshell*") ; project.el eshell buffers
  │        ))
  └────


Bookmark duplicates
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Bufferlo can discourage you from using multiple duplicate active
  bookmarks, but does not prevent them. Having duplicates is confusing
  and they present a race condition when saving as all copies will be
  saved, overwriting one another without regard to ordering, with the
  last one saved winning the race.

  Note: The options to prevent duplicates are not enabled by default to
  maintain backward compatibility with previous versions of bufferlo,
  but they are likely to be enabled by default in the future.

  ┌────
  │ (setq bufferlo-bookmarks-save-duplicates-policy 'prompt) ; default
  │ (setq bufferlo-bookmarks-save-duplicates-policy 'allow) ; old default behavior
  │ (setq bufferlo-bookmarks-save-duplicates-policy 'disallow) ; even better
  └────


Save current, other, or all frame bookmarks
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  If you use batch or automatic saving, this option lets you control
  which frames' bookmarks are saved. For example, some prefer not to
  have their current working set be saved unless and until they choose.

  ┌────
  │ (setq bufferlo-bookmarks-save-frame-policy 'all) ; default
  │ (setq bufferlo-bookmarks-save-frame-policy 'other) ; saves unselected frames' bookmarks
  │ (setq bufferlo-bookmarks-save-frame-policy 'current) ; saves only the current frame bookmarks
  └────


Frame bookmark options
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Refine these options to suit your workflow as you gain experience with
  bufferlo. Refer to each option's documentation for additional
  settings.

  ┌────
  │ ;; make a new frame to hold loaded frame bookmarks
  │ (setq bufferlo-bookmark-frame-load-make-frame t) ; default is nil for backward compatibility
  │ (setq bufferlo-bookmark-frame-load-make-frame 'restore-geometry)
  └────
  ┌────
  │ ;; policy when loading onto an already bookmarked frame
  │ (setq bufferlo-bookmark-frame-load-policy 'prompt) ; default
  │ (setq bufferlo-bookmark-frame-load-policy 'replace-frame-retain-current-bookmark) ; old default behavior
  │ (setq bufferlo-bookmark-frame-load-policy 'replace-frame-adopt-loaded-bookmark)
  │ (setq bufferlo-bookmark-frame-load-policy 'merge) ; best selected via prompting to merge new tabs into the existing frame
  └────
  ┌────
  │ ;; allow duplicate active frame bookmarks in the Emacs session
  │ (setq bufferlo-bookmark-frame-duplicate-policy 'prompt) ; default
  │ (setq bufferlo-bookmark-frame-duplicate-policy 'allow) ; old default behavior
  │ (setq bufferlo-bookmark-frame-duplicate-policy 'clear) ; silently clear the loaded frame bookmark
  │ (setq bufferlo-bookmark-frame-duplicate-policy 'clear-warn) ; clear the loaded frame bookmark with a message
  │ (setq bufferlo-bookmark-frame-duplicate-policy 'ignore) ; bypass loading the duplicate frame bookmark
  │ (setq bufferlo-bookmark-frame-duplicate-policy 'raise) ; do not load, raise the existing frame
  └────
  Note: 'raise is considered to act as 'clear by bookmark set loading.


Tab bookmark options
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Refine these options to suit your workflow as you gain experience with
  bufferlo. Refer to each option's documentation for additional
  settings.

  ┌────
  │ ;; make a new frame when loading a a batch of tab bookmarks
  │ (setq bufferlo-bookmarks-load-tabs-make-frame nil) ; default, it reuses the current frame
  │ (setq bufferlo-bookmarks-load-tabs-make-frame t) ; make a new tab when loading a batch of tab bookmarks
  └────
  ┌────
  │ ;; load a tab bookmark replacing the current tab or making a new tab
  │ (setq bufferlo-bookmark-tab-replace-policy 'replace) ; default (backward compatible behavior)
  │ (setq bufferlo-bookmark-tab-replace-policy 'new)
  └────
  ┌────
  │ ;; allow duplicate active tab bookmarks in the Emacs session
  │ (setq bufferlo-bookmark-tab-duplicate-policy 'prompt) ; default
  │ (setq bufferlo-bookmark-tab-duplicate-policy 'allow) ; old default behavior
  │ (setq bufferlo-bookmark-tab-duplicate-policy 'clear) ; silently clear the loaded tab bookmark
  │ (setq bufferlo-bookmark-tab-duplicate-policy 'clear-warn) ; clear the loaded tab bookmark with a message
  │ (setq bufferlo-bookmark-tab-duplicate-policy 'ignore) ; bypass loading the duplicate tab bookmark
  │ (setq bufferlo-bookmark-tab-duplicate-policy 'raise) ; do not load, raise the existing frame/tab
  └────
  Note: 'raise is considered to act as 'clear by bookmark set loading.
  ┌────
  │ ;; allow inferior tab bookmark on a bookmarked frame (Note: frame bookmarks supersede tab bookmarks when saving)
  │ (setq bufferlo-bookmark-tab-in-bookmarked-frame-policy 'prompt) ; default
  │ (setq bufferlo-bookmark-tab-in-bookmarked-frame-policy 'allow) ; old default behavior
  │ (setq bufferlo-bookmark-tab-in-bookmarked-frame-policy 'clear) ; silently clear the loaded tab bookmark
  │ (setq bufferlo-bookmark-tab-in-bookmarked-frame-policy 'clear-warn) ; clear the loaded tab bookmark with a message
  └────
  ┌────
  │ ;; handle buffer bookmarks that could not be restored
  │ (setq bufferlo-bookmark-tab-failed-buffer-policy nil) ; ignore; the default
  │ (setq bufferlo-bookmark-tab-failed-buffer-policy 'placeholder) ; placeholder buffer and buffer name
  │ (setq bufferlo-bookmark-tab-failed-buffer-policy 'placeholder-orig) ; placeholder buffer with original buffer name
  │ (setq bufferlo-bookmark-tab-failed-buffer-policy "*scratch*") ; default to a specific buffer
  │ (setq bufferlo-bookmark-tab-failed-buffer-policy #'my/failed-bookmark-handler) ; function to call that returns a buffer
  └────


Bookmark set options
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Refine these options to suit your workflow as you gain experience with
  bufferlo. Refer to each option's documentation for additional
  settings.

  ┌────
  │ ;; frame geometry restoration policy
  │ (setq bufferlo-set-restore-geometry-policy 'all) ; restore frame and tab-frame geometries; the default
  │ (setq bufferlo-set-restore-geometry-policy 'frames) ; restore only frame geometries
  │ (setq bufferlo-set-restore-geometry-policy 'tab-frames) ; restore only tab-frame geometries
  └────

  The following option is useful for auto-loading bookmark sets at
  startup time or overlaying constituent tabs in the frame from which a
  bookmark set is loaded.

  ┌────
  │ ;; make a new frame when loading a a batch of tab bookmarks
  │ (setq bufferlo-set-restore-tabs-reuse-init-frame 'reuse) ; reuse the existing first frame; the default
  │ (setq bufferlo-set-restore-tabs-reuse-init-frame 'reuse-reset-geometry) ; like 'reuse but also alters the reused frame's geometry
  │ (setq bufferlo-set-restore-tabs-reuse-init-frame nil) ; always make new frames
  └────

  ┌────
  │ ;; ignore already-active bufferlo bookmarks when loading a bookmark set
  │ (setq bufferlo-set-restore-ignore-already-active nil) ; prompt for each duplicate bookmark; the default
  │ (setq bufferlo-set-restore-ignore-already-active 'prompt) ; prompt to ignore already-active bookmarks in bulk
  │ (setq bufferlo-set-restore-ignore-already-active 'ignore) ; always ignore already-active bookmarks
  └────


Bookmark handler hooks
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  You can add your own functions to the following abnormal hooks to be
  called upon successful loading of tab, frame, and set bookmarks. See
  the docstrings for each function for its calling conventions.

  Example: You could use a tab handler function to set the tab-bar group
  for each loaded tab to its source bookmark name. While tab-bar does
  have `tab-bar-tab-post-open-functions', the bookmark context will not
  be available when those functions are called.

  ┌────
  │ (add-hook 'bufferlo-bookmark-tab-handler-functions #'tab-bookmark-fun)
  │ (add-hook 'bufferlo-bookmark-frame-handler-functions #'frame-bookmark-fun)
  │ (add-hook 'bufferlo-bookmark-set-handler-functions #'set-bookmark-fun)
  └────


Frame geometry options
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Bufferlo provides wrappers around Emacs frame functions to provide
  more precision. This is due to issues that affect `make-frame' and
  hence `frameset-restore'. One bug preventing pixel-level precision was
  reported and fixed for Emacs 31.

  Frames stored in bufferlo frame bookmarks have their geometries stored
  individually and are recreated on demand. Bookmark sets frame
  collections are implemented via `frameset-save' and are restored by
  Emacs en masse.

  Frame bookmarks saved via Emacs tty will not store a frame geometry
  (none available on tty). Conversely, frame bookmarks saved via GUI and
  restored on tty will ignore frame geometry.

  Note: See below to adjust `bufferlo-frame-sleep-for' for your window
  manager.

  Note: Not much testing has been done in hybrid tty/GUI environments
  using `emacsclient', or with multi-display setups where frames may be
  expected to be restored on their originating displays.

  ┌────
  │ ;; function to determine a frame's pixelwise geometry (it is not
  │ ;; likely you will need to replace this--but is provided just in case)
  │ (setq bufferlo-frame-geometry-function #'bufferlo-frame-geometry-default) ; the default uses text-width and text-height
  │ (setq bufferlo-frame-geometry-function #'my/bufferlo-frame-geometry) ; or your own
  └────
  ┌────
  │ ;; function to set a frame's pixelwise geometry (it is not likely you
  │ ;; will need to replace this--but is provided just in case)
  │ (setq bufferlo-set-frame-geometry-function #'bufferlo-set-frame-geometry-default)
  │ (setq bufferlo-set-frame-geometry-function #'my/bufferlo-set-frame-geometry) ; or your own
  └────
  ┌────
  │ ;; seconds to sleep after each frame parameter change that requires
  │ ;; external window manager cooperation.
  │ (setq bufferlo-frame-sleep-for 0) ; the default, which seems to work on macOS
  │ (setq bufferlo-frame-sleep-for 0.3) ; seems to work for GTK/GNOME
  └────

  ┌────
  │ ;; methodology for bookmark-set frameset geometry restoration
  │ (setq bufferlo-frameset-restore-geometry 'bufferlo) ; the pixel-level precision default
  │ (setq bufferlo-frameset-restore-geometry 'native) ; uses `frameset-restore' geometry handling (buggy pre Emacs 31)
  │ (setq bufferlo-frameset-restore-geometry nil) ; inhibit frame geometry restoration
  └────
  ┌────
  │ ;; inhibit additional frame parameter symbols from being stored by `frameset-save'
  │ (setq bufferlo-frameset-save-filter nil)
  │ (setq bufferlo-frameset-save-filter '(my:frame-id ; practical example
  │ 				      zoom--frame-snapshot))
  └────
  ┌────
  │ ;; inhibit additional frame parameter symbols from being restored by `frameset-restore'
  │ (setq bufferlo-frameset-restore-filter nil)
  └────
  ┌────
  │ ;; you can override bufferlos `frameset-restore' wrapper should you need to
  │ (setq bufferlo-frameset-restore-function #'bufferlo-frameset-restore-default) ; the default
  │ ;; a practical example that inhibits user-configured
  │ ;; `after-make-frame-functions' frame maximization by let-binding
  │ ;; my:frame-maximize to nil allowing `frameset-restore' and bufferlo
  │ ;; to control restored frame geometry.
  │ (defun my/bufferlo-frameset-restore-function (frameset)
  │   (let ((my:frame-maximize nil))
  │     (bufferlo-frameset-restore-default frameset)))
  │ (setq bufferlo-frameset-restore-function #'my/bufferlo-frameset-restore-function)
  └────
  ┌────
  │ (setq bufferlo-frameset-restore-parameters-function #'bufferlo-frameset-restore-parameters-default) ; default
  │ ;; a practical example where Emacs Linux/GTK behaves differently vs. macOS
  │ (defun my/bufferlo-frameset-restore-parameters ()
  │   "Function to create parameters for `frameset-restore', which see."
  │   (cond (my:on-linux-gnome
  │ 	 (list :reuse-frames nil
  │ 	       :force-display nil ; bufferlo defaults to t which works on macOS
  │ 	       :force-onscreen (display-graphic-p)
  │ 	       :cleanup-frames nil))
  │ 	(t
  │ 	 (bufferlo-frameset-restore-parameters-default))))
  │ (setq bufferlo-frameset-restore-parameters-function #'my/bufferlo-frameset-restore-parameters)
  └────


Bookmark addenda
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Emacs bookmarks do not store your file or buffer contents, only
  references to your files and buffers. Many Emacs modes support Emacs
  bookmarks and can be saved and recalled including `eshell' and
  `magit-status' buffers. The state of non-bookmarkable buffers is not
  saved. However, during bookmark saving, they are included in the
  bookmark record. Emacs 31 has support for `shell-mode' local and
  remote buffer bookmarks.

  Restoring bookmarks correctly handles renamed buffers with unchanged
  file association (e.g., when Emacs had to "uniquify" buffer names).

  If files are deleted between Emacs sessions and a bookmarked buffer
  cannot be restored, after loading a bookmark with a missing file, a
  message similar to this can be found in your `*Messages*' buffer:

  `Bufferlo bookmark: Could not restore file.txt (error
  (bookmark-error-no-filename stringp /etc/file.txt))'

  Please note: Emacs `bookmark-jump-other-frame' and
  `bookmark-jump-other-window' commands are not compatible with bufferlo
  bookmarks. A future version of bufferlo might wrap these functions for
  convenience to either provide a warning or provide alternative jump
  functionality.

  It can be convenient to share bookmark files among your computers or
  among colleagues. Bookmarks can be made more "portable" with the
  following assumptions:

  • You share an Emacs configuration including packages, mode settings,
    etc.

  • You share a directory hierarchy for files in common such as
    programming or writing projects on which you collaborate.


Mode line
─────────

  Bufferlo's default mode-line indicator shows the currently active
  frame- and/or tab-bookmark name and also indicates if at least one
  bookmark set is active.

  • If you prefer iconic mode-line prefixes, set one like this:
  ┌────
  │ (setq bufferlo-mode-line-prefix "🐮") ; bufferlos are cows
  │ (setq bufferlo-mode-line-prefix "🐃") ; some are water bufferlos
  │ (setq bufferlo-mode-line-prefix "Bfl") ; the text default
  └────
  • To disable bufferlo's mode-line or provide your own custom mode-line
    function:
  ┌────
  │ (setq bufferlo-mode-line nil) ; disable the bufferlo mode-line
  │ (setq bufferlo-mode-line #'my/bufferlo-mode-line) ; or use your own
  └────
  • To control the appearance of other mode-line features:
  ┌────
  │ (setq bufferlo-mode-line-set-active-prefix "Ⓢ")
  │ (setq bufferlo-mode-line-frame-prefix "Ⓕ")
  │ (setq bufferlo-mode-line-tab-prefix "Ⓣ")
  │ (setq bufferlo-mode-line-left-prefix nil) ; default "[" similar to flymake
  │ (setq bufferlo-mode-line-right-suffix nil) ; default "]"
  └────
  • To control mode-line faces:
  ┌────
  │ (set-face-attribute 'bufferlo-mode-line-face nil
  │ 		    :box '(:line-width (-1 . -1) :color "#8aca9f")
  │ 		    :height 0.85)
  │ ;; below inherit bufferlo-mode-line-face
  │ (set-face-attribute 'bufferlo-mode-line-frame-bookmark-face nil
  │ 		    :foreground "#8aca0f")
  │ (set-face-attribute 'bufferlo-mode-line-tab-bookmark-face nil
  │ 		    :foreground "#00ffff")
  │ (set-face-attribute 'bufferlo-mode-line-set-face nil
  │ 		    :foreground "#000fff")
  └────


Menu bar
────────

  Bufferlo enables its menu bar entry by default to encourage feature
  discovery and menu-item entries are adorned with key mappings from
  your configuration.

  Note: Due to a limitation in Emacs where it does not reference key
  bindings of commands via aliases, you must provide key mappings on
  bufferlo's aliased commands, as the menu is defined in alias terms. We
  default to aliases to reduce the text displayed by `which-key-mode' to
  a readable width vs. fully-qualified command names.

  ┌────
  │ ;; To control the menu bar visibility before package initialization
  │ (setq bufferlo-menu-bar-show t) ; the default
  │ (setq bufferlo-menu-bar-show nil)
  └────

  ┌────
  │ ;; bufferlo menu buffer window behavior
  │ (setq bufferlo-menu-bar-list-buffers 'simple) ; show buffer lists using `Buffer-menu-mode'
  │ (setq bufferlo-menu-bar-list-buffers 'ibuffer) ; show buffer lists using `ibuffer'
  │ (setq bufferlo-menu-bar-list-buffers 'both) ; show both options; the default
  │ (setq bufferlo-menu-bar-list-buffers nil) ; show neither
  └────


Initial buffer
──────────────

  By default, the currently-active buffer is shown in a newly created
  tab so this buffer inevitably ends up in the new tab's local buffer
  list. You can change the initial buffer by customizing
  `tab-bar-new-tab-choice':
  ┌────
  │ (setq tab-bar-new-tab-choice "*scratch*") ; or another buffer of your choice
  └────
  This lets new tabs always start with the `*scratch*' buffer.

  You can also create a local scratch buffer for each tab:
  ┌────
  │ (setq tab-bar-new-tab-choice #'bufferlo-create-local-scratch-buffer)
  └────
  You can customize the name of the local scratch buffers by setting
  `bufferlo-local-scratch-buffer-name'.

  The same can be achieved for new frames. Use this to set the scratch
  buffer as the initial buffer for new frames:
  ┌────
  │ (add-hook 'after-make-frame-functions #'bufferlo-switch-to-scratch-buffer)
  └────

  Alternatively, create a new local scratch buffer for new frames:
  ┌────
  │ (add-hook 'after-make-frame-functions #'bufferlo-switch-to-local-scratch-buffer)
  └────

  You can also set an arbitrary buffer as the initial frame buffer:
  ┌────
  │ (defun my/set-initial-frame-buffer (frame)
  │   (with-selected-frame frame
  │     (switch-to-buffer "<BUFFER_NAME>")))
  │ (add-hook 'after-make-frame-functions #'my/set-initial-frame-buffer)
  └────


Bufferlo anywhere
─────────────────

  "Bufferlo anywhere" lets you have bufferlo's frame/tab-local buffer
  list anywhere you like, i.e. in any command with interactive buffer
  selection (via `read-buffer', e.g., `diff-buffers',
  `make-indirect-buffer', …) – not just in the switch-buffer facilities.
  You can configure which commands use bufferlo's local list and which
  use the global list.

  Enable `bufferlo-anywhere-mode' to use bufferlo's local buffer list by
  default.  Customize `bufferlo-anywhere-filter' and
  `bufferlo-anywhere-filter-type' to restrict the commands that use the
  local list.  With the command prefix
  `bufferlo-anywhere-disable-prefix', you can temporarily disable
  `bufferlo-anywhere-mode' for the next command.

  Instead of the minor mode, you can use the command prefix
  `bufferlo-anywhere-enable-prefix', which only temporarily enables
  bufferlo's local buffer list for the next command.


Package integration
═══════════════════

Consult
───────

  You can integrate bufferlo with `consult-buffer'.

  This is an example configuration:
  ┌────
  │ (defvar my:bufferlo-consult--source-local-buffer
  │   (list :name "Bufferlo Local Buffers"
  │ 	:narrow   ?l
  │ 	:category 'buffer
  │ 	:face     'consult-buffer
  │ 	:history  'buffer-name-history
  │ 	:state    #'consult--buffer-state
  │ 	:default  t
  │ 	:items    (lambda () (consult--buffer-query
  │ 			      :predicate #'bufferlo-local-buffer-p
  │ 			      :sort 'visibility
  │ 			      :as #'buffer-name)))
  │   "Local Bufferlo buffer candidate source for `consult-buffer'.")
  │ 
  │ (defvar my:bufferlo-consult--source-buffer
  │   (list :name "Bufferlo Other Buffers"
  │ 	:narrow   ?b
  │ 	:category 'buffer
  │ 	:face     'consult-buffer
  │ 	:history  'buffer-name-history
  │ 	:state    #'consult--buffer-state
  │ 	:items    (lambda () (consult--buffer-query
  │ 			      :predicate #'bufferlo-non-local-buffer-p
  │ 			      :sort 'visibility
  │ 			      :as #'buffer-name)))
  │   "Non-local Bufferlo buffer candidate source for `consult-buffer'.")
  │ 
  │ ;; add in the reverse order of display preference
  │ (add-to-list 'consult-buffer-sources 'my:bufferlo-consult--source-other-buffers)
  │ (add-to-list 'consult-buffer-sources 'my:bufferlo-consult--source-local-buffers)
  └────

  <./img/consult1.svg> Fig.1: All buffers are shown; the local buffers
  are grouped separately.

  You can also configure `consult-buffer' to hide the non-local buffers
  by default:
  ┌────
  │ (defvar my:bufferlo-consult--source-all-buffers
  │   (list :name "Bufferlo All Buffers"
  │ 	:narrow   ?a
  │ 	:hidden   t
  │ 	:category 'buffer
  │ 	:face     'consult-buffer
  │ 	:history  'buffer-name-history
  │ 	:state    #'consult--buffer-state
  │ 	:items    (lambda () (consult--buffer-query
  │ 			      :sort 'visibility
  │ 			      :as #'buffer-name)))
  │   "All Bufferlo buffer candidate source for `consult-buffer'.")
  │ 
  │ (defvar my:bufferlo-consult--source-local-buffers
  │   (list :name "Bufferlo Local Buffers"
  │ 	:narrow   ?l
  │ 	:category 'buffer
  │ 	:face     'consult-buffer
  │ 	:history  'buffer-name-history
  │ 	:state    #'consult--buffer-state
  │ 	:default  t
  │ 	:items    (lambda () (consult--buffer-query
  │ 			      :predicate #'bufferlo-local-buffer-p
  │ 			      :sort 'visibility
  │ 			      :as #'buffer-name)))
  │   "Local Bufferlo buffer candidate source for `consult-buffer'.")
  │ 
  │ ;; add in the reverse order of display preference
  │ (add-to-list 'consult-buffer-sources #'consult--source-hidden-buffer)
  │ (add-to-list 'consult-buffer-sources #'my:bufferlo-consult--source-all-buffers)
  │ (add-to-list 'consult-buffer-sources #'my:bufferlo-consult--source-local-buffers)
  └────

  <./img/consult2.svg> Fig.2: By entering 'a'+<space>, the global buffer
  list is shown ("All Buffers").

  A good alternative is to bind space to "All Buffers" (via `:narrow
  32'). By default, a space character prefix is used for hidden buffers
  (`consult--source-hidden-buffer'). If you still need the hidden buffer
  list, you can make a new source for it, for example, with period as
  the narrowing key (`:narrow ?.').


Ivy
───

  You can also integrate bufferlo with `ivy'.

  ┌────
  │ (defun ivy-bufferlo-switch-buffer ()
  │   "Switch to another local buffer.
  │ If the prefix arument is given, include all buffers."
  │     (interactive)
  │     (if current-prefix-arg
  │ 	(ivy-switch-buffer)
  │       (ivy-read "Switch to local buffer: " #'internal-complete-buffer
  │ 		:predicate (lambda (b) (bufferlo-local-buffer-p (cdr b)))
  │ 		:keymap ivy-switch-buffer-map
  │ 		:preselect (buffer-name (other-buffer (current-buffer)))
  │ 		:action #'ivy--switch-buffer-action
  │ 		:matcher #'ivy--switch-buffer-matcher
  │ 		:caller 'ivy-switch-buffer)))
  └────


shell-mode bookmarks
────────────────────

  We may post some code on the bufferlo wiki illustrate how to enable
  bookmarks for `shell-mode' buffers. We will help contribute this
  feature to Emacs 31.


save-place-mode
───────────────

  If you use `save-place-mode', and prefer to *always* use its
  buffer-position history, overriding bufferlo's saved bookmark
  positions, add this to your configuration:

  ┌────
  │ (setq bufferlo-bookmark-inhibit-bookmark-point t)
  └────

  This takes effect when saving or updating a bufferlo bookmark.
  Previously stored bufferlo bookmarks with an embedded point will
  remain in force until they are saved if this policy is set to t.


Complete configuration sample
─────────────────────────────

  ┌────
  │ (global-unset-key (kbd "C-z")) ; free C-z to use as a prefix key
  │ 
  │ (use-package bufferlo
  │   :demand t
  │   :after (ibuffer consult) ; also mark these :demand t or use explicit require
  │   :bind
  │   (
  │    ;; buffer / ibuffer
  │    ("C-z C-b" . bufferlo-ibuffer)
  │    ("C-z M-C-b" . bufferlo-ibuffer-orphans)
  │    ("C-z b -" . bufferlo-remove)
  │    ;; general bookmark (interactive)
  │    ("C-z b l" . bufferlo-bms-load)
  │    ("C-z b s" . bufferlo-bms-save)
  │    ("C-z b c" . bufferlo-bms-close)
  │    ("C-z b r" . bufferlo-bm-raise)
  │    ;; dwim frame or tab bookmarks
  │    ("C-z d s" . bufferlo-bm-save)
  │    ("C-z d l" . bufferlo-bm-load)
  │    ("C-z d 0" . bufferlo-bm-close)
  │    ;; tabs
  │    ("C-z t s" . bufferlo-bm-tab-save)               ; save
  │    ("C-z t u" . bufferlo-bm-tab-save-curr)          ; update
  │    ("C-z t l" . bufferlo-bm-tab-load)               ; load
  │    ("C-z t r" . bufferlo-bm-tab-load-curr)          ; reload
  │    ("C-z t 0" . bufferlo-bm-tab-close-curr)         ; kill
  │    ;; frames
  │    ("C-z f s" . bufferlo-bm-frame-save)             ; save
  │    ("C-z f u" . bufferlo-bm-frame-save-curr)        ; update
  │    ("C-z f l" . bufferlo-bm-frame-load)             ; load
  │    ("C-z f r" . bufferlo-bm-frame-load-curr)        ; reload
  │    ("C-z f m" . bufferlo-bm-frame-load-merge)       ; merge
  │    ("C-z f 0" . bufferlo-bm-frame-close-curr)       ; kill
  │    ;; sets
  │    ("C-z s s" . bufferlo-set-save)                  ; save
  │    ("C-z s u" . bufferlo-set-save-curr)             ; update
  │    ("C-z s l" . bufferlo-set-load)                  ; load
  │    ("C-z s 0" . bufferlo-set-close)                 ; kill
  │    ("C-z s c" . bufferlo-set-clear)                 ; clear
  │    ("C-z s L" . bufferlo-set-list)                  ; list contents of selected active sets
  │    )
  │   :init
  │   ;; these must be set before the bufferlo package is loaded
  │   (setq bufferlo-menu-bar-show t)
  │   (setq bufferlo-menu-bar-list-buffers 'ibuffer)
  │   (setq bufferlo-prefer-local-buffers 'tabs)
  │   (setq bufferlo-ibuffer-bind-local-buffer-filter t)
  │   (setq bufferlo-ibuffer-bind-keys t)
  │   :config
  │   (setq bufferlo-mode-line-prefix "🐃") ; "🐮"
  │   (setq bufferlo-mode-line-set-active-prefix "Ⓢ")
  │   (setq bufferlo-mode-line-frame-prefix "Ⓕ")
  │   (setq bufferlo-mode-line-tab-prefix "Ⓣ")
  │   (setq bufferlo-mode-line-left-prefix nil)
  │   (setq bufferlo-mode-line-right-suffix nil)
  │   (setq switch-to-prev-buffer-skip-regexp
  │ 	(concat "\\` *"
  │ 		"\\(\\*\\(" ; earmuffs
  │ 		(mapconcat #'identity
  │ 			   '("Messages"
  │ 			     "Buffer List"
  │ 			     "Ibuffer"
  │ 			     "Local Buffer List" ; bufferlo
  │ 			     "scratch"
  │ 			     "Occur"
  │ 			     "Completions"
  │ 			     "Help"
  │ 			     "Warnings"
  │ 			     "Apropos"
  │ 			     "Bookmark List"
  │ 			     "Async-native-compile-log"
  │ 			     "Flymake log"
  │ 			     "ruff-format errors"
  │ 			     "vc-diff")
  │ 			   "\\|")
  │ 		"\\)\\*\\)"
  │ 		"\\|" (rx "*" (1+ anything) " Ibuffer*")
  │ 		"\\|" (rx "*helpful " (1+ anything) "*")
  │ 		"\\|" (rx "*tramp" (1+ anything) "*")
  │ 		"\\|" (rx "magit" (* anything) ": " (1+ anything))
  │ 		"\\'"))
  │   (setq bufferlo-kill-buffers-prompt t)
  │   (setq bufferlo-kill-modified-buffers-policy 'retain-modified-kill-without-file-name) ; nil 'retain-modified 'retain-modified-kill-without-file-name 'kill-modified
  │   (setq bufferlo-bookmark-inhibit-bookmark-point t)
  │   (setq bufferlo-delete-frame-kill-buffers-prompt t)
  │   (setq bufferlo-bookmark-frame-save-on-delete 'when-bookmarked)
  │   (setq bufferlo-bookmark-tab-save-on-close 'when-bookmarked)
  │   (setq bufferlo-close-tab-kill-buffers-prompt t)
  │   (setq bufferlo-bookmark-frame-load-make-frame 'restore-geometry)
  │   (setq bufferlo-bookmark-frame-load-policy 'prompt)
  │   (setq bufferlo-bookmark-frame-duplicate-policy 'prompt)
  │   (setq bufferlo-bookmark-tab-replace-policy 'new)
  │   (setq bufferlo-bookmark-tab-duplicate-policy 'prompt)
  │   (setq bufferlo-bookmark-tab-in-bookmarked-frame-policy 'prompt)
  │   (setq bufferlo-bookmark-tab-failed-buffer-policy 'placeholder)
  │   (setq bufferlo-bookmarks-save-duplicates-policy 'prompt)
  │   (setq bufferlo-bookmarks-save-frame-policy 'all)
  │   (setq bufferlo-bookmarks-load-tabs-make-frame t)
  │   (setq bufferlo-bookmarks-save-at-emacs-exit 'all)
  │   (setq bufferlo-bookmarks-load-at-emacs-startup 'pred)
  │   (setq bufferlo-bookmarks-load-at-emacs-startup-tabs-make-frame nil)
  │   (setopt bufferlo-bookmarks-auto-save-interval (* 60 5)) ; 5 minutes
  │   (setq bufferlo-bookmarks-auto-save-messages 'saved)
  │   (setq bufferlo-set-restore-geometry-policy 'all)
  │   (setq bufferlo-set-restore-tabs-reuse-init-frame 'reuse) ; nil 'reuse 'reuse-reset-geometry
  │   (setq bufferlo-set-restore-ignore-already-active 'prompt) ; nil 'prompt 'ignore
  │   (setq bufferlo-frameset-restore-geometry 'bufferlo)
  │   (setq bufferlo-frame-geometry-function #'bufferlo-frame-geometry-default)
  │   (setq bufferlo-frame-sleep-for 0.3)
  │ 
  │   (setq bookmark-bmenu-type-column-width 12) ; supported in Emacs 31 (innocuous on earlier versions)
  │ 
  │   (setq bufferlo-bookmark-buffers-exclude-filters
  │ 	(list
  │ 	 (rx bos " " (1+ anything)) ; ignores "invisible" buffers; e.g., " *Minibuf...", " markdown-code-fontification:..."
  │ 	 (rx bos "*" (1+ anything) "*") ; ignores "special" buffers; e.g;, "*Messages*", "*scratch*", "*occur*"
  │ 	 ))
  │ 
  │   (setq bufferlo-bookmark-buffers-include-filters
  │ 	(list
  │ 	 (rx bos "*shell*") ; comment out shells if you do not have bookmark support
  │ 	 (rx bos "*" (1+ anything) "-shell*") ; project.el shell buffers
  │ 	 (rx bos "*eshell*")
  │ 	 (rx bos "*" (1+ anything) "-eshell*") ; project.el eshell buffers
  │ 	 ))
  │ 
  │   (defun my/bufferlo-bookmarks-save-p (bookmark-name)
  │     (string-match-p (rx "=as") bookmark-name))
  │   (setq bufferlo-bookmarks-save-predicate-functions nil) ; clear the save-all predicate
  │   (add-hook 'bufferlo-bookmarks-save-predicate-functions #'my/bufferlo-bookmarks-save-p)
  │ 
  │   (defun my/bufferlo-bookmarks-load-p (bookmark-name)
  │     (string-match-p (rx "=al") bookmark-name))
  │   (add-hook 'bufferlo-bookmarks-load-predicate-functions #'my/bufferlo-bookmarks-load-p)
  │ 
  │   (defvar my:bufferlo-consult--source-local-buffers
  │     (list :name "Bufferlo Local Buffers"
  │ 	  :narrow   ?l
  │ 	  :category 'buffer
  │ 	  :face     'consult-buffer
  │ 	  :history  'buffer-name-history
  │ 	  :state    #'consult--buffer-state
  │ 	  :default  t
  │ 	  :items    (lambda () (consult--buffer-query
  │ 				:predicate #'bufferlo-local-buffer-p
  │ 				:sort 'visibility
  │ 				:as #'buffer-name)))
  │     "Local Bufferlo buffer candidate source for `consult-buffer'.")
  │ 
  │   (defvar my:bufferlo-consult--source-other-buffers
  │     (list :name "Bufferlo Other Buffers"
  │ 	  :narrow   ?o
  │ 	  :category 'buffer
  │ 	  :face     'consult-buffer
  │ 	  :history  'buffer-name-history
  │ 	  :state    #'consult--buffer-state
  │ 	  :items    (lambda () (consult--buffer-query
  │ 				:predicate #'bufferlo-non-local-buffer-p
  │ 				:sort 'visibility
  │ 				:as #'buffer-name)))
  │     "Non-local Bufferlo buffer candidate source for `consult-buffer'.")
  │ 
  │   (defvar my:bufferlo-consult--source-all-buffers
  │     (list :name "Bufferlo All Buffers"
  │ 	  :narrow   ?a
  │ 	  :hidden   t
  │ 	  :category 'buffer
  │ 	  :face     'consult-buffer
  │ 	  :history  'buffer-name-history
  │ 	  :state    #'consult--buffer-state
  │ 	  :items    (lambda () (consult--buffer-query
  │ 				:sort 'visibility
  │ 				:as #'buffer-name)))
  │     "All Bufferlo buffer candidate source for `consult-buffer'.")
  │ 
  │   ;; add in the reverse order of display preference
  │   (add-to-list 'consult-buffer-sources 'my:bufferlo-consult--source-all-buffers)
  │   (add-to-list 'consult-buffer-sources 'my:bufferlo-consult--source-other-buffers)
  │   (add-to-list 'consult-buffer-sources 'my:bufferlo-consult--source-local-buffers)
  │ 
  │   (bufferlo-mode)
  │   (bufferlo-anywhere-mode))
  └────


CRM prompt enhancement
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Bufferlo uses `completing-read-multiple' for the prompts where you can
  specify more than one input selection; e.g., when opening multiple
  bookmarks at once using `bufferlo-bookmarks-load-interactive'. Emacs
  31 will be getting a proper CRM prompt that displays the CRM separator
  character as a reminder hint. Note: The default separator is a comma.

  Per [vertico#completing-read-multiple] from the author of the Emacs
  CRM patch, we recommend adding the following snippet to your Emacs
  configuration.

  ┌────
  │ ;; Prompt indicator for `completing-read-multiple'.
  │ (when (< emacs-major-version 31)
  │   (advice-add #'completing-read-multiple :filter-args
  │ 	      (lambda (args)
  │ 		(cons (format "[CRM%s] %s"
  │ 			      (string-replace "[ \t]*" "" crm-separator)
  │ 			      (car args))
  │ 		      (cdr args))))))
  └────


[vertico#completing-read-multiple]
<https://github.com/minad/vertico#completing-read-multiple>


Related Packages
════════════════

desktop.el
──────────

  The built-in `desktop.el' package provides the possibility to persist
  the state of the current Emacs session for future recall. Bufferlo is
  fully compatible with `desktop.el'. Bufferlo's local buffer lists for
  frames/tabs are saved and restored by `desktop.el'.

  With its bookmark feature, bufferlo offers an alternative session
  persistence solution. In contrast to `desktop.el''s all-or-nothing
  solution, bufferlo's ability to bookmark tabs, frames, and sets are
  more fine-grained and lightweight. They are particularly suited for
  long-lived Emacs sessions with a large number of buffers that belong
  to different contexts.

  Unlike `desktop.el', bufferlo does not persist each buffer's enabled
  major or minor modes, instead relying on your Emacs configuration to
  establish modes, same as when you establish the buffer manually. As
  your configuration evolves, so too will your preferred major and minor
  modes evolve rather than assuming the desktop file will always
  represent your preferences. One typical example of an optional minor
  mode is `treesit-explore-mode' which you might use to understand
  treesitter behaviors. This minor mode will not be reenabled by
  bufferlo. If you want this behavior automatically, add
  `treesit-explore-mode' to your major-mode hook.

  Bufferlo bookmarks are still compatible with `desktop.el'. It is even
  possible to use both features together.


Similar packages
────────────────

  There are other Emacs packages that provide functionality with varying
  degrees of similarity to bufferlo. These packages offer some form of
  frame or tab-based buffer-list isolation and/or session management.

  • [Beframe]: frame-based buffer isolation
  • [Tabspaces]: project-based buffer isolation for tabs and frames
  • [activities.el]: purpose-based sessions on frame/tab level
  • [Bufler]: rule-based workspace management and buffer grouping
  • [Burly]: save and restore window configurations for single or
    multiple frames
  • [purpose]: manage windows and buffers according to purposes
  • [frame-purpose]: specialize frames to only display certain buffers
  • [perject]: purpose/project-based buffer isolation and session
    management based on `desktop.el'
  • [Perspective]: frame-based workspace isolation and persistence
  • [persp-mode]: based on perspective; allows multiple frames per
    workspace
  • [easysession.el]: session management
  • [bookmark-view.el]: save and restore window configurations
  • [tab-bookmark.el]: save and restore window configurations for tabs
  • [tab-bar-buffers]: isolate selected buffers and show them in the tab
    bar
  • [tab-sets.el]: save and restore tabs
  • [Workroom]: buffer isolation
  • [psession]: session management
  • [Chumpy-windows (Spaces)]: switch between named window
    configurations
  • [state]: switch between window configurations
  • [Emacs-session]: session management
  • [Sesman]: session management
  • [wsp]: session management
  • [Windwow]: session management
  • [frame-bufs]: frame-based buffer isolation
  • [desktop+.el]: extended `desktop.el' session management
  • [Workgroups]: session management
  • [restart-emacs]: reatart Emacs; can restore session via `desktop.el'
  • [framegroups.el]: session management via `desktop.el'


[Beframe] <https://github.com/protesilaos/beframe>

[Tabspaces] <https://github.com/mclear-tools/tabspaces>

[activities.el] <https://github.com/alphapapa/activities.el>

[Bufler] <https://github.com/alphapapa/bufler.el>

[Burly] <https://github.com/alphapapa/burly.el>

[purpose] <https://github.com/bmag/emacs-purpose>

[frame-purpose] <https://github.com/alphapapa/frame-purpose.el>

[perject] <https://github.com/overideal/perject>

[Perspective] <https://github.com/nex3/perspective-el>

[persp-mode] <https://github.com/Bad-ptr/persp-mode.el>

[easysession.el] <https://github.com/jamescherti/easysession.el>

[bookmark-view.el] <https://github.com/minad/bookmark-view>

[tab-bookmark.el] <https://github.com/minad/tab-bookmark>

[tab-bar-buffers] <https://github.com/ajrosen/tab-bar-buffers>

[tab-sets.el] <https://github.com/localauthor/tab-sets>

[Workroom] <https://codeberg.org/akib/emacs-workroom>

[psession] <https://github.com/thierryvolpiatto/psession>

[Chumpy-windows (Spaces)] <https://github.com/chumpage/chumpy-windows>

[state] <https://github.com/thisirs/state>

[Emacs-session] <https://emacs-session.sourceforge.net>

[Sesman] <https://github.com/vspinu/sesman>

[wsp] <https://github.com/petergardfjall/emacs-wsp>

[Windwow] <https://github.com/vijumathew/windwow>

[frame-bufs] <https://github.com/alpaker/frame-bufs>

[desktop+.el]
<https://github.com/ffevotte/desktop-plus/blob/master/desktop%2B.el>

[Workgroups] <https://github.com/tlh/workgroups.el>

[restart-emacs] <https://github.com/iqbalansari/restart-emacs>

[framegroups.el] <https://github.com/noctuid/framegroups.el>
