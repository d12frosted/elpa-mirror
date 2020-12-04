;;; insert-esv.el --- Insert ESV Bible passages -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Sam (sam030820)

;; Author: Sam (sam030820)
;; Version: 0.1.1
;; Package-Version: 20201201.722
;; Package-Commit: 067bdd92ab2fccdfdee3d8707aa570527c74fd6a
;; Package-Requires: ((emacs "24.3") (request "0.3.2"))
;; Keywords: convenience
;; URL: https://github.com/sam030820/insert-esv/

;; This file is not part of GNU Emacs.

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
;;
;; *insert-esv is an Emacs package for inserting ESV Bible passages.*
;;
;; ** Installation
;; insert-esv is available on [[https://melpa.org/#/getting-started][MELPA]].
;; To install it, run ~M-x package-install RET insert-esv RET~.
;;
;; Alternatively, clone this repo and run
;; ~M-x package-install-file RET </path/to/insert-esv.el> RET~.
;;
;; ** Usage
;; 1. Grab an API key from [[https://api.esv.org/docs/][Crossway]].
;; 2. Add the API key to your init file:
;;   ~(setq insert-esv-crossway-api-key "<token>")~.
;; 3. Set a keybind in your init file:
;;   ~(global-set-key (kbd "C-x C-e") #'insert-esv-passage)~.
;; 4. Once invoked, enter a Bible reference and hit ~RET~ to insert it at point.
;;
;; *** Example configuration
;; You can include this [[https://github.com/jwiegley/use-package][use-package]]
;; config in place of Steps 2 and 3. In addition, it contains
;; suggested preferences for attribution, headings, and line length.
;;
;; #+BEGIN_SRC elisp
;; (use-package
;;   insert-esv
;;   :init
;;   (setq insert-esv-crossway-api-key "<token>")
;;   (setq insert-esv-include-short-copyright 'true)
;;   (setq insert-esv-include-headings 'true)
;;   (setq insert-esv-include-passage-horizontal-lines 'false)
;;   (setq insert-esv-line-length '50)
;;   :bind ("C-x C-e" . insert-esv-passage))
;; #+END_SRC
;;
;; ** Options
;; - This package contains support for the optional parameters in Crossway's
;;   [[https://api.esv.org/docs/passage-text/][Passage Text API]].
;; - You can customise these parameters in your init file.
;; - Make sure to prefix each parameter with the package name:
;;   ~(setq insert-esv-include-headings 'true)~.
;;
;; ** Disclaimer
;; - insert-esv is licensed under
;;   [[https://github.com/sam030820/insert-esv/blob/master/COPYING][GPLv3]]
;;   and copyright sam030820 and
;;   [[https://github.com/sam030820/insert-esv/contributors][contributors]].
;; - Scripture quotations are from the ESV® Bible, copyright © 2001 by
;;   Crossway, a publishing ministry of Good News Publishers.

;;; Code:

(require 'json)
(require 'request)

(defgroup insert-esv nil
  "Insert an English Standard Version Bible passage at point."
  :group 'convenience
  :prefix "insert-esv-")

(defvar insert-esv-log nil "List of previously fetched Bible passages.")

;; User Variables

(defcustom insert-esv-crossway-api-key nil
  "Provide your Crossway API key (https://api.esv.org/)."
  :type 'string
  :group 'insert-esv)

(defcustom insert-esv-include-passage-references 'true
  "Include the passage reference before the text."
  :type '(choice (false) (true))
  :group 'insert-esv)

(defcustom insert-esv-include-verse-numbers 'false
  "Include verse numbers."
  :type '(choice (false) (true))
  :group 'insert-esv)

(defcustom insert-esv-include-first-verse-numbers 'false
  "Include the verse number for the first verse of a chapter."
  :type '(choice (false) (true))
  :group 'insert-esv)

(defcustom insert-esv-include-footnotes 'false
  "Include callouts to footnotes in the text."
  :type '(choice (false) (true))
  :group 'insert-esv)

(defcustom insert-esv-include-footnote-body 'false
  "Include footnote bodies below the text."
  :type '(choice (false) (true))
  :group 'insert-esv)

(defcustom insert-esv-include-headings 'false
  "Include section headings."
  :type '(choice (false) (true))
  :group 'insert-esv)

(defcustom insert-esv-include-short-copyright 'false
  "Include a copyright notice (ESV) at the end of the text."
  :type '(choice (false) (true))
  :group 'insert-esv)

(defcustom insert-esv-include-passage-horizontal-lines 'false
  "Include a line of equal signs (====) above the beginning of each passage."
  :type '(radio (false) (true))
  :group 'insert-esv)

(defcustom insert-esv-include-heading-horizontal-lines 'false
  "Include a visual line of underscores (____) above each section heading."
  :type '(choice (false) (true))
  :group 'insert-esv)

(defcustom insert-esv-horizontal-line-length '55
  "Set the length of the line for passage and heading horizontal lines."
  :type 'integer
  :group 'insert-esv)

(defcustom insert-esv-include-selahs 'true
  "Include Selah in certain Psalms."
  :type '(radio (false) (true))
  :group 'insert-esv)

(defcustom insert-esv-indent-using 'space
  "Set indentation (must be space or tab)."
  :type '(radio (space) (tab))
  :group 'insert-esv)

(defcustom insert-esv-indent-paragraphs '0
  "Set how many indentation characters start a paragraph."
  :type 'integer
  :group 'insert-esv)

(defcustom insert-esv-indent-poetry 'true
  "Set indentation of poetry lines."
  :type '(choice (false) (true))
  :group 'insert-esv)

(defcustom insert-esv-indent-poetry-lines '4
  "Set how many characters are used per indentation level for poetry."
  :type 'integer
  :group 'insert-esv)

(defcustom insert-esv-indent-declares '40
  "Set how many indentation characters are used for 'Declares the LORD' lines."
  :type 'integer
  :group 'insert-esv)

(defcustom insert-esv-indent-psalm-doxology '30
  "Set how many indentation characters are used for Psalm doxologies."
  :type 'integer
  :group 'insert-esv)

(defcustom insert-esv-line-length '0
  "Control maximum line length (0 = unlimited)."
  :type 'integer
  :group 'insert-esv)

;; Commands

;;;###autoload
(defun insert-esv-passage (ref)
  "Insert an English Standard Version Bible passage (REF) at point."
  (interactive
   (list (read-string "Enter Bible reference: " nil 'insert-esv-log)))
  (if (equal 'nil insert-esv-crossway-api-key)
      (error "Error! You must set `insert-esv-crossway-api-key` first"))
  (request "https://api.esv.org/v3/passage/text/"
    :headers `(("Authorization" . ,(format "Token %s" insert-esv-crossway-api-key)))
    :parser 'json-read
    :params `(("q" . ,ref)
              ("include-passage-references" . ,insert-esv-include-passage-references)
              ("include-verse-numbers" . ,insert-esv-include-verse-numbers)
              ("include-first-verse-numbers" . ,insert-esv-include-first-verse-numbers)
              ("include-footnotes" . ,insert-esv-include-footnotes)
              ("include-footnote-body" . ,insert-esv-include-footnote-body)
              ("include-headings" . ,insert-esv-include-headings)
              ("include-short-copyright" . ,insert-esv-include-short-copyright)
              ("include-passage-horizontal-lines" .
               ,insert-esv-include-passage-horizontal-lines)
              ("include-heading-horizontal-lines" .
               ,insert-esv-include-heading-horizontal-lines)
              ("horizontal-line-length" . ,insert-esv-horizontal-line-length)
              ("include-selahs" . ,insert-esv-include-selahs)
              ("indent-using" . ,insert-esv-indent-using)
              ("indent-paragraphs" . ,insert-esv-indent-paragraphs)
              ("indent-poetry" . ,insert-esv-indent-poetry)
              ("indent-poetry-lines" . ,insert-esv-indent-poetry-lines)
              ("indent-declares" . ,insert-esv-indent-declares)
              ("indent-psalm-doxology" . ,insert-esv-indent-psalm-doxology)
              ("line-length" . ,insert-esv-line-length))
    :success (cl-function
              (lambda (&key data &allow-other-keys)
                (insert
                 (replace-regexp-in-string "[][]" ""
                                           (format "%s" (assoc-default 'passages data))))))
    :error (cl-function
            (lambda (&rest args &key error-thrown &allow-other-keys)
              (message "Error! Reference could not be fetched:\n%s" error-thrown)))))

(provide 'insert-esv)

;;; insert-esv.el ends here
