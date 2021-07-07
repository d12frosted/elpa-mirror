;;; gvariant.el --- GVariant (GLib) helpers -*- lexical-binding: t; -*-

;; Author: wouter bolsterlee <wouter@bolsterl.ee>
;; Keywords: languages
;; Package-Version: 20210507.1310
;; Package-Commit: f2e87076845800cbaaeed67f175ad4e4a9c01e37
;; URL: https://github.com/wbolster/emacs-gvariant
;; Package-Requires: ((emacs "24") (parsec "0.1.4"))
;; Version: 1.0.0

;; Copyright 2019 wouter bolsterlee. Licensed under the BSD-3-clause license.

;;; Commentary:

;; This package provides helpers for GVariant strings. The only public
;; function is ‘gvariant-parse’, which parses a string into an elisp
;; data structure.

;;; Code:

(require 'parsec)

(defconst gvariant--special-chars
  '((?\" . ?\")
    (?\' . ?\')
    (?\\ . ?\\)
    (?a . ?\a)
    (?b . ?\b)
    (?f . ?\f)
    (?n . ?\n)
    (?r . ?\r)
    (?t . ?\t)
    (?v . ?\v))
  "GVariant string escapes, translated to elisp.")

(defconst gvariant--format-string-regex
  (concat "[" (regexp-quote "bynqiuxthdsogvam(){}@*?r&^") "]+")
  "Regular expression to detect GVariant format strings.")

(defconst gvariant--type-keywords-regex
  (regexp-opt
   '("boolean"
     "byte"
     "double"
     "handle"
     "int16"
     "int32"
     "int64"
     "objectpath"
     "signature"
     "string"
     "uint16"
     "uint32"
     "uint64")
   'words)
  "Regular expression to detect GVariant type keywords.")

(defun gvariant-parse (s)
  "Parse the string representation of a GVariant value from string S."
  (let ((case-fold-search nil))
    (parsec-with-input s
      (parsec-return
          (gvariant--value)
        (parsec-eol-or-eof)))))

(defun gvariant--value ()
  "Parse a GVariant value."
  (parsec-optional
   (parsec-try
    (gvariant--type-prefix)))
  (parsec-or
   (gvariant--nothing)
   (gvariant--boolean)
   (gvariant--number)
   (gvariant--string)
   (gvariant--array)
   (gvariant--tuple)
   (gvariant--dictionary)))

(defun gvariant--whitespace ()
  "Parse whitespace."
  (parsec-many (parsec-ch ?\s)))

(defun gvariant--type-prefix ()
  "Parse (and ignore) a GVariant type prefix."
  (parsec-return
      (parsec-or
       (parsec-re gvariant--type-keywords-regex)
       (parsec-re gvariant--format-string-regex))
    (parsec-ch ?\s)
    (gvariant--whitespace)))

(defun gvariant--nothing ()
  "Parse an empty GVariant value."
  (parsec-and (parsec-str "nothing") nil))

(defun gvariant--boolean ()
  "Parse a GVariant boolean."
  (parsec-or
   (parsec-and (parsec-str "true") t)
   (parsec-and (parsec-str "false") nil)))

(defun gvariant--number ()
  "Parse a GVariant number."
  (parsec-or
   (gvariant--octal)
   (gvariant--hexadecimal)
   (gvariant--decimal)))

(defun gvariant--decimal ()
  "Parse a GVariant integer or float using decimal notation."
  (string-to-number
   (parsec-try
    (parsec-collect-as-string
     (parsec-optional (parsec-one-of ?- ?+))
     (parsec-or (parsec-re "[0-9]+\\.[0-9]*")
                (parsec-re "\\.[0-9]+")
                (parsec-re "[1-9][0-9]*"))
     (parsec-optional (parsec-re "[Ee]\\-?[0-9]+"))))))

(defun gvariant--octal ()
  "Parse a GVariant integer in octal notation."
  (string-to-number
   (parsec-try
    (parsec-collect-as-string
     (parsec-optional (parsec-one-of ?- ?+))
     (parsec-re "0[0-7]+")))
   8))

(defun gvariant--hexadecimal ()
  "Parse a GVariant integer in hexadecimal notation."
  (string-to-number
   (parsec-try
    (parsec-collect-as-string
     (parsec-optional (parsec-one-of ?- ?+))
     (parsec-and (parsec-str "0x") nil)
     (parsec-re "[0-9a-zA-Z]+")))
   16))

(defsubst gvariant--char (quote-char)
  "Parse a character inside a GVariant string delimited by QUOTE-CHAR."
  (parsec-or
   (parsec-and (parsec-ch ?\\) (gvariant--escaped-char))
   (parsec-none-of quote-char ?\\)))

(defun gvariant--escaped-char ()
  "Parse a GVariant string escape."
  (let ((case-fold-search nil))
    (parsec-or
     (char-to-string
      (assoc-default
       (string-to-char
        (parsec-satisfy (lambda (x) (assq x gvariant--special-chars))))
       gvariant--special-chars))
     (parsec-and (parsec-ch ?u) (gvariant--unicode-hex 4))
     (parsec-and (parsec-ch ?U) (gvariant--unicode-hex 8)))))

(defun gvariant--unicode-hex (n)
  "Parse a GVariant hexadecimal unicode value consisting of N hex digits."
  (let ((regex (format "[0-9a-zA-z]\\{%d\\}" n)))
    (format "%c" (string-to-number (parsec-re regex) 16))))

(defun gvariant--string ()
  "Parse a GVariant string."
  (parsec-or
   (parsec-between (parsec-ch ?\')
                   (parsec-ch ?\')
                   (parsec-many-as-string (gvariant--char ?\')))
   (parsec-between (parsec-ch ?\")
                   (parsec-ch ?\")
                   (parsec-many-as-string (gvariant--char ?\")))))

(defun gvariant--array ()
  "Parse a GVariant array."
  (vconcat
   (parsec-try
    (parsec-between
     (parsec-ch ?\[)
     (parsec-ch ?\])
     (gvariant--comma-separated-values)))))

(defun gvariant--tuple ()
  "Parse a GVariant tuple."
  (parsec-try
   (parsec-between
    (parsec-ch ?\()
    (parsec-ch ?\))
    (gvariant--comma-separated-values))))

(defsubst gvariant--comma-separator ()
  "Parse a comma separator, optionally enclosed by whitespace."
  (parsec-and
   (gvariant--whitespace)
   (parsec-ch ?,)
   (gvariant--whitespace)
   nil))

(defun gvariant--comma-separated-values ()
  "Parse a comma separated sequence of GVariant values (array or tuple contents)."
  (parsec-sepby
   (gvariant--value)
   (gvariant--comma-separator)))

(defun gvariant--dictionary ()
  "Parse a GVariant dictionary."
  (parsec-or
   (gvariant--dictionary-mapping)
   (gvariant--dictionary-entries-array)))

(defun gvariant--dictionary-mapping ()
  "Parse a GVariant dictionary expressed as a mapping."
  (parsec-try
   (parsec-between
    (parsec-ch ?\{)
    (parsec-ch ?\})
    (parsec-sepby
     (parsec-collect*
      (gvariant--value)
      (parsec-and
       (gvariant--whitespace)
       (parsec-ch ?:)
       (gvariant--whitespace)
       nil)
      (gvariant--value))
     (gvariant--comma-separator)))))

(defsubst gvariant--dictionary-entry ()
  "Parse a GVariant dictionary entry."
  (parsec-between
   (parsec-ch ?\{)
   (parsec-ch ?\})
   (parsec-collect*
    (gvariant--value)
    (parsec-and
     (gvariant--comma-separator)
     nil)
    (gvariant--value))))

(defun gvariant--dictionary-entries-array ()
  "Parse an array of GVariant dictionary entries."
  (parsec-try
   (parsec-between
    (parsec-ch ?\[)
    (parsec-ch ?\])
    (parsec-sepby
     (gvariant--dictionary-entry)
     (gvariant--comma-separator)))))

(provide 'gvariant)
;;; gvariant.el ends here
