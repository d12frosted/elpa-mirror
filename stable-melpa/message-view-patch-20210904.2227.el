;;; message-view-patch.el --- Colorize patch-like emails in mu4e -*- lexical-binding: t; -*-

;; Copyright (C) 2011 Frank Terbeck.
;; Copyright (C) 2018-2021 Sean Farley.

;; Author: Sean Farley
;; URL: https://github.com/seanfarley/message-view-patch
;; Package-Version: 20210904.2227
;; Package-Commit: 40bc2e554fc1d0b6f0c403192c0a3ceaa019a78d
;; Version: 0.2.0
;; Created: 2018-06-15
;; Package-Requires: ((emacs "24.4") (magit "3.0.0"))
;; Keywords: extensions mu4e gnus

;;; License

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This is adapted from Frank Terbeck's gnus-article-treat-patch.el but has
;; been adapted to work with mu4e.

;;; Code:

(require 'diff-mode)
(require 'gnus)
(require 'magit)

;; Customs
(defgroup message-view-patch nil
  "Type faces (fonts) used in message-view-patch."
  :group 'mu4e)

(defcustom message-view-patch-regex
  '("^@@ -[0-9]+,[0-9]+ \\+[0-9]+,[0-9]+ @@")
  "List of conditions that will enable patch treatment.

String values will be matched as regular expressions within the
currently processed part. Non-string value are supposed to be
code fragments, which determine whether or not to do treatment:
The code needs to return t if treatment is wanted."
  :type '(repeat (string :tag "regex"))
  :group 'message-view-patch)

;; Faces
(defgroup message-view-patch-faces nil
  "Type faces (fonts) used in message-view-patch."
  :group 'mu4e
  :group 'faces)

(defface message-view-patch-three-dashes
  '((t :inherit diff-header))
  "Face for the three dashes in a diff header."
  :group 'message-view-patch-faces)

(defface message-view-patch-scissors
  '((t :inherit diff-header))
  "Face for the scissors 8< lines."
  :group 'message-view-patch-faces)

(defface message-view-patch-diff-index
  '((t :inherit diff-header))
  "Face for the diff index."
  :group 'message-view-patch-faces)

(defface message-view-patch-diff-hunk
  '((t :inherit magit-diff-hunk-heading))
  "Face for the diff hunk."
  :group 'message-view-patch-faces)

(defface message-view-patch-diff-equals
  '((t :inherit diff-header))
  "Face for the line of equal signs that some diffs have."
  :group 'message-view-patch-faces)

(defface message-view-patch-commit-message
  '((t :inherit magit-section-highlight))
  "Face for the commit message."
  :group 'message-view-patch-faces)

(defface message-view-patch-diff-stat-file
  '((t :inherit magit-filename))
  "Face for the file stats."
  :group 'message-view-patch-faces)

(defface message-view-patch-diff-stat-bar
  '((t :inherit magit-section-highlight))
  "Face for the stat bar separator."
  :group 'message-view-patch-faces)

(defface message-view-patch-diff-stat-num
  '((t :inherit magit-section-highlight))
  "Face for the stat number column."
  :group 'message-view-patch-faces)

(defface message-view-patch-misc
  '((t :inherit magit-diff-file-heading-highlight))
  "Face for the \"misc line\" part of the diff."
  :group 'message-view-patch-faces)

(defface message-view-patch-commit-comment
  '((t :inherit magit-section-highlight))
  "Face for the commit part of the diff.

E.g. between two ---'s after the commit message)."
  :group 'message-view-patch-faces)

(defface message-view-patch-diff-header
  '((t :inherit diff-header))
  "Face for the diff hunk headers."
  :group 'message-view-patch-faces)

(defface message-view-patch-diff-added
  '((t :inherit diff-added))
  "Face for the diff lines that are added."
  :group 'message-view-patch-faces)

(defface message-view-patch-diff-removed
  '((t :inherit magit-diff-removed))
  "Face for the diff lines that are removed."
  :group 'message-view-patch-faces)

(defface message-view-patch-diff-context
  '((t :inherit magit-diff-context))
  "Face for the context lines in the diff."
  :group 'message-view-patch-faces)

(defface message-view-patch-cite-1
  '((t :inherit gnus-cite-1))
  "Face for cited message parts (level 1)."
  :group 'message-view-patch-faces)

(defface message-view-patch-cite-2
  '((t :inherit gnus-cite-2))
  "Face for cited message parts (level 2)."
  :group 'message-view-patch-faces)

(defface message-view-patch-cite-3
  '((t :inherit gnus-cite-3))
  "Face for cited message parts (level 3)."
  :group 'message-view-patch-faces)

(defface message-view-patch-cite-4
  '((t :inherit gnus-cite-4))
  "Face for cited message parts (level 4)."
  :group 'message-view-patch-faces)

(defface message-view-patch-cite-5
  '((t :inherit gnus-cite-5))
  "Face for cited message parts (level 5)."
  :group 'message-view-patch-faces)

(defface message-view-patch-cite-6
  '((t :inherit gnus-cite-6))
  "Face for cited message parts (level 6)."
  :group 'message-view-patch-faces)

(defface message-view-patch-cite-7
  '((t :inherit gnus-cite-7))
  "Face for cited message parts (level 7)."
  :group 'message-view-patch-faces)

;; Pseudo-headers
(defcustom message-view-patch-pseudo-headers
  '(("^Acked-by: "      'gnus-header-name 'gnus-header-from)
    ("^C\\(c\\|C\\): "  'gnus-header-name 'gnus-header-from)
    ("^From: "          'gnus-header-name 'gnus-header-from)
    ("^Link: "          'gnus-header-name 'gnus-header-from)
    ("^Reported-by: "   'gnus-header-name 'gnus-header-from)
    ("^Reviewed-by: "   'gnus-header-name 'gnus-header-from)
    ("^Signed-off-by: " 'gnus-header-name 'gnus-header-from)
    ("^Subject: "       'gnus-header-name 'gnus-header-from)
    ("^Suggested-by: "  'gnus-header-name 'gnus-header-from)
    ("^Tested-by: "     'gnus-header-name 'gnus-header-from))
  "List of lists of regular expressions (with two face names)
which are used to determine the highlighting of pseudo headers in
the commit message (such as \"Signed-off-by:\").

The first face if used to highlight the header's name; the second
highlights the header's value."
  :type '(string)
  :group 'message-view-patch)

;; Color handling of faces
(defun message-view-patch-color-line (use-face)
  "Set text overlay to `USE-FACE' for the current line."
  (overlay-put (make-overlay (point-at-bol) (point-at-eol)) 'face use-face))

(defun message-view-patch-pseduo-header-get (line)
  "Check if `LINE' is a pseudo header.

If so return its entry in `message-view-patch-pseudo-headers'."
  (catch 'done
    (dolist (entry message-view-patch-pseudo-headers)
      (let ((regex (car entry)))
        (if (string-match regex line)
            (throw 'done entry))))
    (throw 'done '())))

(defun message-view-patch-pseudo-header-p (line)
  "Return t if `LINE' is a pseudo-header; nil otherwise.

`message-view-patch-pseudo-headers' is used to determine what a
pseudo-header is."
  (if (eq (message-view-patch-pseduo-header-get line) '()) nil t))

(defun message-view-patch-pseudo-header-color (line)
  "Colorize a pseudo-header `LINE'."
  (let ((data (message-view-patch-pseduo-header-get line)))
    (if (eq data '())
        nil
      (let* ((s (point-at-bol))
             (e (point-at-eol))
             (colon (re-search-forward ":"))
             (value (+ colon 1)))
        (overlay-put (make-overlay s colon) 'face (nth 1 data))
        (overlay-put (make-overlay value e) 'face (nth 2 data))))))

;; diff-stat
(defun message-view-patch-diff-stat-color ()
  "Colorize a diff-stat `LINE'."
  (let ((s (point-at-bol))
        (e (point-at-eol))
        (bar (- (re-search-forward "|") 1))
        (num (- (re-search-forward "[0-9]") 1))
        (pm (- (re-search-forward "\\([+-]\\|$\\)") 1)))

    (overlay-put (make-overlay s (- bar 1)) 'face 'message-view-patch-diff-stat-file)
    (overlay-put (make-overlay bar (+ bar 1)) 'face 'message-view-patch-diff-stat-bar)
    (overlay-put (make-overlay num pm) 'face 'message-view-patch-diff-stat-num)

    (goto-char pm)
    (let* ((plus (looking-at "\\+"))
           (brk (if plus
                    (re-search-forward "-" e t)
                  (re-search-forward "\\+" e t)))
           (first-face (if plus 'message-view-patch-diff-added 'message-view-patch-diff-removed))
           (second-face (if plus 'message-view-patch-diff-removed 'message-view-patch-diff-added)))

      (if (null brk)
          (overlay-put (make-overlay pm e) 'face first-face)
        (progn
          (setq brk (- brk 1))
          (overlay-put (make-overlay pm brk) 'face first-face)
          (overlay-put (make-overlay brk e) 'face second-face))))))

(defun message-view-patch-diff-stat-summary-color ()
  "Colorize a diff-stat summary `LINE'."
  (let* ((e (point-at-eol))
         (plus (- (re-search-forward "(\\+)" e t) 2))
         (minus (- (re-search-forward "(-)" e t) 2)))
    (overlay-put (make-overlay plus (+ plus 1)) 'face 'message-view-patch-diff-added)
    (overlay-put (make-overlay minus (+ minus 1)) 'face 'message-view-patch-diff-removed)))

(defun message-view-patch-diff-stat-line-p (line)
  "Return t if `LINE' is a diff-stat line; nil otherwise."
  (string-match "^ *[^ ]+[^|]+| +[0-9]+\\( *\\| +[+-]+\\)$" line))

(defun message-view-patch-diff-stat-summary-p (line)
  "Return t if `LINE' is a diff-stat summary-line; nil otherwise."
  (string-match "^ *[0-9]+ file\\(s\\|\\) changed,.*insertion.*deletion" line))

;; unified-diffs
(defun message-view-patch-diff-header-p (line)
  "Return t if `LINE' is a diff-header; nil otherwise."
  (cond
   ((string-match "^\\(\\+\\+\\+\\|---\\) " line) t)
   ((string-match "^diff -" line) t)
   (t nil)))

(defun message-view-patch-index-line-p (line)
  "Return t if `LINE' is an index-line; nil otherwise."
  (cond
   ((string-match "^Index: " line) t)
   ((string-match "^index [0-9a-f]+\\.\\.[0-9a-f]+" line) t)
   (t nil)))

(defun message-view-patch-hunk-line-p (line)
  "Return t if `LINE' is a hunk-line; nil otherwise."
  (string-match "^@@ -[0-9]+,[0-9]+ \\+[0-9]+,[0-9]+ @@" line))

(defun message-view-patch-atp-misc-diff-p (line)
  "Return t if `LINE' is a \"misc line\"; nil otherwise.

This is tested with respect to patch treatment."
  (let ((patterns '("^new file"
                    "^RCS file:"
                    "^retrieving revision ")))
    (catch 'done
      (dolist (regex patterns)
        (if (string-match regex line)
            (throw 'done t)))
      (throw 'done nil))))

(defun message-view-patch-atp-looks-like-diff (line)
  "Return t if `LINE' is a unified diff; nil otherwise.

This will test anything that even looks remotely like a line from
a unified diff"
  (or (message-view-patch-index-line-p line)
      (message-view-patch-diff-header-p line)
      (message-view-patch-hunk-line-p line)))

;; miscellaneous line handlers
(defun message-view-patch-scissors-line-p (line)
  "Return t if `LINE' is a scissors-line; nil otherwise."
  (cond
   ((string-match "^\\( *--* *\\(8<\\|>8\\)\\)+ *-* *$" line) t)
   (t nil)))

(defun message-view-patch-reply-line-p (line)
  "Return face if `LINE' is a reply to previous message; nil otherwise."
  (cond
   ((string-match "^> *> *> *> *> *> *>" line) 'message-view-patch-cite-7)
   ((string-match "^> *> *> *> *> *> "   line) 'message-view-patch-cite-6)
   ((string-match "^> *> *> *> *> "      line) 'message-view-patch-cite-5)
   ((string-match "^> *> *> *> "         line) 'message-view-patch-cite-4)
   ((string-match "^> *> *> "            line) 'message-view-patch-cite-3)
   ((string-match "^> *> "               line) 'message-view-patch-cite-2)
   ((string-match "^> "                  line) 'message-view-patch-cite-1)
   (t nil)))

;; Patch mail detection
(defun message-view-patch-want-treatment ()
  "Return t if patch treatment is wanted.

Run through `message-view-patch-regex' to determine
whether patch treatment is wanted or not."
  (catch 'done
    (save-excursion
      (goto-char (point-min))
      (dolist (entry message-view-patch-regex)
        (cond
         ((stringp entry)
          (if (re-search-forward entry nil t)
              (throw 'done t)))
         (t
          (if (eval entry)
              (throw 'done t)))))
      (throw 'done nil))))

;; The actual treatment code
(defun message-view-patch-state-machine ()
  "Colorize a part of the mu4e-view buffer.

Implement the state machine which colorizes a part of an article
if it looks patch-like.

The state machine works like this:

  0a. The machinery starts at the first line of the article's
      body. Not the header lines. We don't care about header
      lines at all.

  0b. The whole thing works line by line. It doesn't do any
      forward or backward looks.

  1. Initially, we assume, that what we'll see first is part of
     the patch's commit-message. Hence this first initial state
     is \"commit-message\". There are several ways out of this
     state:

       a) a scissors line is found (see 2.)
       b) a pseudo-header line is found (see 3.)
       c) a three-dashes line is found (see 4.)
       d) something that looks like the start of a unified diff is
          found (see 7.)

  2. A scissors line is something that looks like a pair of
     scissors running through a piece of paper. Like this:

      ------ 8< ----- 8< ------

     or this:

      ------------>8-----------

     The function `message-view-patch-scissors-line-p' decides whether a
     line is a scissors line or not. After a scissors line was
     treated, the machine will switch back to the
     \"commit-mesage\" state.

  3. This is very similar to a scissors line. It'll just return
     to the old state after its being done. The
     `message-view-patch-pseudo-header-p' function decides if a line is a
     pseudo header. The line will be appropriately colored.

  4. A three-dashes line is a line that looks like this: \"---\".
     It's the definite end of the \"commit-message\" state. The
     three dashes line is coloured and the state switches to
     \"commit-comment\". (See 5.)

  5. Nothing in \"commit-comment\" will appear in the generated
     commit (this is git-am specific semantics, but it's useful,
     so...). It may contain things like random comments or -
     promimently - a diff stat. (See 6.)

  6. A diff stat provides statistics about how much changed in a
     given commit by files and by whole commit (in a summary
     line). Two functions `message-view-patch-diff-stat-line-p' and
     `message-view-patch-diff-stat-summary-p' decide if a line belongs to
     a diff stat. It's coloured appropriately and the state
     switches back to \"commit-comment\".

  7. There is a function `message-view-patch-atp-looks-like-diff' which
     will cause the state to switch to \"unified-diff\" state
     from either \"commit-message\" or \"commit-comment\". In
     this mode there can be a set of lines types:

       a) diff-header lines (`message-view-patch-diff-header-p')
       b) index lines (`message-view-patch-index-line-p')
       c) hunk lines (`message-view-patch-hunk-line-p')
       d) equals line (\"^==*$\")
       e) context lines (\"^ \")
       f) add lines (\"^\\+\")
       g) remove lines (\"^-\")
       h) empty lines (\"^$\")

     This state runs until the end of the part."
  (catch 'message-view-patch-atp-done
    (let ((state 'commit-message)
          line do-not-move)

      (while t
        ;; Put the current line into an easy-to-handle string variable.
        (setq line
              (buffer-substring-no-properties (point-at-bol) (point-at-eol)))
        (setq do-not-move nil)

        ;; Switched state machine. The "real" states are `commit-message',
        ;; `commit-comment' and `unified-diff'. The other "states" are only
        ;; single-line colourisations that return to their respective parent-
        ;; state. Each state may (throw 'message-view-patch-atp-done) to leave the state-
        ;; machine immediately.
        (setq state
              (cond

               ((eq state 'commit-message)
                (cond
                 ((message-view-patch-scissors-line-p line)
                  (message-view-patch-color-line 'message-view-patch-scissors)
                  'commit-message)
                 ((message-view-patch-pseudo-header-p line)
                  (message-view-patch-pseudo-header-color line)
                  'commit-message)
                 ((string= line "---")
                  (message-view-patch-color-line 'message-view-patch-three-dashes)
                  'commit-comment)
                 ((message-view-patch-atp-looks-like-diff line)
                  (setq do-not-move t)
                  'unified-diff)
                 ((message-view-patch-reply-line-p line)
                  (message-view-patch-color-line (message-view-patch-reply-line-p line))
                  'commit-message)
                 (t
                  (message-view-patch-color-line 'message-view-patch-commit-message)
                  'commit-message)))

               ((eq state 'commit-comment)
                (cond
                 ((message-view-patch-diff-stat-line-p line)
                  (message-view-patch-diff-stat-color)
                  'commit-comment)
                 ((message-view-patch-diff-stat-summary-p line)
                  (message-view-patch-diff-stat-summary-color)
                  'commit-comment)
                 ((message-view-patch-atp-looks-like-diff line)
                  (setq do-not-move t)
                  'unified-diff)
                 ((message-view-patch-reply-line-p line)
                  (message-view-patch-color-line (message-view-patch-reply-line-p line))
                  'commit-message)
                 (t
                  (message-view-patch-color-line 'message-view-patch-commit-comment)
                  'commit-comment)))

               ((eq state 'unified-diff)
                (cond
                 ((message-view-patch-diff-header-p line)
                  (message-view-patch-color-line 'message-view-patch-diff-header)
                  'unified-diff)
                 ((message-view-patch-index-line-p line)
                  (message-view-patch-color-line 'message-view-patch-diff-index)
                  'unified-diff)
                 ((message-view-patch-hunk-line-p line)
                  (message-view-patch-color-line 'message-view-patch-diff-hunk)
                  'unified-diff)
                 ((string-match "^==*$" line)
                  (message-view-patch-color-line 'message-view-patch-diff-equals)
                  'unified-diff)
                 ((string-match "^$" line)
                  'unified-diff)
                 ((string-match "^ " line)
                  (message-view-patch-color-line 'message-view-patch-diff-context)
                  'unified-diff)
                 ((message-view-patch-atp-misc-diff-p line)
                  (message-view-patch-color-line 'message-view-patch-misc)
                  'unified-diff)
                 ((string-match "^\\+" line)
                  (message-view-patch-color-line 'message-view-patch-diff-added)
                  'unified-diff)
                 ((string-match "^-- $" line) ;; rare that the entire line exactly "-- " so just treat
                                              ;; as a git-diff ending marker
                  (message-view-patch-color-line 'message-view-patch-diff-header)
                  'unified-diff)
                 ((string-match "^-" line)
                  (message-view-patch-color-line 'message-view-patch-diff-removed)
                  'unified-diff)
                 (t 'unified-diff)))))

        (if (not do-not-move)
            (if (> (forward-line) 0)
                (throw 'message-view-patch-atp-done t)))))))

;;;###autoload
(defun message-view-patch-highlight ()
  "Highlight mail parts, that look like patches.

Well, usually they *are* patches - or possibly, when you take
git's format-patch output, entire commit exports - including
comments). This treatment assumes the use of unified diffs. Here
is how it works:

The most fancy type of patch mails look like this:

  From: ...
  Subject: ...
  Other-Headers: ...

  Body text, which can be reflecting the commit message but may
  optionally be followed by a so called scissors line, which
  looks like this (in case of a scissors line, the text above is
  not part of the commit message):

  -------8<----------

  If there really was a scissors line, then it's usually
  followed by repeated mail-headers. Which do not *have* to
  be the same as the one from the sender.

  From: ...
  Subject: ...

  More text. Usually part of the commit message. Likely
  multiline.  What follows may be an optional diffstat. If
  there is one, it's usually preceded by a line that contains
  only three dashes and nothing more. Before the diffstat,
  however, there may be a set of pseudo headers again, like
  these:

  Acked-by: Mike Dev <md@other.tld>
  Signed-off-by: Joe D. User <jdu@example.com>

  ---
  ChangeLog                    |    5 ++++-
  1 file changed, 4 insertions(+), 1 deletions(-)

  Now, there is again room for optional text, which is not
  part of the actual commit message. May be multiline. Actually,
  anything between the three-dashes line and the diff content
  is ignored as far as the commit message goes.

  Now for the actual diff part.  I want this to work for as
  many unified diff formats as possible.  What comes to mind
  is the format used by git and the format used by cvs and
  quilt.

  CVS style looks like this:

  Index: foo/bar.c
  ============================================================
  --- boo.orig/foo/bar.c       2010-02-24 ....
  +++ boo/foo/bar.c            2010-02-28 ....
  @@ -1823,7 +1823,7 @@
  <hunk>

  There may be multiple hunks. Each file gets an \"Index:\" and
  equals line.  Now the git format looks like this:

  diff --git a/ChangeLog b/ChangeLog
  index 6ffbc8c..36e5c17 100644
  --- a/ChangeLog
  +++ b/ChangeLog
  @@ -3,6 +3,9 @@
  <hunk>

  Again, there may be multiple hunks.

  When all hunks and all files are done, there may be additional
  text below the actual text.

And that's it.

You may define the look of several things: pseudo headers, scissor
lines, three-dashes-line, equals lines, diffstat lines, diffstat
summary. Then there is added lines, removed lines, context lines,
diff-header lines and diff-file-header lines, for which we are
borrowing the highlighting faces for from `diff-mode'."
  (if (message-view-patch-want-treatment)
      (save-excursion
        (progn
          (let ((inhibit-read-only t))
            (goto-char (point-min))
            (message-view-patch-state-machine))))))

(provide 'message-view-patch)

;;; message-view-patch.el ends here
