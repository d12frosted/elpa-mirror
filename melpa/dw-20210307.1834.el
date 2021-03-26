;;; dw.el --- Diceware passphrase generation commands  -*- lexical-binding: t; -*-

;; Copyright (C) 2017-2020  D. Williams

;; Author: D. Williams <d.williams@posteo.net>
;; Maintainer: D. Williams <d.williams@posteo.net>
;; Keywords: convenience, games
;; Version: 1.0.2
;; Homepage: https://github.com/integral-dw/dw-passphrase-generator
;; Package-Requires: ((emacs "25.1"))

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

;; This package implements Arnold G. Reinhold's diceware method for
;; Emacs.  For more information regarding diceware, see
;; http://world.std.com/~reinhold/diceware.html
;; Diceware (C) 1995-2020 Arnold G. Reinhold

;; IMPORTANT: Please read the below section to know how to use this
;; package, as it requires additional files *NOT* included in the base
;; install.  Apart from the listed requirements, this package requires (ideally)
;; one or more casino-grade dice for true random number generation.


;; Basic setup:
;;
;; This package requires a so called wordlist to function as intended.
;; This file serves as the pool of random words from which your secure
;; passphrase is generated.  Put a wordlist for passphrase generation
;; into the directory specified by ‘dw-directory’.  It will be
;; automatically generated the first time this package is loaded.  If
;; you don't already have a wordlist, you can find two common, English
;; wordlists below:

;; https://www.eff.org/files/2016/07/18/eff_large_wordlist.txt
;; http://world.std.com/%7Ereinhold/diceware.wordlist.asc

;; The former generates passphrases with long, common words while the
;; latter favors short words and letter combinations, which may be
;; harder to remember but quicker to type.  You can find wordlists
;; for many other languages here:

;; http://world.std.com/~reinhold/diceware.html#Diceware%20in%20Other%20Languages|outline

;; Basic usage:
;;
;; 1) Choose a buffer to write your passphrase in (temporarily).
;; 2) Roll your dice, reading them in some consistent way (e.g. left to
;;    right) every time, and typing them neatly separated in groups of
;;    five.  You can separate them using any character matched by
;;    ‘dw-separator-regexp’ (whitespace by default).  For example, if you
;;    rolled ⚄⚂⚀⚅⚅, type "53166".  You will need five times as many die
;;    rolls as you want words in your passphrase (six being a decent
;;    amount for normal passphrases).
;; 3) Mark the region where you wrote down your sequence of rolls and
;;    use the command ‘dw-passgen-region’.  You may need to choose a
;;    wordlist depending on your setup.  See the documentation for
;;    ‘dw-named-wordlists’ below for how to skip this step and set up
;;    a default wordlist.

;; This package provides the following interactive commands:
;;
;; * dw-passgen-region
;;
;;    The all-in-one interactive passphrase generation command, and
;;    most likely everything you'll ever need from this package.  Just
;;    mark the region containing your written down die rolls and run
;;    the command.

;; * dw-set-wordlist
;;
;;     Manually set a wordlist without invoking ‘dw-passgen-region’,
;;     and regardless of whether a wordlist has been set for the
;;     current buffer before.

;; Final notes:
;; The package itself is not at all required to create diceware
;; passphrases, but automates the table lookup bit of it.

;;; Code:

(require 'seq)
(require 'wid-edit)
(eval-when-compile
  (require 'cl-lib))

(defgroup dw nil
  "Generate diceware passphrases."
  :group 'convenience)

;;; Package-specific errors
;; The specifics and conventions are only relevant if you are
;; interested in writing code depending on this package.  In that
;; case, see the README for a complete documentation of errors and
;; their conventions.

;; Input Errors
(define-error 'dw-bad-roll
  "Invalid die roll"
  'user-error)
(define-error 'dw-incomplete-roll
  "Not enough die rolls for a complete word"
  'dw-bad-roll)
(define-error 'dw-too-short-passphrase
  "Too few words for a secure passphrase"
  'dw-bad-roll)
;; File Errors
(define-error 'dw-bad-wordlist
  "Broken wordlist")
;; Misc RNG Errors
(define-error 'dw-incomplete-int
  "Not enough die rolls for the given integer range"
  'dw-bad-roll)
(define-error 'dw-overflow
  "Too many consecutive die rolls, not implemented")


;;; Package-specific warnings

(defun dw--warn-short-words ()
  "Report a warning for passphrases with too many short words."
  (delay-warning '(dw too-many-short-words)
                 (concat "The generated passphrase has many short words. "
                         "Consider discarding it.")))

(defun dw--warn-bad-random-characters ()
  "Report a warning for incomplete character lookup strings.
This warning is triggered if an entry in ‘dw-random-characters’
unexpectedly cannot assign a die roll to a character, which is
only allowed for entries with a non-nil LAX value."
(delay-warning '(dw bad-dw-random-characters)
               (concat "There were unused rolls. "
                       "‘dw-random-characters’ is probably misconfigured.")))



;;; Constants

(defconst dw--dice-number 5
  "Number of die rolls needed for one word in a passphrase.")

(defconst dw--conversion-limit 10
  "Length of the largest string that allows direct integer conversion.
This constant also governs the maximum number of dice usable to
generate a random integer with ‘dw-generate-ranint’.")

(defconst dw--wordlist-length (expt 6 dw--dice-number)
  "Number of entries needed for a valid wordlist.")


;;; User-facing variables
;; Core API

;;;###autoload
(put 'dw-salt 'risky-local-variable t)
(defcustom dw-salt nil
  "Unique, personal string to append to passphrases.
Salt is a string of non-secret data to append to your
passphrases.  It serves to prevent dictionary attacks, and makes
it harder for potential attackers to brute force multiple keys at
once.

While it is not a good idea to use the same passphrase for
everything, it is best to use the same salt or everything, as it
frees precious mental real estate.  You can use a phone number, a
random string of characters, or anything else for this purpose,
as long as it is sufficiently unique.

It is also a great way to fulfill those pesky demands of some
services to have a special character, a number and an uppercase
character in it without adding mental overhead.

If non-nil, interactive commands should ask whether they should
append the salt, depending on the value of ‘dw-use-salt’.

Appended salt is separated from the remaining passphrase the same
way individual words are, using ‘dw-passphrase-separator’."
  :type '(choice :format "Personal salt: %[Value Menu%] %v"
                (const :tag "none" nil)
                (string :tag "custom string"
                        :format "%v"))
  :risky t
  :group 'dw)

(defcustom dw-use-salt t
  "Non-nil means to (conditionally) append ‘dw-salt’ to generated passphrases.
If set to the symbol ‘prompt’, interactive commands will prompt
the user whether they should append salt.  Any other non-nil
value is equivalent to t, meaning salt is appended automatically.

Appended salt is separated from the remaining passphrase the same
way individual words are, using ‘dw-passphrase-separator’.

This variable has no effect if ‘dw-salt’ is nil."
  :type '(choice :format "Append salt interactively: %[Value Menu%] %v"
                 (const :tag "always" t)
                 (const :tag "ask every time" 'prompt)
                 (const :tag "never" nil))
  :group 'dw)

(defcustom dw-separator-regexp "\\s-"
  "Regular expression to match a single separator character.
Essentially, this regexp defines which characters (apart from the
numerals 1 to 6) are valid to appear in die roll strings.
Allowing separators serves as a convenience for the user to be
able to keep long sequences of die rolls readable on input."
  :type 'regexp
  :group 'dw)

(defcustom dw-minimum-word-count 5
  "Minimum length of a good passphrase (measured in words rolled).

Generating any passphrase shorter than this value will signal an
error by default.

It is generally a bad idea to set this value any lower than 5, as
permitting any shorter passphrase renders diceware passphrase
generation pointless.  It may however be reasonable to set it to
6, the commonly recommended minimum passphrase length."
  :type '(choice
          :format "Minimum security level: %[Value Menu%] %v"
          (const :format "%t (%v words)"
                 :tag "lax" 5)
          (const :format "%t (%v words)"
                 :tag "moderate" 6)
          (const :format "%t (%v words)"
                 :tag "high" 7)
          (const :format "%t (%v words)"
                 :tag "too high to justify using this package" 8)
          (const :format "%t (%v words)"
                 :tag "random essay generator" 9))
  :group 'dw)

;; Extended passphrase generation
;;;###autoload
(put 'dw-random-characters 'risky-local-variable t)
(defcustom dw-random-characters
  '((special-characters "945678^~!#$%=&*()-}+[]\\{>:;\"'<3?/012")
    (numerals "0123456789" . t)
    (alphanumeric-uppercase "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
    (alphanumeric-lowercase "abcdefghijklmnopqrstuvwxyz0123456789"))
  "Alist of strings to randomly choose characters from.

Each element should be a dotted list of the form
\(NAME STRING . LAX)

where NAME (a symbol) is a descriptive name for the STRING’s
contents.  ‘dw-ranstring-region’ will prompt for these
names (with completion).  Choosing the symbol ‘default’ as a name
causes the particular string to always be the default value when
prompted.

LAX, if non-nil, does not enforce the length of STRING to be a
power of 6.  As a consequence, some rolls will fail to produce a
result.

Remark: The number of die rolls needed to generate a single
character increases logarithmically with the number of
characters: Less than 7 characters require 1 die per roll, less
than 36 two, etc.  Some character numbers may produce a high
failure rate (in particular values slightly above 6^n/2), which
can double the (average) number of dice per successfully generated
character."
  :type '(alist
          :key-type (symbol :format "Name: %v" :value default)
          :value-type
          (cons :validate dw--validate-ran-chars
                (string :format "Available characters: %v")
                (choice :format "Match die rolls: %[Toggle%] %v"
                        (const :tag "lax" t)
                        (const :tag "strict" nil))))
  :risky t
  :group 'dw)

(defun dw--validate-ran-chars (cons-widget)
  "Signal an error if string in CONS-WIDGET is unsafe to use."
  (or (dw--validate-ran-string-length cons-widget)
      (dw--validate-ran-string-uniq cons-widget)))

(defun dw--validate-ran-string-length (cons-widget)
  "Check that the car of CONS-WIDGET is a 6^N long string.
If the cdr (LAX) is non-nil, return nil instead.

Note for the technically inclined: In principle it may as well be
okay for non-lax (\"strict\") strings to *divide* a power of 6
instead of actually *being* a power of 6.  However, the number of
die rolls needed per character only increases on average for all
reasonable number ranges."
  (let* ((current-cons (widget-value cons-widget))
         (str-length (length (car current-cons)))
         (lax (cdr current-cons)))
    (cond
     (lax nil)
     ((/= str-length (expt 6 (dw-required-dice str-length)))
      (widget-put cons-widget
                  :error "Non-lax strings must be a power of 6 long")
      cons-widget))))

(defun dw--validate-ran-string-uniq (cons-widget)
  "Check that the string in the car of CONS-WIDGET has no repeating chars."
  (let* ((current-cons (widget-value cons-widget))
         (ran-string (car current-cons))
         (minimized-string (concat (seq-uniq ran-string))))
    (unless (string= ran-string minimized-string)
      (setf (car current-cons) minimized-string)
      (widget-put cons-widget
                  :error "Characters must be unique in string")
      (widget-value-set cons-widget current-cons)
      (widget-setup)
      cons-widget)))


;; Interactive use
;;;###autoload
(put 'dw-directory 'risky-local-variable t)
(defcustom dw-directory (locate-user-emacs-file "diceware")
  "Default directory for diceware wordlists for interactive functions.
If this directory is not present, it is automatically generated."
  :type 'directory
  :risky t
  :set (lambda (symbol value)
         (condition-case nil
             (make-directory value)
           (file-already-exists))
         (set-default symbol value))
  :group 'dw)

(defcustom dw-named-wordlists nil
  "Alist of personal wordlists for interactive use.

Each element is a dotted list of the form
\(NAME FILE . CODING)

where NAME is the wordlist’s name used interactively (a symbol),
FILE is a string containing the actual filename of the wordlist
and CODING is the encoding of the file, nil being equivalent to
`utf-8'.

NAME is what interactive commands will prompt for to access a
particular wordlist.

If a wordlist has the special name ‘default’, interactive
commands will use it by default instead of prompting.  Similarly,
if the alist has only one entry, that wordlist is treated as the
default wordlist, regardless of the name.

FILE, if relative, is relative to ‘dw-directory’."
  :type '(alist
          :key-type (symbol :format "Wordlist name: %v" :value default)
          :value-type
          (cons (string :format "Wordlist file: %v")
                (choice
                 :format "Coding: %[Value Menu%] %v"
                 (const :tag "Default (‘utf-8’)" nil)
                 (coding-system
                  :tag "Other coding system")))) ;; TODO: validate string argument
  :group 'dw)

(defcustom dw-passphrase-separator "\s"
  "String inserted between words in interactively generated passphrases.
It is generally not recommended to drop separators (using the
empty string), but possible.  Either way, it is best to decide
for one way to do it and stick to that."
  :type '(string :value "\s")
  :group 'dw)

(defcustom dw-capitalize-words nil
  "Non-nil means capitalize words in interactively generated passphrases."
  :type '(boolean)
  :group 'dw)


;;; Internal variables

(defvar dw-current-wordlist nil
  "Current internalized wordlist for interactive use.
This variable is used by ‘dw-passgen-region’ to access and store
the most recently used wordlist.

Do not set this variable directly; it is automatically
initialized by ‘dw-passgen-region’.  If you want to initialize or
manipulate it from within an interactive command, use
‘dw-set-wordlist’.  If you want to set a default wordlist, see
‘dw-named-wordlists’.

If interactive commands require a wordlist, they should use the
value of this variable.  If they use a different wordlist
generated by ‘dw-build-alist’, they should set this variable")


;;; Internal predicates

(defun dw--valid-rolls-p (string)
  "Return t if STRING is a nonempty sequence of digits from 1 to 6."
  (and (stringp string)
       (not (seq-empty-p string))
       (not (dw--invalid-chars-list string))))


;;; Internal string processing

(defun dw--strip-separators (string)
  "Remove separator chars from STRING.
Which chars constitute as such is governed by
‘dw-separator-regexp’."
  (replace-regexp-in-string
   dw-separator-regexp "" string))

(defun dw--invalid-chars-list (string)
  "Return a list of invalid die rolls in STRING.
The resulting list contains all characters that are not digits
from 1 to 6."
  (seq-difference string "123456"))

(defun dw--internalize-rolls (string)
  "Convert a STRING of die rolls to a base-6 int."
  (string-to-number
   (replace-regexp-in-string "6" "0" string) 6))

;; Sadly, ‘number-to-string’ has no optional BASE argument.
(defun dw--format-die-rolls (int)
  "Convert internally used INT to corresponding string of die rolls."
  (when (>= int 0)
    (let (digits)
      (dotimes (_ dw--dice-number)
          (push (% int 6) digits)
        (setq int (/ int 6)))
      (replace-regexp-in-string "0" "6"
                                (mapconcat #'number-to-string digits "")))))

(defun dw--parse-string (user-string &optional noerror)
  "Parse a USER-STRING of die rolls.

USER-STRING is stripped of junk chars specified by
‘dw-separator-regexp’ and then converted into a list of keys for an
internalized diceware wordlist (an alist).

If the optional second argument NOERROR is non-nil, then return
nil for invalid strings instead of signaling an error."
  (let* ((string (dw--strip-separators user-string))
         (total-rolls (length string))
         error-data)
    (cond
     ((not (dw--valid-rolls-p string))
      (setq error-data
            (if (seq-empty-p string)
                `(dw-incomplete-roll 0 ,dw--dice-number)
              `(dw-bad-roll
                ,(char-to-string
                  (car (dw--invalid-chars-list string)))))))
     ((/= (% total-rolls dw--dice-number) 0)
      (setq error-data
            `(dw-incomplete-roll
              ,total-rolls
              ,(* dw--dice-number
                  (ceiling total-rolls dw--dice-number))))))
    (cond ((and error-data noerror) nil)
          (error-data
           (signal (car error-data) (cdr error-data)))
          (t (mapcar #'dw--internalize-rolls
            (seq-partition string dw--dice-number))))))


;;; Internal wordlist parsing

;; This function is taken from rejeep’s f.el.
(defun dw--read (path &optional coding)
  "Read text file located at PATH, using CODING.
Return the decoded text as multibyte string.

CODING defaults to ‘utf-8’."
  (decode-coding-string
   (with-temp-buffer
     (set-buffer-multibyte nil)
     (setq buffer-file-coding-system 'binary)
     (insert-file-contents-literally path)
     (buffer-substring-no-properties (point-min) (point-max)))
   (or coding 'utf-8)))

(defun dw--read-wordlist (path &optional coding)
  "Internalize plain text wordlist at PATH using CODING.
Return the resulting intermediate list for further processing.

CODING defaults to ‘utf-8’.

Each non-empty line of the file should be of the form
  ROLL WORD

where ROLL is a sequence of five digits from 1 to 6, representing
one of the 6^5 (7776) possible die rolls.  WORD should be a
sequence of (non-whitespace) characters to be used in the
passphrase for that particular ROLL.

Each element of the returned list is a list of strings
corresponding to one (non-empty) line in the file.  Each line is
in return segmented at every space and horizontal tab.

This function is not supposed to be used by itself.  In order to
access a diceware wordlist from a file, see `dw-build-alist'."
  (let ((dice-table (dw--read path coding)))
    (mapcar (lambda (x) (split-string x "[ \t]+" t "[ \t]+"))
            (split-string dice-table "[\f\r\n\v]+" t))))

(defun dw--parse-list (read-list)
  "Parse raw construct READ-LIST, forming a proper diceware alist.
READ-LIST is sanitized before conversion, so that junk entries
are ignored.

This function is not supposed to be used by itself.  In order to
access a diceware wordlist from a file, see `dw-build-alist'."
  (mapcar (lambda (x)
            (cons (dw--internalize-rolls (elt x 0))
                  (elt x 1)))
          (seq-filter
           (lambda (x) (and (dw--valid-rolls-p (car x))
                            (= (length (car x)) dw--dice-number)))
           read-list)))


;;; Checkers
(defun dw--check-passlist (passlist &optional noerror)
  "Check PASSLIST for issues and return it.

If the optional second argument NOERROR is non-nil, then return
nil instead of raising an error for an unusable PASSLIST."
  (let ((word-count (length passlist))
        (pass-length (length (apply #'concat passlist)))
        error-data)
    (cond
     ((< word-count dw-minimum-word-count)
      (setq error-data
            `(dw-too-short-passphrase ,word-count ,dw-minimum-word-count)))
     ;; Taking the estimate from the website (that trying to
     ;; brute-force the wordlist should be more efficient than the
     ;; easier to come up with method of trying every passphrase up to
     ;; the actual length L of the passphrase) yields the following
     ;; estimate (for N words in a phrase and an alphabet of size A):
     ;;
     ;; 6^(5N) ≤ 1 + A^1 + A^2 + ... + A^(L-1) = (A^L - 1)/(A - 1)
     ;;
     ;; Which (approximately) simplifies to
     ;;
     ;; L ≥ 5N/log6(A) + 1.
     ;;
     ;; Assuming A=27 (latin alphabet + SPC), you get the below.  This
     ;; is slightly more strict for 8 words than the homepage's
     ;; recommendation, but I can reason this one more confidently.
     ((< pass-length (round (1+ (* word-count 2.72))))
      (dw--warn-short-words)))
    (cond ((and error-data noerror)
           nil)
          (error-data
           (signal (car error-data) (cdr error-data)))
          (t
           passlist))))

(defun dw--check-wordlist (alist &optional noerror)
  "Check internalized wordlist ALIST for issues and return it.

If the optional second argument NOERROR is non-nil, then return
nil instead of raising an error for an unusable ALIST."
  (let ((wordlist-length (length alist))
        (required-keys (number-sequence 0 (1- dw--wordlist-length)))
        (key-list (mapcar #'car alist))
        missing-keys
        error-data)
    (cond
     ((< wordlist-length dw--wordlist-length)
      (setq error-data `(dw-bad-wordlist
                         (< ,wordlist-length ,dw--wordlist-length))))
     ((> wordlist-length dw--wordlist-length)
      (setq error-data `(dw-bad-wordlist
                         (> ,wordlist-length ,dw--wordlist-length))))
     ((not (equal key-list required-keys))
      (setq missing-keys
            (seq-filter #'identity
                        (cl-mapcar (lambda (x y) (and (/= x y) x))
                              required-keys
                              key-list)))
      (setq error-data `(dw-bad-wordlist
                         ,(dw--format-die-rolls (car missing-keys))))))
    (cond ((and error-data noerror)
           nil)
          (error-data
           (signal (car error-data) (cdr error-data)))
          (t
           alist))))


;;; Basic public API

(defun dw-build-alist (path &optional default-dir coding noerror)
  "Read a plain text wordlist at PATH and convert to an internalized alist.

Each non-empty line of the file should be of the form
  ROLL WORD

where ROLL is a sequence of five digits from 1 to 6, representing
one of the 6^5 (7776) possible die rolls.  WORD should be a
sequence of (non-whitespace) characters to be used in the
passphrase for that particular ROLL.  It must be separated from
ROLL by at least one space or tab character.  Both may be
preceded/followed by an arbitrary amount of whitespace.

Empty lines (as well as lines with invalid contents) are treated
as junk and ignored.

DEFAULT-DIR, if non-nil, is the directory to start with if PATH
is relative.  It defaults to the current buffer’s value of
‘default-directory’.

CODING, if non-nil, is the coding system used for the wordlist.
It defaults to ‘utf-8’.

If the optional fourth argument NOERROR is non-nil, then return
nil instead of raising an error in case of the wordlist being
either invalid or incomplete."
  (let ((dice-file (expand-file-name path default-dir)))

    (dw--check-wordlist
     (sort (dw--parse-list
            (dw--read-wordlist dice-file coding))
           (lambda (x y) (< (car x) (car y))))
     noerror)))

(defun dw-generate-passlist (string alist &optional noerror)
  "Generate a list of words from a STRING of die rolls.
ALIST should be an internalized wordlist generated by
‘dw-build-alist’.  The result is a list of words forming the
actual passphrase.

If the optional third argument NOERROR is non-nil, then return
nil instead of raising an error in case of STRING being either
invalid or incomplete."
  (dw--check-passlist
   (mapcar (lambda (x) (cdr (assq x alist)))
           (dw--parse-string string noerror))
   noerror))

(defun dw-generate-passphrase (string alist &optional separator strfun)
  "Convert a STRING of die rolls to a complete passphrase.
STRING should be a sequence of die rolls meant for passphrase
generation.  ALIST should be an internalized wordlist as
generated by ‘dw-build-alist’.

Words in the passphrase will be separated by the optional
argument SEPARATOR, if non-nil.  SEPARATOR should be a string.
Its default value is \"\\s\".

If the optional fourth argument STRFUN is non-nil, apply STRFUN
to all words in the passphrase.  It may be any kind of string
function of one variable."
  (let ((passlist (dw-generate-passlist string alist))
        (separator (or separator "\s"))
        (wordfun (or strfun #'identity)))

    (mapconcat wordfun passlist separator)))


;;; Additional public functions

(defun dw-required-dice (n)
  "Minimum number of dice to randomly choose between N possible outcomes."
  (ceiling (log n 6)))

(defun dw-generate-ranint (string maxint &optional noerror)
  "Convert STRING of die rolls to a random int from 0 to MAXINT.
STRING is expected to be a sequence of die rolls.
MAXINT is not included in the random number range.
If STRING does not produce a valid value, return nil.

STRING must contain at least log6(MAXINT) die rolls, rounded up.
It may contain more, however (up to a machine-dependent limit).

Unless MAXINT is a number of the form 2^a * 3^b , there is no way
to map all outcomes N dice can produce evenly and exhaustively at
the same time.  Hence, on occasion random number generation will
fail, producing nil as an outcome.  Since the failure chance can
reach up to 50%, it is recommended to choose an appropriate
MAXINT.

If the optional third argument NOERROR is non-nil, then return
nil instead of raising an error in case of STRING."

  (let* ((string (dw--strip-separators string))
         (dice-num (length string))
         (min-dice (dw-required-dice maxint))
         random-int
         error-data)
    (cond ((< dice-num min-dice)
           (setq error-data
                 `(dw-incomplete-int ,dice-num ,min-dice)))
          ((not (dw--valid-rolls-p string))
           (setq error-data
                 `(dw-bad-roll
                   ,(char-to-string (car (dw--invalid-chars-list string))))))
          ;; Does the entire dice string fit into a fixnum int?
          ((< dice-num dw--conversion-limit)
           (setq random-int (dw--internalize-rolls string))
           (if (< random-int (% (expt 6 dice-num) maxint))
               (setq random-int nil)
             (setq random-int (% random-int maxint))))
          ;; With bignums in Emacs 27.1, I could in principle rely on
          ;; arbitrary integer arithmetic.  However, using bignums
          ;; for this is immensely wasteful, especially since this can
          ;; easily be done with fixnums using simple modulo
          ;; arithmetic.  However, it's a feature not worth needlessly
          ;; implementing, especially since this package has a history
          ;; of accumulating needless complexity.  I'll support it
          ;; once someone opens an issue.
          (t
           (setq error-data
                 `(dw-overflow ,dice-num ,dw--conversion-limit))))
    (when (and error-data (not noerror))
      (signal (car error-data) (cdr error-data)))
    random-int))


;;; Private functions for misc. interactive commands
(defvar dw--wordlist-history nil
  "Minibuffer history for previously used wordlists.")

(defun dw--prompt-wordlist ()
  "Read a named wordlist in the minibuffer, with completion.
Returns the name of the wordlist as a string."
  (let* ((names (mapcar #'car dw-named-wordlists))
         (default-list (if (memq 'default names)
                           "default"
                         (or (car dw--wordlist-history)
                             (symbol-name (car names)))))
         symbol-string)
    (setq symbol-string
          (completing-read
           ;; REVIEW: should it be "(default symbol-name)" or
           ;; "(default ‘symbol-name’)"?
           (format "Wordlist (default ‘%s’): " default-list)
           names nil t nil 'dw--wordlist-history default-list))
    (add-to-history 'dw--wordlist-history symbol-string)
    (intern symbol-string)))

(defun dw--prompt-wordlist-file ()
  "Read a wordlist filename, with completion.
Return a mockup entry of ‘dw-named-wordlists’ for internal
processing."
  (let ((file-name
         (read-file-name "Read wordlist file: " dw-directory dw-directory t)))
    (unless (file-regular-p file-name)
      (signal 'dw-bad-wordlist
              (list 'file-regular-p file-name)))
    (list 'ad-hoc file-name)))

(defun dw--generate-charlist (dice-string possible-chars)
  "Convert DICE-STRING into a random sequence of POSSIBLE-CHARS.

Return a cons of the form
\(STRING . RNG-FAILURES)

where STRING is the converted random char sequence, and
RNG-FAILURES is the number of failed character generations."
  (let* ((char-num (length possible-chars))
         (rng-failures 0)
         rand-pos
         rand-chars)
    ;; Convert die rolls to characters.
    (dolist (roll (seq-partition dice-string (dw-required-dice char-num)))
      (setq rand-pos
            (condition-case error
                (dw-generate-ranint roll char-num)
              ;; Inform the user if the number of rolls does not match the
              ;; expected format.
              (dw-incomplete-int
               (message "%s (%i/%i)."
                        "Region is missing die rolls for one additional character"
                        (elt error 1) (elt error 2))
               ;; This edge case is not the RNG's fault
               t)))
      (cond
       ((integerp rand-pos)
        (push (elt possible-chars rand-pos) rand-chars))
       ((not rand-pos)
        (setq rng-failures (1+ rng-failures)))))
    (cons (concat (nreverse rand-chars))
          rng-failures)))

(defun dw--append-salt-maybe (passphrase)
  "Conditionally append ‘dw-salt’ to PASSPHRASE.

Whether this happens automatically or requires user input is
governed by ‘dw-use-salt’, which see."
  (if dw-salt
      (cl-case dw-use-salt
        (prompt
         (if (y-or-n-p "Append salt? ")
             (concat passphrase dw-passphrase-separator dw-salt)
           passphrase))
        ((nil)
         passphrase)
        (t
         (concat passphrase dw-passphrase-separator dw-salt)))
    passphrase))

(defvar dw--random-character-history nil
  "Minibuffer history for previously used generation strings.")

(defun dw--prompt-random-chatacters ()
  "Read an entry from ‘dw-random-characters’, with completion.
Return a cons cell of the form (STRING . LAX), see ‘dw-random-characters’."
  (let* ((names (mapcar #'car dw-random-characters))
         (default-string (if (memq 'default names)
                             "default"
                           (or (car dw--random-character-history)
                               (symbol-name (car names)))))
         symbol-string)
    (setq symbol-string
          (completing-read
           (format "Random string of (default %s): "
                   default-string)
           names nil t nil 'dw--random-character-history default-string))
    (add-to-history 'dw--random-character-history symbol-string)
    (cdr
     (assq (intern symbol-string)
           dw-random-characters))))


;;; Interactive commands
;;;###autoload
(defun dw-set-wordlist (&optional use-default)
  "Set a (named) wordlist for interactive passphrase generation.
This function always returns nil.

Named wordlists are specified by ‘dw-named-wordlists’.  If
‘dw-named-wordlists’ is nil, prompt for a file to use, with
‘dw-directory’ as the default directory.

If the prefix argument USE-DEFAULT is non-nil, use the default
wordlist, if available.  Otherwise, prompt the user for which
wordlist to use.

This function specifically manipulates the active wordlist stored
in ‘dw-current-wordlist’ accessible to ‘dw-passgen-region’.  If
you want to convert a wordlist file into the internal format, use
‘dw-build-alist’ instead."
  (interactive "P")
  (let (wordlist-entry file coding)
    (setq wordlist-entry
          (cond ((null dw-named-wordlists)
                 (dw--prompt-wordlist-file))
                ((= (length dw-named-wordlists) 1)
                 (car dw-named-wordlists))
                ((and use-default
                      (assq 'default dw-named-wordlists)))
                (t
                 (assq
                  (dw--prompt-wordlist)
                  dw-named-wordlists)))
          file (cadr wordlist-entry)
          coding (cddr wordlist-entry)
          dw-current-wordlist (dw-build-alist file dw-directory coding)))
  nil)

;;;###autoload
(defun dw-passgen-region (start end &optional choose-wordlist)
  "Replace sequence of die rolls in region with corresponding passphrase.

Without prefix argument, use the last wordlist used in the same
session.  If no wordlist has been set, use the default wordlist,
if available.  If no default wordlist is available, either prompt
for a named wordlist specified by ‘dw-named-wordlists’ or fall
back to prompting for a file.  With prefix argument, ignore the
presence of a default wordlist.

For additional protection, you can append salt to your passphrase
using ‘dw-salt’.  Salt serves as an additional countermeasure
against the common case of attackers trying to crack multiple
passphrases at once.

Noninteractively, the optional second argument CHOOSE-WORDLIST
serves the same purpose as the prefix argument.

If called from Lisp, the arguments START and END must specify the
region to use for passphrase generation."
  (interactive "*r\nP")
  (when (= start end)
    (user-error "Cannot generate passphrase: empty region"))
  (let* ((strfun (when dw-capitalize-words #'capitalize))
         (dice-string (buffer-substring-no-properties start end))
         (use-default (not choose-wordlist))
         passphrase)
    (unless (and dw-current-wordlist use-default)
      (dw-set-wordlist use-default))
    (setq passphrase
          (dw-generate-passphrase dice-string
                                  dw-current-wordlist
                                  dw-passphrase-separator
                                  strfun))
    (setq passphrase
          (dw--append-salt-maybe passphrase))
    (delete-region start end)
    (insert passphrase)
    passphrase))

;;;###autoload
(defun dw-ranstring-region (start end)
  "Replace sequence of die rolls in region with a random character sequence.

This command uses ‘dw-random-characters’ as a resource for sets
of characters to generate a random string from.  You can use this
function to generate a personal salt from die rolls.  See
‘dw-salt’ for more on salt.

If called from Lisp, the arguments START and END must specify the
region to use for passphrase generation."
  (interactive "*r")
  (when (= start end)
    (user-error "Cannot generate random string: empty region"))
  (when (null dw-random-characters)
    (user-error "Cannot generate random string: ‘dw-random-characters’ is nil"))
  (pcase-let* ((dice-string (dw--strip-separators
                             (buffer-substring-no-properties start end)))
               (`(,possible-chars . ,lax) (dw--prompt-random-chatacters))
               (`(,rand-string . ,rng-failures)
                (dw--generate-charlist dice-string possible-chars)))
    ;; Notify the user of RNG fails
    (cond ((and (/= rng-failures 0) lax)
           (message "%i roll(s) failed to generate a random character."
                    rng-failures))
          ((/= rng-failures 0)
           (dw--warn-bad-random-characters)))
    (delete-region start end)
    (insert rand-string)
    rand-string))

(provide 'dw)
;;; dw.el ends here

;; LocalWords:  wordlists wordlist utf alist https http
