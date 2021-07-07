;;; gsettings.el --- GSettings (Gnome) helpers -*- lexical-binding: t; -*-

;; Author: wouter bolsterlee <wouter@bolsterl.ee>
;; Keywords: languages
;; Package-Version: 20190512.1053
;; Package-Commit: 1dd9a6a3036d76d8e680b2764c35b31bf5e6aff7
;; URL: https://github.com/wbolster/emacs-gsettings
;; Package-Requires: ((emacs "24.3") (dash "2.16.0") (gvariant "1.0.0") (s "1.12.0"))
;; Version: 1.0.0

;; Copyright 2019 wouter bolsterlee. Licensed under the 3-Clause BSD License.

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

(provide 'gsettings)
;;; gsettings.el ends here
