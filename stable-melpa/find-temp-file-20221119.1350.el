;;; find-temp-file.el --- Open quickly a temporary file

;; Copyright (C) 2012-2017 Sylvain Rousseau <thisirs at gmail dot com>

;; Author: Sylvain Rousseau <thisirs at gmail dot com>
;; Maintainer: Sylvain Rousseau <thisirs at gmail dot com>
;; URL: https://github.com/thisirs/find-temp-file.git
;; Package-Version: 20221119.1350
;; Package-Commit: 601e39b052c66df4cd928cf7e308dd6a54769a99
;; Keywords: convenience

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

;; This library allows you to open quickly a temporary file of a given
;; extension. No need to specify a name, just an extension.

;;; Installation:

;; Just put this file in your load path and require it:
;; (require 'find-temp-file)

;; You may want to bind `find-temp-file' to a convenient keystroke. In
;; my setup, I bind it to "C-x C-t".

;;; Examples:

;; (require 'find-temp-file)
;; (global-set-key (kbd "C-x C-t") 'find-temp-file)
;; (setq find-temp-file-directory "~/deathrow/drafts/")
;; (setq find-temp-template-default "%D/%M/%N-%S.%E")

;;; Code:

(require 'format-spec)

(defgroup find-temp-file nil
  "Open quickly a temporary file."
  :link '(url-link "https://github.com/thisirs/find-temp-file.git")
  :prefix 'find-temp
  :group 'convenience)

(defcustom find-temp-file-directory temporary-file-directory
  "Directory where temporary files are created."
  :type 'string)

(defcustom find-temp-file-prefix
  '("alpha" "bravo" "charlie" "delta" "echo" "foxtrot" "golf" "hotel"
    "india" "juliet" "kilo" "lima" "mike" "november" "oscar" "papa"
    "quebec" "romeo" "sierra" "tango" "uniform" "victor" "whiskey"
    "x-ray" "yankee" "zulu")
  "Successive names of temporary files."
  :type 'list)

(defcustom find-temp-template-alist
  '(("m" . "%N_%U.%E"))
  "Alist with file extensions and corresponding file name template.

%N: prefix taken from `find-temp-file-prefix'
%S: shortened sha-1 of the extension
%T: shortened sha-1 of the extension + username + machine
%U: shortened sha-1 of the extension + username + machine + timestamp
%E: extension
%M: replace by mode name associated with the extension
%D: date with format %Y-%m-%d

The default template is stored in `find-temp-template-default'."
  :type 'alist)

(defcustom find-temp-template-default
  "%N-%U.%E"
  "Default template for temporary files."
  :type 'string)

(defcustom find-temp-custom-spec ()
  "Additionnal specs that supersede default ones."
  :type 'alist)

(defcustom find-temp-add-to-history t
  "Add containing folder to file name history when a temporary
file is created."
  :type 'boolean)

(defmacro find-temp--ext-binding (ext binding)
  `(define-key map (kbd ,binding)
     (lambda ()
       (interactive)
       (delete-minibuffer-contents)
       (insert ,ext)
       (exit-minibuffer))))

(defvar find-temp-file-keymap
  (let ((map (make-sparse-keymap)))
    (find-temp--ext-binding "org" "C-o")
    (find-temp--ext-binding "tex" "C-t")
    (set-keymap-parent map minibuffer-local-map)
    map)
  "Keymap used when asking for an extension in the minibuffer.")

;;;###autoload
(defun find-temp-file (extension)
  "Open a temporary file.

EXTENSION is the extension of the temporary file. If EXTENSION
contains a dot, use EXTENSION as the full file name."
  (interactive
   (let* ((default (concat (if buffer-file-name
                               (file-name-extension
                                buffer-file-name))))
          (default-prompt (if (equal default "") ""
                            (format " (%s)" default)))
          choice)
     (setq choice (read-from-minibuffer
                   (format "Extension%s: " default-prompt)
                   nil
                   find-temp-file-keymap))
     (list (if (equal "" choice)
               default
             choice))))
  (setq extension (or extension ""))
  (let ((file-path (find-temp-file--filename extension)))
    (make-directory (file-name-directory file-path) :parents)
    (if find-temp-add-to-history
        (add-to-history 'file-name-history (file-name-directory file-path)))
    (find-file file-path))
  (basic-save-buffer))

(defun find-temp-file-eval-specs (specs)
  (mapcar (lambda (spec)
            (if (functionp (cdr spec))
                (cons (car spec) (funcall (cdr spec)))
              spec))
          specs))

(defun find-temp-file--filename (&optional extension-or-file)
  "Return a full path of a temporary file to be opened. If
EXTENSION-OR-FILE contains a dot, it is used as file-name. If
not, it assumes it is the extension of the temporary file, a
unique and recognizable name is automatically constructed."
  (let (file-name extension file-template template)
    (if (memq ?. (string-to-list extension-or-file))
        (setq file-name extension-or-file
              extension (or (file-name-extension extension-or-file) ""))
      (setq extension extension-or-file))

    (setq template
          (or
           (and extension
                (assoc-default extension find-temp-template-alist 'string-match))
           find-temp-template-default))

    (setq file-template
          (expand-file-name
           (format-spec
            template
            (append
             (find-temp-file-eval-specs find-temp-custom-spec)
             `((?E . ,extension)
               (?S . ,(substring (sha1 extension) 0 5))
               (?T . ,(substring (sha1 (concat  extension user-login-name (system-name))) 0 5))
               (?U . ,(substring (sha1 (concat extension (format-time-string "%Y-%m-%d") user-login-name (system-name))) 0 5))
               (?M . ,(let ((fun (assoc-default (concat "." extension)
                                                auto-mode-alist
                                                'string-match)))
                        (symbol-name (or fun (default-value 'major-mode)))))
               (?D . ,(format-time-string "%Y-%m-%d"))
               (?N . "%N"))))
           find-temp-file-directory))

    (if file-name
        (expand-file-name file-name (file-name-directory file-template))
      (catch 'found
        (mapc (lambda (prefix)
                (setq file-name
                      (format-spec
                       file-template
                       `((?N . ,prefix))))

                (unless (file-exists-p file-name)
                  (throw 'found file-name)))
              find-temp-file-prefix)
        (error "Run out of prefixes to create filenames")))))

(provide 'find-temp-file)

;;; find-temp-file.el ends here
