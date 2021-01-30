;;; elfeed-score.el --- Gnus-style scoring for Elfeed  -*- lexical-binding: t; -*-

;; Copyright (C) 2019-2021 Michael Herstine <sp1ff@pobox.com>

;; Author: Michael Herstine <sp1ff@pobox.com>
;; Version: 0.6.5
;; Package-Version: 20210130.159
;; Package-Commit: fe2e9a1b1d745c111fc858224fe23135f7b7ff4e
;; Package-Requires: ((emacs "24.4") (elfeed "3.3.0"))
;; Keywords: news
;; URL: https://github.com/sp1ff/elfeed-score

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

;; `elfeed-score' is an add-on for `elfeed', an RSS reader for
;; Emacs.  It brings Gnus-style scoring to your RSS feeds.  Elfeed, by
;; default, displays feed entries by date.  This package allows you to
;; setup rules for assigning numeric scores to entries, and sorting
;; entries with higher scores ahead of those with lower, regardless of
;; date.  The idea is to prioritize content important to you.

;; After installing this file, enable scoring by invoking
;; `elfeed-score-enable'.  This will setup the Elfeed new entry hook,
;; the Elfeed sort function, and load the score file (if it exists).
;; Turn off scoring by invoking `elfeed-score-unload'.

;;; Code:

(require 'elfeed-search)

(defconst elfeed-score-version "0.6.5")

(defgroup elfeed-score nil
  "Gnus-style scoring for Elfeed entries."
  :group 'comm)

(define-obsolete-variable-alias 'elfeed-score/default-score
  'elfeed-score-default-score "0.2.0" "Move to standard-compliant naming.")

(defcustom elfeed-score-default-score 0
  "Default score for an Elfeed entry."
  :group 'elfeed-score
  :type 'int)

(define-obsolete-variable-alias 'elfeed-score/meta-kw
  'elfeed-score-meta-keyword "0.2.0" "Move to standard-compliant naming.")

(defcustom elfeed-score-meta-keyword :elfeed-score/score
  "Default keyword for storing scores in Elfeed entry metadata."
  :group 'elfeed-score
  :type 'symbol)

(define-obsolete-variable-alias 'elfeed-score/score-file
  'elfeed-score-score-file "0.2.0" "Move to standard-compliant naming.")

(defcustom elfeed-score-score-file
  (concat (expand-file-name user-emacs-directory) "elfeed.score")
  "Location at which to persist scoring rules.

Set this to nil to disable automatic serialization &
deserialization of scoring rules."
  :group 'elfeed-score
  :type 'file)

(defcustom elfeed-score-score-format '("%d " 6 :right)
  "Format for scores when displayed in the Elfeed search buffer.
This is a three-tuple: the `format' format string, target width,
and alignment.  This should be (string integer keyword)
for (format width alignment).  Possible alignments are :left and
:right."
  :group 'elfeed-score
  :type '(list string integer (choice (const :left) (const :right))))

(defcustom elfeed-score-explanation-buffer-name
  "*elfeed-score-explanations*"
  "Name of the buffer to be used for scoring explanations."
  :group 'elfeed-score
  :type 'string)

(defface elfeed-score-date-face
  '((t :inherit font-lock-type-face))
  "Face for showing the date in the elfeed score buffer."
  :group 'elfeed-score)

(defface elfeed-score-error-level-face
  '((t :foreground "red"))
  "Face for showing the `error' log level in the elfeed score buffer."
  :group 'elfeed-score)

(defface elfeed-score-warn-level-face
  '((t :foreground "goldenrod"))
  "Face for showing the `warn' log level in the elfeed score buffer."
  :group 'elfeed-score)

(defface elfeed-score-info-level-face
  '((t :foreground "deep sky blue"))
  "Face for showing the `info' log level in the elfeed score buffer."
  :group 'elfeed-score)

(defface elfeed-score-debug-level-face
  '((t :foreground "magenta2"))
  "Face for showing the `debug' log level in the elfeed score buffer."
  :group 'elfeed-score)

(define-obsolete-variable-alias 'elfeed-score/debug
  'elfeed-score-debug "0.2.0" "Move to standard-compliant naming.")

(defvar elfeed-score-debug nil
  "Control debug output.

Setting this to a non-nil value will produce copious debugging
information to the \"*Messages*\" buffer.")

(make-obsolete-variable 'elfeed-score-debug 'elfeed-score-log-level "0.4")

(defvar elfeed-score-log-buffer-name "*elfeed-score*"
  "Name of buffer used for logging `elfeed-score' events.")

(defvar elfeed-score-log-level (if elfeed-score-debug 'info 'warn)
  "Level at which `elfeed-score' shall log; may be one of 'debug, 'info, 'warn, or 'error.")

(defvar elfeed-score-max-log-buffer-size 750
  "Maximum length (in lines) of the log buffer.  nil means unlimited.")

(defun elfeed-score--log-level-number (level)
  "Return a numeric value for log level LEVEL."
  (cl-case level
    (debug -10)
    (info 0)
    (warn 10)
    (error 20)
    (otherwise 0)))

(defun elfeed-score-log-buffer ()
  "Return the `elfeed-score' log buffer, creating it if needed."
  (let ((buffer (get-buffer elfeed-score-log-buffer-name)))
    (if buffer
        buffer
      (with-current-buffer (generate-new-buffer elfeed-score-log-buffer-name)
        (special-mode)
        (current-buffer)))))

(defun elfeed-score--truncate-log-buffer ()
  "Truncate the log buffer to `elfeed-score-max-log-buffer-size lines."
  (with-current-buffer (elfeed-score-log-buffer)
    (goto-char (point-max))
    (forward-line (- elfeed-score-max-log-buffer-size))
    (beginning-of-line)
    (let ((inhibit-read-only t))
      (delete-region (point-min) (point)))))

(defun elfeed-score-log (level fmt &rest objects)
  "Write a log message FMT at level LEVEL to the `elfeed-score' log buffer."
  (when (>= (elfeed-score--log-level-number level)
            (elfeed-score--log-level-number elfeed-score-log-level))
    (let ((inhibit-read-only t)
          (log-level-face
           (cl-case level
             (debug 'elfeed-score-debug-level-face)
             (info 'elfeed-score-info-level-face)
             (warn 'elfeed-score-warn-level-face)
             (error 'elfeed-score-error-level-face)
             (otherwise 'elfeed-score-debug-level-face))))
      (with-current-buffer (elfeed-score-log-buffer)
        (goto-char (point-max))
        (insert
         (format
          (concat "[" (propertize "%s" 'face 'elfeed-score-date-face) "] "
                  "[" (propertize "%s" 'face log-level-face) "]: "
                  "%s\n")
          (format-time-string "%Y-%m-%d %H:%M:%S")
          level
          (apply #'format fmt objects)))
        (if (and elfeed-score-max-log-buffer-size
                 (> (line-number-at-pos)
                    elfeed-score-max-log-buffer-size))
            (elfeed-score--truncate-log-buffer))))))

(defun elfeed-score--debug (fmt &rest params)
  "Produce a formatted (FMT) message based on PARAMS at debug level.

Print a formatted message if `elfeed-score-debug' is non-nil."
  (elfeed-score-log 'debug fmt params))

(make-obsolete 'elfeed-score--debug 'elfeed-score-log "0.4")

(defun elfeed-score--set-score-on-entry (entry score)
  "Set the score on ENTRY to SCORE."
  (setf (elfeed-meta entry elfeed-score-meta-keyword) score))

(defun elfeed-score--get-score-from-entry (entry)
  "Retrieve the score from ENTRY."
  (elfeed-meta entry elfeed-score-meta-keyword elfeed-score-default-score))

(define-obsolete-function-alias 'elfeed-score/sort
  'elfeed-score-sort "0.2.0" "Move to standard-compliant naming.")

(defun elfeed-score-sort (a b)
  "Return non-nil if A should sort before B.

`elfeed-score' will substitute this for the Elfeed scoring function."

  (let ((a-score (elfeed-score--get-score-from-entry a))
        (b-score (elfeed-score--get-score-from-entry b)))
    (if (> a-score b-score)
        t
      (let ((a-date (elfeed-entry-date a))
            (b-date (elfeed-entry-date b)))
        (and (eq a-score b-score) (> a-date b-date))))))

(define-obsolete-function-alias 'elfeed-score/set-score
  'elfeed-score-set-score "0.2.0" "Move to standard-compliant naming.")

(defun elfeed-score-set-score (&optional score ignore-region)
  "Set the score of one or more Elfeed entries to SCORE.

Their scores will be set to `elfeed-score-default-score' by
default.

If IGNORE-REGION is nil (as it will be when called
interactively), then all entries in the current region will have
their scores re-set.  If the region is not active, then only the
entry under point will be affected.  If IGNORE-REGION is t, then
only the entry under point will be affected, regardless of the
region's state."

  (interactive "P")

  (let ((score
         (if score
             (prefix-numeric-value score)
           elfeed-score-default-score))
        (entries (elfeed-search-selected ignore-region)))
    (dolist (entry entries)
      (elfeed-score-log 'info "entry %s ('%s') was directly set to %d"
                        (elfeed-entry-id entry ) (elfeed-entry-title entry) score)
      (elfeed-score--set-score-on-entry entry score))))

(define-obsolete-function-alias 'elfeed-score/get-score
  'elfeed-score-get-score "0.2.0" "Move to standard-compliant naming.")

(defun elfeed-score-get-score ()
  "Return the score of the entry under point.

If called interactively, print a message."

  (interactive)

  (let* ((entry (elfeed-search-selected t))
         (score (elfeed-score--get-score-from-entry entry)))
    (if (called-interactively-p 'any)
        (message "%s has a score of %d." (elfeed-entry-title entry) score))
    score))

(defun elfeed-score-format-score (score)
  "Format SCORE for printing in `elfeed-search-mode'.

The customization `elfeed-score-score-format' sets the
formatting.  This implementation is based on that of
`elfeed-search-format-date'."
  (cl-destructuring-bind (format target alignment) elfeed-score-score-format
    (let* ((string (format format score))
           (width (string-width string)))
      (cond
       ((> width target)
        (if (eq alignment :left)
            (substring string 0 target)
          (substring string (- width target) width)))
       ((< width target)
        (let ((pad (make-string (- target width) ?\s)))
          (if (eq alignment :left)
              (concat string pad)
            (concat pad string))))
       (string)))))

(cl-defstruct (elfeed-score-title-rule
               ;; Disable the default ctor (the name violates Emacs
               ;; package naming conventions)
               (:constructor nil)
               ;; Abuse the &aux keyword to validate our parameters; I
               ;; can only specify type in the slot description if I
               ;; specify a default value for the slot, which doesn't
               ;; always make sense.
               (:constructor
                elfeed-score-title-rule--create
                (&key text value type date tags (hits 0) feeds
                      &aux
                      (_
                       (unless (and (stringp text) (> (length text) 0))
                         (error "Title rule text must be a non-empty string"))
                       (unless (numberp value)
                         (error "Title rule value must be a number"))
                       (unless (and (symbolp type)
                                    (or (eq type 's)
                                        (eq type 'S)
                                        (eq type 'r)
                                        (eq type 'R)
                                        (eq type 'w)
                                        (eq type 'W)))
                         (error "Title type must be one of '{s,S,r,R,wW}"))))))
  "Rule for scoring against entry titles.

    - text :: The rule's match text; either a string or a regular
              expression (on which more below)

    - value :: Integral value (positive or negative) to be added
               to an entry's score if this rule matches

    - type :: One of the symbols s S r R w W; s/r/w denotes
              substring/regexp/whole word match; lower-case means
              case-insensitive and upper case sensitive.
              Defaults to r (case-insensitive regexp match)

    - date :: time (in seconds since epoch) when this rule last
              matched

    - tags :: cons cell of the form (A . B) where A is either t
              or nil and B is a list of symbols. The latter is
              interpreted as a list of tags scoping the rule and
              the former as a boolean switch possibly negating the
              scoping. E.g. (t . (a b)) means \"apply this rule
              if either of tags a & b are present\". Making the
              first element nil means \"do not apply this rule if
              any of a and b are present\".

    - hits :: the number of times since upgrading to score file
              version 5 that this rule has been matched

    - feeds :: cons cell of the form (A . B) where A is either t
               or nil and B is a list of three-tuples. Each
               three-tuple will be matched against an entry's
               feed:

                 1. attribute: one of 't, 'u, or 'a for title,
                 URL, or author, resp.
                 2. match type: one of 's, 'S, 'r, 'R, 'w, or
                 'W (the usual match types)
                 3. match text

               So, e.g. '(t s \"foo\") means do a
               case-insensitive substring match for \"foo\"
               against the feed title.

               The first element of the cons cell is interpreted as a boolean
               switch possibly negating the scoping. For
               instance, (t . '((t s \"foo\") (u s
               \"https://bar.com/feed\"))) means \"apply this rule
               only to feeds entitled foo or from
               https://bar/com/feed\" Making the first element nil
               means \"do not apply this rule if the feed is
               either foo or bar\"."
  text value type date tags (hits 0) feeds)

(cl-defstruct (elfeed-score-title-explanation
               (:constructor nil)
               (:constructor elfeed-score-make-title-explanation))
  "An explanation of a title rule match."
  matched-text rule)

(defun elfeed-score-pp-title-explanation (match)
  "Pretty-print MATCH to string."
  (let ((rule (elfeed-score-title-explanation-rule match)))
    (format "title{%s}: \"%s\": %d"
            (elfeed-score-title-rule-text rule)
            (elfeed-score-title-explanation-matched-text match)
            (elfeed-score-title-rule-value rule))))

(defun elfeed-score-title-explanation-contrib (match)
  "Return the score contribution due to MATCH."
  (elfeed-score-title-rule-value
   (elfeed-score-title-explanation-rule match)))

(cl-defstruct (elfeed-score-feed-rule
               ;; Disable the default ctor (the name violates Emacs
               ;; package naming conventions)
               (:constructor nil)
               ;; Abuse the &aux keyword to validate our parameters; I
               ;; can only specify type in the slot description if I
               ;; specify a default value for the slot, which doesn't
               ;; always make sense.
               (:constructor
                elfeed-score-feed-rule--create
                (&key text value type attr date tags (hits 0)
                      &aux
                      (_
                       (unless (and (stringp text) (> (length text) 0))
                         (error "Feed rule text must be a non-empty string"))
                       (unless (numberp value)
                         (error "Feed rule value must be a number"))
                       (unless (and (symbolp type)
                                    (or (eq type 's)
                                        (eq type 'S)
                                        (eq type 'r)
                                        (eq type 'R)
                                        (eq type 'w)
                                        (eq type 'W)))
                         (error "Feed type must be one of '{s,S,r,R,wW}"))
                       (unless (and (symbolp attr)
                                    (or (eq type 't)
                                        (eq type 'u)))
                         (error "Feed attribute must be one of '{t,u}"))))))
  "Rule for scoring against entry feeds.

    - text :: The rule's match text; either a string or a regular
              expression (on which more below)

    - value :: Integral value (positive or negative) to be added to
               an entry's score if this rule matches

    - type :: One of the symbols s S r R w W; s/r/w denotes
              substring/regexp/whole word match; lower-case means
              case-insensitive and upper case sensitive.
              Defaults to r (case-insensitive regexp match)

    - attr :: Defines the feed attribute against which matching
              shall be performed: 't for title & 'u for URL.

    - date :: time (in seconds since epoch) when this rule last
              matched

    - tags :: cons cell of the form (a . b) where A is either t
              or nil and B is a list of symbols. The latter is
              interpreted as a list of tags scoping the rule and
              the former as a boolean switch possibly negating the
              scoping. E.g. (t . (a b)) means \"apply this rule
              if either of tags a & b are present\". Making the
              first element nil means \"do not apply this rule if
              any of a and b are present\".

    - hits :: the number of times since upgrading to score file
              version 5 that this rule has been matched"
  text value type attr date tags (hits 0))

(cl-defstruct (elfeed-score-feed-explanation
               (:constructor nil)
               (:constructor elfeed-score-make-feed-explanation))
  "An explanation of a feed rule match"
  matched-text rule)

(defun elfeed-score-pp-feed-explanation (match)
  "Pretty-print MATCH to string."
  (let ((rule (elfeed-score-feed-explanation-rule match)))
    (format "feed{%s/%s}: \"%s\": %d"
            (elfeed-score-feed-rule-attr rule)
            (elfeed-score-feed-rule-text rule)
            (elfeed-score-feed-explanation-matched-text match)
            (elfeed-score-feed-rule-value rule))))

(defun elfeed-score-feed-explanation-contrib (match)
  "Return the score contribution due to MATCH."
  (elfeed-score-feed-rule-value
   (elfeed-score-feed-explanation-rule match)))

(cl-defstruct (elfeed-score-content-rule
               ;; Disable the default ctor (the name violates Emacs
               ;; package naming conventions)
               (:constructor nil)
               ;; Abuse the &aux keyword to validate our parameters; I
               ;; can only specify type in the slot description if I
               ;; specify a default value for the slot, which doesn't
               ;; always make sense.
               (:constructor
                elfeed-score-content-rule--create
                (&key text value type date tags (hits 0) feeds
                      &aux
                      (_
                       (unless (and (stringp text) (> (length text) 0))
                         (error "Content rule text must be a non-empty string"))
                       (unless (numberp value)
                         (error "Content rule value must be a number"))
                       (unless (and (symbolp type)
                                    (or (eq type 's)
                                        (eq type 'S)
                                        (eq type 'r)
                                        (eq type 'R)
                                        (eq type 'w)
                                        (eq type 'W)))
                         (error "Content type must be one of '{s,S,r,R,wW}"))))))
  "Rule for scoring against entry content

    - text :: The rule's match text; either a string or a regular
              expression (on which more below)

    - value :: Integral value (positive or negative) to be added to
               an entry's score if this rule matches

    - type :: One of the symbols s S r R w W; s/r/w denotes
              substring/regexp/whole word match; lower-case
              means case-insensitive and upper case sensitive.
              Defaults to r (case-insensitive regexp match)

    - date :: time (in seconds since epoch) when this rule last
              matched

    - tags :: cons cell of the form (a . b) where A is either t
              or nil and B is a list of symbols. The latter is
              interpreted as a list of tags scoping the rule and
              the former as a boolean switch possibly negating the
              scoping. E.g. (t . (a b)) means \"apply this rule
              if either of tags a & b are present\". Making the
              first element nil means \"do not apply this rule if
              any of a and b are present\".

    - hits :: the number of times since upgrading to score file
              version 5 that this rule has been matched

    - feeds :: cons cell of the form (A . B) where A is either t
               or nil and B is a list of three-tuples. Each
               three-tuple will be matched against an entry's
               feed:

                 1. attribute: one of 't, 'u, or 'a for title,
                 URL, or author, resp.
                 2. match type: one of 's, 'S, 'r, 'R, 'w, or
                 'W (the usual match types)
                 3. match text

               So, e.g. '(t s \"foo\") means do a
               case-insensitive substring match for \"foo\"
               against the feed title.

               The first element of the cons cell is interpreted as a boolean
               switch possibly negating the scoping. For
               instance, (t . '((t s \"foo\") (u s
               \"https://bar.com/feed\"))) means \"apply this rule
               only to feeds entitled foo or from
               https://bar/com/feed\" Making the first element nil
               means \"do not apply this rule if the feed is
               either foo or bar\"."
  text value type date tags (hits 0) feeds)

(cl-defstruct (elfeed-score-content-explanation
               (:constructor nil)
               (:constructor elfeed-score-make-content-explanation))
  "An explanation of a matched content rule."
  matched-text rule)

(defun elfeed-score-content-explanation-contrib (match)
  "Return the score contribution due to MATCH."
  (elfeed-score-content-rule-value
   (elfeed-score-content-explanation-rule match)))

(defun elfeed-score-pp-content-explanation (match)
  "Pretty-print MATCH to string."
  (let ((rule (elfeed-score-content-explanation-rule match)))
    (format "content{%s}: \"%s\": %d"
            (elfeed-score-content-rule-text rule)
            (elfeed-score-content-explanation-matched-text match)
            (elfeed-score-content-rule-value rule))))

(cl-defstruct (elfeed-score-title-or-content-rule
               ;; Disable the default ctor (the name violates Emacs
               ;; package naming conventions)
               (:constructor nil)
               ;; Abuse the &aux keyword to validate our parameters; I
               ;; can only specify type in the slot description if I
               ;; specify a default value for the slot, which doesn't
               ;; always make sense.
               (:constructor
                elfeed-score-title-or-content-rule--create
                (&key text title-value content-value type date tags
                      (hits 0) feeds
                      &aux
                      (_
                       (unless (and (stringp text) (> (length text) 0))
                         (error "Title-or-content rule text must be a \
non-empty string"))
                       (unless (numberp title-value)
                         (error "Title-or-content rule title value must \
be a number"))
                       (unless (numberp content-value)
                         (error "Title-or-content rule content value must \
be a number"))
                       (unless (and (symbolp type)
                                    (or (eq type 's)
                                        (eq type 'S)
                                        (eq type 'r)
                                        (eq type 'R)
                                        (eq type 'w)
                                        (eq type 'W)))
                         (error "Title-or-content type must be one of \
'{s,S,r,R,wW}"))))))
  "Rule for scoring the same text against both entry title & content.

I found myself replicating the same rule for both title &
content, with a higher score for title.  This rule permits
defining a single rule for both.

    - text :: The rule's match text; either a string or a regular
              expression (on which more below)

    - title-value :: Integral value (positive or negative) to be
                     added to an entry's score should this rule
                     match the entry's title

    - content-value :: Integral value (positive or negative) to
                       be added to an entry's score should this
                       rule match the entry's value

    - type :: One of the symbols s S r R w W; s/r/w denotes
              substring/regexp/whole word match; lower-case means
              case-insensitive and upper case sensitive.
              Defaults to r (case-insensitive regexp match)

    - date :: time (in seconds since epoch) when this rule last matched

    - tags :: cons cell of the form (a . b) where A is either t
              or nil and B is a list of symbols. The latter is
              interpreted as a list of tags scoping the rule and
              the former as a boolean switch possibly negating the
              scoping. E.g. (t . (a b)) means \"apply this rule
              if either of tags a & b are present\". Making the
              first nil element means \"do not apply this rule if
              any of a and b are present\".

    - hits :: the number of times since upgrading to score file version
              5 that this rule has been matched

    - feeds :: cons cell of the form (A . B) where A is either t
               or nil and B is a list of three-tuples. Each
               three-tuple will be matched against an entry's
               feed:

                 1. attribute: one of 't, 'u, or 'a for title,
                 URL, or author, resp.
                 2. match type: one of 's, 'S, 'r, 'R, 'w, or
                 'W (the usual match types)
                 3. match text

               So, e.g. '(t s \"foo\") means do a
               case-insensitive substring match for \"foo\"
               against the feed title.

               The first element of the cons cell is interpreted as a boolean
               switch possibly negating the scoping. For
               instance, (t . '((t s \"foo\") (u s
               \"https://bar.com/feed\"))) means \"apply this rule
               only to feeds entitled foo or from
               https://bar/com/feed\" Making the first element nil
               means \"do not apply this rule if the feed is
               either foo or bar\"."
  text title-value content-value type date tags (hits 0) feeds)

(cl-defstruct (elfeed-score-title-or-content-explanation
               (:constructor nil)
               (:constructor elfeed-score-make-title-or-content-explanation))
  "An explanation of a title-or-content rule match."
  matched-text rule attr)

(defun elfeed-score-pp-title-or-content-explanation (match)
  "Pretty-print MATCH to string."
  (let ((rule (elfeed-score-title-or-content-explanation-rule match))
        (attr (elfeed-score-title-or-content-explanation-attr match)))
    (format "title-or-content{%s/%s}: \"%s\": %d"
            attr
            (elfeed-score-title-or-content-rule-text rule)
            (elfeed-score-title-or-content-explanation-matched-text match)
            (if (eq 't attr)
                (elfeed-score-title-or-content-rule-title-value rule)
              (elfeed-score-title-or-content-rule-content-value rule)))))

(defun elfeed-score-title-or-content-explanation-contrib (match)
  "Return the score contribution due to MATCH."
  (let ((rule (elfeed-score-title-or-content-explanation-rule match)))
    (if (eq 't (elfeed-score-title-or-content-explanation-attr match))
        (elfeed-score-title-or-content-rule-title-value rule)
      (elfeed-score-title-or-content-rule-content-value rule))))

(cl-defstruct (elfeed-score-authors-rule
               ;; Disable the default ctor (the name violates Emacs
               ;; package naming conventions)
               (:constructor nil)
               ;; Abuse the &aux keyword to validate our parameters; I
               ;; can only specify type in the slot description if I
               ;; specify a default value for the slot, which doesn't
               ;; always make sense.
               (:constructor
                elfeed-score-authors-rule--create
                (&key text value type date tags (hits 0) feeds
                      &aux
                      (_
                       (unless (and (stringp text) (> (length text) 0))
                         (error "Authors rule text must be a non-empty string"))
                       (unless (numberp value)
                         (error "Authors rule value must be a number"))
                       (unless (and (symbolp type)
                                    (or (eq type 's)
                                        (eq type 'S)
                                        (eq type 'r)
                                        (eq type 'R)
                                        (eq type 'w)
                                        (eq type 'W)))
                         (error "Authors rulle type must be one of \
'{s,S,r,R,w,W}"))))))
  "Rule for scoring against the names of all the authors

    - text :: The rule's match text; either a string or a regular
              expression (on which more below)

    - value :: Integral value (positive or negative) to be added
               to an entry's score should this rule match one of
               the authors

    - type :: One of the symbols s S r R w W; s/r/w denotes
              substring/regexp/whole word match; lower-case means
              case-insensitive and upper case sensitive.
              Defaults to r (case-insensitive regexp match)

    - date :: time (in seconds since epoch) when this rule last
              matched

    - tags :: cons cell of the form (a . b) where A is either t
              or nil and B is a list of symbols. The latter is
              interpreted as a list of tags scoping the rule and
              the former as a boolean switch possibly negating the
              scoping. E.g. (t . (a b)) means \"apply this rule
              if either of tags a & b are present\". Making the
              first nil element means \"do not apply this rule if
              any of a and b are present\".

    - hits :: the number of times since upgrading to score file
              version 5 that this rule has been matched

    - feeds :: cons cell of the form (A . B) where A is either t
               or nil and B is a list of three-tuples. Each
               three-tuple will be matched against an entry's
               feed:

                 1. attribute: one of 't, 'u, or 'a for title,
                 URL, or author, resp.
                 2. match type: one of 's, 'S, 'r, 'R, 'w, or
                 'W (the usual match types)
                 3. match text

               So, e.g. '(t s \"foo\") means do a
               case-insensitive substring match for \"foo\"
               against the feed title.

               The first element of the cons cell is interpreted as a boolean
               switch possibly negating the scoping. For
               instance, (t . '((t s \"foo\") (u s
               \"https://bar.com/feed\"))) means \"apply this rule
               only to feeds entitled foo or from
               https://bar/com/feed\" Making the first element nil
               means \"do not apply this rule if the feed is
               either foo or bar\"."
  text value type date tags (hits 0) feeds)

(cl-defstruct (elfeed-score-authors-explanation
               (:constructor nil)
               (:constructor elfeed-score-make-authors-explanation))
  "An explanation of an authors rule match"
  matched-text rule)

(defun elfeed-score-pp-authors-explanation (match)
  "Pretty-print MATCH to string."
  (let ((rule (elfeed-score-authors-explanation-rule match)))
    (format "authors{%s} \"%s\": %d"
            (elfeed-score-authors-rule-text rule)
            (elfeed-score-authors-explanation-matched-text match)
            (elfeed-score-authors-rule-value rule))))

(defun elfeed-score-authors-explanation-contrib (match)
  "Return the score contribution due to MATCH."
  (elfeed-score-authors-rule-value
   (elfeed-score-authors-explanation-rule match)))

(cl-defstruct (elfeed-score-tag-rule
               ;; Disable the default ctor (the name violates Emacs
               ;; package naming conventions)
               (:constructor nil)
               ;; Abuse the &aux keyword to validate our parameters; I
               ;; can only specify type in the slot description if I
               ;; specify a default value for the slot, which doesn't
               ;; always make sense.
               (:constructor
                elfeed-score-tag-rule--create
                (&key tags value date (hits 0)
                      &aux
                      (_
                       (unless (and (listp tags))
                         (error "Tags rules must begin with a cons cell"))
                       (unless (numberp value)
                         (error "Tags rule value must be a number"))))))
  "Rule for scoring based on the presence or absence of a tag or tags.

    - tags :: cons cell of the form (A . B) where A is either t
              or nil and B is a symbol or list of symbols. The
              latter is interpreted as a list of tags selecting
              the entries to which this rule shall apply & the
              former as a boolean switch possibly negating this
              selection.  E.g. (t . (a b)) means \"apply this if
              either of the tags a & b are present\". Making the
              first element nil means \" do not apply this rule
              if any of a and b are present\".

    - value :: integral value (positive or negative) by which to
               adjust the entry score if this rule matches

    - date :: time (in seconds since epoch) when this rule last
              matched

    - hits :: the number of times since upgrading to score file
              version 5 that this rule has been matched"
  tags value date (hits 0))

(cl-defstruct (elfeed-score-tags-explanation
               (:constructor nil)
               (:constructor elfeed-score-make-tags-explanation))
  "An explanation of a tags rule match."
  rule)

(defun elfeed-score-pp-tags-explanation (match)
  "Pretty-print MATCH to string."
  (let ((rule (elfeed-score-tags-explanation-rule match)))
    (format "tags{%s}: %d"
            (elfeed-score-tag-rule-tags rule)
            (elfeed-score-tag-rule-value rule))))

(defun elfeed-score-tags-explanation-contrib (match)
  "Return the score contribution due to MATCH."
  (elfeed-score-tag-rule-value
   (elfeed-score-tags-explanation-rule match)))

(cl-defstruct (elfeed-score-adjust-tags-rule
               ;; Disable the default ctor (the name violates Emacs
               ;; package naming conventions)
               (:constructor nil)
               ;; Abuse the &aux keyword to validate our parameters; I
               ;; can only specify type in the slot description if I
               ;; specify a default value for the slot, which doesn't
               ;; always make sense.
               (:constructor
                elfeed-score-adjust-tags-rule--create
                (&key threshold tags date (hits 0)
                      &aux
                      (_
                       (unless (listp threshold)
                         (error "Adjust tags rules must begin with a cons cell"))
                       (unless (listp tags)
                         (error "Adjust tags rules must specify tags with \
a cons cell"))))))
  "Rule for adjusting tags based on score.

    - threshold :: a cons cell of the form (A . B) where A is a
                   boolean and B is an integral value. If A is t,
                   then this rule will apply to all entries whose
                   score is greater than or equal to B. If A is
                   nil, this rule will apply to all entries whose
                   score is less than or equal to B.

    - tags :: a cons cell of the form (A . B) where A is a
              boolean and B is a symbol or list of symbols. If A
              is t, and this rule matches, the tags in B will be
              added to the entry. If A is nil & this rule
              matches, the list of tags in B shall be removed
              from the entry.

    - date :: time (in seconds since epoch) when this rule last
              matched

    - hits :: the number of times since upgrading to score file
              version 5 that this rule has been matched"
  threshold tags date (hits 0))

(defun elfeed-score--parse-title-rule-sexps (sexps)
  "Parse a list of lists SEXPS into a list of title rules.

Each sub-list shall have the form (TEXT VALUE TYPE DATE TAGS HITS
FEEDS).  NB Over the course of successive score file versions,
new fields have been added at the end so as to maintain backward
compatibility (i.e. this function can be used to read all
versions of the title rule serialization format.)"
  (let (title-rules)
    (dolist (item sexps)
      (let ((struct (elfeed-score-title-rule--create
                     :text  (nth 0 item)
                     :value (nth 1 item)
                     :type  (nth 2 item)
                     :date  (nth 3 item)
                     :tags  (nth 4 item)
                     :hits  (let ((hits (nth 5 item))) (or hits 0))
                     :feeds (nth 6 item))))
        (unless (member struct title-rules)
          (setq title-rules (append title-rules (list struct))))))
    title-rules))

(defun elfeed-score--parse-feed-rule-sexps (sexps)
  "Parse a list of lists SEXPS into a list of feed rules.

Each sub-list shall have the form (TEXT VALUE TYPE ATTR DATE TAGS
HITS).  NB Over the course of successive score file versions, new
fields have been added at the end so as to maintain backward
compatibility (i.e. this function can be used to read all
versions of the feed rule serialization format.)"
  (let (feed-rules)
    (dolist (item sexps)
      (let ((struct (elfeed-score-feed-rule--create
                     :text  (nth 0 item)
                     :value (nth 1 item)
                     :type  (nth 2 item)
                     :attr  (nth 3 item)
                     :date  (nth 4 item)
                     :tags  (nth 5 item)
                     :hits  (let ((hits (nth 6 item))) (or hits 0)))))
        (unless (member struct feed-rules)
          (setq feed-rules (append feed-rules (list struct))))))
    feed-rules))

(defun elfeed-score--parse-content-rule-sexps (sexps)
  "Parse a list of lists SEXPS into a list of content rules.

Each sub-list shall have the form (TEXT VALUE TYPE DATE TAGS HITS
FEEDS).  NB Over the course of successive score file versions,
new fields have been added at the end so as to maintain backward
compatibility (i.e. this function can be used to read all
versions of the content rule serialization format.)"
  (let (content-rules)
    (dolist (item sexps)
      (let ((struct (elfeed-score-content-rule--create
                     :text  (nth 0 item)
                     :value (nth 1 item)
                     :type  (nth 2 item)
                     :date  (nth 3 item)
                     :tags  (nth 4 item)
                     :hits  (let ((hits (nth 5 item))) (or hits 0))
                     :feeds (nth 6 item))))
        (unless (member struct content-rules)
          (setq content-rules (append content-rules (list struct))))))
    content-rules))

(defun elfeed-score--parse-title-or-content-rule-sexps (sexps)
  "Parse a list of lists SEXPS into a list of title-or-content rules.

Each sub-list shall have the form '(TEXT TITLE-VALUE
CONTENT-VALUE TYPE DATE TAGS HITS FEEDS).  NB Over the course of
successive score file versions, new fields have been added at the
end so as to maintain backward compatibility (i.e. this function
can be used to read all versions of the title-or-content rule
serialization format.)"
  (let (toc-rules)
    (dolist (item sexps)
      (let ((struct (elfeed-score-title-or-content-rule--create
                     :text          (nth 0 item)
                     :title-value   (nth 1 item)
                     :content-value (nth 2 item)
                     :type          (nth 3 item)
                     :date          (nth 4 item)
                     :tags          (nth 5 item)
                     :hits          (let ((hits (nth 6 item))) (or hits 0))
                     :feeds         (nth 7 item))))
        (unless (member struct toc-rules)
          (setq toc-rules (append toc-rules (list struct))))))
    toc-rules))

(defun elfeed-score--parse-authors-rule-sexps (sexps)
  "Parse a list of lists SEXPS into a list of authors rules.

Each sub-list shall have the form '(TEXT VALUE TYPE DATE TAGS
HITS FEEDS).  NB Over the course of successive score file
versions, new fields have been added at the end so as to maintain
backward compatibility (i.e. this function can be used to read
all versions of the authors rule serialization format.)"
  (let (authors-rules)
    (dolist (item sexps)
      (let ((struct (elfeed-score-authors-rule--create
                     :text  (nth 0 item)
                     :value (nth 1 item)
                     :type  (nth 2 item)
                     :date  (nth 3 item)
                     :tags  (nth 4 item)
                     :hits  (let ((hits (nth 5 item))) (or hits 0))
                     :feeds (nth 6 item))))
        (unless (member struct authors-rules)
          (setq authors-rules (append authors-rules (list struct))))))
    authors-rules))

(defun elfeed-score--parse-scoring-sexp-1 (sexp)
  "Interpret the S-expression SEXP as scoring rules version 1.

Parse version 1 of the scoring S-expression.  This function will
fail if SEXP has a \"version\" key with a value other than 1 (the
caller may want to remove it via `assoc-delete-all' or some
such).  Return a property list with the following keys:

    - :title : list of elfeed-score-title-rule structs
    - :content : list of elfeed-score-content-rule structs
    - :feed : list of elfeed-score-feed-rule structs
    - :mark : score below which entries shall be marked read"

  (let (mark titles feeds content)
    (dolist (raw-item sexp)
      (let ((key  (car raw-item))
	          (rest (cdr raw-item)))
	      (cond
         ((string= key "version")
          (unless (eq 1 (car rest))
            (error "Unsupported score file version %s" (car rest))))
	       ((string= key "title")
          (setq titles (elfeed-score--parse-title-rule-sexps rest)))
         ((string= key "content")
          (setq content (elfeed-score--parse-content-rule-sexps rest)))
         ((string= key "feed")
          (setq feeds (elfeed-score--parse-feed-rule-sexps rest)))
	       ((eq key 'mark)
          ;; set `mark' to (cdr rest) if (not mark) or (< mark (cdr rest))
          (let ((rest (car rest)))
            (if (or (not mark)
                    (< mark rest))
                (setq mark rest))))
	       (t
	        (error "Unknown score file key %s" key)))))
    (list
     :mark mark
	   :feeds feeds
	   :titles titles
     :content content)))

(defun elfeed-score--parse-scoring-sexp-2 (sexp)
  "Interpret the S-expression SEXP as scoring rules version 2.

Parse version 2 of the scoring S-expression.  Return a property list
with the following keys:

    - :title : list of elfeed-score-title-rule structs
    - :content : list of elfeed-score-content-rule structs
    - :title-or-content: list of elfeed-score-title-or-content-rule
                         structs
    - :feed : list of elfeed-score-feed-rule structs
    - :mark : score below which entries shall be marked read"

  (let (mark titles feeds content tocs)
    (dolist (raw-item sexp)
      (let ((key  (car raw-item))
	          (rest (cdr raw-item)))
	      (cond
         ((string= key "version")
          (unless (eq 2 (car rest))
            (error "Unsupported score file version %s" (car rest))))
	       ((string= key "title")
          (setq titles (elfeed-score--parse-title-rule-sexps rest)))
         ((string= key "content")
          (setq content (elfeed-score--parse-content-rule-sexps rest)))
         ((string= key "feed")
          (setq feeds (elfeed-score--parse-feed-rule-sexps rest)))
         ((string= key "title-or-content")
          (setq tocs (elfeed-score--parse-title-or-content-rule-sexps rest)))
	       ((eq key 'mark)
          ;; set `mark' to (cdr rest) if (not mark) or (< mark (cdr rest))
          (let ((rest (car rest)))
            (if (or (not mark)
                    (< mark rest))
                (setq mark rest))))
	       (t
	        (error "Unknown score file key %s" key)))))
    (list
     :mark mark
	   :feeds feeds
	   :titles titles
     :content content
     :title-or-content tocs)))

(defun elfeed-score--parse-tag-rule-sexps (sexps)
  "Parse a list of lists SEXPS into a list of tag rules."
  (let ((tag-rules))
    (dolist (item sexps)
      (let ((struct (elfeed-score-tag-rule--create
                     :tags  (nth 0 item)
                     :value (nth 1 item)
                     :date  (nth 2 item))))
        (unless (member struct tag-rules)
          (setq tag-rules (append tag-rules (list struct))))))
    tag-rules))

(defun elfeed-score--parse-adjust-tags-rule-sexps (sexps)
  "Parse a list of lists SEXPS into a list of adjust-tags rules."
  (let ((adj-tag-rules))
    (dolist (item sexps)
      (let ((struct (elfeed-score-adjust-tags-rule--create
                     :threshold (nth 0 item)
                     :tags      (nth 1 item)
                     :date      (nth 2 item))))
        (unless (member struct adj-tag-rules)
          (setq adj-tag-rules (append adj-tag-rules (list struct))))))
    adj-tag-rules))

(defun elfeed-score--parse-scoring-sexp-3 (sexp)
  "Interpret the S-expression SEXP as scoring rules version 3.

Parse version 3 of the scoring S-expression.  Return a property list
with the following keys:

    - :title : list of elfeed-score-title-rule structs
    - :content : list of elfeed-score-content-rule structs
    - :title-or-content: list of elfeed-score-title-or-content-rule
                         structs
    - :feed : list of elfeed-score-feed-rule structs
    - :tag : list of elfeed-score-tag-rule structs
    - :mark : score below which entries shall be marked read
    - :adjust-tags : list of elfeed-score-adjust-tags-rule structs"

  (let (mark titles feeds content tocs tags adj-tags)
    (dolist (raw-item sexp)
      (let ((key  (car raw-item))
	          (rest (cdr raw-item)))
	      (cond
         ((string= key "version")
          (unless (eq 3 (car rest))
            (error "Unsupported score file version %s" (car rest))))
	       ((string= key "title")
          (setq titles (elfeed-score--parse-title-rule-sexps rest)))
         ((string= key "content")
          (setq content (elfeed-score--parse-content-rule-sexps rest)))
         ((string= key "feed")
          (setq feeds (elfeed-score--parse-feed-rule-sexps rest)))
         ((string= key "title-or-content")
          (setq tocs (elfeed-score--parse-title-or-content-rule-sexps rest)))
         ((string= key "tag")
          (setq tags (elfeed-score--parse-tag-rule-sexps rest)))
         ((string= key "adjust-tags")
          (setq adj-tags (elfeed-score--parse-adjust-tags-rule-sexps rest)))
	       ((eq key 'mark)
          ;; set `mark' to (cdr rest) if (not mark) or (< mark (cdr rest))
          (let ((rest (car rest)))
            (if (or (not mark)
                    (< mark rest))
                (setq mark rest))))
	       (t
	        (error "Unknown score file key %s" key)))))
    (list
     :mark mark
     :adjust-tags adj-tags
	   :feeds feeds
	   :titles titles
     :content content
     :title-or-content tocs
     :tag tags)))

(defun elfeed-score--parse-scoring-sexp-4 (sexp)
  "Interpret the S-expression SEXP as scoring rules version 4.

Parse version 4 of the scoring S-expression.  Return a property list
with the following keys:

    - :title : list of elfeed-score-title-rule structs
    - :content : list of elfeed-score-content-rule structs
    - :title-or-content: list of elfeed-score-title-or-content-rule
                         structs
    - :feed : list of elfeed-score-feed-rule structs
    - :authors : list of elfeed-score-authors-rule-structs
    - :tag : list of elfeed-score-tag-rule structs
    - :mark : score below which entries shall be marked read
    - :adjust-tags : list of elfeed-score-adjust-tags-rule structs"

  (let (mark titles feeds content tocs authors tags adj-tags)
    (dolist (raw-item sexp)
      (let ((key  (car raw-item))
	          (rest (cdr raw-item)))
	      (cond
         ((string= key "version")
          (unless (or (eq 4 (car rest)) (eq 5 (car rest)))
            (error "Unsupported score file version %s" (car rest))))
	       ((string= key "title")
          (setq titles (elfeed-score--parse-title-rule-sexps rest)))
         ((string= key "content")
          (setq content (elfeed-score--parse-content-rule-sexps rest)))
         ((string= key "feed")
          (setq feeds (elfeed-score--parse-feed-rule-sexps rest)))
         ((string= key "title-or-content")
          (setq tocs (elfeed-score--parse-title-or-content-rule-sexps rest)))
	       ((string= key "authors")
          (setq authors (elfeed-score--parse-authors-rule-sexps rest)))
         ((string= key "tag")
          (setq tags (elfeed-score--parse-tag-rule-sexps rest)))
         ((string= key "adjust-tags")
          (setq adj-tags (elfeed-score--parse-adjust-tags-rule-sexps rest)))
	       ((eq key 'mark)
          ;; set `mark' to (cdr rest) if (not mark) or (< mark (cdr rest))
          (let ((rest (car rest)))
            (if (or (not mark)
                    (< mark rest))
                (setq mark rest))))
	       (t
	        (error "Unknown score file key %s" key)))))
    (list
     :mark mark
     :adjust-tags adj-tags
	   :feeds feeds
	   :titles titles
     :content content
     :title-or-content tocs
     :authors authors
     :tag tags)))

(defun elfeed-score--parse-scoring-sexp (sexps)
  "Parse raw S-expressions (SEXPS) into scoring rules."
  (let ((version
         (cond
          ((assoc 'version sexps)
           (cadr (assoc 'version sexps)))
          ((assoc "version" sexps)
           (cadr (assoc "version" sexps)))
          (t
           ;; I'm going to assume this is a new, hand-authored scoring
           ;; file, and attempt to parse it according to the latest
           ;; version spec.
           4))))
    ;; I use `cl-delete' instead of `assoc-delete-all' because the
    ;; latter would entail a dependency on Emacs 26.2, which I would
    ;; prefer not to do.
    (cl-delete "version" sexps :test 'equal :key 'car)
    (cl-delete 'version sexps :test 'equal :key 'car)
    (cond
     ((eq version 1)
      (elfeed-score--parse-scoring-sexp-1 sexps))
     ((eq version 2)
      (elfeed-score--parse-scoring-sexp-2 sexps))
     ((eq version 3)
      (elfeed-score--parse-scoring-sexp-3 sexps))
     ((eq version 4)
      (elfeed-score--parse-scoring-sexp-4 sexps))
     ((eq version 5)
      ;; This is not a typo-- I want to call
      ;; `elfeed-score--parse-scoring-sexp-4' even when the score file
      ;; format is 5.  The difference in the two formats is that
      ;; version 5 adds new fields to the end of several rule types;
      ;; the first-level structure of the s-expression doesn't
      ;; change.  So if an old version of `elfeed-score' tried to read
      ;; version 5, it wouldn't encounter an error, it would just
      ;; silently ignore those new fields. I don't think this is what
      ;; the user would want (especially since their new attributes
      ;; would be lost the first time their old `elfeed-score' writes
      ;; out their scoring rules), so I bumped the version to 5 (to
      ;; keep old versions from even trying to read it) but I can
      ;; still use the same first-level parsing logic.
      (elfeed-score--parse-scoring-sexp-4 sexps))
     (t
      (error "Unknown version %s" version)))))

(defun elfeed-score--parse-score-file (score-file)
  "Parse SCORE-FILE.

Internal.  This is the core score file parsing routine.  Opens
SCORE-FILE, reads the contents as a Lisp form, and parses that
into a property list with the following properties:

    - :content
    - :feeds
    - :authors
    - :mark
    - :titles
    - :adjust-tags
    - :title-or-content
    - :tags"

  (let ((sexp
         (car
		      (read-from-string
		       (with-temp-buffer
			       (insert-file-contents score-file)
			       (buffer-string))))))
    (elfeed-score--parse-scoring-sexp sexp)))

(defvar elfeed-score--title-rules nil
  "List of structs each defining a scoring rule for entry titles.")

(defvar elfeed-score--feed-rules nil
  "List of structs each defining a scoring rule for entry feeds.")

(defvar elfeed-score--authors-rules nil
  "List of structs each defining a scoring rule for entry authors.")

(defvar elfeed-score--content-rules nil
  "List of structs each defining a scoring rule for entry content.")

(defvar elfeed-score--title-or-content-rules nil
  "List of structs each defining a scoring rule for entry title or content.")

(defvar elfeed-score--tag-rules nil
  "List of structs each defining a scoring rule for entry tags.")

(defvar elfeed-score--score-mark nil
  "Score at or below which entries shall be marked as read.")

(defvar elfeed-score--adjust-tags-rules nil
  "List of structs defining rules to be run after scoring to adjust entry tags based on score.")

(defun elfeed-score--load-score-file (score-file)
  "Load SCORE-FILE into our internal scoring rules.

Internal.  Read SCORE-FILE, store scoring rules in our internal datastructures,"

  (let ((score-entries (elfeed-score--parse-score-file score-file)))
    (setq elfeed-score--title-rules            (plist-get score-entries :titles)
          elfeed-score--feed-rules             (plist-get score-entries :feeds)
          elfeed-score--content-rules          (plist-get score-entries :content)
          elfeed-score--title-or-content-rules (plist-get score-entries :title-or-content)
          elfeed-score--tag-rules              (plist-get score-entries :tag)
          elfeed-score--authors-rules          (plist-get score-entries :authors)
          elfeed-score--score-mark             (plist-get score-entries :mark)
          elfeed-score--adjust-tags-rules      (plist-get score-entries :adjust-tags))))

(defun elfeed-score--match-text (match-text search-text match-type)
  "Test SEARCH-TEXT against MATCH-TEXT according to MATCH-TYPE.
Return nil on failure, the matched text on match."
  (cond
   ((or (eq match-type 's)
        (eq match-type 'S))
    (let ((case-fold-search (eq match-type 's)))
      (if (string-match (regexp-quote match-text) search-text)
          (match-string 0 search-text)
        nil)))
   ((or (eq match-type 'r)
        (eq match-type 'R)
        (not match-type))
    (let ((case-fold-search (eq match-type 'r)))
      (if (string-match match-text search-text)
          (match-string 0 search-text)
        nil)))
   ((or (eq match-type 'w)
        (eq match-type 'W))
    (let ((case-fold-search (eq match-type 'w)))
      (if  (string-match (word-search-regexp match-text) search-text)
          (match-string 0 search-text))))
   (t
    (error "Unknown match type %s" match-type))))

(defun elfeed-score--match-tags (entry-tags tag-rule)
  "Test a ENTRY-TAGS against TAG-RULE.

ENTRY-TAGS shall be a list of symbols, presumably the tags applied to the Elfeed
entry being scored.  TAG-RULE shall be a list of the form (boolean . (symbol...))
or nil, and is presumably a tag scoping for a scoring rule."

  (if tag-rule
      (let ((flag (car tag-rule))
            (rule-tags (cdr tag-rule))
            (apply nil))
        ;; Special case allowing this method to be called like (... (t . symbol))
        (if (symbolp rule-tags)
            (setq rule-tags (list rule-tags)))
        (while (and rule-tags (not apply))
          (if (memq (car rule-tags) entry-tags)
              (setq apply t))
          (setq rule-tags (cdr rule-tags)))
        (if flag
            apply
          (not apply)))
    t))

(defun elfeed-score--get-feed-attr (feed attr)
  "Retrieve attribute ATTR from FEED."
  (cond
   ((eq attr 't) (elfeed-feed-title feed))
   ((eq attr 'u) (elfeed-feed-url feed))
   ((eq attr 'a) (elfeed-feed-author feed))
   (t (error "Unknown feed attribute %s" attr))))

(defun elfeed-score--match-feeds (entry-feed feed-rule)
  "Test ENTRY-FEED against FEED-RULE.

ENTRY-FEED shall be an <elfeed-feed> instance.  FEED-RULE shall
be a list of the form (BOOLEAN (ATTR TYPE TEXT)...), or nil, and
is presumably the feed scoping for a scoring rule."

  (if feed-rule
      (let ((flag (car feed-rule))
            (rule-feeds (cdr feed-rule))
            (match))
        ;; Special case allowing this method to be called like (... (t 't 's "title))
        (if (symbolp (car rule-feeds))
            (setq rule-feeds (list rule-feeds)))
        (while (and rule-feeds (not match))
          (let* ((feed (car rule-feeds))
                 (attr (nth 0 feed))
                 (match-type (nth 1 feed))
                 (match-text (nth 2 feed))
                 (feed-text (elfeed-score--get-feed-attr entry-feed attr)))
            (if (elfeed-score--match-text match-text feed-text match-type)
                (setq match t)))
          (setq rule-feeds (cdr rule-feeds)))
        (if flag match (not match)))
    t))

(defun elfeed-score--apply-title-rules (entry on-match)
  "Apply all title scoring rules to ENTRY; call ON-MATCH for each match.

ON-MATCH will be invoked with the matching rule & the matchted text."
  (let ((title (elfeed-entry-title entry)))
    (dolist (rule elfeed-score--title-rules)
      (let* ((match-text   (elfeed-score-title-rule-text  rule))
		         (match-type   (elfeed-score-title-rule-type  rule))
             (tag-rule     (elfeed-score-title-rule-tags  rule))
             (feed-rule    (elfeed-score-title-rule-feeds rule))
             (matched-text (and
                            (elfeed-score--match-tags (elfeed-entry-tags entry) tag-rule)
                            (elfeed-score--match-feeds (elfeed-entry-feed entry) feed-rule)
                            (elfeed-score--match-text match-text title match-type))))
        (if matched-text (funcall on-match rule matched-text))))))

(defun elfeed-score--explain-title (entry)
  "Apply all title scoring rules to ENTRY; return an explanation.

The explanation will be a list of two-tuples (i.e. a list with
two elements), one for each matching rule.  The first element of
each two-tuple will be the matching rule & the second the
matched text."
  (let ((hits '()))
    (elfeed-score--apply-title-rules
     entry
     (lambda (rule matched-text)
       (setq hits (cons (elfeed-score-make-title-explanation :matched-text matched-text :rule rule) hits))))
    hits))

(defun elfeed-score--score-on-title (entry)
  "Run all title scoring rules against ENTRY; return the summed values."
  (let ((score 0))
    (elfeed-score--apply-title-rules
     entry
     (lambda (rule matched-text)
       (let* ((value (elfeed-score-title-rule-value rule)))
         (elfeed-score-log
          'debug
          "title rule '%s' matched text '%s' for entry %s('%s'); adding %d to
its score"
          (elfeed-score--pp-rule-to-string rule)
          matched-text
          (elfeed-entry-id entry)
          (elfeed-entry-title entry) value)
		     (setq score (+ score value))
         (setf (elfeed-score-title-rule-date rule) (float-time))
         (setf (elfeed-score-title-rule-hits rule)
               (1+ (elfeed-score-title-rule-hits rule))))))
    score))

(defun elfeed-score--concatenate-authors (authors-list)
  "Given AUTHORS-LIST, list of plists; return string of all authors concatenated."
  (mapconcat (lambda (author) (plist-get author :name)) authors-list ", "))

(defun elfeed-score--apply-authors-rules (entry on-match)
  "Apply all authors rules to ENTRY; invoke ON-MATCH for each match.

ON-MATCH will be invoked with the matching rule & the matched text."
  (let ((authors-string
         (elfeed-score--concatenate-authors
          (elfeed-meta entry :authors))))
    (dolist (rule elfeed-score--authors-rules)
      (let* ((match-text   (elfeed-score-authors-rule-text  rule))
		         (match-type   (elfeed-score-authors-rule-type  rule))
             (tag-rule     (elfeed-score-authors-rule-tags  rule))
             (feed-rule    (elfeed-score-authors-rule-feeds rule))
             (matched-text (and
                            (elfeed-score--match-tags (elfeed-entry-tags entry) tag-rule)
                            (elfeed-score--match-feeds (elfeed-entry-feed entry) feed-rule)
                            (elfeed-score--match-text match-text authors-string match-type))))
        (if matched-text (funcall on-match rule matched-text))))))

(defun elfeed-score--explain-authors (entry)
  "Apply the authors rules to ENTRY; return an explanation.

The explanation will be a list of two-tuples (i.e. a list with
two elements), one for each rule.  The first element of each
two-tuple will be the rule & the second the matched text."
  (let ((hits '()))
    (elfeed-score--apply-authors-rules
     entry
     (lambda (rule match-text)
       (setq hits (cons (elfeed-score-make-authors-explanation :matched-text match-text :rule rule) hits))))
    hits))

(defun elfeed-score--score-on-authors (entry)
  "Run all title scoring rules against ENTRY; return the summed values."
  (let ((score 0))
    (elfeed-score--apply-authors-rules
     entry
     (lambda (rule match-text)
       (let ((value (elfeed-score-authors-rule-value rule)))
         (elfeed-score-log
          'debug
          "title rule '%s' matched text '%s' for entry %s('%s'); \
adding %d to its score"
          (elfeed-score--pp-rule-to-string rule)
          match-text
          (elfeed-entry-id entry)
          (elfeed-entry-title entry)
          value)
		     (setq score (+ score value))
         (setf (elfeed-score-authors-rule-date rule) (float-time))
         (setf (elfeed-score-authors-rule-hits rule)
               (1+ (elfeed-score-authors-rule-hits rule))))))
    score))

(defun elfeed-score--apply-feed-rules (entry on-match)
  "Run all feed rules against ENTRY; invoke ON-MATCH for each match.

ON-MATCH will be invoked with the applicable rule as well as the matched text."
  (let ((feed (elfeed-entry-feed  entry)))
    (dolist (rule elfeed-score--feed-rules)
      (let* ((match-text   (elfeed-score-feed-rule-text rule))
		         (match-type   (elfeed-score-feed-rule-type rule))
             (attr         (elfeed-score-feed-rule-attr rule))
             (feed-text    (elfeed-score--get-feed-attr feed attr))
             (tag-rule     (elfeed-score-feed-rule-tags rule))
             (matched-text (and
                            (elfeed-score--match-tags (elfeed-entry-tags entry) tag-rule)
                            (elfeed-score--match-text match-text feed-text match-type))))
        (if matched-text (funcall on-match rule matched-text))))))

(defun elfeed-score--explain-feed (entry)
  "Apply the feed scoring rules to ENTRY, return an explanation.

The explanation will be a list of two-tuples (i.e. a list with
two elements), one for each rule that matches.  The first element
will be the rule that matched & the second the matched text."
  (let ((hits '()))
    (elfeed-score--apply-feed-rules
     entry
     (lambda (rule match-text)
       (setq hits (cons (elfeed-score-make-feed-explanation :matched-text match-text :rule rule) hits))))
    hits))

(defun elfeed-score--score-on-feed (entry)
  "Run all feed scoring rules against ENTRY; return the summed values."
  (let ((score 0))
    (elfeed-score--apply-feed-rules
     entry
     (lambda (rule match-text)
       (let ((value (elfeed-score-feed-rule-value rule)))
         (elfeed-score-log
          'debug
          "feed rule '%s' matched text '%s' for entry %s('%s'); \
adding %d to its score"
          (elfeed-score--pp-rule-to-string rule)
          match-text
          (elfeed-entry-id entry)
          (elfeed-entry-title entry) value)
		     (setq score (+ score value))
		     (setf (elfeed-score-feed-rule-date rule) (float-time))
         (setf (elfeed-score-feed-rule-hits rule)
               (1+ (elfeed-score-feed-rule-hits rule))))))
    score))

(defun elfeed-score--apply-content-rules (entry on-match)
  "Apply the content scoring rules to ENTRY; invoke ON-MATCH for each match.

ON-MATCH will be invoked with each matching rule and the ENTRY
text on which it matched."
  (let ((content (elfeed-deref (elfeed-entry-content entry))))
    (if content
        (dolist (rule elfeed-score--content-rules)
          (let* ((match-text    (elfeed-score-content-rule-text  rule))
		             (match-type    (elfeed-score-content-rule-type  rule))
                 (tag-rule      (elfeed-score-content-rule-tags  rule))
                 (feed-rule     (elfeed-score-content-rule-feeds rule))
                 (matched-text  (and
                                 (elfeed-score--match-tags (elfeed-entry-tags entry) tag-rule)
                                 (elfeed-score--match-feeds (elfeed-entry-feed entry) feed-rule)
                                 (elfeed-score--match-text match-text content match-type))))
            (if matched-text (funcall on-match rule matched-text)))))))

(defun elfeed-score--explain-content (entry)
  "Apply the content scoring rules to ENTRY, return an explanation.

The explanation is a list of two-tuples (i.e. a list with two elements); the
first member of each list element will be the rule that matched & the second
the matched text."

  (let ((hits '()))
    (elfeed-score--apply-content-rules
     entry
     (lambda (rule match-text)
       (setq hits (cons (elfeed-score-make-content-explanation :matched-text match-text :rule rule) hits))))
    hits))

(defun elfeed-score--score-on-content (entry)
  "Run all content scoring rules against ENTRY; return the summed values."
  (let ((score 0))
    (elfeed-score--apply-content-rules
     entry
     (lambda (rule match-text)
       (let ((value (elfeed-score-content-rule-value rule)))
         (elfeed-score-log
          'debug "content rule '%s' matched text '%s' for entry %s('%s'); \
adding %d to its score"
          (elfeed-score--pp-rule-to-string rule)
          match-text
          (elfeed-entry-id entry)
          (elfeed-entry-title entry)
          value)
		     (setq score (+ score value))
		     (setf (elfeed-score-content-rule-date rule)
               (float-time))
         (setf (elfeed-score-content-rule-hits rule)
               (1+ (elfeed-score-content-rule-hits rule))))))
    score))

(defun elfeed-score--apply-title-or-content-rules (entry on-match)
  "Apply the title-or-content rules to ENTRY; invoke ON-MATCH for each match.

ON-MATCH will be invoked with the matching rule, the matched
text, and a boolean value indicating whether this is a title
match (t) or a content match (nil)."

  (let ((title (elfeed-entry-title entry))
        (content (elfeed-deref (elfeed-entry-content entry))))
    (dolist (rule elfeed-score--title-or-content-rules)
      (let* ((match-text      (elfeed-score-title-or-content-rule-text        rule))
		         (match-type      (elfeed-score-title-or-content-rule-type        rule))
             (tag-rule        (elfeed-score-title-or-content-rule-tags        rule))
             (feed-rule       (elfeed-score-title-or-content-rule-feeds       rule))
             (matched-tags    (elfeed-score--match-tags  (elfeed-entry-tags entry) tag-rule))
             (matched-feeds   (elfeed-score--match-feeds (elfeed-entry-feed entry) feed-rule))
             (matched-title
              (and
               matched-tags
               matched-feeds
               (elfeed-score--match-text match-text title match-type)))
             (matched-content
              (and
               content
               matched-tags
               matched-feeds
               (elfeed-score--match-text match-text content match-type)))
             (got-title-match (and matched-tags matched-feeds matched-title))
             (got-content-match (and content matched-tags matched-feeds matched-content)))
        (if got-title-match (funcall on-match rule matched-title t))
        (if got-content-match (funcall on-match rule matched-content nil))))))

(defun elfeed-score--explain-title-or-content (entry)
  "Apply the title-or-content scoring rules to ENTRY, return an explanation.

The explanation is a list of three-tuples: rule, matched text, t
for a title match & nil for a content match."
  (let ((hits '()))
    (elfeed-score--apply-title-or-content-rules
     entry
     (lambda (rule match-text title-match)
       (setq
        hits
        (cons
         (elfeed-score-make-title-or-content-explanation
          :matched-text match-text :rule rule :attr (if title-match 't 'c))
         hits))))
    hits))

(defun elfeed-score--score-on-title-or-content (entry)
  "Run all title-or-content rules against ENTRY; return the summed values."
  (let ((score 0))
    (elfeed-score--apply-title-or-content-rules
     entry
     (lambda (rule match-text title-match)
       (if title-match
           (let ((value (elfeed-score-title-or-content-rule-title-value rule)))
             (elfeed-score-log 'debug "title-or-content rule '%s' matched text\
 '%s' in the title of entry '%s'; adding %d to its score"
                               (elfeed-score--pp-rule-to-string rule)
                               match-text (elfeed-entry-id entry) value)
		         (setq score (+ score value))
             (setf (elfeed-score-title-or-content-rule-date rule)
                   (float-time))
             (setf (elfeed-score-title-or-content-rule-hits rule)
                   (1+ (elfeed-score-title-or-content-rule-hits rule))))
         (let ((value (elfeed-score-title-or-content-rule-content-value rule)))
           (elfeed-score-log 'debug "title-or-content rule '%s' matched text\
 '%s' in the content of entry '%s'; adding %d to its score"
                             (elfeed-score--pp-rule-to-string rule)
                             match-text (elfeed-entry-id entry)
                             value)
		       (setq score (+ score value))
		       (setf (elfeed-score-title-or-content-rule-date rule)
                 (float-time))
           (setf (elfeed-score-title-or-content-rule-hits rule)
                 (1+ (elfeed-score-title-or-content-rule-hits rule)))))))
    score))

(defun elfeed-score--apply-tag-rules (entry on-match)
  "Apply the tag scoring rules to ENTRY; invoke ON-MATCH for each match.

On match, ON-MATCH will be called with the matching rule."
  (let ((tags (elfeed-entry-tags entry)))
    (dolist (rule elfeed-score--tag-rules)
      (let* ((rule-tags  (elfeed-score-tag-rule-tags rule))
             (got-match  (elfeed-score--match-tags tags rule-tags)))
        (if got-match (funcall on-match rule))))))

(defun elfeed-score--explain-tags (entry)
  "Record with tags rules match ENTRY.  Return a list of the rules that matched."
  (let ((hits '()))
    (elfeed-score--apply-tag-rules
     entry
     (lambda (rule)
       (setq hits (cons (elfeed-score-make-tags-explanation :rule rule) hits))))
    hits))

(defun elfeed-score--score-on-tags (entry)
  "Run all tag scoring rules against ENTRY; return the summed value."

  (let ((score 0))
    (elfeed-score--apply-tag-rules
     entry
     (lambda (rule)
       (let ((rule-value (elfeed-score-tag-rule-value rule)))
         (elfeed-score-log
          'debug "tag rule '%s' matched entry %s('%s'); adding %d to its score"
          (elfeed-score--pp-rule-to-string rule)
          (elfeed-entry-id entry)
          (elfeed-entry-title entry)
          rule-value)
         (setq score (+ score rule-value))
         (setf (elfeed-score-tag-rule-date rule) (float-time))
         (setf (elfeed-score-tag-rule-hits rule)
               (1+ (elfeed-score-tag-rule-hits rule))))))
    score))

(defun elfeed-score--adjust-tags (entry score)
  "Run all tag adjustment rules against ENTRY for score SCORE."
  (dolist (adj-tags elfeed-score--adjust-tags-rules)
    (let* ((thresh           (elfeed-score-adjust-tags-rule-threshold adj-tags))
           (threshold-switch (car thresh))
           (threshold-value  (cdr thresh)))
      (if (or (and threshold-switch )
              (and (not threshold-switch) (<= score threshold-value)))
          (let* ((rule-tags   (elfeed-score-adjust-tags-rule-tags adj-tags))
                 (rule-switch (car rule-tags))
                 (actual-tags (cdr rule-tags))) ;; may be a single tag or a list!
            (if rule-switch
                (progn
                  ;; add `actual-tags'...
                  (elfeed-score-log 'debug "Tag adjustment rule %s matched score %d for entry \
%s(%s); adding tag(s) %s"
                                    rule-tags score (elfeed-entry-id entry)
                                    (elfeed-entry-title entry) actual-tags)
                  (apply #'elfeed-tag entry actual-tags)
                  (setf (elfeed-score-adjust-tags-rule-date adj-tags) (float-time))
                  (setf (elfeed-score-adjust-tags-rule-hits adj-tags)
                        (1+ (elfeed-score-adjust-tags-rule-hits adj-tags))))
              (progn
                ;; else rm `actual-tags'
                (elfeed-score-log 'debug "Tag adjustment rule %s matched score %d for entry \
%s(%s); removing tag(s) %s"
                                  rule-tags score (elfeed-entry-id entry)
                                  (elfeed-entry-title entry) actual-tags)
                (apply #'elfeed-untag entry actual-tags)
                (setf (elfeed-score-adjust-tags-rule-date adj-tags) (float-time))
                (setf (elfeed-score-adjust-tags-rule-hits adj-tags)
                      (1+ (elfeed-score-adjust-tags-rule-hits adj-tags))))))))))

(defun elfeed-score--score-entry (entry)
  "Score an Elfeed ENTRY.

This function will return the entry's score, update it's meta-data, and
update the \"last matched\" time of the salient rules."

  (let ((score (+ elfeed-score-default-score
                  (elfeed-score--score-on-title            entry)
                  (elfeed-score--score-on-feed             entry)
                  (elfeed-score--score-on-content          entry)
                  (elfeed-score--score-on-title-or-content entry)
                  (elfeed-score--score-on-authors          entry)
                  (elfeed-score--score-on-tags             entry))))
    (elfeed-score--set-score-on-entry entry score)
    (elfeed-score--adjust-tags entry score)
	  (if (and elfeed-score--score-mark
		         (< score elfeed-score--score-mark))
	      (elfeed-untag entry 'unread))
    score))

(defun elfeed-score--pp-rule-match-to-string (match)
  "Pretty-print a rule explanation MATCH & return the resulting string."

  (cl-typecase match
    (elfeed-score-title-explanation
     (elfeed-score-pp-title-explanation match))
    (elfeed-score-feed-explanation
     (elfeed-score-pp-feed-explanation match))
    (elfeed-score-content-explanation
     (elfeed-score-pp-content-explanation match))
    (elfeed-score-title-or-content-explanation
     (elfeed-score-pp-title-or-content-explanation match))
    (elfeed-score-authors-explanation
     (elfeed-score-pp-authors-explanation match))
    (elfeed-score-tags-explanation
     (elfeed-score-pp-tags-explanation match))
    (t
     (error "Don't know how to pretty-print %S" match))))

(defun elfeed-score--get-match-contribution (match)
  "Retrieve the score contribution for MATCH."

  (cl-typecase match
    (elfeed-score-title-explanation
     (elfeed-score-title-explanation-contrib match))
    (elfeed-score-feed-explanation
     (elfeed-score-feed-explanation-contrib match))
    (elfeed-score-content-explanation
     (elfeed-score-content-explanation-contrib match))
    (elfeed-score-title-or-content-explanation
     (elfeed-score-title-or-content-explanation-contrib match))
    (elfeed-score-authors-explanation
     (elfeed-score-authors-explanation-contrib match))
    (elfeed-score-tags-explanation
     (elfeed-score-tags-explanation-contrib match))
    (t
     (error "Don't know how to evaluate %S" match))))

(defun elfeed-score-explain-entry (entry)
  "Explain an Elfeed ENTRY.

This function will apply all scoring rules to an entry, but will
not change anything (e.g.  update ENTRY's meta-data, or the
last-matched timestamp in the matching rules); instead, it will
provide a human-readable description of what would happen if
ENTRY were to be scored, presumably for purposes of debugging or
understanding of scoring rules."

  ;; Generate the list of matching rules
  (let* ((matches
          (append
           (elfeed-score--explain-title            entry)
           (elfeed-score--explain-feed             entry)
           (elfeed-score--explain-content          entry)
           (elfeed-score--explain-title-or-content entry)
           (elfeed-score--explain-authors          entry)
           (elfeed-score--explain-tags             entry)))
         (candidate-score
          (cl-reduce
           '+
           matches
           :key #'elfeed-score--get-match-contribution
           :initial-value elfeed-score-default-score)))
    (with-current-buffer-window
        elfeed-score-explanation-buffer-name
        nil nil
      (goto-char (point-max))
      (insert (format "\"%s\" matches %d rules"(elfeed-entry-title entry) (length matches)))
      (if (> (length matches) 0)
          (progn
            (insert (format " for a score of %d:\n" candidate-score))
            (cl-dolist (match matches)
              (insert
               (format
                "%s\n"
                (elfeed-score--pp-rule-match-to-string match)))))))))

(defun elfeed-score-explain (&optional ignore-region)
  "Explain why some entries were scored the way they were.

Explain the scores for all the selected entries, unless
IGNORE-REGION is non-nil, in which case only the entry under
point will be explained.  If the region is not active, only the
entry under point will be explained."
  (interactive)
  (let ((entries (elfeed-search-selected ignore-region)))
    (dolist (entry entries)
      (elfeed-score-explain-entry entry))
    (elfeed-search-update t)))

(define-obsolete-function-alias 'elfeed-score/load-score-file
  'elfeed-score-load-score-file "0.2.0" "Move to standard-compliant naming.")

(defun elfeed-score-load-score-file (score-file)
  "Load SCORE-FILE into the current scoring rules."

  (interactive
   (list
    (read-file-name "score file: " nil elfeed-score-score-file t
                    elfeed-score-score-file)))
  (elfeed-score--load-score-file score-file))

(define-obsolete-function-alias 'elfeed-score/write-score-file
  'elfeed-score-write-score-file "0.2.0" "Move to standard-compliant naming.")

(defun elfeed-score-write-score-file (score-file)
  "Write the current scoring rules to SCORE-FILE."
  (interactive
   (list
    (read-file-name "score file: " nil elfeed-score-score-file t
                    elfeed-score-score-file)))
  (write-region
   (format
    ";;; Elfeed score file                                     -*- lisp -*-\n%s"
    (let ((print-level nil)
          (print-length nil))
	    (pp-to-string
	     (list
	      (list 'version 5)
        (append
         '("title")
	       (mapcar
	        (lambda (x)
            (list
             (elfeed-score-title-rule-text  x)
             (elfeed-score-title-rule-value x)
             (elfeed-score-title-rule-type  x)
             (elfeed-score-title-rule-date  x)
             (elfeed-score-title-rule-tags  x)
             (elfeed-score-title-rule-hits  x)
             (elfeed-score-title-rule-feeds x)))
	        elfeed-score--title-rules))
        (append
         '("content")
	       (mapcar
	        (lambda (x)
            (list
		         (elfeed-score-content-rule-text  x)
		         (elfeed-score-content-rule-value x)
		         (elfeed-score-content-rule-type  x)
		         (elfeed-score-content-rule-date  x)
             (elfeed-score-content-rule-tags  x)
             (elfeed-score-content-rule-hits  x)
             (elfeed-score-content-rule-feeds x)))
	        elfeed-score--content-rules))
        (append
         '("title-or-content")
         (mapcar
          (lambda (x)
            (list
             (elfeed-score-title-or-content-rule-text x)
             (elfeed-score-title-or-content-rule-title-value x)
             (elfeed-score-title-or-content-rule-content-value x)
             (elfeed-score-title-or-content-rule-type x)
             (elfeed-score-title-or-content-rule-date x)
             (elfeed-score-title-or-content-rule-tags x)
             (elfeed-score-title-or-content-rule-hits x)
             (elfeed-score-title-or-content-rule-feeds x)))
          elfeed-score--title-or-content-rules))
        (append
         '("tag")
         (mapcar
          (lambda (x)
            (list
             (elfeed-score-tag-rule-tags  x)
             (elfeed-score-tag-rule-value x)
             (elfeed-score-tag-rule-date  x)
             (elfeed-score-tag-rule-hits  x)))
          elfeed-score--tag-rules))
        (append
         '("authors")
	       (mapcar
	        (lambda (x)
            (list
             (elfeed-score-authors-rule-text  x)
             (elfeed-score-authors-rule-value x)
             (elfeed-score-authors-rule-type  x)
             (elfeed-score-authors-rule-date  x)
             (elfeed-score-authors-rule-tags  x)
             (elfeed-score-authors-rule-hits  x)
             (elfeed-score-authors-rule-feeds x)))
	        elfeed-score--authors-rules))
        (append
         '("feed")
	       (mapcar
	        (lambda (x)
            (list
		         (elfeed-score-feed-rule-text  x)
		         (elfeed-score-feed-rule-value x)
		         (elfeed-score-feed-rule-type  x)
             (elfeed-score-feed-rule-attr  x)
		         (elfeed-score-feed-rule-date  x)
             (elfeed-score-feed-rule-tags  x)
             (elfeed-score-feed-rule-hits  x)))
	        elfeed-score--feed-rules))
        (list 'mark elfeed-score--score-mark)
        (append
         '("adjust-tags")
         (mapcar
          (lambda (x)
            (list
             (elfeed-score-adjust-tags-rule-threshold x)
             (elfeed-score-adjust-tags-rule-tags      x)
             (elfeed-score-adjust-tags-rule-date      x)
             (elfeed-score-adjust-tags-rule-hits      x)))
          elfeed-score--adjust-tags-rules))))))
   nil score-file))

(define-obsolete-function-alias 'elfeed-score/score
  'elfeed-score-score "0.2.0" "Move to standard-compliant naming.")

(defun elfeed-score-score (&optional ignore-region)
  "Score some entries.

Score all selected entries, unless IGNORE-REGION is non-nil, in
which case only the entry under point will be scored.  If the
region is not active, only the entry under point will be scored."

  (interactive "P")

  (let ((entries (elfeed-search-selected ignore-region)))
    (dolist (entry entries)
      (let ((score (elfeed-score--score-entry entry)))
        (elfeed-score-log 'info "entry %s('%s') has been given a score of %d"
                          (elfeed-entry-id entry) (elfeed-entry-title entry) score)))
    (if elfeed-score-score-file
       (elfeed-score-write-score-file elfeed-score-score-file))
    (elfeed-search-update t)))

(define-obsolete-function-alias 'elfeed-score/score-search
  'elfeed-score-score-search "0.2.0" "Move to standard-compliant naming.")

(defun elfeed-score-score-search ()
  "Score the current set of search results."

  (interactive)

  (dolist (entry elfeed-search-entries)
    (let ((score (elfeed-score--score-entry entry)))
      (elfeed-score-log 'info "entry %s('%s') has been given a score of %d"
                        (elfeed-entry-id entry) (elfeed-entry-title entry) score)))
  (if elfeed-score-score-file
	    (elfeed-score-write-score-file elfeed-score-score-file))
  (elfeed-search-update t))

(defvar elfeed-score-map
  (let ((map (make-sparse-keymap)))
    (prog1 map
      (suppress-keymap map)
      (define-key map "e" #'elfeed-score-set-score)
      (define-key map "g" #'elfeed-score-get-score)
      (define-key map "l" #'elfeed-score-load-score-file)
      (define-key map "s" #'elfeed-score-score)
      (define-key map "v" #'elfeed-score-score-search)
      (define-key map "w" #'elfeed-score-write-score-file)
      (define-key map "x" #'elfeed-score-explain)))
  "Keymap for `elfeed-score' commands.")

(defvar elfeed-score--old-sort-function nil
  "Original value of `elfeed-search-sort-function'.")

(defvar elfeed-score--old-print-entry-function nil
  "Original value of `elfed-search-print-entry-function'.")

(defun elfeed-score-print-entry (entry)
  "Print ENTRY to the Elfeed search buffer.
This implementation is derived from `elfeed-search-print-entry--default'."
  (let* ((date (elfeed-search-format-date (elfeed-entry-date entry)))
         (title (or (elfeed-meta entry :title) (elfeed-entry-title entry) ""))
         (title-faces (elfeed-search--faces (elfeed-entry-tags entry)))
         (feed (elfeed-entry-feed entry))
         (feed-title
          (when feed
            (or (elfeed-meta feed :title) (elfeed-feed-title feed))))
         (tags (mapcar #'symbol-name (elfeed-entry-tags entry)))
         (tags-str (mapconcat
                    (lambda (s) (propertize s 'face 'elfeed-search-tag-face))
                    tags ","))
         (title-width (- (window-width) 10 elfeed-search-trailing-width))
         (title-column (elfeed-format-column
                        title (elfeed-clamp
                               elfeed-search-title-min-width
                               title-width
                               elfeed-search-title-max-width)
                        :left))
	       (score
          (elfeed-score-format-score
           (elfeed-score--get-score-from-entry entry))))
    (insert score)
    (insert (propertize date 'face 'elfeed-search-date-face) " ")
    (insert (propertize title-column 'face title-faces 'kbd-help title) " ")
    (when feed-title
      (insert (propertize feed-title 'face 'elfeed-search-feed-face) " "))
    (when tags
      (insert "(" tags-str ")"))))

;;;###autoload
(defun elfeed-score-enable (&optional arg)
  "Enable `elfeed-score'.  With prefix ARG do not install a custom sort function."

  (interactive "P")

  ;; Begin scoring on every new entry...
  (add-hook 'elfeed-new-entry-hook #'elfeed-score--score-entry)
  ;; sort based on score...
  (unless arg
    (setq elfeed-score--old-sort-function        elfeed-search-sort-function
          elfeed-search-sort-function            #'elfeed-score-sort
          elfeed-score--old-print-entry-function elfeed-search-print-entry-function))
  ;; & load the default score file, if it's defined & exists.
  (if (and elfeed-score-score-file
           (file-exists-p elfeed-score-score-file))
      (elfeed-score-load-score-file elfeed-score-score-file)))

(defun elfeed-score-unload ()
  "Unload `elfeed-score'."

  (interactive)

  (if elfeed-score-score-file
	    (elfeed-score-write-score-file elfeed-score-score-file))
  (if elfeed-score--old-sort-function
      (setq elfeed-search-sort-function elfeed-score--old-sort-function))
  (if elfeed-score--old-print-entry-function
      (setq elfeed-search-print-entry-function elfeed-score--old-print-entry-function))
  (remove-hook 'elfeed-new-entry-hook #'elfeed-score--score-entry))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; functions for rule maintenance
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun elfeed-score--get-last-match-date (rule)
  "Retrieve the time at which RULE was last matched.

Return the time, in seconds since epoch, at which RULE was most
recently matched against an entry (floating point).  Note that
RULE may be any rule struct."

  (let ((date
	 (cl-typecase rule
	   (elfeed-score-title-rule
	    (elfeed-score-title-rule-date rule))
	   (elfeed-score-feed-rule
	    (elfeed-score-feed-rule-date rule))
	   (elfeed-score-content-rule
	    (elfeed-score-content-rule-date rule))
	   (elfeed-score-title-or-content-rule
	    (elfeed-score-title-or-content-rule-date rule))
	   (elfeed-score-authors-rule
	    (elfeed-score-authors-rule-date rule))
	   (elfeed-score-tag-rule
	    (elfeed-score-tag-rule-date rule))
	   (elfeed-score-adjust-tags-rule
	    (elfeed-score-adjust-tags-rule-date rule))
	   (otherwise (error "Unknown rule type %S" rule)))))
    (or date 0.0)))

(defun elfeed-score--get-hits (rule)
  "Retrieve the number of times RULE has matched an entry.

Note that RULE may be an instance of any rule structure."

  (let ((hits
         (cl-typecase rule
	         (elfeed-score-title-rule
	          (elfeed-score-title-rule-hits rule))
	         (elfeed-score-feed-rule
	          (elfeed-score-feed-rule-hits rule))
	         (elfeed-score-content-rule
	          (elfeed-score-content-rule-hits rule))
	         (elfeed-score-title-or-content-rule
	          (elfeed-score-title-or-content-rule-hits rule))
	         (elfeed-score-authors-rule
	          (elfeed-score-authors-rule-hits rule))
	         (elfeed-score-tag-rule
	          (elfeed-score-tag-rule-hits rule))
	         (elfeed-score-adjust-tags-rule
	          (elfeed-score-adjust-tags-rule-hits rule))
	         (otherwise (error "Unknown rule type %S" rule)))))
    (or hits 0)))

(defun elfeed-score--sort-rules-by-last-match (rules)
  "Sort RULES in decreasing order of last match.

Note that RULES need not be homogeneous; it may contain rule
structs of any kind understood by
`elfeed-score--get-last-match-date'."
  (sort
   rules
   (lambda (lhs rhs)
     (> (elfeed-score--get-last-match-date lhs)
        (elfeed-score--get-last-match-date rhs)))))

(defun elfeed-score--sort-rules-by-hits (rules)
  "Sort RULES in decreasing order of match hits.

Note that RULES need not be homogeneous; it may contain rule
structs of any kind understood by
`elfeed-score--get-hits'."
  (sort
   rules
   (lambda (lhs rhs)
     (> (elfeed-score--get-hits lhs)
        (elfeed-score--get-hits rhs)))))

(defun elfeed-score--pp-rule-to-string (rule)
  "Pretty-print RULE; return as a string."
  (cl-typecase rule
    (elfeed-score-title-rule
     (format "title{%s}" (elfeed-score-title-rule-text rule)))
    (elfeed-score-feed-rule
     (format "feed{%s}" (elfeed-score-feed-rule-text rule)))
    (elfeed-score-content-rule
     (format "content{%s}" (elfeed-score-content-rule-text rule)))
    (elfeed-score-title-or-content-rule
     (format "title-or-content{%s}" (elfeed-score-title-or-content-rule-text rule)))
    (elfeed-score-authors-rule
     (format "authors{%s}" (elfeed-score-authors-rule-text rule)))
    (elfeed-score-tag-rule
     (format "tag{%s}" (prin1-to-string (elfeed-score-tag-rule-tags rule))))
    (elfeed-score-adjust-tags-rule
     (format "adjust-tags{%s}" (prin1-to-string (elfeed-score-adjust-tags-rule-tags rule))))
    (otherwise (error "Don't know how to pretty-print %S" rule))))

(defun elfeed-score--display-rules-by-last-match (rules title)
  "Sort RULES in decreasing order of last match; display results as TITLE."
  (let ((rules (elfeed-score--sort-rules-by-last-match rules))
	      (results '())
	      (max-text 0))
    (cl-dolist (rule rules)
      (let* ((pp (elfeed-score--pp-rule-to-string rule))
	           (lp (length pp)))
	      (if (> lp max-text) (setq max-text lp))
	      (setq
	       results
	       (append
          results
          (list (cons (format-time-string "%a, %d %b %Y %T %Z" (elfeed-score--get-last-match-date rule)) pp))))))
    (with-current-buffer-window title nil nil
      (let ((fmt (format "%%28s: %%-%ds\n" max-text)))
	      (cl-dolist (x results)
	        (insert (format fmt (car x) (cdr x))))
        (special-mode)))))

(defun elfeed-score--display-rules-by-match-hits (rules title)
  "Sort RULES in decreasing order of match hits; display results as TITLE."
  (let ((rules (elfeed-score--sort-rules-by-hits rules))
	      (results '())
	      (max-text 0)
        (max-hits 0))
    (cl-dolist (rule rules)
      (let* ((pp (elfeed-score--pp-rule-to-string rule))
	           (lp (length pp))
             (hits (elfeed-score--get-hits rule)))
	      (if (> lp max-text) (setq max-text lp))
        (if (> hits max-hits) (setq max-hits hits))
	      (setq results (append results (list (cons hits pp))))))
    (with-current-buffer-window title nil nil
      (let ((fmt (format "%%%dd: %%-%ds\n" (ceiling (log max-hits 10)) max-text)))
	      (cl-dolist (x results)
	        (insert (format fmt (car x) (cdr x))))
        (special-mode)))))

(defun elfeed-score--rules-for-keyword (key)
  "Retrieve the list of rules corresponding to keyword KEY."
  (cond
   ((eq key :title) elfeed-score--title-rules)
   ((eq key :feed) elfeed-score--feed-rules)
   ((eq key :content) elfeed-score--content-rules)
   ((eq key :title-or-content) elfeed-score--title-or-content-rules)
   ((eq key :authors) elfeed-score--authors-rules)
   ((eq key :tag) elfeed-score--tag-rules)
   ((eq key :adjust-tags) elfeed-score--adjust-tags-rules)
   (t
    (error "Unknown keyword %S" key))))

(defun elfeed-score-display-rules-by-last-match (&optional category)
  "Display all scoring rules in descending order of last match.

CATEGORY may be used to narrow the scope of rules displayed.  If
nil, display all rules.  If one of the following symbols, display
only that category of rules:

    :title
    :feed
    :content
    :title-or-content
    :authors
    :tag
    :adjust-tags

Finally, CATEGORY may be a list of symbols in the preceding
list, in which case the union of the corresponding rule
categories will be displayed."

  (interactive)
  (let ((rules
	       (cond
	        ((not category)
	         (append elfeed-score--title-rules elfeed-score--feed-rules
		               elfeed-score--content-rules
		               elfeed-score--title-or-content-rules
		               elfeed-score--authors-rules elfeed-score--tag-rules
		               elfeed-score--adjust-tags-rules))
	        ((symbolp category)
	         (elfeed-score--rules-for-keyword category))
	        ((listp category)
	         (cl-loop for sym in category
		                collect (elfeed-score--rules-for-keyword sym)))
	        (t
	         (error "Invalid argument %S" category)))))
    (elfeed-score--display-rules-by-last-match rules "elfeed-score Rules by Last Match")))

(defun elfeed-score-display-rules-by-match-hits (&optional category)
  "Display all scoring rules in descending order of match hits.

CATEGORY may be used to narrow the scope of rules displayed.  If
nil, display all rules.  If one of the following symbols, display
only that category of rules:

    :title
    :feed
    :content
    :title-or-content
    :authors
    :tag
    :adjust-tags

Finally, CATEGORY may be a list of symbols in the preceding
list, in which case the union of the corresponding rule
categories will be displayed."

  (interactive)
  (let ((rules
	       (cond
	        ((not category)
	         (append elfeed-score--title-rules elfeed-score--feed-rules
		               elfeed-score--content-rules
		               elfeed-score--title-or-content-rules
		               elfeed-score--authors-rules elfeed-score--tag-rules
		               elfeed-score--adjust-tags-rules))
	        ((symbolp category)
	         (elfeed-score--rules-for-keyword category))
	        ((listp category)
	         (cl-loop for sym in category
		                collect (elfeed-score--rules-for-keyword sym)))
	        (t
	         (error "Invalid argument %S" category)))))
    (elfeed-score--display-rules-by-match-hits rules "elfeed-score Rules by Match Hits")))

(provide 'elfeed-score)

;;; elfeed-score.el ends here
