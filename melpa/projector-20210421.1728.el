;;; projector.el --- Lightweight library for managing project-aware shell and command buffers
;;
;; Copyright 2013-2021 Justin Talbott
;;
;; Author: Justin Talbott <justin@waymondo.com>
;; URL: https://github.com/waymondo/projector.el
;; Package-Version: 20210421.1728
;; Package-Commit: 7bbee0ef70817d52339119d4517dbbcbab930de6
;; Version: 0.3.2
;; Package-Requires: ((alert "1.1") (projectile "0.11.0") (cl-lib "0.5"))
;; License: GNU General Public License version 3, or (at your option) any later version
;;
;;; Commentary:
;;
;;; Installation:
;;
;;   (require 'projector)
;;   (setq alert-default-style 'notifier) ; for background alerts
;;   (setq projector-always-background-regex '("^mysql.server\\.*" "^powder\\.*"))
;;
;;; Code:

(require 'cl-lib)
(require 'alert)

(defcustom projector-always-background-regex '()
  "A list of regex patterns for shell commands to always run in the background."
  :type 'list
  :group 'projector)

(defcustom projector-command-modes-alist '()
  "An alist of command patterns to run in specific modes.
The alist should follow the format of (COMMAND-REGEX . MODE)."
  :type 'alist
  :group 'projector)

(defcustom projector-default-command nil
  "The default command to run with `projector-run-default-shell-command'.
This is usually most helpful to set on a directoy local level via a
`.dir-locals.el' file."
  :group 'projector
  :type 'string)

(defcustom projector-completion-system 'default
  "The completion system to be used by Projectile."
  :group 'projector
  :type '(radio
          (const :tag "Ido" ido)
          (const :tag "Ivy" ivy)
          (const :tag "Default" default)
          (function :tag "Custom function")))

(defcustom projector-use-vterm (featurep 'vterm)
  "Opt into using `vterm' instead of `shell-mode' for
buffers. Defaults to true if `vterm' is installed."
  :group 'projector
  :type 'boolean)

(put 'projector-default-command 'safe-local-variable #'stringp)

(defvar projector-buffer-prefix "projector: "
  "Prefix for all projector-created buffers.")

(defvar projector-process-cache-alist '()
  "A cached alist of command buffers and processes.")

(defvar projector-command-history '()
  "The minibuffer history of `projector' shell commands run.")

(defvar projector-ivy-command-history nil
  "Store command history for ivy backend completion.")

(declare-function ido-complete-space "ido")

(defvar projector-ido-no-complete-space nil
  "Advice flag to allow space to insert actual space with `ido' completion.")

(defadvice ido-complete-space (around ido-insert-space activate)
  "Allow space on keyboard to insert space when `ido'-ing shell commands."
  (if projector-ido-no-complete-space
      (insert " ")
    ad-do-it))

(defun projector-shell-buffer-name ()
  (concat "*" projector-buffer-prefix (projectile-project-name) "*"))

(defun projector-shell-command-buffer-name (cmd)
  (concat "*" projector-buffer-prefix (projectile-project-name) " " cmd "*"))

(defun projector-shell-command-output-title (process msg)
  (concat (process-name process) " - " msg))

(defun projector-string-match-pattern-in-list (str lst)
  (consp (memq t (mapcar (lambda (s) (numberp (string-match s str))) lst))))

(defun projector-mode-for-command (cmd)
  (assoc-default cmd projector-command-modes-alist (lambda (x y) (string-match x y))))

(defun projector-shell-or-vterm (buf-name)
  (if projector-use-vterm
      (vterm buf-name)
    (shell buf-name)))

(defun projector-make-shell ()
  (with-temp-buffer
    (cd (projectile-project-root))
    (let ((buf-name (projector-shell-buffer-name)))
      (projector-shell-or-vterm buf-name)
      (get-buffer buf-name))))

(defun projector-output-message-kill-buffer-sentinel (process msg)
  (when (memq (process-status process) '(exit signal))
    (alert (with-current-buffer (get-buffer (process-buffer process)) (buffer-string))
           :title (projector-shell-command-output-title process msg))
    (kill-buffer (process-buffer process))))

(defun projector-async-shell-command-get-buffer ()
  (let ((command-buffer-name (projector-shell-command-buffer-name cmd)))
    (async-shell-command cmd command-buffer-name)
    (get-buffer command-buffer-name)))

(defvar-local projector-vterm-buffer-command nil
  "Cache the last shell command for the current vterm buffer.")

(defun projector-vterm-shell-command-get-buffer ()
  (let* ((command-buffer-name (projector-shell-command-buffer-name cmd))
         (buf (get-buffer-create command-buffer-name)))
    (with-current-buffer buf
      (unless (derived-mode-p 'vterm-mode)
        (vterm-mode)
        (vterm-send-string cmd)
        (vterm-send-return)
        (setq projector-vterm-buffer-command cmd)))
    buf))

(defun projector-run-command-buffer (cmd in-current-directory notify-on-exit)
  (if (or notify-on-exit (projector-string-match-pattern-in-list cmd projector-always-background-regex))
      (with-temp-buffer
        (unless in-current-directory (cd (projectile-project-root)))
        (set-process-sentinel (start-process-shell-command cmd cmd cmd) #'projector-output-message-kill-buffer-sentinel))
    (let ((command-buffer (get-buffer (projector-shell-command-buffer-name cmd))))
      (if command-buffer
          (switch-to-buffer command-buffer)
        (switch-to-buffer
         (save-window-excursion
           (unless in-current-directory (cd (projectile-project-root)))
           (if projector-use-vterm
               (projector-vterm-shell-command-get-buffer)
             (projector-async-shell-command-get-buffer))))
        (let* ((command-buffer-mode (projector-mode-for-command cmd))
               (command-buffer-name (buffer-name (current-buffer)))
               (command-buffer-process (get-buffer-process (current-buffer))))
          (add-to-list 'projector-process-cache-alist `(,command-buffer-name . ,command-buffer-process))
          (when (and (not projector-use-vterm) command-buffer-mode)
            (funcall command-buffer-mode)))))))

(defun projector-run-command-buffer-prompt (in-current-directory notify-on-exit dir-string)
  (let ((prompt (concat "Shell command (" dir-string "): "))
        (choices (cl-delete-duplicates projector-command-history :test #'equal))
        (initial-input (car projector-command-history)))
    (cond
     ((eq projector-completion-system 'ido)
      (let ((cmd
             (ido-completing-read prompt choices nil nil nil 'projector-command-history initial-input)))
        (projector-run-command-buffer cmd in-current-directory notify-on-exit)))
     ((eq projector-completion-system 'default)
      (let ((cmd
             (completing-read prompt choices nil nil nil 'projector-command-history initial-input)))
        (projector-run-command-buffer cmd in-current-directory notify-on-exit)))
     ((eq projector-completion-system 'ivy)
      (if (fboundp 'ivy-read)
          (let ((project-root (projectile-project-root)))
            (ivy-read prompt projector-command-history
                      :caller 'projector-run-command-buffer-prompt
                      :history 'projector-ivy-command-history
                      :action (lambda (cmd)
                                (unless in-current-directory (cd project-root))
                                (push cmd projector-command-history)
                                (setq projector-command-history
                                      (delq nil (delete-dups projector-command-history)))
                                (projector-run-command-buffer cmd in-current-directory notify-on-exit))))
        (user-error "Please install ivy from \
https://github.com/abo-abo/swiper")))
     (t (funcall projector-completion-system prompt choices)))))

(with-eval-after-load "ivy"
  (ivy-set-actions
   'projector-run-command-buffer-prompt
   '(("D" (lambda (cmd)
            (delete cmd projector-command-history))
      "remove from history"))))

;;;###autoload
(defun projector-rerun-buffer-process ()
  "Kill then re-run the current shell command from a shell command buffer."
  (interactive)
  (let* ((buff (buffer-name (current-buffer)))
         (active-process (get-buffer-process buff))
         (process-directory default-directory)
         (process (assoc-default buff projector-process-cache-alist)))
    (if (not process)
        (message "No buffer process found")
      (let ((cmd
             (if projector-use-vterm
                 (list projector-vterm-buffer-command)
               (process-command process)))
            (kill-buffer-query-functions '()))
        (when active-process
          (kill-process nil t))
        (kill-buffer buff)
        (let ((default-directory process-directory))
          (projector-run-command-buffer (car (last cmd)) t nil))))))

;;;###autoload
(defun projector-run-default-shell-command (&optional notify-on-exit)
  "Execute `projector-default-command' at the project root.
By default, it outputs into a dedicated buffer.
With the optional argument NOTIFY-ON-EXIT, execute command in the background
and send the exit message as a notification."
  (interactive)
  (hack-dir-local-variables-non-file-buffer)
  (if (not projector-default-command)
      (message "`projector-default-command' is unset")
    (projector-run-command-buffer projector-default-command nil notify-on-exit)))

;;;###autoload
(defun projector-run-shell-command-project-root (&optional notify-on-exit)
  "Execute command from minibuffer at the project root.
By default, it outputs into a dedicated buffer.
With the optional argument NOTIFY-ON-EXIT, execute command in the background
and send the exit message as a notification."
  (interactive "P")
  (let ((dir-string (concat (projectile-project-name) " root")))
    (projector-run-command-buffer-prompt nil (consp notify-on-exit) dir-string)))

;;;###autoload
(defun projector-run-shell-command-project-root-background ()
  "Execute command from minibuffer at the project root in the background.
Sends the exit message as a notification."
  (interactive)
  (let ((dir-string (concat (projectile-project-name) " root")))
    (projector-run-command-buffer-prompt nil t dir-string)))

;;;###autoload
(defun projector-run-shell-command-current-directory (&optional notify-on-exit)
  "Execute command from minibuffer in the current directory.
By default, it outputs into a dedicated buffer.
With the optional argument NOTIFY-ON-EXIT, execute command in the background
and send the exit message as a notification."
  (interactive "P")
  (let ((dir-string "current-directory"))
    (projector-run-command-buffer-prompt t (consp notify-on-exit) dir-string)))

;;;###autoload
(defun projector-run-shell-command-current-directory-background ()
  "Execute command from minibuffer in the current directory.
Sends the exit message as a notification."
  (interactive)
  (let ((dir-string "current-directory"))
    (projector-run-command-buffer-prompt t t dir-string)))

(defun projector-is-shell-buffer-name (buf-name)
  (when (and (>= (length buf-name) (length string-to-match))
             (string-equal (substring buf-name 0 (length string-to-match)) string-to-match))
    buf-name))

(defun projector-shell-buffers ()
  (save-excursion
    (delq
     nil
     (mapcar (lambda (buf)
               (when (buffer-live-p buf)
                 (with-current-buffer buf
                   (and (buffer-name buf)
                        (projector-is-shell-buffer-name (buffer-name buf))))))
             (buffer-list)))))

;;;###autoload
(defun projector-switch-to-or-create-project-shell ()
  "Find or create a dedicated shell for the current project."
  (interactive)
  (switch-to-buffer
   (or (get-buffer (projector-shell-buffer-name))
       (save-window-excursion (projector-make-shell))))
  (end-of-buffer))

;;;###autoload
(defun projector-open-project-shell ()
  "Use `completing-read' to find or create a `shell-mode' buffer for a project."
  (interactive)
  (let ((project-path (completing-read "Open project shell: " projectile-known-projects)))
    (with-temp-buffer
      (cd project-path)
      (projector-shell-or-vterm (projector-shell-buffer-name)))))

;;;###autoload
(defun projector-switch-to-shell-buffer ()
  "Use `completing-read' to switch to any shell buffer created by `projector'."
  (interactive)
  (let ((string-to-match (concat "*" projector-buffer-prefix)))
    (switch-to-buffer
     (completing-read "Projector Shell Buffer: " (projector-shell-buffers)))))

;;;###autoload
(defun projector-switch-to-shell-buffer-in-project ()
  "Use `completing-read' to switch to any shell buffer created by
`projector' in the current project."
  (interactive)
  (let ((string-to-match (substring (projector-shell-buffer-name) 0 -1)))
    (switch-to-buffer
     (completing-read "Projector Shell Buffer: " (projector-shell-buffers)))))

;;;###autoload
(defun projector-switch-project-run-shell-command ()
  "Switch to another `projectile' project and run a shell command
from that project's root."
  (interactive)
  (let ((project-path (completing-read "Switch to project: " projectile-known-projects)))
    (projectile-with-default-dir project-path
      (call-interactively 'projector-run-shell-command-project-root))))

;;;###autoload
(defun projector-switch-project-run-shell-command-background ()
  "Switch to another `projectile' project and run a shell command
in the background from that project's root."
  (interactive)
  (let ((project-path (completing-read "Switch to project: " projectile-known-projects)))
    (projectile-with-default-dir project-path
      (call-interactively 'projector-run-shell-command-project-root-background))))

;;;###autoload
(defun projector-switch-project-run-default-shell-command ()
  "Switch to another `projectile' project and run the default
shell command from that project's root."
  (interactive)
  (let ((project-path (completing-read "Switch to project: " projectile-known-projects)))
    (projectile-with-default-dir project-path
      (call-interactively 'projector-run-default-shell-command))))

(provide 'projector)
;;; projector.el ends here
