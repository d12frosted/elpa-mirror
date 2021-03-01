;;; elx.el --- extract information from Emacs Lisp libraries  -*- lexical-binding: t -*-

;; Copyright (C) 2008-2021  Jonas Bernoulli

;; Author: Jonas Bernoulli <jonas@bernoul.li>
;; Created: 20081202
;; Package-Requires: ((emacs "25.1"))
;; Package-Version: 20210228.2103
;; Package-Commit: de9d42c86fc3e71239492f64bf4ed7325b056363
;; Homepage: https://github.com/emacscollective/elx
;; Keywords: docs, libraries, packages

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package extracts information from Emacs Lisp libraries.  It
;; extends built-in `lisp-mnt', which is only suitable for libraries
;; that closely follow the header conventions.  Unfortunately there
;; are many libraries that do not - this library tries to cope with
;; that.

;; It also defines some new extractors not available in `lisp-mnt',
;; and some generalizations of extractors available in the latter.

;;; Code:

(require 'json)
(require 'lisp-mnt)
(require 'subr-x)

(defgroup elx nil
  "Extract information from Emacs Lisp libraries."
  :group 'maint
  :link '(url-link :tag "Homepage" "https://github.com/emacscollective/elx"))

;;; Extract Summary

(defun elx-summary (&optional file sanitize)
  "Return the one-line summary of file FILE.
If optional FILE is nil return the summary of the current buffer
instead.  When optional SANITIZE is non-nil a trailing period is
removed and the first word is upcases."
  (lm-with-file file
    (and (cl-flet ((summary-match
                    ()
                    (and (looking-at lm-header-prefix)
                         (progn (goto-char (match-end 0))
                                ;; There should be three dashes after the
                                ;; filename but often there are only two or
                                ;; even just one.
                                (looking-at "[^ ]+[ \t]+-+[ \t]+\\(.*\\)")))))
           (or (summary-match)
               ;; Some people put the -*- specification on a separate
               ;; line, pushing the summary to the second or third line.
               (progn (forward-line) (summary-match))
               (progn (forward-line) (summary-match))))
         (let ((summary (match-string-no-properties 1)))
           (and (not (equal summary ""))
                (progn
                  ;; Strip off -*- specifications.
                  (when (string-match "[ \t]*-\\*-.*-\\*-" summary)
                    (setq summary (substring summary 0 (match-beginning 0))))
                  (when sanitize
                    (when (string-match "\\.$" summary)
                      (setq summary (substring summary 0 -1)))
                    (when (string-match "^[a-z]" summary)
                      (setq summary
                            (concat (upcase (substring summary 0 1))
                                    (substring summary 1)))))
                  (and (not (equal summary ""))
                       summary)))))))

;;; Extract Keywords

(defcustom elx-remap-keywords nil
  "List of keywords that should be replaced or dropped by `elx-keywords'.
If function `elx-keywords' is called with a non-nil SANITIZE
argument it checks this variable to determine if keywords should
be dropped from the return value or replaced by another.  If the
cdr of an entry is nil then the keyword is dropped; otherwise it
will be replaced with the keyword in the cadr."
  :group 'elx
  :type '(repeat (list string (choice (const  :tag "drop" nil)
                                      (string :tag "replacement")))))

(defvar elx-keywords-regexp "^[- a-z]+$")

(defun elx-keywords-list (&optional file sanitize symbols)
  "Return list of keywords given in file FILE.
If optional FILE is nil return keywords given in the current
buffer instead.  If optional SANITIZE is non-nil replace or
remove some keywords according to option `elx-remap-keywords'.
If optional SYMBOLS is non-nil return keywords as symbols,
else as strings."
  (lm-with-file file
    (let (keywords)
      (dolist (line (lm-header-multiline "keywords"))
        (dolist (keyword (split-string
                          (downcase line)
                          (concat "\\("
                                  (if (string-match-p "," line)
                                      ",[ \t]*"
                                    "[ \t]+")
                                  "\\|[ \t]+and[ \t]+\\)")
                          t))
          (when sanitize
            (when-let ((remap (assoc keyword elx-remap-keywords)))
              (setq keyword (cadr remap)))
            (when (and keyword (string-match elx-keywords-regexp keyword))
              (push keyword keywords)))))
      (setq keywords (delete-dups (sort keywords 'string<)))
      (if symbols (mapcar #'intern keywords) keywords))))

;;; Extract Commentary

(defun elx-commentary (&optional file sanitize)
  "Return the commentary in file FILE, or current buffer if FILE is nil.
Return the value as a string.  In the file, the commentary
section starts with the tag `Commentary' or `Documentation' and
ends just before the next section.  If the commentary section is
absent, return nil.

If optional SANITIZE is non-nil cleanup the returned string.
Leading and trailing whitespace is removed from the returned
value but it always ends with exactly one newline.  On each line
the leading semicolons and exactly one space are removed,
likewise leading \"\(\" is replaced with just \"(\".  Lines
consisting only of whitespace are converted to empty lines."
  (lm-with-file file
    (when-let ((start (lm-section-start lm-commentary-header t)))
      (progn
        (goto-char start)
        (let ((commentary (buffer-substring-no-properties
                           start (lm-commentary-end))))
          (when sanitize
            (mapc (lambda (elt)
                    (setq commentary (replace-regexp-in-string
                                      (car elt) (cdr elt) commentary)))
                  '(("^;+ ?"        . "")
                    ("^\\\\("       . "(")
                    ("^\n"        . "")
                    ("^[\n\t\s]\n$" . "\n")
                    ("\\`[\n\t\s]*" . "")
                    ("[\n\t\s]*\\'" . "")))
            (setq commentary
                  (and (string-match "[^\s\t\n]" commentary)
                       (concat commentary "\n"))))
          commentary)))))

;;; Extract Pages

(defun elx-wikipage (&optional file)
  "Extract the Emacswiki page of the specified package."
  (when-let ((page (lm-with-file file (lm-header "Doc URL"))))
    (and (string-match
          "^<?http://\\(?:www\\.\\)?emacswiki\\.org.*?\\([^/]+\\)>?$"
          page)
         (match-string 1 page))))

;;; Extract License

(defconst elx-gnu-permission-statement-regexp
  (replace-regexp-in-string
   "\s" "[\s\t\n;]+"
   ;; is free software[.,:;]? \
   ;; you can redistribute it and/or modify it under the terms of the \
   "\
GNU \\(?1:Lesser \\| Library \\|Affero \\|Free \\)?\
General Public Licen[sc]e[.,:;]? \
\\(?:as published by the \\(?:Free Software Foundation\\|FSF\\)[.,:;]? \\)?\
\\(?:either \\)?\
\\(?:GPL \\)?\
version \\(?2:[0-9.]*[0-9]\\)[.,:;]?\
\\(?: of the Licen[sc]e[.,:;]?\\)?\
\\(?3: or \\(?:(?at your option)? \\)?any later version\\)?"))

(defconst elx-bsd-permission-statement-regexp
  (replace-regexp-in-string
   "%" "[-0-4).*\s\t\n;]+"
   (replace-regexp-in-string
    "\s" "[\s\t\n;]+"
    ;; Copyright (c) <year>, <copyright holder>
    ;; All rights reserved.
    "\
Redistribution and use in source and binary forms, with or without \
modification, are permitted provided that the following conditions are met: \
%Redistributions of source code must retain the above copyright \
notice, this list of conditions and the following disclaimer\\.
\
%Redistributions in binary form must reproduce the above copyright \
notice, this list of conditions and the following disclaimer in the \
documentation and/or other materials provided with the distribution\\. \
\
\\(?3:\\(?4:%All advertising materials mentioning features or use of this software \
must display the following acknowledgement: \
\
This product includes software developed by .+?\\. \\)?\
%\\(?:Neither the name of .+? nor the names of its contributors may\\|\
The name of the University may not\\) \
be used to endorse or promote products \
derived from this software without specific prior written permission\\. \\)?\
\
THIS SOFTWARE IS PROVIDED BY \
\\(?:THE \\(UNIVERSITY\\|COPYRIGHT HOLDERS?\\|COPYRIGHT OWNERS?\\)\
\\(?: \\(?:AND\\|OR\\) CONTRIBUTORS\\)?\\|.+?\\) \
[\"'`]*AS IS[\"'`]* AND ANY \
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED \
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE \
DISCLAIMED. IN NO EVENT SHALL \
\\(?:THE \\(UNIVERSITY\\|COPYRIGHT HOLDERS?\\|COPYRIGHT OWNERS?\\)\
\\(?: \\(?:AND\\|OR\\) CONTRIBUTORS\\)?\\|.+?\\) \
BE LIABLE FOR ANY \
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES \
\(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; \
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND \
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT \
\(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS \
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE\\.")))

(defconst elx-mit-permission-statement-regexp
  (replace-regexp-in-string
   "\s" "[\s\t\n;]+"
   ;; Copyright (c) <year> <copyright holders>
   ;;
   "\
Permission is hereby granted, free of charge, to any person obtaining a copy \
of this software and associated documentation files\\(?: (the \"Software\")\\)?, \
to deal \
in the Software without restriction, including without limitation the rights \
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell \
copies of the Software, and to permit persons to whom the Software is \
furnished to do so, subject to the following conditions: \
\
The above copyright notice and this permission notice shall be included in all \
copies or substantial portions of the Software\\. \
\
THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR \
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, \
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT\\. IN NO EVENT SHALL THE \
\\(?:AUTHORS OR COPYRIGHT HOLDERS\\|.+?\\) \
BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER \
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, \
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE \
SOFTWARE\\.\
\\( \
Except as contained in this notice, \
the names? \\(?:of the above copyright holders\\|.+?\\) shall not be
used in advertising or otherwise to promote the sale, use or other dealings in
this Software without prior written authorization\\)?"
   ;; "." or "from <copyright holders>."
   ))

(defconst elx-isc-permission-statement-regexp
  (replace-regexp-in-string
   "\s" "[\s\t\n;]+"
   ;; Copyright <YEAR> <OWNER>
   ;;
   "\
Permission to use, copy, modify, and\\(/or\\)? distribute this software \
for any purpose with or without fee is hereby granted, provided \
that the above copyright notice and this permission notice appear \
in all copies\\. \
\
THE SOFTWARE IS PROVIDED [\"'`]*AS IS[\"'`]* AND THE AUTHOR \
DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING \
ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS\\. IN NO \
EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, \
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER \
RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION \
OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF \
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE\\."))

(defconst elx-cc-permission-statement-regexp
  (replace-regexp-in-string
   "\s" "[\s\t\n;]+"
   ;; This work is
   "\
licensed under the Creative Commons \
\\(Attribution\
\\|Attribution-ShareAlike\
\\|Attribution-NonCommercial\
\\|Attribution-NoDerivs\
\\|Attribution-NonCommercial-ShareAlike\
\\|Attribution-NonCommercial-NoDerivs\
\\) \
\\([0-9.]+\\) .*?Licen[sc]e\\."
   ;; To view a copy of this license, visit"
   ))

(defconst elx-wtf-permission-statement-regexp
  (replace-regexp-in-string
   "\s" "[\s\t\n;]+"
   ;; This program is
   "\
free software. It comes without any warranty, to \
the extent permitted by applicable law\\. You can redistribute it \
and/or modify it under the terms of the Do What The Fuck You Want \
To Public License, Version 2, as published by Sam Hocevar\\."))

(defconst elx-gnu-license-keyword-regexp "\
\\(?:GNU \\(?1:Lesser \\|Library \\|Affero \\|Free \\)?General Public Licen[sc]e ?\
\\|\\(?4:[laf]?gpl\\)[- ]?\
\\)\
\\(?5:>= \\)?\
\\(?:\\(?:[vV]\\|version \\)?\\(?2:[0-9.]*[0-9]\\)\\)?\
\\(?3:\\(?:\\+\
\\|,? or \\(?:(at your option) \\)?\\(?:any \\)?later\\(?: version\\)?\
\\|,? or newer\
\\|,? or whatever newer comes along\
\\)\\)?")

(defconst elx-gnu-non-standard-permission-statement-alist
  `(("GPL-3+"        . "^;\\{1,4\\} Licensed under the same terms as Emacs")
    ("GPL-2+"        . "^;;   :licence:  GPL 2 or later (free software)")
    ("GPL"           . "^;; Copyright (c) [-0-9]+ Jason Milkins (GNU/GPL Licence)")
    ("GPL"           . "^;; GPL'ed under GNU'S public license")
    ("GPL-2"         . ,(replace-regexp-in-string "\s" "[\s\n;]+" "\
This file is free software; you can redistribute it and/or \
modify it under the terms of version 2 of the GNU General \
Public License as published by the Free Software Foundation\\.")) ; lmselect, tiger
    ))

(defconst elx-non-gnu-license-keyword-alist
  '(("Apache-2.0"    . "apache-2\\.0")
    ("Artistic-1.0"  . "Artistic-1.0")
    ("BSD-3-clause"  . "BSD Licen[sc]e 2\\.0")
    ("BSD-3-clause"  . "\\(Revised\\|New\\|Modified\\) BSD\\( Licen[sc]e\\)?")
    ("BSD-3-clause"  . "BSD[-v]?3")
    ("BSD-3-clause"  . "BSD[- ]3-clause\\( license\\)?")
    ("BSD-2-clause"  . "BSD[-v]?2")
    ("BSD-2-clause"  . "BSD[- ]2-clause\\( license\\)?")
    ("BSD-2-clause"  . "Simplified BSD\\( Licen[sc]e\\)?")
    ("BSD-2-clause"  . "The same license terms as Ruby")
    ("MIT"           . "mit")
    ("as-is"         . "as-?is")
    ("as-is"         . "free for all usages/modifications/distributions/whatever.") ; darkroom-mode, w32-fullscreen
    ("public-domain" . "public[- ]domain")
    ("WTFPL-2"       . "WTFPL .+?http://sam\\.zoy\\.org/wtfpl")
    ("WTFPL"         . "WTFPL")
    ("CeCILL"        . "CeCILL")
    ("CeCILL-B"      . "CeCILL-B")
    ("MS-PL"         . "MS-PL")
    ("unlicense"     . "Unlicense")
    ("BEER-WARE"     . "BEER-WARE")
    ))

(defconst elx-non-gnu-license-keyword-regexp "\
\\`\\(?4:[a-z]+\\)\\(?:\\(?:v\\|version \\)?\\(?2:[0-9.]*[0-9]\\)\\)?\\'")

(defconst elx-permission-statement-alist
  `(("Apache-2.0"    . "^;.* Apache Licen[sc]e, Version 2\\.0")
    ("MIT"           . "^;.* mit licen[sc]e")
    ("MIT"           . "^;; This file is free software (MIT License)$")
    ("MIT-0"         . "^;; terms of the MIT No Attribution license\\.") ; logpad
    ("GPL-3+"        . "^;; Licensed under the same terms as Emacs\\.$")
    ("GPL-3+"        . "^;; This file may be distributed under the same terms as GNU Emacs\\.$")
    ("GPL-3+"        . "^;; Licensed under the same terms as Org-mode")
    ("GPL-3+"        . "^;; Standard GPL v3 or higher license applies\\.")
    ("GPL-3"         . "^;; This file is free software (GPLv3 License)$")
    ("GPL-3"         . "^;; This software is licensed under the GPL version 3")
    ("GPL-3"         . "^;; This software can be redistributed\\. GPL v3 applies\\.$")
    ("GPL-3"         . "^;; This file is licensed under GPLv3\\.$") ; metapost-mode+
    ("GPL-2+"        . "^;; choice of the GNU General Public License (version 2 or later),$") ; uuid
    ("GPL-2"         . "^;; This software can be redistributed\\. GPL v2 applies\\.$")
    ("GPL"           . "^;; Released under the GPL")
    ("GPL"           . "^;; Licensed under the GPL")
    ("WTFPL-2"       . "do what the fuck you want to public licen[sc]e,? version 2")
    ("WTFPL"         . "do what the fuck you want to")
    ("WTFPL"         . "wtf public licen[sc]e")
    ("BSD-2-clause"  . "^;; Simplified BSD Licen[sc]e$")
    ("BSD-2-clause"  . "This software can be treated with: ``The 2-Clause BSD License''") ; yatex
    ("BSD-3-clause"  . "^;; 3-clause \"new bsd\"")
    ("BSD-3-clause"  . "freely distributable under the terms of a new BSD licence") ; tinysegmenter
    ("BSD-3-clause"  . "^; Distributed under the OSI-approved BSD 3-Clause License") ; cmake-mode
    ("BSD-3-clause"  . "Licensed under the BSD-3-[cC]lause [lL]icense\\.$") ; gsettings, gvariant
    ("BSD-3-clause"  . "Licensed under the 3-[cC]lause BSD [lL]icense\\.$") ; balanced-windows
    ("Artistic-2.0"  . "^;; .*Artistic Licen[sc]e 2\\.0")
    ("CeCILL-B"      . "^;; It is a free software under the CeCILL-B license\\.$")
    ("MS-PL"         . "^;; This code is distributed under the MS-Public License")
    ("MS-PL"         . "licensed under the Ms-PL")
    ("Ruby"          . "^;;; Use and distribution subject to the terms of the Ruby license\\.$") ; rcodetools
    ("public-domain" . "^;.*in\\(to\\)? the public[- ]domain")
    ("public-domain" . "^;+ +Public domain")
    ("public-domain" . "^;+ This program belongs to the public domain")
    ("public-domain" . "^;; This file is public domain")
    ("public-domain" . "placed in the Public\n;;;? Domain") ; manued
    ("public-domain" . "^;; No license, this code is under public domain, do whatever you want") ; company-go
    ("as-is"         . "\"as is\"*")
    ("as-is"         . "\\*as is\\*")
    ("as-is"         . "‘as-is’")
    ("as-is"         . "^;;; ada-ref-man\\.el --- Ada Reference Manual 2012$") ; ada-ref-man
    ("as-is"         . "^;.* \\(\\(this\\|the\\) \\(software\\|file\\) is \\)\
\\(provided\\|distributed\\) \
\\(by the \\(author?\\|team\\|copyright holders\\)\\( and contributors\\)? \\)?\
[\"'`]*as\\(\n;;\\)?[- ]is[\"'`]*")
    ("BEER-WARE"     . "^;; If you like this package and we meet in the future, you can buy me a
;; beer\\. Otherwise, if we don't meet, drink a beer anyway\\.") ; distel-completion-lib
    ("COPYLOVE"      . "^;; Copying is an act of love, please copy\\.")
    ("CC BY-SA 4.0"  . "^;; This file is distributed under the Creative Commons
;; Attribution-ShareAlike 4\\.0 International Public License") ; sicp-info
    ("CC BY-NC-SA 3.0" . "^;; \\[CC BY-NC-SA 3\\.0\\](http://creativecommons\\.org/licenses/by-nc-sa/3\\.0/)") ; vimgolf
    ("Unicode TOS"   . "covered by the Unicode copyright terms") ; uni-confusables
    ))

(defcustom elx-license-use-licensee t
  "Whether `elx-license' used the \"licensee\" executable."
  :group 'elx
  :type 'boolean)

(defun elx-license (&optional file dir package-name)
  "Attempt to return the license used for the file FILE.
Or the license used for the file that is being visited in the
current buffer if FILE is nil.

*** A value is returned in the hope that it will be useful, but
*** WITHOUT ANY WARRANTY; without even the implied warranty of
*** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

The license is determined from the permission statement, if
any.  Otherwise the value of the \"License\" header keyword
is considered.  If a \"LICENSE\" file or similar exits in
the proximity of FILE then that is considered also, using
`licensee' (https://github.com/licensee/licensee), provided
`elx-license-use-licensee' is non-nil.

An effort is made to normalize the returned value."
  (lm-with-file file
    (cl-flet ((format-gnu-abbrev
               (&optional object)
               (let ((abbrev  (match-string 1 object))
                     (version (match-string 2 object))
                     (later   (or (match-string 3 object)
                                  (match-string 5 object)))
                     (prefix  (match-string 4 object)))
                 (concat (if prefix
                             (upcase prefix)
                           (pcase (and abbrev (downcase abbrev))
                             ("lesser "  "LGPL")
                             ("library " "LGBL")
                             ("affero "  "AGPL")
                             ("free "    "FDL")
                             (`nil       "GPL")))
                         (and version (concat "-" version))
                         (and later "+")))))
      (let* ((bound nil) ; (lm-code-start)) some put it at eof
             (case-fold-search t)
             (license
              (or (and (re-search-forward elx-gnu-permission-statement-regexp bound t)
                       (format-gnu-abbrev))
                  (and (re-search-forward elx-bsd-permission-statement-regexp bound t)
                       (format "BSD-%s-clause"
                               (cond ((match-string 4) 4)
                                     ((match-string 3) 3)
                                     (t                2))))
                  (and (re-search-forward elx-mit-permission-statement-regexp bound t)
                       (format "MIT (%s)"
                               (if (match-string 1) "expat" "x11")))
                  (and (re-search-forward elx-isc-permission-statement-regexp bound t)
                       (format "ISC (%s)"
                               (if (match-string 1) "and/or" "and")))
                  (and (re-search-forward elx-cc-permission-statement-regexp bound t)
                       (let ((license (match-string 1))
                             (version (match-string 2)))
                         (format "CC-%s-%s"
                                 (pcase license
                                   ("Attribution"                          "BY")
                                   ("Attribution-ShareAlike"               "BY-SA")
                                   ("Attribution-NonCommercial"            "BY-NC")
                                   ("Attribution-NoDerivs"                 "BY-ND")
                                   ("Attribution-NonCommercial-ShareAlike" "BY-NC-SA")
                                   ("Attribution-NonCommercial-NoDerivs"   "BY-NC-ND"))
                                 version)))
                  (and (re-search-forward elx-wtf-permission-statement-regexp bound t)
                       "WTFPL-2")
                  (when-let ((license (lm-header "\\(?:Licen[sc]e\\|SPDX-License-Identifier\\)")))
                    (and (not (equal license ""))
                         (string-match elx-gnu-license-keyword-regexp license)
                         (format-gnu-abbrev license)))
                  (and elx-license-use-licensee
                       (elx-licensee dir))
                  (car (cl-find-if (pcase-lambda (`(,_ . ,re))
                                     (re-search-forward re bound t))
                                   elx-gnu-non-standard-permission-statement-alist))
                  (when-let ((license (lm-header "\\(?:Licen[sc]e\\|SPDX-License-Identifier\\)")))
                    (or (car (cl-find-if (pcase-lambda (`(,_ . ,re))
                                           (string-match re license))
                                         elx-non-gnu-license-keyword-alist))
                        (and (string-match elx-non-gnu-license-keyword-regexp license)
                             (format-gnu-abbrev license))))
                  (car (cl-find-if (pcase-lambda (`(,_ . ,re))
                                     (re-search-forward re bound t))
                                   elx-permission-statement-alist)))))
        (pcase (list license package-name)
          (`("GPL-3.0+" ,_)         "GPL-3+")
          (`("GPL-2.0+" ,_)         "GPL-2+")
          (`("GPL-3.0" ,_)          "GPL-3")
          (`("GPL-2.0" ,_)          "GPL-2")
          (`("BSD-3-Clause" ,_)     "BSD-3-clause")
          (`("BSD-2-Clause" ,_)     "BSD-2-clause")
          (`("LGPL-3.0" ,_)         "LGPL-3")
          (`("MPL-2.0" ,_)          "MPL-2")
          (`("Unlicense" ,_)        "unlicense")
          (_ license))))))

(defun elx-licensee (&optional directory-or-file)
  (save-match-data
    (let* ((match
            (with-temp-buffer
              (save-excursion
                (call-process "licensee" nil '(t nil) nil "detect" "--json"
                              (or directory-or-file default-directory)))
              (car (cl-sort
                    (cdr (assq 'matched_files
                               (let ((json-object-type 'alist)
                                     (json-array-type  'list)
                                     (json-key-type    'symbol)
                                     (json-false       nil)
                                     (json-null        nil))
                                 (condition-case nil (json-read)
                                   (error (error "licensee failed: %S"
                                                 (buffer-string)))))))
                    #'>
                    :key (lambda (elt) (or (let-alist elt .matcher.confidence)) 0)))))
           (license (cdr (assq 'matched_license match)))
           (file    (cdr (assq 'filename match))))
      (pcase license
        (""            nil) ; haven't seen this lately
        ("NONE"        nil) ; unable to detect a license
        ("NOASSERTION" nil) ; almost able to detect a licence
        ("ISC License"
         (with-temp-buffer
           (insert-file-contents file)
           (re-search-forward
            "Permission to use, copy, modify,? and\\(/or\\)? distribute")
           (if (match-beginning 1) "ISC (and/or)" "ISC (and)")))
        (_ license)))))

(defcustom elx-license-url-alist
  '(("GPL-3"         . "http://www.fsf.org/licensing/licenses/gpl.html")
    ("GPL-2"         . "http://www.gnu.org/licenses/old-licenses/gpl-2.0.html")
    ("GPL-1"         . "http://www.gnu.org/licenses/old-licenses/gpl-1.0.html")
    ("LGPL-3"        . "http://www.fsf.org/licensing/licenses/lgpl.html")
    ("LGPL-2.1"      . "http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html")
    ("LGPL-2.0"      . "http://www.gnu.org/licenses/old-licenses/lgpl-2.0.html")
    ("AGPL-3"        . "http://www.fsf.org/licensing/licenses/agpl.html")
    ("FDL-1.2"       . "http://www.gnu.org/licenses/old-licenses/fdl-1.2.html")
    ("FDL-1.1"       . "http://www.gnu.org/licenses/old-licenses/fdl-1.1.html"))
  "List of FSF license to canonical license url mappings.
Each entry has the form (LICENSE . URL) where LICENSE is the
abbreviation of a license published by the Free Software
Foundation in the form \"<ABBREV>-<VERSION>\" and URL the
canonical url to the license."
  :group 'elx
  :type '(repeat (cons (string :tag "License")
                       (string :tag "URL"))))

(defun elx-license-url (license)
  "Return the canonical url to the FSF license LICENSE.
The license is looked up in the variable `elx-license-url'.
If no matching entry exists then return nil."
  (cdr (assoc license elx-license-url-alist)))

;;; Extract Dates

(defun elx-created (&optional file)
  "Return the created date given in file FILE.
Or of the current buffer if FILE is equal to `buffer-file-name'
or is nil.  The date is returned as YYYYMMDD or if not enough
information is available YYYYMM or YYYY.  The date is taken from
the \"Created\" header keyword, or if that doesn't work from the
copyright line."
  (lm-with-file file
    (or (elx--date-1 (lm-creation-date))
        (elx--date-1 (elx--date-copyright)))))

(defun elx-updated (&optional file)
  "Return the updated date given in file FILE.
Or of the current buffer if FILE is equal to `buffer-file-name'
or is nil.  The date is returned as YYYYMMDD or if not enough
information is available YYYYMM or YYYY.  The date is taken from
the \"Updated\" or \"Last-Updated\" header keyword."
  (lm-with-file file
    (elx--date-1 (lm-header "\\(last-\\)?updated"))))

;; Yes, I know.
(defun elx--date-1 (string)
  (and (stringp string)
       (let ((ymd "\
\\([0-9]\\{4,4\\}\\)\\(?:[-/.]?\
\\([0-9]\\{1,2\\}\\)\\(?:[-/.]?\
\\([0-9]\\{1,2\\}\\)?\\)?\\)")
             (dmy "\
\\(?3:[0-9]\\{1,2\\}\\)\\(?:[-/.]?\\)\
\\(?2:[0-9]\\{1,2\\}\\)\\(?:[-/.]?\\)\
\\(?1:[0-9]\\{4,4\\}\\)"))
         (or (elx--date-2 string ymd t)
             (elx--date-2 string dmy t)
             (let ((a (elx--date-3 string))
                   (b (or (elx--date-2 string ymd nil)
                          (elx--date-2 string dmy nil))))
               (cond ((not a) b)
                     ((not b) a)
                     ((> (length a) (length b)) a)
                     ((> (length b) (length a)) b)
                     (t a)))))))
  
(defun elx--date-2 (string regexp anchored)
  (and (string-match (if anchored (format "^%s$" regexp) regexp) string)
       (let ((m  (match-string 2 string))
             (d  (match-string 3 string)))
         (concat (match-string 1 string)
                 (and m d (concat (if (= (length m) 2) m (concat "0" m))
                                  (if (= (length d) 2) d (concat "0" d))))))))

(defun elx--date-3 (string)
  (let ((time (mapcar (lambda (e) (or e 0))
                      (butlast (ignore-errors (parse-time-string string))))))
    (and time
         (not (= (nth 5 time) 0))
         (format-time-string (if (and (> (nth 4 time) 0)
                                      (> (nth 3 time) 0))
                                 "%Y%m%d"
                               ;; (format-time-string
                               ;;  "%Y" (encode-time x x x 0 0 2012))
                               ;; => "2011"
                               (setcar (nthcdr 3 time) 1)
                               (setcar (nthcdr 4 time) 1)
                               "%Y")
                             (apply 'encode-time time)
                             t))))

;; FIXME implement range extraction in lm-crack-copyright
(defun elx--date-copyright ()
  (let ((lm-copyright-prefix "^\\(;+[ \t]\\)+Copyright \\((C) \\)?"))
    (when (lm-copyright-mark)
      (cadr (lm-crack-copyright)))))

;;; Extract People

(defcustom elx-remap-names nil
  "List of names that should be replaced or dropped by `elx-crack-address'.
If function `elx-crack-address' is called with a non-nil SANITIZE argument
it checks this variable to determine if names should be dropped from the
return value or replaced by another.  If the cdr of an entry is nil then
the keyword is dropped; otherwise it will be replaced with the keyword in
the cadr."
  :group 'elx
  :type '(repeat (list string (choice (const  :tag "drop" nil)
                                      (string :tag "replacement")))))

;; Yes, I know.
(defun elx-crack-address (x)
  "Split up an email address X into full name and real email address.
The value is a cons of the form (FULLNAME . ADDRESS)."
  (let (name mail)
    (cond ((string-match (concat "\\(.+\\) "
                                 "?[(<]\\(\\S-+@\\S-+\\)[>)]") x)
           (setq name (match-string 1 x))
           (setq mail (match-string 2 x)))
          ((string-match (concat "\\(.+\\) "
                                 "[(<]\\(?:\\(\\S-+\\) "
                                 "\\(?:\\*?\\(?:AT\\|[.*]\\)\\*?\\) "
                                 "\\(\\S-+\\) "
                                 "\\(?:\\*?\\(?:DOT\\|[.*]\\)\\*? \\)?"
                                 "\\(\\S-+\\)\\)[>)]") x)
           (setq name (match-string 1 x))
           (setq mail (concat (match-string 2 x) "@"
                              (match-string 3 x) "."
                              (match-string 4 x))))
          ((string-match (concat "\\(.+\\) "
                                 "[(<]\\(?:\\(\\S-+\\) "
                                 "\\(?:\\*?\\(?:AT\\|[.*]\\)\\*?\\) "
                                 "\\(\\S-+\\)[>)]\\)") x)
           (setq name (match-string 1 x))
           (setq mail (concat (match-string 2 x) "@"
                              (match-string 3 x))))
          ((string-match (concat "\\(\\S-+@\\S-+\\) "
                                 "[(<]\\(.*\\)[>)]") x)
           (setq name (match-string 2 x))
           (setq mail (match-string 1 x)))
          ((string-match "\\S-+@\\S-+" x)
           (setq mail x))
          (t
           (setq name x)))
    (setq name (and (stringp name)
                    (string-match "^ *\\([^:0-9<@>]+?\\) *$" name)
                    (match-string 1 name)))
    (setq mail (and (stringp mail)
                    (string-match
                     (concat "^\\s-*\\("
                             "[a-z0-9!#$%&'*+/=?^_`{|}~-]+"
                             "\\(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+\\)*@"
                             "\\(?:[a-z0-9]\\(?:[a-z0-9-]*[a-z0-9]\\)?\.\\)+"
                             "[a-z0-9]\\(?:[a-z0-9-]*[a-z0-9]\\)?"
                             "\\)\\s-*$") mail)
                    (downcase (match-string 1 mail))))
    (when-let ((elt (assoc name elx-remap-names)))
      (setq name (cadr elt)))
    (and (or name mail)
         (cons name mail))))

(defun elx-people (header file)
  (lm-with-file file
    (let (people)
      (dolist (p (lm-header-multiline header))
        (when-let ((p (and p (elx-crack-address p))))
          (push p people)))
      (nreverse people))))

(defun elx-authors (&optional file)
  "Return the author list of file FILE.
Or of the current buffer if FILE is equal to `buffer-file-name'
or is nil.  Each element of the list is a cons; the car is the
full name, the cdr is an email address."
  (elx-people "authors?" file))

(defun elx-maintainers (&optional file)
  "Return the maintainer list of file FILE.
Or of the current buffer if FILE is equal to `buffer-file-name'
or is nil.  Each element of the list is a cons; the car is the
full name, the cdr is an email address.  If there is no
maintainer list then return the author list."
  (or (elx-people "maintainers?" file)
      (elx-authors file)))

(defun elx-adapted-by (&optional file)
  "Return the list of people who have adapted file FILE
Or of the current buffer if FILE is equal to `buffer-file-name'
or is nil.  Each element of the list is a cons; the car is the
full name, the cdr is an email address."
  (elx-people "adapted-by" file))

;;; _
(provide 'elx)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; elx.el ends here
