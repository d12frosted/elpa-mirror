Wand is an extension that allows users perform actions on a region based on
predefined patterns.  Wand is inspired by Xiki[1] and Acme[2].


; Dependencies:

Note that you don't need to worry about these dependencies if you're using
an Emacs package manager.

* Common Lisp Extensions, bundled with all recent versions of Emacs.

* A modern list library for Emacs Lisp: @magnars's excellent Dash[4] -- to
  promote better ways to write Emacs Lisp.

* The long lost Emacs string manipulation library: s.el[5] -- also by
  @magnars.

; Installation:

Thanks to @yasuyk, Wand is available in MELPA.  Make sure you have MELPA
repository added to `package-archives' and simply call `package-install':

  (add-to-list 'package-archives '("melpa" . "http://melpa.milkbox.net/packages/"))
  (package-initialize)
  (package-install 'wand)

Or `M-x package-install RET wand RET`.

Then `require' it:

  (require 'wand)
