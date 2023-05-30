;;; smog.el --- Analyse the writing style, word use and readability of prose -*- coding: utf-8; lexical-binding: t -*-

;; Copyright FoAM 2020
;;
;; Author: nik gaffney <nik@fo.am>
;; Created: 2020-02-02
;; Version: 0.1
;; Package-Version: 20230530.843
;; Package-Commit: 2fc5fef0f5000027b3550495259a65966c68ec52
;; Package-Requires: ((emacs "24.1") (org "8.1"))
;; Keywords: tools, style, readability, prose
;; URL: https://github.com/zzkt/smog

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

;; A simple tool to analyse the writing style, word use and readability of prose.
;;
;; The analysis is produced by the command line tool 'style'.  It performs
;; several readability tests on the text including; Flesch-Kincaid readability
;; tests, Automated readability index (aka “ARI”), Coleman-Liau Index, Gunning
;; fog index (aka "Fog Index"), and SMOG Index (aka "SMOG-Grading", “Simple
;; Measure Of Gobbledygook“). It also summarises word usage and provides
;; information about sentence and paragraph structure.
;;
;; M-x smog-check


;;; Code:

(defgroup smog nil
  "Analyse writing style, word use and readability."
  :group 'wp)

(defcustom smog-command "style -L en"
  "The command to use to run style (including any flags).

From GNU style 1.11
 -L, --language          set the document language.
 -l, --print-long        print all sentences longer than <length> words
 -r, --print-ari         print all sentences with an ARI greater than than <ari>
 -p, --print-passive     print all sentences phrased in the passive voice
 -N, --print-nom         print all sentences containing nominalizations
-n, --print-nom-passive print all sentences phrased in the passive voice or
                         containing nominalizations
 -h, --help              print this message
     --version           print the version"
  :type '(string)
  :group 'smog)

(defcustom smog-reference "\n* Reference

** Kincaid formula

The <<<Kincaid>>> Formula has been developed for Navy training manuals, that ranged in difficulty from 5.5 to 16.3. It is probably best applied to technical documents, because it is based on adult training manuals rather than school book text. Dialogs (often found in fictional texts) are usually a series of short sentences, which lowers the score. On the other hand, scientific texts with many long scientific terms are rated higher, although they are not necessarily harder to read for people who are familiar with those terms.

*Kincaid* = 11.8*syllables/wds+0.39*wds/sentences-15.59

** Automated Readability Index (ARI)

The Automated Readability Index (<<<ARI>>>) is typically higher than Kincaid and Coleman-Liau, but lower than Flesch.

*ARI* = 4.71*chars/wds+0.5*wds/sentences-21.43

** Coleman-Liau Formula

The <<<Coleman-Liau>>> Formula usually gives a lower grade than Kincaid, ARI and Flesch when applied to technical documents.

*Coleman-Liau* = 5.88*chars/wds-29.5*sent/wds-15.8

** Flesch Reading Ease Formula (Flesch Index)

Flesch Reading Ease Formula (<<<Flesch Index>>>) has been developed by Flesch in 1948 and it is based on school text covering grade 3 to 12. It is wide spread, especially in the USA, because of good results and simple computation. The index is usually between 0 (hard) and 100 (easy), standard English documents averages approximately 60 to 70. Applying it to German documents does not deliver good results because of the different language structure.

*Flesch Index* = 206.835-84.6*syll/wds-1.015*wds/sent

** Fog Index

The <<<Fog index>>> has been developed by Robert Gunning. Its value is a school grade. The “ideal” Fog Index level is 7 or 8. A level above 12 indicates the writing sample is too hard for most people to read. Only use it on texts of at least hundred words to get meaningful results. Note that a correct implementation would not count words of three or more syllables that are proper names, combinations of easy words, or made three syllables by suffixes such as -ed, -es, or -ing.

*Fog Index* = 0.4*(wds/sent+100*((wds >= 3 syll)/wds))

** Lix formula

The <<<Lix>>> formula developed by Bjornsson from Sweden is very simple and employs a mapping table as well:

*Lix* = wds/sent+100*(wds >= 6 char)/wds

| Index       | 34 | 38 | 41 | 44 | 48 | 51 | 54 | 57 |
| School year |  5 |  6 |  7 |  8 |  9 | 10 | 11 |    |

** SMOG-Grading

The <<<SMOG-Grading>>> for English texts has been developed by McLaughlin in 1969. Its result is a school grade.

*SMOG-Grading* = square root of (((wds >= 3 syll)/sent)*30) + 3

It has been adapted to German by Bamberger & Vanecek in 1984, who changed the constant +3 to -2.

** Word usage

The <<<word usage>>> counts are intended to help identify excessive use of particular parts of speech.

*Verb Phrases*

The category of verbs labeled “to be” identifies phrases using the passive voice. Use the passive voice sparingly, in favor of more direct verb forms. The flag -p causes style to list all occurrences of the passive voice.

The verb category “aux” measures the use of modal auxiliary verbs, such as “can”, “could”, and “should”. Modal auxiliary verbs modify the mood of a verb.

*Conjunctions*

The conjunctions counted by style are coordinating and subordinating. Coordinating conjunctions join grammatically equal sentence fragments, such as a noun with a noun, a phrase with a phrase, or a clause to a clause. Coordinating conjunctions are “and,” “but,” “or,” “yet,” and “nor.”

Subordinating conjunctions connect clauses of unequal status. A subordinating conjunction links a subordinate clause, which is unable to stand alone, to an independent clause. Examples of subordinating conjunctions are “because,” “although,” and “even if.”

*Pronouns*

Pronouns are contextual references to nouns and noun phrases. Documents with few pronouns generally lack cohesiveness and fluidity. Too many pronouns may indicate ambiguity.

*Nominalizations*

Nominalizations are verbs that are changed to nouns. Style recognizes words that end in “ment,” “ance,” “ence,” or “ion” as nominalizations. Examples are “endowment,” “admittance,” and “nominalization.” Too much nominalization in a document can sound abstract and be difficult to understand.

Further details can be found in the =style(1)= man page.\n"
  "Short descriptions of readability and word use analysis."
  :type '(string)
  :group 'smog)

(defun smog--style-installed-p ()
  "Is the style command installed?"
  (let ((program "style"))
    (unless (executable-find program)
      (message "The program 'style' isn't installed or can't be found.\nTry installing the 'diction' package for your OS or download the source from http://ftp.gnu.org/gnu/diction/"))
    (eq 0 (condition-case nil
                          (call-process program)
                          (error (message "The program 'style' test run exit abnormally."))))))

(defun smog-check-buffer ()
  "Analyse the surface characteristics of a buffer."
  (interactive)
  (when (smog--style-installed-p)
    (let ((smog-buffer (current-buffer))
          (smog-output (get-buffer-create "*Readability*"))
          (smog-target (buffer-file-name (current-buffer))))
      ;; run the shell command. synchronously.
      (shell-command
       (concat smog-command " " (shell-quote-argument smog-target))
       smog-output)
      ;; output the results and add references (in org-mode if it's available)
      (with-current-buffer smog-output
        (goto-char (point-min))
        (if (buffer-modified-p smog-buffer)
            (insert (format
                     "\nChanges to the file '%s' have not been saved. Analysis may be inaccurate.\n\n"
                     smog-target))
            (insert (format "\n*Style analysis* of the file \[\[%s\]\[%s\]\] \n\n"
                            smog-target smog-buffer)))
        (goto-char (point-max))
        (insert smog-reference)
        (when (fboundp 'org-mode)
          (org-mode))
        (when (fboundp 'org-update-radio-target-regexp)
          (org-update-radio-target-regexp))))))

;;;###autoload
(defun smog-check ()
  "Analyse the readability and word use of a selected region or buffer."
  (interactive)
  (when (smog--style-installed-p)
    (let* ((smog-buffer (current-buffer))
           (smog-output (get-buffer-create "*Readability*"))
           (region-p (use-region-p))
           ;; beginning of either buffer or region
           (selection-start (if region-p
                                (region-beginning)
                                (point-min)))
           ;; end of either buffer or region
           (selection-end  (if region-p
                               (region-end)
                               (point-max))))
      ;; run the shell command. synchronously.
      (shell-command-on-region selection-start selection-end
                               (format "%s" smog-command) smog-output)
      ;; output the results and add references (in org-mode if it's available)
      (with-current-buffer smog-output
        (goto-char (point-min))
        (insert (format "\n*Style analysis* of %s*%s*\n\n"
                        (if region-p "the selected region of " "") smog-buffer))
        (goto-char (point-max))
        (insert smog-reference)
        (when (fboundp 'org-mode)
          (org-mode))
        (when (fboundp 'org-update-radio-target-regexp)
          (org-update-radio-target-regexp))))))

(provide 'smog)

;;; smog.el ends here
