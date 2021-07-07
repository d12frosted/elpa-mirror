;;; clojure-quick-repls.el --- Quickly create Clojure and ClojureScript repls for a project.

;; Copyright (C) 2014 symfrog

;; URL: https://github.com/symfrog/clojure-quick-repls
;; Package-Version: 20150814.736
;; Package-Commit: 730311dd3ac4e0aceb0204f818b422017873467f
;; Keywords: languages, clojure, cider, clojurescript
;; Version: 0.2.0-cvs
;; Package-Requires: ((cider "0.8.1") (dash "2.9.0"))

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Quickly create Clojure and ClojureScript repls for a project.
;; Once the repls are created the usual CIDER commands can be used in either a clj/cljs buffer and the forms will be routed automatically via the correct connection.
;; So no need to manually switch connections!

;;; Installation:

;; Available as a package in melpa.org.
;; M-x package-install clojure-quick-repls

;;; Usage:

;;     (require 'clojure-quick-repls)

;;; Code:

(require 'cider)
(require 'dash)

(defcustom clojure-quick-repls-cljs-setup
  "(require 'cljs.repl.browser)
       (cemerick.piggieback/cljs-repl
                    :repl-env (cljs.repl.browser/repl-env :port 9000))"
  "Default form to initialize ClojureScript REPL"
  :type '(string)
  :group 'clojure-quick-repls)

(defvar clojure-quick-repls-nrepl-connected-fn nil)

(defvar clojure-quick-repls-current-buffer nil)
(defvar clojure-quick-repls-nrepl-connect-done nil)

(defvar clojure-quick-repls-clj-con-buf nil)
(defvar clojure-quick-repls-cljs-con-buf nil)

(defun clojure-quick-repls-noop-nrepl-connected-fn  ()
  (fset 'clojure-quick-repls-nrepl-connected-fn (lambda (buf) nil)))

(clojure-quick-repls-noop-nrepl-connected-fn)

(defun clojure-quick-repls-clear-con-bufs ()
  (setq clojure-quick-repls-clj-con-buf nil)
  (setq clojure-quick-repls-cljs-con-buf nil))

(add-hook 'nrepl-connected-hook (lambda ()
                                  (clojure-quick-repls-nrepl-connected-fn clojure-quick-repls-current-buffer)))

(add-hook 'nrepl-disconnected-hook #'clojure-quick-repls-clear-con-bufs)

;;;###autoload
(defun clojure-quick-repls-connect ()
  "Launch Clojure and ClojureScript repls for the current project"
  (interactive)
  (setq clojure-quick-repls-current-buffer (current-buffer))
  (clojure-quick-repls-noop-nrepl-connected-fn)
  (cider-jack-in)

  (clojure-quick-repls-clear-con-bufs)

  (lexical-let* ((cljs-fn (lambda (buf)  
                            (with-current-buffer buf
                              (clojure-quick-repls-noop-nrepl-connected-fn)
                              (if (string= "ex" (cadr (nrepl-sync-request:eval clojure-quick-repls-cljs-setup)))
                                  (message "Failed to initialize cljs connection with form %s" clojure-quick-repls-cljs-setup)
                                (progn
                                  (setq clojure-quick-repls-cljs-con-buf (nrepl-current-connection-buffer))
                                  (message "Clj connection buffer: %s Cljs connection buffer %s" clojure-quick-repls-clj-con-buf clojure-quick-repls-cljs-con-buf)
                                  (message "Cljs browser repl ready")
                                        ; Make the clj buf default after completion 
                                  (nrepl-make-connection-default clojure-quick-repls-clj-con-buf))))))
                 (clj-fn (lambda (buf)
                           (with-current-buffer buf
                             (clojure-quick-repls-noop-nrepl-connected-fn )
                             (fset 'clojure-quick-repls-nrepl-connected-fn cljs-fn)
                             (setq clojure-quick-repls-clj-con-buf (nrepl-current-connection-buffer))
                             (message "Creating nrepl connection for cljs")
                             (clojure-quick-repls-new-repl-connection)))))
    (fset 'clojure-quick-repls-nrepl-connected-fn clj-fn)))

(defun clojure-quick-repls-new-repl-connection ()
  (let* ((host (nrepl-current-host))
         (port (nrepl-extract-port)))
    (message "Creating repl connection to nrepl server  on port %s, host %s" host port)
    (cider-connect host port)))

(defun clojure-quick-repls-bound-truthy-p (s)
  (and (boundp s) (symbol-value s)))

(defun clojure-quick-repls-buffer-extension (buffer)
  (let ((name (buffer-name buffer)))
    (-when-let (p-loc (string-match-p "\\." name))
      (substring name (1+ p-loc) nil))) )

(defun clojure-quick-repls-set-connection (f h)
  (let ((ext (clojure-quick-repls-buffer-extension (current-buffer))))
    (if (and (clojure-quick-repls-bound-truthy-p 'clojure-quick-repls-clj-con-buf)
             (clojure-quick-repls-bound-truthy-p 'clojure-quick-repls-cljs-con-buf)
             ext
             (or (string= ext "clj") (string= ext "boot") (string= ext "cljs")))
        (progn
          (if (string= ext "cljs")
              (nrepl-make-connection-default clojure-quick-repls-cljs-con-buf)
            (nrepl-make-connection-default clojure-quick-repls-clj-con-buf))
          (when f
            (funcall f)))
      (when h
        (funcall h)))))

(defun clojure-quick-repls-switch-to-relevant-repl (arg)
  (interactive)
  (lexical-let ((a arg))
    (clojure-quick-repls-set-connection (lambda () (cider-switch-to-current-repl-buffer a))
                                        (lambda () (cider-switch-to-relevant-repl-buffer a)))))

(if (version< emacs-version "24.4")
    (progn
      (defadvice cider-interactive-eval (before clojure-quick-repls-nrepl-current-session activate)
        (clojure-quick-repls-set-connection nil nil))
      (defadvice cider-tooling-eval (before clojure-quick-repls-nrepl-current-session activate)
        (clojure-quick-repls-set-connection nil nil))
      (defadvice cider-complete-at-point (before clojure-quick-repls-nrepl-current-session activate)
        (clojure-quick-repls-set-connection nil nil)))
  (defun clojure-quick-repls-nrepl-current-session (&optional arg1 arg2 arg3)
    (clojure-quick-repls-set-connection nil nil))
  (advice-add 'cider-interactive-eval :before #'clojure-quick-repls-nrepl-current-session)
  (advice-add 'cider-tooling-eval :before #'clojure-quick-repls-nrepl-current-session)
  (advice-add 'cider-complete-at-point :before #'clojure-quick-repls-nrepl-current-session))

(provide 'clojure-quick-repls)

;;; clojure-quick-repls.el ends here
