;;; ggo-mode.el --- Gengetopt major mode

;; Copyright (C) 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2010, 2013, 2021
;; Matthew K. Junker

;; Author: Matthew K. Junker <junker@alum.mit.edu>
;; Version: 20210310
;; Package-Version: 20210310.1345
;; Package-Commit: 6a7617b5af3d13029e4d680a375e8107c40d0fac
;; Keywords: extensions, convenience, local

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:
;;
;; A major mode for editing gengetopt files.
;;
;; Modify `ggo-skeleton' to suit your format.
;;
;; Should work with Emacs version 21 and later.  Works with
;; gengetopt 2.22.4.  May or may not work with previous versions.
;;
;; Reuben Thomas made helpful updates to this file.


;;; History:

;; $Log: ggo-mode.el,v $
;; Revision 1.17  2008/05/23 15:49:56  junker.m
;; Added newline to detailed description to make help2man work better.
;;
;; Revision 1.16  2008/05/16 16:36:41  junker.m
;; Fixed RCS Id.  Fixed some customization groups.
;;
;; Revision 1.15  2008/05/05 15:22:09  junker.m
;; Changed "no" to "optional".
;;
;; Revision 1.14  2008/05/05 15:13:16  junker.m
;; Updated for version 22.2.
;;
;; Revision 1.13  2007/06/23 15:37:34  Matt
;; Corrected initial skeleton.
;;
;; Revision 1.12  2007/02/02 23:18:16  Matt
;; Updated for 1.19.  Keywords, skeleton.
;;
;; Revision 1.11  2006-02-18 08:21:58-06  Matt
;; Added autoload.
;;
;; Revision 1.10  2005-06-30 10:20:30-05  junker.m
;; Fixed inserting ``flag'' and type string.
;;
;; Revision 1.9  2005-06-09 15:05:32-05  junker.m
;; Updated for 2.13.1.  Added enumerated type.  Removed old skeletons
;; for inserting text as this can be done with headers, and help2man
;; accepts additional text.
;;

;; Revision 1.8 2004/07/01 Updated for GG0 2.12.1.  Added argoptional.
;; Made `ggo-insert-option-skeleton' match the documentation better.

;; Revision 1.5 2003/04/18 Added group features (GGO 2.9).

;; Revision 1.1 2002/04/19 Initial revision


;;; Code:

(defgroup ggo-mode nil
  "Major mode for editing and processing gengetopt files."
  :group 'local)

(defcustom ggo-mode-hook nil
  "*Hook called by `ggo-mode'."
  :type 'hook
  :group 'ggo-mode)

(defcustom ggo-types
  '("" "string" "int" "short" "long" "float"
    "double" "longdouble" "longlong" "flag" "enum")
  "*Types of gengetopt options (not for groupoption)."
  :type '(repeat string)
  :group 'ggo-mode)

(defcustom ggo-groupoption-types
  '("" "string" "int" "short" "long" "float"
    "double" "longdouble" "longlong" "enum")
  "*Types of gengetopt options for groupoption records."
  :type '(repeat string)
  :group 'ggo-mode)

(defvar ggo-option-type nil
  "The type of option current being inserted.

This is nil for regular options, 'group for group options and
'mode for mode options.  This is a variable because skeletons
can't have parameters.  Any function that sets this to non-nil
must set it back to nil after completion.")

(defun ggo-end-matter ()
  "Insert the stuff after the types."
  (if (and (null (eq ggo-option-type 'group))
           (y-or-n-p "Required? "))
      (insert " required") (insert " optional"))
  (let ((dependon (read-from-minibuffer "Depends on: ")))
    (unless (string= dependon "") (insert " dependon=\"" dependon "\"")))
  (when (y-or-n-p "Argument optional? ") (insert " argoptional"))
  (when (y-or-n-p "Multiple? ")
    (insert " multiple")
    (let ((min (read-from-minibuffer
                "Minimum entries (blank for no specification): "))
          (max (read-from-minibuffer
                "Maximum entries (blank for no specification): ")))
      (cond ((and (string= min max) (string= min "")))
            ((string= min max) (insert "(" min ")"))
            ((string= min "") (insert "(-" max ")"))
            ((string= max "") (insert "(" min "-)")))))
  (when (y-or-n-p "Hidden? ") (insert " hidden")))


(define-skeleton ggo-insert-option-skeleton
  ;; A group option is like a regular option except for the group
  ;; parameter, and it cannot be required.  Mode options are like
  ;; regular options.
  "Insert a gengetopt option."
  "Long name: "
  (if (boundp 'ggo-option-type)
      (cond ((eq ggo-option-type 'group) "group")
            ((eq ggo-option-type 'mode) "mode"))
    (setq ggo-option-type nil))
  "option \"" str "\""
  (let ((short (substring str 0 1)))
    (skeleton-insert '("Short name: " '(setq input short) " " str | "-")))
  (skeleton-insert '("Description: " " \"" str "\""))
  (skeleton-insert '("Detailed description: " " details=\"" str & "\\n\"" | -10))
  (cond ((eq ggo-option-type 'group)
         (skeleton-insert '("Group: " " group=\"" str "\"")))
        ((eq ggo-option-type 'mode)
         (skeleton-insert '("Mode: " " mode=\"" str "\""))))
  (let ((type
         (completing-read "Enter the type: "
                          (mapcar '(lambda (a) (list a a)) ggo-types) nil t)))
    (unless (member type '("" "flag" "enum"))
      (insert " " type)
      (let ((typestr (read-from-minibuffer "Enter the type string: ")))
        (unless (string= typestr "") (insert " typestr=\"" typestr "\""))))
    (cond ((string= type "flag")
           (insert " flag " (completing-read
                    "Initial flag status: "
                    (list (list "on" "on") (list "off" "off"))
                    nil t "on")))
          ((string= type "enum")
           (insert " enum")
           (let ((typestr (read-from-minibuffer "Enter the type string: ")))
             (unless (string= typestr "") (insert " typestr=\"" typestr "\"")))
           (let ((value-list (list))
                 (input ""))
             (while (not
                     (string= (setq input (read-from-minibuffer "Value: ")) ""))
               (add-to-list 'value-list input t))
             (when (not (null value-list))
               (insert " values=")
               (dolist (str value-list)
                 (insert "\"" str "\", "))
               (backward-delete-char-untabify 2))
             (let ((default
                     (completing-read "Default value: "
                                      (mapcar '(lambda (a) (list a a))
                                              value-list) nil t)))
               (unless (string= default "")
                 (insert " default=\"" default "\"")))
             (ggo-end-matter)))
          ((string= type "")
           (insert " optional"))
          (t
           (let ((default (read-from-minibuffer "Default value: ")))
             (unless (string= default "") (insert " default=\"" default "\"")))
           (ggo-end-matter)))))


(define-skeleton ggo-insert-defgroup-skeleton
  "Insert a gengetopt defgroup record."
  "Group name: "
  "defgroup \"" str "\""
  (skeleton-insert '("Description: " " groupdesc=\"" str | -12))
  & "\""
  (if (y-or-n-p "Required? ")
      (insert " yes")
    nil))


(defun ggo-insert-groupoption ()
  "Insert a gengetopt groupoption."
  (interactive)
  (let ((ggo-option-type 'group))
    (ggo-insert-option-skeleton)))


(define-skeleton ggo-insert-defmode-skeleton
  "Insert a gengetopt defmode record."
  "Mode name: "
  "defmode \"" str "\""
  (skeleton-insert '("Description: " " modedesc=\"" str | -11))
  & "\"")


(defun ggo-insert-modeoption ()
  "Insert a gengetopt groupoption."
  (interactive)
  (let ((ggo-option-type 'mode))
    (ggo-insert-option-skeleton)))


(define-skeleton ggo-insert-section-skeleton
  "Insert a gengetopt section."
  "Section name: "
  "section \"" str "\""
  (skeleton-insert '("Section description: " " sectiondesc=\""  str | -14))
  & "\\n\"")


(defvar ggo-mode-map
  (let ((map (make-sparse-keymap)))
    ;; reverse order of desired binding list
    (define-key map "\C-c\C-k" 'ggo-skeleton)
    (define-key map "\C-c\C-s" 'ggo-insert-section-skeleton)
    (define-key map "\C-c\C-o" 'ggo-insert-option-skeleton)
    (define-key map "\C-c\C-g" 'ggo-insert-groupoption)
    (define-key map "\C-c\C-m" 'ggo-insert-modeoption)
    (define-key map "\C-c\C-d\C-g" 'ggo-insert-defgroup-skeleton)
    (define-key map "\C-c\C-d\C-m" 'ggo-insert-defmode-skeleton)
    map)
  "Keymap for ggo mode.")

(defcustom ggo-mode-comment-start "#"
  "*Comment string to use in ggo mode."
  :type 'string
  :group 'ggo-mode)

(defvar ggo-mode-syntax-table nil
  "Syntax table used while in ggo mode.")

(if ggo-mode-syntax-table
    ()
  (setq ggo-mode-syntax-table (make-syntax-table))
  (modify-syntax-entry ?# "<" ggo-mode-syntax-table)
  (modify-syntax-entry ?\n ">" ggo-mode-syntax-table))

(defvar ggo-font-lock-keywords
  (list
   '("^#:.*"          0 'font-lock-variable-name-face t)
   '("^#text.*"       0 'font-lock-variable-name-face t)
   '("#:\\\\\\\".*"   0 'font-lock-comment-face t)
   '("package"     . 'font-lock-function-name-face)
   '("version"     . 'font-lock-function-name-face)
   '("purpose"     . 'font-lock-function-name-face)
   '("usage"       . 'font-lock-function-name-face)
   '("description" . 'font-lock-function-name-face)
   '("args"        . 'font-lock-function-name-face)
   '("groupoption" . 'font-lock-function-name-face)
   '("modeoption"  . 'font-lock-function-name-face)
   '("defgroup"    . 'font-lock-builtin-face)
   '("defmode"     . 'font-lock-builtin-face)
   '("groupdesc"   . 'font-lock-builtin-face)
   '("group"       . 'font-lock-builtin-face)
   '("modedesc"    . 'font-lock-builtin-face)
   '("mode"        . 'font-lock-builtin-face)
   '("sectiondesc" . 'font-lock-builtin-face)
   '("section"     . 'font-lock-builtin-face)
   '("string"      . 'font-lock-type-face)
   '("int"         . 'font-lock-type-face)
   '("short"       . 'font-lock-type-face)
   '("long"        . 'font-lock-type-face)
   '("float"       . 'font-lock-type-face)
   '("double"      . 'font-lock-type-face)
   '("longdouble"  . 'font-lock-type-face)
   '("longlong"    . 'font-lock-type-face)
   '("flag"        . 'font-lock-type-face)
   '("values"      . 'font-lock-type-face)
   '("details"     . 'font-lock-type-face)
   '("multiple"    . 'font-lock-keyword-face)
   '("yes"         . 'font-lock-keyword-face)
   '("default"     . 'font-lock-keyword-face)
   '("no"          . 'font-lock-keyword-face)
   '("off"         . 'font-lock-keyword-face)
   '("hidden"      . 'font-lock-keyword-face)
   '("required"    . 'font-lock-keyword-face)
   '("argoptional" . 'font-lock-keyword-face)
   '("optional"    . 'font-lock-keyword-face)
   '("dependon"    . 'font-lock-keyword-face)
   '("option"      . 'font-lock-function-name-face)
   '("on"          . 'font-lock-keyword-face)
   '("text"        . 'font-lock-function-name-face)
   '("typestr"     . 'font-lock-keyword-face)
   '("enum"        . 'font-lock-keyword-face))
  "Font-lock highlighting control in ggo mode.")


;;;###autoload
(defun ggo-mode ()
  "Major mode for editing gengetopt files.

\\[ggo-skeleton] inserts the basic .ggo data.

\\[ggo-insert-option-skeleton] inserts an option and parameters at the
point.

The \`argtype\' field includes \`enum\', which indicates a string
field, but complies with the requirements of the \`values\'
keyword.

\\{ggo-mode-map}"
  (interactive)
  (kill-all-local-variables)
  (setq major-mode          'ggo-mode
        mode-name           "ggo"
        comment-start       ggo-mode-comment-start
        comment-end         ""          ; blank = EOL
        comment-start-skip  "\\(\\(^\\|[^\\\\\n]\\)\\(\\\\\\\\\\)*\\)#+ *"
        parse-sexp-ignore-comments t)
  (set-syntax-table ggo-mode-syntax-table)
  (set (make-local-variable 'font-lock-defaults)
       '(ggo-font-lock-keywords nil t))
  (use-local-map ggo-mode-map)
  (run-hooks 'ggo-mode-hook))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Skeletons
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(define-skeleton ggo-skeleton
  "Skeleton for Gengetopt files."
  "Package name: "
  "# $Id\$"
  \n "# gengetopt input file.  See the info entry for directions."
  \n "package \"" str "\""
  \n "# version \"1.0\""
  \n "purpose \"" (skeleton-read "Purpose: " nil nil) "\""
  \n (skeleton-insert '("Usage: " "usage \"" str & "\"" | -7))
  \n (skeleton-insert '("Description: " "description \"" str & "\"" | -13))
  \n
  _
  \n "option \"parser-debug\" P \"Debug the parser.\" no"
  \n "option \"scanner-debug\" S \"Debug the scanner.\" no"
  \n "text \"\\n\\nReport bugs to <" user-mail-address ">.\""
  )

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.ggo\\'" . ggo-mode))
(require 'autoinsert)
(add-to-list 'auto-insert-alist '(ggo-mode . ggo-skeleton))

(provide 'ggo-mode)
;;; ggo-mode.el ends here
