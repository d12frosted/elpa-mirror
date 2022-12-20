		━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
		 POP A POSFRAME (JUST A FRAME) AT POINT
		━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━





1 What is posframe?
═══════════════════

  Posframe can pop up a frame at point, this *posframe* is a child-frame
  connected to its root window's buffer.

  The main advantages are:
  1. It is fast enough for daily usage :-)
  2. It works well with CJK languages.

  NOTE:
  1. For MacOS users, posframe needs Emacs version >= 26.0.91
  2. GNOME users with GTK3 builds need Emacs 27 or later.  See variable
     `posframe-gtk-resize-child-frames' which auto-detects this
     configuration.

     More details:
     1. [Fix some problems with moving and resizing child frames]
     2. [Emacs's set-frame-size can not work well with gnome-shell?]

  <file:./snapshots/posframe-1.png>


[Fix some problems with moving and resizing child frames]
<https://git.savannah.gnu.org/cgit/emacs.git/commit/?h=emacs-27&id=c49d379f17bcb0ce82604def2eaa04bda00bd5ec>

[Emacs's set-frame-size can not work well with gnome-shell?]
<https://lists.gnu.org/archive/html/emacs-devel/2020-01/msg00343.html>


2 Installation
══════════════

  ┌────
  │ (require 'posframe)
  └────


3 Usage
═══════

3.1 Create a posframe
─────────────────────

3.1.1 Simple way
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (when (posframe-workable-p)
  │   (posframe-show " *my-posframe-buffer*"
  │                  :string "This is a test"
  │                  :position (point)))
  └────


3.1.2 Advanced way
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (defvar my-posframe-buffer " *my-posframe-buffer*")
  │ 
  │ (with-current-buffer (get-buffer-create my-posframe-buffer)
  │   (erase-buffer)
  │   (insert "Hello world"))
  │ 
  │ (when (posframe-workable-p)
  │   (posframe-show my-posframe-buffer
  │                  :position (point)))
  └────


3.1.3 Arguments
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ C-h f posframe-show
  └────


3.2 Hide a posframe
───────────────────

  ┌────
  │ (posframe-hide " *my-posframe-buffer*")
  └────


3.3 Hide all posframes
──────────────────────

  ┌────
  │ M-x posframe-hide-all
  └────


3.4 Delete a posframe
─────────────────────

  1. Delete posframe and its buffer
     ┌────
     │ (posframe-delete " *my-posframe-buffer*")
     └────
  2. Only delete the frame
     ┌────
     │ (posframe-delete-frame " *my-posframe-buffer*")
     └────


3.5 Delete all posframes
────────────────────────

  ┌────
  │ M-x posframe-delete-all
  └────

  Note: this command will delete all posframe buffers.  You probably
  shouldn't use it if you are sharing a buffer between posframe and
  other packages.


3.6 posframe-arghandler
───────────────────────

  posframe-arghandler feature has been removed from posframe-1.1, user
  can use advice feature instead.


3.7 Mouse banish
────────────────

  Default setting will work well in most case, but for EXWM user,
  suggest use the below config.

  ┌────
  │ (setq posframe-mouse-banish-function #'posframe-mouse-banish-simple)
  └────
