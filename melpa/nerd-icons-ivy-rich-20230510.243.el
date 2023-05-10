;;; nerd-icons-ivy-rich.el --- Excellent experience with nerd icons for ivy/counsel        -*- lexical-binding: t; -*-

;; Copyright (C) 2023 Vincent Zhang

;; Author: Vincent Zhang <seagle0128@gmail.com>
;; Homepage: https://github.com/seagle0128/nerd-icons-ivy-rich
;; Version: 1.0.1
;; Package-Version: 20230510.243
;; Package-Commit: 664f4cd0bfd9845ef429cb341a713d1a9ded76d6
;; Package-Requires: ((emacs "26.1") (ivy-rich "0.1.0") (nerd-icons "0.0.1"))
;; Keywords: convenience, icons, ivy

;; This file is not part of GNU Emacs.

;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;

;;; Commentary:

;; Excellent experience with nerd icons for ivy/counsel.
;;
;; Install:
;; From melpa, `M-x package-install RET nerd-icons-ivy-rich RET`.
;; (nerd-icons-ivy-rich-mode 1)
;; or
;; (use-package nerd-icons-ivy-rich-mode
;;   :ensure t
;;   :init (nerd-icons-ivy-rich-mode 1))


;;; Code:

(eval-when-compile
  (require 'subr-x)
  (require 'package)
  (require 'bookmark)
  (require 'project))

(require 'ivy-rich)
(require 'nerd-icons)



;; Suppress warnings
(defvar counsel--fzf-dir)
(defvar ivy--directory)
(defvar ivy-last)
(defvar ivy-posframe-buffer)

(declare-function bookmark-get-front-context-string "bookmark")
(declare-function counsel-world-clock--local-time "ext:counsel-world-clock")
(declare-function find-library-name "find-func")
(declare-function ivy-posframe--display "ext:ivy-posframe")
(declare-function package--from-builtin "package")
(declare-function package-desc-status "package")
(declare-function projectile-project-root "ext:projectile")


;;
;; Faces
;;

(defgroup nerd-icons-ivy-rich nil
  "Better experience using icons in ivy."
  :group 'nerd-icons
  :group 'ivy-rich
  :link '(url-link :tag "Homepage" "https://github.com/seagle0128/nerd-icons-ivy-rich"))

(defface nerd-icons-ivy-rich-on-face
  '((t :inherit success))
  "Face used to signal enabled modes.")

(defface nerd-icons-ivy-rich-off-face
  '((t :inherit shadow))
  "Face used to signal disabled modes.")

(defface nerd-icons-ivy-rich-error-face
  '((t :inherit error))
  "Face used to signal disabled modes.")

(defface nerd-icons-ivy-rich-warn-face
  '((t :inherit warning))
  "Face used to signal disabled modes.")

(defface nerd-icons-ivy-rich-icon-face
  '((t (:inherit default)))
  "Face used for the icons while `nerd-icons-ivy-rich-color-icon' is nil."
  :group 'nerd-icons-ivy-rich)

(defface nerd-icons-ivy-rich-dir-face
  '((t (:inherit font-lock-doc-face)))
  "Face used for the directory icon."
  :group 'nerd-icons-ivy-rich)

(defface nerd-icons-ivy-rich-doc-face
  '((t (:inherit ivy-completions-annotations)))
  "Face used for documentation string."
  :group 'nerd-icons-ivy-rich)

(defface nerd-icons-ivy-rich-size-face
  '((t (:inherit font-lock-constant-face)))
  "Face used for buffer size."
  :group 'nerd-icons-ivy-rich)

(defface nerd-icons-ivy-rich-time-face
  '((t (:inherit shadow)))
  "Face used for time."
  :group 'nerd-icons-ivy-rich)

(defface nerd-icons-ivy-rich-bookmark-face
  '((t (:inherit nerd-icons-ivy-rich-doc-face)))
  "Face used for time."
  :group 'nerd-icons-ivy-rich)

(defface nerd-icons-ivy-rich-version-face
  '((t (:inherit font-lock-constant-face)))
  "Face used for package version."
  :group 'nerd-icons-ivy-rich)

(defface nerd-icons-ivy-rich-archive-face
  '((t (:inherit font-lock-doc-face)))
  "Face used for package archive."
  :group 'nerd-icons-ivy-rich)

(defface nerd-icons-ivy-rich-package-status-avaible-face
  '((t (:inherit nerd-icons-ivy-rich-on-face)))
  "Face used for package status."
  :group 'nerd-icons-ivy-rich)

(defface nerd-icons-ivy-rich-package-status-new-face
  '((t (:inherit (nerd-icons-ivy-rich-on-face bold))))
  "Face used for package status."
  :group 'nerd-icons-ivy-rich)

(defface nerd-icons-ivy-rich-package-status-held-face
  '((t (:inherit font-lock-constant-face)))
  "Face used for package status."
  :group 'nerd-icons-ivy-rich)

(defface nerd-icons-ivy-rich-package-status-installed-face
  '((t (:inherit nerd-icons-ivy-rich-off-face)))
  "Face used for package status."
  :group 'nerd-icons-ivy-rich)

(defface nerd-icons-ivy-rich-package-status-warn-face
  '((t (:inherit nerd-icons-ivy-rich-warn-face)))
  "Face used for package status."
  :group 'nerd-icons-ivy-rich)

(defface nerd-icons-ivy-rich-pacage-desc-face
  '((t (:inherit nerd-icons-ivy-rich-doc-face)))
  "Face used for package description."
  :group 'nerd-icons-ivy-rich)

(defface nerd-icons-ivy-rich-path-face
  '((t (:inherit nerd-icons-ivy-rich-doc-face)))
  "Face used for file path."
  :group 'nerd-icons-ivy-rich)

(defface nerd-icons-ivy-rich-indicator-face
  '((t (:inherit nerd-icons-ivy-rich-error-face)))
  "Face used for file indicators."
  :group 'nerd-icons-ivy-rich)

(defface nerd-icons-ivy-rich-major-mode-face
  '((t (:inherit font-lock-keyword-face)))
  "Face used for buffer major mode."
  :group 'nerd-icons-ivy-rich)

(defface nerd-icons-ivy-rich-project-face
  '((t (:inherit font-lock-string-face)))
  "Face used for project."
  :group 'nerd-icons-ivy-rich)

(defface nerd-icons-ivy-rich-persp-face
  '((t (:inherit font-lock-string-face)))
  "Face used for persp."
  :group 'nerd-icons-ivy-rich)

(defface nerd-icons-ivy-rich-file-name-face
  '((t :inherit nerd-icons-ivy-rich-doc-face))
  "Face used for highlight file names.")

(defface nerd-icons-ivy-rich-file-priv-no
  '((t :inherit shadow))
  "Face used to highlight the no file privilege attribute.")

(defface nerd-icons-ivy-rich-file-priv-dir
  '((t :inherit font-lock-keyword-face))
  "Face used to highlight the dir file privilege attribute.")

(defface nerd-icons-ivy-rich-file-priv-link
  '((t :inherit font-lock-keyword-face))
  "Face used to highlight the link file privilege attribute.")

(defface nerd-icons-ivy-rich-file-priv-read
  '((t :inherit font-lock-type-face))
  "Face used to highlight the read file privilege attribute.")

(defface nerd-icons-ivy-rich-file-priv-write
  '((t :inherit font-lock-builtin-face))
  "Face used to highlight the write file privilege attribute.")

(defface nerd-icons-ivy-rich-file-priv-exec
  '((t :inherit font-lock-function-name-face))
  "Face used to highlight the exec file privilege attribute.")

(defface nerd-icons-ivy-rich-file-priv-other
  '((t :inherit font-lock-constant-face))
  "Face used to highlight some other file privilege attribute.")

(defface nerd-icons-ivy-rich-file-priv-rare
  '((t :inherit font-lock-variable-name-face))
  "Face used to highlight a rare file privilege attribute.")

(defface nerd-icons-ivy-rich-file-owner-face
  '((t :inherit font-lock-keyword-face))
  "Face used for highlight file owners.")

(defface nerd-icons-ivy-rich-process-id-face
  '((t :inherit default))
  "Face used for process id.")

(defface nerd-icons-ivy-rich-process-status-face
  '((t :inherit success))
  "Face used for process status.")

(defface nerd-icons-ivy-rich-process-status-alt-face
  '((t :inherit nerd-icons-ivy-rich-error-face))
  "Face used for process status: stop, exit, closed and failed.")

(defface nerd-icons-ivy-rich-process-buffer-face
  '((t :inherit font-lock-keyword-face))
  "Face used for process buffer label.")

(defface nerd-icons-ivy-rich-process-tty-face
  '((t :inherit font-lock-doc-face))
  "Face used for process tty.")

(defface nerd-icons-ivy-rich-process-thread-face
  '((t :inherit font-lock-doc-face))
  "Face used for process thread.")

(defface nerd-icons-ivy-rich-process-command-face
  '((t :inherit nerd-icons-ivy-rich-doc-face))
  "Face used for process command.")

(defface nerd-icons-ivy-rich-type-face
  '((t :inherit font-lock-keyword-face))
  "Face used for type.")

(defface nerd-icons-ivy-rich-value-face
  '((t :inherit font-lock-keyword-face))
  "Face used for variable value.")

(defface nerd-icons-ivy-rich-true-face
  '((t :inherit font-lock-builtin-face))
  "Face used to highlight true variable values.")

(defface nerd-icons-ivy-rich-null-face
  '((t :inherit font-lock-comment-face))
  "Face used to highlight null or unbound variable values.")

(defface nerd-icons-ivy-rich-list-face
  '((t :inherit font-lock-constant-face))
  "Face used to highlight list expressions.")

(defface nerd-icons-ivy-rich-number-face
  '((t :inherit font-lock-constant-face))
  "Face used to highlight numeric values.")

(defface nerd-icons-ivy-rich-string-face
  '((t :inherit font-lock-string-face))
  "Face used to highlight string values.")

(defface nerd-icons-ivy-rich-function-face
  '((t :inherit font-lock-function-name-face))
  "Face used to highlight function symbols.")

(defface nerd-icons-ivy-rich-symbol-face
  '((t :inherit font-lock-type-face))
  "Face used to highlight general symbols.")

(defface nerd-icons-ivy-rich-imenu-type-face
  '((t (:inherit nerd-icons-ivy-rich-type-face)))
  "Face used for imenu type."
  :group 'nerd-icons-ivy-rich)

(defface nerd-icons-ivy-rich-imenu-doc-face
  '((t (:inherit nerd-icons-ivy-rich-doc-face)))
  "Face used for imenu documentation."
  :group 'nerd-icons-ivy-rich)

;;
;; Customization
;;

(defcustom nerd-icons-ivy-rich-icon t
  "Whether display the icons."
  :group 'nerd-icons-ivy-rich
  :type 'boolean)

(defcustom nerd-icons-ivy-rich-color-icon t
  "Whether display the colorful icons.

It respects `nerd-icons-color-icons'."
  :group 'nerd-icons-ivy-rich
  :type 'boolean)

(defcustom nerd-icons-ivy-rich-icon-size 1.0
  "The default icon size in ivy."
  :group 'nerd-icons-ivy-rich
  :type 'float)

(defcustom nerd-icons-ivy-rich-project t
  "Whether support project root."
  :group 'nerd-icons-ivy-rich
  :type 'boolean)

(defcustom nerd-icons-ivy-rich-field-width 80
  "Maximum truncation width of annotation fields.

This value is adjusted depending on the `window-width'."
  :group 'nerd-icons-ivy-rich
  :type 'integer)

(defcustom nerd-icons-ivy-rich-display-transformers-list
  '(ivy-switch-buffer
    (:columns
     ((nerd-icons-ivy-rich-buffer-icon)
      (ivy-switch-buffer-transformer (:width 0.3))
      (ivy-rich-switch-buffer-size (:width 7 :face nerd-icons-ivy-rich-size-face))
      (ivy-rich-switch-buffer-indicators (:width 4 :face nerd-icons-ivy-rich-indicator-face :align right))
      (nerd-icons-ivy-rich-switch-buffer-major-mode (:width 18 :face nerd-icons-ivy-rich-major-mode-face))
      (ivy-rich-switch-buffer-project (:width 0.12 :face nerd-icons-ivy-rich-project-face))
      (ivy-rich-switch-buffer-path (:width (lambda (x) (ivy-rich-switch-buffer-shorten-path x (ivy-rich-minibuffer-width 0.3))) :face nerd-icons-ivy-rich-path-face)))
     :predicate
     (lambda (cand) (get-buffer cand))
     :delimiter " ")
    ivy-switch-buffer-other-window
    (:columns
     ((nerd-icons-ivy-rich-buffer-icon)
      (ivy-switch-buffer-transformer (:width 0.3))
      (ivy-rich-switch-buffer-size (:width 7 :face nerd-icons-ivy-rich-size-face))
      (ivy-rich-switch-buffer-indicators (:width 4 :face nerd-icons-ivy-rich-indicator-face :align right))
      (nerd-icons-ivy-rich-switch-buffer-major-mode (:width 18 :face nerd-icons-ivy-rich-major-mode-face))
      (ivy-rich-switch-buffer-project (:width 0.12 :face nerd-icons-ivy-rich-project-face))
      (ivy-rich-switch-buffer-path (:width (lambda (x) (ivy-rich-switch-buffer-shorten-path x (ivy-rich-minibuffer-width 0.3))) :face nerd-icons-ivy-rich-path-face)))
     :predicate
     (lambda (cand) (get-buffer cand))
     :delimiter " ")

    ;; counsel
    counsel-switch-buffer
    (:columns
     ((nerd-icons-ivy-rich-buffer-icon)
      (ivy-switch-buffer-transformer (:width 0.3))
      (ivy-rich-switch-buffer-size (:width 7 :face nerd-icons-ivy-rich-size-face))
      (ivy-rich-switch-buffer-indicators (:width 4 :face nerd-icons-ivy-rich-indicator-face :align right))
      (nerd-icons-ivy-rich-switch-buffer-major-mode (:width 18 :face nerd-icons-ivy-rich-major-mode-face))
      (ivy-rich-switch-buffer-project (:width 0.12 :face nerd-icons-ivy-rich-project-face))
      (ivy-rich-switch-buffer-path (:width (lambda (x) (ivy-rich-switch-buffer-shorten-path x (ivy-rich-minibuffer-width 0.3))) :face nerd-icons-ivy-rich-path-face)))
     :predicate
     (lambda (cand) (get-buffer cand))
     :delimiter " ")
    counsel-switch-buffer-other-window
    (:columns
     ((nerd-icons-ivy-rich-buffer-icon)
      (ivy-switch-buffer-transformer (:width 0.3))
      (ivy-rich-switch-buffer-size (:width 7 :face nerd-icons-ivy-rich-size-face))
      (ivy-rich-switch-buffer-indicators (:width 4 :face nerd-icons-ivy-rich-indicator-face :align right))
      (nerd-icons-ivy-rich-switch-buffer-major-mode (:width 18 :face nerd-icons-ivy-rich-major-mode-face))
      (ivy-rich-switch-buffer-project (:width 0.12 :face nerd-icons-ivy-rich-project-face))
      (ivy-rich-switch-buffer-path (:width (lambda (x) (ivy-rich-switch-buffer-shorten-path x (ivy-rich-minibuffer-width 0.3))) :face nerd-icons-ivy-rich-path-face)))
     :predicate
     (lambda (cand) (get-buffer cand))
     :delimiter " ")
    counsel-M-x
    (:columns
     ((nerd-icons-ivy-rich-function-icon)
      (counsel-M-x-transformer (:width 0.3))
      (ivy-rich-counsel-function-docstring (:face nerd-icons-ivy-rich-doc-face))))
    counsel-describe-function
    (:columns
     ((nerd-icons-ivy-rich-function-icon)
      (counsel-describe-function-transformer (:width 0.3))
      (nerd-icons-ivy-rich-symbol-class (:width 8 :face nerd-icons-ivy-rich-type-face))
      (nerd-icons-ivy-rich-function-args (:width 0.12 :face nerd-icons-ivy-rich-value-face))
      (ivy-rich-counsel-function-docstring (:face nerd-icons-ivy-rich-doc-face))))
    counsel-describe-variable
    (:columns
     ((nerd-icons-ivy-rich-variable-icon)
      (counsel-describe-variable-transformer (:width 0.3))
      (nerd-icons-ivy-rich-symbol-class (:width 8 :face nerd-icons-ivy-rich-type-face))
      (nerd-icons-ivy-rich-variable-value (:width 0.12))
      (ivy-rich-counsel-variable-docstring (:face nerd-icons-ivy-rich-doc-face))))
    counsel-describe-symbol
    (:columns
     ((nerd-icons-ivy-rich-symbol-icon)
      (ivy-rich-candidate (:width 0.3))
      (nerd-icons-ivy-rich-symbol-class (:width 8 :face nerd-icons-ivy-rich-type-face))
      (nerd-icons-ivy-rich-symbol-docstring (:face nerd-icons-ivy-rich-doc-face)))
     :delimiter " ")
    counsel-set-variable
    (:columns
     ((nerd-icons-ivy-rich-variable-icon)
      (counsel-describe-variable-transformer (:width 0.3))
      (nerd-icons-ivy-rich-symbol-class (:width 8 :face nerd-icons-ivy-rich-type-face))
      (nerd-icons-ivy-rich-variable-value (:width 0.12))
      (ivy-rich-counsel-variable-docstring (:face nerd-icons-ivy-rich-doc-face))))
    counsel-apropos
    (:columns
     ((nerd-icons-ivy-rich-symbol-icon)
      (ivy-rich-candidate (:width 0.3))
      (nerd-icons-ivy-rich-symbol-class (:width 8 :face nerd-icons-ivy-rich-type-face))
      (nerd-icons-ivy-rich-symbol-docstring (:face nerd-icons-ivy-rich-doc-face)))
     :delimiter " ")
    counsel-info-lookup-symbol
    (:columns
     ((nerd-icons-ivy-rich-symbol-icon)
      (ivy-rich-candidate (:width 0.3))
      (nerd-icons-ivy-rich-symbol-class (:width 8 :face nerd-icons-ivy-rich-type-face))
      (nerd-icons-ivy-rich-symbol-docstring (:face nerd-icons-ivy-rich-doc-face)))
     :delimiter " ")
    counsel-descbinds
    (:columns
     ((nerd-icons-ivy-rich-keybinding-icon)
      (ivy-rich-candidate (:width 0.3))
      (nerd-icons-ivy-rich-keybinding-docstring (:face nerd-icons-ivy-rich-doc-face)))
     :delimiter " ")
    counsel-find-file
    (:columns
     ((nerd-icons-ivy-rich-file-icon)
      (nerd-icons-ivy-rich-file-name (:width 0.4))
      (nerd-icons-ivy-rich-file-id (:width 15 :face nerd-icons-ivy-rich-file-owner-face :align right))
      (nerd-icons-ivy-rich-file-modes (:width 12))
      (nerd-icons-ivy-rich-file-size (:width 7 :face nerd-icons-ivy-rich-size-face))
      (nerd-icons-ivy-rich-file-modification-time (:face nerd-icons-ivy-rich-time-face)))
     :delimiter " ")
    counsel-file-jump
    (:columns
     ((nerd-icons-ivy-rich-file-icon)
      (nerd-icons-ivy-rich-file-name (:width 0.4))
      (nerd-icons-ivy-rich-file-id (:width 15 :face nerd-icons-ivy-rich-file-owner-face :align right))
      (nerd-icons-ivy-rich-file-modes (:width 12))
      (nerd-icons-ivy-rich-file-size (:width 7 :face nerd-icons-ivy-rich-size-face))
      (nerd-icons-ivy-rich-file-modification-time (:face nerd-icons-ivy-rich-time-face)))
     :delimiter " ")
    counsel-dired
    (:columns
     ((nerd-icons-ivy-rich-file-icon)
      (nerd-icons-ivy-rich-file-name (:width 0.4))
      (nerd-icons-ivy-rich-file-id (:width 15 :face nerd-icons-ivy-rich-file-owner-face :align right))
      (nerd-icons-ivy-rich-file-modes (:width 12))
      (nerd-icons-ivy-rich-file-size (:width 7 :face nerd-icons-ivy-rich-size-face))
      (nerd-icons-ivy-rich-file-modification-time (:face nerd-icons-ivy-rich-time-face)))
     :delimiter " ")
    counsel-dired-jump
    (:columns
     ((nerd-icons-ivy-rich-file-icon)
      (nerd-icons-ivy-rich-file-name (:width 0.4))
      (nerd-icons-ivy-rich-file-id (:width 15 :face nerd-icons-ivy-rich-file-owner-face :align right))
      (nerd-icons-ivy-rich-file-modes (:width 12))
      (nerd-icons-ivy-rich-file-size (:width 7 :face nerd-icons-ivy-rich-size-face))
      (nerd-icons-ivy-rich-file-modification-time (:face nerd-icons-ivy-rich-time-face)))
     :delimiter " ")
    counsel-fzf
    (:columns
     ((nerd-icons-ivy-rich-file-icon)
      (nerd-icons-ivy-rich-file-name (:width 0.4))
      (nerd-icons-ivy-rich-file-id (:width 15 :face nerd-icons-ivy-rich-file-owner-face :align right))
      (nerd-icons-ivy-rich-file-modes (:width 12))
      (nerd-icons-ivy-rich-file-size (:width 7 :face nerd-icons-ivy-rich-size-face))
      (nerd-icons-ivy-rich-file-modification-time (:face nerd-icons-ivy-rich-time-face)))
     :delimiter " ")
    counsel-git
    (:columns
     ((nerd-icons-ivy-rich-file-icon)
      (nerd-icons-ivy-rich-file-name (:width 0.4))
      (nerd-icons-ivy-rich-file-id (:width 15 :face nerd-icons-ivy-rich-file-owner-face :align right))
      (nerd-icons-ivy-rich-file-modes (:width 12))
      (nerd-icons-ivy-rich-file-size (:width 7 :face nerd-icons-ivy-rich-size-face))
      (nerd-icons-ivy-rich-file-modification-time (:face nerd-icons-ivy-rich-time-face)))
     :delimiter " ")
    counsel-recentf
    (:columns
     ((nerd-icons-ivy-rich-file-icon)
      (nerd-icons-ivy-rich-file-name (:width 0.5))
      (nerd-icons-ivy-rich-file-id (:width 15 :face nerd-icons-ivy-rich-file-owner-face :align right))
      (nerd-icons-ivy-rich-file-modes (:width 12))
      (nerd-icons-ivy-rich-file-size (:width 7 :face nerd-icons-ivy-rich-size-face))
      (ivy-rich-file-last-modified-time (:face nerd-icons-ivy-rich-time-face)))
     :delimiter " ")
    counsel-buffer-or-recentf
    (:columns
     ((nerd-icons-ivy-rich-file-icon)
      (counsel-buffer-or-recentf-transformer (:width 0.5))
      (nerd-icons-ivy-rich-file-id (:width 15 :face nerd-icons-ivy-rich-file-owner-face :align right))
      (nerd-icons-ivy-rich-file-modes (:width 12))
      (nerd-icons-ivy-rich-file-size (:width 7 :face nerd-icons-ivy-rich-size-face))
      (ivy-rich-file-last-modified-time (:face nerd-icons-ivy-rich-time-face)))
     :delimiter " ")
    counsel-bookmark
    (:columns
     ((nerd-icons-ivy-rich-bookmark-icon)
      (nerd-icons-ivy-rich-bookmark-name (:width 0.25))
      (ivy-rich-bookmark-type (:width 10))
      (nerd-icons-ivy-rich-bookmark-filename (:width 0.3 :face nerd-icons-ivy-rich-bookmark-face))
      (nerd-icons-ivy-rich-bookmark-context (:face nerd-icons-ivy-rich-doc-face)))
     :delimiter " ")
    counsel-bookmarked-directory
    (:columns
     ((nerd-icons-ivy-rich-file-icon)
      (ivy-rich-candidate))
     :delimiter " ")
    counsel-package
    (:columns
     ((nerd-icons-ivy-rich-package-icon)
      (ivy-rich-candidate (:width 0.25))
      (nerd-icons-ivy-rich-package-version (:width 16 :face nerd-icons-ivy-rich-version-face))
      (nerd-icons-ivy-rich-package-status (:width 12))
      (nerd-icons-ivy-rich-package-archive-summary (:width 7 :face nerd-icons-ivy-rich-archive-face))
      (nerd-icons-ivy-rich-package-install-summary (:face nerd-icons-ivy-rich-pacage-desc-face)))
     :delimiter " ")
    counsel-fonts
    (:columns
     ((nerd-icons-ivy-rich-font-icon)
      (ivy-rich-candidate))
     :delimiter " ")
    counsel-major
    (:columns
     ((nerd-icons-ivy-rich-mode-icon)
      (counsel-describe-function-transformer (:width 0.3))
      (ivy-rich-counsel-function-docstring (:face nerd-icons-ivy-rich-doc-face))))
    counsel-minor
    (:columns
     ((nerd-icons-ivy-rich-mode-icon)
      (ivy-rich-candidate))
     :delimiter " ")
    counsel-find-library
    (:columns
     ((nerd-icons-ivy-rich-library-icon)
      (nerd-icons-ivy-rich-library-transformer))
     :delimiter " ")
    counsel-load-library
    (:columns
     ((nerd-icons-ivy-rich-library-icon)
      (nerd-icons-ivy-rich-library-transformer))
     :delimiter " ")
    counsel-load-theme
    (:columns
     ((nerd-icons-ivy-rich-theme-icon)
      (ivy-rich-candidate))
     :delimiter " ")
    counsel-world-clock
    (:columns
     ((nerd-icons-ivy-rich-world-clock-icon)
      (ivy-rich-candidate (:width 0.3))
      (nerd-icons-ivy-rich-world-clock (:face nerd-icons-ivy-rich-time-face)))
     :delimiter " ")
    counsel-tramp
    (:columns
     ((nerd-icons-ivy-rich-tramp-icon)
      (ivy-rich-candidate))
     :delimiter " ")
    counsel-git-checkout
    (:columns
     ((nerd-icons-ivy-rich-git-commit-icon)
      (ivy-rich-candidate))
     :delimiter " ")
    counsel-list-processes
    (:columns
     ((nerd-icons-ivy-rich-process-icon)
      (ivy-rich-candidate (:width 25))
      (nerd-icons-ivy-rich-process-id (:width 7 :face nerd-icons-ivy-rich-process-id-face))
      (nerd-icons-ivy-rich-process-status (:width 7))
      (nerd-icons-ivy-rich-process-buffer-name (:width 25 :face nerd-icons-ivy-rich-process-buffer-face))
      (nerd-icons-ivy-rich-process-tty-name (:width 12 :face nerd-icons-ivy-rich-process-tty-face))
      (nerd-icons-ivy-rich-process-thread (:width 12 :face nerd-icons-ivy-rich-process-thread-face))
      (nerd-icons-ivy-rich-process-command (:width 0.4 :face nerd-icons-ivy-rich-process-command-face)))
     :delimiter " ")
    counsel-projectile-switch-project
    (:columns
     ((nerd-icons-ivy-rich-file-icon)
      (nerd-icons-ivy-rich-project-name (:width 0.4))
      (nerd-icons-ivy-rich-project-file-id (:width 15 :face nerd-icons-ivy-rich-file-owner-face :align right))
      (nerd-icons-ivy-rich-project-file-modes (:width 12))
      (nerd-icons-ivy-rich-project-file-size (:width 7 :face nerd-icons-ivy-rich-size-face))
      (nerd-icons-ivy-rich-project-file-modification-time (:face nerd-icons-ivy-rich-time-face)))
     :delimiter " ")
    counsel-projectile
    (:columns
     ((counsel-projectile-switch-to-buffer-transformer))
     :predicate
     (lambda (cand) (get-buffer cand))
     :delimiter " ")
    counsel-projectile-switch-to-buffer
    (:columns
     ((counsel-projectile-switch-to-buffer-transformer))
     :predicate
     (lambda (cand) (get-buffer cand))
     :delimiter " ")
    counsel-projectile-find-file
    (:columns
     ((nerd-icons-ivy-rich-file-icon)
      (counsel-projectile-find-file-transformer (:width 0.4))
      (nerd-icons-ivy-rich-project-file-id (:width 15 :face nerd-icons-ivy-rich-file-owner-face :align right))
      (nerd-icons-ivy-rich-project-file-modes (:width 12))
      (nerd-icons-ivy-rich-project-file-size (:width 7 :face nerd-icons-ivy-rich-size-face))
      (nerd-icons-ivy-rich-project-file-modification-time (:face nerd-icons-ivy-rich-time-face)))
     :delimiter " ")
    counsel-projectile-find-dir
    (:columns
     ((nerd-icons-ivy-rich-file-icon)
      (counsel-projectile-find-dir-transformer (:width 0.4))
      (nerd-icons-ivy-rich-project-file-id (:width 15 :face nerd-icons-ivy-rich-file-owner-face :align right))
      (nerd-icons-ivy-rich-project-file-modes (:width 12))
      (nerd-icons-ivy-rich-project-file-size (:width 7 :face nerd-icons-ivy-rich-size-face))
      (nerd-icons-ivy-rich-project-file-modification-time (:face nerd-icons-ivy-rich-time-face)))
     :delimiter " ")
    counsel-imenu
    (:columns
     ((nerd-icons-ivy-rich-imenu-icon)
      (nerd-icons-ivy-rich-imenu-transformer (:width 0.3))
      (nerd-icons-ivy-rich-imenu-class (:width 8 :face nerd-icons-ivy-rich-imenu-type-face))
      (nerd-icons-ivy-rich-imenu-docstring (:face nerd-icons-ivy-rich-imenu-doc-face)))
     :delimiter " ")
    counsel-company
    (:columns
     ((nerd-icons-ivy-rich-company-icon)
      (ivy-rich-candidate))
     :delimiter " ")
    counsel-command-history
    (:columns
     ((nerd-icons-ivy-rich-command-icon)
      (ivy-rich-candidate))
     :delimiter " ")
    counsel-minibuffer-history
    (:columns
     ((nerd-icons-ivy-rich-history-icon)
      (ivy-rich-candidate))
     :delimiter " ")
    counsel-read-directory-name
    (:columns
     ((nerd-icons-ivy-rich-dir-icon)
      (nerd-icons-ivy-rich-project-name))
     :delimiter " ")
    counsel-rpm
    (:columns
     ((nerd-icons-ivy-rich-package-icon)
      (ivy-rich-candidate))
     :delimiter " ")
    counsel-dpkg
    (:columns
     ((nerd-icons-ivy-rich-package-icon)
      (ivy-rich-candidate))
     :delimiter " ")

    counsel-ack
    (:columns
     ((nerd-icons-ivy-rich-grep-file-icon)
      (nerd-icons-ivy-rich-grep-transformer))
     :delimiter " ")
    counsel-ag
    (:columns
     ((nerd-icons-ivy-rich-grep-file-icon)
      (nerd-icons-ivy-rich-grep-transformer))
     :delimiter " ")
    counsel-pt
    (:columns
     ((nerd-icons-ivy-rich-grep-file-icon)
      (nerd-icons-ivy-rich-grep-transformer))
     :delimiter " ")
    counsel-rg
    (:columns
     ((nerd-icons-ivy-rich-grep-file-icon)
      (nerd-icons-ivy-rich-grep-transformer))
     :delimiter " ")

    ;; Execute command
    execute-extended-command
    (:columns
     ((nerd-icons-ivy-rich-function-icon)
      (counsel-M-x-transformer (:width 0.3))
      (ivy-rich-counsel-function-docstring (:face nerd-icons-ivy-rich-doc-face))))
    execute-extended-command-for-buffer
    (:columns
     ((nerd-icons-ivy-rich-function-icon)
      (counsel-M-x-transformer (:width 0.3))
      (ivy-rich-counsel-function-docstring (:face nerd-icons-ivy-rich-doc-face))))

    ;; Kill buffer
    kill-buffer
    (:columns
     ((nerd-icons-ivy-rich-buffer-icon)
      (ivy-switch-buffer-transformer (:width 0.3))
      (ivy-rich-switch-buffer-size (:width 7 :face nerd-icons-ivy-rich-size-face))
      (ivy-rich-switch-buffer-indicators (:width 4 :face nerd-icons-ivy-rich-indicator-face :align right))
      (nerd-icons-ivy-rich-switch-buffer-major-mode (:width 18 :face nerd-icons-ivy-rich-major-mode-face))
      (ivy-rich-switch-buffer-project (:width 0.12 :face nerd-icons-ivy-rich-project-face))
      (ivy-rich-switch-buffer-path (:width (lambda (x) (ivy-rich-switch-buffer-shorten-path x (ivy-rich-minibuffer-width 0.3))) :face nerd-icons-ivy-rich-path-face)))
     :predicate
     (lambda (cand) (get-buffer cand))
     :delimiter " ")

    ;; projectile
    projectile-completing-read
    (:columns
     ((nerd-icons-ivy-rich-file-icon)
      (nerd-icons-ivy-rich-project-find-file-transformer (:width 0.4))
      (nerd-icons-ivy-rich-project-file-id (:width 15 :face nerd-icons-ivy-rich-file-owner-face :align right))
      (nerd-icons-ivy-rich-project-file-modes (:width 12))
      (nerd-icons-ivy-rich-project-file-size (:width 7 :face nerd-icons-ivy-rich-size-face))
      (nerd-icons-ivy-rich-project-file-modification-time (:face nerd-icons-ivy-rich-time-face)))
     :delimiter " ")

    ;; project
    project-execute-extended-command
    (:columns
     ((nerd-icons-ivy-rich-function-icon)
      (counsel-M-x-transformer (:width 0.3))
      (ivy-rich-counsel-function-docstring (:face nerd-icons-ivy-rich-doc-face))))
    project-switch-project
    (:columns
     ((nerd-icons-ivy-rich-project-icon)
      (nerd-icons-ivy-rich-project-name))
     :delimiter " ")
    project-find-file
    (:columns
     ((nerd-icons-ivy-rich-file-icon)
      (nerd-icons-ivy-rich-project-find-file-transformer (:width 0.4))
      (nerd-icons-ivy-rich-project-file-id (:width 15 :face nerd-icons-ivy-rich-file-owner-face :align right))
      (nerd-icons-ivy-rich-project-file-modes (:width 12))
      (nerd-icons-ivy-rich-project-file-size (:width 7 :face nerd-icons-ivy-rich-size-face))
      (nerd-icons-ivy-rich-project-file-modification-time (:face nerd-icons-ivy-rich-time-face)))
     :delimiter " ")
    project-or-external-find-file
    (:columns
     ((nerd-icons-ivy-rich-file-icon)
      (nerd-icons-ivy-rich-project-find-file-transformer (:width 0.4))
      (nerd-icons-ivy-rich-project-file-id (:width 15 :face nerd-icons-ivy-rich-file-owner-face :align right))
      (nerd-icons-ivy-rich-project-file-modes (:width 12))
      (nerd-icons-ivy-rich-project-file-size (:width 7 :face nerd-icons-ivy-rich-size-face))
      (nerd-icons-ivy-rich-project-file-modification-time (:face nerd-icons-ivy-rich-time-face)))
     :delimiter " ")
    project-find-dir
    (:columns
     ((nerd-icons-ivy-rich-file-icon)
      (ivy-rich-candidate (:width 0.4))
      (nerd-icons-ivy-rich-project-file-id (:width 15 :face nerd-icons-ivy-rich-file-owner-face :align right))
      (nerd-icons-ivy-rich-project-file-modes (:width 12))
      (nerd-icons-ivy-rich-project-file-size (:width 7 :face nerd-icons-ivy-rich-size-face))
      (nerd-icons-ivy-rich-project-file-modification-time (:face nerd-icons-ivy-rich-time-face)))
     :delimiter " ")
    project-find-regexp
    (:columns
     ((nerd-icons-ivy-rich-grep-file-icon)
      (nerd-icons-ivy-rich-grep-transformer))
     :delimiter " ")

    ;; package
    package-install
    (:columns
     ((nerd-icons-ivy-rich-package-icon)
      (ivy-rich-candidate (:width 0.25))
      (nerd-icons-ivy-rich-package-version (:width 16 :face nerd-icons-ivy-rich-version-face))
      (nerd-icons-ivy-rich-package-status (:width 12))
      (nerd-icons-ivy-rich-package-archive-summary (:width 7 :face nerd-icons-ivy-rich-archive-face))
      (nerd-icons-ivy-rich-package-install-summary (:face nerd-icons-ivy-rich-pacage-desc-face)))
     :delimiter " ")
    package-reinstall
    (:columns
     ((nerd-icons-ivy-rich-package-icon)
      (ivy-rich-candidate (:width 0.25))
      (nerd-icons-ivy-rich-package-version (:width 16 :face nerd-icons-ivy-rich-version-face))
      (nerd-icons-ivy-rich-package-status (:width 12))
      (nerd-icons-ivy-rich-package-archive-summary (:width 7 :face nerd-icons-ivy-rich-archive-face))
      (nerd-icons-ivy-rich-package-install-summary (:face nerd-icons-ivy-rich-pacage-desc-face)))
     :delimiter " ")
    package-delete
    (:columns
     ((nerd-icons-ivy-rich-package-icon)
      (nerd-icons-ivy-rich-package-name (:width 0.25))
      (nerd-icons-ivy-rich-package-version (:width 16 :face nerd-icons-ivy-rich-version-face))
      (nerd-icons-ivy-rich-package-status (:width 12))
      (nerd-icons-ivy-rich-package-archive-summary (:width 7 :face nerd-icons-ivy-rich-archive-face))
      (nerd-icons-ivy-rich-package-install-summary (:face nerd-icons-ivy-rich-pacage-desc-face)))
     :delimiter " ")
    package-recompile
    (:columns
     ((nerd-icons-ivy-rich-package-icon)
      (ivy-rich-candidate (:width 0.25))
      (nerd-icons-ivy-rich-package-version (:width 16 :face nerd-icons-ivy-rich-version-face))
      (nerd-icons-ivy-rich-package-status (:width 12))
      (nerd-icons-ivy-rich-package-archive-summary (:width 7 :face nerd-icons-ivy-rich-archive-face))
      (nerd-icons-ivy-rich-package-install-summary (:face nerd-icons-ivy-rich-pacage-desc-face)))
     :delimiter " ")
    package-update
    (:columns
     ((nerd-icons-ivy-rich-package-icon)
      (ivy-rich-candidate (:width 0.25))
      (nerd-icons-ivy-rich-package-version (:width 16 :face nerd-icons-ivy-rich-version-face))
      (nerd-icons-ivy-rich-package-status (:width 12))
      (nerd-icons-ivy-rich-package-archive-summary (:width 7 :face nerd-icons-ivy-rich-archive-face))
      (nerd-icons-ivy-rich-package-install-summary (:face nerd-icons-ivy-rich-pacage-desc-face)))
     :delimiter " ")
    package-vc-checkout
    (:columns
     ((nerd-icons-ivy-rich-package-icon)
      (ivy-rich-candidate (:width 0.25))
      (nerd-icons-ivy-rich-package-version (:width 16 :face nerd-icons-ivy-rich-version-face))
      (nerd-icons-ivy-rich-package-status (:width 12))
      (nerd-icons-ivy-rich-package-archive-summary (:width 7 :face nerd-icons-ivy-rich-archive-face))
      (nerd-icons-ivy-rich-package-install-summary (:face nerd-icons-ivy-rich-pacage-desc-face)))
     :delimiter " ")
    package-vc-install
    (:columns
     ((nerd-icons-ivy-rich-package-icon)
      (ivy-rich-candidate (:width 0.25))
      (nerd-icons-ivy-rich-package-version (:width 16 :face nerd-icons-ivy-rich-version-face))
      (nerd-icons-ivy-rich-package-status (:width 12))
      (nerd-icons-ivy-rich-package-archive-summary (:width 7 :face nerd-icons-ivy-rich-archive-face))
      (nerd-icons-ivy-rich-package-install-summary (:face nerd-icons-ivy-rich-pacage-desc-face)))
     :delimiter " ")
    package-vc-update
    (:columns
     ((nerd-icons-ivy-rich-package-icon)
      (ivy-rich-candidate (:width 0.25))
      (nerd-icons-ivy-rich-package-version (:width 16 :face nerd-icons-ivy-rich-version-face))
      (nerd-icons-ivy-rich-package-status (:width 12))
      (nerd-icons-ivy-rich-package-archive-summary (:width 7 :face nerd-icons-ivy-rich-archive-face))
      (nerd-icons-ivy-rich-package-install-summary (:face nerd-icons-ivy-rich-pacage-desc-face)))
     :delimiter " ")

    ;; persp
    persp-switch-to-buffer
    (:columns
     ((nerd-icons-ivy-rich-buffer-icon)
      (ivy-switch-buffer-transformer (:width 0.3))
      (ivy-rich-switch-buffer-size (:width 7 :face nerd-icons-ivy-rich-size-face))
      (ivy-rich-switch-buffer-indicators (:width 4 :face nerd-icons-ivy-rich-indicator-face :align right))
      (nerd-icons-ivy-rich-switch-buffer-major-mode (:width 18 :face nerd-icons-ivy-rich-major-mode-face))
      (ivy-rich-switch-buffer-project (:width 0.12 :face nerd-icons-ivy-rich-project-face))
      (ivy-rich-switch-buffer-path (:width (lambda (x) (ivy-rich-switch-buffer-shorten-path x (ivy-rich-minibuffer-width 0.3))) :face nerd-icons-ivy-rich-path-face)))
     :predicate
     (lambda (cand) (get-buffer cand))
     :delimiter " ")
    persp-switch
    (:columns
     ((nerd-icons-ivy-rich-project-icon)
      (ivy-rich-candidate (:face nerd-icons-ivy-rich-persp-face)))
     :delimiter " ")
    persp-frame-switch
    (:columns
     ((nerd-icons-ivy-rich-project-icon)
      (ivy-rich-candidate (:face nerd-icons-ivy-rich-persp-face)))
     :delimiter " ")
    persp-window-switch
    (:columns
     ((nerd-icons-ivy-rich-project-icon)
      (ivy-rich-candidate (:face nerd-icons-ivy-rich-persp-face)))
     :delimiter " ")
    persp-kill
    (:columns
     ((nerd-icons-ivy-rich-project-icon)
      (ivy-rich-candidate (:face nerd-icons-ivy-rich-persp-face)))
     :delimiter " ")
    persp-save-and-kill
    (:columns
     ((nerd-icons-ivy-rich-project-icon)
      (ivy-rich-candidate (:face nerd-icons-ivy-rich-persp-face)))
     :delimiter " ")
    persp-import-buffers
    (:columns
     ((nerd-icons-ivy-rich-project-icon)
      (ivy-rich-candidate (:face nerd-icons-ivy-rich-persp-face)))
     :delimiter " ")
    persp-import-win-conf
    (:columns
     ((nerd-icons-ivy-rich-project-icon)
      (ivy-rich-candidate (:face nerd-icons-ivy-rich-persp-face)))
     :delimiter " ")
    persp-kill-buffer
    (:columns
     ((nerd-icons-ivy-rich-buffer-icon)
      (ivy-switch-buffer-transformer (:width 0.3))
      (ivy-rich-switch-buffer-size (:width 7 :face nerd-icons-ivy-rich-size-face))
      (ivy-rich-switch-buffer-indicators (:width 4 :face nerd-icons-ivy-rich-indicator-face :align right))
      (nerd-icons-ivy-rich-switch-buffer-major-mode (:width 18 :face nerd-icons-ivy-rich-major-mode-face))
      (ivy-rich-switch-buffer-project (:width 0.12 :face nerd-icons-ivy-rich-project-face))
      (ivy-rich-switch-buffer-path (:width (lambda (x) (ivy-rich-switch-buffer-shorten-path x (ivy-rich-minibuffer-width 0.3))) :face nerd-icons-ivy-rich-path-face)))
     :predicate
     (lambda (cand) (get-buffer cand))
     :delimiter " ")
    persp-remove-buffer
    (:columns
     ((nerd-icons-ivy-rich-buffer-icon)
      (ivy-switch-buffer-transformer (:width 0.3))
      (ivy-rich-switch-buffer-size (:width 7 :face nerd-icons-ivy-rich-size-face))
      (ivy-rich-switch-buffer-indicators (:width 4 :face nerd-icons-ivy-rich-indicator-face :align right))
      (nerd-icons-ivy-rich-switch-buffer-major-mode (:width 18 :face nerd-icons-ivy-rich-major-mode-face))
      (ivy-rich-switch-buffer-project (:width 0.12 :face nerd-icons-ivy-rich-project-face))
      (ivy-rich-switch-buffer-path (:width (lambda (x) (ivy-rich-switch-buffer-shorten-path x (ivy-rich-minibuffer-width 0.3))) :face nerd-icons-ivy-rich-path-face)))
     :predicate
     (lambda (cand) (get-buffer cand))
     :delimiter " ")
    persp-add-buffer
    (:columns
     ((nerd-icons-ivy-rich-buffer-icon)
      (ivy-switch-buffer-transformer (:width 0.3))
      (ivy-rich-switch-buffer-size (:width 7 :face nerd-icons-ivy-rich-size-face))
      (ivy-rich-switch-buffer-indicators (:width 4 :face nerd-icons-ivy-rich-indicator-face :align right))
      (nerd-icons-ivy-rich-switch-buffer-major-mode (:width 18 :face nerd-icons-ivy-rich-major-mode-face))
      (ivy-rich-switch-buffer-project (:width 0.12 :face nerd-icons-ivy-rich-project-face))
      (ivy-rich-switch-buffer-path (:width (lambda (x) (ivy-rich-switch-buffer-shorten-path x (ivy-rich-minibuffer-width 0.3))) :face nerd-icons-ivy-rich-path-face)))
     :predicate
     (lambda (cand) (get-buffer cand))
     :delimiter " ")

    org-switchb
    (:columns
     ((nerd-icons-ivy-rich-buffer-icon)
      (ivy-switch-buffer-transformer (:width 0.3))
      (ivy-rich-switch-buffer-size (:width 7 :face nerd-icons-ivy-rich-size-face))
      (ivy-rich-switch-buffer-indicators (:width 4 :face nerd-icons-ivy-rich-indicator-face :align right))
      (nerd-icons-ivy-rich-switch-buffer-major-mode (:width 18 :face nerd-icons-ivy-rich-major-mode-face))
      (ivy-rich-switch-buffer-project (:width 0.12 :face nerd-icons-ivy-rich-project-face))
      (ivy-rich-switch-buffer-path (:width (lambda (x) (ivy-rich-switch-buffer-shorten-path x (ivy-rich-minibuffer-width 0.3))) :face nerd-icons-ivy-rich-path-face)))
     :predicate
     (lambda (cand) (get-buffer cand))
     :delimiter " ")

    customize-group
    (:columns
     ((nerd-icons-ivy-rich-group-settings-icon)
      (ivy-rich-candidate (:width 0.3))
      (nerd-icons-ivy-rich-custom-group-docstring (:face nerd-icons-ivy-rich-doc-face)))
     :delimiter " ")
    customize-group-other-window
    (:columns
     ((nerd-icons-ivy-rich-group-settings-icon)
      (ivy-rich-candidate (:width 0.3))
      (nerd-icons-ivy-rich-custom-group-docstring (:face nerd-icons-ivy-rich-doc-face)))
     :delimiter " ")
    customize-option
    (:columns
     ((nerd-icons-ivy-rich-variable-settings-icon)
      (ivy-rich-candidate (:width 0.3))
      (nerd-icons-ivy-rich-custom-variable-docstring (:face nerd-icons-ivy-rich-doc-face)))
     :delimiter " ")
    customize-option-other-window
    (:columns
     ((nerd-icons-ivy-rich-variable-settings-icon)
      (ivy-rich-candidate (:width 0.3))
      (nerd-icons-ivy-rich-custom-variable-docstring (:face nerd-icons-ivy-rich-doc-face)))
     :delimiter " ")
    customize-variable
    (:columns
     ((nerd-icons-ivy-rich-variable-settings-icon)
      (ivy-rich-candidate (:width 0.3))
      (nerd-icons-ivy-rich-custom-variable-docstring (:face nerd-icons-ivy-rich-doc-face)))
     :delimiter " ")
    customize-variable-other-window
    (:columns
     ((nerd-icons-ivy-rich-variable-settings-icon)
      (ivy-rich-candidate (:width 0.3))
      (nerd-icons-ivy-rich-custom-variable-docstring (:face nerd-icons-ivy-rich-doc-face)))
     :delimiter " ")

    describe-character-set
    (:columns
     ((nerd-icons-ivy-rich-charset-icon)
      (ivy-rich-candidate (:width 0.3))
      (nerd-icons-ivy-rich-charset-docstring (:face nerd-icons-ivy-rich-doc-face)))
     :delimiter " ")

    describe-coding-system
    (:columns
     ((nerd-icons-ivy-rich-coding-system-icon)
      (ivy-rich-candidate (:width 0.3))
      (nerd-icons-ivy-rich-coding-system-docstring (:face nerd-icons-ivy-rich-doc-face)))
     :delimiter " ")

    describe-language-environment
    (:columns
     ((nerd-icons-ivy-rich-lang-icon)
      (ivy-rich-candidate))
     :delimiter " ")

    describe-input-method
    (:columns
     ((nerd-icons-ivy-rich-input-method-icon)
      (ivy-rich-candidate (:width 0.3))
      (nerd-icons-ivy-rich-input-method-docstring (:face nerd-icons-ivy-rich-doc-face)))
     :delimiter " ")

    set-input-method
    (:columns
     ((nerd-icons-ivy-rich-input-method-icon)
      (ivy-rich-candidate (:width 0.3))
      (nerd-icons-ivy-rich-input-method-docstring (:face nerd-icons-ivy-rich-doc-face)))
     :delimiter " ")

    remove-hook
    (:columns
     ((nerd-icons-ivy-rich-variable-icon)
      (counsel-describe-variable-transformer (:width 0.3))
      (nerd-icons-ivy-rich-symbol-class (:width 8 :face nerd-icons-ivy-rich-type-face))
      (nerd-icons-ivy-rich-variable-value (:width 0.12))
      (ivy-rich-counsel-variable-docstring (:face nerd-icons-ivy-rich-doc-face))))

    markdown-insert-link
    (:columns
     ((nerd-icons-ivy-rich-link-icon)
      (ivy-rich-candidate))
     :delimiter " ")
    markdown-insert-image
    (:columns
     ((nerd-icons-ivy-rich-link-icon)
      (ivy-rich-candidate))
     :delimiter " ")

    getenv
    (:columns
     ((nerd-icons-ivy-rich-key-icon)
      (ivy-rich-candidate (:face nerd-icons-ivy-rich-string-face)))
     :delimiter " ")
    setenv
    (:columns
     ((nerd-icons-ivy-rich-key-icon)
      (ivy-rich-candidate (:face nerd-icons-ivy-rich-string-face)))
     :delimiter " ")

    lsp-install-server
    (:columns
     ((nerd-icons-ivy-rich-lsp-icon)
      (ivy-rich-candidate))
     :delimiter " ")
    lsp-update-server
    (:columns
     ((nerd-icons-ivy-rich-lsp-icon)
      (ivy-rich-candidate))
     :delimiter " ")
    lsp-uninstall-server
    (:columns
     ((nerd-icons-ivy-rich-lsp-icon)
      (ivy-rich-candidate))
     :delimiter " ")
    lsp-ivy-workspace-folders-remove
    (:columns
     ((nerd-icons-ivy-rich-dir-icon)
      (ivy-rich-candidate))
     :delimiter " ")

    magit-find-file
    (:columns
     ((nerd-icons-ivy-rich-magit-file-icon)
      (nerd-icons-ivy-rich-file-name (:width 0.4))
      (nerd-icons-ivy-rich-file-id (:width 15 :face nerd-icons-ivy-rich-file-owner-face :align right))
      (nerd-icons-ivy-rich-file-modes (:width 12))
      (nerd-icons-ivy-rich-file-size (:width 7 :face nerd-icons-ivy-rich-size-face))
      (nerd-icons-ivy-rich-file-modification-time (:face nerd-icons-ivy-rich-time-face)))
     :delimiter " ")
    magit-find-file-other-frame
    (:columns
     ((nerd-icons-ivy-rich-magit-file-icon)
      (nerd-icons-ivy-rich-file-name (:width 0.4))
      (nerd-icons-ivy-rich-file-id (:width 15 :face nerd-icons-ivy-rich-file-owner-face :align right))
      (nerd-icons-ivy-rich-file-modes (:width 12))
      (nerd-icons-ivy-rich-file-size (:width 7 :face nerd-icons-ivy-rich-size-face))
      (nerd-icons-ivy-rich-file-modification-time (:face nerd-icons-ivy-rich-time-face)))
     :delimiter " ")
    magit-find-file-other-window
    (:columns
     ((nerd-icons-ivy-rich-magit-file-icon)
      (nerd-icons-ivy-rich-file-name (:width 0.4))
      (nerd-icons-ivy-rich-file-id (:width 15 :face nerd-icons-ivy-rich-file-owner-face :align right))
      (nerd-icons-ivy-rich-file-modes (:width 12))
      (nerd-icons-ivy-rich-file-size (:width 7 :face nerd-icons-ivy-rich-size-face))
      (nerd-icons-ivy-rich-file-modification-time (:face nerd-icons-ivy-rich-time-face)))
     :delimiter " ")
    ivy-magit-todos
    (:columns
     ((nerd-icons-ivy-rich-magit-todos-icon)
      (nerd-icons-ivy-rich-magit-todos-transformer))
     :delimiter " ")

    treemacs-projectile
    (:columns
     ((nerd-icons-ivy-rich-project-icon)
      (nerd-icons-ivy-rich-project-name))
     :delimiter " "))
  "Definitions for ivy-rich transformers.

See `ivy-rich-display-transformers-list' for details."
  :group 'nerd-icons-ivy-rich
  :type '(repeat sexp))


;;
;; Utilities
;;

;; Support`ivy-switch-buffer'
(defun nerd-icons-ivy-rich-switch-buffer-major-mode (cand)
  "Return the mode name for CAND."
  (format-mode-line (ivy-rich--local-values cand 'mode-name)))

;; Support `kill-buffer'
(defun nerd-icons-ivy-rich-kill-buffer (fn &optional buffer-or-name)
  "Kill the buffer specified by BUFFER-OR-NAME."
  (interactive
   (list (completing-read (format "Kill buffer (default %s): " (buffer-name))
                          (mapcar (lambda (b)
                                    (buffer-name b))
                                  (buffer-list))
                          nil t nil nil
                          (buffer-name))))
  (funcall fn buffer-or-name))

(defun nerd-icons-ivy-rich--project-root ()
  "Get the path to the root of your project.
Return `default-directory' if no project was found."
  (when nerd-icons-ivy-rich-project
    (cond
     ;; Ignore remote files due to performance issue
     ((file-remote-p default-directory)
      default-directory)
     ((fboundp 'ffip-project-root)
      (let ((inhibit-message t))
        (ffip-project-root)))
     ((bound-and-true-p projectile-mode)
      (projectile-project-root))
     ((fboundp 'project-current)
      (when-let ((project (project-current)))
        (expand-file-name
         (if (fboundp 'project-root)
             (project-root project)
           (car (with-no-warnings (project-roots project)))))))
     (t default-directory))))

(defun nerd-icons-ivy-rich--file-path (cand)
  "Get the file path of CAND."
  (if (eq (ivy-state-caller ivy-last) 'counsel-fzf)
      (expand-file-name cand counsel--fzf-dir)
    (expand-file-name cand ivy--directory)))

(defun nerd-icons-ivy-rich--project-file-path (cand)
  "Get the project file path of CAND."
  (expand-file-name cand (nerd-icons-ivy-rich--project-root)))

(defun nerd-icons-ivy-rich-project-find-file-transformer (cand)
  "Transform non-visited file name of CAND with `ivy-virtual' face."
  (cond
   ((or (ivy--dirname-p cand)
        (file-directory-p (nerd-icons-ivy-rich--file-path cand)))
    (propertize cand 'face 'ivy-subdir))
   ((not (get-file-buffer
          (expand-file-name cand (nerd-icons-ivy-rich--project-root))))
    (propertize cand 'face 'ivy-virtual))
   (t cand)))

(defvar nerd-icons-ivy-rich--file-modes-cache nil
  "File modes cache.")
(defun nerd-icons-ivy-rich--file-modes (file)
  "Return FILE modes."
  (cond
   ((file-remote-p file) "")
   ((not (file-exists-p file)) "")
   (t (let ((modes (file-attribute-modes (file-attributes file))))
        (or (car (member modes nerd-icons-ivy-rich--file-modes-cache))
            (progn
              (dotimes (i (length modes))
                (put-text-property
                 i (1+ i) 'face
                 (pcase (aref modes i)
                   (?- 'nerd-icons-ivy-rich-file-priv-no)
                   (?d 'nerd-icons-ivy-rich-file-priv-dir)
                   (?l 'nerd-icons-ivy-rich-file-priv-link)
                   (?r 'nerd-icons-ivy-rich-file-priv-read)
                   (?w 'nerd-icons-ivy-rich-file-priv-write)
                   (?x 'nerd-icons-ivy-rich-file-priv-exec)
                   ((or ?s ?S ?t ?T) 'nerd-icons-ivy-rich-file-priv-other)
                   (_ 'nerd-icons-ivy-rich-file-priv-rare))
                 modes))
              (push modes nerd-icons-ivy-rich--file-modes-cache)
              modes)
            "")))))

(defun nerd-icons-ivy-rich--file-id (path)
  "Return file uid/gid for PATH."
  (cond
   ((file-remote-p path) "")
   ((not (file-exists-p path)) "")
   (t (let* ((attrs (file-attributes path 'integer))
             (uid (file-attribute-user-id attrs))
             (gid (file-attribute-group-id attrs)))
        (if (or (/= (user-uid) uid) (/= (group-gid) gid))
            (let* ((attributes (file-attributes path 'string))
                   (user (file-attribute-user-id attributes))
                   (group (file-attribute-group-id attributes)))
              (format " %s:%s " user group))
          "")))))

(defun nerd-icons-ivy-rich--file-size (file)
  "Return FILE size."
  (cond
   ((file-remote-p file) "")
   ((not (file-exists-p file)) "")
   (t (file-size-human-readable (file-attribute-size (file-attributes file))))))

(defun nerd-icons-ivy-rich--file-modification-time (file)
  "Return FILE modification time."
  (cond
   ((file-remote-p file) "")
   ((not (file-exists-p file)) "")
   (t (format-time-string
       "%b %d %R"
       (file-attribute-modification-time (file-attributes file))))))

;; Support `counsel-find-file', `counsel-dired', etc.
(defun nerd-icons-ivy-rich-file-name (cand)
  "Return file name for CAND when reading files.
Display directories with different color.
Display the true name when the file is a symlink."
  (let* ((file (ivy-read-file-transformer cand))
         (path (nerd-icons-ivy-rich--file-path cand))
         (type (unless (file-remote-p path)
                 (file-symlink-p path))))
    (if (stringp type)
        (concat file
                (propertize (concat " -> " type)
                            'face 'nerd-icons-ivy-rich-doc-face))
      file)))

(defun nerd-icons-ivy-rich-file-modes (cand)
  "Return file modes for CAND."
  (nerd-icons-ivy-rich--file-modes
   (nerd-icons-ivy-rich--file-path cand)))

(defun nerd-icons-ivy-rich-file-id (cand)
  "Return file uid/gid for CAND."
  (nerd-icons-ivy-rich--file-id
   (nerd-icons-ivy-rich--file-path cand)))

(defun nerd-icons-ivy-rich-file-size (cand)
  "Return file size for CAND."
  (nerd-icons-ivy-rich--file-size
   (nerd-icons-ivy-rich--file-path cand)))

(defun nerd-icons-ivy-rich-file-modification-time (cand)
  "Return file modification time for CAND."
  (nerd-icons-ivy-rich--file-modification-time
   (nerd-icons-ivy-rich--file-path cand)))

;; Support `counsel-projectile-find-file', `counsel-projectile-dired', etc.
(defun nerd-icons-ivy-rich-project-name (cand)
  "Return project name for CAND."
  (if (or (ivy--dirname-p cand)
          (file-directory-p (nerd-icons-ivy-rich--file-path cand)))
      (propertize (abbreviate-file-name cand) 'face 'ivy-subdir)
    (abbreviate-file-name cand)))

(defun nerd-icons-ivy-rich-project-file-modes (cand)
"Return file modes for CAND."
(nerd-icons-ivy-rich--file-modes
 (nerd-icons-ivy-rich--project-file-path cand)))

(defun nerd-icons-ivy-rich-project-file-id (cand)
  "Return file uid/gid for CAND."
  (nerd-icons-ivy-rich--file-id
   (nerd-icons-ivy-rich--project-file-path cand)))

(defun nerd-icons-ivy-rich-project-file-size (cand)
  "Return file size for CAND."
  (nerd-icons-ivy-rich--file-size
   (nerd-icons-ivy-rich--project-file-path cand)))

(defun nerd-icons-ivy-rich-project-file-modification-time (cand)
  "Return file modification time for CAND."
  (nerd-icons-ivy-rich--file-modification-time
   (nerd-icons-ivy-rich--project-file-path cand)))

;; Support `counsel-bookmark'
(defun nerd-icons-ivy-rich-bookmark-name (cand)
  "Return bookmark name for CAND."
  (car (assoc cand bookmark-alist)))

(defun nerd-icons-ivy-rich-bookmark-filename (cand)
  "Return bookmark info for CAND."
  (let ((file (ivy-rich-bookmark-filename cand)))
    (cond
     ((null file) "")
     ((file-remote-p file) file)
     (t file))))

(defun nerd-icons-ivy-rich-bookmark-context (cand)
  "Return bookmark context for CAND."
  (let ((context (bookmark-get-front-context-string
                  (assoc cand (bound-and-true-p bookmark-alist)))))
    (if (and context (not (string-empty-p context)))
        (concat (string-trim
                 (replace-regexp-in-string
                  "[ \t]+" " "
                  (replace-regexp-in-string "\n" "\\\\n" context)))
                "…")
      "")))

;; Support `counsel-package', `package-delete', `package-reinstall' and `package-delete'
(defun nerd-icons-ivy-rich-package-name (cand)
  "Return formalized package name for CAND."
  (replace-regexp-in-string "-[[:digit:]]+\\.?[[:digit:]+\\.]+\\'" ""
                            (replace-regexp-in-string "^\\(\\+\\|-\\)" "" cand)))

(defun nerd-icons-ivy-rich-package-status (cand)
  "Return package status for CAND."
  (let* ((pkg-alist (bound-and-true-p package-alist))
         (pkg (intern-soft (nerd-icons-ivy-rich-package-name cand)))
         ;; taken from `describe-package-1'
         (pkg-desc (or (car (alist-get pkg pkg-alist))
                       (if-let (built-in (assq pkg package--builtins))
                           (package--from-builtin built-in)
                         (car (alist-get pkg package-archive-contents))))))
    (if-let ((status (and pkg-desc (package-desc-status pkg-desc))))
        (cond ((string= status "available")
               (propertize status 'face 'nerd-icons-ivy-rich-package-status-avaible-face))
              ((string= status "new")
               (propertize status 'face 'nerd-icons-ivy-rich-package-status-new-face))
              ((string= status "held")
               (propertize status 'face 'nerd-icons-ivy-rich-package-status-held-face))
              ((member status '("avail-obso" "installed" "dependency" "incompat" "deleted"))
               (propertize status 'face 'nerd-icons-ivy-rich-package-status-installed-face))
              ((member status '("disabled" "unsigned"))
               (propertize status 'face 'nerd-icons-ivy-rich-package-status-warn-face))
              (t status))
      (propertize "orphan" 'face 'nerd-icons-ivy-rich-error-face))))

(defun nerd-icons-ivy-rich-package-install-summary (cand)
  "Return package install summary for CAND. Used for `counsel-package'."
  (ivy-rich-package-install-summary (nerd-icons-ivy-rich-package-name cand)))

(defun nerd-icons-ivy-rich-package-archive-summary (cand)
  "Return package archive summary for CAND. Used for `counsel-package'."
  (ivy-rich-package-archive-summary (nerd-icons-ivy-rich-package-name cand)))

(defun nerd-icons-ivy-rich-package-version (cand)
  "Return package version for CAND. Used for `counsel-package'."
  (ivy-rich-package-version (nerd-icons-ivy-rich-package-name cand)))

(defun nerd-icons-ivy-rich--truncate-docstring (doc)
  "Truncate DOC string."
  (if (and doc (string-match "^\\(.+\\)\\([\r\n]\\)?" doc))
      (truncate-string-to-width (match-string 1 doc) 80)
    ""))

;; Support `counsel-describe-face'
(defun nerd-icons-ivy-rich-face-docstring (cand)
  "Return face's documentation for CAND."
  (nerd-icons-ivy-rich--truncate-docstring
   (documentation-property (intern-soft cand) 'face-documentation)))

;; Support `counsel-describe-function'and `counsel-describe-variable'
(defun nerd-icons-ivy-rich-function-args (cand)
  "Return function arguments for CAND."
  (let ((sym (intern-soft cand))
        (tmp))
    (or
     (elisp-function-argstring
      (cond
       ((listp (setq tmp (gethash (indirect-function sym)
                                  advertised-signature-table t)))
        tmp)
       ((setq tmp (help-split-fundoc
		           (ignore-errors (documentation sym t))
		           sym))
        (substitute-command-keys (car tmp)))
       ((setq tmp (help-function-arglist sym))
        (if (and (stringp tmp)
                 (string-match-p "Arg list not available" tmp))
            "[autoload]"
          tmp))))
     "")))

(defun nerd-icons-ivy-rich-variable-value (cand)
  "Return the variable value of CAND as string."
  (let ((sym (intern-soft cand)))
    (cond
     ((not (boundp sym))
      (propertize "#<unbound>" 'face 'nerd-icons-ivy-rich-null-face))
     (t (let ((val (symbol-value sym)))
          (pcase val
            ('nil (propertize "nil" 'face 'nerd-icons-ivy-rich-null-face))
            ('t (propertize "t" 'face 'nerd-icons-ivy-rich-true-face))
            ((pred keymapp) (propertize "#<keymap>" 'face 'nerd-icons-ivy-rich-value-face))
            ((pred bool-vector-p) (propertize "#<bool-vector>" 'face 'nerd-icons-ivy-rich-value-face))
            ((pred hash-table-p) (propertize "#<hash-table>" 'face 'nerd-icons-ivy-rich-value-face))
            ((pred syntax-table-p) (propertize "#<syntax-table>" 'face 'nerd-icons-ivy-rich-value-face))
            ;; Emacs BUG: abbrev-table-p throws an error
            ((guard (ignore-errors (abbrev-table-p val))) (propertize "#<abbrev-table>" 'face 'nerd-icons-ivy-rich-value-face))
            ((pred char-table-p) (propertize "#<char-table>" 'face 'nerd-icons-ivy-rich-value-face))
            ((pred byte-code-function-p) (propertize "#<byte-code-function>" 'face 'nerd-icons-ivy-rich-function-face))
            ((and (pred functionp) (pred symbolp))
             ;; NOTE: We are not consistent here, values are generally printed unquoted. But we
             ;; make an exception for function symbols to visually distinguish them from symbols.
             ;; I am not entirely happy with this, but we should not add quotation to every type.
             (format (propertize "#'%s" 'face 'nerd-icons-ivy-rich-function-face) val))
            ((pred recordp) (format (propertize "#<record %s>" 'face 'nerd-icons-ivy-rich-value-face) (type-of val)))
            ((pred symbolp) (propertize (symbol-name val) 'face 'nerd-icons-ivy-rich-symbol-face))
            ((pred numberp) (propertize (number-to-string val) 'face 'nerd-icons-ivy-rich-number-face))
            (_ (let ((print-escape-newlines t)
                     (print-escape-control-characters t)
                     (print-escape-multibyte t)
                     (print-level 10)
                     (print-length nerd-icons-ivy-rich-field-width))
                 (propertize
                  (prin1-to-string
                   (if (stringp val)
                       ;; Get rid of string properties to save some of the precious space
                       (substring-no-properties
                        val 0
                        (min (length val) nerd-icons-ivy-rich-field-width))
                     val))
                  'face
                  (cond
                   ((listp val) 'nerd-icons-ivy-rich-list-face)
                   ((stringp val) 'nerd-icons-ivy-rich-string-face)
                   (t 'nerd-icons-ivy-rich-value-face)))))))))))

;; Support `counsel-describe-symbol', `counsel-info-lookup-symbol' and `counsel-apropos'

;; Taken from advice--make-docstring
(defun nerd-icons-ivy-rich--advised (fun)
  "Return t if function FUN is advised."
  (let ((flist (indirect-function fun)))
    (advice--p (if (eq 'macro (car-safe flist)) (cdr flist) flist))))

;; Symbol class characters from Emacs 28 `help--symbol-completion-table-affixation'
;; ! and * are additions. Same as marginalia
(defun nerd-icons-ivy-rich-symbol-class (cand)
  "Return symbol class characters for symbol CAND.

Function:
f function
c command
C interactive-only command
m macro
M special-form
g cl-generic
p pure
s side-effect-free
@ autoloaded
! advised
- obsolete

Variable:
u custom (U modified compared to global value)
v variable
l local (L modified compared to default value)
- obsolete

Other:
a face
t cl-type"
  (let ((s (intern-soft cand)))
    (format
     "%-6s"
     (concat
      (when (fboundp s)
        (concat
         (cond
          ((get s 'pure) "p")
          ((get s 'side-effect-free) "s"))
         (cond
          ((commandp s) (if (get s 'interactive-only) "C" "c"))
          ((cl-generic-p s) "g")
          ((macrop (symbol-function s)) "m")
          ((special-form-p (symbol-function s)) "M")
          (t "f"))
         (and (autoloadp (symbol-function s)) "@")
         (and (nerd-icons-ivy-rich--advised s) "!")
         (and (get s 'byte-obsolete-info) "-")))
      (when (boundp s)
        (concat
         (when (local-variable-if-set-p s)
           (if (ignore-errors
                 (not (equal (symbol-value s)
                             (default-value s))))
               "L" "l"))
         (if (custom-variable-p s)
             (if (ignore-errors
                   (not (equal
                         (symbol-value s)
                         (eval (car (get s 'standard-value))))))
                 "U" "u")
           "v")
         (and (get s 'byte-obsolete-variable) "-")))
      (and (facep s) "a")
      (and (fboundp 'cl-find-class) (cl-find-class s) "t")))))

(defun nerd-icons-ivy-rich-symbol-docstring (cand)
  "Return symbol's documentation for CAND."
  (let ((symbol (intern-soft cand)))
    (cond
     ((fboundp symbol)
      (ivy-rich-counsel-function-docstring cand))
     ((facep symbol)
      (nerd-icons-ivy-rich-face-docstring cand))
     ((and (boundp symbol) (not (keywordp symbol)))
      (ivy-rich-counsel-variable-docstring cand))
     (t ""))))

;; Support `counsel-imenu'
(defun nerd-icons-ivy-rich-imenu-symbol (cand)
  "Return imenu symbol from CAND."
  (let ((str (split-string cand ": ")))
    (or (cadr str) (car str))))

(defun nerd-icons-ivy-rich-imenu-transformer (cand)
  "Transform imenu CAND."
  (if nerd-icons-ivy-rich-icon
      (let* ((str (nerd-icons-ivy-rich-imenu-symbol cand))
             (s (intern-soft str)))
        (cond
         ((fboundp s) (counsel-describe-function-transformer str))
         ((boundp s) (counsel-describe-variable-transformer str))
         (t str)))
    cand))

(defun nerd-icons-ivy-rich-imenu-class (cand)
  "Return imenu's class characters for CAND.

Only available in `emacs-lisp-mode'."
  (if (derived-mode-p 'emacs-lisp-mode)
      (string-trim
       (nerd-icons-ivy-rich-symbol-class
        (nerd-icons-ivy-rich-imenu-symbol cand)))
    ""))

(defun nerd-icons-ivy-rich-imenu-docstring (cand)
  "Return imenu's documentation for CAND.

Only available in `emacs-lisp-mode'."
  (if (derived-mode-p 'emacs-lisp-mode)
      (nerd-icons-ivy-rich-symbol-docstring
       (nerd-icons-ivy-rich-imenu-symbol cand))
    ""))

;; Support `counsel-descbinds'
(defun nerd-icons-ivy-rich-keybinding-docstring (cand)
  "Return keybinding's documentation for CAND."
  ;; The magic number 15 is from `counsel--descbinds-cands'
  (if (not (string-match-p " ignore" cand))
      (let* ((pos (string-match-p " .+" cand 15))
             (sym (string-trim (substring cand pos))))
        (nerd-icons-ivy-rich-symbol-docstring sym))
    ""))

;; Support `customize-group' and `customize-group-other-window'
(defun nerd-icons-ivy-rich-custom-group-docstring (cand)
  "Return custom group's documentation for CAND."
  (nerd-icons-ivy-rich--truncate-docstring
   (or (documentation-property (intern cand) 'group-documentation) "")))

;; Support `customize-variable' and `customize-variable-other-window'
;; `customize-variable' ia an alias of `customize-option'
(defun nerd-icons-ivy-rich-custom-variable-docstring (cand)
  "Return custom variable's documentation for CAND."
  (nerd-icons-ivy-rich--truncate-docstring
   (or (documentation-property (intern cand) 'variable-documentation) "")))

;; Support `describe-character-set'
(defun nerd-icons-ivy-rich-charset-docstring (cand)
  "Return charset's documentation for CAND."
  (nerd-icons-ivy-rich--truncate-docstring (charset-description (intern cand))))

;; Support `describe-coding-system'
(defun nerd-icons-ivy-rich-coding-system-docstring (cand)
  "Return coding system's documentation for CAND."
  (nerd-icons-ivy-rich--truncate-docstring (coding-system-doc-string (intern cand))))

;; Support `set-input-method'
(defun nerd-icons-ivy-rich-input-method-docstring (cand)
  "Return input method's documentation for CAND."
  (nth 4 (assoc cand input-method-alist)))

;; Support `counsel-list-processes'
(defun nerd-icons-ivy-rich-process-id (cand)
  "Return process id for CAND.

For a network, serial, and pipe connections, return \"--\"."
  (let ((p (get-process cand)))
    (when (processp p)
      (format "%s" (or (process-id p) "--")))))

(defun nerd-icons-ivy-rich-process-status (cand)
  "Return process status for CAND."
  (let ((p (get-process cand)))
    (when (processp p)
      (let* ((status (process-status p))
             (face (if (memq status '(stop exit closed failed))
                       'nerd-icons-ivy-rich-process-status-alt-face
                     'nerd-icons-ivy-rich-process-status-face)))
        (propertize (symbol-name status) 'face face)))))

(defun nerd-icons-ivy-rich-process-buffer-name (cand)
  "Return process buffer name for CAND.

If the buffer is killed, return \"--\"."
  (let ((p (get-process cand)))
    (when (processp p)
      (let ((buf (process-buffer p)))
        (if (buffer-live-p buf)
		    (buffer-name buf)
		  "--")))))

(defun nerd-icons-ivy-rich-process-tty-name (cand)
  "Return the name of the terminal process use for CAND."
  (let ((p (get-process cand)))
    (when (processp p)
      (or (process-tty-name p) "--"))))

(defun nerd-icons-ivy-rich-process-thread (cand)
  "Return process thread for CAND."
  (propertize
   (format "%-12s"
           (let ((p (get-process cand)))
             (when (processp p)
               (cond
                ((or
                  (null (process-thread p))
                  (not (fboundp 'thread-name))) "--")
                ((eq (process-thread p) main-thread) "Main")
	            ((thread-name (process-thread p)))
	            (t "--")))))
   'face 'nerd-icons-ivy-rich-process-thread-face))

(defun nerd-icons-ivy-rich-process-command (cand)
  "Return process command for CAND."
  (let ((p (get-process cand)))
    (when (processp p)
      (let ((type (process-type p)))
        (if (memq type '(network serial pipe))
		    (let ((contact (if (> emacs-major-version 26)
                               (process-contact p t t)
                             (process-contact p t))))
			  (if (eq type 'network)
			      (format "(%s %s)"
				          (if (plist-get contact :type)
					          "datagram"
				            "network")
				          (if (plist-get contact :server)
					          (format
                               "server on %s"
					           (if (plist-get contact :host)
                                   (format "%s:%s"
						                   (plist-get contact :host)
                                           (plist-get
                                            contact :service))
					             (plist-get contact :local)))
				            (format "connection to %s:%s"
					                (plist-get contact :host)
					                (plist-get contact :service))))
			    (format "(serial port %s%s)"
				        (or (plist-get contact :port) "?")
				        (let ((speed (plist-get contact :speed)))
				          (if speed
					          (format " at %s b/s" speed)
				            "")))))
		  (mapconcat #'identity (process-command p) " "))))))

;; Support `counsel-find-library' and `counsel-load-library'
(defun nerd-icons-ivy-rich-library-transformer (cand)
  "Return library name for CAND."
  (if (featurep (intern-soft cand))
      cand
    (propertize cand 'face 'nerd-icons-ivy-rich-off-face)))

;; Support `counsel-world-clock'
(defun nerd-icons-ivy-rich-world-clock (cand)
  "Return local time of timezone (CAND)."
  (counsel-world-clock--local-time cand))

(defun nerd-icons-ivy-rich-grep-transformer (cand)
  "Transform search results (CAND).
Support`counsel-ack', `counsel-ag', `counsel-pt' and `counsel-rg', etc."
  (cond
   ((string-match "\\(.+\\):\\([0-9]+\\):\\(.+\\)" cand)
    (let ((file (match-string 1 cand))
          (line (match-string 2 cand))
          (result (match-string 3 cand)))
      (format "%s:%s:%s"
              (propertize file 'face 'ivy-grep-info)
              (propertize line 'face 'ivy-grep-info)
              result)))
   ((string-match "\\(.+\\):\\(.+\\)(\\(.+\\))" cand)
    (let ((file (match-string 1 cand))
          (msg (match-string 2 cand))
          (err (match-string 3 cand)))
      (format "%s:%s(%s)"
              (propertize file 'face 'ivy-grep-info)
              msg
              (propertize err 'face 'error))))
   (t cand)))

(defun nerd-icons-ivy-rich-magit-todos-transformer (cand)
  "Transform `magit-todos' result (CAND)."
  (let* ((strs (split-string cand " "))
         (file (car strs))
         (desc (cdr strs)))
    (format "%s %s"
            (propertize file 'face 'ivy-grep-info)
            (string-join desc " "))))

;;
;; Icons
;;

(defun nerd-icons-ivy-rich-icon (icon)
  "Format ICON'."
  (when nerd-icons-ivy-rich-icon
    (format "%s%s"
            (propertize " " 'display '((space :relative-width 0.1)))
            icon)))

(defun nerd-icons-ivy-rich-buffer-icon (cand)
  "Display buffer icon for CAND."
  (nerd-icons-ivy-rich-icon
   (let ((icon (with-current-buffer (get-buffer cand)
                 (if (eq major-mode 'dired-mode)
                     (nerd-icons-icon-for-dir cand :face 'nerd-icons-ivy-rich-dir-face)
                   (nerd-icons-icon-for-buffer)))))
     (if (or (null icon) (symbolp icon))
         (nerd-icons-faicon "nf-fa-file_o" :face 'nerd-icons-dsilver)
       (propertize icon 'display '(raise 0.0))))))

(defun nerd-icons-ivy-rich-file-icon (cand)
  "Display file icon for CAND."
  (nerd-icons-ivy-rich-icon
   (let ((icon (cond
                ((ivy--dirname-p cand)
                 (nerd-icons-icon-for-dir cand :face 'nerd-icons-ivy-rich-dir-face))
                ((not (string-empty-p cand))
                 (nerd-icons-icon-for-file (file-name-nondirectory cand))))))
     (if (or (null icon) (symbolp icon))
         (nerd-icons-faicon "nf-fa-file_o" :face 'nerd-icons-dsilver)
       (propertize icon 'display '(raise 0.0))))))

(defun nerd-icons-ivy-rich-magit-file-icon (cand)
  "Display file icon for CAND."
  (if (string-suffix-p "Find file from revision: " ivy--prompt)
      (nerd-icons-ivy-rich-git-branch-icon cand)
    (nerd-icons-ivy-rich-file-icon cand)))

(defun nerd-icons-ivy-rich-magit-todos-icon (cand)
  "Display file icon for CAND in `magit-todos'."
  (nerd-icons-ivy-rich-file-icon (nth 0 (split-string cand " "))))

(defun nerd-icons-ivy-rich-dir-icon (_cand)
  "Display project icon for CAND."
  (nerd-icons-ivy-rich-icon
   (nerd-icons-octicon "nf-oct-file_directory" :face 'nerd-icons-silver)))

(defun nerd-icons-ivy-rich-project-icon (_cand)
  "Display project icon for CAND."
  (nerd-icons-ivy-rich-icon
   (nerd-icons-octicon "nf-oct-repo" :face 'nerd-icons-green)))

(defun nerd-icons-ivy-rich-history-icon (_cand)
  "Display history icon for CAND."
  (nerd-icons-ivy-rich-icon
   (nerd-icons-mdicon "nf-md-history" :face 'nerd-icons-lblue)))

(defun nerd-icons-ivy-rich-mode-icon (_cand)
  "Display mode icon for CAND."
  (nerd-icons-ivy-rich-icon
   (nerd-icons-codicon "nf-cod-symbol_method" :face 'nerd-icons-blue)))

(defun nerd-icons-ivy-rich-function-icon (cand)
  "Display function icon for CAND."
  (nerd-icons-ivy-rich-icon
   (if (commandp (intern cand))
       (nerd-icons-codicon "nf-cod-symbol_method" :face 'nerd-icons-blue)
     (nerd-icons-codicon "nf-cod-symbol_method" :face 'nerd-icons-purple))))

(defun nerd-icons-ivy-rich-command-icon (_cand)
  "Display command icon for CAND."
  (nerd-icons-ivy-rich-icon
   (nerd-icons-codicon "nf-cod-symbol_method" :face 'nerd-icons-blue)))

(defun nerd-icons-ivy-rich-variable-icon (cand)
  "Display the variable icon for CAND."
  (nerd-icons-ivy-rich-icon
   (if (custom-variable-p (intern cand))
       (nerd-icons-codicon "nf-cod-symbol_variable" :face 'nerd-icons-blue)
     (nerd-icons-codicon "nf-cod-symbol_variable" :face 'nerd-icons-lblue))))

(defun nerd-icons-ivy-rich-face-icon (_cand)
  "Display face icon."
  (nerd-icons-ivy-rich-icon
   (nerd-icons-codicon "nf-cod-symbol_color" :face 'nerd-icons-blue)))

(defun nerd-icons-ivy-rich-symbol-icon (cand)
  "Display the symbol icon for CAND."
  (let ((sym (intern (nerd-icons-ivy-rich-imenu-symbol cand))))
    (cond
     ((string-match-p "Packages?[:)]" cand)
      (nerd-icons-ivy-rich-icon
       (nerd-icons-codicon "nf-cod-archive" :face 'nerd-icons-silver)))
     ((or (functionp sym) (macrop sym))
      (nerd-icons-ivy-rich-function-icon cand))
     ((facep sym)
      (nerd-icons-ivy-rich-face-icon cand))
     ((symbolp sym)
      (nerd-icons-ivy-rich-variable-icon cand))
     (t (nerd-icons-ivy-rich-icon
         (nerd-icons-codicon "nf-cod-gear" :face 'nerd-icons-silver))))))

(defun nerd-icons-ivy-rich-company-icon (cand)
  "Display the symbol icon for CAND in company."
  (nerd-icons-ivy-rich-icon
   (if (fboundp 'company-box--get-icon)
       (company-box--get-icon cand)
     (nerd-icons-codicon "nf-cod-gear" :face 'nerd-icons-silver))))

(defun nerd-icons-ivy-rich-theme-icon (_cand)
  "Display the theme icon."
  (nerd-icons-ivy-rich-icon
   (nerd-icons-codicon "nf-cod-symbol_color" :face 'nerd-icons-lcyan)))

(defun nerd-icons-ivy-rich-keybinding-icon (_cand)
  "Display the keybindings icon."
  (nerd-icons-ivy-rich-icon
   (nerd-icons-faicon "nf-fa-keyboard_o" :face 'nerd-icons-lsilver)))

(defun nerd-icons-ivy-rich-library-icon (_cand)
  "Display the library icon."
  (nerd-icons-ivy-rich-icon
   (nerd-icons-faicon "nf-fa-archive" :face 'nerd-icons-silver)))

(defun nerd-icons-ivy-rich-package-icon (_cand)
  "Display the package icon."
  (nerd-icons-ivy-rich-icon
   (nerd-icons-faicon "nf-fa-archive" :face 'nerd-icons-silver)))

(defun nerd-icons-ivy-rich-font-icon (_cand)
  "Display the font icon."
  (nerd-icons-ivy-rich-icon
   (nerd-icons-sucicon "nf-seti-font" :face 'nerd-icons-blue)))

(defun nerd-icons-ivy-rich-world-clock-icon (_cand)
  "Display the world clock icon."
  (nerd-icons-ivy-rich-icon
   (nerd-icons-codicon "nf-cod-globe" :face 'nerd-icons-blue)))

(defun nerd-icons-ivy-rich-tramp-icon (_cand)
  "Display the tramp icon."
  (nerd-icons-ivy-rich-icon
   (nerd-icons-mdicon "remote")))

(defun nerd-icons-ivy-rich-git-branch-icon (_cand)
  "Display the git branch icon."
  (nerd-icons-ivy-rich-icon
   (nerd-icons-octicon "nf-oct-git_branch" :face 'nerd-icons-green)))

(defun nerd-icons-ivy-rich-git-commit-icon (_cand)
  "Display the git commit icon."
  (nerd-icons-ivy-rich-icon
   (nerd-icons-octicon "nf-oct-git_commit" :face 'nerd-icons-green)))

(defun nerd-icons-ivy-rich-process-icon (_cand)
  "Display the process icon."
  (nerd-icons-ivy-rich-icon
   (nerd-icons-codicon "nf-cod-server_process" :face 'nerd-icons-blue)))

(defun nerd-icons-ivy-rich-imenu-icon (cand)
  "Display the imenu icon for CAND."
  (if (derived-mode-p 'emacs-lisp-mode)
      (nerd-icons-ivy-rich-symbol-icon cand)
    (nerd-icons-ivy-rich-icon
     (let ((case-fold-search nil))
       (cond
        ((string-match-p "Type Parameters?[:)]" cand)
         (nerd-icons-codicon "nf-cod-symbol_class"))
        ((string-match-p "\\(Variables?\\)\\|\\(Fields?\\)\\|\\(Parameters?\\)[:)]" cand)
         (nerd-icons-codicon "nf-cod-symbol_variable" :face 'nerd-icons-lblue))
        ((string-match-p "Constants?[:)]" cand)
         (nerd-icons-codicon "nf-cod-symbol_constant"))
        ((string-match-p "Enum\\(erations?\\)?[:)]" cand)
         (nerd-icons-codicon "nf-cod-symbol_enum" :face 'nerd-icons-orange))
        ((string-match-p "References?[:)]" cand)
         (nerd-icons-codicon "nf-cod-symbol_misc"))
        ((string-match-p "\\(Types?\\)\\|\\(Property\\)[:)]" cand)
         (nerd-icons-codicon "nf-cod-symbol_property"))
        ((string-match-p "\\(Functions?\\)\\|\\(Methods?\\)\\|\\(Constructors?\\)[:)]" cand)
         (nerd-icons-codicon "nf-cod-symbol_method" :face 'nerd-icons-purple))
        ((string-match-p "Class[:)]" cand)
         (nerd-icons-codicon "nf-cod-symbol_class" :face 'nerd-icons-orange))
        ((string-match-p "Structs?[:)]" cand)
         (nerd-icons-codicon "nf-cod-symbol_structure" :face 'nerd-icons-orange))
        ((string-match-p "Interfaces?[:)]" cand)
         (nerd-icons-codicon "nf-cod-symbol_interface" :face 'nerd-icons-lblue))
        ((string-match-p "Modules?[:)]" cand)
         (nerd-icons-codicon "nf-cod-symbol_namespace" :face 'nerd-icons-lblue))
        ((string-match-p "Packages?[:)]" cand)
         (nerd-icons-codicon "nf-cod-archive" :face 'nerd-icons-silver))
        (t
         (nerd-icons-codicon "nf-cod-symbol_field" :face 'nerd-icons-blue)))))))

(defun nerd-icons-ivy-rich-bookmark-icon (cand)
  "Return bookmark type for CAND."
  (nerd-icons-ivy-rich-icon
   (let ((file (ivy-rich-bookmark-filename cand)))
     (cond
      ((null file)
       (nerd-icons-mdicon "nf-md-block_helper" :face 'nerd-icons-ivy-rich-warn-face))  ; fixed #38
      ((file-remote-p file)
       (nerd-icons-mdicon "nf-md-remote"))
      ((not (file-exists-p file))
       (nerd-icons-mdicon "nf-md-block_helper" :face 'nerd-icons-ivy-rich-error-face))
      ((file-directory-p file)
       (nerd-icons-mdicon "nf-md-folder"))
      (t
       (nerd-icons-icon-for-file (file-name-nondirectory file)))))))

(defun nerd-icons-ivy-rich-group-settings-icon (_cand)
  "Display group settings icon for CAND."
  (nerd-icons-ivy-rich-icon
   (nerd-icons-codicon "nf-cod-settings" :face 'nerd-icons-lblue)))

(defun nerd-icons-ivy-rich-variable-settings-icon (_cand)
  "Display variable settings icon for CAND."
  (nerd-icons-ivy-rich-icon
   (nerd-icons-codicon "nf-cod-settings" :face 'nerd-icons-lgreen)))

(defun nerd-icons-ivy-rich-charset-icon (_cand)
  "Display charset icon for CAND."
  (nerd-icons-ivy-rich-icon
   (nerd-icons-faicon "nf-fa-table" :face 'nerd-icons-lblue)))

(defun nerd-icons-ivy-rich-coding-system-icon (_cand)
  "Display coding system icon for CAND."
  (nerd-icons-ivy-rich-icon
   (nerd-icons-faicon "nf-fa-table" :face 'nerd-icons-purple)))

(defun nerd-icons-ivy-rich-lang-icon (_cand)
  "Display language icon."
  (nerd-icons-ivy-rich-icon
   (nerd-icons-faicon "nf-fa-language" :face 'nerd-icons-lblue)))

(defun nerd-icons-ivy-rich-input-method-icon (_cand)
  "Display input method icon."
  (nerd-icons-ivy-rich-icon
   (nerd-icons-faicon "nf-fa-keyboard-o" :face 'nerd-icons-lblue)))

(defun nerd-icons-ivy-rich-grep-file-icon (cand)
  "Display file icon for CAND.
Support`counsel-ack', `counsel-ag', `counsel-pt' and `counsel-rg', etc."
  (when (or (string-match "\\(.+\\):\\([0-9]+\\):\\(.+\\)" cand)
            (string-match "\\(.+\\):\\(.+\\)(\\(.+\\))" cand))
    (nerd-icons-ivy-rich-file-icon (match-string 1 cand))))

(defun nerd-icons-ivy-rich-link-icon (cand)
  "Display link icon for CAND."
  (nerd-icons-ivy-rich-icon
   (if (string-prefix-p "#" cand)
       (nerd-icons-mdicon "nf-md-anchor":face 'nerd-icons-green)
     (nerd-icons-mdicon "nf-md-link" :face 'nerd-icons-blue))))

(defun nerd-icons-ivy-rich-key-icon (_cand)
  "Display key icon."
  (nerd-icons-ivy-rich-icon
   (nerd-icons-octicon "nf-oct-key")))

(defun nerd-icons-ivy-rich-lsp-icon (_cand)
  "Display lsp icon."
  (nerd-icons-ivy-rich-icon
   (nerd-icons-octicon "nf-oct-rocket" :face 'nerd-icons-lgreen)))


;;
;; Modes
;;

(defvar nerd-icons-ivy-rich-display-transformers-old-list ivy-rich-display-transformers-list)

;;;###autoload
(define-minor-mode nerd-icons-ivy-rich-mode
  "Better experience with icons for ivy."
  :lighter nil
  :global t
  (if nerd-icons-ivy-rich-mode
      (progn
        (advice-add #'kill-buffer :around #'nerd-icons-ivy-rich-kill-buffer)
        (setq ivy-rich-display-transformers-list nerd-icons-ivy-rich-display-transformers-list))
    (progn
      (advice-remove #'kill-buffer #'nerd-icons-ivy-rich-kill-buffer)
      (setq ivy-rich-display-transformers-list nerd-icons-ivy-rich-display-transformers-old-list)))
  (ivy-rich-reload))

;;;###autoload
(defun nerd-icons-ivy-rich-reload ()
  "Reload `nerd-icons-ivy-rich'."
  (interactive)
  (when nerd-icons-ivy-rich-mode
    (nerd-icons-ivy-rich-mode -1)
    (nerd-icons-ivy-rich-mode 1)
    (message "Reload nerd-icons-ivy-rich")))

(provide 'nerd-icons-ivy-rich)

;;; nerd-icons-ivy-rich.el ends here
