;;; rivet-mode.el --- A minor mode for editing Apache Rivet files -*- lexical-binding: t; -*-
;;
;; Author: Jade Michael Thornton
;; Copyright (c) 2019-2020 Jade Michael Thornton
;; Package-Requires: ((emacs "24") (web-mode "16"))
;; Package-Version: 20201013.1905
;; Package-Commit: 3dd4fc28f29e4d4f43a881ed5816dea41a912419
;; URL: https://gitlab.com/thornjad/rivet-mode
;; Version: 4.1.0
;;
;; This file is not part of GNU Emacs

;;; Commentary:
;;
;; [![MELPA: rivet-mode](https://melpa.org/packages/rivet-mode-badge.svg)](https://melpa.org/#/rivet-mode) [![ISC License](https://img.shields.io/badge/license-ISC-green.svg)](./LICENSE) [![](https://img.shields.io/github/languages/code-size/thornjad/rivet-mode.svg)](https://gitlab.com/thornjad/rivet-mode) [![](https://img.shields.io/github/v/tag/thornjad/rivet-mode.svg?label=version&color=yellowgreen)](https://gitlab.com/thornjad/rivet-mode/-/tags)
;;
;; Rivet mode is a minor mode for editing Apache Rivet files. It automatically
;; detects whether TCL or HTML is currently being edited and uses the major
;; modes tcl-mode and web-mode, respectively.
;;
;; By default, `rivet-mode' requires `tcl' (built-in) and `web-mode'. To use
;; another mode, customize `rivet-mode-host-mode' and `rivet-mode-inner-mode' to
;; suit.

;; Installation:
;;
;; Install the `rivet-mode' package from MELPA.

;; Usage:
;;
;; The mode will be activated upon opening a Rivet file. There are a handful of
;; convenient function available inside this file. It is recommended to bind
;; these to keys of your choosing.
;;
;; Provided functions:
;;
;; - `rivet-insert-tcl': Insert TCL tags ("<?" and "?>") at point, and move point
;; inside of the tags. This will also switch to TCL mode.
;;
;; - `rivet-insert-begin-tcl': Insert an opening TCL tag at point and move inside
;; it.
;;
;; - `rivet-insert-end-tcl': Insert a closing TCL tag at point and move outside
;; it. This will also switch to web mode.
;;
;; - `rivet-insert-echo': Insert TCL echo tags ("<?=" and "?>") at point and move
;; inside them. This will also switch to TCL mode.
;;
;; - `rivet-insert-begin-echo': Insert an opening TCL echo tag at point and move
;; inside it.

;; Customization:
;;
;; The variable `rivet-mode-host-mode' determines the "host" major mode, which
;; is `web-mode' by default.
;;
;; The variable `rivet-mode-inner-mode' determines the "inner" major mode, which
;; is the built-in `tcl-mode' by default.
;;
;; The variable `rivet-mode-delimiters' defines the left and right delimiters
;; which demark the bounds of the "inner" major mode (TCL). These are "<?" and
;; "?>" by default. Note that the "<?=" delimiter, which marks the start of an
;; expression, still begins with "<?" and so will be caught.

;;; License:
;;
;; Copyright (c) 2019-2020 Jade Michael Thornton
;;
;; Permission to use, copy, modify, and/or distribute this software for any
;; purpose with or without fee is hereby granted, provided that the above
;; copyright notice and this permission notice appear in all copies.
;;
;; The software is provided "as is" and the author disclaims all warranties with
;; regard to this software including all implied warranties of merchantability
;; and fitness. In no event shall the author be liable for any special, direct,
;; indirect, or consequential damages or any damages whatsoever resulting from
;; loss of use, data or profits, whether in an action of contract, negligence or
;; other tortious action, arising out of or in connection with the use or
;; performance of this software.

;;; Code:


;;; Variables

(defvar rivet-mode-host-mode '("Web" web-mode web-mode)
  "The host mode is the 'outer' mode, i.e. HTML, CSS and JS.

Format is '(NAME MAJOR-MODE PACKAGE).

The PACKAGE part of the list is the name of the package which provides
MAJOR-MODE.")

(defvar rivet-mode-inner-mode '("TCL" tcl-mode tcl)
  "The inner mode is contained within the `rivet-mode-delimiters', used for TCL.

Format is '(NAME MAJOR-MODE PACKAGE). See `rivet-mode-delimiters' for more on
the demarcation between the inner and host modes.

The PACKAGE part of the list is the name of the package which provides
MAJOR-MODE.")

(defvar rivet-mode-delimiters '("<?" "?>")
  "These delimiters denote the boundaries of the 'inner' mode, i.e. TCL.

The car and cadr are the left and right delimiters. That is to say the format is
'(LEFT-DELIMITER RIGHT-DELIMITER). Note that the '<?=' output syntax is included
since it begins with '<?'.")

(make-variable-buffer-local
 (defvar rivet-mode--last-position 0
   "Value of point from the last time an update was attempted.

This buffer-local variable allows `rivet-mode' to tell if the point has moved,
and if, therefore, the current mode should be re-evaluated. This variable should
not be changed manually."))

(defvar rivet-mode-hook nil
  "*Hook called upon running minor mode function `rivet-mode'.")
(defvar rivet-mode-change-hook nil
  "*Hook called upon changing between inner and host modes.")


;;; The parts that do the real work

(defun rivet-mode--change-mode (to-mode)
  "Call TO-MODE, then set up the hook again and run rivet-mode-change-hook."

  ;; call our new mode function
  (funcall (cadr to-mode))

  ;; HACK this is crappy, but for some reason that funcall removes us from the
  ;; post-command hook, so let's put us back in.
  (add-hook 'post-command-hook #'rivet-mode--maybe-change-mode nil t)

  ;; After the mode was set, we reread the "Local Variables" section.
  (hack-local-variables)

  (if rivet-mode-change-hook (run-hooks 'rivet-mode-change-hook)))

(defun rivet-mode--maybe-change-mode ()
  "Change switch between inner and host modes if appropriate.

If there is no active region and point has changed, then determine if point is
in a host or inner section. If point has moved to a different section, change to
that section's major mode."
  (when (and (not (region-active-p))
           (not (equal (point) rivet-mode--last-position)))

    ;; cache our position for the next call
    (setq rivet-mode--last-position (point))

    (let ((last-left-delim -1) (last-right-delim -1))
      (save-excursion
        (if (search-backward (car rivet-mode-delimiters) nil t)
            (setq last-left-delim (point))))
      (save-excursion
        (if (search-backward (cadr rivet-mode-delimiters) nil t)
            (setq last-right-delim (point))))
      (let ((section-mode
             (if (and (not (and (= last-left-delim -1)
                            (= last-right-delim -1)))
                    (>= last-left-delim last-right-delim))
                 rivet-mode-inner-mode
               rivet-mode-host-mode)))
        (unless (equal major-mode (cadr section-mode))
          (rivet-mode--change-mode section-mode))))))

(defmacro rivet-mode--insert-move (str pos)
  `(progn (save-excursion (insert ,str)) (forward-char ,pos)))


;;; Public functions

(defun rivet-insert-tcl ()
  "Insert TCL tags <? and ?> at point."
  (interactive)
  (rivet-mode--insert-move "<?  ?>" 3))

(defun rivet-insert-begin-tcl ()
  "Insert an opening TCL tag at point."
  (interactive)
  (rivet-mode--insert-move "<?  " 3))

(defun rivet-insert-end-tcl ()
  "Insert a closing TCL tag at point."
  (interactive)
  (rivet-mode--insert-move "?>  " 3))

(defun rivet-insert-echo ()
  "Insert TCL echo tags at point."
  (interactive)
  (rivet-mode--insert-move "<?=  ?>" 4))

(defun rivet-insert-begin-echo ()
  "Insert an opening TCL echo tag at point."
  (interactive)
  (rivet-mode--insert-move "<?=  " 4))


;;; Minor mode and auto-mode setup

;;;###autoload
(define-minor-mode rivet-mode
  "Minor mode for editing Apache Rivet files.

Rivet mode intelligently switches between TCL and Web major modes for editing
Rivet files."
  :lighter " Rivet"

  ;; Load the required packages
  (dolist (mode (list rivet-mode-host-mode rivet-mode-inner-mode))
    (unless (require (caddr mode) nil t)
      (error
       "Rivet mode requires %s to work properly. Please ensure this package is available"
       (symbol-name (caddr mode)))))

  ;; Chances are we are at position 1 because the file has just been opened
  ;; cold. Since the inner mode requires delimiters and we could not possibly be
  ;; within a delimiter at position 1 (because the delimiters are at least two
  ;; characters), we must be in the host mode. If, however, we are not at
  ;; position 1, we need to check.
  (if (eql (point) 1)
      (progn
        (funcall (cadr rivet-mode-host-mode))
        (add-hook 'post-command-hook #'rivet-mode--maybe-change-mode nil t))
    (rivet-mode--maybe-change-mode))

  (if rivet-mode-hook (run-hooks 'rivet-mode-hook)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.rvt\\'" . rivet-mode))

(provide 'rivet-mode)

;;; rivet-mode.el ends here
