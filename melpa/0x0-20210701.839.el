;;; 0x0.el --- Upload sharing to 0x0.st -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2021 William Vaughn
;;
;; Author: William Vaughn <https://gitlab.com/willvaughn>
;; Maintainer: William Vaughn <vaughnwilld@gmail.com>
;; Created: June 26, 2021
;; Modified: June 26, 2021
;; Version: 1.0.0
;; Package-Version: 20210701.839
;; Package-Commit: 63cd5eccc85e527f28e1acc89502a53245000428
;; Homepage: https://gitlab.com/willvaughn/emacs-0x0
;; Package-Requires: ((emacs "26.1"))
;;
;; This program is free software: you can redistribute it and/or modify
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
;;
;;; Commentary:
;;
;; Integration with https://0x0.st, envs.sh, ttm.sh, and self-hosted services
;;
;; Upload whatever you need to a pastebin server. The commands
;; `0x0-upload-file',`0x0-upload-text' and `0x0-upload-kill-ring', which
;; respectively upload (parts of) the current buffer, a file on your disk and a
;; string from the minibuffer can be used too.
;;
;; The default host and the host this package is named after is https://0x0.st.
;; Consider donating to https://liberapay.com/mia/donate if you like the service.

(require 'url)

;;; Code:
(defgroup 0x0 nil
  "Share files, links, pastes, and images with others."
  :group 'convenience
  :tag "0x0"
  :prefix "0x0-")

(defcustom 0x0-servers
  `((0x0
     :scheme "https"
     :host "0x0.st"
     :default-dir "~/Desktop"
     :curl-args-fun 0x0--make-0x0-curl-args
     :min-age 30
     :max-age 365
     :max-size ,(* 1024 1024 512))
    (ttm
     :scheme "https"
     :host "ttm.sh"
     :default-dir "~/Desktop"
     :curl-args-fun 0x0--make-0x0-curl-args
     :min-age 30
     :max-age 365
     :max-size ,(* 1024 1024 256))
    (envs
     :scheme "https"
     :host "envs.sh"
     :default-dir "~/Desktop"
     :curl-args-fun 0x0--make-0x0-curl-args
     :min-age 30
     :max-age 365
     :max-size ,(* 1024 1024 512)))
  "Configurations for the target servers.

Override these values to associate your own target servers."
  :type '(alist :key-type symbol
                :value-type (plist :value-type sexp)))

(defcustom 0x0-default-server '0x0
  "Symbol describing server to use.

The symbol must be a key from the alist `0x0-servers'."
  :type `(choice ,@(mapcar (lambda (srv)
                             `(const :tag ,(plist-get (cdr srv) :host) ,(car srv)))
                           0x0-servers)))

(defcustom 0x0-use-curl 'if-installed
  "Policy how how to use curl.
Can be a symbol (t, nil, if-installed) to respectivly use curl
unconditionally, never or only if found.
Alternativly the value might be a string describing a path to the
curl binary."
  :type '(choice (const :tag "Unconditionally" t)
                 (const :tag "If Installed" if-installed)
                 (const :tag "Never" nil)
                 (string :tag "Path to curl")))

(defun 0x0--choose-server ()
  "Prompt user for service to use."
  (let ((server-key (if current-prefix-arg
                        (intern (completing-read "Server: "
                                                 (mapcar #'car 0x0-servers)
                                                 nil t nil nil
                                                 0x0-default-server))
                      0x0-default-server)))
    (cdr (assq server-key 0x0-servers))))

(defun 0x0--calculate-timeout (server size)
  "Calculate days a file of size SIZE would last on SERVER."
  (condition-case nil
      (let ((min-age (float (plist-get server :min-age)))
            (max-age (float (plist-get server :max-age)))
            (max-size (float (plist-get server :max-size))))
        (+ min-age (* (- min-age max-age)
                      (expt (- (/ size max-size) 1.0) 3))))
    (wrong-type-argument nil)))

(defun 0x0--get-server-default-dir (server)
  "Access the :default-dir property of the SERVER Property list."
  (plist-get server :default-dir))

(defun 0x0--get-server-curl-args-fun (server)
  "Access the value of :curl-args-fun on the SERVER."
  (plist-get server :curl-args-fun))

(defun 0x0--pick-file (server)
  "Prompt to pick a file path or use dired file at point.

This function creates a prompt for interactive functions below.
The SERVER is used to look up the default directory to use for where to find
uploadable files."
  (cond ((derived-mode-p 'dired-mode) (dired-file-name-at-point))
        (t (read-file-name "Pick a file to share: " (0x0--get-server-default-dir server)))))

(defun 0x0--make-server-host-uri (server &optional basic-auth-creds)
  "Make a SERVER host URI using configuration properties.

BASIC-AUTH-CREDS plist optionally contains :user and :pass."
  (if basic-auth-creds
      (format "%s://%s:%s@%s"
              (plist-get server :scheme)
              (plist-get basic-auth-creds :user)
              (plist-get basic-auth-creds :pass)
              (plist-get server :host))
    (format "%s://%s" (plist-get server :scheme) (plist-get server :host))))

(defun 0x0--make-0x0-curl-args (server file-name &optional bounded)
  "Create 0x0 curl arguments from SERVER configs and FILE-NAME.

BOUNDED indicates a partial upload and that changes querystring parameters."
  (let ((q-string (if bounded
                      "file=@-;filename=%s"
                    "file=@%s")))
    (list "-s" "-S" "-F" (format q-string file-name) (0x0--make-server-host-uri server))))

(defun 0x0--make-curl-args (server file-name &optional bounded)
  "Call SERVER :curl-args-fun with FILE-NAME and BOUNDED arguments."
  (let ((curl-args-fun (0x0--get-server-curl-args-fun server)))
    (funcall curl-args-fun server file-name bounded)))

(defun 0x0--make-bounds (&optional start end)
  "Make Bounds property list from START and END points.

Defaults START to =point-min= and END to =point-min=."
  (let ((start (or start (point-min)))
        (end (or end (point-max))))
    (list :start start :end end)))

(defun 0x0--bounds-size (bounds)
  "Get end - start size of BOUNDS."
  (- (plist-get bounds :end) (plist-get bounds :start)))

(defun 0x0--curl (curl-args &optional bounds)
  "Wrapper around curl background process call.

CURL-ARGS are forwarded to the curl command. If BOUNDS are supplied the curl
process call will be called using =call-process-region= on the portion of the
buffer between start and end."
  (let ((buf (generate-new-buffer "*0x0 response*"))
        (curl-cmd (if (stringp 0x0-use-curl) 0x0-use-curl "curl")))
    (if bounds
        (apply #'call-process-region (plist-get bounds :start) (plist-get bounds :end) curl-cmd nil buf nil curl-args)
      (apply #'call-process curl-cmd nil buf nil curl-args))
    buf))

(defun 0x0--make-url-props (server file-name &optional bounded)
  "Create 0x0 url arguments from SERVER configs and FILE-NAME.

BOUNDED indicates a partial upload and changes querystring parameters."
  (let ((query-str (format "name=\"file\"; filename=\"%s\"" (file-name-nondirectory file-name)))
        (host-uri (0x0--make-server-host-uri server))
        (file-path (unless bounded file-name)))
    (list :file-path file-path :query-str query-str :host-uri host-uri)))

(defun 0x0--url (url-props &optional bounds)
  "Uploading using `url' functions according to URL-PROPS infrormation.

Operate on region between BOUNDS."
  (let* ((boundary (format "%X-%X-%X" (random) (random) (random)))
         (file-path (plist-get url-props :file-path))
         (query-str (plist-get url-props :query-str))
         (host-uri (plist-get url-props :host-uri))
         (url-request-extra-headers
          `(("Content-Type" . ,(concat "multipart/form-data; boundary=" boundary))))
         (url-request-data
          (let ((source (if file-path
                            (with-temp-buffer
                              (insert-file-contents file-path)
                              (buffer-substring-no-properties (point-min) (point-max)))
                          (buffer-substring-no-properties (plist-get bounds :start) (plist-get bounds :end)))))
            (with-temp-buffer
              (insert "--" boundary "\r\n")
              (insert "Content-Disposition: form-data; ")
              (insert query-str "\r\n")
              (insert "Content-type: text/plain\r\n\r\n")
              (insert source)
              (insert "\r\n--" boundary "--")
              (buffer-string))))
         (url-request-method "POST"))
    (with-current-buffer (url-retrieve-synchronously host-uri)
      (rename-buffer "*0x0 response*" t)
      (goto-char (point-min))
      (save-match-data
        (when (search-forward-regexp "^[[:space:]]*$" nil t)
          (delete-region (point-min) (match-end 0))))
      (current-buffer))))

(defun 0x0--send (server file-name &optional bounds)
  "Send data to SERVER from file with FILE-NAME.

Optionally, uses BOUNDS when sending a partial file as text."
  (if (cond ((eq 0x0-use-curl t))
            ((eq 0x0-use-curl 'if-installed) (executable-find "curl"))
            ((stringp 0x0-use-curl)))
      (0x0--curl (0x0--make-curl-args server file-name bounds) bounds)
    (0x0--url (0x0--make-url-props server file-name bounds) bounds)))

(defun 0x0--handle-resp (server size resp)
  "Yank successful SERVER share URI into \"kill-ring\" from response RESP.

The SIZE influences the estimate of file timeout."
  (with-current-buffer resp
    (goto-char (point-min))
    (save-match-data
      (unless (search-forward-regexp (concat "^" (0x0--make-server-host-uri server) ".+") nil t)
        (error "Failed to upload/parse. see %s for more details"
               (buffer-name (current-buffer))))
      (kill-new (match-string 0))
      (let ((timeout (and size (0x0--calculate-timeout server size))))
        (message (concat "yanked `%s' into kill ring."
                         (and timeout " Should last ~%g days."))
                 (match-string 0) timeout))
      (prog1 (match-string 0)
        (kill-buffer (current-buffer))))))

;;;###autoload
(defun 0x0-upload-file (server file)
  "Choose FILE and upload it to SERVER."
  (interactive (let ((srv (0x0--choose-server)))
                 (list srv
                       (0x0--pick-file srv))))
  (let* ((file-name (expand-file-name file))
         (size (file-attribute-size (file-attributes file)))
         (resp (0x0--send server file-name)))
    (0x0--handle-resp server size resp)))

;;;###autoload
(defun 0x0-upload-text (server)
  "Upload full or region text from the current buffer to SERVER."
  (interactive (list (0x0--choose-server)))
  ;; TODO file name looking like a function
  (let* ((file-name "upload.txt")
         (bounds (if (use-region-p)
                     (0x0--make-bounds (region-beginning) (region-end))
                   (0x0--make-bounds)))
         (size (0x0--bounds-size bounds))
         (resp (0x0--send server file-name bounds)))
    (0x0--handle-resp server size resp)))

;;;###autoload
(defun 0x0-upload-kill-ring (server)
  "Upload content from the \"kill-ring\" to SERVER."
  (interactive (list (0x0--choose-server)))
  (with-temp-buffer
    (insert (current-kill 0))
    (let* ((file-name (or (buffer-file-name) (buffer-name) "kill-ring.txt"))
           (bounds (0x0--make-bounds))
           (size (0x0--bounds-size bounds))
           (resp (0x0--send server file-name bounds)))
      (0x0--handle-resp server size resp))))

;;;###autoload
(defun 0x0-shorten-uri (server uri)
  "Shorten the given URI with SERVER."
  (interactive (list (0x0--choose-server)
                     (read-string "URI: ")))
  (unless (cond ((eq 0x0-use-curl t))
                ((eq 0x0-use-curl 'if-installed) (executable-find "curl"))
                ((stringp 0x0-use-curl)))
    (error "Unsupported currenlty without using curl"))
  (let* ((host-uri (0x0--make-server-host-uri server))
         (curl-args (list "-s" "-S" "-F" (format "shorten=%s" uri) host-uri))
         (resp (0x0--curl curl-args)))
    (0x0--handle-resp server nil resp)))

(defun 0x0-popup-upload (server)
  "Upload to SERVER and kill current buffer."
  (interactive (list (0x0--choose-server)))
  (let* ((file-name "popup-upload.txt")
         (bounds (0x0--make-bounds))
         (size (0x0--bounds-size bounds))
         (resp (0x0--send server file-name bounds)))
    (0x0--handle-resp server size resp))
  (kill-buffer (current-buffer)))

;;;###autoload
(defun 0x0-popup (server)
  "Create a new buffer, fill it with content, and upload it to SERVER later."
  (interactive (list (0x0--choose-server)))
  (with-current-buffer (generate-new-buffer "*upload*")
    (local-set-key (kbd "C-c C-c") (lambda ()
                                     (interactive)
                                     (let ((current-prefix-arg current-prefix-arg))
                                       (0x0-popup-upload server))))
    (pop-to-buffer (current-buffer)))
  (message "Press C-c C-c to upload."))

;;;###autoload
(defun 0x0-dwim (server)
  "Try to guess what to upload to SERVER."
  (interactive (list (0x0--choose-server)))
  (cond ((region-active-p)
         (0x0-upload-text server))
        ((memq last-command '(kill-ring-save
                              kill-region
                              append-next-kill))
         (0x0-upload-kill-ring server))
        ((derived-mode-p 'dired-mode)
         (0x0-upload-file server (dired-file-name-at-point)))
        ((ffap-guess-file-name-at-point) (if-let* ((file (ffap-guess-file-name-at-point)))
                                             (when (yes-or-no-p (format "Is publicly sharing this file what you intended? %s" file))
                                               (0x0-upload-file server file))))
        ((0x0-upload-text server))))

(provide '0x0)
;;; 0x0.el ends here
