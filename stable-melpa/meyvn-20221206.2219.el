;;; meyvn.el --- Meyvn client                  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Daniel Szmulewicz

;; Author: Daniel Szmulewicz <daniel.szmulewicz@gmail.com>
;; Created: 2020-02-11
;; URL: https://github.com/danielsz/meyvn-el
;; Package-Version: 20221206.2219
;; Package-Commit: 493e652b8fffcbed226f69a2ea82e6f9fc51ab08
;; Version: 1.1
;; Package-Requires: ((emacs "25.1") (cider "0.23") (projectile "2.1") (s "1.12") (dash "2.17") (parseedn "1.1.0") (parseclj "1.1.0") (geiser "0.12"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;; This package provides an Emacs client for the Meyvn build tool, https://meyvn.org

;; To use this package, simply add the following code snippet in your init.el

;; Changelog: Kawa Geiser support.

;;   (add-hook 'cider-mode-hook #'meyvn-setup)

;;; Code:

(require 'cider)
(require 'cider-classpath)
(require 'cider-ns)
(require 'projectile)
(require 's)
(require 'dash)
(require 'parseclj)
(require 'parseedn)
(require 'geiser)

(defun meyvn-get-repl-port (dir)
  "Find repl port in DIR."
  (let ((file (expand-file-name ".nrepl-port" dir)))
    (with-temp-buffer
      (insert-file-contents file)
      (buffer-string))))

(defun meyvn-read-repl-port (dir)
  "Get repl port from meyvn config in DIR."
  (let ((conf (meyvn-read-conf (expand-file-name "meyvn.edn" dir))))
    (ignore-errors
      (thread-last conf
	(gethash :interactive)
	(gethash :repl-port)))))

;;;###autoload
(defun meyvn-connect (arg)
  "Connect to nREPL.

EDN configuration will be read from project root or in the
directory of the current buffer if ARG (command prefix) is
supplied."
  (interactive "p")
  (let* ((dir (if (= arg 4)
		 default-directory
	       (projectile-project-root)))
	(port (if (eq :auto (meyvn-read-repl-port dir))
		  (meyvn-get-repl-port dir)
		(meyvn-read-repl-port dir))))
    (cider-connect-clj `(:host "localhost" :port ,port))
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
						     (message "System var: %s" value))
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
    (message "Found %d %s" count "properties in the environment.")))

(defun meyvn-geiser (dir)
  "Connect to a Kawa repl with geiser in DIR."
  (let* ((port (if (eq :auto (meyvn-read-repl-port dir))
		  (meyvn-get-repl-port dir)
		(meyvn-read-repl-port dir)))
	 (kawa-port (number-to-string (1+ (string-to-number port))))
	 (count 0))
    (while (and (< count 10)
		(not (zerop (call-process "lsof" nil nil nil (concat "-i:" kawa-port)))))
      (sleep-for 0.1)
      (setq count (1+ count)))
    (geiser-connect 'kawa "localhost" kawa-port)))

(defun meyvn-nrepl-session-init ()
  "Will notify the Meyvn nREPL middleware that we're ready to go."
  (interactive)
  (cider-ensure-connected)
  (let ((resp (nrepl-send-sync-request '("op" "meyvn-init") (cider-current-connection))))
    (message (nrepl-dict-get resp "value"))))

;; Reload system on file change

(defun meyvn-read-conf (filename)
  "Parse FILENAME as a Meyvn config and return an Emacs Lisp data structure."
  (with-temp-buffer
    (insert-file-contents filename)
    (car (parseedn-read))))

(defun meyvn-project-p ()
  "Does a Meyvn config exist?"
  (when-let ((dir (projectile-project-root)))
    (file-exists-p (expand-file-name "meyvn.edn" dir))))

(defun meyvn-system-enabled-p ()
  "Is system enabled in Meyvn config?"
  (let ((conf (meyvn-read-conf (expand-file-name "meyvn.edn" (projectile-project-root)))))
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
    (let* ((conf (meyvn-read-conf (expand-file-name "meyvn.edn" (projectile-project-root))))
	   (reload-enabled-p (thread-last conf
			       (gethash :interactive)
			       (gethash :reload-on-save))))
      (when reload-enabled-p (cider-ns-reload)))))

(defun meyvn-system-reload ()
  "Reload or restart system if conditions apply."
  (when (and (eq major-mode 'clojure-mode) (meyvn-project-p) (meyvn-system-enabled-p) (meyvn-clj-suffix-p))
    (cider-ensure-connected)
    (let* ((conf (meyvn-read-conf (expand-file-name "meyvn.edn" (projectile-project-root))))
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

(defun meyvn-portal ()
  "Toggle Portal inspector."
  (interactive)
  (cider-ensure-connected)
  (cider-ensure-op-supported "meyvn-portal")
  (let ((resp (nrepl-send-sync-request '("op" "meyvn-portal") (cider-current-connection))))
    (message (nrepl-dict-get resp "value"))))

(defun meyvn-flowstorm ()
  "Toggle Flowstorm debugger."
  (interactive)
  (cider-ensure-connected)
  (cider-ensure-op-supported "meyvn-flowstorm")
  (let ((resp (nrepl-send-sync-request '("op" "meyvn-flowstorm") (cider-current-connection))))
    (message (nrepl-dict-get resp "value"))))

(defun meyvn-virgil-dependants ()
  "Show dependants in Portal."
  (interactive)
  (cider-ensure-connected)
  (cider-ensure-op-supported "meyvn-virgil-dependants")
  (let* ((query (file-name-nondirectory (buffer-file-name)))
         (resp (nrepl-send-sync-request `("op" "meyvn-virgil-dependants" "query" ,query) (cider-current-connection))))
    (s-split "\n" (nrepl-dict-get resp "value"))))

(defun meyvn-kawa (arg)
  "Start a Kawa REPL.  ARG determines root directory."
  (interactive "p")
  (cider-ensure-connected)
  (cider-ensure-op-supported "meyvn-kawa")
  (let ((resp (nrepl-send-sync-request '("op" "meyvn-kawa") (cider-current-connection))))
    (when (string= "OK" (car (s-split "\n" (nrepl-dict-get resp "value"))))
      (let ((dir (if (= arg 4)
		     default-directory
		   (projectile-project-root))))
	(meyvn-geiser dir)))))

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

(defun meyvn-deps (arg)
  "Select a library from the Clojars catalog and load in the runtime.

If called with the prefix argument denoted by ARG, will also write to `deps.edn'."
  (interactive "p")
  (let* ((cands (meyvn-catalog))
	 (cand (completing-read "Select a dependency: " cands)))
    (meyvn-candidates cand arg)))

(defun meyvn-candidates (artifact arg)
  "Helper function for meyvn-deps.

Select a library candidate denoted by ARTIFACT and add it to the
runtime.  If ARG indicates that the prefix argument was used,
persist to `deps.edn'."
  (let* ((cands (meyvn-versions artifact))
	 (cand (completing-read "Adding runtime dependency: " cands)))
    (meyvn-add-dep cand)
    (when (= arg 4) (meyvn-persist-dep cand))))

;;;###autoload
(defun meyvn-setup ()
  "Setup `meyvn'."
  (add-hook 'after-save-hook #'meyvn-system-reload)
  (add-hook 'after-save-hook #'meyvn-reload-on-save))

(defun meyvn-teardown ()
  "Teardown `meyvn'."
  (remove-hook 'after-save-hook #'meyvn-system-reload)
  (remove-hook 'after-save-hook #'meyvn-reload-on-save))

;; Transform Boot/Leiningen coordinates to tools.deps format

(defun meyvn-depsify-transform-coords (s)
  "S represents a Maven coordinate."
  (let* ((temp (-> s
		   s-trim
		   (substring-no-properties  1 -1)))
	 (els (s-split " " temp)))
    (concat (car els) " {:mvn/version " (cadr els) "}")))

;;;###autoload
(defun meyvn-depsify (buffer start end)
  "Transforms boot/leiningen coordinates to tools.deps format.
BUFFER is `deps.edn'.  START and END delineates selected text."
  (interactive "BSelect deps.edn buffer: \nr")
  (let* ((selected (-> (buffer-substring-no-properties start end)
		       s-lines)))
    (deactivate-mark)
    (with-current-buffer (get-buffer-create buffer)
      (dolist (line selected)
	(when (s-present? line)
	  (insert (meyvn-depsify-transform-coords line))
	  (newline-and-indent))))))

(provide 'meyvn)
;;; meyvn.el ends here
