;;; org-variable-pitch.el --- Minor mode for variable pitch text in org mode.  -*- lexical-binding: t; -*-

;; Copyright (C) 2018, 2019, 2020, 2021  Göktuğ Kayaalp

;; Author: Göktuğ Kayaalp <self@gkayaalp.com>
;; Keywords: faces
;; Package-Version: 20210414.1844
;; Package-Commit: 8a3b529d5ece261a8847298ea03ed35615cc9bfa
;; Version: 2.1
;; URL: https://dev.gkayaalp.com/elisp/index.html#ovp
;; Package-Requires: ((emacs "25"))


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

;; Variable-pitch support for org-mode.  This minor mode enables
;; ‘variable-pitch-mode’ in the current Org-mode buffer, and sets some
;; particular faces up so that they are are rendered in fixed-width
;; font.  Also, indentation, list bullets and checkboxes are displayed
;; in monospace, in order to keep the shape of the outline.

;;; Installation:

;; Have this file somewhere in the load path, then:

;;   (require 'org-variable-pitch)
;;   (add-hook 'org-mode-hook 'org-variable-pitch-minor-mode)

;;; Setup:

;; org-variable-pitch.el (hereafter, OVP) can be set up in two
;; methods, the new method introduced in v2.0, and the old way which
;; was the initial method.

;;;; New set up method:

;; With v2.0 a new function, ‘org-variable-pitch-setup’ has been
;; added, which is means to be added to the ‘after-init-hook’ in order
;; to set up a sensible default configuration for OVP.  In order to
;; use this method, you can simply add the following to your
;; ‘user-init-file’:

;;   (require 'org-variable-pitch)
;;   (add-hook 'after-init-hook #'org-variable-pitch-setup)

;; If you desire finer control, however, you might instead configure
;; OVP as follows:

;;  (require 'org-variable-pitch)
;;  (set-face-attribute 'org-variable-pitch-fixed-face nil
;;                      :family "My Custom Font Mono")
;;  (add-hook 'org-mode-hook 'org-variable-pitch--enable)

;; At the time I’m writing this, the above snippet is essentially
;; equivalent to what ‘org-variable-pitch-setup’ does, but that
;; function might get improved over time.  I’ll try to keep the
;; documentation in sync with it, but it’s recommended that you use
;; the setup function instead.

;;;; Old setup method:

;; The old way involved setting a variable-pitch font by hand and
;; adding ‘org-variable-pitch-minor-mode’ to ‘org-mode-hook’.

;; Because this method of setup is obsolete, it’s not documented here,
;; but OVP should still work fine with old-style configurations.  You
;; can still modify ‘org-variable-pitch-fixed-face’ (the new name of
;; ‘org-variable-pitch-face’, which is obsoleted) and have your
;; configurations stick though, which was not possible before v2.0.

;;; Configuration:

;; There are a couple variables and faces you can use to configure how
;; OVP behaves.  These can be modified through the Emacs’
;; customisation facility via

;;   M-x customize-group RET org-variable-pitch RET

;; or manually, in your ‘user-init-file’.  It’s advisable that you
;; consult the documentation of each variable with ‘describe-variable’
;; and each face with ‘describe-face’.

;;;; ‘org-variable-pitch-fixed-face’ (face):

;;   This face is applied to parts of the buffer that OVP renders in
;;   fixed pitch, i.e. monospace fonts.  These include the space
;;   characters on the left edge of the buffer (indentation), list
;;   bullets, checkboxes, and optionally, leading asterixes of the
;;   headline (see below).

;;   By default, ‘org-variable-pitch-setup’ sets the ‘:family’
;;   attribute of this face to that of the ‘default’ face.  Pre-v2.0
;;   this was achieved via setting the ‘org-variable-pitch-fixed-font’
;;   to a desired font, which can still be used (see below), but we’ve
;;   obsoleted that method in favour of this new style of
;;   configuration in order to allow customising this face.

;;   This face replaces ‘org-variable-pitch-face’, which is made into
;;   an obsolete alias (i.e. still usable, but obsoleted).

;;;; ‘org-variable-pitch-fixed-font’ (variable):

;;   Obsolete since v2.0. Please configure
;;   ‘org-variable-pitch-fixed-face’ instead.

;;;; ‘org-variable-pitch-fixed-faces’ (variable):

;;   Apart from applying a face to the indentation and other aligned
;;   parts of an Org mode buffer to fix alignment issues, OVP also
;;   modifies the appearance of some other elements of the buffer so
;;   that everything appears tidy and aligned when
;;   ‘variable-pitch-mode’ is enabled.

;;   This variable contains a list of the faces that are to be
;;   modified in order to achive that.  You can extend this list with
;;   the names of faces you want to keep in fixed pitch, tho the
;;   default is aimed to be fairly comprehensive.

;;;; ‘org-variable-pitch-fontify-headline-prefix’ (variable):

;;   When this variable is non-nil, the leading asterixes of Org mode
;;   headlines are configured to appear in fixed pitch too.

;;; Notes:

;; - Setting ‘redisplay-skip-fontification-on-input’ to t may lead to
;;   inconsistent application of ‘org-variable-pitch-fixed-face’ to
;;   indentation.  This usually self-remedies as new input is added to
;;   the buffer and e.g. sometimes when ‘org-fill-paragraph’ is run,
;;   but will still lead to confusing issues, like for example the
;;   second and further lines of list items’ indentation not being
;;   made fixed, leading to them appearing on the wrong indentation
;;   level.



;;; Code:

(require 'org)
(require 'rx)

(defgroup org-variable-pitch nil
  "Customisations for ‘org-variable-pitch-minor-mode’."
  :group 'org
  :prefix "org-variable-pitch-")

(defun org-variable-pitch--get-fixed-font ()
  (if (string= org-variable-pitch-fixed-font--default
               org-variable-pitch-fixed-font)
      (face-attribute 'default :family)
    org-variable-pitch-fixed-font))

(defcustom org-variable-pitch-fixed-font "Monospace"
  "Monospace font to use with ‘org-variable-pitch-minor-mode’."
  :group 'org-variable-pitch
  :type 'string
  :risky t)

(defconst org-variable-pitch-fixed-font--default
  org-variable-pitch-fixed-font)

(make-obsolete-variable
 'org-variable-pitch-fixed-font
 "customize ‘org-variable-pitch-fixed-face’ instead."
 "org-variable-pitch.el 2.0")

(defcustom org-variable-pitch-fixed-faces
  '(org-block
    org-block-begin-line
    org-block-end-line
    org-code
    org-document-info-keyword
    org-done
    org-formula
    org-indent
    org-meta-line
    org-special-keyword
    org-table
    org-todo
    org-verbatim
    org-date
    org-drawer)
  "Faces to keep fixed-width when using ‘org-variable-pitch-minor-mode’."
  :group 'org-variable-pitch
  :type '(repeat symbol))

(defcustom org-variable-pitch-fontify-headline-prefix nil
  "Fontify the headline prefix.
When non-nil, headline prefix will use the monospace face.
Otherwise the headline will use the default `org-level-*' face.

Note that this will drop all `org-level-*' face styles and only
apply the monospace face to the headline prefix."
  :group 'org-variable-pitch
  :type 'boolean)

(define-obsolete-face-alias
  'org-variable-pitch-face
  'org-variable-pitch-fixed-face
  "org-variable-pitch.el 2.0")

(defface org-variable-pitch-fixed-face
  `((t . (:family ,(org-variable-pitch--get-fixed-font))))
  "Face for initial space and list item bullets.
This face is used to keep them in monospace when using
‘org-variable-pitch-minor-mode’."
  :group 'org-variable-pitch)

(defvar org-variable-pitch-font-lock-keywords)
(defvar org-variable-pitch-headline-font-lock-keywords)
(let ((code '(0 (put-text-property
                   (match-beginning 0)
                   (match-end 0)
                   'face 'org-variable-pitch-fixed-face))))
  (setq
   org-variable-pitch-font-lock-keywords
    `((,(rx bol (1+ blank))
       ,code)
      (,(rx bol (0+ blank)
            (or (: (or (+ digit) letter) (in ".)"))
                (: (or (in "-+") (1+ blank "\*"))
                   (opt blank "[" (in "-X ") "]")))
            blank)
       ,code))
    org-variable-pitch-headline-font-lock-keywords
    `((,(rx bol (1+ "\*") blank)
       ,code))))


(defvar org-variable-pitch--cookies nil
  "Face remappings to restore when the minor mode is deactivated")

;;;###autoload
(define-minor-mode org-variable-pitch-minor-mode
  "Set up the buffer to be partially in variable pitch.
Keeps some elements in fixed pitch in order to keep layout."
  nil " OVP" nil
  (if org-variable-pitch-minor-mode
      (progn
        (variable-pitch-mode 1)
        (dolist (face org-variable-pitch-fixed-faces)
          (if (facep face)
              (push (face-remap-add-relative face 'org-variable-pitch-fixed-face)
                    org-variable-pitch--cookies)
            (message "‘%s’ is not a valid face, thus OVP skipped it"
                     (symbol-name face))))
        (font-lock-add-keywords nil org-variable-pitch-font-lock-keywords)
        (when org-variable-pitch-fontify-headline-prefix
          (font-lock-add-keywords nil org-variable-pitch-headline-font-lock-keywords)))
    (variable-pitch-mode -1)
    (mapc #'face-remap-remove-relative org-variable-pitch--cookies)
    (setq org-variable-pitch--cookies nil)
    (font-lock-remove-keywords nil org-variable-pitch-font-lock-keywords)
    (font-lock-remove-keywords nil org-variable-pitch-headline-font-lock-keywords))
  (font-lock-ensure))

(defun org-variable-pitch--enable ()
  "Enable ‘org-variable-pitch-minor-mode’"
  (org-variable-pitch-minor-mode +1))

;;;###autoload
(defun org-variable-pitch-setup ()
  "Set up ‘org-variable-pitch-minor-mode’.

This function is a helper to set up OVP.  It syncs
‘org-variable-pitch-fixed-face’ with ‘default’ face, and adds a
hook to ‘org-mode-hook’.  Ideally, you’d want to run this
function somewhere after you set up ‘default’ face.

A nice place to call this function is from within
‘after-init-hook’:

    \(add-hook 'after-init-hook #'org-variable-pitch-setup)

Alternatively, you might want to manually set up the attributes
of ‘org-variable-pitch-fixed-face’, in which case you should
calling avoid this function, add ‘org-variable-pitch-minor-mode’
to ‘org-mode-hook’ manually, and set up the face however you
please."
  (interactive)
  (set-face-attribute 'org-variable-pitch-fixed-face nil
                      :family (org-variable-pitch--get-fixed-font))
  (add-hook 'org-mode-hook 'org-variable-pitch--enable))




;;; Footer:

(provide 'org-variable-pitch)
;;; org-variable-pitch.el ends here
