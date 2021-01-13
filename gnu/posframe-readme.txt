* Posframe README                                :README:
** What is posframe?
Posframe can pop up a frame at point, this *posframe* is a
child-frame connected to its root window's buffer.

The main advantages are:
1. It is fast enough for daily usage :-)
2. It works well with CJK languages.

NOTE:
1. For MacOS users, posframe needs Emacs version >= 26.0.91
2. GNOME users with GTK3 builds need Emacs 27 or later.
   See variable `posframe-gtk-resize-child-frames'
   which auto-detects this configuration.

   More details:
   1. [[https://git.savannah.gnu.org/cgit/emacs.git/commit/?h=emacs-27&id=c49d379f17bcb0ce82604def2eaa04bda00bd5ec][Fix some problems with moving and resizing child frames]]
   2. [[https://lists.gnu.org/archive/html/emacs-devel/2020-01/msg00343.html][Emacs's set-frame-size can not work well with gnome-shell?]]

[[./snapshots/posframe-1.png]]

** Installation

#+BEGIN_EXAMPLE
(require 'posframe)
#+END_EXAMPLE

** Usage

*** Create a posframe

**** Simple way
#+BEGIN_EXAMPLE
(when (posframe-workable-p)
  (posframe-show " *my-posframe-buffer*"
                 :string "This is a test"
                 :position (point)))
#+END_EXAMPLE

**** Advanced way
#+BEGIN_EXAMPLE
(defvar my-posframe-buffer " *my-posframe-buffer*")

(with-current-buffer (get-buffer-create my-posframe-buffer)
  (erase-buffer)
  (insert "Hello world"))

(when (posframe-workable-p)
  (posframe-show my-posframe-buffer
                 :position (point)))
#+END_EXAMPLE

**** Arguments

#+BEGIN_EXAMPLE
C-h f posframe-show
#+END_EXAMPLE

*** Hide a posframe
#+BEGIN_EXAMPLE
(posframe-hide " *my-posframe-buffer*")
#+END_EXAMPLE

*** Hide all posframes
#+BEGIN_EXAMPLE
M-x posframe-hide-all
#+END_EXAMPLE

*** Delete a posframe
1. Delete posframe and its buffer
   #+BEGIN_EXAMPLE
   (posframe-delete " *my-posframe-buffer*")
   #+END_EXAMPLE
2. Only delete the frame
   #+BEGIN_EXAMPLE
   (posframe-delete-frame " *my-posframe-buffer*")
   #+END_EXAMPLE
*** Delete all posframes
#+BEGIN_EXAMPLE
M-x posframe-delete-all
#+END_EXAMPLE

Note: this command will delete all posframe buffers.
You probably shouldn't use it if you are sharing a buffer
between posframe and other packages.

*** Customizing mouse pointer control

By default, posframe moves the pointer to point (0,0) in
the frame, as a way to address an issue with mouse focus.
To disable this feature, add this to your init.el:
#+BEGIN_EXAMPLE
(setq posframe-mouse-banish nil)
#+END_EXAMPLE

*** Set fallback arguments of posframe-show

Users can set fallback values of posframe-show's arguments with the
help of `posframe-arghandler'.  The example below sets fallback
border-width to 10 and fallback background color to green.

#+BEGIN_EXAMPLE
(setq posframe-arghandler #'my-posframe-arghandler)
(defun my-posframe-arghandler (buffer-or-name arg-name value)
  (let ((info '(:internal-border-width 10 :background-color "green")))
    (or (plist-get info arg-name) value)))
#+END_EXAMPLE

*** Some packages which use posframe
1. [[https://github.com/yanghaoxie/which-key-posframe][which-key-posframe]]
2. [[https://github.com/conao3/ddskk-posframe.el][ddskk-posframe]]
3. [[https://github.com/tumashu/pyim][pyim]]
4. [[https://github.com/tumashu/ivy-posframe][ivy-posframe]]
5. [[https://github.com/tumashu/company-posframe][company-posframe]]
6. [[https://github.com/randomwangran/org-marginalia-posframe][org-marginalia-posframe]]
7. ...