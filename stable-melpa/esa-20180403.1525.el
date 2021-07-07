;;; esa.el --- Interface to esa.io

;; Original Author: Masahiro Hayashi <mhayashi1120@gmail.com>
;; Original Created: 21 Jul 2008
;; Original URL: https://github.com/mhayashi1120/yagist.el
;; Author: Nab Inno <nab@blahfe.com>
;; Created: 21 May 2016
;; Version: 0.8.13
;; Package-Version: 20180403.1525
;; Package-Commit: 417e0ac55abe9b17e0b7165d0df26bc018aff42e
;; Keywords: tools esa
;; Package-Requires: ((cl-lib "0.5"))
;; URL: https://github.com/nabinno/esa.el

;; This file is NOT part of GNU Emacs.

;; This is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 2, or (at your option) any later
;; version.
;;
;; This is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
;; FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
;; for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
;; MA 02111-1307, USA.

;;; Commentary:

;; Get the Personal API Access Token from:
;; https://yourteam.esa.io/user/tokens
;;
;; Put following to your .emacs:
;;
;; (require 'esa)
;; (setq esa-token "******************************")
;; (setq esa-team-name "yourteam")
;;
;; TODO:
;; - Add esa-tokens-and-team-names defcustom
;; - Encrypt risky configs

;;; Code:

(require 'cl-lib)
(require 'json)
(require 'url)
(require 'derived)
(require 'easy-mmode)


;;; Configuration:

(defgroup esa nil
  "Simple esa application."
  :prefix "esa-"
  :group 'applications)

(defcustom esa-token nil
  "If non-nil, will be used as your Esa OAuth token."
  :group 'esa
  :type 'string)

(defcustom esa-team-name nil
  "If non-nil, will be used as your Esa team name."
  :group 'esa
  :type 'string)

(defcustom esa-tokens-and-team-names nil
  "If non-nil, will be used as your Esa OAuth tokens and team names."
  :group 'esa
  :type 'alist)

(defcustom esa-view-esa nil
  "If non-nil, use `browse-url' to view esas after they're posted."
  :type 'boolean
  :group 'esa)

(defcustom esa-display-date-format "%Y-%m-%d %H:%M"
  "Date format displaying in `esa-list' buffer."
  :type 'string
  :group 'esa)

(defvar esa-authenticate-function nil
  "Authentication function symbol.")
(make-obsolete-variable 'esa-authenticate-function nil "0.8.13")

(defcustom esa-working-directory "~/.esa"
  "*Working directory where to go esa repository is."
  :type 'directory
  :group 'esa)

(defcustom esa-working-directory-alist nil
  "*Alist of esa numer as key, value is directory path.

Example:
\(setq esa-working-directory-alist
      `((\"1080701\" . \"~/myesa/Emacs-nativechecker\")))
"
  :type '(alist :key-type string
                :value-type directory)
  :group 'esa)

(defcustom esa-number-of-list-per-page "20"
  "Number of list per page."
  :type 'string
  :group 'esa)


;;; Stores:

;; POST /v1/teams/%s/posts
;;;###autoload
(defun esa-region (begin end &optional wip skip-notice)
  "Post the current region from BEGIN to END as a new esa at yourteam.esa.io.

With a prefix argument, makes a esa on WIP with SKIP-NOTICE."
  (interactive "r\nP")
  (let* ((name (read-from-minibuffer "Name: "))
         (category (read-from-minibuffer "Category: "))
         (tags (read-from-minibuffer "Tags: ")))
    (esa-request
     "POST"
     (format "https://api.esa.io/v1/teams/%s/posts" esa-team-name)
     'esa-created-callback
     `(("post" .
        (("name" . ,name)
         ("body_md" . ,(buffer-substring begin end))
         ("category" . ,category)
         ("message" . ,(if skip-notice "[skip notice]" ""))
         ("tags" . ,(vconcat (split-string tags)))
         ("wip" . ,(if wip 't :json-false))))))))

;;;###autoload
(defun esa-region-wip (begin end)
  "Post the current region as a new wip paste at yourteam.esa.io.
Copies the URL into the kill ring."
  (interactive "r")
  (esa-region begin end t nil))

;;;###autoload
(defun esa-buffer (&optional wip skip-notice)
  "Post the current buffer as a new paste at yourteam.esa.io.
Copies the URL into the kill ring.

With a prefix argument, makes a WIP and SKIP-NOTICE paste."
  (interactive "P")
  (esa-region (point-min) (point-max) wip skip-notice))

;;;###autoload
(defun esa-buffer-wip ()
  "Post the current buffer as a new wip paste at yourteam.esa.io.
Copies the URL into the kill ring."
  (interactive)
  (esa-region (point-min) (point-max) t nil))

;;;###autoload
(defun esa-region-or-buffer (&optional wip skip-notice)
  "Post either the current region, or if mark is not set.
The current buffer as a new paste at yourteam.esa.io.
Copies the URL into the kill ring.

With a prefix argument, makes a WIP and SKIP-NOTICE paste."
  (interactive "P")
  (if (esa-region-active-p)
      (esa-region (region-beginning) (region-end) wip)
    (esa-buffer wip skip-notice)))

;;;###autoload
(defun esa-region-or-buffer-wip ()
  "Post either the current region, or if mark is not set, the
current buffer as a new wip paste at yourteam.esa.io Copies
the URL into the kill ring."
  (interactive)
  (if (esa-region-active-p)
      (esa-region (region-beginning) (region-end) t)
    (esa-buffer t nil)))

(defun esa-region-active-p ()
  (if (functionp 'region-active-p)
      ;; trick for suppressing elint warning
      (funcall 'region-active-p)
    (and transient-mark-mode mark-active)))

(defun esa-created-callback (status url json)
  (let ((json (save-excursion
                (goto-char (point-min))
                (when (re-search-forward "^\r?$" nil t)
                  (esa--read-json (point) (point-max)))))
        (http-url))
    (cond
     ((json-alist-p json)
      (setq http-url (cdr (assq 'url json)))
      (message "Paste created: %s (\\( ⁰⊖⁰)/)" http-url)
      (when esa-view-esa
        (browse-url http-url)))
     (t
      (message (esa--err-propertize "failed (\\( ⁰⊖⁰)/)"))))
    (when http-url
      (kill-new http-url))
    (url-mark-buffer-as-dead (current-buffer))))

;; GET /v1/teams/%s/posts
(defvar esa-list-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "g") 'revert-buffer)
    (define-key map (kbd "o") 'push-button)
    (define-key map (kbd "/") 'esa-search)
    (define-key map (kbd "f") 'esa-search)
    (define-key map (kbd "q") 'esa-list-quit-window)
    (define-key map (kbd "D") 'esa-delete-command)
    (define-key map (kbd "k") 'previous-line)
    (define-key map (kbd "j") 'forward-line)
    (define-key map (kbd "p") 'esa-list-beginning-of-buffer)
    (define-key map (kbd "n") 'end-of-buffer)
    (define-key map (kbd "SPC") 'scroll-up)
    (define-key map (kbd "b") 'scroll-up)
    (define-key map (kbd "S-SPC") 'scroll-down)
    (define-key map (kbd "u") 'scroll-down)
    map))

(define-derived-mode esa-list-mode fundamental-mode "Esa"
  "Show your esa list"
  (setq buffer-read-only t)
  (setq truncate-lines t)
  (set (make-local-variable 'revert-buffer-function)
       'esa-list-revert-buffer)
  (use-local-map esa-list-mode-map))

;;;###autoload
(defun esa-search ()
  "Displays a list of search esa results in a new buffer."
  (interactive)
  (let* ((query (read-from-minibuffer "Query: ")))
    (message "Retrieving list of your esas...")
    (esa-list-draw-esas query)))

;;;###autoload
(defun esa-list ()
  "Displays a list of all of the current user's esas in a new buffer."
  (interactive)
  (message "Retrieving list of your esas...")
  (esa-list-draw-esas))

(defun esa-list-draw-esas (&optional q)
  (with-current-buffer (get-buffer-create "*esas*")
    (let ((inhibit-read-only t))
      (erase-buffer)
      (esa-list-mode)
      (esa-insert-list-header)))
  (esa-request
   "GET"
   (format "https://api.esa.io/v1/teams/%s/posts" esa-team-name)
   'esa-lists-retrieved-callback
   (if q
       `(("per_page" . ,esa-number-of-list-per-page) ("q" . ,q))
     `(("per_page" . ,esa-number-of-list-per-page)))))

(defun esa-list-revert-buffer (&rest ignore)
  ;; redraw esa list
  (esa-list))

(defun esa-list-quit-window (&optional kill-buffer)
  "Bury the *esas* buffer and delete its window.
With a prefix argument, kill the buffer instead."
  (interactive "P")
  (quit-window kill-buffer))

(defun esa-list-beginning-of-buffer ()
  "Move beginning of the *esas* buffer."
  (interactive)
  (progn
    (goto-char (point-min))
    (forward-line 1)))

(defun esa-lists-retrieved-callback (status url params)
  "Called when the list of esas has been retrieved.
Parses the result and displays the list."
  (goto-char (point-min))
  (when (re-search-forward "^\r?$" nil t)
    (let* ((json (append
                  (cdr (assq 'posts (esa--read-json (point) (point-max))))
                  nil)))
      (with-current-buffer (get-buffer-create "*esas*")
        (save-excursion
          (let ((inhibit-read-only t))
            (goto-char (point-max))
            (mapc 'esa-insert-esa-link json)))
        (set-window-buffer nil (current-buffer)))))
  (message "List succeeded (\\( ⁰⊖⁰)/)")
  (url-mark-buffer-as-dead (current-buffer)))

;; DELETE /v1/teams/%s/posts/%s
(defun esa-delete (number)
  (esa-request
   "DELETE"
   (format "https://api.esa.io/v1/teams/%s/posts/%s" esa-team-name number)
   (esa-simple-receiver "Delete")))

;; PATCH /v1/teams/%s/posts/%s
(defun esa-update (number name category tags body_md &optional wip skip-notice)
  (esa-request
   "PATCH"
   (format "https://api.esa.io/v1/teams/%s/posts/%s" esa-team-name number)
   (esa-simple-receiver "Update esa")
   `(,@(cond
        (body_md
         `(("post" .
            (("body_md" . ,body_md)
             ("wip" . ,(if wip 't :json-false))
             ("message" . ,(if skip-notice "[skip notice]" ""))))))
        (tags
         `(("post" .
            (("tags" . ,(vconcat (split-string tags)))
             ("message" . "[skip notice]")))))
        (category
         `(("post" .
            (("category" . ,category)
             ("message" . "[skip notice]")))))
        (name
         `(("post" .
            (("name" . ,name)
             ("message" . "[skip notice]")))))))))


;;; Components:

;; esa list (esas)
(defun esa-insert-list-header ()
  "Creates the header line in the esa list buffer."
  (save-excursion
    (insert "  No    Updated           Prog   Full Name"
            (esa-fill-string "" (- (frame-width) 2))
            ".\n"))
  (let ((ov (make-overlay (line-beginning-position) (line-end-position))))
    (overlay-put ov 'face 'header-line))
  (forward-line))

(defun esa-insert-esa-link (esa)
  "Inserts a button that will open the given esa when pressed."
  (let* ((data (esa-parse-esa esa))
         (number (cdr (assq 'number data))))
    (dolist (x (cdr data))
      (insert (format "  %s" x)))
    (make-text-button (line-beginning-position) (line-end-position)
                      'repo number
                      'action 'esa-describe-button
                      'face 'default
                      'esa-json esa))
  (insert "\n"))

(defun esa-parse-esa (esa)
  "Returns a list of the esa's attributes for display, given the xml list
for the esa."
  (let ((number (cdr (assq 'number esa)))
        (updated-at (cdr (assq 'updated_at esa)))
        (full_name (cdr (assq 'full_name esa)))
        (progress (if (eq (cdr (assq 'wip esa)) 't)
                      "WIP"
                    "Ship")))
    (list number
          (esa-fill-string (number-to-string number) 4)
          (esa-fill-string
           (format-time-string
            esa-display-date-format (esa-parse-time-string updated-at))
           16)
          (esa-fill-string progress 5)
          (or full_name ""))))

(defun esa-parse-time-string (string)
  (let* ((times (split-string string "[-+T:Z]" t))
         (getter (lambda (x) (string-to-number (nth x times))))
         (year (funcall getter 0))
         (month (funcall getter 1))
         (day (funcall getter 2))
         (hour (funcall getter 3))
         (min (funcall getter 4))
         (sec (funcall getter 5))
         (utc-hour (- hour (funcall getter 6)))
         (utc-min (- min (funcall getter 7))))
    (encode-time sec utc-min utc-hour day month year 0)))

(defun esa-fill-string (string width)
  (truncate-string-to-width string width nil ?\s "..."))

;; esa describe (esa)
(defvar esa-describe-read-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "q") 'kill-this-buffer)
    (define-key map (kbd "o") 'kill-this-buffer)
    (define-key map (kbd "RET") 'esa-describe-write-mode)
    (define-key map (kbd "k") 'previous-line)
    (define-key map (kbd "j") 'forward-line)
    (define-key map (kbd "p") 'esa-describe-beginning-of-buffer)
    (define-key map (kbd "n") 'end-of-buffer)
    (define-key map (kbd "SPC") 'scroll-up)
    (define-key map (kbd "b") 'scroll-up)
    (define-key map (kbd "S-SPC") 'scroll-down)
    (define-key map (kbd "u") 'scroll-down)
    map))

(define-derived-mode esa-describe-read-mode fundamental-mode "Esa Describe"
  "Show your esa describe."
  (setq buffer-read-only nil)
  (erase-buffer)
  (esa-describe-esa-1 json)
  (setq buffer-read-only t)
  (goto-char (point-min)) (re-search-forward "^-\r?\n\n" nil t)
  (setq truncate-lines t)
  (use-local-map esa-describe-read-mode-map))

(defvar esa-describe-write-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-k") 'kill-this-buffer)
    (define-key map (kbd "C-c C-c") 'esa-update-body-md-wip-command)
    (define-key map (kbd "C-c C-p") 'esa-update-body-md-skip-notice-command)
    map))

(define-derived-mode esa-describe-write-mode fundamental-mode "Esa Describe"
  "Edit your esa describe body."
  (setq buffer-read-only nil)
  (esa-describe-read-only-header)
  (use-local-map esa-describe-write-mode-map)
  (message "Type C-c C-c to wip post, C-c C-p to post, or C-c C-k to cancel (\\( ⁰⊖⁰)/)"))

(defun esa-describe-button (button)
  (let ((json (button-get button 'esa-json)))
    (with-current-buffer (get-buffer-create "*esa*")
      (esa-describe-read-mode)
      (switch-to-buffer "*esa*"))))

(defun esa-describe-read-only-header ()
  (put-text-property (point-min)
                     (progn
                       (goto-char (point-min))
                       (re-search-forward "^-\r?\n\n" nil t)
                       (- (point) 1))
                     'read-only t))

(defun esa-describe-insert-button (text action json)
  (let ((button-text text)
        (button-face (if (display-graphic-p)
                         '(:box (:line-width 2 :color "dark grey")
                                :background "light grey"
                                :foreground "black")
                       'link))
        (number (cdr (assq 'number json))))
    (insert-text-button button-text
                        'face 'default
                        'follow-link t
                        'action action
                        'repo number
                        'esa-json json)))

(defun esa-describe-beginning-of-buffer ()
  "Move beginning of the *esas* buffer."
  (interactive)
  (progn
    (goto-char (point-min))
    (re-search-forward "^-\r?\n\n" nil t)))

(defun esa-describe-esa-1 (esa)
  (let ((name (cdr (assq 'name esa)))
        (category (cdr (assq 'category esa)))
        (tags
         (mapconcat 'identity
                    (delete "" (split-string
                                (format "%s" (cdr (assq 'tags esa)))
                                "[\]\[,\(\) ]"))
                    " "))
        (progress (eq (cdr (assq 'wip esa)) :json-false))
        (updated (cdr (assq 'updated_at esa)))
        (url (cdr (assq 'url esa)))
        (number (cdr (assq 'number esa)))
        (body_md (replace-regexp-in-string "\r\n" "\n" (cdr (assq 'body_md esa)))))
    (insert (propertize "  Number: " 'font-lock-face 'bold)) (insert (number-to-string number) "\n")
    (insert (propertize "    Name: " 'font-lock-face 'bold)) (esa-describe-insert-button (or name "---") 'esa-update-name-button esa) (insert "\n")
    (insert (propertize "Category: " 'font-lock-face 'bold)) (esa-describe-insert-button (or category "---") 'esa-update-category-button esa) (insert "\n")
    (insert (propertize "    Tags: " 'font-lock-face 'bold)) (esa-describe-insert-button (if (string= tags "") "---" tags) 'esa-update-tags-button esa) (insert "\n")
    (insert (propertize "Progress: " 'font-lock-face 'bold))
    (insert (if progress
                (propertize "Ship" 'font-lock-face `(bold ,font-lock-warning-face))
              (propertize "WIP" 'font-lock-face '(bold)))
            "\n")
    (insert (propertize " Updated: " 'font-lock-face 'bold))
    (insert (format-time-string esa-display-date-format (esa-parse-time-string updated)) "\n")
    (insert (propertize "     URL: " 'font-lock-face 'bold)) (esa-describe-insert-button url 'esa-open-web-button esa) (insert "\n")
    (insert (propertize "-" 'font-lock-face 'bold) "\n\n")
    (insert (or body_md ""))))

;; commands
(defun esa-update-body-md-command (&optional number body_md)
  "Edit the esa by NUMBER and BODY_MD."
  (interactive "P")
  (let* ((number (save-excursion
                   (goto-char (point-min))
                   (when (re-search-forward "Number: " nil t)
                     (buffer-substring (point) (progn (forward-word) (point))))))
         (body_md (save-excursion
                    (goto-char (point-min))
                    (when (re-search-forward "^-\r?\n\n" nil t)
                      (buffer-substring (point) (point-max))))))
    (esa-update number nil nil nil body_md)))

(defun esa-update-body-md-skip-notice-command (&optional number body_md)
  "Edit the esa with [skip notice] by NUMBER and BODY_MD."
  (interactive "P")
  (let* ((number (save-excursion
                   (goto-char (point-min))
                   (when (re-search-forward "Number: " nil t)
                     (buffer-substring (point) (progn (forward-word) (point))))))
         (body_md (save-excursion
                    (goto-char (point-min))
                    (when (re-search-forward "^-\r?\n\n" nil t)
                      (buffer-substring (point) (point-max))))))
    (esa-update number nil nil nil body_md nil "[skip notice]")))

(defun esa-update-body-md-wip-command (&optional number body_md)
  "Edit the esa by NUMBER and BODY_MD."
  (interactive "P")
  (let* ((number (save-excursion
                   (goto-char (point-min))
                   (when (re-search-forward "Number: " nil t)
                     (buffer-substring (point) (progn (forward-word) (point))))))
         (body_md (save-excursion
                    (goto-char (point-min))
                    (when (re-search-forward "^-\r?\n\n" nil t)
                      (buffer-substring (point) (point-max))))))
    (esa-update number nil nil nil body_md t)))

(defun esa-delete-command (&optional number)
  "Confirm and delete the esa by NUMBER."
  (interactive "P")
  (when (y-or-n-p "Really delete this esa? ")
    (let* ((number (save-excursion
                     (move-beginning-of-line 1)
                     (forward-char 2)
                     (buffer-substring (point) (progn (forward-word) (point))))))
      (esa-delete number))))

;; buttons
(defun esa-update-name-button (button)
  "Called when a esa [Edit] button has been pressed.
Edit the esa name."
  (let* ((json (button-get button 'esa-json))
         (name (read-from-minibuffer
                "Name: "
                (cdr (assq 'name json)))))
    (esa-update (button-get button 'repo) name nil nil nil)))

(defun esa-update-category-button (button)
  "Called when a esa [Edit] button has been pressed.
Edit the esa category."
  (let* ((json (button-get button 'esa-json))
         (category (read-from-minibuffer
                    "Category: "
                    (cdr (assq 'category json)))))
    (esa-update (button-get button 'repo) nil category nil nil)))

(defun esa-update-tags-button (button)
  "Called when a esa [Edit] button has been pressed.
Edit the esa tags."
  (let* ((json (button-get button 'esa-json))
         (tags (read-from-minibuffer
                "Tgas: "
                (mapconcat 'identity
                           (delete "" (split-string
                                       (format "%s" (cdr (assq 'tags json)))
                                       "[\]\[,\(\) ]"))
                           " "))))
    (esa-update (button-get button 'repo) nil nil tags nil)))

(defun esa-open-web-button (button)
  "Called when a esa [Browse] button has been pressed."
  (let* ((json (button-get button 'esa-json))
         (url (cdr (assq 'url json))))
    (browse-url url)))


;;; Utilities:

;; rest client
(defun esa--read-json (start end)
  (let* ((str (buffer-substring start end))
         (decoded (decode-coding-string str 'utf-8)))
    (json-read-from-string decoded)))

(defun esa-request-0 (auth method url callback &optional json-or-params)
  (let* ((json (and (member method '("POST" "PATCH")) json-or-params))
         (params (and (member method '("GET" "DELETE")) json-or-params))
         (url-request-data (and json (concat (encode-coding-string (json-encode json) 'utf-8) "\n")))
         (url-request-extra-headers
          `(("Authorization" . ,auth)
            ("Content-Type" . "application/json;charset=UTF-8")))
         (url-request-method method)
         (url-max-redirection -1)
         (url (if params
                  (concat url "?" (esa-make-query-string params))
                url)))
    (url-retrieve url callback (list url json-or-params))))

(defun esa-request (method url callback &optional json-or-params)
  (let ((token (esa-check-oauth-token)))
    (esa-request-0
     (format "Bearer %s" token)
     method url callback json-or-params)))

(defun esa-check-oauth-token ()
  (cond
   (esa-token)
   (t
    (browse-url (format "https://%s.esa.io/user/tokens" esa-team-name))
    (error "You need to get OAuth Access Token by your browser"))))

(defun esa-make-query-string (params)
  "Returns a query string constructed from PARAMS, which should be
a list with elements of the form (KEY . VALUE). KEY and VALUE
should both be strings."
  (let ((hexify
         (lambda (x)
           (url-hexify-string
            (with-output-to-string (princ x))))))
    (mapconcat
     (lambda (param)
       (concat (funcall hexify (car param))
               "="
               (funcall hexify (cdr param))))
     params "&")))

;; callback
(defun esa-simple-receiver (message)
  ;; Create a receiver of `esa-request-0'
  `(lambda (status url json-or-params)
     (goto-char (point-min))
     (when (re-search-forward "^HTTP/1.1 \\([0-9]+\\)" nil t)
       (let ((code (string-to-number (match-string 1))))
         (if (and (<= 200 code) (< code 300))
             (progn (cond ((get-buffer "*esa*") (kill-buffer "*esa*")))
                    (esa-list-revert-buffer)
                    (message "%s succeeded (\\( ⁰⊖⁰)/)" ,message))
           (message "%s %s"
                    code
                    (esa--err-propertize "failed (\\( ⁰⊖⁰)/)")))))
     (url-mark-buffer-as-dead (current-buffer))))

;; exception handling
(defun esa--err-propertize (string)
  (propertize string 'face 'font-lock-warning-face))



(provide 'esa)
;;; esa.el ends here
