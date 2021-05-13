;;; python-black.el --- Reformat Python using python-black -*- lexical-binding: t; -*-

;; Author: wouter bolsterlee <wouter@bolsterl.ee>
;; Keywords: languages
;; Package-Version: 20210511.1545
;; Package-Commit: 6b6ab71d2762b6da703f8d1d3d964b712a98939e
;; URL: https://github.com/wbolster/emacs-python-black
;; Package-Requires: ((emacs "25") (dash "2.16.0") (reformatter "0.3"))
;; Version: 1.0.0

;; Copyright 2019 wouter bolsterlee. Licensed under the 3-Clause BSD License.

;;; Commentary:

;; Commands for reformatting Python code via black (and black-macchiato).

;;; Code:

(require 'dash)
(require 'python)
(require 'reformatter)
(require 'rx)

(defgroup python-black nil
  "Python reformatting using black."
  :group 'python
  :prefix "python-black-")

(defcustom python-black-command "black"
  "Name of the ‘black’ executable."
  :group 'python-black
  :type 'string)

(defcustom python-black-macchiato-command "black-macchiato"
  "Name of the ‘black-macchiato’ executable."
  :group 'python-black
  :type 'string)

(defvar python-black--base-args '("--quiet")
  "Base arguments to pass to black.")

(defcustom python-black-extra-args nil
  "Extra arguments to pass to black."
  :group 'python-black
  :type '(repeat string))

(defconst python-black--config-file "pyproject.toml")
(defconst python-black--config-file-marker-regex (rx bol "[tool.black]" eol))

;;;###autoload (autoload 'python-black-buffer "python-black" nil t)
;;;###autoload (autoload 'python-black-region "python-black" nil t)
;;;###autoload (autoload 'python-black-on-save-mode "python-black" nil t)
(reformatter-define python-black
  :program (python-black--command beg end)
  :args (python-black--make-args beg end)
  :lighter " BlackFMT"
  :group 'python-black)

;;;###autoload
(defun python-black-on-save-mode-enable-dwim ()
  "Enable ‘python-black-on-save-mode’ if this project is using Black.

The heuristic used looks for ‘[tool.black]’ in a ‘pyproject.toml’ file."
  (interactive)
  (when (python-black--buffer-in-blackened-project-p)
    (python-black-on-save-mode)))

;;;###autoload
(defun python-black-statement (&optional display-errors)
  "Reformats the current statement.

When called interactively with a prefix argument, or when
DISPLAY-ERRORS is non-nil, shows a buffer if the formatting fails."
  (interactive "p")
  (-when-let* ((beg (save-excursion
                      (python-nav-beginning-of-statement)
                      (line-beginning-position)))
               (end (save-excursion
                      (python-nav-end-of-statement)
                      (line-end-position)))
               (non-empty? (not (= beg end))))
    (python-black-region beg (min (point-max) (1+ end)) display-errors)))

;;;###autoload
(defun python-black-partial-dwim (&optional display-errors)
  "Reformats the active region or the current statement.

This runs ‘python-black-region’ or ‘python-black-statement’ depending
on whether the region is currently active.

When called interactively with a prefix argument, or when
DISPLAY-ERRORS is non-nil, shows a buffer if the formatting fails."
  (interactive "p")
  (if (region-active-p)
      (python-black-region (region-beginning) (region-end) display-errors)
    (python-black-statement display-errors)))

(defun python-black--command (beg end)
  "Helper to decide which command to run for span BEG to END."
  (if (python-black--whole-buffer-p beg end)
      python-black-command
    (unless (executable-find python-black-macchiato-command)
      (error "Partial formatting requires ‘%s’, but it is not installed"
             python-black-macchiato-command))
    python-black-macchiato-command))

(defun python-black--make-args (beg end)
  "Helper to build the argument list for black for span BEG to END."
  (append
   python-black--base-args
   (-when-let* ((file-name (buffer-file-name))
                (extension (file-name-extension file-name))
                (is-pyi-file (string-equal "pyi" extension)))
     '("--pyi"))
   python-black-extra-args
   (when (python-black--whole-buffer-p beg end)
     '("-"))))

(defun python-black--whole-buffer-p (beg end)
  "Return whether BEG and END span the whole buffer."
  (and (= (point-min) beg)
       (= (point-max) end)))

(defun python-black--buffer-in-blackened-project-p ()
  "Check whether the current buffer resides in a project that is using Black."
  (-when-let* ((file-name (buffer-file-name))
               (project-directory (locate-dominating-file file-name python-black--config-file))
               (config-file (concat project-directory python-black--config-file))
               (config-file-contains-marker
                (with-temp-buffer
                  (insert-file-contents-literally config-file)
                  (re-search-forward python-black--config-file-marker-regex nil t 1))))
    t))

(provide 'python-black)
;;; python-black.el ends here
