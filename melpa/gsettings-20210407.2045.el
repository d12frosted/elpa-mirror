;;; gsettings.el --- GSettings (Gnome) helpers -*- lexical-binding: t; -*-

;; Author: wouter bolsterlee <wouter@bolsterl.ee>
;; Keywords: languages
;; Package-Version: 20210407.2045
;; Package-Commit: 9f9fb1fe946bbba46307c26355f355225ea7262a
;; URL: https://github.com/wbolster/emacs-gsettings
;; Package-Requires: ((emacs "24.3") (dash "2.16.0") (gvariant "1.0.0") (s "1.12.0"))
;; Version: 1.0.0

;; Copyright 2019 wouter bolsterlee. Licensed under the BSD-3-clause license.

;;; Commentary:

;; This package provides helpers for Gnome GSettings.
;;
;; Examples:
;;
;;   (gsettings-available?)
;;   (gsettings-list-schemas)
;;   (gsettings-schema-exists? "org.gnome.desktop.interface")
;;   (gsettings-list-keys "org.gnome.desktop.interface")
;;   (gsettings-get "org.gnome.desktop.interface" "font-name")
;;   (gsettings-get "org.gnome.desktop.interface" "cursor-blink")
;;   (gsettings-get "org.gnome.desktop.interface" "cursor-size")
;;   (gsettings-get "org.gnome.desktop.interface" "this-fails")
;;   (gsettings-set-from-gvariant-string "org.gnome.desktop.interface" "cursor-blink" "false")

;;; Code:

(require 'dash)
(require 'gvariant)
(require 's)

(defvar gsettings--command "gsettings"
  "Name of the gsettings command line tool.")

(defvar gsettings--error-buffer-name "*gsettings*"
  "Name of the buffer used for showing gsettings error output.")

(defun gsettings-available? ()
  "Check whether gsettings is available."
  (not (null (executable-find gsettings--command))))

(defun gsettings-get (schema key)
  "Get the value that SCHEMA has for KEY."
  (gvariant-parse (gsettings--run "get" schema key)))

(defun gsettings-get-default (schema key default)
  "Get the value that SCHEMA has for KEY.

Returns DEFAULT if the schema does not exists. Note that using a
non-existing key name in an existing schema will still result in
an error, since this is likely caused by buggy code."
  (if (gsettings-schema-exists? schema)
      (gsettings-get schema key)
    default))

(defun gsettings-list-schemas ()
  "List all schemas."
  (gsettings--split-lines (gsettings--run "list-schemas")))

(defun gsettings-schema-exists? (schema)
  "Check whether the schema with SCHEMA exists."
  (-contains? (gsettings-list-schemas) schema))

(defun gsettings-list-keys (schema)
  "List all keys in SCHEMA."
  (gsettings--split-lines (gsettings--run "list-keys" schema)))

(defun gsettings-reset (schema key)
  "Reset the SCHEMA KEY to its default value."
  (gsettings--run "reset" schema key))

(defun gsettings-set-from-gvariant-string (schema key value)
  "Set the SCHEMA KEY to the string VALUE.

Note that VALUE should be a valid GVariant string."
  (gsettings--run "set" schema key value))

;;;###autoload
(defun gsettings-apply-gnome-settings ()
  "Apply some Gnome desktop configuration to Emacs."
  (interactive)
  (when (and (gsettings-available?) (gsettings-gnome-running?))
    (let* ((cursor-blink (gsettings-get "org.gnome.desktop.interface" "cursor-blink"))
           (monospace-font-name (gsettings-get "org.gnome.desktop.interface" "monospace-font-name"))
           (monospace-font-family (gsettings--strip-font-size monospace-font-name))
           (document-font-name (gsettings-get "org.gnome.desktop.interface" "document-font-name"))
           (document-font-family (gsettings--strip-font-size document-font-name)))
      (setq font-use-system-font t)     ;; this may not always work
      (blink-cursor-mode (if cursor-blink 1 -1))
      (set-face-attribute 'default nil :family monospace-font-family)
      (set-face-attribute 'variable-pitch nil :family document-font-family))))

(defun gsettings-gnome-running? ()
  "Return whether Emacs is running inside a Gnome environment."
  (-when-let* ((gui-running (display-graphic-p))
               (xdg-current-desktop (getenv "XDG_CURRENT_DESKTOP"))
               (s-contains-p "gnome" xdg-current-desktop t))
    t))

(defun gsettings--run (&rest args)
  "Run gsettings using the provided ARGS and return the result as a string."
  (let ((stderr-tempfile (make-temp-file "gsettings-stderr-"))
        (exit-code))
    (with-temp-buffer
      (setq exit-code (apply #'call-process gsettings--command nil `(t ,stderr-tempfile) nil args))
      (unless (zerop exit-code)
        (with-current-buffer (get-buffer-create gsettings--error-buffer-name)
          (erase-buffer)
          (insert (format "error running %s:\n\n" gsettings--command))
          (insert (s-join " " (-map #'shell-quote-argument (cons gsettings--command args))))
          (insert "\n\n")
          (insert-file-contents stderr-tempfile)
          (display-buffer (current-buffer)))
        (error "Error running %s" gsettings--command))
      (buffer-substring-no-properties (point-min) (point-max)))))

(defun gsettings--split-lines (s)
  "Split string S into a list of lines, removing blanks."
  (-remove #'s-blank-str? (s-lines s)))

(defun gsettings--strip-font-size (s)
  "Strip the font size from a font string S."
  (->> s
       (s-replace-regexp "\\(.*\\) [0-9.]+" "\\1")
       (s-chop-suffixes '(" Medium" " Bold" " Light" " Semi-Light"))))

(provide 'gsettings)
;;; gsettings.el ends here
