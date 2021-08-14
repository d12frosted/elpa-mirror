;;; webpaste.el --- Paste to pastebin-like services  -*- lexical-binding: t; -*-

;; Copyright (c) 2016 Elis Hirwing

;; Author: Elis "etu" Hirwing
;; URL: https://github.com/etu/webpaste.el
;; Package-Commit: bbdc5e5b689a787c6b4ae7690751fe9c10d6796e
;; Package-Version: 20210813.1901
;; Package-X-Original-Version: 3.2.1
;; Version: 3.2.1
;; Keywords: convenience, comm, paste
;; Package-Requires: ((emacs "24.4") (request "0.2.0") (cl-lib "0.5"))

;;; Commentary:

;; This mode allows to paste whole buffers or parts of buffers to
;; pastebin-like services.  It supports more than one service and will
;; failover if one service fails.  More services can easily be added
;; over time and preferred services can easily be configured.

;;; License:

;; This file is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this file; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
;; 02110-1301, USA.

;;; Code:
(require 'request)
(require 'cl-lib)
(require 'json)



;;;###autoload
(defgroup webpaste nil
  "Configuration options for webpaste.el where you can define paste providers,
provider priority for which order which provider should be tried when used."
  :group 'web)


(defcustom webpaste-provider-priority ()
  "Define provider priority of which providers to try in which order.
This variable should be a list of strings and if it isn't defined it will
default to all providers in order defined in ‘webpaste--provider’ list."
  :group 'webpaste
  :type '(repeat string))


(defcustom webpaste-paste-confirmation nil
  "Prompt for a yes/no confirmation before attempting to paste a region or buffer."
  :group 'webpaste
  :type 'boolean)


(defcustom webpaste-open-in-browser nil
  "Open recently created pastes in a browser.
This uses `browse-url-generic' to open URLs."
  :group 'webpaste
  :type 'boolean)


(defcustom webpaste-add-to-killring t
  "Add the returned URL to the killring after paste."
  :group 'webpaste
  :type 'boolean)


(defcustom webpaste-paste-raw-text nil
  "Enable this to disable language detection to only make raw pastes."
  :group 'webpaste
  :type 'boolean)


(defcustom webpaste-return-url-hook nil
  "Hook executed with the returned url as parameter."
  :group 'webpaste
  :type 'hook)


(defcustom webpaste-max-retries 10
  "Max retries before we give up on pasting, say if network is down or so."
  :group 'webpaste
  :type 'number)


(defcustom webpaste-providers-alist
  '(("ix.io"
     :uri "http://ix.io/"
     :post-field "f:1"
     :lang-uri-separator "/"
     :lang-overrides ((emacs-lisp-mode . "elisp")
                      (nix-mode . "nix"))
     :success-lambda webpaste--providers-success-returned-string)

    ("paste.rs"
     :uri "https://paste.rs"
     :post-field nil
     :success-lambda webpaste--providers-success-returned-string)

    ("dpaste.com"
     :uri "http://dpaste.com/api/v2/"
     :post-data (("title" . "")
                 ("poster" . "")
                 ("expiry_days" . 1))
     :post-field "content"
     :post-lang-field-name "syntax"
     :lang-overrides ((emacs-lisp-mode . "clojure"))
     :success-lambda webpaste--providers-success-location-header)

    ("dpaste.org"
     :uri "https://dpaste.org/api/"
     :post-data (("expires" . 86400))
     :post-field "content"
     :post-lang-field-name "lexer"
     :lang-overrides ((emacs-lisp-mode . "clojure"))
     :success-lambda webpaste--providers-success-returned-string)

    ("paste.mozilla.org"
      :uri "https://paste.mozilla.org/api/"
      :post-data (("expires" . 86400))
      :post-field "content"
      :post-lang-field-name "lexer"
      :lang-overrides ((emacs-lisp-mode . "clojure"))
      :success-lambda webpaste--providers-success-returned-string)

    ("gist.github.com"
     :uri "https://api.github.com/gists"
     :post-field nil
     :post-field-lambda (lambda () (cl-function (lambda (&key text &allow-other-keys)
                                                  (let ((filename (if (buffer-file-name)
                                                                      (file-name-nondirectory (buffer-file-name))
                                                                    "file.txt")))
                                                    (json-encode `(("description" . "Pasted from Emacs with webpaste.el")
                                                                   ("public" . "false")
                                                                   ("files" .
                                                                    ((,filename .
                                                                                (("content" . ,text)))))))))))
     :success-lambda (lambda () (cl-function (lambda (&key data &allow-other-keys)
                                               (when data
                                                 (webpaste--return-url
                                                  (cdr (assoc 'html_url (json-read-from-string data)))))))))

    ("bpa.st"
     :uri "https://bpa.st/api/v1/paste"
     :post-data (("expiry" . "1day"))
     :post-field-lambda webpaste--providers-pinnwand-request
     :lang-overrides ((emacs-lisp-mode . "emacs"))
     :success-lambda webpaste--providers-pinnwand-success))

  "Define all webpaste.el providers.
Consists of provider name and arguments to be sent to `webpaste--provider' when
the provider is created.  So to create a custom provider you should read up on
the docs for `webpaste--provider'."
  :group 'webpaste
  :type 'alist)



;; modified from https://emacs.stackexchange.com/a/33893/12534
(defun webpaste--alist-set (key val alist)
  "Set property KEY to VAL in ALIST.
Return new alist.  This creates the association if it is missing, and otherwise
sets the cdr of the first matching association in the list.  It does not create
duplicate associations.  Key comparison is done with `equal'.

This method may mutate the original alist, but you still need to use the return
value of this method instead of the original alist, to ensure correct results."
  (let ((pair (assoc key alist)))
    (if pair
        (setcdr pair val)
      (push (cons key val) alist)))
  alist)



(defvar webpaste--tested-providers ()
  "Variable for storing which providers to try in which order while running.
This list will be re-populated each run based on ‘webpaste-provider-priority’ or
if that variable is nil, it will use the list of names from ‘webpaste--provider’
each run.")


(defvar webpaste--provider-separators ()
  "Variable for storing separators for providers that doesn't post language.
Some providers accepts a post parameter with which language the code is.  But
some providers want to append the language to the resulting URL.")


(defvar webpaste--provider-lang-alists ()
  "Variable for storing alists with languages for highlighting for providers.
This list will be populated when you add providers to have the languages
precalculated, and also available both for pre and post request access.")


(defvar webpaste--current-retries 0
  "Variable for storing the current amount of retries.
This shouldn't go biffer than `webpaste-max-retries' to avoid infinite
loops.  This variable is reset on each new paste.")


(defvar webpaste--default-lang-alist
  '((c-mode . "c")
    (c++-mode . "cpp")
    (cmake-mode . "cmake")
    (css-mode . "css")
    (diff-mode . "diff")
    (fundamental-mode . "text")
    (haskell-mode . "haskell")
    (html-mode . "html")
    (makefile-mode . "make")
    (java-mode . "java")
    (js-mode . "js")
    (go-mode . "go")
    (perl-mode . "perl")
    (php-mode . "php")
    (python-mode . "python")
    (ruby-mode . "rb")
    (rust-mode . "rust")
    (sh-mode . "bash")
    (sql-mode . "sql")
    (tex-mode . "tex")
    (xml-mode . "xml")
    (yaml-mode . "yaml"))
  "Alist that maps `major-mode' names to language names.")



;;; Predefined error lambda for providers
(cl-defun webpaste--providers-error-lambda (&key text)
  "Predefined error that pastes TEXT to next provider.
This is the default failover hook that we use for most providers."
  (cl-function (lambda (&key error-thrown &allow-other-keys)
                 (message "Got error: %S" error-thrown)
                 (webpaste--paste-text text))))


(cl-defun webpaste--providers-error-lambda-no-failover (&rest _)
  "Predefined error callback for providers that shouldn't do failover."
  (cl-function (lambda (&key error-thrown &allow-other-keys)
                 (message "Got error: %S" error-thrown))))


;;; Predefined success lambdas for providers
(cl-defun webpaste--providers-success-location-header ()
  "Predefined success callback for providers returning a Location header."
  (cl-function (lambda (&key response &allow-other-keys)
                 (when response
                   (webpaste--return-url
                    (request-response-header response "Location"))))))


(cl-defun webpaste--providers-success-response-url ()
  "Predefined success callback for providers that and up with an URL somehow."
  (cl-function (lambda (&key response &allow-other-keys)
                 (when response
                   (webpaste--return-url
                    (request-response-url response))))))


(cl-defun webpaste--providers-success-returned-string ()
  "Predefined success callback for providers returning a string with URL."
  (cl-function (lambda (&key data &allow-other-keys)
                 (when data
                   (setq data (replace-regexp-in-string "\n$" "" data))
                   (setq data (replace-regexp-in-string "\"" "" data))

                   (webpaste--return-url data)))))


(cl-defun webpaste--providers-default-post-field-lambda ()
  "Predefined lambda for building post fields."
  (cl-function (lambda (&key text
                             post-field
                             provider-uri
                             (post-lang-field-name nil)
                             (post-data '()))
                 (cl-pushnew (cons post-field text) post-data)

                 ;; Fetch language name for this provider
                 (let ((language-name (webpaste--get-buffer-language provider-uri)))
                   (if (and post-lang-field-name language-name)
                       ;; Append language to the post-data
                       (cl-pushnew (cons post-lang-field-name language-name) post-data)))

                 ;; If there's no defined field
                 (if (equal post-field nil)
                     ;; Just return the plain data
                     text

                   ;; Otherwise we return the formatted post data
                   post-data))))

(cl-defun webpaste--providers-pinnwand-request ()
  "Build request for pinnwand pastebins."
  (cl-function (lambda (&key text post-data provider-uri &allow-other-keys)
                 "Build request for pinnwand pastebins."
                 (let* ((lexer (or (webpaste--get-buffer-language provider-uri) "text"))
                        (file `(("lexer" . ,lexer) ("content" . ,text)))
                        (file-name (buffer-file-name)))
                   (when file-name
                     (push (cons "name"
                                 (file-name-nondirectory file-name))
                           file))
                   (json-encode `((expiry . ,(or (cdr (assoc "expiry" post-data)) "1day"))
                                  (files . ,(vector file))))))))


(cl-defun webpaste--providers-pinnwand-success ()
  "Parse JSON response from pinnwand pastebins in DATA."
  (cl-function (lambda (&key data &allow-other-keys)
                 (webpaste--return-url (cdr (assq 'link (json-read-from-string data)))))))




(cl-defun webpaste--get-lang-alist-with-overrides (overrides)
  "Fetches lang-alist with OVERRIDES applied."

  ;; Copy original list to temporary list
  (let ((lang-alist webpaste--default-lang-alist))
    ;; Go through list of overrides and append them to the temporary list
    (dolist (override-element overrides)
      (cl-pushnew override-element lang-alist))

    ;; Return temporary list
    lang-alist))


(cl-defun webpaste--provider
    (&key uri
          post-field
          success-lambda
          (type "POST")
          (post-data '())
          (post-lang-field-name nil)
          (parser 'buffer-string)
          (lang-overrides '())
          (lang-uri-separator nil)
          (error-lambda 'webpaste--providers-error-lambda)
          (post-field-lambda 'webpaste--providers-default-post-field-lambda))
  "Function to create the lambda function for a provider.

Usage:
  (webpaste--provider
    [:keyword [option]]...)

Required params:
:uri               URI that we should do the request to to paste data.

:post-field        Name of the field to insert the code into.

:success-lambda    Callback sent to `request', look up how to write these in the
                   documentation for `request'.  Two good examples are
                   `webpaste--providers-success-location-header' and
                   `webpaste--providers-success-returned-string' as well as the
                   custom one used for the gist.github.com provider.

Optional params:
:type              HTTP Request TYPE, defaults to POST.

:post-data         Default post fields sent to service.  Defaults to nil.

:post-lang-field-name   Fieldname for defining which language your paste should
                        use to the provider.

:lang-overrides    Alist defining overrides for languages for this provider.  If
                   a mode is set to nil, it will use fundamental-mode's value as
                   fallback.  Fundamental-mode's value can also be overridden.

:lang-uri-separator   Lang URI separator.  This is used for providers that
                      appends the language to the end of the resulting URI and
                      needs a separator between language and link.

:parser            Defines how request.el parses the result.  Look up :parser for
                   `request'.  This defaults to 'buffer-string.

:error-lambda      Callback sent to `request', look up how to write these in the
                   documentation for `request'.  The default value for this is
                   `webpaste--providers-error-lambda', but there's also
                   `webpaste--providers-error-lambda-no-failover' available if
                   you need a provider that isn't allowed to failover.

:post-field-lambda Function that builds and returns the post data that should be
                   sent to the provider.  It should accept named parameters by
                   the names TEXT, POST-FIELD and POST-DATA.  POST-DATA should
                   default to 'nil' or empty list.  It also takes the option
                   LANG-OVERRIDES which is a list that enables overriding of
                   `webpaste--default-lang-alist'.

                   TEXT contains the data that should be sent.
                   POST-FIELD contains the name of the field to be sent.
                   POST-DATA contains predefined fields that the provider needs.
                   SUCCESS-LAMBDA contains the function to run on an successful paste."
  ;; If we get a separator sent to the function, append it to the list of
  ;; separators for later use
  (when lang-uri-separator
    (setq webpaste--provider-separators
          (webpaste--alist-set
           uri lang-uri-separator webpaste--provider-separators)))

  ;; Add pre-calculated list of webpaste lang alists
  (setq webpaste--provider-lang-alists
        (webpaste--alist-set
         uri
         (webpaste--get-lang-alist-with-overrides lang-overrides)
         webpaste--provider-lang-alists))

  (cl-function
   (lambda (text
            &key
            (sync nil))
     "Paste TEXT to provider. Force SYNC if needed for debugging."

     (prog1 nil
       ;; Do request
       (request uri
                :type type
                :data (funcall (funcall post-field-lambda)
                               :text text
                               :provider-uri uri
                               :post-field post-field
                               :post-lang-field-name post-lang-field-name
                               :post-data post-data)
                :parser parser
                :success (funcall success-lambda)
                :sync sync
                :error (funcall error-lambda :text text))))))


(cl-defun webpaste--get-provider-by-name (provider-name)
  "Get provider by PROVIDER-NAME."

  (apply 'webpaste--provider
         (cdr (assoc provider-name webpaste-providers-alist))))


(cl-defun webpaste--get-provider-priority ()
  "Return provider priority."

  ;; Populate webpaste-provider-priority if needed
  (unless webpaste-provider-priority
    (let ((provider-names))
      ;; Loop provider list
      (dolist (provider webpaste-providers-alist)
        (cl-pushnew (car provider) provider-names))

      ;; Set names list
      (setq-default webpaste-provider-priority (reverse provider-names))))

  webpaste-provider-priority)


(cl-defun webpaste--get-shebang-lang-mode ()
  "Return language of the buffer set using a shebang as a mode symbol.

Return nil if no shebang found.

Example: For \"#!/usr/bin/env bash\", 'bash-mode is returned.
         For \"#!/bin/python\", 'python-mode is returned."

  (let* ((end-of-first-line (save-excursion
                              (save-restriction
                                (widen)
                                (goto-char (point-min))
                                (end-of-line 1)
                                (point))))
         (first-line (save-restriction
                       (widen)
                       (buffer-substring-no-properties
                        (point-min) end-of-first-line))))
    (when (string-match "\\`#!\\(?1:\\(?:[^ ]+/\\)\\(?2:[^ /]+\\)\\)\\(?: +\\(?3:[^ ]+\\)\\)*" first-line)
      (let ((lang (if (string= "/usr/bin/env" (match-string-no-properties 1 first-line))
                      (match-string-no-properties 3 first-line)
                    (match-string-no-properties 2 first-line))))
        (when lang
          (intern (format "%s-mode" lang)))))))


(cl-defun webpaste--get-buffer-language (provider)
  "Return language of the buffer that should be sent to the PROVIDER.

This also depends on which provider it is since different providers might have
different opinions of how the input for their fields should look like."

  (unless webpaste-paste-raw-text
    (let* ((provider-lang-alist (cdr (assoc provider webpaste--provider-lang-alists)))
           (detected-mode (or (webpaste--get-shebang-lang-mode) major-mode))
           (language-name (cdr (assoc detected-mode provider-lang-alist))))
      language-name)))


(cl-defun webpaste--return-url (returned-url)
  "Return RETURNED-URL to user from the result of the paste service."

  ;; Loop providers separators
  (dolist (provider-separator webpaste--provider-separators)
    ;; Match if the separator is for this URI
    (when (string-match-p (regexp-quote (car provider-separator)) returned-url)
      ;; Look up the language of the buffer for this provider
      (let ((language-name (webpaste--get-buffer-language (car provider-separator))))
        ;; Append the language to the link if it existed
        (when language-name
          (setq returned-url (concat returned-url (cdr provider-separator) language-name))))))

  ;; Reset tested providers after successful paste
  (setq webpaste--tested-providers nil)

  ;; If the user want to open the link in an external browser, do so.
  (when webpaste-open-in-browser
    (browse-url-generic returned-url))

  ;; Add RETURNED-URL to killring for easy pasting
  (when webpaste-add-to-killring
    (kill-new returned-url)
    (message "Added %S to kill ring." returned-url))

  ;; Run user defined hooks
  (dolist (hook webpaste-return-url-hook)
    (funcall hook returned-url))

  ;; Return URL instead of nil
  returned-url)


(cl-defun webpaste--paste-text-to-provider (text provider-name)
  "Paste TEXT to specific PROVIDER-NAME.
This function sends a paste to a specific provider.  This function is created to
make `webpaste--paste-text' do less magic things all at once."
  (funcall (webpaste--get-provider-by-name provider-name) text))


(cl-defun webpaste--paste-text (text)
  "Paste TEXT to some paste service.
If ‘webpaste-provider-priority’ isn't populated, it will populate it with the
default providers.

Then if ‘webpaste--tested-providers’ isn't populated it will be populated by
‘webpaste-provider-priority’.

Then it extracts the first element of ‘webpaste--tested-providers’ and drops
the first element from that list and gets the lambda for the provider and
runs the lambda to paste TEXT to the paste service.  The paste-service in turn
might call this function again with TEXT as param to retry if it failed.

When we run out of providers to try, it will restart since
‘webpaste--tested-providers’ will be empty and then populated again."

  ;; Populate tested providers for this request if needed
  (unless webpaste--tested-providers
    (setq webpaste--tested-providers (webpaste--get-provider-priority)))

  ;; If we have too many retries, empty the provider list.
  (if (>= webpaste--current-retries webpaste-max-retries)
      (setq webpaste--tested-providers nil)
    ;; Otherwise increment the retry counter.
    (setq webpaste--current-retries (+ 1 webpaste--current-retries)))

  ;; Get name of provider at the top of the list
  (let ((provider-name (car webpaste--tested-providers)))
    ;; Drop the name at the top of the list
    (setq webpaste--tested-providers (cdr webpaste--tested-providers))

    ;; Run pasting function
    (webpaste--paste-text-to-provider text provider-name)))



;;;###autoload
(cl-defun webpaste-paste-region (point mark)
  "Paste selected region to some paste service.
Argument POINT Current point.
Argument MARK Current mark."
  (interactive "r")

  ;; Set retry counter to zero before we start.
  (setq webpaste--current-retries 0)

  ;; unless we wanted a paste confirmation and declined
  (unless (and webpaste-paste-confirmation
               (not (yes-or-no-p "paste entire region?")))
    ;; Extract the buffer contents with buffer-substring and paste it
    (webpaste--paste-text (buffer-substring point mark))))


;;;###autoload
(cl-defun webpaste-paste-buffer ()
  "Paste current buffer to some paste service."
  (interactive)

  ;; Set retry counter to zero before we start.
  (setq webpaste--current-retries 0)

  ;; unless we wanted a paste confirmation and declined
  (unless (and webpaste-paste-confirmation
               (not (yes-or-no-p "paste entire buffer?")))
    ;; Extract the buffer contents with buffer-substring and paste it
    (webpaste--paste-text (buffer-substring (point-min) (point-max)))))


;;;###autoload
(cl-defun webpaste-paste-buffer-or-region (&optional point mark)
  "Paste current buffer or selected region to some paste service.
Takes optional POINT and MARK to paste a region."
  (interactive "r")

  ;; if region is selected
  (if (region-active-p)
      ;; Paste selected region
      (webpaste-paste-region point mark)
    ;; Else, Paste buffer
    (webpaste-paste-buffer)))



(provide 'webpaste)

;;; webpaste.el ends here
