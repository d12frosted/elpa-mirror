;;; diff-at-point.el --- Diff navigation -*- lexical-binding: t -*-

;; Copyright (C) 2019  Campbell Barton

;; Author: Campbell Barton <ideasman42@gmail.com>

;; URL: https://gitlab.com/ideasman42/emacs-diff-at-point
;; Package-Version: 20210921.603
;; Package-Commit: 63951d8236163d86d5261b35d6c9a3f3f280e876
;; Version: 0.1
;; Package-Requires: ((emacs "26.2"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Open a diff, navigating to the current file, line and column.

;;; Usage

;; ;; Run from a diff buffer.
;; (diff-at-point-goto-source-and-close)
;;
;; ;; Create a diff on the repository, navigate to the current point.
;; (diff-at-point-open-and-goto-hunk)

;;; Code:

;; Needed for calling 'diff-goto-source'.
(require 'diff-mode)

(defvar diff-at-point-diff-command (lambda () (interactive) (vc-root-diff nil))
  "This is the function called to create a diff in the current repository.

On success it must open a diff buffer and return a non-nil value.

Override this function for a different diff function `vc-root-diff'.")


(defun diff-at-point-file-line-to-point
  (current-filename-relative current-line current-column &optional strict)
  "This can be used to navigate to a point in a diff buffer.

Given the file, line and column in the original (non-diff) file,
this returns the point in the diff buffer or nil if it can't be found.

This can be used to implement a utility to open a diff buffer,
then navigate to the point the user was viewing.
However this function doesn't make any change the the buffer state,
that's up to the caller to implement.

CURRENT-FILENAME-RELATIVE the filename to look-up in the diff.
Typically this is the filename of the current buffer,
relative to the repository root.

Arguments CURRENT-LINE & CURRENT-COLUMN define the location in the file.
Typically this is taken from the current `point'.

When STRICT is enabled, only return a result if the line exists in the diff,
otherwise return a point in the closest hunk."
  (save-excursion
    (unless
      (re-search-forward
        (concat
          ;; Filename declaration.
          "^"
          "\\-\\-\\-[[:blank:]]+.*\n" ;; '--- '
          "\\+\\+\\+[[:blank:]]+" ;;     '+++ '.
          ;; Optional 'b/'.
          "\\(\\|b/\\)" (regexp-quote current-filename-relative)
          ;; Optional ' (some text)'
          ;; Subversion quirk.
          "\\(\\|[[:blank:]]+.*\\)\n" ;; Ignore this line.
          "@@[[:blank:]]+.*[[:blank:]]@@"
          ;; may have trailing text, ignore this.
          )
        nil t 1)
      (user-error "Unable to find filename in diff: %S" current-filename-relative))

    (beginning-of-line)
    (let
      (
        ;; Next file or end of document.
        (point-found nil)
        ;; Fallback point closest to the hunk,
        ;; used if 'current-line' isn't inside the hunk in the diff.
        ;;
        ;; The fallback uses either the beginning or end of the hunk.
        (fallback-point-begin nil)
        (fallback-point-end nil)
        (fallback-point-is-begin nil)
        ;; The distance of the fallback point to the line we're looking for.
        (fallback-delta-lines nil)
        ;; Find the next hunk or file max, to restrict the search.
        (current-filename-diff-point-max
          (save-excursion
            (cond
              (
                (re-search-forward
                  (concat
                    "\\(^\\)"
                    ;; Optional, don't capture, ignore.
                    ;; Git uses: "diff ..." & "index ..."
                    ;; Subversion uses: "Index ..." & "===...".
                    ;;
                    ;; So use any non-blank line start except for '-' & '+'.
                    "\\(?:[^\\-\\+[:blank:]]+.*\n\\)+?"
                    ;; Prefix.
                    "---[[:blank:]]+.*\n" ;; '--- '
                    "\\+\\+\\+[[:blank:]]+.*\n" ;; '+++ '
                    ;; May have trailing text which can be safely ignored.
                    "@@[[:blank:]]+.*[[:blank:]]@@")
                  nil t 1)
                (match-beginning 0))
              (t
                (point-max))))))

      ;; Now search for the current hunk.
      (save-excursion
        (while
          (and
            (null point-found)
            (re-search-forward
              (concat
                "^\\(@@\\)[[:blank:]]+"
                ;; Previous (ignore).
                "-" "\\([[:digit:]]+\\),\\([[:digit:]]+\\)" "[[:blank:]]+"
                ;; Current (use).
                "\\+" "\\([[:digit:]]+\\),\\([[:digit:]]+\\)" "[[:blank:]]+@@")
              current-filename-diff-point-max t 1))
          (let*
            (
              (diff-hunk-point (match-beginning 1))
              (diff-hunk-begin
                (string-to-number
                  (buffer-substring-no-properties (match-beginning 4) (match-end 4))))
              (diff-hunk-lines
                (string-to-number
                  (buffer-substring-no-properties (match-beginning 5) (match-end 5))))
              (diff-hunk-end (+ diff-hunk-begin diff-hunk-lines)))
            ;; We have something like this:
            ;; @@ -1,4 +1,5 @@
            ;; string-to-number
            ;; (message "%S %S" diff-hunk-begin diff-hunk-end)

            ;; If the last hunk was set as the fallback, use this chink as the
            ;; end of that fallback.
            (when (and (null fallback-point-end) (not (null fallback-point-begin)))
              (setq fallback-point-end diff-hunk-point))

            ;; Scan down the the line...
            (cond
              ((< current-line diff-hunk-begin)
                (let ((delta (- diff-hunk-begin current-line)))
                  (when (or (null fallback-delta-lines) (> fallback-delta-lines delta))
                    (setq fallback-point-begin diff-hunk-point)
                    (setq fallback-point-is-begin t)
                    (setq fallback-delta-lines delta)
                    ;; Set next iteration.
                    (setq fallback-point-end nil))))
              ((>= current-line diff-hunk-end)
                (let ((delta (- current-line diff-hunk-end)))
                  (when (or (null fallback-delta-lines) (> fallback-delta-lines delta))
                    (setq fallback-point-begin diff-hunk-point)
                    (setq fallback-point-is-begin nil)
                    (setq fallback-delta-lines delta)
                    ;; Set next iteration.
                    (setq fallback-point-end nil))))
              (t
                (let ((diff-line-current diff-hunk-begin))
                  (forward-line)
                  ;; Avoid eternal loop (for mal-formed diffs).
                  (while (null point-found)
                    (let ((c (char-after (point))))
                      (cond
                        ((memq c '(?\s ?+))
                          (when (eq diff-line-current current-line)
                            (setq point-found (+ 1 (point) current-column)))
                          (setq diff-line-current (+ 1 diff-line-current)))
                        ((eq c ?-)
                          nil)
                        (t
                          (user-error "Malformed diff, unexpected character %S" c))))
                    (forward-line))))))))

      ;; May be nil, return either way.
      (cond
        (strict
          point-found)
        (t
          (or
            point-found
            ;; Use the beginning or end of the hunk.
            (save-excursion
              (cond
                (fallback-point-is-begin
                  (goto-char fallback-point-begin)
                  (forward-line 1)
                  (forward-char))
                (t
                  (goto-char (or fallback-point-end current-filename-diff-point-max))
                  (forward-line -1)
                  (forward-char)))
              ;; fallback-point-end
              (point))))))))

;;;###autoload
(defun diff-at-point-open-and-goto-hunk (&optional scroll-reset)
  "Open a diff of the repository in the current frame.
Jumping to the file & line.

When SCROLL-RESET is not nil the view re-centers,
otherwise the offset from the window is kept."
  (interactive)
  ;; Any narrowing causes the offset calculations to fail.
  (save-restriction
    (widen)

    (let*
      (
        (current-filename (buffer-file-name))
        (current-line (line-number-at-pos))
        (current-column (- (point) (line-beginning-position)))

        (init-buffer (current-buffer))
        (init-window (selected-window))
        (lines-from-top
          (cond
            (scroll-reset
              nil)
            (t
              (count-lines
                (window-start init-window)
                (save-excursion
                  (move-beginning-of-line nil)
                  (point))))))

        ;; Replace the current window.
        (pop-up-windows nil))

      (when (funcall diff-at-point-diff-command)
        (cond
          ((eq init-buffer (current-buffer))
            (message
              (concat
                "While 'diff-at-point-diff-command' succeeded, "
                "no diff buffer was created by 'diff-at-point-diff-command'")))
          (t
            (when current-filename
              (let*
                (
                  (current-filename-relative
                    (file-relative-name current-filename default-directory))
                  (point-found
                    (diff-at-point-file-line-to-point
                      current-filename-relative
                      current-line
                      current-column)))
                ;; Go to the file in the diff which we were previously viewing.
                (when point-found
                  (goto-char point-found)
                  (cond
                    (scroll-reset
                      (recenter))
                    (t
                      (set-window-start
                        init-window
                        (save-excursion
                          (forward-line (- lines-from-top))
                          (point))
                        t))))))))))))

;;;###autoload
(defun diff-at-point-goto-source-and-close (&optional scroll-reset)
  "Go to the source and close the current diff buffer.

When SCROLL-RESET is not nil the view re-centers,
otherwise the offset from the window is kept."
  (interactive)
  (let*
    (
      (buf (current-buffer))
      ;; Replace the current window.
      (pop-up-windows nil)

      (init-window (selected-window))
      (lines-from-top
        (cond
          (scroll-reset
            nil)
          (t
            (count-lines
              (window-start init-window)
              (save-excursion
                (move-beginning-of-line nil)
                (point)))))))

    ;; From 'diff-mode'
    (diff-goto-source)

    (kill-buffer buf)
    ;; Convenient to center the view.
    (cond
      (scroll-reset
        (recenter))
      (t
        (set-window-start
          init-window
          (save-excursion
            (forward-line (- lines-from-top))
            (point))
          t)))))

(provide 'diff-at-point)

;;; diff-at-point.el ends here
