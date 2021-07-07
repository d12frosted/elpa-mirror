;;; helm-recoll.el --- helm interface for the recoll desktop search tool. -*- lexical-binding: t -*-

;; Copyright (C) 2012 Thierry Volpiatto
;; Copyright (C) 2013-2016 Joe Bloggs, Michael Heerdegen and Cayetano Santos

;; Author:      Thierry Volpiatto <thierry.volpiatto at gmail.com>
;; Maintainers: Joe Bloggs <vapniks at yahoo.com>,
;;              Michael Heerdegen <michael_heerdegen at web.de>
;;              Cayetano Santos <cayetanosantos at gmail.com>

;; Filename: helm-recoll.el
;; Description: helm interface for the recoll desktop search tool.
;; URL: https://github.com/emacs-helm/helm-recoll
;; Package-Version: 20200805.1235
;; Package-Commit: c021a3b5e8c010bdad062cceb80fb49788f89e9f
;; Keywords: convenience
;; Version: 1.2
;; Package-Requires: ((helm "3.3") (emacs "24.4"))
;;
;; Features that might be required by this library:
;;
;; helm
;;

;; This file is NOT part of GNU Emacs.

;;; License:

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
;;
;; Helm interface for the recoll [1] desktop search tool.
;;
;; [1] http://www.lesbonscomptes.com/recoll/

;;; Create recoll indexes:
;;
;; First you have to create an index for each directory you want
;; to index, for this create some directories like "~/.recoll-<your-directory-name>"
;; then create "recoll.conf" config files in each directory containing
;; topdirs = <full/path/to/your/directory>
;; then run recollindex -c ~/.recoll-<your-directory-name>
;; to create index for each directory.
;; See https://bitbucket.org/medoc/recoll/wiki/MultipleIndexes
;; for more infos.

;;; Configure:
;;
;; Then you need to create some helm-recoll sources before you can use them.
;; You can create sources by customizing `helm-recoll-directories'.

;; Then just call M-x helm-recoll
;; will build a specific command for each directory and the specific sources for
;; these directories.

;;; Installation:
;;
;; After customizing `helm-recoll-directories' (see above)
;; just require helm-recoll or even better autoload the `helm-recoll'
;; function.
;; If you use use-package you can use e.g
;;
;;     (use-package helm-recoll
;;         :commands helm-recoll
;;         :init (setq helm-recoll-directories
;;                     '(("confdir" . "~/.recoll-.emacs.d")
;;                       ("lisp sources" . "~/.recoll-elisp")
;;                       ("work" . "~/.recoll-work"))))

;;; Code:

(eval-when-compile
  (require 'cl-lib))
(require 'helm)
(require 'helm-for-files)

(defvar helm-find-files-actions)
(defvar helm-find-files-map)
(defvar helm-ff-help-message)

(defgroup helm-recoll ()
  "Helm interface for the recoll desktop search tool"
  :group 'convenience
  :prefix "helm-recoll")

(defcustom helm-recoll-options '("recoll" "-t")
  "A list where the `car' is the name of the recoll program followed by options.
You do not need to include the -c option since this is already included, and the
config directory can be passed as a argument to `helm-recoll-create-source'."
  :type '(repeat string))

(defcustom helm-recoll-input-idle-delay 0.6
  "The `helm-input-idle-delay' value for helm-recoll."
  :type 'float)

(defvar helm-recoll-sources-buffer "*helm recoll source select*")

(defvar helm-recoll-history nil
  "History of helm-recoll queries.")

;;; Help

(defvar helm-recoll-help-message
  "* Helm Recoll Help

** Helm Recoll Query Options

Enter one of the following options before your query to specify the query type:

-l      advanced search query (default, see next section)
-f      (exact) file name search query
-a      all words search query (matches if document contains all the words)
-o      any words search query (matches if document contains any of the words)

** Recoll Advanced Queries

Queries are sequences of terms with implicit AND and explicit OR and NOT (-)
logical operators. NOT gets priority over OR which gets priority over AND
\(i.e. disjunctive normal form).

Terms can be either a word or double quoted phrase to search for in the
document, or a <FIELD>:<VALUE> pair as listed below. Wildcard (*/?/[]) and
anchor characters (^/$) can be used in words, phrases and field values, and
modifiers can be used for phrases (see below).

Example:

  ext:pdf -date:/2010 dir:local OR dir:share this OR that

is equivalent to

  ext:pdf AND (NOT date:/2010) AND (dir:local OR dir:share) AND (this OR that)

meaning search for

  pdf files BEFORE 2010 IN pathnames containing \"local\" or \"share\" with
  WORDS this or that IN

*** <FIELD>:<VALUE> pairs

title:      searching text in the document title or subject

author:     searching the documents originators

recipient:  searching the documents recipients

keyword:    searching document-specified keywords (few documents actually
							have any)
filename:   the document's file name

ext:        specifies the file name extension
            e.g.: ext:html

dir:        filtering on file location
            accepts negation, wildcards and tilde expansion; case sensitive

size:       filtering on file size
            use <,> or = and letters k/K, m/M, g/G, t/T as multipliers
            e.g (files between 100k and 1MB): size>100k size<1m

date:       for filtering on dates (but not times). General syntax is 2
            elements separated by a /. If either element is missing it is
            interpreted as the first/last date in the index. Each element can
            be a date in the form YYYY-MM-DD (the month or day may be missing)
            or a period in the form pNyNmNd where the N numbers are the
            respective numbers of years, months or days, any of which may be
            missing.
            e.g.:
            2001-03-01/p1y2m   the period covering 1 year and 2 months after
                                the 1st of March 2003
            2001/              from the beginning of 2001 up to now
            /2001              all dates up to 2001
            p2d/               from 2 days ago up to now

mime:       mime type
            values will be OR'ed by default except for negated terms which
            are AND'ed; you can use wildcards in the value (mime:text/*)
            e.g.: mime:application/* -mime:application/pdf

type:       category as defined in /usr/share/recoll/mimeconf
            (e.g. text/media/presentation/etc.).
            categories are OR'ed like mime types above, but can't be negated
            with -

*** Wildcards & Anchors

\"*\"           matches 0 or more characters
\"?\"           matches a single character
\"[]\"          match any character within the square brackets
\"^\"           match the beginning of the document text or field value
\"$\"           match the end of the document text or field value

Note: wildcards at the beginning of a word/phrase can slow recoll down a lot

*** Phrase Modifiers

Any of the following phrase modifiers may be placed at the end of a double
quoted phrase:

oN          allow upto N arbitrary words between words in phrase,
            e.g. ^\"test\"o5
            if N is not specified it defaults to 10
l           turn off stemming (mostly makes sense with p because stemming is
				      off by default for phrases)
p           turn default phrase search into a proximity one (unordered),
            e.g. \"order any in\"p
C           turn on case sensitivity
D           turn on diacritics sensitivity (if the index supports it)

** References

For more details see:

    https://www.lesbonscomptes.com/recoll/usermanual/webhelp/docs/index.html

** Commands
\\<helm-generic-files-map>
\\[helm-ff-run-toggle-basename]\t\tToggle basename.
\\[helm-ff-run-grep]\t\tRun grep (`\\[universal-argument]' to recurse).
\\[helm-ff-run-zgrep]\t\tRun zgrep.
\\[helm-ff-run-gid]\t\tRun GID (id-utils).
\\[helm-ff-run-pdfgrep]\t\tRun PDFgrep on marked files.
\\[helm-ff-run-copy-file]\t\tCopy file(s)
\\[helm-ff-run-rename-file]\t\tRename file(s).
\\[helm-ff-run-symlink-file]\t\tSymlink file(s).
\\[helm-ff-run-hardlink-file]\t\tHardlink file(s).
\\[helm-ff-run-delete-file]\t\tDelete file(s).
\\[helm-ff-run-byte-compile-file]\t\tByte compile Elisp file(s) (`\\[universal-argument]' to load).
\\[helm-ff-run-load-file]\t\tLoad Elisp file(s).
\\[helm-ff-run-ediff-file]\t\tEdiff file.
\\[helm-ff-run-ediff-merge-file]\t\tEdiff-merge file.
\\[helm-ff-run-switch-other-window]\t\tSwitch to other window.
\\[helm-ff-properties-persistent]\t\tShow file properties.
\\[helm-ff-run-etags]\t\tRun etags (`\\[universal-argument]' to use tap, `\\[universal-argument] \\[universal-argument]' to reload the database).
\\[helm-ff-run-open-file-externally]\t\tOpen file with external program (`\\[universal-argument]' to choose).
\\[helm-ff-run-open-file-with-default-tool]\t\tOpen file externally with default tool.
\\[helm-ff-run-insert-org-link]\t\tInsert org link.")

;;; Keymap

(defvar helm-recoll-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map helm-generic-files-map)
    map))

;;; Actions

(defun helm-recoll-action-require-helm (_candidate)
  "Invoke helm with selected candidates."
  (require 'helm-files)
  (helm :sources (helm-build-sync-source "Select"
		   :candidates (helm-marked-candidates)
		   :keymap helm-find-files-map
		   :fuzzy-match t
		   :action helm-find-files-actions)))

;;; Main

(defun helm-recoll--setup-cmd (dir)
  (let* ((patterns (split-string helm-pattern))
         (option (helm-aand (member (car patterns) '("-l" "-f" "-a" "-o"))
                            (car it)))
         (pattern-seq (if option (cdr patterns) patterns)))
    (append helm-recoll-options
            (list "-c" dir) (cons (or option "-q") pattern-seq))))

(defun helm-recoll--candidates-process (&optional confdir)
  "Candidates function used by `helm-recoll-source'."
  (setq confdir (or confdir (helm-attr 'confdir)))
  (let ((cmd (helm-recoll--setup-cmd confdir))
        (inhibit-quit t)) ; Avoid quitting unexpectedly within
                          ; with-temp-buffer especially when deleting
                          ; char backward.
    (helm-log "Command line used was:\n\n>>>%s" (mapconcat 'identity cmd " "))
    (with-temp-buffer
      (unless (eq (while-no-input
                    (apply #'call-process "recoll" nil '(t nil) nil (cdr cmd)))
                  t)
        (split-string (buffer-string) "\n" t)))))
;; As of Version: 1.22.4-1:
;; text/x-emacs-lisp	[file:///home/thierry/elisp/Emacs-wgrep/wgrep-helm.el]	[wgrep-helm.el]	3556	bytes	
(defun helm-recoll-filter-one-by-one (file)
  "Strip out all garbage provided by recoll."
  (when (string-match "\\`\\(.*\\)\\(\\s-+\\)\\(\\[file://\\)\\([^]]+\\)\\(\\]\\)" file)
    ;; FIXME: Should I filter out directories from 1th group (inode/directory)?
    (match-string 4 file)))

(defun helm-recoll-filtered-transformer (candidates _source)
  (cl-loop for c in candidates
           for candidate = (helm-recoll-filter-one-by-one c)
           when candidate collect it))

(defclass helm-recoll-override-inheritor (helm-type-file) ())

(defclass helm-recoll-source (helm-source-sync helm-recoll-override-inheritor)
  ((confdir :initarg :confdir
            :initform nil
            :custom 'file)
   (candidates :initform #'helm-recoll--candidates-process)
   (match-dynamic :initform t)
   (requires-pattern :initform 3)
   (history :initform helm-recoll-history)
   (candidate-number-limit :initform 9999)
   (nohighlight :initform t)))

(defmethod helm--setup-source :after ((source helm-recoll-override-inheritor))
  (let ((actions (slot-value source 'action)))
    (setf (slot-value source 'filtered-candidate-transformer)
          '(helm-recoll-filtered-transformer helm-highlight-files))
    (setf (slot-value source 'action-transformer) nil)
    (setf (slot-value source 'help-message) 'helm-recoll-help-message)
    (setf (slot-value source 'keymap) helm-recoll-map)
    (setf (slot-value source 'action)
          (helm-append-at-nth
           (symbol-value actions)
           '(("Run helm with selected candidates" . helm-recoll-action-require-helm))
           1))))

(defun helm-recoll-build-sources (var value)
  (set var value)
  (cl-loop for (n . d) in value
           do (helm-recoll-create-source n d)))

;;;###autoload
(defun helm-recoll-create-source (name confdir)
  "Create helm source and associated functions for recoll search results.
The first argument NAME is a string.  Define a source variable
named `helm-source-recoll-NAME' and a command named
`helm-recoll-NAME'.  CONFDIR is the path to the config directory
which recoll should use."
  (let ((source  (intern (concat "helm-source-recoll-" name))))
    (defalias (intern (concat "helm-recoll-" name))
        (lambda ()
          (interactive)
          (require 'helm-recoll)
          (helm :sources source
                :history 'helm-recoll-history
                :buffer helm-recoll-sources-buffer)))
    (set source
         (helm-make-source (concat "Recoll " name)
             'helm-recoll-source :confdir (expand-file-name confdir)))
    (put source 'variable-documentation (format "\
Source for retrieving files matching the current input pattern
using recoll with the configuration in \"%s\"." confdir))
    source))

(defcustom helm-recoll-directories nil
  "Alist of (name . directory) where to build a recoll source.
A command to call directly this source will be created also.
The source will be called helm-source-recoll-<name> and the command
helm-recoll-<name>."
  :type '(alist :key-type   (string :tag "Source name")
                :value-type (string :tag "Configuration directory"))
  :set 'helm-recoll-build-sources)

(defclass helm-recoll-sources (helm-source-sync)
  ((candidate-number-limit :initform 9999)
   (candidates :initform
               (lambda ()
                 (cl-loop for vname in (all-completions "helm-source-recoll-" obarray)
                          for var = (intern vname)
                          for name = (ignore-errors (assoc-default 'name (symbol-value var)))
                          if name collect (cons (format "%s (%s)" name vname) var))))
   (action :initform `(("Invoke helm with selected sources" .
                        ,(lambda (_candidate)
                           (helm :sources (helm-marked-candidates)
                                 :buffer helm-recoll-sources-buffer
                                 :ff-transformer-show-only-basename nil)))
                       ("Describe variable" . helm-describe-variable)))
   (persistent-action :initform (lambda (candidate)
                                  (helm-elisp--persistent-help
                                   candidate 'helm-describe-variable)))))

(defvar helm-recoll-sources-source
  (helm-make-source "helm-recoll sources" 'helm-recoll-sources)
  "Source for browsing all defined recoll sources.")

;;;###autoload
(defun helm-recoll nil
  "Select recoll sources for helm."
  (interactive)
  (let ((helm-input-idle-delay helm-recoll-input-idle-delay))
    (helm :sources 'helm-recoll-sources-source
          :buffer helm-recoll-sources-buffer)))

(provide 'helm-recoll)

;; Test:
;; (helm-recoll-create-source "main" "~/.recoll")
;; (helm :sources 'helm-source-recoll-main)

;;; helm-recoll.el ends here
