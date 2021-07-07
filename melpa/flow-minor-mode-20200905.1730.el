;;; flow-minor-mode.el --- Flow type mode based on web-mode. -*- lexical-binding: t -*-

;; This source code is licensed under the BSD-style license found in
;; the LICENSE file in the root directory of this source tree.

;; Version: 0.3
;; Package-Version: 20200905.1730
;; Package-Commit: 804217a15a28f6918fba93c91d495ed7d50b0495
;; URL: https://github.com/an-sh/flow-minor-mode

;; Package-Requires: ((emacs "25.1"))

;;; Commentary:

;; Minor mode for flowtype.org, derived from web-mode.  Essentially a
;; rewrite of an official flow-for-emacs snippet into a standalone
;; mode with an improved usability.
;;
;; To enable this mode, enable it in your preferred javascript mode's
;; hooks:
;;
;;   (add-hook 'js2-mode-hook 'flow-minor-enable-automatically)
;;
;; This will enable flow-minor-mode for a file only when there is a
;; "// @flow" declaration at the first line and a `.flowconfig` file
;; is present in the project.  If you wish to enable flow-minor-mode
;; for all javascript files, use this instead:
;;
;;  (add-hook 'js2-mode-hook 'flow-minor-mode)
;;
;;; Code:

(require 'xref)
(require 'json)
(require 'compile)

(defconst flow-minor-buffer "*Flow Output*")

(defcustom flow-minor-default-binary "flow"
  "Flow executable to use when no project-specific binary is found."
  :group 'flow-minor-mode
  :type 'string)

(defcustom flow-minor-jump-other-window nil
  "Jump to definitions in other window."
  :group 'flow-minor-mode
  :type 'boolean)

(defcustom flow-minor-stop-server-on-exit t
  "Stop flow server when Emacs exits."
  :group 'flow-minor-mode
  :type 'boolean)

(defun flow-minor-column-at-pos (position)
  "Column number at position.
POSITION point"
  (save-excursion (goto-char position) (current-column)))

(defun flow-minor-region ()
  "Format region data."
  (if (use-region-p)
      (let ((begin (region-beginning))
            (end (region-end)))
        (format ":%d:%d,%d:%d"
                (line-number-at-pos begin)
                (flow-minor-column-at-pos begin)
                (line-number-at-pos end)
                (flow-minor-column-at-pos end)))
    ""))

(defun flow-minor-binary ()
  "Search for a local or global flow binary."
  (let* ((root (locate-dominating-file
                (or (buffer-file-name) default-directory)
                "node_modules"))
         (flow (and root
                    (expand-file-name "node_modules/.bin/flow"
                                      root))))
    (if (and flow (file-executable-p flow))
        flow
      flow-minor-default-binary)))

(defun flow-minor-cmd (&rest args)
  "Run flow with arguments, outputs to flow buffer.
ARGS"
  (apply #'call-process (flow-minor-binary) nil flow-minor-buffer t args))

(defun flow-minor-cmd-ignore-output (&rest args)
  "Run flow with arguments, ignore output.
ARGS"
  (apply #'call-process (flow-minor-binary) nil nil nil args))

(defun flow-minor-cmd-to-string (&rest args)
  "Run flow with arguments, outputs to string.
ARGS"
  (with-temp-buffer
    (apply #'call-process (flow-minor-binary) nil t nil args)
    (buffer-string)))

(defmacro flow-minor-with-flow (&rest body)
  "With flow.
BODY progn"
  `(progn
     (flow-minor-cmd-ignore-output "start")
     ,@body))

(defmacro flow-minor-region-command (region-sym &rest body)
  "Flow command on a region.
REGION-SYM symbol
BODY progn"
  (declare (indent defun))
  `(flow-minor-with-flow
    (let ((,region-sym (concat (buffer-file-name) (flow-minor-region))))
      (switch-to-buffer-other-window flow-minor-buffer)
      (setf buffer-read-only nil)
      (erase-buffer)
      ,@body)))

(defun flow-minor-status ()
  "Show errors."
  (interactive)
  (flow-minor-region-command region
    (flow-minor-cmd "status" "--from" "emacs")
    (compilation-mode)
    (setf buffer-read-only t)))

(defun flow-minor-suggest ()
  "Fill types."
  (interactive)
  (flow-minor-region-command region
    (flow-minor-cmd "suggest" region)
    (diff-mode)
    (setf buffer-read-only t)))

(defun flow-minor-coverage ()
  "Show coverage."
  (interactive)
  (flow-minor-region-command region
    (message "%s" region)
    (flow-minor-cmd "coverage" region)
    (compilation-mode)
    (setf buffer-read-only t)))

(defvar flow-type-font-lock-highlight
  '(
    ("\\([-_[:alnum:]]+\\)\\??:" . font-lock-variable-name-face)
    ("\\_<\\(true\\|false\\|null\\|undefined\\|void\\)\\_>" . font-lock-constant-face)
    ("<\\([-_[:alnum:]]+\\)>" . font-lock-type-face)
    ))

(defun flow-minor-colorize-buffer ()
  (setq font-lock-defaults '(flow-type-font-lock-highlight))
  (font-lock-fontify-buffer))

(defun flow-minor-colorize-type (text)
  (with-temp-buffer
    (insert text)
    (flow-minor-colorize-buffer)
    (buffer-string)))

(defvar flow-minor-pos-regexp "\n\\(.*:[0-9]+:[0-9]+.*\n\\)?\\'")

(defun flow-minor-type-at-pos ()
  "Show type at position."
  (interactive)
  (flow-minor-with-flow
   (let* ((file (buffer-file-name))
          (line (number-to-string (line-number-at-pos)))
          (col (number-to-string (1+ (current-column))))
          (type (flow-minor-cmd-to-string "type-at-pos" "--quiet" file line col)))
     (message "%s" (flow-minor-colorize-type
                    (replace-regexp-in-string flow-minor-pos-regexp "" type))))))

(defun flow-minor-jump-to-definition ()
  "Jump to definition."
  (interactive)
  (flow-minor-with-flow
   (let* ((file (buffer-file-name))
          (line (number-to-string (line-number-at-pos)))
          (col (number-to-string (1+ (current-column))))
          (location (json-read-from-string
                     (flow-minor-cmd-to-string "get-def" "--json" "--quiet" file line col)))
          (path (alist-get 'path location))
          (line (alist-get 'line location))
          (offset-in-line (alist-get 'start location)))
     (if (> (length path) 0)
         (progn
           (xref-push-marker-stack)
           (funcall (if flow-minor-jump-other-window #'find-file-other-window #'find-file) path)
           (goto-line line)
           (when (> offset-in-line 0)
             (forward-char (1- offset-in-line))))
       (message "Not found")))))

(defvar flow-minor-mode-map (make-sparse-keymap)
  "Keymap for ‘flow-minor-mode’.")

(define-key flow-minor-mode-map (kbd "M-.") 'flow-minor-jump-to-definition)
(define-key flow-minor-mode-map (kbd "M-,") 'xref-pop-marker-stack)

(define-key flow-minor-mode-map (kbd "C-c C-c s") 'flow-minor-status)
(define-key flow-minor-mode-map (kbd "C-c C-c c") 'flow-minor-coverage)
(define-key flow-minor-mode-map (kbd "C-c C-c t") 'flow-minor-type-at-pos)
(define-key flow-minor-mode-map (kbd "C-c C-c f") 'flow-minor-suggest)

(define-key flow-minor-mode-map [menu-bar flow-minor-mode]
  (cons "Flow" flow-minor-mode-map))

(define-key flow-minor-mode-map [menu-bar flow-minor-mode flow-minor-mode-s]
  '(menu-item "Flow status" flow-minor-status))

(define-key flow-minor-mode-map [menu-bar flow-minor-mode flow-minor-mode-c]
  '(menu-item "Flow coverage" flow-minor-coverage))

(define-key flow-minor-mode-map [menu-bar flow-minor-mode flow-minor-mode-t]
  '(menu-item "Type at point" flow-minor-type-at-pos))

(define-key flow-minor-mode-map [menu-bar flow-minor-mode flow-minor-mode-f]
  '(menu-item "Type suggestions" flow-minor-suggest))

(defun flow-minor-stop-flow-server ()
  "Stop flow hook."
  (if flow-minor-stop-server-on-exit (ignore-errors (flow-minor-cmd-ignore-output "stop"))))

(add-hook 'kill-emacs-hook 'flow-minor-stop-flow-server t)

(defun flow-minor-maybe-delete-process (name)
  (when (get-process name)
    (delete-process name)))

(defun flow-minor-eldoc-sentinel (process _event)
  (when (eq (process-status process) 'exit)
    (if (eq (process-exit-status process) 0)
        (with-current-buffer "*Flow Eldoc*"
          (goto-char (point-min))
          (save-match-data
            (if (re-search-forward flow-minor-pos-regexp nil t)
                (replace-match "")))
          (flow-minor-colorize-buffer)
          (eldoc-message (buffer-string))))))

(defun flow-minor-eldoc-documentation-function ()
  "Display type at point with eldoc."
  (flow-minor-maybe-delete-process "flow-minor-eldoc")

  (let* ((line (line-number-at-pos (point)))
         (col (+ 1 (current-column)))
         (buffer (get-buffer-create "*Flow Eldoc*"))
         (errorbuffer (get-buffer-create "*Flow Eldoc Error*"))
         (command (list (flow-minor-binary)
                        "type-at-pos"
                        "--path" buffer-file-name
                        "--quiet"
                        (number-to-string line)
                        (number-to-string col)))
         (process (make-process :name "flow-minor-eldoc"
                                :buffer buffer
                                :command command
                                :connection-type 'pipe
                                :sentinel 'flow-minor-eldoc-sentinel
                                :stderr errorbuffer)))
    (with-current-buffer buffer
      (erase-buffer))
    (with-current-buffer errorbuffer
      (erase-buffer))
    (save-restriction
      (widen)
      (process-send-region process (point-min) (point-max)))
    (process-send-string process "\n")
    (process-send-eof process))
  nil)

;;;###autoload
(define-minor-mode flow-minor-mode
  "Flow mode"
  nil " Flow" flow-minor-mode-map
  (if flow-minor-mode
      (progn
        (setq-local eldoc-documentation-function 'flow-minor-eldoc-documentation-function)
        (eldoc-mode))))

(defun flow-minor-tag-present-p ()
  "Return true if the '// @flow' tag is present in the current buffer."
  (save-excursion
    (goto-char (point-min))
    (let (stop found)
      (while (not stop)
        (when (not (re-search-forward "[^\n[:space:]]" nil t))
          (setq stop t))
        (if (equal (point) (point-min))
            (setq stop t)
          (backward-char))
        (cond ((or (looking-at "//+[ ]*@flow")
                   (looking-at "/\\**[ ]*@flow"))
               (setq found t)
               (setq stop t))
              ((looking-at "//")
               (forward-line))
              ((looking-at "/\\*")
               (when (not (re-search-forward "*/" nil t))
                 (setq stop t)))
              (t (setq stop t))))
      found)))

(defun flow-minor-configured-p ()
  "Predicate to check configuration."
  (locate-dominating-file
   (or (buffer-file-name) default-directory)
   ".flowconfig"))

;;;###autoload
(defun flow-minor-enable-automatically ()
  "Search for a flow marker and enable flow-minor-mode."
  (when (and (flow-minor-configured-p)
             (flow-minor-tag-present-p))
    (flow-minor-mode +1)))

(defun flow-status ()
  "Invoke flow to check types"
  (interactive)
  (let ((cmd (concat (flow-minor-binary) " status"))
        (regexp '(flow "^\\(Error:\\)[ \t]+\\(\\(.+\\):\\([[:digit:]]+\\)\\)"
                       3 4 nil (1) 2 (1 compilation-error-face))))
    (add-to-list 'compilation-error-regexp-alist 'flow)
    (add-to-list 'compilation-error-regexp-alist-alist regexp)
    (compile cmd)))

(provide 'flow-minor-mode)
;;; flow-minor-mode.el ends here
