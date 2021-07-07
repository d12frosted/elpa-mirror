;;; bufshow.el --- A simple presentation tool for Emacs.
;;
;; Copyright (C) 2012 Peter Jones <pjones@pmade.com>
;;
;; Author: Peter Jones <pjones@pmade.com>
;; URL: https://github.com/pjones/bufshow
;; Package-Version: 20130726.1838
;; Package-Commit: d60a554e7239e6f7520d9c3436d5ecdbc9cf6957
;; Package-Requires: ((emacs "24.1"))
;; Version: 0.1.0
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;; A very simple minor mode for moving forward and backward through an
;; ordered set of buffers, possibly narrowing the buffer in the
;; process.
;;
;; For more information see `bufshow-mode' and `bufshow-start'.
;;
;;; License:
;;
;; Permission is hereby granted, free of charge, to any person obtaining
;; a copy of this software and associated documentation files (the
;; "Software"), to deal in the Software without restriction, including
;; without limitation the rights to use, copy, modify, merge, publish,
;; distribute, sublicense, and/or sell copies of the Software, and to
;; permit persons to whom the Software is furnished to do so, subject to
;; the following conditions:
;;
;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
;; LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
;; OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
;; WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
;;
;;; Code:

;; Local Variables:
;; lexical-binding: t
;; End:

(eval-when-compile
  (require 'org))

(defgroup bufshow nil
  "A simple presentation tool for Emacs."
  :version "0.1.0"
  :prefix "bufshow-"
  :group 'applications)

(defcustom bufshow-mode-functions
  '((org-mode . bufshow-narrow-to-org-id)
    (default  . bufshow-narrow-to-token))
  "An alist of major modes and the corresponding functions used
to narrow a buffer.  When showing a buffer as a presentation
slide the function listed in this alist for the major mode will
be invoked to narrow the buffer to the slide.  The function will
be called with narrowing token given in the `bufshow-start'
slides vector."
  :type 'alist
  :group 'bufshow)

;;; Internal Variables
(defvar bufshow--slide-id 0)
(defvar bufshow--slide-vector [])
(defvar bufshow--dir nil)
(defvar bufshow--winconfig nil)
(defvar bufshow--restore-funcs nil)
(defvar bufshow--was-read-only nil)
(defvar bufshow--direction 'next)
(defvar bufshow--scratch-buf "*bufshow*")

;;; Interactive Functions
(defun bufshow-load (file)
  "Evaluates the elisp FILE which should contain a call to
`bufshow-start' and then records the directory for relative file
names in the slides vector.

For information about the format of the slides vector see
`bufshow-start'."
  (interactive "fBufshow slides file: ")
  (bufshow-reset)
  (setq bufshow--dir (file-name-directory file))
  (load-file file))

(defun bufshow-next ()
  "Advance to the next slide."
  (interactive)
  (setq bufshow--direction 'next)
  (let ((next (1+ bufshow--slide-id))
        (size (length bufshow--slide-vector)))
    (bufshow-activate-slide
     (setq bufshow--slide-id (if (>= next size) 0 next)))))

(defun bufshow-prev ()
  "Return to the previous slide."
  (interactive)
  (setq bufshow--direction 'prev)
  (let ((prev (1- bufshow--slide-id))
        (size (length bufshow--slide-vector)))
    (bufshow-activate-slide
     (setq bufshow--slide-id (if (< prev 0) (1- size) prev)))))

;;; External Functions
(defun bufshow-start (slides)
  "Start by creating an elsip file that contains a call to
`bufshow-start' passing in a vector that represents the slides
and their order. The elements of the SLIDES vector must be lists.
For example:

    (bufshow-start
      [(\"file1\" \"token1\")
       (\"file2\" \"token2\")])

Each list in the vector should contain the following elements in
order:

  1. A string containing the name of a file relative to the
     current directory.  This file will be loaded and
     displayed/narrowed based on the next element.

     Instead of a string this element can be a function, in which
     case the function will be called to show a slide.  Any
     remaining elements in the list will be given to the function
     as arguments.

  2. This element is optional but if present controls how the
     buffer will be narrowed.  The default behavior is to locate
     a line in the buffer that contains `{BEGIN: token}` then
     find a succeeding line that contains `{END}`.  The buffer
     will be narrowed between these lines (exclusive).  Nested
     tokens are not supported.

     Some buffers have special behaviors when you supply a token
     in this element.  For example, for an `org-mode' buffer the
     token should contain the ID of a heading and bufshow will
     narrow to that org sub-tree.

After you write an elisp file that contains a call to the
`bufshow-start' function with a slides vector, use `bufshow-load'
to evaluate the file and correctly set the base directory for the
relative file names.

You can write your own functions for showing a slide as described
in item 1 above.  Interesting functions provided by bufshow
include:

  * `bufshow-split-below' and `bufshow-split-right' for splitting
    the frame and showing two slides at once.

If your function opens temporary buffers or needs to clean up
after itself you can add lambda expressions to be called after
the slide is changed by using `bufshow-add-clean-up-function'.
Make sure you're using lexical binding so the lambda expressions
end up being closures too.

Your function will have to manually handle narrowing.  You can
use the `bufshow-load-file' and `bufshow-show-token' functions to
perform the same loading and narrowing that bufshow does already.

When you are done with the presentation you can call
`bufshow-stop' to restore the window configuration and turn
`bufshow-mode' off.

An example presentation given using bufshow can be found here:

  https://github.com/devalot/hs4rb"
  (unless (vectorp slides) (error "slides should be a vector."))
  (if (= (length slides) 0) (error "slides can't be empty."))
  (setq bufshow--slide-id 0
        bufshow--slide-vector slides
        bufshow--dir (or bufshow--dir default-directory)
        bufshow--restore-funcs nil
        bufshow--winconfig (current-window-configuration))
  (bufshow-activate-slide 0))

(defun bufshow-stop ()
  "End the presentation and disable `bufshow-mode'."
  (interactive)
  (bufshow-reset)
  (bufshow-mode -1))

(defun bufshow-split-below (file1 file2 &optional token1 token2)
  "Split the current window into two windows, one above the
other.  FILE1 should be the file to show in the top window and
FILE2 is the file to show in the bottom window.  You can
optionally give TOKEN1 and TOKEN2 for narrowing FILE1 and FILE2
respectively.

If FILE1 and FILE2 are the same file an indirect buffer will be
created for the second window so that it can be narrowed
independently from the first."
  (bufshow-split 'vertically file1 file2 token1 token2))

(defun bufshow-split-right (file1 file2 &optional token1 token2)
  "Show two slides like `bufshow-split-below' except that they
are shown side-by-side."
  (bufshow-split 'horizontal file1 file2 token1 token2))

(defun bufshow-add-clean-up-function (func)
  "Call the function FUNC when the current slide is no longer
shown.  This is useful for removing temporary buffers and/or
doing other useful clean up tasks.

You don't have to worry about the window configuration since that
will be restored automatically."
  (add-to-list 'bufshow--restore-funcs func))

(defun bufshow-reveal-begin (file &optional token)
  "Create a reveal buffer and add the contents of FILE to that
buffer.  The reveal buffer will be switched into the same major
mode as that of FILE.  If TOKEN is non-nil only insert the
content between the token markers."
  (if (eq bufshow--direction 'next)
      (let ((buf (get-buffer-create bufshow--scratch-buf))
            (inhibit-read-only t))
        (with-current-buffer buf
          (buffer-disable-undo buf)
          (erase-buffer))
        (bufshow-append-show-scratch-buf file token))
    (bufshow-reveal-rewind)))

(defun bufshow-reveal-add (file &optional token)
  "Add the contents of FILE to an existing reveal buffer.  You
should have already used `bufshow-reveal-begin' before calling
this function.  If TOKEN is non-nil only add the content for that
token."
  (if (eq bufshow--direction 'next)
      (bufshow-append-show-scratch-buf file token)
    (bufshow-reveal-rewind)))

(defun bufshow-center-text (file &optional token)
  "Display the contents of FILE in a temporary buffer centering
the contents vertically and horizontally.  If TOKEN is non-nil
only display the contents of the token."
  (let ((buf (get-buffer-create bufshow--scratch-buf))
        (win-lines (window-height (selected-window)))
        (inhibit-read-only t)
        buf-lines)
    (with-current-buffer buf
      (buffer-disable-undo)
      (erase-buffer)
      (bufshow-append-scratch-buf file token)
      (center-region (point-min) (point-max))
      (setq buf-lines (count-lines (point-min) (point-max)))
      (goto-char (point-min))
      (insert (make-string (- (/ win-lines 2) (/ buf-lines 2)) ?\n))
      (goto-char (point-max))
      (insert "\n\n")
      (setq buffer-read-only t))
    (set-window-buffer (selected-window) buf)))

;;; Internal Functions
(defun bufshow-load-file (file)
  "Load the given file into the current window.  This also moves
point to the first line and removes any narrowing in preparation
for a call to `bufshow-show-token'."
  (let* ((name (concat bufshow--dir file)))
    (find-file name)
    (widen)
    (goto-char (point-min))))

(defun bufshow-show-token (token)
  "Narrow to the given token."
  (cond
   ((assoc major-mode bufshow-mode-functions)
    (funcall (cdr (assoc major-mode bufshow-mode-functions)) token))
   ((assoc 'default bufshow-mode-functions)
    (funcall (cdr (assoc 'default bufshow-mode-functions)) token))
   (t (error "no bufshow mode function for this buffer."))))

(defun bufshow-activate-slide (n)
  "Active slide number N."
  (bufshow-restore)
  (let* ((slide (aref bufshow--slide-vector n))
         (file  (car slide))
         (token (cadr slide)))
    (cond
     ((functionp file)
      (apply file (cdr slide)))
     (t
      (bufshow-load-file file)
      (if token (bufshow-show-token token))))
    (setq bufshow--was-read-only   buffer-read-only
          buffer-read-only         t)))

(defun bufshow-split (direction file1 file2 &optional token1 token2)
  "Split the window in the given direction and load FILE1 into
the first window and FILE2 into the second.  If the files are the
same an indiect buffer will be created."
  (bufshow-load-file file1)
  (if token1 (bufshow-show-token token1))
  (let* ((buf1 (current-buffer))
         (win2 (if (eq direction 'vertically) (split-window-vertically)
                 (split-window-horizontally)))
         buf2 uniq-name)
    (with-selected-window win2
      (if (not (string= file1 file2)) (bufshow-load-file file2)
        (setq uniq-name (generate-new-buffer-name (buffer-name buf1))
              buf2 (make-indirect-buffer buf1 uniq-name t))
        (bufshow-add-clean-up-function (lambda () (kill-buffer buf2)))
        (set-window-buffer nil buf2)))
    (with-current-buffer buf2
      (widen)
      (goto-char (point-min))
      (if token2 (bufshow-show-token token2)))))

(defun bufshow-reset ()
  "Reset the internal bufshow variables to their defaults."
  (bufshow-restore)
  (setq bufshow--slide-id 0
        bufshow--slide-vector []
        bufshow--dir nil
        bufshow--was-read-only nil))

(defun bufshow-restore ()
  "Restore the previous window configuration and anything that
may have changed by a slide showing function."
  (if (not bufshow--was-read-only) (setq buffer-read-only nil))
  (if bufshow--winconfig (set-window-configuration bufshow--winconfig))
  (mapc 'funcall bufshow--restore-funcs)
  (setq bufshow--restore-funcs nil
        bufshow--was-read-only nil))

(defun bufshow-narrow-to-org-id (token)
  "Narrow the buffer to the org subtree whose ID is TOKEN."
  (goto-char (org-find-entry-with-id token))
  (org-narrow-to-subtree)
  (org-show-subtree)
  (run-hook-with-args 'org-cycle-hook 'subtree))

(defun bufshow-narrow-to-token (token)
  "Narrow the buffer using begin/end tokens."
  (let* ((start (save-excursion
                  (search-forward (concat "{BEGIN: " token "}"))
                  (forward-line)
                  (beginning-of-line)
                  (point)))
         (end (save-excursion
                (goto-char start)
                (search-forward "{END}")
                (forward-line -1)
                (end-of-line)
                (point))))
    (narrow-to-region start end)))

(defun bufshow-reveal-rewind ()
  "Rewind the presentation to the start of the revel or one slide
before that depending on where the rewind starts."
  (let* ((bufshow--direction 'next)
         (size (length bufshow--slide-vector))
         (last-id (1+ bufshow--slide-id))
         (last-fun (car (aref bufshow--slide-vector
                              (if (>= last-id size) 0 last-id)))))
    ;; Go back to either the first reveal slide or the slide before that.
    (while (and (/= 0 bufshow--slide-id)
                (let ((fun (car (aref bufshow--slide-vector bufshow--slide-id))))
                  (if (eq last-fun 'bufshow-reveal-add)
                      ;; Skip back to the slide before a reveal begin.
                      (member fun '(bufshow-reveal-begin bufshow-reveal-add))
                    ;; Only go back to the reveal begin.
                    (not (eq fun 'bufshow-reveal-begin)))))
      (setq bufshow--slide-id (1- bufshow--slide-id)))
    (bufshow-activate-slide bufshow--slide-id)))

(defun bufshow-append-show-scratch-buf (file &optional token)
  "Internal function to append to the bufshow scratch buffer and
then display it in the selected window."
  (bufshow-append-scratch-buf file token)
  (set-window-buffer (selected-window)
                     (get-buffer-create bufshow--scratch-buf)))

(defun bufshow-append-scratch-buf (file &optional token)
  "Internal function to add content to the bufshow scratch buffer."
  (let ((buf (get-buffer-create bufshow--scratch-buf))
        (inhibit-read-only t)
        str mode)
    (save-excursion
      (bufshow-load-file file)
      (if token (bufshow-show-token token))
      (setq str (buffer-substring (point-min) (point-max))
            mode major-mode))
    (with-current-buffer buf
      (insert str)
      (funcall mode)
      (goto-char (point-max)))))

;;;###autoload
(define-minor-mode bufshow-mode
  "Bufshow mode is a presentation tool for Emacs.  Enabling the
`bufshow-mode' global minor mode is the first step to using it.
You'll also need to define an elisp vector that contains the list
of files and tokens to use during the presentation and invoke
`bufshow-load' or `bufshow-start' to start the presentation.

There are key bindings to move to the next and previous slides.
With an Emacs daemon and emacsclient it's easy to invoke the
`bufshow-next' and `bufshow-prev' functions using an IR remote
and something like lirc.

For more information on how to configure a presentation see the
`bufshow-start' function documentation."
  :group 'bufshow
  :init-value nil
  :lighter nil
  :global t
  :keymap `((,(kbd "C-c <f9>")  . bufshow-prev)
            (,(kbd "C-c <f10>") . bufshow-next)
            (,(kbd "C-c <f11>") . bufshow-load)
            (,(kbd "C-c <f12>") . bufshow-stop))
  ;; Toggling the mode should clear the state variables.
  (bufshow-reset))

(provide 'bufshow)
;;; bufshow.el ends here
