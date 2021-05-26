;;; magit-tbdiff.el --- Magit extension for range diffs  -*- lexical-binding: t; -*-

;; Copyright (C) 2017-2021  Kyle Meyer

;; Author: Kyle Meyer <kyle@kyleam.com>
;; URL: https://github.com/magit/magit-tbdiff
;; Package-Version: 20210525.2329
;; Package-Commit: fef1b7772fe192c434089b67644ff93765e384d4
;; Keywords: vc, tools
;; Version: 1.1.0
;; Package-Requires: ((emacs "24.4") (magit "3.0.0"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Magit-tbdiff provides a Magit interface to git-tbdiff [1] and
;; git-range-diff, subcommands for comparing two versions of a topic
;; branch.
;;
;; There are three commands for creating range diffs:
;;
;;   * `magit-tbdiff-ranges' is the most generic of the three
;;     commands.  It reads two ranges that represent the two series to
;;     be compared.
;;
;;   * `magit-tbdiff-revs' reads two revisions.  From these (say, "A"
;;     and "B"), it constructs the two series as B..A and A..B.
;;
;;   * `magit-tbdiff-revs-with-base' is like the previous command, but
;;     it also reads a base revision, constructing the range as
;;     <base>..A and <base>..B.
;;
;; These commands are available in the transient `magit-tbdiff', which
;; in turn is available in the Magit diff transient, bound by default
;; to "i" (for "interdiff" [2]).  So, with the default keybindings,
;; you can invoke the tbdiff transient with "di".
;;
;; As of v2.19.0, Git comes with the "range-diff" subcommand, an
;; analog of tbdiff.  The option `magit-tbdiff-subcommand' controls
;; which subcommand is used.
;;
;; When Magit-tbdiff is installed from MELPA, no additional setup is
;; needed beyond installing git-tbdiff [1].  The tbdiff transient will
;; be added under the Magit diff transient, and Magit-tbdiff will be
;; loaded the first time that the tbdiff transient is invoked.
;;
;; [1] https://github.com/trast/tbdiff

;; [2] When I selected that key, I didn't know what an interdiff was
;;     and that what tbdiff refers to as an "interdiff" isn't
;;     technically one.  Sorry.
;;
;;     https://public-inbox.org/git/nycvar.QRO.7.76.6.1805062155120.77@tvgsbejvaqbjf.bet/#t

;;; Code:

(require 'cl-lib)
(require 'magit)
(require 'transient)


;;; Options

(defgroup magit-tbdiff nil
  "Magit extension for git-tbdiff and git-range-diff"
  :prefix "magit-tbdiff"
  :group 'magit-extensions)

(defface magit-tbdiff-marker-equivalent
  '((t (:inherit magit-cherry-equivalent)))
  "Face for '=' marker in assignment line."
  :group 'magit-tbdiff)

(defface magit-tbdiff-marker-different
  '((t (:inherit magit-cherry-unmatched)))
  "Face for '!' marker in assignment line."
  :group 'magit-tbdiff)

(defface magit-tbdiff-marker-unmatched
  '((t (:inherit magit-cherry-unmatched)))
  "Face for '<' and '>' markers in assignment line."
  :group 'magit-tbdiff)

(defcustom magit-tbdiff-subcommand
  (or (and (ignore-errors
             (file-exists-p
              (concat (file-name-as-directory (magit-git-str "--exec-path"))
                      "git-range-diff")))
           "range-diff")
      "tbdiff")
  "Subcommand used to create range diff.
Translates to 'git [global options] <subcommand> ...'.  The
default is set to \"range-diff\" if git-range-diff (introduced in
Git v2.19.0) is detected on your system and to \"tbdiff\"
otherwise."
  :package-version '(magit-tbdiff . "0.3.0")
  :type 'string)


;;; Internals

(defvar-local magit-tbdiff-buffer-range-a nil)
(defvar-local magit-tbdiff-buffer-range-b nil)

(define-derived-mode magit-tbdiff-mode magit-mode "Magit-tbdiff"
  "Mode for viewing range diffs.

\\{magit-tbdiff-mode-map}"
  :group 'magit-tbdiff
  (setq-local magit-diff-highlight-trailing nil)
  (hack-dir-local-variables-non-file-buffer))

(defvar magit-tbdiff-assignment-re
  (eval-when-compile
    (let ((digit-re '(and (zero-or-more " ")  ; Retain left padding.
                          (or (one-or-more digit)
                              (one-or-more "-"))))
          (hash-re '(or (repeat 4 40 (char digit (?a . ?f)))
                        (repeat 4 40 "-"))))
      (rx-to-string `(and line-start
                          (group ,digit-re)
                          ":" (zero-or-more " ")
                          (group ,hash-re) " "
                          (group (any "<>!=")) " "
                          (group ,digit-re)
                          ":" (zero-or-more " ")
                          (group ,hash-re) " "
                          (group (zero-or-more not-newline)))
                    t))))

;; range-diff's --dual-color inverts the color of the outer diff
;; markers.  Map this to boxed text.
(face-spec-set 'magit-tbdiff-dual-color '((t (:box t))))
(defvar magit-tbdiff-ansi-color-map
  (let ((ansi-color-faces-vector (copy-sequence ansi-color-faces-vector)))
    (aset ansi-color-faces-vector 7 'magit-tbdiff-dual-color)
    (ansi-color-make-color-map)))

(defun magit-tbdiff-wash-hunk (&optional dual-color)
  ;; Note: This hunk matching is less strict than what is in
  ;; `magit-diff-wash-hunk' to accommodate range-diff output changes
  ;; introduced by Git 2.23.0.
  (when (looking-at "^@@\\(?: \\(.*\\)\\)?")
    (let ((heading (match-string 0))
          (value (match-string 1)))
      (magit-delete-line)
      (magit-insert-section section ((eval (if dual-color 'tbdiff-hunk 'hunk))
                                     value)
        (insert (propertize (concat heading "\n")
                            'font-lock-face 'magit-diff-hunk-heading))
        (when dual-color
          (remove-overlays (line-beginning-position 0) (line-end-position 0)))
        (magit-insert-heading)
        (while (not (or (eobp) (looking-at "^[^-+\s\\]")))
          (forward-line))
        (oset section end (point))
        (unless dual-color
          (oset section washer 'magit-diff-paint-hunk))))
    t))

(defun magit-tbdiff-wash (args)
  (let* ((dual-color (member "--dual-color" args))
         (hunk-wash-fn (lambda () (magit-tbdiff-wash-hunk dual-color))))
    (when dual-color
      (require 'ansi-color)
      (let ((ansi-color-map magit-tbdiff-ansi-color-map)
            end-pt)
        (goto-char (point-max))
        (goto-char (line-beginning-position))
        ;; Paint ANSI escape sequences in hunks while removing them from
        ;; the assignment lines.
        (while (zerop (forward-line -1))
          (if (looking-at-p "^ ")
              (unless end-pt
                (setq end-pt (line-end-position)))
            (when end-pt
              (ansi-color-apply-on-region (1+ (line-end-position)) end-pt)
              (setq end-pt nil))
            (ansi-color-filter-region (point) (line-end-position))))))
    (while (not (eobp))
      (if (looking-at magit-tbdiff-assignment-re)
          (magit-bind-match-strings
              (num-a hash-a marker num-b hash-b subject) nil
            (magit-delete-line)
            (when (string-match-p "-" hash-a) (setq hash-a nil))
            (when (string-match-p "-" hash-b) (setq hash-b nil))
            (magit-insert-section (commit (or hash-b hash-a))
              (insert
               (mapconcat
                #'identity
                (list num-a
                      (if hash-a
                          (propertize hash-a 'face 'magit-hash)
                        (make-string (length hash-b) ?-))
                      (propertize marker
                                  'face
                                  (pcase marker
                                    ("=" 'magit-tbdiff-marker-equivalent)
                                    ("!" 'magit-tbdiff-marker-different)
                                    ((or "<" ">") 'magit-tbdiff-marker-different)
                                    (_
                                     (error "Unrecognized marker"))))
                      num-b
                      (if hash-b
                          (propertize hash-b 'face 'magit-hash)
                        (make-string (length hash-a) ?-))
                      subject)
                " ")
               ?\n)
              (magit-insert-heading)
              (when (not (looking-at-p magit-tbdiff-assignment-re))
                (let ((beg (point))
                      end)
                  (while (looking-at "^    ")
                    (magit-delete-match)
                    (forward-line 1))
                  (setq end (point))
                  (goto-char beg)
                  (save-restriction
                    (narrow-to-region beg end)
                    (magit-wash-sequence hunk-wash-fn))))))
        (error "Unexpected tbdiff output")))))

(defun magit-tbdiff-insert ()
  "Insert range diff into a `magit-tbdiff-mode' buffer."
  (let ((magit-git-global-arguments
         (append (list "-c" "color.diff.context=normal"
                       "-c" "color.diff.whitespace=normal")
                 magit-git-global-arguments)))
    (apply #'magit-git-wash
           #'magit-tbdiff-wash
           magit-tbdiff-subcommand
           (if (member "--dual-color" magit-buffer-arguments)
               "--color"
             "--no-color")
           magit-tbdiff-buffer-range-a magit-tbdiff-buffer-range-b
           magit-buffer-arguments)))

(defun magit-tbdiff-setup-buffer (range-a range-b args)
  (magit-setup-buffer #'magit-tbdiff-mode nil
    (magit-tbdiff-buffer-range-a range-a)
    (magit-tbdiff-buffer-range-b range-b)
    (magit-buffer-arguments args)))

(defun magit-tbdiff-refresh-buffer ()
  (setq header-line-format
        (propertize (format " Range diff: %s vs %s"
                            magit-tbdiff-buffer-range-a
                            magit-tbdiff-buffer-range-b)
                    'face 'magit-header-line))
  (magit-insert-section (tbdiff-buf)
    (magit-tbdiff-insert)))

(cl-defmethod magit-buffer-value (&context (major-mode magit-tbdiff-mode))
  (list magit-tbdiff-buffer-range-a magit-tbdiff-buffer-range-b))

(defun magit-tbdiff-apply-error (&rest _args)
  (when (derived-mode-p 'magit-tbdiff-mode)
    (user-error "Cannot apply changes from range diff hunk")))
(advice-add 'magit-apply :before #'magit-tbdiff-apply-error)
(advice-add 'magit-reverse :before #'magit-tbdiff-apply-error)


;;; Commands

;;;###autoload
(defun magit-tbdiff-ranges (range-a range-b &optional args)
  "Compare commits in RANGE-A with those in RANGE-B.
$ git range-diff [ARGS...] RANGE-A RANGE-B"
  (interactive (list (magit-read-range "Range A")
                     (magit-read-range "Range B")
                     (transient-args 'magit-tbdiff)))
  (magit-tbdiff-setup-buffer range-a range-b args))

;;;###autoload
(defun magit-tbdiff-revs (rev-a rev-b &optional args)
  "Compare commits in REV-B..REV-A with those in REV-A..REV-B.
$ git range-diff [ARGS...] REV-B..REV-A REV-A..REV-B"
  (interactive
   (let ((rev-a (magit-read-branch-or-commit "Revision A")))
     (list rev-a
           (magit-read-other-branch-or-commit "Revision B" rev-a)
           (transient-args 'magit-tbdiff))))
  (magit-tbdiff-ranges (concat rev-b ".." rev-a)
                       (concat rev-a ".." rev-b)
                       args))

;;;###autoload
(defun magit-tbdiff-revs-with-base (rev-a rev-b base &optional args)
  "Compare commits in BASE..REV-A with those in BASE..REV-B.
$ git range-diff [ARGS...] BASE..REV-A BASE..REV-B"
  (interactive
   (let* ((rev-a (magit-read-branch-or-commit "Revision A"))
          (rev-b (magit-read-other-branch-or-commit "Revision B" rev-a)))
     (list rev-a rev-b
           (magit-read-branch-or-commit "Base"
                                        (or (magit-get-upstream-branch rev-b)
                                            (magit-get-upstream-branch rev-a)))
           (transient-args 'magit-tbdiff))))
  (magit-tbdiff-ranges (concat base ".." rev-a)
                       (concat base ".." rev-b)
                       args))

(defun magit-tbdiff-save (file)
  "Write current range-diff to FILE."
  (interactive "FWrite range-diff to file: ")
  (unless (derived-mode-p 'magit-tbdiff-mode)
    (user-error "Current buffer is not a `magit-tbdiff-mode' buffer"))
  (let ((range-a magit-tbdiff-buffer-range-a)
        (range-b magit-tbdiff-buffer-range-b)
        (args magit-buffer-arguments))
    (with-temp-file file
      (magit-git-insert magit-tbdiff-subcommand
                        range-a range-b
                        (remove "--dual-color" args))))
  (magit-refresh))

;;;###autoload (autoload 'magit-tbdiff "magit-tbdiff" nil t)
(transient-define-prefix magit-tbdiff ()
  "Invoke tbdiff (or range-diff)."
  :incompatible '(("--left-only" "--right-only"))
  ["Arguments"
   :if (lambda () (equal magit-tbdiff-subcommand "tbdiff"))
   ("-s" "Suppress diffs" "--no-patches")
   ;; TODO: Define custom reader.
   ("-w" "Creation weight [0-1, default: 0.6]" "--creation-weight=")]
  ["Arguments"
   :if-not (lambda () (equal magit-tbdiff-subcommand "tbdiff"))
   ("-d" "Dual color" "--dual-color")
   ("-s" "Suppress diffs" ("-s" "--no-patch"))
   (5 "-N" "Suppress notes diff" "--no-notes")
   (5 "-l" "Exclude commits not in left range" "--left-only"
    :if (lambda () (version<= "2.31" (magit-git-version))))
   (5 "-r" "Exclude commits not in right range" "--right-only"
    :if (lambda () (version<= "2.31" (magit-git-version))))
   ;; TODO: Define custom reader.
   ("-c" "Creation factor [0-100, default: 60] " "--creation-factor=")]
  ["Actions"
   ("b" "Compare revs using common base" magit-tbdiff-revs-with-base)
   ("i" "Compare revs" magit-tbdiff-revs)
   ("r" "Compare ranges" magit-tbdiff-ranges)])

;;;###autoload
(eval-after-load 'magit
  '(progn
     (transient-append-suffix 'magit-diff "p"
       '("i" "Interdiffs" magit-tbdiff))))

(provide 'magit-tbdiff)
;;; magit-tbdiff.el ends here
