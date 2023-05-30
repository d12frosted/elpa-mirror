;;; cue-sheet-mode.el --- Major mode for editing CUE sheet files

;; Copyright © 2017, by Peter Hoeg

;; Author: Peter Hoeg (peter@hoeg.com)
;; Version: 1.1.0
;; Package-Version: 20230522.511
;; Package-Commit: 016dfa8aeed264e15e2f55b0b34fcfdb7e14b9d9
;; Created: 2017
;; Keywords: languages
;; Homepage: https://github.com/peterhoeg/cue-sheet-mode
;; Package-Requires: ((emacs "27.1"))
;; SPDX-License-Identifier: GPL-3.0-or-later
;;
;; This file is not part of GNU Emacs.

;;; Commentary:

;; Major mode for CUE sheet cue files.
;;
;; The official standard supports only a few keywords but in principle many more
;; are in use through REM. This mode treats both the proper keywords and the
;; ones commonly in use in the wild through REM as regular keywords.
;;
;; This mode was previously called `cue-mode' but that clashes with the mode on
;; MELPA used for the CUE data validation language unrelated to this.
;;
;; Additional documentation of the format:
;; https://www.gnu.org/software/ccd2cue/manual/html_node/CUE-sheet-format.html

;;; Code:

(require 'rx)

(defun cue-sheet-mode-lookup-dwim (&optional code)
  "Look up an ISRC `CODE' online."
  (interactive)
  (let* ((isrc (or code (thing-at-point 'word)))
         (url (format "https://isrcsearch.ifpi.org/#!/search?tab=lookup&isrcCode=%s" isrc)))
    (if (string-match (rx bos
                          (= 2 alpha) ; country
                          (= 3 alnum) ; issuer
                          (= 2 digit) ; year
                          (= 5 digit) ; sequence
                          eos) isrc)
        (browse-url url)
      (warn "Invalid ISRC: %s" isrc))))

;;;###autoload
(define-derived-mode cue-sheet-mode conf-mode "CUESheet"
  "Major mode for editing CUE sheet files."

  (rx-define spaces (one-or-more space))
  (rx-define types (or "AUDIO" "BINARY" "CDI/2336" "CDI/2352" "CDG" "MODE1/2048" "MODE1/2352" "MODE2/2336" "MODE2/2352" "MP3" "WAVE"))

  (setq-local comment-start "REM"
              comment-end ""
              font-lock-defaults
              `(((,(rx bol (or "REM")) . 'font-lock-comment-face)
                 (,(rx (or "GENRE") spaces (group (one-or-more (any alnum "/" "-")))) . (1 'font-lock-constant-face))
                 (,(rx (or "CATALOG" "DATE" "DISCID" "ISRC") spaces (group (one-or-more (any alnum "/")))) . (1 'font-lock-variable-name-face))
                 (,(rx (or "CATALOG" "CDTEXTFILE" "COMMENT" "COMPOSER" "DATE" "DISCID" "FILE" "FLAGS" "GENRE" "INDEX" "ISRC" "PERFORMER" "POSTGAP" "PREGAP" "SONGWRITER" "TITLE" "TRACK")) . 'font-lock-keyword-face)
                 (,(rx types) . 'font-lock-type-face)))
              imenu-generic-expression `(("Track" ,(rx bol (optional spaces) "TRACK" spaces (group (one-or-more digit)) spaces types (optional spaces) eol) 1)
                                         ("File"  ,(rx bol (optional spaces) "FILE" spaces "\"" (group (one-or-more not-newline)) "\"" spaces types (optional spaces) eol) 1 ))))

;;;###autoload
(add-to-list 'auto-mode-alist `(,(rx ".cue" eos) . cue-sheet-mode))

(provide 'cue-sheet-mode)

;;; cue-sheet-mode.el ends here
