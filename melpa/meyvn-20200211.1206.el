;;; meyvn.el --- Emacs meyvn Client                  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Daniel Szmulewicz

;; Author: Daniel Szmulewicz <daniel.szmulewicz@gmail.com>
;; Created: 2020-02-11
;; URL: https://github.com/danielsz/meyvn-el
;; Package-Version: 20200211.1206
;; Package-Commit: 3119214ff45db630789f9371f956d5ac06229b1d
;; Version: 1.0
;; Package-Requires: ((emacs "25.1"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; This package provides an Emacs client for the Meyvn build tool, https://meyvn.org
;;; Code:

(require 'cider-mode)
(require 'cider-classpath)
(require 'projectile)
(require 'ivy)

(defun meyvn-get-repl-port ()
  "Find repl port."
  (let* ((dir (projectile-project-root))
	(file (concat dir ".nrepl-port")))
    (with-temp-buffer (insert-file-contents file)
      (buffer-string))))

(defun meyvn-read-repl-port ()
  "Get repl port from meyvn config."
  (let ((conf (meyvn-read-conf (concat (projectile-project-root) "/meyvn.edn"))))
    (ignore-errors
      (thread-last conf
	(gethash :interactive)
	(gethash :repl-port)))))

;;;###autoload
(defun meyvn-connect ()
  "Connect to nREPL."
  (interactive)
  (let ((port (if (eq :auto (meyvn-read-repl-port))
		  (meyvn-get-repl-port)
		(meyvn-read-repl-port))))
    (cider-connect `(:host "localhost" :port ,port))
    (cider-ensure-op-supported "meyvn-init")
    (meyvn-nrepl-session-init)))

(defun meyvn-classpath ()
  "Show classpath for current project."
  (interactive)
  (cider-ensure-connected)
  (let ((resp (nrepl-send-sync-request '("op" "meyvn-classpath") (cider-current-connection))))
    (with-current-buffer (cider-popup-buffer "*meyvn-classpath*" 'select nil 'ancillary)
      (cider-classpath-list (current-buffer) (split-string (nrepl-dict-get resp "value") " ")))))

(defun meyvn-system-init! ()
  "Init the system."
  (interactive)
  (cider-ensure-connected)
  (nrepl-send-request '("op" "meyvn-system-init")
		      (nrepl-make-response-handler (current-buffer)
						   (lambda (_buffer value)
						     (message (concat "System var: " value)))
						   nil nil nil)
		      (cider-current-connection)))

(defun meyvn-system-go ()
  "Start the system."
  (interactive)
  (cider-ensure-connected)
  (nrepl-send-request '("op" "meyvn-system-go")
		      (nrepl-make-response-handler (current-buffer)
						   (lambda (_buffer value)
						     (let ((msg value))
						       (message msg)))
						   nil nil nil)
		      (cider-current-connection)))

(defun meyvn-system-reset ()
  "Reset the system."
  (interactive)
  (cider-ensure-connected)
  (nrepl-send-request '("op" "meyvn-system-reset")
		      (nrepl-make-response-handler (current-buffer)
						   (lambda (_buffer value)
						     (let ((msg value))
						       (message msg)))
						   nil nil nil)
		      (cider-current-connection)))

(defun meyvn-properties ()
  "Load Meyvn properties."
  (interactive)
  (cider-ensure-connected)
  (let* ((resp (nrepl-send-sync-request '("op" "meyvn-properties") (cider-current-connection)))
	 (report (nrepl-dict-get resp "report"))
	 (count (nrepl-dict-get report "count")))
    (message (concat "Found " (number-to-string count) " properties in the environment."))))

(defun meyvn-nrepl-session-init ()
  "Will notify the Meyvn nREPL middleware that we're ready to go."
  (interactive)
  (cider-ensure-connected)
  (let ((resp (nrepl-send-sync-request '("op" "meyvn-init") (cider-current-connection))))
    (message (nrepl-dict-get resp "value") )))

;; Reload system on file change

(defun meyvn-read-conf (filename)
  "Parse FILENAME as a Meyvn config and return an Emacs Lisp data structure."
  (with-temp-buffer
    (insert-file-contents filename)
    (car (parseedn-read))))

(defun meyvn-project-p ()
  "Does a Meyvn config exists?"
  (when-let ((dir (projectile-project-root)))
    (file-exists-p (concat dir "/meyvn.edn"))))

(defun meyvn-system-enabled-p ()
  "Is system enabled in Meyvn config?"
  (let ((conf (meyvn-read-conf (concat (projectile-project-root) "/meyvn.edn"))))
    (ignore-errors
      (thread-last conf
	(gethash :interactive)
	(gethash :system)
	(gethash :enabled)))))

(defun meyvn-clj-suffix-p ()
  "Is a known suffix?"
  (let ((suffix (file-name-extension buffer-file-name))
	(known '("clj" "cljc")))
    (seq-contains known suffix)))

(defun meyvn-reload-on-save ()
  "In a meyvn repl, reload on file save."
  (when (and (eq major-mode 'clojure-mode) (meyvn-project-p) (meyvn-clj-suffix-p))
    (cider-ensure-connected)
    (let* ((conf (meyvn-read-conf (concat (projectile-project-root) "/meyvn.edn")))
	   (reload-enabled-p (thread-last conf
			       (gethash :interactive)
			       (gethash :reload-on-save))))
      (when reload-enabled-p (cider-ns-reload)))))

(defun meyvn-system-reload ()
  "Reload or restart system if conditions apply."
  (when (and (eq major-mode 'clojure-mode) (meyvn-project-p) (meyvn-system-enabled-p) (meyvn-clj-suffix-p))
    (cider-ensure-connected)
    (let* ((conf (meyvn-read-conf (concat (projectile-project-root) "/meyvn.edn")))
	   (files (thread-last conf
		     (gethash :interactive)
		     (gethash :system)
		     (gethash :restart-on-change)))
	   (buffer (file-name-nondirectory buffer-file-name)))
      (when (seq-contains files buffer)
	(meyvn-system-reset)))))

;; Add dependencies at runtime

(defun meyvn-catalog ()
  "Get catalog from Clojars and Maven Central."
  (cider-ensure-connected)
  (cider-ensure-op-supported "meyvn-catalog")
  (let ((resp (nrepl-send-sync-request '("op" "meyvn-catalog") (cider-current-connection))))
    (s-split "\n" (nrepl-dict-get resp "value"))))

(defun meyvn-versions (artifact)
  "Get available versions of ARTIFACT in repositories."
  (cider-ensure-connected)
  (cider-ensure-op-supported "meyvn-versions")
  (let ((resp (nrepl-send-sync-request `("op" "meyvn-versions" "query" ,artifact) (cider-current-connection))))
    (s-split "\n" (nrepl-dict-get resp "value"))))

(defun meyvn-add-dep (query)
  "Add a dependency denoted by QUERY at runtime."
  (cider-ensure-connected)
  (cider-ensure-op-supported "meyvn-add-dep")
  (nrepl-send-request `("op" "meyvn-add-dep" "query" ,query)
		      (nrepl-make-response-handler (current-buffer)
						   (lambda (_buffer value)
						     (let ((msg value))
						       (message msg)))
						   nil nil nil)
		      (cider-current-connection)))

(defun meyvn-persist-dep (query)
  "Write the dependency denoted by QUERY in `deps.edn'."
  (cider-ensure-connected)
  (cider-ensure-op-supported "meyvn-persist-dep")
  (nrepl-send-request `("op" "meyvn-persist-dep" "query" ,query)
		      (nrepl-make-response-handler (current-buffer)
						   (lambda (_buffer value)
						     (let ((msg value))
						       (message msg)))
						   nil nil nil)
		      (cider-current-connection)))

(defun meyvn-deps ()
  "Load the Clojars libraries."
  (interactive)
  (let ((cands (meyvn-catalog)))
    (ivy-read "Select a dependency: " cands
              :action (lambda (x) (meyvn-candidates x))
              :keymap counsel-describe-map)))

(defun meyvn-candidates (artifact)
  "Select a library candidate denoted by ARTIFACT and add it to the runtime."
  (interactive)
  (let ((cands (meyvn-versions artifact)))
    (ivy-read "Adding runtime dependency: " cands
              :action '(1
			("o" meyvn-add-dep "Add dep at runtime")
			("p" meyvn-persist-dep "Persist to deps.edn"))
              :keymap counsel-describe-map)))

(add-hook 'after-save-hook #'meyvn-system-reload)
(add-hook 'after-save-hook #'meyvn-reload-on-save)

;; Transform Boot/Leiningen coordinates to tools.deps format

(defun meyvn-depsify-transform-coords (s)
  "S represents a Maven coordinate."
  (let* ((temp (-> s
		  s-trim
		  (substring-no-properties  1 -1)))
	(els (s-split " " temp)))
    (concat (car els) " {:mvn/version " (cadr els) "}")))

(defun meyvn-depsify (buffer start end)
  "Transforms boot/leiningen coordinates to tools.deps format.
BUFFER is `deps.edn'.  START and END delineates selected text."
  (interactive "BSelect deps.edn buffer: \nr")
  (let* ((selected (-> (buffer-substring-no-properties start end)
		       s-lines)))
    (deactivate-mark)
    (with-current-buffer (get-buffer-create buffer)
      (dolist (line selected)
	(when (not (s-blank? line))
	  (insert (meyvn-depsify-transform-coords line))
	  (newline-and-indent))))))

(provide 'meyvn)
;;; meyvn.el ends here
