;;; osx-plist.el --- Apple plist file parser  -*- lexical-binding: t -*-

;; Copyright (C) 2005  Theresa O'Connor <tess@oconnor.cx>
;; Copyright (C) 2020  Neil Okamoto <neil.okamoto+melpa@gmail.com>

;; Author: Theresa O'Connor <tess@oconnor.cx>
;; Maintainer: Neil Okamoto <neil.okamoto+melpa@gmail.com>
;; Keywords: convenience
;; Package-Version: 20200212.1724
;; Package-Commit: cd86c03a52eab9b1a1496618809155b25b030ba6
;; Package-Requires: ((emacs "25.1"))
;; URL: https://github.com/gonewest818/osx-plist
;; Version: 2.0.0

;; This file is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the
;; Free Software Foundation; either version 2, or (at your option) any
;; later version.

;; This file is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING. If not, write to the Free
;; Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
;; 02111-1307, USA.

;;; Commentary:

;; Simple parser for Mac OS X plist files.  The main entry points are
;; `osx-plist-parse-file' and `osx-plist-parse-buffer'.

;;; Changelog:

;; v2.0.0 (2020) Support plist types: integer, real, date, and data
;;               Breaking change is that the original environment.plist
;;               capability has been removed (see README.md)

;; v1.0.0 (2005) First published, documented on
;;               https://www.emacswiki.org/emacs/MacOSXPlist

;;; Code:

(require 'xml)
(require 'parse-time)

(defun osx-plist-process-array (xml)
  "Process the plist array element XML."
  (let ((real-children (list)))
    (mapc (lambda (child)
            (unless (stringp child)
              (push (osx-plist-node-value child) real-children)))
          (xml-node-children xml))
    (apply #'vector (nreverse real-children))))

(defun osx-plist-process-dict (xml)
  "Place the key-value pairs of plist XML into HASH."
  (let ((hash (make-hash-table :test 'equal))
        (current-key nil))
    (mapc
     (lambda (child)
       (unless (stringp child)          ; ignore inter-tag whitespace
         (let ((name (xml-node-name child)))
           (if (eq name 'key)
               (setq current-key (osx-plist-node-value child))
             (puthash current-key
                      (osx-plist-node-value child)
                      hash)))))
     (xml-node-children xml))
    hash))

(defun osx-plist-node-value (node)
  "Return a Lisp value equivalent of plist node NODE."
  (let ((name (xml-node-name node))
        (children (xml-node-children node)))
    (cond ((eq name 'false) nil)
          ((eq name 'true)  t)
          ((memq name '(key string))
           (apply #'concat children))
          ((memq name '(integer real))
           (string-to-number (car children)))
          ((eq name 'date)
           (decode-time (parse-iso8601-time-string (car children))))
          ((eq name 'data)
           (base64-decode-string (apply #'concat children)))
          ((eq name 'dict)
           (osx-plist-process-dict node))
          ((eq name 'array)
           (osx-plist-process-array node)))))

(defun osx-plist-p (xml)
  "Non-null if XML appears to be an Apple plist."
  (and xml (listp xml) (eq (xml-node-name xml) 'plist)))

(defun osx-plist-process-xml (xml)
  "Run the parser on the parsed XML containing the plist data."
  (let* ((node (car xml))
         (child (car (or (xml-get-children node 'dict)
                         (xml-get-children node 'array)))))
    (when (osx-plist-p node)
      (osx-plist-node-value child))))

(defun osx-plist-parse-file (file)
  "Parse the plist file FILE into an elisp hash table.
If the FILE does not contain valid XML, return nil."
  (condition-case err
      (osx-plist-process-xml (xml-parse-file file))
    (error
     (message "osx-plist caught: %s" (error-message-string err))
     nil)))

(defun osx-plist-parse-buffer (&optional buffer)
  "Parse the plist in buffer BUFFER into an elisp hash table.
If BUFFER is nil then process the current buffer instead.
If BUFFER does not contain valid XML, return nil."
  (condition-case err
      (osx-plist-process-xml (xml-parse-region nil nil buffer))
    (error
     (message "osx-plist caught: %s" (error-message-string err))
     nil)))

(provide 'osx-plist)
;;; osx-plist.el ends here
