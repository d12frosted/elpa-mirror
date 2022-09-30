;;; private-comments-mode.el --- Minor mode for masukomi/private_comments  -*- lexical-binding: t; coding: utf-8 -*-

;; Copyright (C) 2022 Kay Rhodes
;; SPDX-License-Identifier: MIT
;;
;; Authors: Richard Chiang <richard@commandlinesystems.com>
;;              Kay Rhodes <masukomi@masukomi.org>
;; Version: 0.1.1
;; Package-Version: 20220929.1807
;; Package-Commit: b32b862e42e1f5cf26b6ca4cebea69b3f4e1aeab
;; Keywords: tools
;; URL: https://github.com/masukomi/private-comments-mode
;; Package-Requires: ((emacs "27.1"))

;;; Commentary:

;; A minor mode for ``masukomi/private_comments``.
;; https://github.com/masukomi/private_comments
;; Private comments appear as overlays and are
;; not part of the source.

;;; Code:

(require 'url-http)
(require 'vc-git)

(defvar url-http-end-of-headers)

(defgroup private-comments nil
  "Minor mode for Private Comments."
  :group 'tools)

(defvar private-comments-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map prog-mode-map)
    (define-key map (kbd "C-c C-r") #'private-comments-record)
    (define-key map (kbd "C-c C-d") #'private-comments-delete)
    (easy-menu-define private-comments-menu map "Private Comments Mode Menu"
      `("Private-Comments"
        :help "Private Comments"
        ["Record" private-comments-record
         :help "Record Comment"]
        ["Delete" private-comments-delete
         :help "Delete Comment"]))
    map)
  "Private comments mode key map.")

(defun private-comments-clear ()
  "Remove PCM overlays."
  (interactive)
  (save-excursion
    (save-restriction
      (widen)
      (dolist (ov (cl-remove-if-not
                   (lambda (ov)
                     (overlay-get ov 'pcm-commit))
                   (overlays-in (point-min) (point-max))))
        (delete-overlay ov)))))

;;;###autoload (autoload 'private-comments-mode "private-comments-mode" nil t)
(define-minor-mode private-comments-mode
  "Private Comments minor mode.

\\{private-comments-mode-map}"
  :lighter " PCM"
  (unless (buffer-file-name)
    (display-warning 'private-comments "private-comments-mode: no buffer")
    (setq private-comments-mode nil))
  (if private-comments-mode
      (condition-case-unless-debug err
          (private-comments-apply)
        (error (display-warning
                'private-comments
                (format "private-comments-apply: %s"
                        (error-message-string err)))
               (private-comments-clear)))
    (private-comments-clear)))

(defface private-comments-face
  `((((class color) (background light))
     :background "honeydew1" :foreground "#030303" ,@(when (>= emacs-major-version 27) '(:extend t)))
    (((class color) (background dark))
     :background "#383838" :foreground "#FFFFFF" ,@(when (>= emacs-major-version 27) '(:extend t))))
  "Face for annotations."
  :group 'private-comments)

(defcustom private-comments-executable-args ""
  "Command line arguments to Private Comments server."
  :group 'private-comments
  :type 'string)

(defcustom private-comments-executable "private_comments"
  "Private Comments server executable."
  :group 'private-comments
  :type 'string
  :initialize 'custom-initialize-changed
  :set (lambda (symbol value)
         (set-default symbol value)
         (unless (executable-find value)
           (display-warning 'private-comments
                            (format "'%s' not found in PATH" value)))))

(defcustom private-comments-localhost "0.0.0.0"
  "Some users keep their browser in a separate domain.
Do not set this to \"localhost\" as a numeric IP is required
for the oauth handshake."
  :group 'private-comments
  :type 'string)

(defcustom private-comments-url nil
  "Url of so-called mini API server.
Can be specified as host:port, e.g, 0.0.0.0:5749, or just the
numerical port, e.g., 5749, which assumes
`private-comments-localhost', or nil which assumes port 5749."
  :group 'private-comments
  :type 'string
  :set-after '(private-comments-localhost)
  :set (lambda (symbol value)
         (set-default symbol value)
         (cond ((null value)
                (set-default symbol (format "http://%s:%d"
                                            private-comments-localhost
                                            5749)))
               ((or (integerp value)
                    (and (stringp value)
                         (equal value (number-to-string (string-to-number value)))))
                (set-default symbol (format "http://%s:%s"
                                            private-comments-localhost value)))
               (t (set-default symbol value)))
         (let* ((attempt (symbol-value symbol))
                (reattempt (format "http://%s" attempt)))
           (unless (url-host (url-generic-parse-url attempt))
             (when (url-host (url-generic-parse-url reattempt))
               (set-default symbol reattempt))))))

(defun private-comments-ensure-server ()
  "Ensure PC Server running."
  (interactive)
  (cl-flet ((ping (repeats)
              (cl-loop
               with parsed-url = (url-generic-parse-url private-comments-url)
               repeat repeats
               when (condition-case nil
                        (prog1 t
                          (delete-process
                           (make-network-process :name "test-port"
                                                 :noquery t
                                                 :host (url-host parsed-url)
                                                 :service (url-port parsed-url)
                                                 :buffer nil
                                                 :stop t)))
                      (file-error nil))
               return t ;; skip finally
               do (accept-process-output nil 0.3))))
    (unless (ping 1)
      (if (y-or-n-p "PC Server not running. Run now? ")
          (private-comments--run-server)
        (user-error "`private-comments-ensure-server': quit")))
    (unless (ping 5)
      (error "`private-comments-ensure-server': could not start server"))))

(defconst private-comments-server-process-name "PCM Server")
(defconst private-comments-server-buffer-name
  (format "*%s*" private-comments-server-process-name))

(defun private-comments-kill-server ()
  "Kill PC Server."
  (interactive)
  (when-let ((buffer (get-buffer private-comments-server-buffer-name))
             (proc (get-buffer-process buffer)))
    (delete-process proc)))

(defun private-comments--run-server ()
  "Run PC Server."
  (let* ((buf (with-current-buffer
                  (get-buffer-create private-comments-server-buffer-name)
                (setq buffer-read-only t)
                (current-buffer)))
         (proc (apply #'start-process
                      private-comments-server-process-name
                      buf
                      private-comments-executable
                      (split-string private-comments-executable-args))))
    (set-process-query-on-exit-flag proc nil)
    (when (process-live-p proc)
      (message "private-comments-mode: '%s' started in %s"
               (file-name-nondirectory private-comments-executable)
               (process-buffer proc)))
    proc))

(defun private-comments--mod-callback (ov _after _beg _end &optional _len)
  "Stub a callback should OV be modified."
  (ignore ov))

(defun private-comments--generic-callback (buffer &rest _args)
  "Current buffer is url-http's retrieval (starts with ' *http').
BUFFER is the edit buffer from which `url-retrieve' was issued."
  (unwind-protect
      (progn
        (goto-char (1+ url-http-end-of-headers))
        (let* ((result (condition-case-unless-debug err
                           (json-parse-buffer :object-type 'plist
                                              :array-type 'list
                                              :null-object json-null
                                              :false-object json-false)
                         (json-parse-error
                          `(:status ERROR :description ,(error-message-string err)))))
               (status (plist-get result :status))
               (description (plist-get result :description)))
          (if (equal status "SUCCESS")
              ;; rebuild the world for now
              (with-current-buffer buffer
                (private-comments-apply))
            (display-warning 'private-comments
                             (format "private-comments--generic-callback[%s]: %s"
                                     status
                                     (if (stringp description)
                                         description
                                       "No description"))))))
    (kill-buffer)))

(defun private-comments--apply-callback (buffer &rest _args)
  "Current buffer is url-http's retrieval (starts with ' *http').
BUFFER is the edit buffer from which `url-retrieve' was issued."
  (unwind-protect
      (progn
        (goto-char (1+ url-http-end-of-headers))
        (let ((comments (plist-get
                         (json-parse-buffer :object-type 'plist
                                            :array-type 'list
                                            :null-object json-null
                                            :false-object json-false)
                         :comments)))
          (when (buffer-live-p buffer)
            (with-current-buffer buffer
              (private-comments-clear)
              (save-excursion
                (save-restriction
                  (widen)
                  (dolist (comment comments)
                    (goto-char (point-min))
                    (forward-line (1- (plist-get comment :line_number)))
                    (if-let ((treeish (plist-get comment :treeish))
                             (indent (current-indentation))
                             (aligned (concat
                                       (make-string indent ? )
                                       (string-trim
                                        (mapconcat
                                         #'identity
                                         (split-string
                                          (plist-get comment :comment)
                                          "[\n\r\v]")
                                         (concat "\n"
                                                 (make-string indent ? ))))
                                       "\n"))
                             (propertized (propertize
                                           aligned
                                           'face '(private-comments-face
                                                   default)))
			     ; this is the overlay on the text we're commenting on
                             (ov (make-overlay (point) (point-at-eol))))
                        (progn
                          (overlay-put ov 'pcm-commit treeish)
                          (overlay-put ov 'pcm-unformatted (plist-get comment :comment))
                          (overlay-put ov 'before-string propertized)
                          (overlay-put ov 'modification-hooks
                                       (list 'private-comments--mod-callback)))

                      (display-warning 'private-comments
                                       (concat "private-comments--apply-callback: "
                                               "unexpected "
                                               (format "%S" comment)))))))))))
    (kill-buffer)))

(defun private-comments-relative-name (base-name)
  "Divine relative path of BASE-NAME from git root."
  (with-temp-buffer
    (vc-git-command t 0 base-name "ls-files" "-z" "--full-name" "--")
    (buffer-substring-no-properties
     (point-min) (max (point-min) (1- (point-max))))))

(defvar private-comments-edit-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "\C-c\C-k" 'private-comments-edit-abort)
    (define-key map "\C-c\C-c" 'private-comments-edit-done)
    map))

(define-minor-mode private-comments-edit-mode
  "Poor man's org-src-mode minor mode.

\\{private-comments-edit-mode-map}"
  :lighter " PCM Edit"
  (setq-local header-line-format
              (substitute-command-keys
               "Edit, then exit with \\[private-comments-edit-done] \
or abort with \\[private-comments-edit-abort]")))

(defun private-comments-edit-abort ()
  "Abort adding private comment."
  (interactive)
  (kill-buffer))

(defun private-comments-edit-done ()
  "Confirm adding private comment."
  (interactive)
  (when (bound-and-true-p private-comments--edit-callback-1)
    (funcall private-comments--edit-callback-1 (buffer-string)))
  (kill-buffer))

(defun private-comments--edit-callback-4 (buffer* line-number* commit* comment)
  "Internal callback for `private-comments-edit-done'.
Starred variable names are fixed at the time of calling
`private-comment-record'.  BUFFER* is the original source
buffer (as opposed to the comment edit buffer).  LINE-NUMBER* is
the target source line number.  COMMIT* is the commit hash of
LINE-NUMBER*.  COMMENT is the just added comment."
  (private-comments-ensure-server)
  (if (not (buffer-live-p buffer*))
      (error "`private-comments--edit-callback-4': Buffer '%s' killed"
             (buffer-name buffer*))
    (with-current-buffer buffer*
      (let* ((default-directory (directory-file-name
                                 (file-name-directory (buffer-file-name))))
             (base-name (file-name-nondirectory (buffer-file-name)))
             (relative-name (private-comments-relative-name base-name))
             (url-request-method "POST")
             (json (json-encode-alist
                    `((project_name_hash . ,(secure-hash
                                             'sha256
                                             (file-name-nondirectory
                                              (directory-file-name
                                               (vc-git-root default-directory)))))
                      (file_path_hash . ,(secure-hash 'sha256 relative-name))
                      (treeish . ,commit*)
                      (line_number . ,line-number*)
                      (comment . ,comment))))
             (url-request-data json)
             (query (format "%s/v1/comments"
                            (directory-file-name private-comments-url))))
        (url-retrieve
         query
         (apply-partially
          #'private-comments--generic-callback
          buffer*)
         nil t)))))

(defvar-local private-comments--edit-callback-1 nil)
(defun private-comments-edit (callback)
  "Like `org-edit-special'.
CALLBACK is called upon `private-comments-edit-done'."
  (interactive)
  (let ((restore-window-config (current-window-configuration))
        (ov (car (cl-remove-if-not
                  (lambda (ov)
                    (overlay-get ov 'pcm-commit))
                  (overlays-at (point)))))
        (buffer (switch-to-buffer-other-window (generate-new-buffer "PCM Edit"))))
    (with-current-buffer buffer
      (add-hook 'kill-buffer-hook
                (apply-partially #'set-window-configuration restore-window-config)
                nil t)
      (setq-local private-comments--edit-callback-1 callback)
      (private-comments-edit-mode)
      (when ov
        (save-excursion
          (insert (overlay-get ov 'pcm-unformatted)))))))

(defun private-comments-blame-data (base-name)
  "Git blame BASE-NAME.
An uncommitted change cannot be privately commented."
  (with-temp-buffer
    (vc-git-command t 0 base-name "blame")
    (goto-char (point-max))
    (while (progn (beginning-of-line)
                  (and (not (bobp))
                       (not (looking-at "\\S-"))))
      (forward-line -1))
    (cl-loop with data
             with ws = "[ \\f\\t\\n\\r\\v]"
             until (not (looking-at "\\S-"))
             ;; so-called boundary commit marker
             when (looking-at (regexp-quote "^"))
             do (forward-char)
             end
             for commit = (string-trim
                           (buffer-substring-no-properties
                            (point)
                            (re-search-forward ws)))
             for line-number = (progn
                                 (re-search-forward
                                  (concat "\\([0-9]+\\))" ws))
                                 (string-to-number (match-string 1)))
             for line-string = (buffer-substring-no-properties
                                (point)
                                (line-end-position))
             unless data
             do (setq data (make-vector (1+ line-number) nil))
             end
             do (aset data line-number
                      (list :line-string line-string
                            :commit commit))
             do (beginning-of-line)
             until (bobp)
             do (forward-line -1)
             finally return data)))

(defun private-comments-delete ()
  "Delete the first preceding private comment, if any."
  (interactive)
  (if-let ((default-directory (directory-file-name
                               (file-name-directory (buffer-file-name))))
           (base-name (file-name-nondirectory (buffer-file-name)))
           (relative-name (private-comments-relative-name base-name))
           (ov (car (sort (cl-remove-if-not
                           (lambda (ov)
                             (overlay-get ov 'pcm-commit))
                           (overlays-in (point-min) (min (point-max)
                                                         (1+ (point)))))
                          (lambda (a b)
                            (> (overlay-end a) (overlay-end b))))))
           (line-number (save-excursion (goto-char (overlay-start ov))
                                        (line-number-at-pos)))
           (url-request-method "DELETE")
           (query (format "%s/v1/comments?%s"
                          (directory-file-name private-comments-url)
                          (url-build-query-string
                           `((project_name_hash ,(secure-hash
                                                  'sha256
                                                  (file-name-nondirectory
                                                   (directory-file-name
                                                    (vc-git-root default-directory)))))
                             (file_path_hash ,(secure-hash 'sha256 relative-name))
                             (line_number ,line-number)
                             (treeish ,(overlay-get ov 'pcm-commit)))))))
      (url-retrieve
       query
       (apply-partially
        #'private-comments--generic-callback
        (current-buffer))
       nil t)
    (user-error "No private comment found")))

(defsubst private-comments--uncommitted (commit)
  "Predicate whether COMMIT hash is committed."
  (or (not (stringp commit))
      (string-match-p "^0+$" commit)))

(defun private-comments-record ()
  "Record a private comment."
  (interactive)
  (let* ((default-directory (directory-file-name
                             (file-name-directory (buffer-file-name))))
         (base-name (file-name-nondirectory (buffer-file-name)))
         (blame-data (private-comments-blame-data base-name))
         ;; line-number and blame-data are one-indexed
         (line-number (line-number-at-pos))
         (blame (when (<= line-number (length blame-data))
                  (aref blame-data line-number)))
         (commit (plist-get blame :commit)))
    (if (private-comments--uncommitted commit)
        (user-error "Line %s is uncommitted" line-number)
      (private-comments-edit
       (apply-partially #'private-comments--edit-callback-4
                        (current-buffer)
                        line-number
                        commit)))))

(defun private-comments-apply ()
  "Apply overlays for extant private comments."
  (interactive)
  (private-comments-ensure-server)
  (let* ((default-directory (directory-file-name
                             (file-name-directory (buffer-file-name))))
         (base-name (file-name-nondirectory (buffer-file-name)))
         (relative-name (private-comments-relative-name base-name))
         (blame-data (private-comments-blame-data base-name))
         (blame-commits
          (cl-delete-duplicates
           (cl-remove-if
            #'private-comments--uncommitted
            (seq-map (lambda (x) (plist-get x :commit)) blame-data))
           :test #'equal))
         (query (format "%s/v1/comments?%s"
                        (directory-file-name private-comments-url)
                        (url-build-query-string
                         `((project_name_hash ,(secure-hash
                                                'sha256
                                                (file-name-nondirectory
                                                 (directory-file-name
                                                  (vc-git-root default-directory)))))
                           (file_path_hash ,(secure-hash 'sha256 relative-name))
                           (treeishes ,(mapconcat #'identity blame-commits ",")))))))
    (url-retrieve
     query
     (apply-partially
      #'private-comments--apply-callback
      (current-buffer))
     nil t)))

(provide 'private-comments-mode)

;;; private-comments-mode.el ends here
