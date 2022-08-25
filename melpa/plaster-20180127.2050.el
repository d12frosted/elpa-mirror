;;; plaster.el --- Pasting to a plaster host with buffers. -*- lexical-binding: t; -*-

;; Copyright (c) 2017 Nicolas Hafner
;;
;; Author: Nicolas Hafner <shinmera@tymoon.eu>
;; URL: http://github.com/shirakumo/plaster/
;; Package-Version: 20180127.2050
;; Package-Commit: 11eb23920410818fe444887b97ad4c8722d66c85
;; Package-Requires: ((emacs "24.3"))
;; Version: 1.0
;; Keywords: convenience, paste service

;; This file is not part of GNU Emacs.

;;; License:
;; Licensed under the Artistic License 2.0

;;; Commentary:
;;
;; This package allows you to interact with a
;; plaster paste service directly from within
;; Emacs.
;;
;; By default this package uses the service at
;;   https://plaster.tymoon.eu
;; However, you can also configure your own setup
;; if you so desire. The Plaster server app can
;; be obtained at
;;   https://github.com/Shirakumo/plaster
;;
;; The following commands are available:
;;
;; - plaster-login
;;     If you have a plaster account, use this
;;     to log yourself in.
;; - plaster-visit
;;     Opens an existing paste in a buffer
;; - plaster-paste-buffer
;;     Pastes the current buffer to a new paste
;; - plaster-paste-region
;;     Pastes the current region to a new paste
;; - plaster-new
;;     Opens a new buffer for a new paste
;; - plaster-annotate                    (C-x C-a)
;;     Create an annotation for the current paste
;; - plaster-save                        (C-x C-s)
;;     Save the current buffer as a paste
;; - plaster-delete                      (C-x C-k)
;;     Delete the current buffer's paste
;;
;; The keybindings mentioned are only active in
;; plaster-mode buffers.

;;; Code:

(defgroup plaster nil
  "Pasting to a plaster host with Emacs buffers."
  :group 'extensions
  :group 'convenience
  :link '(emacs-library-link :tag "Lisp File" "plaster.el"))

(defcustom plaster-root "https://plaster.tymoon.eu/"
  "The root URL part for all plaster requests."
  :type 'string
  :group 'plaster)

(defcustom plaster-session-token ""
  "The cookie used to identify the plaster session."
  :type 'string
  :group 'plaster)

(defcustom plaster-type-mode-map '(("c++src" . c++-mode)
                                   ("c++hdr" . c++-mode)
                                   ("ecmascript" . js-mode)
                                   ("html" . web-mode)
                                   ("mssql" . sql-mode)
                                   ("mysql" . sql-mode)
                                   ("pgsql" . sql-mode)
                                   ("plsql" . sql-mode)
                                   ("rustsrc" . rust-mode)
                                   ("xml" . nxml-mode)
                                   ("xml-dtd" . nxml-mode))
  "A map of plaster paste types to Emacs modes."
  :type '(alist :key-type string :value-type symbol))

(defvar plaster-mode-map (make-sparse-keymap)
  "Keymap for function ‘plaster-mode’.")

(defvar plaster-types '("text" "apl" "aspx" "asterisk" "brainfuck" "c" "c++hdr"
                        "c++src" "cassandra" "ceylon" "clojure" "clojurescript"
                        "cmake" "cobol" "coffeescript" "common-lisp" "crystal"
                        "csharp" "css" "cypher-query" "cython" "d" "dart"
                        "diff" "django" "dockerfile" "dylan" "ebnf" "ecl"
                        "ecmascript" "edn" "eiffel" "ejs" "elm" "erb" "erlang"
                        "ez80" "factor" "fcl" "feature" "forth" "fortran"
                        "fragment" "gfm" "go" "gql" "groovy" "gss" "haml"
                        "handlebars-template" "haskell" "haxe" "hive" "html"
                        "http" "httpd-php" "httpd-php-open" "hxml" "ini" "java"
                        "javascript" "json" "jsp" "jsx" "julia" "kotlin"
                        "latex" "less" "literate-haskell" "lua" "mariadb"
                        "markdown" "mbox" "mirc" "mscgen" "msgenny" "mssql"
                        "mumps" "mysql" "n-triples" "nesc" "nginx-conf" "nsis"
                        "objectivec" "octave" "oz" "pascal" "perl" "pgp"
                        "pgp-keys" "pgp-signature" "pgsql" "php" "pig" "plsql"
                        "properties" "protobuf" "puppet" "python" "q"
                        "rpm-changes" "rpm-spec" "rsrc" "ruby" "rustsrc" "sas"
                        "sass" "scala" "scheme" "scss" "sieve" "slim" "smarty"
                        "solr" "soy" "sparql-query" "spreadsheet" "sql"
                        "squirrel" "stex" "styl" "swift" "systemverilog" "tcl"
                        "textile" "tiddlywiki" "tiki" "tlv" "tornado"
                        "ttcn-asn" "ttcn-cfg" "turtle" "twig" "typescript"
                        "typescript-jsx" "vb" "vbscript" "velocity" "verilog"
                        "vertex" "vhdl" "vue" "webidl" "xml" "xml-dtd"
                        "xquery" "xu" "yaml" "z80")
  "List of all available paste types in plaster.")

(defvar-local plaster-id nil
  "The paste ID associated with this buffer.")

(defvar-local plaster-parent nil
  "The parent paste ID associated with this buffer.")

(require 'url)
(require 'json)

(defun plaster-read-type (&optional default)
  (let ((completion-ignore-case t))
    (completing-read "Paste type:" plaster-types nil t nil nil (or default "text"))))

(defun plaster-find-session-token (cookies)
  "Find the radiance-session token in the cookie jar.

Argument COOKIES The cookie jar as used in ‘url-cookie-list’."
  (let* ((domain (url-host (url-generic-parse-url plaster-root)))
         (cookies (dolist (cookie cookies)
                    (when (or (cl-search (car cookie) domain)
                              (cl-search domain (car cookie)))
                      (return (cdr cookie))))))
    (dolist (cookie cookies)
      (when (equal (aref cookie 1) "radiance-session")
        (return (aref cookie 2))))))

(defun plaster-make-cookie (var val &optional time path domain)
  "Create a new cookie value in the expected format for URL.

Argument VAR The name of the cookie variable.
Argument VAL The name of the cookie value.
Optional argument TIME The cookie's expiry date string.
Optional argument PATH The cookie's path.
Optional argument DOMAIN The cookie's active domain."
  (let ((time (or time (format-time-string "%a, %d %b %Y %H:%M:%S %z" (+ (float-time) 3600))))
        (path (or path "/"))
        (domain (or domain (url-host (url-generic-parse-url plaster-root)))))
    `[url-cookie ,var ,val ,time ,path ,domain nil]))

(defun plaster-api (endpoint)
  "Construct the URL to the given plaster API ENDPOINT."
  (concat plaster-root "api/plaster/" endpoint))

(defun plaster-paste-url (id)
  "Construct the URL to view the paste with the given ID."
  (concat plaster-root "view/" id))

(defun plaster-type-mode (type)
  "Return the name of a suitable mode for the given paste TYPE if any."
  (let ((explicit-mode (alist-get type plaster-type-mode-map))
        (implicit-mode (intern-soft (concat type "-mode"))))
    (or (and explicit-mode (fboundp explicit-mode) explicit-mode)
        (and implicit-mode (fboundp implicit-mode) implicit-mode))))

(defun plaster-mode-type (mode)
  "Return the name of a suitable type for the given Emacs MODE if any."
  (let ((explicit-type (car (rassoc mode plaster-type-mode-map)))
        (implicit-type (substring (symbol-name mode) 0 (cl-search "-mode" (symbol-name mode) :from-end t))))
    (or (and explicit-type (member explicit-type plaster-types) explicit-type)
        (and implicit-type (member implicit-type plaster-types) implicit-type))))

(defun plaster-request (endpoint params)
  "Perform a request against the Radiance API.

Argument ENDPOINT The URL of the endpoint to request against.
Argument PARAMS An alist of request parameters."
  (let ((url-request-method "POST")
        (url-cookie-storage
          (when plaster-session-token
            `((,(url-host (url-generic-parse-url plaster-root))
               ,(plaster-make-cookie "radiance-session" plaster-session-token)))))
        (url-request-extra-headers
          '(("Content-Type" . "application/x-www-form-urlencoded")))
        (url-request-data
          (mapconcat (lambda (arg)
                       (concat (url-hexify-string (car arg))
                               "="
                               (url-hexify-string (format "%s" (cdr arg)))))
                     params
                     "&")))
    (let ((response (with-current-buffer (url-retrieve-synchronously endpoint)
                      (goto-char (point-min))
                      (re-search-forward "^$")
                      (delete-region (point) (point-min))
                      (json-read-from-string (buffer-string)))))
      (unless (= 200 (alist-get 'status response))
        (error "Plaster request failed: %s" (alist-get 'message response)))
      (setq plaster-session-token (plaster-find-session-token url-cookie-storage))
      (alist-get 'data response))))

;;;###autoload
(defun plaster-login (&optional username password)
  "Log in to the remote plaster server.

On successful log in this will update the
‘plaster-session-token’ to a token that should be
associated with the given account.

Optional argument USERNAME The username of the account.
Optional argument PASSWORD The password to the account."
  (interactive)
  (let* ((username (or username (read-string "Username: ")))
         (password (or password (read-string "Password: "))))
    (setq plaster-session-token nil)
    (condition-case-unless-debug
     error
     (message "%s" (plaster-request (concat plaster-root "api/simple-auth/login")
                                    `(("username" . ,username)
                                      ("password" . ,password))))
     (error
      (message "%s" (error-message-string error))))))

;;;###autoload
(defun plaster-visit (&optional id)
  "Visit an existing paste in a new buffer.

If no ID is given, it will query you for one in the
minibuffer.  If the remote paste exists and is accessible
to you, the paste's contents will be opened in a new
buffer in function ‘plaster-mode’."
  (interactive)
  (let ((id (or id (read-string "Paste ID: "))))
    (when (equal id "") (return))
    (let* ((data (plaster-request (plaster-api "view")
                                  `(("id" . ,id))))
           (mode (plaster-type-mode (alist-get 'type data))))
      (with-current-buffer (generate-new-buffer (alist-get 'title data))
        (setq plaster-id (format "%s" (alist-get '_id data)))
        (insert (alist-get 'text data))
        (goto-char (point-min))
        (replace-string "\n" "\n")
        (when mode
          (funcall mode))
        (plaster-mode)
        (switch-to-buffer (current-buffer))
        (message "Now viewing paste from %s" (plaster-paste-url id))))))

(defun plaster-update (id &optional text)
  "Update the specified ID with the given TEXT.

By default the current buffer string is used.

Argument ID The ID of the paste to update."
  (let ((text (or text (buffer-string))))
    (plaster-request (plaster-api "edit")
                     `(("id" . ,id)
                       ("text" . ,text))))
  (message "Paste updated."))

;;;###autoload
(defun plaster-paste-buffer (&optional type title)
  "Paste the current buffer to a new remote paste.

This creates a fresh paste on the remote Plaster server.
On successful save, the new paste's URL is displayed in
the minibuffer and copied to the ‘kill-ring’ for you.

Optional argument TYPE The paste type to use.
Optional argument TITLE The title for the paste."
  (interactive)
  (let* ((type (or type
                   (plaster-mode-type major-mode)
                   (plaster-read-type)))
         (title (or title
                    (read-string "Paste title: " (buffer-name))))
         (data (plaster-request (plaster-api "new")
                                `(("text" . ,(buffer-string))
                                  ("title" . ,title)
                                  ("type" . ,type)
                                  ("parent" . ,(or plaster-parent ""))))))
    (unless plaster-mode (plaster-mode))
    (setq plaster-id (format "%s" (alist-get '_id data)))
    (let ((url (plaster-paste-url plaster-id)))
      (kill-new url)
      (message "Paste now available at: %s" url))))

;;;###autoload
(defun plaster-paste-region (&optional type title)
  "Paste the currently active region to a new remote paste.

This creates a fresh paste on the remote Plaster server.
On successful save, the new paste's URL is displayed in
the minibuffer and copied to the ‘kill-ring’ for you.

Optional argument TYPE The paste type to use.
Optional argument TITLE The title for the paste."
  (interactive)
  (let* ((mode major-mode)
         (type (or type
                   (plaster-mode-type major-mode)
                   (plaster-read-type)))
         (title (or title
                    (read-string "Paste title: " (buffer-name))))
         (text (buffer-substring (mark) (point))))
    (with-current-buffer (generate-new-buffer title)
      (insert text)
      (funcall mode)
      (switch-to-buffer (current-buffer))
      (plaster-paste-buffer type title))))

(defun plaster-save-paste (&optional id)
  "Save the current paste.

If the current buffer does not represent a paste, a new
paste is created for it.

Optional argument ID The ID for the paste to save to.  If nil, a new paste is created."
  (interactive)
  (let ((id (or id plaster-id)))
    (if id
        (plaster-update id)
        (plaster-paste-buffer))))

(defun plaster-save ()
  "Save the current paste.

If the current buffer represents a file, then the usual
‘save-buffer’ is performed as well.  If the current buffer
does not represent a paste, a new paste is created for it."
  (interactive)
  (when buffer-file-name
    (save-buffer))
  (plaster-save-paste))

;;;###autoload
(defun plaster-new ()
  "Visit a new buffer that represents a paste.

The remote paste will be automatically created when the buffer
is opened."
  (interactive)
  (let* ((title (read-string "Paste title: "))
         (type (plaster-read-type)))
    (with-current-buffer (generate-new-buffer title)
      (insert " ")
      (switch-to-buffer (current-buffer))
      (plaster-paste-buffer type title))))

(defun plaster-annotate (&optional parent)
  "Create an annotation to a paste.

If the current buffer represents a paste, then the annotation
will be made against that paste.
Optional argument PARENT The ID of the parent paste to annotate."
  (interactive)
  (let ((id (or parent plaster-parent plaster-id (read-string "Parent paste: "))))
    (with-current-buffer (generate-new-buffer (concat "Annotation to " (format "%s" id)))
      (setq plaster-parent id)
      (plaster-mode)
      (switch-to-buffer (current-buffer)))))

(defun plaster-delete (&optional id)
  "Delete a plaster paste.

If the current buffer represents a paste, then it will delete
this paste and close the buffer.

Optional argument ID The ID of the paste to delete."
  (interactive)
  (let ((id (or id plaster-id (read-string "Paste ID: "))))
    (plaster-request (plaster-api "delete")
                     `(("id" . ,id)))
    (when (equal plaster-id (format "%s" id))
      (kill-buffer))
    (message "Paste %s has been deleted." (format "%s" id))))

;;;###autoload
(define-minor-mode plaster-mode
  "Toggle Plaster mode.

Within this mode, you can automatically manage the remote pastes
through simple keystrokes."
  :group 'plaster
  :lighter " Plaster"
  :keymap plaster-mode-map)

(define-key plaster-mode-map (kbd "C-x C-s") #'plaster-save)
(define-key plaster-mode-map (kbd "C-x C-k") #'plaster-delete)
(define-key plaster-mode-map (kbd "C-x C-a") #'plaster-annotate)

(provide 'plaster)

;;; plaster.el ends here
