;;; helm-rg.el --- a helm interface to ripgrep -*- lexical-binding: t -*-
;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;; Author: Danny McClanahan
;; Version: 0.1
;; Package-Version: 20180206.631
;; Package-Commit: 96dcbeb366caa0b158668384113458ee5f7c4dfd
;; URL: https://github.com/cosmicexplorer/helm-rg
;; Package-Requires: ((emacs "25") (helm "2.8.8") (cl-lib "0.5") (dash "2.13.0"))
;; Keywords: find, file, files, helm, fast, rg, ripgrep, grep, search


;;; Commentary:

;; The below is generated from a README at
;; https://github.com/cosmicexplorer/helm-rg.

;; Search massive codebases extremely fast, using `ripgrep' and `helm'.
;; Inspired by `helm-ag' and `f3'.

;; Also check out rg.el, which I haven't used much but seems pretty cool.


;; Usage:

;; *See the `ripgrep' whirlwind tour for further information on invoking
;; `ripgrep'.*

;; - Invoke the interactive function `helm-rg' to start a search with `ripgrep'
;; in the current directory.
;;     - `helm' is used to browse the results and update the output as you
;; type.
;;     - Each line has the file path, the line number, and the column number of
;; the start of the match, and each part is highlighted differently.
;;     - Use 'TAB' to invoke the helm persistent action, which previews the
;; result and highlights the matched text in the preview.
;;     - Use 'RET' to visit the file containing the result, move point to the
;; start of the match, and recenter.
;; - The text entered into the minibuffer is interpreted as a PCRE regexp which
;; `ripgrep' uses to search your files.
;; - Use 'M-d' to select a new directory to search from.
;; - Use 'M-g' to input a glob pattern to filter files by, e.g. `*.py'.
;;     - The glob pattern defaults to the value of
;; `helm-rg-default-glob-string', which is an empty string (matches every file)
;; unless you customize it.
;;     - Pressing 'M-g' again shows the same minibuffer prompt for the glob
;; pattern, with the string that was previously input.


;; TODO:

;; - make a keybinding to move by files (go to next file of results)
;;     - also one to move by containing directory
;; - make a keybinding to drop into an edit mode and edit file content inline
;; in results like helm-ag


;; License:

;; GPL 3.0+

;; End Commentary


;;; Code:

(require 'ansi-color)
(require 'cl-lib)
(require 'dash)
(require 'helm)
(require 'helm-lib)
(require 'rx)


;; Helpers
(defun helm-rg--always-safe-local (_)
  "Use as a :safe predicate in a `defcustom' form to accept any local override."
  t)


;; Customization
(defgroup helm-rg nil
  "Group for `helm-rg' customizations."
  :group 'files)

(defcustom helm-rg-base-command '("rg" "--vimgrep" "--color=always")
  "The beginning of the command line to invoke ripgrep, as a list."
  :type 'list
  :safe #'helm-rg--always-safe-local
  :group 'helm-rg)

(defcustom helm-rg-candidate-limit 2000
  "The number of lines of output to show at once when running `helm-rg'."
  :type 'integer
  :safe #'helm-rg--always-safe-local
  :group 'helm-rg)

(defcustom helm-rg-default-glob-string ""
  "The glob pattern used for the '-g' argument to ripgrep.
Set to the empty string to match every file."
  :type 'string
  :safe #'helm-rg--always-safe-local
  :group 'helm-rg)

(defcustom helm-rg-thing-at-point 'symbol
  "Type of object at point to initialize the `helm-rg' minibuffer input with."
  :type 'symbol
  :group 'helm-rg)

(defcustom helm-rg--display-buffer-default-method #'switch-to-buffer
  "The function to use to display each visited buffer in some window."
  :type 'function
  :group 'helm-rg)

(defface helm-rg-preview-line-highlight
  '((t (:background "green" :foreground "black")))
  "Face for the line of text matched by the ripgrep process."
  :group 'helm-rg)

(defface helm-rg-preview-match-highlight
  '((t (:background "purple" :foreground "white")))
  "Face of the text matched by the pattern given to the ripgrep process."
  :group 'helm-rg)


;; Constants
(defconst helm-rg--helm-buffer-name "*helm-rg*")
(defconst helm-rg--process-name "*helm-rg--rg*")
(defconst helm-rg--process-buffer-name "*helm-rg--rg-output*")

(defconst helm-rg--error-process-name "*helm-rg--error-process*")
(defconst helm-rg--error-buffer-name "*helm-rg--errors*")

(defconst helm-rg--vimgrep-output-line-regexp
  (rx (: bol
         (group (+ (not (any ?:))))
         ":"
         (group (+ (any digit)))
         ":"
         (group (+ (any digit)))
         ":"
         (group (* nonl))
         eol))
  "Regexp matching the output of invoking ripgrep with the '--vimgrep' option.")

(defconst helm-rg--case-insensitive-pattern-regexp
  (rx (: bos (* (not upper)) eos))
  "Regexp matching an search which should be interpreted case-insensitively.")

(defconst helm-rg--alternate-display-buffer-method #'pop-to-buffer
  "A function accepting a single argument BUF and displaying the buffer.")


;; Variables
(defvar helm-rg--append-persistent-buffers nil
  "Whether to record buffers opened during an `helm-rg' session.")

(defvar helm-rg--cur-persistent-bufs nil
  "List of buffers opened temporarily during an `helm-rg' session.")

(defvar helm-rg--current-overlays nil
  "List of overlays used to highlight matches in `helm-rg'.")

(defvar helm-rg--current-dir nil
  "Working directory for the current `helm-rg' session.")

(defvar helm-rg--glob-string nil
  "Glob string used for the current `helm-rg' session.")

(defvar helm-rg--glob-string-history nil
  "History variable for the selection of `helm-rg--glob-string'.")

(defvar helm-rg--display-buffer-method nil
  "The method to use to display a buffer visiting a result.
Should accept one argument BUF, the buffer to display.")


;; Logic
(defun helm-rg--make-dummy-process ()
  "Make a process that immediately exits to display just a title."
  (let* ((dummy-proc (make-process
                      :name helm-rg--process-name
                      :buffer helm-rg--process-buffer-name
                      :command '("echo")
                      :noquery t))
         (helm-src-name
          (format "rg empty dummy process (no output) @ %s"
                  helm-rg--current-dir)))
    (helm-attrset 'name helm-src-name)
    dummy-proc))

(defun helm-rg--make-process ()
  "Invoke ripgrep in `helm-rg--current-dir' with `helm-pattern'."
  (let ((default-directory helm-rg--current-dir))
    (if (string= "" helm-pattern)
        (helm-rg--make-dummy-process)
      (let* ((case-insensitive-p
              (let ((case-fold-search nil))
                (string-match-p
                 helm-rg--case-insensitive-pattern-regexp helm-pattern)))
             (rg-cmd
              (append
               helm-rg-base-command
               (list "-g" helm-rg--glob-string)
               (if case-insensitive-p '("-i") ())
               (list helm-pattern)))
             (real-proc (make-process
                         :name helm-rg--process-name
                         :buffer helm-rg--process-buffer-name
                         :command rg-cmd
                         :noquery t))
             (helm-src-name
              (format "rg cmd: '%s' @ %s"
                      (mapconcat (lambda (s) (format "'%s'" s))
                                 rg-cmd " ")
                      helm-rg--current-dir)))
        (helm-attrset 'name helm-src-name)
        (set-process-query-on-exit-flag real-proc nil)
        real-proc))))

(defun helm-rg--decompose-vimgrep-output-line (line)
  "Parse LINE into its constituent elements, returning a plist."
  (when (string-match helm-rg--vimgrep-output-line-regexp line)
    (let ((matches (cl-mapcar (lambda (ind) (match-string ind line))
                              (number-sequence 1 4))))
      (cl-destructuring-bind (file-path line-no col-no content) matches
        (list
         :file-path file-path
         :line-no (1- (string-to-number line-no))
         :col-no (1- (string-to-number col-no))
         :content content)))))

(defun helm-rg--pcre-to-elisp-regexp (pcre)
  "Convert the string PCRE to an Emacs Lisp regexp."
  (with-temp-buffer
    (insert pcre)
    (goto-char (point-min))
    ;; convert (, ), {, }, |
    (while (re-search-forward "[(){}|]" nil t)
      (backward-char 1)
      (cond ((looking-back "\\\\\\\\" nil))
            ((looking-back "\\\\" nil)
             (delete-char -1))
            (t
             (insert "\\")))
      (forward-char 1))
    ;; convert \s and \S -> \s- \S-
    (goto-char (point-min))
    (while (re-search-forward "\\(\\\\s\\)" nil t)
      (unless (looking-back "\\\\\\\\s" nil)
        (insert "-")))
    (buffer-string)))

(defun helm-rg--make-overlay-with-face (beg end face)
  "Generate an overlay in region BEG to END with face FACE."
  (let ((olay (make-overlay beg end)))
    (overlay-put olay 'face face)
    olay))

(defun helm-rg--delete-overlays ()
  "Delete all cached overlays in `helm-rg--current-overlays', and clear it."
  (mapc #'delete-overlay helm-rg--current-overlays)
  (setq helm-rg--current-overlays nil))

(defun helm-rg--get-overlay-columns (elisp-regexp content)
  "Find regions matching ELISP-REGEXP in the string CONTENT."
  (with-temp-buffer
    (insert content)
    (goto-char (point-min))
    (cl-loop
     while (re-search-forward elisp-regexp nil t)
     for (beg end) = (match-data t)
     collect (list :beg (1- beg) :end (1- end)))))

(defun helm-rg--async-action (cand)
  "Visit the file at the line and column specified by CAND.
The match is highlighted in its buffer."
  (let ((default-directory helm-rg--current-dir))
    (helm-rg--delete-overlays)
    (cl-destructuring-bind (&key file-path line-no col-no content)
        (helm-rg--decompose-vimgrep-output-line cand)
      (let* ((file-abs-path
              (expand-file-name file-path))
             (buffer-to-display
              (or (find-buffer-visiting file-abs-path)
                  (let ((new-buf (find-file-noselect file-abs-path)))
                    (when helm-rg--append-persistent-buffers
                      (push new-buf helm-rg--cur-persistent-bufs))
                    new-buf)))
             (olay-cols
              (helm-rg--get-overlay-columns
               (helm-rg--pcre-to-elisp-regexp helm-pattern)
               content)))
        (funcall helm-rg--display-buffer-method buffer-to-display)
        (goto-char (point-min))
        (forward-line line-no)
        (let* ((line-olay
                (helm-rg--make-overlay-with-face
                 (line-beginning-position) (line-end-position)
                 'helm-rg-preview-line-highlight))
               (match-olays
                (-map (-lambda ((&plist :beg beg :end end))
                        (helm-rg--make-overlay-with-face
                         (+ (point) beg) (+ (point) end)
                         'helm-rg-preview-match-highlight))
                      olay-cols)))
          (setq helm-rg--current-overlays
                (cons line-olay match-olays)))
        (forward-char col-no)
        (recenter)))))

(defun helm-rg--async-persistent-action (cand)
  "Visit the file at the line and column specified by CAND.
Call `helm-rg--async-action', but push the buffer corresponding to CAND to
`helm-rg--current-overlays', if there was no buffer visiting it already."
  (let ((helm-rg--append-persistent-buffers t))
    (helm-rg--async-action cand)))

(defun helm-rg--kill-proc-if-live (proc-name)
  "Delete the process named PROC-NAME, if it is alive."
  (let ((proc (get-process proc-name)))
    (when (process-live-p proc)
      (delete-process proc))))

(defun helm-rg--kill-bufs-if-live (&rest bufs)
  "Kill any live buffers in BUFS."
  (mapc
   (lambda (buf)
     (when (buffer-live-p (get-buffer buf))
       (kill-buffer buf)))
   bufs))

(defun helm-rg--unwind-cleanup ()
  "Reset all the temporary state in `defvar's in this package."
  (helm-rg--delete-overlays)
  (cl-loop
   for opened-buf in helm-rg--cur-persistent-bufs
   unless (eq (current-buffer) opened-buf)
   do (kill-buffer opened-buf)
   finally (setq helm-rg--cur-persistent-bufs nil))
  (helm-rg--kill-proc-if-live helm-rg--process-name)
  (helm-rg--kill-bufs-if-live helm-rg--helm-buffer-name
                          helm-rg--process-buffer-name
                          helm-rg--error-buffer-name))

(defun helm-rg--do-helm-rg (rg-pattern)
  "Invoke ripgrep to search for RG-PATTERN, using `helm'."
  (helm :sources '(helm-rg-process-source)
        :buffer helm-rg--helm-buffer-name
        :input rg-pattern
        :prompt "rg pattern: "))

(defun helm-rg--get-thing-at-pt ()
  "Get the object surrounding point, or the empty string."
  (helm-aif (thing-at-point helm-rg-thing-at-point)
      (substring-no-properties it)
    ""))


;; Toggles and settings
(defmacro helm-rg--run-after-exit (&rest body)
  "Wrap BODY in `helm-run-after-exit'."
  `(helm-run-after-exit (lambda () ,@body)))

(defun helm-rg--set-glob ()
  "Set the glob string used to invoke ripgrep and search again."
  (interactive)
  (let* ((pat helm-pattern)
         (start-dir helm-rg--current-dir))
    (helm-rg--run-after-exit
     (let ((helm-rg--current-dir start-dir)
           (helm-rg--glob-string
            (read-string
             "rg glob: " helm-rg--glob-string 'helm-rg--glob-string-history)))
       (helm-rg--do-helm-rg pat)))))

(defun helm-rg--set-dir ()
  "Set the directory in which to invoke ripgrep and search again."
  (interactive)
  (let ((pat helm-pattern))
    (helm-rg--run-after-exit
     (let ((helm-rg--current-dir
            (read-directory-name "rg directory: " helm-rg--current-dir nil t)))
       (helm-rg--do-helm-rg pat)))))


;; Keymap
(defconst helm-rg-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map helm-map)
    (define-key map (kbd "M-g") #'helm-rg--set-glob)
    (define-key map (kbd "M-d") #'helm-rg--set-dir)
    map)
  "Keymap for `helm-rg'.")


;; Helm sources
(defconst helm-rg-process-source
  (helm-build-async-source "ripgrep"
    :candidates-process #'helm-rg--make-process
    :candidate-number-limit helm-rg-candidate-limit
    :action (helm-make-actions "Visit" #'helm-rg--async-action)
    :filter-one-by-one #'ansi-color-apply
    :persistent-action #'helm-rg--async-persistent-action
    :keymap 'helm-rg-map)
  "Helm async source to search files in a directory using ripgrep.")


;; Autoloaded functions
;;;###autoload
(defun helm-rg (rg-pattern &optional pfx)
  "Search for the perl regexp RG-PATTERN extremely quickly with ripgrep.

\\{helm-rg-map}"
  (interactive (list (helm-rg--get-thing-at-pt) current-prefix-arg))
  (let* ((helm-rg--current-dir (or helm-rg--current-dir
                                   default-directory))
         (helm-rg--glob-string (or helm-rg--glob-string
                                   helm-rg-default-glob-string))
         (helm-rg--display-buffer-method
          (if pfx helm-rg--alternate-display-buffer-method
            helm-rg--display-buffer-default-method)))
    (unwind-protect (helm-rg--do-helm-rg rg-pattern)
      (helm-rg--unwind-cleanup))))

(provide 'helm-rg)
;;; helm-rg.el ends here
