;;; plsense-direx.el --- Perl Package Explorer

;; Copyright (C) 2014  Hiroaki Otsu

;; Author: Hiroaki Otsu <ootsuhiroaki@gmail.com>
;; Keywords: perl, convenience
;; Package-Version: 20140520.2008
;; Package-Commit: 8a2f465264c74e04524cc789cdad0190ace43f6c
;; URL: https://github.com/aki2o/plsense-direx
;; Version: 0.2.0
;; Package-Requires: ((direx "0.1alpha") (plsense "0.3.2") (log4e "0.2.0") (yaxception "0.3.2"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; 
;; see <https://github.com/aki2o/plsense-direx/blob/master/README.md>

;;; Dependency:
;; 
;; - direx.el ( see <https://github.com/m2ym/direx-el> )
;; - plsense.el ( see <https://github.com/aki2o/emacs-plsense> )
;; - yaxception.el ( see <https://github.com/aki2o/yaxception> )
;; - log4e.el ( see <https://github.com/aki2o/log4e> )

;;; Installation:
;;
;; Put this to your load-path.
;; And put the following lines in your .emacs or site-start.el file.
;; 
;; (require 'plsense-direx)

;;; Configuration:
;; 
;; ;; Key Binding
;; (setq plsense-direx:open-explorer-key "C-x j")
;; (setq plsense-direx:open-explorer-other-window-key "C-x J")
;; (setq plsense-direx:open-referer-key "C-x M-j")
;; (setq plsense-direx:open-referer-other-window-key "C-x C-M-J")
;; 
;; (plsense-direx:config-default)

;;; Customization:
;; 
;; [EVAL] (autodoc-document-lisp-buffer :type 'user-variable :prefix "plsense-direx:[^:]" :docstring t)
;; `plsense-direx:open-explorer-key'
;; Keystroke for `plsense-direx:open-explorer'.
;; `plsense-direx:open-explorer-other-window-key'
;; Keystroke for `plsense-direx:open-explorer-other-window'.
;; `plsense-direx:open-referer-key'
;; Keystroke for `plsense-direx:open-referer'.
;; `plsense-direx:open-referer-other-window-key'
;; Keystroke for `plsense-direx:open-referer-other-window'.
;; 
;;  *** END auto-documentation

;;; API:
;; 
;; [EVAL] (autodoc-document-lisp-buffer :type 'command :prefix "plsense-direx:[^:]" :docstring t)
;; `plsense-direx:open-explorer'
;; Open perl package explorer.
;; `plsense-direx:open-explorer-other-window'
;; Open perl package explorer in other window.
;; `plsense-direx:open-referer'
;; Open perl package referer.
;; `plsense-direx:open-referer-other-window'
;; Open perl package referer in other window.
;; `plsense-direx:display-help'
;; Display help buffer about the node/leaf of cursor location.
;; `plsense-direx:update-current-package'
;; Update the package of cursor location in Perl buffer.
;; `plsense-direx:setup-current-buffer'
;; Do setup for using plsense-direx in current buffer.
;; 
;;  *** END auto-documentation
;; [EVAL] (autodoc-document-lisp-buffer :type 'function :prefix "plsense-direx:[^:]" :docstring t)
;; `plsense-direx:get-explorer'
;; Return the buffer of package explorer for PROJNM.
;; `plsense-direx:get-referer'
;; Return the buffer of package referer for PROJNM.
;; `plsense-direx:get-explorer-with-open-location'
;; Return the buffer of package explorer for PROJNM with open location of PKGNM/MTDNM.
;; `plsense-direx:get-referer-with-open-location'
;; Return the buffer of package referer for PROJNM with open location of PKGNM/MTDNM.
;; `plsense-direx:update-explorer'
;; Update the buffer of package explorer for PROJNM about PKGNM.
;; `plsense-direx:update-referer'
;; Update the buffer of package referer for PROJNM about PKGNM.
;; `plsense-direx:find-explorer-no-select'
;; Find the buffer of package explorer matched cursor location without display.
;; `plsense-direx:find-referer-no-select'
;; Find the buffer of package referer matched cursor location without display.
;; `plsense-direx:config-default'
;; Do setting recommemded configuration.
;; 
;;  *** END auto-documentation
;; [Note] Functions and variables other than listed above, Those specifications may be changed without notice.

;;; Tested On:
;; 
;; - Emacs ... GNU Emacs 24.3.1 (i686-pc-linux-gnu, GTK+ Version 3.4.2) of 2013-08-22 on chindi02, modified by Debian
;; - direx.el ... Version 0.1alpha
;; - plsense.el ... Version 0.3.2
;; - yaxception.el ... Version 0.3.2
;; - log4e.el ... Version 0.2.0


;; Enjoy!!!


(require 'direx)
(require 'plsense)
(require 'dired)
(require 'log4e)
(require 'yaxception)

(defgroup plsense-direx nil
  "Perl Package Explorer."
  :group 'convenience
  :prefix "plsense-direx")

(defcustom plsense-direx:open-explorer-key nil
  "Keystroke for `plsense-direx:open-explorer'."
  :type 'string
  :group 'plsense-direx)

(defcustom plsense-direx:open-explorer-other-window-key nil
  "Keystroke for `plsense-direx:open-explorer-other-window'."
  :type 'string
  :group 'plsense-direx)

(defcustom plsense-direx:open-referer-key nil
  "Keystroke for `plsense-direx:open-referer'."
  :type 'string
  :group 'plsense-direx)

(defcustom plsense-direx:open-referer-other-window-key nil
  "Keystroke for `plsense-direx:open-referer-other-window'."
  :type 'string
  :group 'plsense-direx)

(defface plsense-direx:regular-package-face
  '((t (:inherit dired-directory)))
  "Face for the regular package name part."
  :group 'plsense-direx)

(defface plsense-direx:parent-package-face
  '((t (:inherit font-lock-type-face)))
  "Face for the parent package name part."
  :group 'plsense-direx)

(defface plsense-direx:included-package-face
  '((t (:inherit font-lock-keyword-face)))
  "Face for the included package name part."
  :group 'plsense-direx)

(defface plsense-direx:regular-method-face
  nil
  "Face for the regular method name part."
  :group 'plsense-direx)


(log4e:deflogger "plsense-direx" "%t [%l] %m" "%H:%M:%S" '((fatal . "fatal")
                                                           (error . "error")
                                                           (warn  . "warn")
                                                           (info  . "info")
                                                           (debug . "debug")
                                                           (trace . "trace")))
(plsense-direx--log-set-level 'trace)


;;;;;;;;;;;;;;;
;; Utilities

(defvar plsense-direx::regexp-main-package (rx-to-string `(and bos
                                                               "main[" (group (+ not-newline)) "]"
                                                               (? "::" (+ (not (any ":]"))))
                                                               eos)))

(defun* plsense-direx::show-message (msg &rest args)
  (apply 'message (concat "[PLSENSE-DIREX] " msg) args)
  nil)

(defsubst plsense-direx::maybe-main-package-p (s &optional return-filepath)
  (let ((fpath (when s (cond ((string= s "main")
                              "")
                             ((string-match plsense-direx::regexp-main-package s)
                              (match-string-no-properties 1 s))))))
    (when fpath
      (if return-filepath fpath t))))

(defsubst plsense-direx::get-root-package-name (pkgnm)
  (when pkgnm
    (cond ((plsense-direx::maybe-main-package-p pkgnm)
           pkgnm)
          ((string-match "\\`\\([^: ]+\\)" pkgnm)
           (match-string-no-properties 1 pkgnm)))))

(defsubst plsense-direx::get-parent-package-name (pkgnm)
  (when (not (plsense-direx::maybe-main-package-p pkgnm))
    (let ((ret (replace-regexp-in-string "::[^:]+\\'" "" pkgnm)))
      (when (and (not (string= ret ""))
                 (not (string= ret pkgnm)))
        ret))))

(defsubst plsense-direx::build-address (pkgnm mtdnm)
  (cond ((and pkgnm mtdnm) (concat "&" pkgnm "::" mtdnm))
        (pkgnm             pkgnm)
        (mtdnm             (concat "&" mtdnm))))

(defsubst plsense-direx::pick-pkgnm-from-method-addr (addr)
  (when (string-match "\\`&" addr)
    (let* ((addr (replace-regexp-in-string "::[^:]+\\'" "" addr))
           (addr (replace-regexp-in-string "\\`&" "" addr)))
      addr)))

(defun plsense-direx::get-current-parsed-location ()
  (plsense-direx--trace "start get current parsed location.")
  (when (and (plsense--set-current-file)
             (plsense--set-current-package)
             (plsense--set-current-method))
    (let* ((locret (plsense--get-server-response "location" :waitsec 2 :ignore-done t))
           (projnm (when (string-match "^Project: \\([^\n]+\\)" locret)
                     (match-string-no-properties 1 locret)))
           (fpath (when (string-match "^File: \\([^\n]+\\)" locret)
                    (match-string-no-properties 1 locret)))
           (pkgnm (when (string-match "^Module: \\([^\n]+\\)" locret)
                    (match-string-no-properties 1 locret)))
           (mtdnm (when (string-match "^Sub: \\([^\n]+\\)" locret)
                    (match-string-no-properties 1 locret))))
      (plsense-direx--trace "got current parsed location : projnm[%s] fpath[%s] pkgnm[%s] mtdnm[%s]" projnm fpath pkgnm mtdnm)
      (list projnm
            (if (and pkgnm (string= pkgnm "main")) (format "main[%s]" fpath) pkgnm)
            mtdnm))))


;;;;;;;;;;;;;
;; Explore

(defvar plsense-direx::hash-explore-cache (make-hash-table :test 'equal))
(defvar plsense-direx::use-root-cache nil)
(defvar plsense-direx::current-project nil)

(defsubst plsense-direx::get-cache-key (pkgnm)
  (format "%s|%s" plsense-direx::current-project pkgnm))

(defun plsense-direx::get-explore-request-argument (pkgnm)
  (cond ((plsense-direx::maybe-main-package-p pkgnm)
         (let ((qpkgnm (shell-command-to-string (format "perl -e 'print quotemeta \"%s\"'" pkgnm))))
           (when qpkgnm (format "\\A %s \\z" qpkgnm))))
        (plsense-direx::use-root-cache
         (format "\\A %s (\\z|:)" (plsense-direx::get-root-package-name pkgnm)))
        (pkgnm
         (format "\\A %s (\\z|:)" pkgnm))))

(defun plsense-direx::clear-explore-cache (&optional pkgnm)
  (plsense-direx--trace "start clear explore cache : %s" pkgnm)
  (let ((reqpkgnm (plsense-direx::get-explore-request-argument pkgnm)))
    (if reqpkgnm
        (remhash (plsense-direx::get-cache-key reqpkgnm) plsense-direx::hash-explore-cache)
      (setq plsense-direx::hash-explore-cache (make-hash-table :test 'equal)))))

(defun plsense-direx::clear-explore-cache-by-regexp (regexp)
  (plsense-direx--trace "start clear explore cache by regexp : %s" regexp)
  (when regexp
    (loop for k being the hash-key in plsense-direx::hash-explore-cache
          for pkgnm = (replace-regexp-in-string (format "\\`%s|" plsense-direx::current-project) "" k)
          if (and (not (string= pkgnm k))
                  (string-match regexp pkgnm))
          do (remhash k plsense-direx::hash-explore-cache))))

(yaxception:deferror 'plsense-direx:explore-error nil "[PLSENSE-DIREX] Failed get the explore result of %s" 'pkg)
(defun plsense-direx::get-explore-result (pkgnm)
  (plsense-direx--trace "start get explore result of [%s]. use-root-cache[%s]"
                        pkgnm plsense-direx::use-root-cache)
  (let* ((reqpkgnm (plsense-direx::get-explore-request-argument pkgnm))
         (ret (when reqpkgnm
               (or (gethash (plsense-direx::get-cache-key reqpkgnm) plsense-direx::hash-explore-cache)
                   (puthash (plsense-direx::get-cache-key reqpkgnm)
                            (plsense--get-server-response (concat "explore " reqpkgnm)
                                                          :waitsec 3
                                                          :force t
                                                          :ignore-done t)
                            plsense-direx::hash-explore-cache)))))
    (when (or (not ret)
              (string= ret ""))
      (remhash (plsense-direx::get-cache-key reqpkgnm) plsense-direx::hash-explore-cache)
      (plsense-direx--error "failed get explore result of [%s]" pkgnm)
      (yaxception:throw 'plsense-direx:explore-error :pkg pkgnm))
    ret))

(defun plsense-direx::get-matched-package-region (pkgre)
  (let* ((startpt (when (re-search-forward pkgre nil t)
                    (point-at-bol)))
         (endpt (when startpt
                  (goto-char (or (when (re-search-forward "^[^ ]" nil t)
                                   (point-at-bol))
                                 (point-max)))
                  (point))))
    (when (and startpt endpt)
      (buffer-substring-no-properties startpt endpt))))

(defun plsense-direx::get-own-explore-results (pkgnm)
  (plsense-direx--trace "start get own explore results of [%s]" pkgnm)
  (when (and (stringp pkgnm)
             (not (string= pkgnm "")))
    (let ((re (direx:aif (plsense-direx::maybe-main-package-p pkgnm t)
                  (rx-to-string `(and bol "main " ,it " "))
                (rx-to-string `(and bol ,pkgnm " "))))
          (exret (plsense-direx::get-explore-result pkgnm)))
      (with-temp-buffer
        (insert exret)
        (goto-char (point-min))
        (direx:awhen (plsense-direx::get-matched-package-region re)
          (plsense-direx--trace "got own explore region.\n%s" it)
          (split-string it "\r?\n"))))))

(defun plsense-direx::get-child-explore-results (pkgnm)
  (plsense-direx--trace "start get child explore results of [%s]" pkgnm)
  (when (and (stringp pkgnm)
             (not (string= pkgnm ""))
             (not (plsense-direx::maybe-main-package-p pkgnm)))
    (let* ((re (rx-to-string `(and bol ,pkgnm "::" (+ (not (any ": \t\r\n"))) " ")))
           (exret (plsense-direx::get-explore-result pkgnm))
           (childs (with-temp-buffer
                     (insert exret)
                     (loop initially (goto-char (point-min))
                           while (re-search-forward re nil t)
                           collect (replace-regexp-in-string "\r?\n\\'" "" (thing-at-point 'line))))))
      (plsense-direx--trace "got child explore region.\n%s" (mapconcat 'identity childs "\n"))
      childs)))

(defun plsense-direx::get-mock-child-explore-results (pkgnm)
  (plsense-direx--trace "start get mock child explore results of [%s]" pkgnm)
  (when (and (stringp pkgnm)
             (not (string= pkgnm ""))
             (not (plsense-direx::maybe-main-package-p pkgnm)))
    (let* ((re (rx-to-string `(and bol (group ,pkgnm "::" (+ (not (any ": \t\r\n")))) "::" (not (any ": \t\r\n")))))
           (exret (plsense-direx::get-explore-result pkgnm))
           (childs (with-temp-buffer
                     (insert exret)
                     (loop with founds = nil
                           initially (goto-char (point-min))
                           while (re-search-forward re nil t)
                           for child = (match-string-no-properties 1)
                           if (not (member child founds))
                           collect (progn (push child founds) child)))))
      (plsense-direx--trace "got mock child explore region.\n%s" (mapconcat 'identity childs "\n"))
      childs)))


;;;;;;;;;;;
;; Trees

(defvar plsense-direx::tree-flat-p nil)

(defgeneric plsense-direx::get-location-address (location)
  "Return the address of LOCATION.")

(defgeneric plsense-direx::get-location-line (location)
  "Return the line number of LOCATION.")

(defgeneric plsense-direx::get-location-column (location)
  "Return the column number of LOCATION.")

(defgeneric plsense-direx::get-location-package (location)
  "Return the package string of LOCATION.")

(defgeneric plsense-direx::get-location-package-symbol (location)
  "Return the symbol part of the package string of LOCATION.")

(defgeneric plsense-direx::get-location-file (location)
  "Return the file path of LOCATION.")

(defgeneric plsense-direx::update-location (location)
  "update LOCATION by using cache.")

(defun plsense-direx::get-best-location (loc)
  (let ((file (plsense-direx::get-location-file loc))
        (line (plsense-direx::get-location-line loc))
        (col (plsense-direx::get-location-column loc)))
    (cond ((or (not file) (not line) (not col))
           (plsense-direx--warn "part of location is missing"))
          ((and (file-exists-p file) (> line 0) (> col 0))
           (list file line col))
          (t
           (plsense-direx::update-location loc)
           (list (plsense-direx::get-location-file loc)
                 (plsense-direx::get-location-line loc)
                 (plsense-direx::get-location-column loc))))))

(defun plsense-direx::goto-location (loc)
  (multiple-value-bind (file line col) (plsense-direx::get-best-location loc)
    (plsense-direx--trace "start goto location. file[%s] line[%s] col[%s]" file line col)
    (if (or (not file)
            (not (file-exists-p file)))
        (plsense-direx::show-message "Not exist file of %s : %s"
                                     (plsense-direx::get-location-package-symbol loc) file)
      (with-current-buffer (find-file-noselect file)
        (if (or (eq line 0) (eq col 0))
            (progn
              (plsense-direx::show-message "This package might be not yet ready.")
              (sleep-for 1)
              (plsense-direx::clear-explore-cache (plsense-direx::get-location-package loc)))
          (goto-char 1)
          (forward-line (- line 1))
          (forward-char (- col 1)))
        (current-buffer)))))


(defclass plsense-direx::method (direx:leaf)
  ((package :initarg :package
            :accessor plsense-direx::method-package)
   (line :initarg :line
         :accessor plsense-direx::method-line)
   (column :initarg :column
           :accessor plsense-direx::method-column)))

(defclass plsense-direx::package (direx:node)
  ((string :initarg :string
           :accessor plsense-direx::package-string)
   (file :initarg :file
         :accessor plsense-direx::package-file)
   (line :initarg :line
         :accessor plsense-direx::package-line)
   (column :initarg :column
           :accessor plsense-direx::package-column)
   (flat :initarg :flat
         :accessor plsense-direx::package-flat)
   (mock :initarg :mock
         :accessor plsense-direx::package-mock-p)))


(defsubst plsense-direx::make-method-by-explore (str pkg pkgnm &optional target-mtdnm)
  (when (string-match "\\`  &\\([^ ]+\\) +\\([0-9]+\\):\\([0-9]+\\)" str)
    (let* ((mtdnm (match-string-no-properties 1 str))
           (line (string-to-number (match-string-no-properties 2 str)))
           (col (string-to-number (match-string-no-properties 3 str)))
           (addr (plsense-direx::build-address pkgnm mtdnm)))
      (when (or (not target-mtdnm)
                (string= mtdnm target-mtdnm))
        (plsense-direx--trace "make method[%s] by explore : %s" mtdnm str)
        `(,addr . ,(make-instance 'plsense-direx::method
                                  :name mtdnm
                                  :package pkg
                                  :line line
                                  :column col))))))

(defun plsense-direx::make-method-by-name (mtdnm pkg pkgnm &optional explore-results)
  (plsense-direx--trace "start make method by name. mtdnm[%s] pkg[%s] explore-results[%s]"
                        mtdnm pkgnm explore-results)
  (or (loop for str in (or explore-results
                           (plsense-direx::get-own-explore-results pkgnm))
            for mtd-alist = (plsense-direx::make-method-by-explore str pkg pkgnm mtdnm)
            if mtd-alist return (cdr mtd-alist))
      (when plsense-direx::use-root-cache
        ;; If failed to make from cache, retry without cache.
        (let ((plsense-direx::use-root-cache nil))
          (plsense-direx::clear-explore-cache pkgnm)
          (plsense-direx::make-method-by-name mtdnm pkg pkgnm)))))

(defmethod direx:tree-equals ((x plsense-direx::method) y)
  (or (eq x y)
      (and (typep y 'plsense-direx::method)
           (let* ((pkg1 (plsense-direx::method-package x))
                  (pkgnm1 (when pkg1 (plsense-direx::package-string pkg1)))
                  (pkg2 (plsense-direx::method-package y))
                  (pkgnm2 (when pkg2 (plsense-direx::package-string pkg2))))
             (equal (plsense-direx::build-address pkgnm1 (direx:tree-name x))
                    (plsense-direx::build-address pkgnm2 (direx:tree-name y)))))))

(defmethod plsense-direx::get-location-address ((mtd plsense-direx::method))
  (let* ((pkg (plsense-direx::method-package mtd))
         (pkgnm (when pkg (plsense-direx::package-string pkg))))
    (plsense-direx::build-address pkgnm (direx:tree-name mtd))))

(defmethod plsense-direx::get-location-line ((mtd plsense-direx::method))
  (plsense-direx::method-line mtd))

(defmethod plsense-direx::get-location-column ((mtd plsense-direx::method))
  (plsense-direx::method-column mtd))

(defmethod plsense-direx::get-location-package ((mtd plsense-direx::method))
  (let ((pkg (plsense-direx::method-package mtd)))
    (when pkg (plsense-direx::package-string pkg))))

(defmethod plsense-direx::get-location-package-symbol ((mtd plsense-direx::method))
  (let* ((pkg (plsense-direx::method-package mtd))
         (pkgnm (when pkg (plsense-direx::package-string pkg))))
    (if (and pkgnm (plsense-direx::maybe-main-package-p pkgnm))
        "main"
      pkgnm)))

(defmethod plsense-direx::get-location-file ((mtd plsense-direx::method))
  (let ((pkg (plsense-direx::method-package mtd)))
    (when pkg (plsense-direx::package-file pkg))))

(defmethod plsense-direx::update-location ((mtd plsense-direx::method))
  (let* ((mtdnm (direx:tree-name mtd))
         (pkg (plsense-direx::method-package mtd))
         (pkgnm (plsense-direx::package-string pkg))
         (umtd (progn (plsense-direx--trace "start update location of %s::%s" pkgnm mtdnm)
                      (when (plsense-direx::update-location pkg)
                        (plsense-direx::make-method-by-name mtdnm pkg pkgnm)))))
    (when umtd
      (setf (plsense-direx::method-line mtd) (plsense-direx::method-line umtd))
      (setf (plsense-direx::method-column mtd) (plsense-direx::method-column umtd))
      (plsense-direx--trace "updated location of %s::%s" pkgnm mtdnm)
      t)))


(defsubst* plsense-direx::make-package (&key name file line column mock)
  (plsense-direx--trace "make package : name[%s] file[%s] line[%s] col[%s]" name file line column)
  (multiple-value-bind (shortnm pkgnm) (cond ((plsense-direx::maybe-main-package-p name)
                                              (let ((dir (directory-file-name (file-name-directory file)))
                                                    (filenm (file-name-nondirectory file)))
                                                (list (format "%s - %s" filenm dir) (format "main[%s]" file))))
                                             ((and (not plsense-direx::tree-flat-p)
                                                   (string-match "\\`.+::\\([^:]+\\)\\'" name))
                                              (list (match-string-no-properties 1 name) name))
                                             (t
                                              (list name name)))
      (make-instance 'plsense-direx::package
                     :name shortnm
                     :string pkgnm
                     :file file
                     :line line
                     :column column
                     :flat plsense-direx::tree-flat-p
                     :mock mock)))

(defsubst plsense-direx::make-package-by-explore (str &optional mock)
  (when (string-match "\\`[^ \t\r\n]" str)
    (plsense-direx--trace "start make package by explore : %s" str)
    (let* ((e (split-string str " "))
           (pkgnm (when e (pop e)))
           (filepath (loop with ret = ""
                           while (> (length e) 1)
                           if (not (string= ret ""))
                           do (setq ret (concat ret " "))
                           do (setq ret (concat ret (pop e)))
                           finally return ret))
           (e (when e (split-string (pop e) ":")))
           (line (when e (string-to-number (pop e))))
           (col (when e (string-to-number (pop e)))))
      (when pkgnm
        `(,pkgnm . ,(plsense-direx::make-package :name pkgnm
                                                 :file filepath
                                                 :line line
                                                 :column col
                                                 :mock mock))))))

(defun plsense-direx::make-package-by-name (pkgnm &optional explore-results)
  (plsense-direx--trace "start make package by name. pkgnm[%s] explore-results[%s]" pkgnm explore-results)
  (when (and (stringp pkgnm)
             (not (string= pkgnm "")))
    (or (loop for str in (or explore-results
                             (plsense-direx::get-own-explore-results pkgnm))
              for pkg-cons = (plsense-direx::make-package-by-explore str)
              if pkg-cons return (cdr pkg-cons))
        (when plsense-direx::use-root-cache
          ;; If failed to make from cache, retry without cache.
          (let ((plsense-direx::use-root-cache nil))
            (plsense-direx::clear-explore-cache pkgnm)
            (plsense-direx::make-package-by-name pkgnm))))))

(defmethod direx:tree-equals ((x plsense-direx::package) y)
  (or (eq x y)
      (and (typep y 'plsense-direx::package)
           (equal (plsense-direx::package-string x) (plsense-direx::package-string y)))))

(defmethod direx:node-children ((pkg plsense-direx::package))
  (let* ((pkgnm (plsense-direx::package-string pkg))
         (loc-alist (append
                     ;; Get methods
                     (when (not (plsense-direx::package-mock-p pkg))
                       (loop for str in (plsense-direx::get-own-explore-results pkgnm)
                             for mtd-cons = (plsense-direx::make-method-by-explore str pkg pkgnm)
                             if mtd-cons collect mtd-cons))
                     ;; Get child packages
                     (when (not (plsense-direx::package-flat pkg))
                       (sort (loop with founds = nil
                                   for c in (append
                                             (loop for str in (plsense-direx::get-child-explore-results pkgnm)
                                                   for child-cons = (plsense-direx::make-package-by-explore str)
                                                   if child-cons collect child-cons)
                                             (loop for str in (plsense-direx::get-mock-child-explore-results pkgnm)
                                                   for child-cons = (plsense-direx::make-package-by-explore str t)
                                                   if child-cons collect child-cons))
                                   for childnm = (when c (car c))
                                   if (and childnm
                                           (not (member childnm founds)))
                                   collect (progn (push childnm founds) c))
                             (lambda (c1 c2) (string< (car-safe c1) (car-safe c2))))))))
    (loop for c in loc-alist
          for child = (when c (cdr c))
          if child collect child)))

(defmethod direx:node-contains ((pkg plsense-direx::package) loc)
  (let ((pkgnm1 (plsense-direx::package-string pkg))
        (pkgnm2 (plsense-direx::get-location-package loc)))
    (when (and pkgnm1 pkgnm2)
      (if (plsense-direx::package-flat pkg)
          (string= pkgnm1 pkgnm2)
        (direx:starts-with pkgnm2 pkgnm1)))))

(defmethod plsense-direx::get-location-address ((pkg plsense-direx::package))
  (plsense-direx::package-string pkg))

(defmethod plsense-direx::get-location-line ((pkg plsense-direx::package))
  (plsense-direx::package-line pkg))

(defmethod plsense-direx::get-location-column ((pkg plsense-direx::package))
  (plsense-direx::package-column pkg))

(defmethod plsense-direx::get-location-package ((pkg plsense-direx::package))
  (plsense-direx::package-string pkg))

(defmethod plsense-direx::get-location-package-symbol ((pkg plsense-direx::package))
  (let ((pkgnm (plsense-direx::package-string pkg)))
    (if (and pkgnm (plsense-direx::maybe-main-package-p pkgnm))
        "main"
      pkgnm)))

(defmethod plsense-direx::get-location-file ((pkg plsense-direx::package))
  (plsense-direx::package-file pkg))

(defmethod plsense-direx::update-location ((pkg plsense-direx::package))
  (if (plsense-direx::package-mock-p pkg)
      t
    (let* ((plsense-direx::tree-flat-p (plsense-direx::package-flat pkg))
           (pkgnm (plsense-direx::package-string pkg))
           (upkg (progn (plsense-direx--trace "start update location of %s" pkgnm)
                        (plsense-direx::clear-explore-cache pkgnm)
                        (plsense-direx::make-package-by-name pkgnm)))
           (ufpath (when upkg (plsense-direx::package-file upkg))))
      (when (and ufpath
                 (file-exists-p ufpath))
        (setf (plsense-direx::package-file pkg)   ufpath)
        (setf (plsense-direx::package-line pkg)   (plsense-direx::package-line upkg))
        (setf (plsense-direx::package-column pkg) (plsense-direx::package-column upkg))
        (plsense-direx--trace "updated location of %s" pkgnm)
        t))))


;;;;;;;;;;;;;;;;
;; Tree Items

(defvar plsense-direx::root-items nil)

(defun plsense-direx::find-package-file (loc not-this-window)
  (let* ((addr (plsense-direx::get-location-address loc))
         (buff (progn (plsense-direx--trace "start find location : %s" addr)
                      (plsense-direx::goto-location loc)))
         (fpath (when buff (buffer-file-name buff))))
    (when fpath
      (if not-this-window
          (find-file-other-window fpath)
        (find-file fpath)))))

(defun plsense-direx::display-package-file (loc)
  (let* ((addr (plsense-direx::get-location-address loc))
         (buff (progn (plsense-direx--trace "start display location : %s" addr)
                      (plsense-direx::goto-location loc))))
    (when buff
      (display-buffer buff))))


(defclass plsense-direx::item (direx:item) ())

(defmethod direx:generic-find-item ((item plsense-direx::item) not-this-window)
  (plsense-direx::find-package-file (direx:item-tree item) not-this-window))

(defmethod direx:generic-display-item ((item plsense-direx::item))
  (plsense-direx::display-package-file (direx:item-tree item)))

(defmethod direx:make-item ((pkg plsense-direx::package) parent)
  (make-instance 'plsense-direx::item
                 :tree pkg
                 :parent parent
                 :face 'plsense-direx:regular-package-face))

(defmethod direx:make-item ((mtd plsense-direx::method) parent)
  (make-instance 'plsense-direx::item
                 :tree mtd
                 :parent parent
                 :face 'plsense-direx:regular-method-face))

(defmethod direx:item-refresh ((item plsense-direx::item))
  (let* ((loc (direx:item-tree item))
         (pkgnm (when loc (plsense-direx::get-location-package loc)))
         (addr (when loc (plsense-direx::get-location-address loc))))
    (plsense-direx--trace "start direx:item-refresh of %s" addr)
    (yaxception:$~
      (yaxception:try
        ;; Clear cache
        (plsense-direx::clear-explore-cache pkgnm)
        ;; Init child
        (loop for child in (direx:item-children item)
              do (direx:item-delete-recursively child))
        (setf (direx:item-children item) nil)
        ;; Update myself
        (when (plsense-direx::update-location loc)
          (when (direx:item-open item)
            (direx:item-expand item))
          (plsense-direx--trace "finished direx:item-refresh of %s" addr)
          t))
      (yaxception:catch 'error e
        (plsense-direx--error "failed direx:item-refresh of %s : %s" addr (yaxception:get-text e))
        (yaxception:throw e)))))


;;;;;;;;;;;;;;;;;;
;; Setup Buffer

(defvar plsense-direx::active-p nil)

(defun plsense-direx::setup-keymap ()
  (local-set-key (kbd "?") 'plsense-direx:display-help))

(defun plsense-direx::sort-root-item (i1 i2)
  (let* ((loc1 (direx:item-tree i1))
         (loc2 (direx:item-tree i2))
         (face1 (direx:item-face i1))
         (face2 (direx:item-face i2))
         (treenm1 (direx:tree-name loc1))
         (treenm2 (direx:tree-name loc2))
         (main1 (plsense-direx::maybe-main-package-p (plsense-direx::get-location-package loc1) t))
         (main2 (plsense-direx::maybe-main-package-p (plsense-direx::get-location-package loc2) t)))
    (if (eq face1 face2)
        (cond ((and main1 main2) (string< main1 main2))
              (main1             nil)
              (main2             t)
              (t                 (string< treenm1 treenm2)))
      (case face1
        (plsense-direx:regular-package-face  nil)
        (plsense-direx:included-package-face t)
        (plsense-direx:parent-package-face   (case face2
                                               (plsense-direx:regular-package-face t)
                                               (t                                  nil)))))))

(defun plsense-direx::get-root-item-package-names (&optional buff)
  (with-current-buffer (or buff (current-buffer))
    (loop for item in plsense-direx::root-items
          collect (plsense-direx::get-location-package (direx:item-tree item)))))

(defun plsense-direx::add-root-into-buffer (rootnode &optional buff face)
  (with-current-buffer (or buff (current-buffer))
    (let ((rootaddr (plsense-direx::get-location-address rootnode))
          (rootitem (direx:make-item rootnode nil))
          (buffer-read-only nil))
      (plsense-direx--trace "start add root:'%s' into buffer:'%s' with face:%s" rootaddr (buffer-name) face)
      (when face (setf (direx:item-face rootitem) face))
      (setq direx:root-item rootitem)
      ;; Update the list of root item
      (push rootitem plsense-direx::root-items)
      (setq plsense-direx::root-items
            (sort plsense-direx::root-items 'plsense-direx::sort-root-item))
      ;; Go to insert point
      (goto-char (loop with pt = 1
                       for item in plsense-direx::root-items
                       for currloc = (direx:item-tree item)
                       if (direx:tree-equals currloc rootnode)
                       return pt
                       else
                       do (setq pt (or (direx:item-end item)
                                       (point-max)))))
      ;; Insert
      (direx:item-insert rootitem)
      (direx:move-to-item-name-part rootitem)
      rootitem)))

(defun plsense-direx::get-close-item-of-location (loc)
  (or (loop with item = (direx:item-at-point)
            for currloc = (when item (direx:item-tree item))
            while currloc
            if (and (typep currloc 'direx:node)
                    (direx:node-contains currloc loc))
            return item
            else
            do (setq item (direx:item-parent item)))
      (loop for item in plsense-direx::root-items
            for currloc = (when item (direx:item-tree item))
            if (and (typep currloc 'direx:node)
                    (direx:node-contains currloc loc))
            return item)))

(defun plsense-direx::down-to-location (loc &optional fromitem noerror)
  (let* ((locaddr (plsense-direx::get-location-address loc))
         (fromitem (or fromitem (direx:item-at-point)))
         (fromloc (when fromitem (direx:item-tree fromitem)))
         (fromaddr (when fromloc (plsense-direx::get-location-address fromloc)))
         (failed (lambda ()
                   (when (not noerror)
                     (plsense-direx--warn "failed down to location : %s -> %s" fromaddr locaddr)
                     (plsense-direx::show-message "Item not found")))))
    (plsense-direx--trace "down to location : %s -> %s" fromaddr locaddr)
    (when fromaddr
      (cond ((direx:tree-equals fromloc loc)
             ;; The location is found
             (plsense-direx--trace "found location : %s" locaddr)
             (loop with parent = (direx:item-parent fromitem)
                   while parent
                   ;; The tree of the location might be hidden
                   do (direx:item-ensure-open parent)
                   do (setq parent (direx:item-parent parent)))
             (plsense-direx--info "finished down to location : %s" locaddr)
             (direx:move-to-item-name-part fromitem)
             t)
            ((direx:node-contains fromloc loc)
             ;; The parent is found
             (plsense-direx--trace "found parent node : %s" fromaddr)
             (direx:move-to-item-name-part fromitem)
             (direx:item-ensure-open fromitem)
             (loop for child in (direx:item-children fromitem)
                   if (plsense-direx::down-to-location loc child t)
                   return t
                   finally (funcall failed)))
            (t
             (funcall failed))))))

(defun plsense-direx::get-buffer (bufftype projnm &optional force-create no-create)
  (let ((buffnm (format "*PlSense DirEX[%s] %s*" bufftype projnm)))
    (direx:awhen (and force-create
                      (get-buffer buffnm))
      (kill-buffer it))
    (or (get-buffer buffnm)
        (when (not no-create)
          (with-current-buffer (generate-new-buffer buffnm)
            (plsense-direx--trace "generated new buffer : %s" (buffer-name))
            (direx:direx-mode)
            (plsense-direx::setup-keymap)
            (set (make-local-variable 'plsense-direx::active-p) t)
            (set (make-local-variable 'plsense-direx::current-project) projnm)
            (set (make-local-variable 'plsense-direx::root-items) nil)
            (current-buffer))))))

(defun plsense-direx::update-buffer-for-location (buff pkgnm)
  (or (not buff)
      (not (buffer-live-p buff))
      (not pkgnm)
      (with-current-buffer buff
        (plsense-direx--trace "start update buffer for location. buff[%s] pkgnm[%s]" (buffer-name) pkgnm)
        (let* ((pkg (plsense-direx::make-package-by-name pkgnm))
               (item (when pkg
                       (save-excursion
                         (direx:awhen (plsense-direx::get-close-item-of-location pkg)
                           (when (plsense-direx::down-to-location pkg it)
                             (direx:item-at-point)))))))
          (when (and item
                     (direx:item-refresh item))
            (plsense-direx--trace "updated buffer[%s] for pkgnm[%s]" (buffer-name) pkgnm)
            t)))))

(defsubst plsense-direx::update-item-face (item face &optional buff)
  (with-current-buffer (or buff (current-buffer))
    (save-excursion
      (let ((startpt (direx:item-start item)))
        (direx:item-delete item)
        (setf (direx:item-face item) face)
        (goto-char startpt)
        (direx:item-insert item)
        t))))


;;;;;;;;;;;;;;;
;; Fix Direx

(defadvice direx:item-refresh-recursively (around plsense-direx:fix activate)
  (if (not plsense-direx::active-p)
      ad-do-it
    (direx:item-refresh (ad-get-arg 0))))

(defadvice direx:refresh-whole-tree (around plsense-direx:fix activate)
  (if (not plsense-direx::active-p)
      ad-do-it
    (let* ((plsense-direx::use-root-cache t)
           (item (or (ad-get-arg 0)
                     (direx:item-at-point)))
           (loc (when item (direx:item-tree item))))
      (loop for root in plsense-direx::root-items
            if (not (direx:item-refresh root))
            do (progn (direx:item-delete-recursively root)
                      (setq plsense-direx::root-items
                            (delq root plsense-direx::root-items))))
      (when loc
        (plsense-direx::down-to-location loc (plsense-direx::get-close-item-of-location loc))))))


;;;;;;;;;;;;;;;;;;;
;; User Function

;;;###autoload
(defun plsense-direx:get-explorer (projnm &optional force-create no-create)
  "Return the buffer of package explorer for PROJNM."
  (plsense-direx--trace "start get explorer. projnm[%s]" projnm)
  (plsense-direx::get-buffer "E" projnm force-create no-create))

;;;###autoload
(defun plsense-direx:get-referer (projnm &optional force-create no-create)
  "Return the buffer of package referer for PROJNM."
  (plsense-direx--trace "start get referer. projnm[%s]" projnm)
  (plsense-direx::get-buffer "R" projnm force-create no-create))

(yaxception:deferror 'plsense-direx:illegal-pkg-error nil "[PLSENSE-DIREX] '%s' is illegal package" 'pkg)

;;;###autoload
(defun plsense-direx:get-explorer-with-open-location (projnm pkgnm &optional mtdnm)
  "Return the buffer of package explorer for PROJNM with open location of PKGNM/MTDNM."
  (plsense-direx--trace "start get explorer with open location. projnm[%s] pkgnm[%s] mtdnm[%s]"
                        projnm pkgnm mtdnm)
  (yaxception:$~
    (yaxception:try
      (let* ((buff (plsense-direx:get-explorer projnm))
             (plsense-direx::use-root-cache t)
             (plsense-direx::current-project projnm)
             (exrets (plsense-direx::get-own-explore-results pkgnm))
             (pkg (plsense-direx::make-package-by-name pkgnm exrets))
             (loc (cond (mtdnm (plsense-direx::make-method-by-name mtdnm pkg pkgnm exrets))
                        (t     pkg)))
             (addr (plsense-direx::build-address pkgnm mtdnm))
             (rootpkgnm (plsense-direx::get-root-package-name pkgnm)))
        (when (not loc)
          (yaxception:throw 'plsense-direx:illegal-pkg-error :pkg pkgnm))
        (with-current-buffer buff
          (plsense-direx--trace "try to open location : %s" addr)
          (or
           ;; First, try from already root item list
           (loop for root in plsense-direx::root-items
                 if (plsense-direx::down-to-location loc root t) return t)
           ;; Next, if current root item is new, try from it
           (direx:awhen (and (not (member rootpkgnm (plsense-direx::get-root-item-package-names)))
                             (plsense-direx::make-package-by-name rootpkgnm))
             (direx:awhen (plsense-direx::add-root-into-buffer it buff)
               (plsense-direx::down-to-location loc it t)))
           ;; Last, try from resumed item after refresh it
           (direx:awhen (direx:item-at-point)
             (let ((plsense-direx::use-root-cache nil))
               (and (direx:item-refresh it)
                    (plsense-direx::down-to-location loc it))))))
        (plsense-direx--trace "got explorer with open location. projnm[%s] pkgnm[%s] mtdnm[%s]"
                              projnm pkgnm mtdnm)
        buff))
    (yaxception:catch 'error e
      (plsense-direx--error "failed get explorer with open location : %s" (yaxception:get-text e))
      (yaxception:throw e))))

;;;###autoload
(defun plsense-direx:get-referer-with-open-location (projnm pkgnm &optional mtdnm)
  "Return the buffer of package referer for PROJNM with open location of PKGNM/MTDNM."
  (plsense-direx--trace "start get referer with open location. projnm[%s] pkgnm[%s] mtdnm[%s]"
                        projnm pkgnm mtdnm)
  (yaxception:$~
    (yaxception:try
      (let* ((buff (plsense-direx:get-referer projnm t))
             (plsense-direx::use-root-cache t)
             (plsense-direx::tree-flat-p t)
             (plsense-direx::current-project projnm)
             (exrets (plsense-direx::get-own-explore-results pkgnm))
             (pkg (plsense-direx::make-package-by-name pkgnm exrets))
             (loc (cond (mtdnm (plsense-direx::make-method-by-name mtdnm pkg pkgnm exrets))
                        (t     pkg)))
             (addr (plsense-direx::build-address pkgnm mtdnm))
             (parentnms (loop for str in exrets
                              if (string-match "\\`  > \\([^ \t\r\n]+\\)" str)
                              collect (match-string-no-properties 1 str)))
             (usingnms (loop for str in exrets
                              if (string-match "\\`  < \\([^ \t\r\n]+\\)" str)
                              collect (match-string-no-properties 1 str)))
             alreadys selfitem)
        (when (not loc)
          (yaxception:throw 'plsense-direx:illegal-pkg-error :pkg pkgnm))
        (with-current-buffer buff
          (plsense-direx--trace "start setup buffer : self:%s parent:%s using:%s" pkgnm parentnms usingnms)
          (loop for npkgnm in (append (list pkgnm) parentnms usingnms)
                if (not (member npkgnm alreadys))
                do (let* ((npkg (if (string= npkgnm pkgnm)
                                    pkg
                                  (plsense-direx::make-package-by-name npkgnm)))
                          (nface (cond ((member npkgnm parentnms) 'plsense-direx:parent-package-face)
                                       ((member npkgnm usingnms)  'plsense-direx:included-package-face)))
                          (nitem (plsense-direx::add-root-into-buffer npkg buff nface)))
                     (push npkgnm alreadys)
                     (when nitem
                       (when (string= npkgnm pkgnm) (setq selfitem nitem))
                       (when (and (not (member npkgnm usingnms))
                                  mtdnm)
                         (direx:item-expand nitem)
                         (loop for mtd in (direx:item-children nitem)
                               for currmtdnm = (direx:tree-name (direx:item-tree mtd))
                               if (not (string= currmtdnm mtdnm))
                               do (direx:item-hide mtd))))))
          (when selfitem
            (or (plsense-direx::down-to-location loc selfitem t)
                (let ((plsense-direx::use-root-cache nil))
                  (when (direx:item-refresh selfitem)
                    (plsense-direx::down-to-location loc selfitem))))))
        (plsense-direx--trace "got referer with open location. projnm[%s] pkgnm[%s] mtdnm[%s]"
                              projnm pkgnm mtdnm)
        buff))
    (yaxception:catch 'error e
      (plsense-direx--error "failed get referer with open location : %s" (yaxception:get-text e))
      (yaxception:throw e))))

;;;###autoload
(defun plsense-direx:update-explorer (projnm pkgnm)
  "Update the buffer of package explorer for PROJNM about PKGNM."
  (yaxception:$~
    (yaxception:try
      (plsense-direx--trace "start update explorer. projnm[%s] pkgnm[%s]" projnm pkgnm)
      (plsense-direx::update-buffer-for-location (plsense-direx:get-explorer projnm nil t) pkgnm))
    (yaxception:catch 'error e
      (plsense-direx--error "failed update explorer : %s" (yaxception:get-text e))
      (yaxception:throw e))))

;;;###autoload
(defun plsense-direx:update-referer (projnm pkgnm)
  "Update the buffer of package referer for PROJNM about PKGNM."
  (yaxception:$~
    (yaxception:try
      (plsense-direx--trace "start update referer. projnm[%s] pkgnm[%s]" projnm pkgnm)
      (let ((plsense-direx::tree-flat-p t))
        (plsense-direx::update-buffer-for-location (plsense-direx:get-referer projnm nil t) pkgnm)))
    (yaxception:catch 'error e
      (plsense-direx--error "failed update referer : %s" (yaxception:get-text e))
      (yaxception:throw e))))

;;;###autoload
(defun plsense-direx:find-explorer-no-select ()
  "Find the buffer of package explorer matched cursor location without display."
  (yaxception:$~
    (yaxception:try
      (if (not (plsense--active-p))
          (plsense-direx::show-message "Not available buffer : %s" (buffer-name))
        (plsense--try-to-ready)
        (if (not (plsense--ready-p))
            (plsense-direx::show-message "Not yet ready current buffer")
          (multiple-value-bind (projnm pkgnm mtdnm) (plsense-direx::get-current-parsed-location)
            (when pkgnm
              (plsense-direx:get-explorer-with-open-location projnm pkgnm mtdnm))))))
    (yaxception:catch 'error e
      (plsense-direx--error "failed find explorer : %s" (yaxception:get-text e))
      (yaxception:throw e))))

;;;###autoload
(defun plsense-direx:find-referer-no-select ()
  "Find the buffer of package referer matched cursor location without display."
  (yaxception:$~
    (yaxception:try
      (if (not (plsense--active-p))
          (plsense-direx::show-message "Not available buffer : %s" (buffer-name))
        (plsense--try-to-ready)
        (if (not (plsense--ready-p))
            (plsense-direx::show-message "Not yet ready current buffer")
          (multiple-value-bind (projnm pkgnm mtdnm) (plsense-direx::get-current-parsed-location)
            (when pkgnm
              (plsense-direx:get-referer-with-open-location projnm pkgnm mtdnm))))))
    (yaxception:catch 'error e
      (plsense-direx--error "failed find referer : %s" (yaxception:get-text e))
      (yaxception:throw e))))

;;;###autoload
(defun plsense-direx:config-default ()
  "Do setting recommemded configuration."
  (loop for mode in plsense-enable-modes
        for hook = (intern-soft (concat (symbol-name mode) "-hook"))
        do (add-to-list 'ac-modes mode)
        if (and hook
                (symbolp hook))
        do (add-hook hook 'plsense-direx:setup-current-buffer t))
  (add-hook 'after-save-hook 'plsense-direx:update-current-package t))


;;;;;;;;;;;;;;;;;;
;; User Command

;;;###autoload
(defun plsense-direx:open-explorer (&optional other-window)
  "Open perl package explorer."
  (interactive "P")
  (direx:awhen (plsense-direx:find-explorer-no-select)
    (if other-window
        (switch-to-buffer-other-window it)
      (switch-to-buffer it))))

;;;###autoload
(defun plsense-direx:open-explorer-other-window ()
  "Open perl package explorer in other window."
  (interactive)
  (plsense-direx:open-explorer t))

;;;###autoload
(defun plsense-direx:open-referer (&optional other-window)
  "Open perl package referer."
  (interactive "P")
  (direx:awhen (plsense-direx:find-referer-no-select)
    (if other-window
        (switch-to-buffer-other-window it)
      (switch-to-buffer it))))

;;;###autoload
(defun plsense-direx:open-referer-other-window ()
  "Open perl package referer in other window."
  (interactive)
  (plsense-direx:open-referer t))

;;;###autoload
(defun plsense-direx:display-help ()
  "Display help buffer about the node/leaf of cursor location."
  (interactive)
  (yaxception:$~
    (yaxception:try
      (let* ((item (or (direx:item-at-point)
                       (plsense-direx::show-message "Item not found from current point.")))
             (loc (when item (direx:item-tree item)))
             (pkgnm (when loc (plsense-direx::get-location-package loc)))
             (mtdnm (when (typep loc 'plsense-direx::method) (direx:tree-name loc)))
             (cmdstr (when (not (plsense-direx::maybe-main-package-p pkgnm))
                       (cond (mtdnm (concat "subhelp " mtdnm " " pkgnm))
                             (pkgnm (concat "modhelp " pkgnm)))))
             (doc (when cmdstr
                    (plsense--get-server-response cmdstr :waitsec 4 :force t :ignore-done t)))
             (buff (plsense--get-help-buffer doc)))
        (when (buffer-live-p buff)
          (display-buffer buff))))
    (yaxception:catch 'error e
      (plsense-direx::show-message "Failed display help : %s" (yaxception:get-text e))
      (plsense-direx--error "failed display help : %s" (yaxception:get-text e)))))

;;;###autoload
(defun plsense-direx:update-current-package ()
  "Update the package of cursor location in Perl buffer."
  (interactive)
  (yaxception:$~
    (yaxception:try
      (when (and (plsense--active-p)
                 (plsense--ready-p))
        (plsense-direx--trace "start update current package")
        (multiple-value-bind (projnm pkgnm mtdnm) (plsense-direx::get-current-parsed-location)
          (when pkgnm
            (when (and (plsense-direx:update-explorer projnm pkgnm)
                       (plsense-direx:update-referer projnm pkgnm))
              (plsense-direx--trace "updated current package : %s" pkgnm)
              t)))))
    (yaxception:catch 'error e
      (plsense-direx::show-message "Failed update current package : %s" (yaxception:get-text e))
      (plsense-direx--error "failed update current package : %s" (yaxception:get-text e)))))

;;;###autoload
(defun plsense-direx:setup-current-buffer ()
  "Do setup for using plsense-direx in current buffer."
  (interactive)
  (yaxception:$~
    (yaxception:try
      (when (plsense--active-p)
        ;; Key binding
        (loop for e in `((,plsense-direx:open-explorer-key              . plsense-direx:open-explorer)
                         (,plsense-direx:open-explorer-other-window-key . plsense-direx:open-explorer-other-window)
                         (,plsense-direx:open-referer-key               . plsense-direx:open-referer)
                         (,plsense-direx:open-referer-other-window-key  . plsense-direx:open-referer-other-window))
              for key = (car e)
              for cmd = (cdr e)
              if (and (stringp key)
                      (not (string= key "")))
              do (local-set-key (read-kbd-macro key) cmd))
        (plsense-direx--info "finished setup for %s" (current-buffer))))
    (yaxception:catch 'error e
      (plsense-direx::show-message "Failed setup current buffer : %s" (yaxception:get-text e))
      (plsense-direx--error "failed setup current buffer : %s" (yaxception:get-text e)))))


(provide 'plsense-direx)
;;; plsense-direx.el ends here
