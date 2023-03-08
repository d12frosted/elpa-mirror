			       ━━━━━━━━━━
				EMENT.EL
			       ━━━━━━━━━━


[https://elpa.gnu.org/packages/ement.svg]

Ement.el is a Matrix client for Emacs.  It aims to be simple, fast,
featureful, and reliable.

Feel free to join us in the chat room:
[https://img.shields.io/matrix/ement.el:matrix.org.svg?label=%23ement.el:matrix.org]


[https://elpa.gnu.org/packages/ement.svg]
<https://elpa.gnu.org/packages/ement.html>

[https://img.shields.io/matrix/ement.el:matrix.org.svg?label=%23ement.el:matrix.org]
<https://matrix.to/#/#ement.el:matrix.org>


1 Installation
══════════════

1.1 GNU ELPA
────────────

  Ement.el is published in [GNU ELPA], so it may be installed in Emacs
  with the command `M-x package-install RET ement RET'.  This is the
  recommended way to install Ement.el, as it will install the current
  stable release.


[GNU ELPA] <http://elpa.gnu.org/>


1.2 GNU Guix
────────────

  Ement.el is also available in [GNU Guix] as `emacs-ement'.


[GNU Guix] <https://guix.gnu.org/>


1.3 Debian
──────────

  Ement.el is also available in Debian as [elpa-ement].


[elpa-ement] <https://packages.debian.org/elpa-ement>


1.4 Git master
──────────────

  The `master' branch of the Git repository is intended to be usable at
  all times; only minor bugs are expected to be found in it before a new
  stable release is made.  To install from this, it is recommended to
  use [quelpa-use-package], like this:

  ┌────
  │ ;; Install and load `quelpa-use-package'.
  │ (package-install 'quelpa-use-package)
  │ (require 'quelpa-use-package)
  │ 
  │ ;; Install Ement.
  │ (use-package ement
  │   :quelpa (ement :fetcher github :repo "alphapapa/ement.el"))
  └────

  One might also use systems like [Straight] (which is also used by
  [DOOM]) to install from Git, but the author cannot offer support for
  them.


[quelpa-use-package] <https://github.com/quelpa/quelpa-use-package>

[Straight] <https://github.com/radian-software/straight.el>

[DOOM] <https://github.com/doomemacs/doomemacs>


1.5 Manual
──────────

  Ement.el is intended to be installed with Emacs's package system,
  which will ensure that the required autoloads are generated, etc.  If
  you choose to install it manually, you're on your own.


2 Usage
═══════

  • 
  • 
  • 

  1. Call command `ement-connect' to connect.  Multiple sessions are
     supported, so you may call the command again to connect to another
     account.
  2. Wait for initial sync to complete (which can take a few
     moments–initial sync JSON requests can be large).
  3. Use these commands:
     • `ement-list-rooms' to view the list of joined rooms.
     • `ement-view-room' to view a room's buffer, selected with
       completion.
     • `ement-create-room' to create a new room.
     • `ement-invite-user' to invite a user to a room.
     • `ement-join-room' to join a room.
     • `ement-leave-room' to leave a room.
     • `ement-forget-room' to forget a room.
     • `ement-tag-room' to add (or with interactive prefix, remove) a
       tag on a room (including favorite/low-priority status).
     • `ement-list-members' to list members in a room.
     • `ement-send-direct-message' to send a direct message to a user
       (in an existing direct room, or creating a new one
       automatically).
     • `ement-room-edit-message' to edit a message at point.
     • `ement-room-send-file' to send a file.
     • `ement-room-send-image' to send an image.
     • `ement-room-set-topic' to set a room's topic.
     • `ement-room-occur' to search in a room's known events.
     • `ement-room-override-name' to override a room's display name.
     • `ement-ignore-user' to ignore a user (or with interactive
       prefix, un-ignore).
     • `ement-room-set-message-format' to set a room's message format
       buffer-locally.
     • `ement-directory' to view a room directory.
     • `ement-directory-search' to search a room directory.
  4. Use these special buffers to see events from multiple rooms (you
     can also reply to messages from these buffers!):
     • See all new events that mention you in the `*Ement Mentions*'
       buffer.
     • See all new events in rooms that have open buffers in the
       `*Ement Notifications*' buffer.


2.1 Bindings
────────────

  These bindings are common to all of the following buffer types:

  ⁃ Switch to a room buffer: `M-g M-r'
  ⁃ Switch to the room list buffer: `M-g M-l'
  ⁃ Switch to the mentions buffer: `M-g M-m'
  ⁃ Switch to the notifications buffer: `M-g M-n'


2.1.1 Room buffers
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ⁃ Show command menu: `?'



  *Movement*

  ⁃ Next event: `TAB'
  ⁃ Previous event: `<backtab>'
  ⁃ Scroll up and mark read: `SPC'
  ⁃ Scroll down: `S-SPC'
  ⁃ Jump to fully-read marker: `M-SPC'
  ⁃ Load older messages: at top of buffer, scroll contents up
    (i.e. `S-SPC', `M-v' or `mwheel-scroll')

  *Switching*

  ⁃ List rooms: `M-g M-l'
  ⁃ Switch to other room: `M-g M-r'
  ⁃ Switch to mentions buffer: `M-g M-m'
  ⁃ Switch to notifications buffer: `M-g M-n'
  ⁃ Quit window: `q'

  *Messages*

  ⁃ Write message: `RET'
  ⁃ Write reply to event at point (when region is active, only quote
    marked text) : `S-RET'
  ⁃ Compose message in buffer: `M-RET' (while writing in minibuffer:
    `C-c ')' (Use command `ement-room-compose-org' to activate Org mode
    in the compose buffer.)
  ⁃ Edit message: `<insert>'
  ⁃ Delete message: `C-k'
  ⁃ Send reaction to event at point, or send same reaction at point: `s
    r'
  ⁃ Send emote: `s e'
  ⁃ Send file: `s f'
  ⁃ Send image: `s i'
  ⁃ View event source: `v'
  ⁃ Complete members and rooms at point: `C-M-i' (standard
    `completion-at-point' command).

  *Images*

  ⁃ Toggle scale of image (between fit-to-window and thumbnail):
    `mouse-1'
  ⁃ Show image in new buffer at full size: `double-mouse-1'

  *Users*

  ⁃ Send direct message: `u RET'
  ⁃ Invite user: `u i'
  ⁃ Ignore user: `u I'

  *Room*

  ⁃ Occur search in room: `M-s o'
  ⁃ List members: `r m'
  ⁃ Set topic: `r t'
  ⁃ Set message format: `r f'
  ⁃ Set notification rules: `r n'
  ⁃ Override display name: `r N'
  ⁃ Tag/untag room: `r T'

  *Room membership*

  ⁃ Create room: `R c'
  ⁃ Join room: `R j'
  ⁃ Leave room: `R l'
  ⁃ Forget room: `R F'

  *Other*

  ⁃ Sync new messages (not necessary if auto sync is enabled; with
    prefix to force new sync): `g'


2.1.2 Room list buffer
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ⁃ Show buffer of room at point: `RET'
  ⁃ Show buffer of next unread room: `SPC'
  ⁃ Move between room names: `TAB' / `<backtab>'


2.1.3 Directory buffers
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ⁃ View/join a room: `RET' / `mouse-1'
  ⁃ Load next batch of rooms: `+'


2.1.4 Mentions/notifications buffers
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ⁃ Move between events: `TAB' / `<backtab>'
  ⁃ Go to event at point in its room buffer: `RET'
  ⁃ Write reply to event at point (shows the event in its room while
    writing) : `S-RET'


2.2 Tips
────────

  ⁃ Desktop notifications are enabled by default for events that
    mention the local user.  They can also be shown for all events in
    rooms with open buffers.
  ⁃ Send messages in Org mode format by customizing the option
    `ement-room-send-message-filter' (which enables Org format by
    default), or by calling `ement-room-compose-org' in a compose
    buffer (which enables it for a single message).  Then Org-formatted
    messages are automatically converted and sent as HTML-formatted
    messages (with the Org syntax as the plain-text fallback).  You can
    send syntax such as:
    • Bold, italic, underline, strikethrough
    • Links
    • Tables
    • Source blocks (including results with `:exports both')
    • Footnotes (okay, that might be pushing it, but you can!)
    • And, generally, anything that Org can export to HTML
  ⁃ Starting in the room list buffer, by pressing `SPC' repeatedly, you
    can cycle through and read all rooms with unread buffers.  (If a
    room doesn't have a buffer, it will not be included.)
  ⁃ Room buffers and the room-list buffer can be bookmarked in Emacs,
    i.e. using `C-x r m'.  This is especially useful with [Burly]: you
    can arrange an Emacs frame with several room buffers displayed at
    once, use `burly-bookmark-windows' to bookmark the layout, and then
    you can restore that layout and all of the room buffers by opening
    the bookmark, rather than having to manually arrange them every
    time you start Emacs or change the window configuration.
  ⁃ Images and other files can be uploaded to rooms using
    drag-and-drop.
  ⁃ You can customize settings in the `ement' group.
    • *Note:* `setq' should not be used for certain options, because
       it will not call the associated setter function.  Users who
       have an aversion to the customization system may experience
       problems.


[Burly] <https://github.com/alphapapa/burly.el>

2.2.1 Displaying symbols and emojis
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Emacs may not display certain symbols and emojis well by default.
  Based on [this question and answer], you may find that the simplest
  way to fix this is to install an appropriate font, like [Noto Emoji],
  and then use this Elisp code:

  ┌────
  │ (setf use-default-font-for-symbols nil)
  │ (set-fontset-font t 'unicode "Noto Emoji" nil 'append)
  └────


[this question and answer]
<https://emacs.stackexchange.com/questions/62049/override-the-default-font-for-emoji-characters>

[Noto Emoji] <https://www.google.com/get/noto/#emoji-zsye>


2.3 Encrypted room support through Pantalaimon
──────────────────────────────────────────────

  Ement.el doesn't support encrypted rooms natively, but it can be used
  transparently with the E2EE-aware reverse proxy daemon [Pantalaimon].
  After configuring it according to its documentation, call
  `ement-connect' with the appropriate hostname and port, like:

  ┌────
  │ (ement-connect :uri-prefix "http://localhost:8009")
  └────


[Pantalaimon] <https://github.com/matrix-org/pantalaimon/>


3 Rationale
═══════════

  Why write a new Emacs Matrix client when there is already
  [matrix-client.el], by the same author, no less?  A few reasons:

  • `matrix-client' uses an older version of the Matrix spec, r0.3.0,
    with a few elements of r0.4.0 grafted in.  Bringing it up to date
    with the current version of the spec, r0.6.1, would be more work
    than to begin with the current version.  Ement.el targets r0.6.1
    from the beginning.
  • `matrix-client' does not use Matrix's lazy-loading feature (which
    was added to the specification later), so initial sync requests can
    take a long time for the server to process and can be large
    (sometimes tens of megabytes of JSON for the client to process!).
    Ement.el uses lazy-loading, which significantly improves
    performance.
  • `matrix-client' automatically makes buffers for every room a user
    has joined, even if the user doesn't currently want to watch a
    room.  Ement.el opens room buffers on-demand, improving performance
    by not having to insert events into buffers for rooms the user
    isn't watching.
  • `matrix-client' was developed without the intention of publishing
    it to, e.g. MELPA or ELPA.  It has several dependencies, and its
    code does not always install or compile cleanly due to
    macro-expansion issues (apparently depending on the user's Emacs
    config).  Ement.el is designed to have minimal dependencies outside
    of Emacs (currently only one, `plz', which could be imported into
    the project), and every file is linted and compiles cleanly using
    [makem.sh].
  • `matrix-client' uses EIEIO, probably unnecessarily, since few, if
    any, of the benefits of EIEIO are realized in it.  Ement.el uses
    structs instead.
  • `matrix-client' uses bespoke code for inserting messages into
    buffers, which works pretty well, but has a few minor bugs which
    are difficult to track down.  Ement.el uses Emacs's built-in (and
    perhaps little-known) `ewoc' library, which makes it much simpler
    and more reliable to insert and update messages in buffers, and
    enables the development of advanced UI features more easily.
  • `matrix-client' was, to a certain extent, designed to imitate other
    messaging apps.  The result is, at least when used with the
    `matrix-client-frame' command, fairly pleasing to use, but isn't
    especially "Emacsy."  Ement.el is intended to better fit into
    Emacs's paradigms.
  • `matrix-client''s long name makes for long symbol names, which
    makes for tedious, verbose code.  `ement' is easy to type and makes
    for concise, readable code.
  • The author has learned much since writing `matrix-client' and hopes
    to write simpler, more readable, more maintainable code in
    Ement.el.  It's hoped that this will enable others to contribute
    more easily.

  Note that, while `matrix-client' remains usable, and probably will for
  some time to come, Ement.el has now surpassed it in every way.  The
  only reason to choose `matrix-client' instead is if one is using an
  older version of Emacs that isn't supported by Ement.el.


[matrix-client.el] <https://github.com/alphapapa/matrix-client.el>

[makem.sh] <https://github.com/alphapapa/makem.sh>


4 Changelog
═══════════

4.1 0.7
───────

  *Additions*

  ⁃ Command `ement-room-override-name' sets a local override for a
    room's display name.  (Especially helpful for 1:1 rooms and bridged
    rooms.  See [MSC3015].)

  *Changes*

  ⁃ Improve display of room tombstones (displayed at top and bottom of
    buffer, and new room ID is linked to join).
  ⁃ Use descriptive prompts in `ement-leave-room' and
    `ement-forget-room' commands.

  *Fixes*

  ⁃ Command `ement-view-space' when called from a room buffer.  (Thanks
    to [Richard Brežák] for reporting.)
  ⁃ Don't call `display-buffer' when reverting room list buffer.  (Fixes
    [#121].  Thanks to [mekeor] for reporting.)
  ⁃ Retry sync for network timeouts.  (Accidentally broken in v0.6.)

  *Internal*

  ⁃ Function `ement-put-account-data' accepts `:room' argument to put on
    a room's account data.


[MSC3015]
<https://github.com/matrix-org/matrix-spec-proposals/pull/3015#issuecomment-1451017296>

[Richard Brežák] <https://github.com/MagicRB>

[#121] <https://github.com/alphapapa/ement.el/issues/121>

[mekeor] <https://github.com/mekeor>


4.2 0.6
───────

  *Additions*
  ⁃ Command `ement-view-space' to view a space's rooms in a directory
    buffer.

  *Changes*
  ⁃ Improve `ement-describe-room' command (formatting, bindings).

  *Fixes*
  ⁃ Retry sync for HTTP 502 "Bad Gateway" errors.
  ⁃ Formatting of unban events.
  ⁃ Update password authentication according to newer Matrix spec.
    (Fixes compatibility with Conduit servers.  [#66].  Thanks to
    [Travis Peacock], [Arto Jantunen], and [Stephen D].)
  ⁃ Image scaling issues.  (Thanks to [Visuwesh].)


[#66] <https://github.com/alphapapa/ement.el/issues/66>

[Travis Peacock] <https://github.com/tpeacock19>

[Arto Jantunen] <https://github.com/viiru->

[Stephen D] <https://github.com/scd31>

[Visuwesh] <https://github.com/vizs>


4.3 0.5.2
─────────

  *Fixes*
  ⁃ Apply `ement-initial-sync-timeout' properly (important for when the
    homeserver is slow to respond).


4.4 0.5.1
─────────

  *Fixes*
  ⁃ Autoload `ement-directory' commands.
  ⁃ Faces in `ement-directory' listings.


4.5 0.5
───────

  *Additions*
  ⁃ Present "joined-and-left" and "rejoined-and-left" membership event
    pairs as such.
  ⁃ Process and show rooms' canonical alias events.

  *Changes*
  ⁃ The [taxy.el]-based room list, with programmable, smart grouping, is
    now the default `ement-room-list'.  (The old,
    `tabulated-list-mode'-based room list is available as
    `ement-tabulated-room-list'.)
  ⁃ When selecting a room to view with completion, don't offer spaces.
  ⁃ When selecting a room with completion, empty aliases and topics are
    omitted instead of being displayed as nil.

  *Fixes*
  ⁃ Use of send-message filter when replying.
  ⁃ Replies may be written in compose buffers.


[taxy.el] <https://github.com/alphapapa/taxy.el>


4.6 0.4.1
─────────

  *Fixes*
  ⁃ Don't show "curl process interrupted" message when updating a read
    marker's position again.


4.7 0.4
───────

  *Additions*
  ⁃ Option `ement-room-unread-only-counts-notifications', now enabled by
    default, causes rooms' unread status to be determined only by their
    notification counts (which are set by the server and depend on
    rooms' notification settings).
  ⁃ Command `ement-room-set-notification-state' sets a room's
    notification state (imitating Element's user-friendly presets).
  ⁃ Room buffers' Transient menus show the room's notification state
    (imitating Element's user-friendly presets).
  ⁃ Command `ement-set-display-name' sets the user's global displayname.
  ⁃ Command `ement-room-set-display-name' sets the user's displayname in
    a room (which is also now displayed in the room's Transient menu).
  ⁃ Column `Notifications' in the `ement-taxy-room-list' buffer shows
    rooms' notification state.
  ⁃ Option `ement-interrupted-sync-hook' allows customization of how
    sync interruptions are handled.  (Now, by default, a warning is
    displayed instead of merely a message.)

  *Changes*
  ⁃ When a room's read receipt is updated, the room's buffer is also
    marked as unmodified.  (In concert with the new option, this makes
    rooms' unread status more intuitive.)

  *Fixes*
  ⁃ Binding of command `ement-forget-room' in room buffers.
  ⁃ Highlighting of `@room' mentions.


4.8 0.3.1
─────────

  *Fixes*
  ⁃ Room unread status (when the last event in a room is sent by the
    local user, the room is considered read).


4.9 0.3
───────

  *Additions*
  ⁃ Command `ement-directory' shows a server's room directory.
  ⁃ Command `ement-directory-search' searches a server's room directory.
  ⁃ Command `ement-directory-next' fetches the next batch of rooms in a
    directory.
  ⁃ Command `ement-leave-room' accepts a `FORCE-P' argument
    (interactively, with prefix) to leave a room without prompting.
  ⁃ Command `ement-forget-room' accepts a `FORCE-P' argument
    (interactively, with prefix) to also leave the room, and to forget
    it without prompting.
  ⁃ Option `ement-notify-mark-frame-urgent-predicates' marks the frame
    as urgent when (by default) a message mentions the local user or
    "@room" and the message's room has an open buffer.

  *Changes*
  ⁃ Minor improvements to date/time headers.

  *Fixes*
  ⁃ Command `ement-describe-room' for rooms without topics.
  ⁃ Improve insertion of old messages around existing timestamp headers.
  ⁃ Reduce D-Bus notification system check timeout to 2 seconds (from
    the default of 25).
  ⁃ Compatibility with Emacs 27.


4.10 0.2.1
──────────

  *Fixes*
  ⁃ Info manual export filename.


4.11 0.2
────────

  *Changes*
  ⁃ Read receipts are re-enabled.  (They're now implemented with a
    global idle timer rather than `window-scroll-functions', which
    sometimes caused a strange race condition that could cause Emacs to
    become unresponsive or crash.)
  ⁃ When determining whether a room is considered unread, non-message
    events like membership changes, reactions, etc. are ignored.  This
    fixes a bug that caused certain rooms that had no message events
    (like some bridged rooms) to appear as unread when they shouldn't
    have.  But it's unclear whether this is always preferable (e.g. one
    might want a member leaving a room to cause it to be marked unread),
    so this is classified as a change rather than simply a fix, and more
    improvements may be made to this in the future.  (Fixes [#97].
    Thanks to [Julien Roy] for reporting and testing.)
  ⁃ The `ement-taxy-room-list' view no longer automatically refreshes
    the list if the region is active in the buffer.  (This allows the
    user to operate on multiple rooms without the contents of the buffer
    changing before completing the process.)

  *Fixes*
  ⁃ Links to only rooms (as opposed to links to events in rooms) may be
    activated to join them.
  ⁃ Read receipts mark the last completely visible event (rather than
    one that's only partially displayed).
  ⁃ Prevent error when a room avatar image fails to load.


[#97] <https://github.com/alphapapa/ement.el/issues/97>

[Julien Roy] <https://github.com/MrRoy>


4.12 0.1.4
──────────

  *Fixed*
  ⁃ Info manual directory headers.


4.13 0.1.3
──────────

  *Fixed*

  ⁃ Temporarily disable sending of read receipts due to an unusual bug
    that could cause Emacs to become unresponsive.  (The feature will be
    re-enabled in a future release.)


4.14 0.1.2
──────────

  *Fixed*
  ⁃ Function `ement-room-sync' correctly updates room-list buffers.
    (Thanks to [Visuwesh].)
  ⁃ Only send D-Bus notifications when supported.  (Fixes [#83].  Thanks
    to [Tassilo Horn].)


[Visuwesh] <https://github.com/vizs>

[#83] <https://github.com/alphapapa/ement.el/issues/83>

[Tassilo Horn] <https://github.com/tsdh>


4.15 0.1.1
──────────

  *Fixed*
  ⁃ Function `ement-room-scroll-up-mark-read' selects the correct room
    window.
  ⁃ Option `ement-room-list-avatars' defaults to what function
    `display-images-p' returns.


4.16 0.1
────────

  After almost two years of development, the first tagged release.
  Submitted to GNU ELPA.


5 Development
═════════════

  Bug reports, feature requests, suggestions — /oh my/!


5.1 Copyright Assignment
────────────────────────

  Ement.el is published in GNU ELPA and is considered part of GNU Emacs.
  Therefore, cumulative contributions of more than 15 lines of code
  require that the author assign copyright of such contributions to the
  FSF.  Authors who are interested in doing so may contact
  [assign@gnu.org] to request the appropriate form.


[assign@gnu.org] <mailto:assign@gnu.org>


5.2 Matrix spec in Org format
─────────────────────────────

  An Org-formatted version of the Matrix spec is available in the
  [meta/spec] branch.


[meta/spec] <https://github.com/alphapapa/ement.el/tree/meta/spec>


6 License
═════════

  GPLv3
