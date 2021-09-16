;;; helm-hunks.el --- A helm interface for git hunks - browsing, staging, unstaging and killing -*- lexical-binding: t -*-

;; Copyright (C) 2012-2016 Free Software Foundation, Inc.

;; Author: @torgeir
;; Version: 1.6.3
;; Package-Version: 20171217.1933
;; Package-Commit: 6392bf716f618eac23ce81140aceb0dfacb9c6d0
;; Keywords: helm git hunks vc
;; Package-Requires: ((emacs "24.4") (helm "1.9.8"))

;; This program is free software; you can redistribute it and/or modify
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

;; A helm interface for git hunks - browsing, staging, unstaging and killing.
;;
;; Enable `helm-follow-mode' and trigger `helm-hunks' and jump around
;; unstaged hunks like never before with `C-n' and `C-p'. Stage with `C-s'.
;;
;; Run `helm-hunks-current-buffer' to jump around the current buffer only.
;;
;; Run `helm-hunks-staged' to jump around staged hunks, unstage with `C-u'.
;;
;; Run `helm-hunks-staged-current-buffer' to jump around staged hunks in
;; the current buffer only.
;;
;; Kill hunks you wish undone with `C-k'.
;;
;; Preview hunk changes with `C-c C-p', and jump to hunks in "other window"
;; or "other frame" with `C-c o' and `C-c C-o', respectively.
;;
;; Commit with `C-c C-c`, amend with `C-c C-a`.
;;
;; Quit with `C-c C-k'.
;;
;; Credits/inspiration: git-gutter+ - https://github.com/nonsequitur/git-gutter-plus/

;;; Code:

(require 'cl-lib)
(require 'helm)
(require 'subr-x)

(defgroup helm-hunks nil
  "A helm interface for git hunks"
  :group 'helm)

(defcustom helm-hunks-refresh-hook
  nil
  "Hooks triggered whenever `helm-hunks' trigger git changes, so you can refresh your favorite git-gutter on git changes."
  :type 'hook
  :group 'helm)

(defvar helm-hunks-commit-fn
  'magit-commit
  "Defun to call interactively for committing, defaults to magit.")

(defvar helm-hunks-commit-amend-fn
  'magit-commit-amend
  "Defun to call interactively for amending, defaults to magit.")

(defvar helm-hunks-preview-diffs
  nil
  "Enable preview. Shows diff lines preview inside helm while navigating.
`helm-hunks' will modify this var when toggling preview inside of the helm.")

(defconst helm-hunks--diff-re
  "^@@ -\\([0-9]+\\)\\(?:,\\([0-9]+\\)\\)? \\+\\([0-9]+\\)\\(?:,\\([0-9]+\\)\\)? @@"
  "Regex to match the git diff hunk lines, e.g `@@ -{del-line},{del-len} +{add-line},{add-len} @@'.")

(defvar helm-hunks--cmd-file-names
  "git --no-pager diff --name-only"
  "Git command to return names of the changed files.")

(defvar helm-hunks--cmd-diffs
  "git --no-pager diff --no-color --no-ext-diff --unified=0"
  "Git command to show minimal diffs.")

(defconst helm-hunks--cmd-git-root
  "git rev-parse --show-toplevel"
  "Git command to find the root folder of the current repo.")

(defconst helm-hunks--cmd-git-apply
  "git apply --unidiff-zero --cached -"
  "Git command to apply the patch read from stdin.")

(defconst helm-hunks--cmd-git-apply-reverse
  "git apply --unidiff-zero --cached --reverse -"
  "Git command to apply the patch read from stdin in reverse.")

(defconst helm-hunks--msg-no-changes
  "No changes."
  "Message shown in the helm buffer when there are no changed hunks.")

(defconst helm-hunks--msg-no-changes-staged
  "No staged changes."
  "Message shown in the helm buffer when there are no staged hunks.")

(defvar helm-hunks--is-staged
  nil
  "Is showing staged hunks.")

;; Refresh git-gutter+ on git changes
(when (and (boundp 'git-gutter+-mode)
           git-gutter+-mode
           (fboundp 'git-gutter+-refresh))
  (add-hook 'helm-hunks-refresh-hook 'git-gutter+-refresh))

(defun helm-hunks--take (n lst)
  "Take `N' elements of `LST'."
  (butlast lst (- (length lst) n)))

(defun helm-hunks--msg-no-hunks ()
  "Message to show when there are no hunks to display."
  (if helm-hunks--is-staged
      helm-hunks--msg-no-changes-staged
    helm-hunks--msg-no-changes))

(defun helm-hunks--get-file-names ()
  "List file names of changed files."
  (let* ((result (shell-command-to-string helm-hunks--cmd-file-names))
         (raw-file-names (split-string result "\r?\n")))
    (delete "" raw-file-names)))

(defun helm-hunks--get-diffs ()
  "List raw diffs per changed file."
  (let* ((result (shell-command-to-string helm-hunks--cmd-diffs))
         (split-diff-lines (split-string result "^diff --git a/"))
         (split-diff-lines-without-empties (delete "" split-diff-lines)))
    (mapcar (lambda (line)
              (concat "diff --git a/" line))
            split-diff-lines-without-empties)))

(defun helm-hunks--extract-hunk-lines (diff)
  "Split `DIFF' string on ^@@ to group lists of each hunk's header and content lines in a list."
  (mapcar (lambda (hunk)
            (concat "@@" hunk))
          (delete "" (split-string diff "^@@"))))

(defun helm-hunks--get-git-root ()
  "Get the root folder of the current git repository."
  (let ((result (shell-command-to-string helm-hunks--cmd-git-root)))
    (file-name-as-directory
     (replace-regexp-in-string "\r?\n" "" result))))

(defun helm-hunks--parse-hunk (diff-header-str hunk-str)
  "Join `DIFF-HEADER-STR' and the parsed `HUNK-STR' into a hunk.

A hunk is an association list with the fields `diff-header' containing
the diff header-line, `hunk-header' containing the hunks , `content'
containing the content of the change, `raw-content' containing the raw
diff content as an individual patch, `type' the type of change and
`line' the line the change occured on."
  (let* ((hunk-lines (split-string hunk-str "\n"))
         (hunk-header-line (car hunk-lines))
         (content-lines (cdr hunk-lines)))
    (when (string-match helm-hunks--diff-re hunk-header-line)
      (let* ((del-len (string-to-number (or (match-string 2 hunk-header-line) "1")))
             (add-line (string-to-number (match-string 3 hunk-header-line)))
             (add-len (string-to-number (or (match-string 4 hunk-header-line) "1")))
             (content (string-join content-lines "\n"))
             (type (cond ((zerop del-len) 'added)
                         ((zerop add-len) 'deleted)
                         (t 'modified)))
             (is-deleted (eq type 'deleted))
             (line (if is-deleted (1+ add-line) add-line))
             (line-end (if is-deleted line (1- (+ add-line add-len)))))
        (list (cons 'diff-header diff-header-str)
              (cons 'hunk-header hunk-header-line)
              (cons 'content content)
              (cons 'raw-content (concat diff-header-str "\n" hunk-str))
              (cons 'type type)
              (cons 'line line)
              (cons 'line-end line-end))))))

(defun helm-hunks--assoc-file-name (file-name hunks)
  "Associates `FILE-NAME' name with each hunk of the `HUNKS' list."
  (mapcar (lambda (hunk)
            (cons (cons 'file file-name)
                  hunk))
          hunks))

(defun helm-hunks--take-before-diff (acc l)
  "Grab all lines before the one starting with @@."
  (let ((head (car l)))
    (if (or (null head)
            (string-match-p "^@@.*" head))
        acc
      (helm-hunks--take-before-diff (append acc (list head)) (cdr l)))))

(defun helm-hunks--drop-before-diff (l)
  "Throw away all lines before the one starting with @@."
  (let ((head (car l)))
    (if (or (not head)
            (string-match-p "^@@.*" head))
        l
      (helm-hunks--drop-before-diff (cdr l)))))

(defun helm-hunks--get-hunks-by-file (file-names diffs-per-file)
  "Join the changed file names with their corresponding hunks in a list.

`FILE-NAMES' is the list of file names that changed.

`DIFFS-PER-FILE' holds the diff hunks ordered per file name."
  (cl-loop for file-name in file-names
           for diff-str in diffs-per-file
           collect (let* ((split-hunk (split-string diff-str "\r?\n"))
                          (diff-header-lines (helm-hunks--take-before-diff '() split-hunk))
                          (diff-header-str (string-join diff-header-lines "\n"))
                          (rest-str (string-join (helm-hunks--drop-before-diff split-hunk) "\n"))
                          (hunks-lines (helm-hunks--extract-hunk-lines rest-str))
                          (parsed-hunks (mapcar (lambda (hunk-lines)
                                                  (helm-hunks--parse-hunk diff-header-str hunk-lines))
                                                hunks-lines))
                          (parsed-hunks-with-file (helm-hunks--assoc-file-name file-name parsed-hunks)))
                     (cons file-name parsed-hunks-with-file))))

(defun helm-hunks--fontify-as-diff (content)
  "Fontify `CONTENT' as a diff, like it's shown in `diff-mode'."
  (with-temp-buffer
    (insert content)
    (diff-mode)
    (font-lock-default-function 'diff-mode)
    (font-lock-default-fontify-buffer)
    (buffer-string)))

(defun helm-hunks--format-candidate-multiline (file line type content)
  "Formats a multiline hunk, fontifying the contents of the diff.

Includes the `FILE' the change occured in, the `LINE' the change
occured at, the `TYPE' of change, and the `CONTENT' of the change."
  (let ((fontified-content (helm-hunks--fontify-as-diff content)))
    (format "%s:%s (%s)\n%s" file line type fontified-content)))

(defun helm-hunks--format-candidate-line (file line type)
  "Format a single line hunk.

Includes the `FILE' the change occured in, the `LINE' the change
occured at and the `TYPE' of change."
  (format "%s:%s (%s)" file line type))

(defun helm-hunks--format-candidate-for-display (hunk)
  "Formats `HUNK' for display as a line in helm."
  (let ((file (cdr (assoc 'file hunk))))
    (unless (equal file (helm-hunks--msg-no-hunks))
      (let* ((line (cdr (assoc 'line hunk)))
             (type (cdr (assoc 'type hunk)))
             (content (cdr (assoc 'content hunk)))
             (is-content-empty (equal "" content)))
        (if (and helm-hunks-preview-diffs
                 (not is-content-empty))
            (helm-hunks--format-candidate-multiline file line type content)
          (helm-hunks--format-candidate-line file line type))))))

(defun helm-hunks--changes ()
  "Create a list of candidates on the form `(display . real)' suitable for the `helm-hunks' source."
  (reverse
   (let* ((hunks-by-file (helm-hunks--get-hunks-by-file (helm-hunks--get-file-names)
                                                        (helm-hunks--get-diffs)))
          (changes nil))
     (dolist (hunk-by-file hunks-by-file changes)
       (let ((hunks (cdr hunk-by-file)))
         (dolist (hunk hunks)
           (push `(,(helm-hunks--format-candidate-for-display hunk) . ,hunk)
                 changes)))))))

(defun helm-hunks--candidates ()
  "Candidates for the `helm-hunks' source, on the form (display . real)."
  (let ((candidates (helm-hunks--changes)))
    (if (equal nil candidates)
        `((,(helm-hunks--msg-no-hunks) . nil))
      candidates)))

(defun helm-hunks--find-hunk-with-fn (hunk find-file-fn)
  "Jump to the changed line in the file of the `HUNK' using the provided `FIND-FILE-FN' function."
  (let* ((file (cdr (assoc 'file hunk)))
         (line (cdr (assoc 'line hunk)))
         (file-path (concat (helm-hunks--get-git-root) file)))
    (funcall find-file-fn file-path)
    (goto-char (point-min))
    (forward-line (1- line))))

(defun helm-hunks--action-find-hunk-other-window (hunk)
  "Jump to the changed line in the file of the `HUNK' using `find-file-other-window'."
  (helm-hunks--find-hunk-with-fn hunk #'find-file-other-window))

(defun helm-hunks--action-find-hunk-other-frame (hunk)
  "Jump to the changed line in the file of the `HUNK' using `find-file-other-frame'."
  (helm-hunks--find-hunk-with-fn hunk #'find-file-other-frame))

(defun helm-hunks--action-find-hunk (hunk)
  "Action that triggers on RET for the `helm-hunks' source. Jumps to the file of the `HUNK'."
  (unless (equal hunk (helm-hunks--msg-no-hunks))
    (helm-hunks--find-hunk-with-fn hunk #'find-file)))

(defun helm-hunks--persistent-action (hunk)
  "Persistent action to trigger on follow for the `helm-hunks' source. Jumps to the file of the `HUNK'."
  (unless (equal hunk (helm-hunks--msg-no-hunks))
    (helm-hunks--find-hunk-with-fn hunk #'find-file)))

(defvar helm-hunks--keymap
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map helm-map)
    (define-key map (kbd "C-k") 'helm-hunks--revert-hunk-interactive)
    (define-key map (kbd "C-s") 'helm-hunks--stage-hunk-interactive)
    (define-key map (kbd "C-u") 'helm-hunks--unstage-hunk-interactive)
    (define-key map (kbd "C-c o")   'helm-hunks--find-hunk-other-window-interactive)
    (define-key map (kbd "C-c C-o") 'helm-hunks--find-hunk-other-frame-interactive)
    (define-key map (kbd "C-c C-p") 'helm-hunks--toggle-preview-interactive)
    (define-key map (kbd "C-c C-c") 'helm-hunks--commit)
    (define-key map (kbd "C-c C-a") 'helm-hunks--commit-amend)
    (define-key map (kbd "C-c C-k") 'helm-hunks--quit)
    map)
  "Keymap for `helm-hunks'.")

(defvar helm-hunks--source
  (helm-build-sync-source "Show hunks in project"
    :candidates 'helm-hunks--candidates
    :action '(("Go to hunk" . helm-hunks--action-find-hunk))
    :persistent-action 'helm-hunks--persistent-action
    :persistent-help "[C-s] stage, [C-u] unstage/reset, [C-k] kill, [C-c C-p] show diffs, [C-c C-o] find other frame, [C-c o] find other window, [C-c C-c] commit, [C-c C-a] amend, [C-c C-k] quit"
    :multiline t
    :keymap helm-hunks--keymap
    :nomark t
    :follow 1)
  "Helm-hunks source to list changed hunks in the project.")

(defun helm-hunks--run-hooks-for-buffer-of-hunk (hunk)
  "Run refresh hooks with the buffer visiting the `HUNK's file."
  (let* ((path-of-hunk (cdr (assoc 'file hunk)))
         (buffer-name (file-name-nondirectory path-of-hunk)))
    (when buffer-name
      (with-current-buffer buffer-name
        (run-hooks 'helm-hunks-refresh-hook)))))

(defun helm-hunks--perform-fn-with-selected-hunk (stage-or-unstage-hunk-fn)
  "Perform `STAGE-OR-UNSTAGE-HUNK-FN' on the currently selected hunk.

Will refresh the helm buffer and keep the point's current position among the candidates."
  (interactive)
  (with-helm-alive-p
    (let* ((real (helm-get-selection))
           (n (1- (helm-candidate-number-at-point)))
           (candidates (helm-get-cached-candidates helm-hunks--source))
           (next-candidate (nth n candidates)))
      (when real
        (funcall stage-or-unstage-hunk-fn real)
        (helm-refresh)
        (helm-beginning-of-buffer)
        (when (and next-candidate (> n 0))
          (helm-next-line n))
        (helm-hunks--run-hooks-for-buffer-of-hunk real)))))

(defun helm-hunks--revert-collect-deleted-lines (content)
  "Collects the deleted lines from the `CONTENT's of a hunk."
  (with-temp-buffer
    (insert content)
    (goto-char (point-min))
    (cl-loop while (re-search-forward "^-\\(.*?\\)$" nil t)
             collect (match-string 1) into deleted-lines
             finally return deleted-lines)))

(defun helm-hunks--revert-added-hunk (hunk)
  "Reverts lines added by `HUNK' by deleting them."
  (let ((line (cdr (assoc 'line hunk)))
        (line-end (cdr (assoc 'line-end hunk)))
        (start-point (point)))
    (forward-line (1+ (- line-end line)))
    (delete-region start-point (point))))

(defun helm-hunks--revert-deleted-hunk (hunk)
  "Reverts lines deleted by `HUNK' by adding them back."
  (let ((content (cdr (assoc 'content hunk))))
    (dolist (line (helm-hunks--revert-collect-deleted-lines content))
      (insert (concat line "\n")))))

(defun helm-hunks--run-cmd-on-hunk (cmd hunk)
  "Run git `CMD' on `HUNK'.

Will `cd' to the git root to make git diff paths align with paths on disk as we're not nescessarily in the git root when `helm-hunks' is run, and diffs are gathered."
  (let ((raw-hunk-diff (cdr (assoc 'raw-content hunk))))
    (with-temp-buffer
      (insert raw-hunk-diff)
      (unless (zerop
               (shell-command-on-region
                (point-min)
                (point-max)
                (format "cd %s && %s"
                        (shell-quote-argument (helm-hunks--get-git-root))
                        cmd)
                t t nil))
        (buffer-string)))))

(defun helm-hunks--revert-hunk (hunk)
  "Reverts the actions of the `HUNK'."
  (helm-hunks--action-find-hunk hunk)
  (let* ((type (cdr (assoc 'type hunk)))
         (revert-fn (cl-case type
                      (added #'helm-hunks--revert-added-hunk)
                      (deleted #'helm-hunks--revert-deleted-hunk)
                      (modified (lambda (hunk)
                                  (helm-hunks--revert-added-hunk hunk)
                                  (helm-hunks--revert-deleted-hunk hunk))))))
    (helm-hunks--perform-fn-with-selected-hunk revert-fn))
  (save-buffer)
  (other-window -1))

(defun helm-hunks--stage-hunk (hunk)
  "Run git command to apply the `HUNK'."
  (helm-hunks--run-cmd-on-hunk helm-hunks--cmd-git-apply hunk))

(defun helm-hunks--unstage-hunk (hunk)
  "Run git command to apply the `HUNK' in reverse."
  (helm-hunks--run-cmd-on-hunk helm-hunks--cmd-git-apply-reverse hunk))

(defun helm-hunks--revert-hunk-interactive ()
  "Interactive defun to revert the currently selected hunk."
  (interactive)
  (when (not helm-hunks--is-staged)
    (helm-hunks--perform-fn-with-selected-hunk #'helm-hunks--revert-hunk)))

(defun helm-hunks--stage-hunk-interactive ()
  "Interactive defun to stage the currently selected hunk."
  (interactive)
  (when (not helm-hunks--is-staged)
    (helm-hunks--perform-fn-with-selected-hunk #'helm-hunks--stage-hunk)))

(defun helm-hunks--unstage-hunk-interactive ()
  "Interactive defun to unstage the currently selected hunk."
  (interactive)
  (when helm-hunks--is-staged
    (helm-hunks--perform-fn-with-selected-hunk #'helm-hunks--unstage-hunk)))

(defun helm-hunks--find-hunk-other-window-interactive ()
  "Interactive defun to jump to the changed line in the file in another window."
  (interactive)
  (with-helm-alive-p
    (helm-exit-and-execute-action #'helm-hunks--action-find-hunk-other-window)))

(defun helm-hunks--find-hunk-other-frame-interactive ()
  "Interactive defun to jump to the changed line in the file in another frame."
  (interactive)
  (with-helm-alive-p
    (helm-exit-and-execute-action #'helm-hunks--action-find-hunk-other-frame)))

(defun helm-hunks--toggle-preview-interactive ()
  "Toggle diff lines preview mode inside helm, while helm is open."
  (interactive)
  (let* ((is-preview (not helm-hunks-preview-diffs))
         (hunk (helm-get-selection))
         (file (cdr (assoc 'file hunk)))
         (line (cdr (assoc 'line hunk)))
         (type (cdr (assoc 'type hunk)))
         (candidate (helm-hunks--format-candidate-line file line type)))
    (setq helm-hunks-preview-diffs is-preview)
    (with-helm-alive-p
      (helm-force-update candidate))))

(defun helm-hunks--commit ()
  "Safe call to `helm-hunks-commit-fn' for committing."
  (interactive)
  (when (fboundp helm-hunks-commit-fn)
    (helm-run-after-exit helm-hunks-commit-fn)))

(defun helm-hunks--commit-amend ()
  "Safe call to `helm-hunks-commit-amend-fn' for amending."
  (interactive)
  (when (fboundp helm-hunks-commit-amend-fn)
    (helm-run-after-exit helm-hunks-commit-amend-fn)))

(defun helm-hunks--quit ()
  "Quit Helm-hunks."
  (interactive)
  (helm-exit-minibuffer))

;;;###autoload
(defun helm-hunks ()
  "Helm-hunks entry point."
  (interactive)
  (helm :sources '(helm-hunks--source)
        :keymap helm-hunks--keymap))

;;;###autoload
(defun helm-hunks-current-buffer ()
  "Helm-hunks entry point current buffer."
  (interactive)
  (let* ((current-file-relative (file-relative-name (buffer-file-name (current-buffer))))
         (helm-hunks--cmd-diffs-single-file (format "%s -- %s" helm-hunks--cmd-diffs current-file-relative))
         (helm-hunks--cmd-file-names-single-file (format "%s -- %s" helm-hunks--cmd-file-names current-file-relative))
         (helm-hunks--cmd-diffs helm-hunks--cmd-diffs-single-file)
         (helm-hunks--cmd-file-names helm-hunks--cmd-file-names-single-file))
    (helm-hunks)))

;;;###autoload
(defun helm-hunks-staged ()
  "Helm-hunks entry point staged hunks."
  (interactive)
  (let* ((helm-hunks--is-staged t)
         (helm-hunks--cmd-diffs-staged (format "%s --staged" helm-hunks--cmd-diffs))
         (helm-hunks--cmd-file-names-staged (format "%s --staged" helm-hunks--cmd-file-names))
         (helm-hunks--cmd-diffs helm-hunks--cmd-diffs-staged)
         (helm-hunks--cmd-file-names helm-hunks--cmd-file-names-staged))
    (helm-hunks)))

;;;###autoload
(defun helm-hunks-staged-current-buffer ()
  "Helm-hunks entry point staged hunks current buffer."
  (interactive)
  (let* ((current-file-relative (file-relative-name (buffer-file-name (current-buffer))))
         (helm-hunks--is-staged t)
         (helm-hunks--cmd-diffs-staged (format "%s --staged" helm-hunks--cmd-diffs))
         (helm-hunks--cmd-file-names-staged (format "%s --staged" helm-hunks--cmd-file-names))
         (helm-hunks--cmd-diffs-single-file (format "%s -- %s" helm-hunks--cmd-diffs-staged current-file-relative))
         (helm-hunks--cmd-file-names-single-file (format "%s -- %s" helm-hunks--cmd-file-names-staged current-file-relative))
         (helm-hunks--cmd-diffs helm-hunks--cmd-diffs-single-file)
         (helm-hunks--cmd-file-names helm-hunks--cmd-file-names-single-file))
    (helm-hunks)))

(provide 'helm-hunks)
;;; helm-hunks.el ends here
