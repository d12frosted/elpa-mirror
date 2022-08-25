;;; auto-sudoedit.el --- Auto sudo edit by tramp -*- lexical-binding: t -*-

;; Author: ncaq <ncaq@ncaq.net>
;; Version: 1.1.0
;; Package-Version: 20220421.1147
;; Package-Commit: 39cb574a4b5ec74ad62857320bf5fec58abe876f
;; Package-Requires: ((emacs "26.1")(f "0.19.0"))
;; URL: https://github.com/ncaq/auto-sudoedit

;;; Commentary:

;; when find-file-hook and dired-mode-hook, and current path not writable
;; re-open tramp sudo edit automatic

;;; Code:

(require 'dired)
(require 'f)
(require 'recentf)
(require 'tramp)
(require 'tramp-sh)

(defcustom auto-sudoedit-ask
  nil
  "Ask for user confirmation when reopening?"
  :group 'auto-sudoedit
  :type 'boolean)

(defun auto-sudoedit-path (curr-path)
  "To convert path to tramp using sudo path.
Argument CURR-PATH is current path.
The result is a cons cell in the format '(USER . TRAMP-PATH).
USER is nil, when we cannot open via sudo."
  ;; trampのpathに変換します
  (let* ((file-owner (auto-sudoedit-file-owner curr-path))
         (tramp-path
          (if (tramp-tramp-file-p curr-path)
              (auto-sudoedit-path-from-tramp-ssh-like curr-path file-owner)
            (concat "/sudo::" curr-path))))
    (if (and
         ;; We must know the file owner's login name
         ;; If we can't, we don't know which user to sudo as
         file-owner
         ;; The file owner must be different from our current user so that the sudo makes sense
         (not (string= file-owner (auto-sudoedit-current-user curr-path)))
         ;; 変換前のパスと同じでなく(2回めの変換はしない)
         (not (equal curr-path tramp-path)))
        (cons file-owner tramp-path)
      (cons nil curr-path))))

(defun auto-sudoedit-file-owner (path)
  "Determine the login name of the user PATH belongs to."
  (file-attribute-user-id (file-attributes path 'string)))

(defun auto-sudoedit-current-user (path)
  "Determine the user name visiting PATH.  E.g. local Emacs user or ssh login."
  (if (tramp-tramp-file-p path)
      ;; We can't just go by the user in the tramp filename, because it may have been omitted
      (tramp-get-remote-uid (tramp-dissect-file-name path) 'string)
    (user-login-name)))

(defun auto-sudoedit-path-from-tramp-ssh-like (curr-path new-user)
  "Argument CURR-PATH is tramp path(that use protocols such as ssh).
NEW-USER is the user for sudo."
  (let* ((file-name (tramp-dissect-file-name curr-path))
         (method (tramp-file-name-method file-name))
         (user (tramp-file-name-user file-name))
         (host (tramp-file-name-host file-name))
         (port (tramp-file-name-port file-name))
         (localname (tramp-file-name-localname file-name))
         (hop (tramp-file-name-hop file-name))
         (new-method "sudo")
         (new-host host)
         (new-port port)
         (new-localname localname)
         (new-hop (format "%s%s:%s%s%s|" (or hop "") method (if user (concat user "@") "") host (if port (concat port "#") ""))))
    ;; 最終メソッドがsudoである場合それ以上の変換は無意味なので行わない。
    (if (equal method "sudo")
        curr-path
      (tramp-make-tramp-file-name
       (make-tramp-file-name
        :method new-method
        :user new-user
        :host new-host
        :port new-port
        :localname new-localname
        :hop new-hop)))))

(defun auto-sudoedit-current-path ()
  "Current path file or dir."
  (or (buffer-file-name) list-buffers-directory))

(defun auto-sudoedit-sudoedit (curr-path)
  "Open sudoedit.  Argument CURR-PATH is path."
  (interactive (list (auto-sudoedit-current-path)))
  (find-file (cdr (auto-sudoedit-path curr-path))))

(defun auto-sudoedit ()
  "`auto-sudoedit' hook for `find-file'.
Reopen the buffer via tramp with sudo method."
  (let* ((curr-path (auto-sudoedit-current-path))
         (remote-info (auto-sudoedit-path curr-path))
         (user (car remote-info))
         (tramp-path (cdr remote-info)))
    (when (and
           curr-path
           user
           tramp-path
           (or
            (not auto-sudoedit-ask)
            (y-or-n-p (format "This buffer belongs to user %s.  Reopen this buffer as user %s? " user user))))
      ;; We have to tell emacs that this buffer now visits another file (actually the same one, just via tramp sudo)
      ;; We have to do things differently for normal files and for dired
      (when buffer-file-name
        (set-visited-file-name tramp-path t))
      (when dired-directory
        ;; Remove the buffer as displaying the old directory path in dired's active buffer list
        (dired-unadvertise dired-directory)
        (setq list-buffers-directory tramp-path)
        (setq dired-directory tramp-path)
        (setq default-directory tramp-path)
        ;; Insert the new directory path in dired's active buffer list
        (dired-advertise))
      ;; Remove the old filename from the recentf-list
      ;; TODO: Is this a good idea? Could this break something?
      (when (string= (car recentf-list) curr-path)
        (pop recentf-list))
      ;; We have changed the way emacs edits the file
      ;; Therefore we have to reinitialize the buffer (read-only, etc.)
      ;; Also the file may have not been readable before
      ;; Revert buffer fixes this for us.
      ;; Use the arguments to prevent user confirmation
      ;; (There are no changes that could be discarded in the buffer anyways, it was just opened)
      (revert-buffer t t))))

;;;###autoload
(define-minor-mode
  auto-sudoedit-mode
  "When sudo is required, it automatically reopens in tramp."
  :init-value 0
  :lighter " ASE"
  (if auto-sudoedit-mode
      (progn
        (add-hook 'find-file-hook #'auto-sudoedit)
        (add-hook 'dired-mode-hook #'auto-sudoedit))
    (remove-hook 'find-file-hook #'auto-sudoedit)
    (remove-hook 'dired-mode-hook #'auto-sudoedit)))

(provide 'auto-sudoedit)

;;; auto-sudoedit.el ends here
