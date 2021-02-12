This file provides an `imenus' command which may be used as a
substitution for "M-x imenu".  It allows to jump to imenu items in
multiple buffers.  Also it provides additional key bindings for
rescanning, "isearch"-ing and performing "occur" using a current
minibuffer input.

To install the package manually, add the following to your init file:

  (add-to-list 'load-path "/path/to/imenus-dir")
  (autoload 'imenus "imenus" nil t)
  (autoload 'imenus-mode-buffers "imenus" nil t)

The main purpose of this package is to provide a framework to use
`imenu' indexes of multiple buffers/files.  For example, you may
search for imenu items in elisp files of your "~/.emacs.d/" directory
with a command like this:

(defun imenus-my-elisp-files ()
  "Perform `imenus' on elisp files from `user-emacs-directory'."
  (interactive)
  (imenus-files
   (directory-files user-emacs-directory t "^[^.].*\\.el\\'")))
