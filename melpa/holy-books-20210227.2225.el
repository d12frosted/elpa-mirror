;;; holy-books.el --- Org-mode links/tooltips/lookups for Quran & Bible  -*- lexical-binding: t; -*-

;; Copyright (c) 2021 Musa Al-hassy

;; Author: Musa Al-hassy <alhassy@gmail.com>
;; Version: 1.4
;; Package-Version: 20210227.2225
;; Package-Commit: 53ee29d1b1a1a9cbd664c318b01aa1c13011efff
;; Package-Requires: ((s "1.12.0") (dash "2.16.0") (emacs "27.1") (org "9.1"))
;; Keywords: quran, bible, links, tooltips, convenience, comm, hypermedia
;; Repo: https://github.com/alhassy/holy-books
;; Homepage: https://alhassy.github.io/holy-books/

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

;; This library provides common desirable features using the Org interface for
;; when writing about the Quran and the Bible:
;;
;; 0. Links “quran:chapter:verse|colour|size|no-info-p”, or just “quran:chapter:verse”
;;    for retrieving a verse from the Quran. Use “Quran:chapter:verse” to HTML export
;;    as a tooltip. The particular translation can be selected by altering the
;;    HOLY-BOOKS-QURAN-TRANSLAITON variable.
;;
;; 1. Likewise, “bible:book:chapter:verse”.
;;    The particular version can be selected by altering the
;;    HOLY-BOOKS-BIBLE-VERSION variable.
;;
;; 2. Two functions, HOLY-BOOKS-QURAN and HOLY-BOOKS-BIBLE that do the heavy
;;    work of the link types.
;;
;; 3. A link type to produce the Arabic basmallah; e.g., “basmala:darkgreen|20px|span”.
;;
;; Minimal Working Example:
;;
;; Sometimes I want to remember the words of the God of Abraham. In English Bibles,
;; His name is “Elohim”, whereas in Arabic Bibles and the Quran, His name is
;; “Allah”. We can use links to quickly access them, such as Quran:7:157|darkgreen
;; and bible:Deuteronomy:18:18-22|darkblue.  Arab-speaking Christians and Muslims
;; use the Unicode symbol [[green:ﷲ]] to refer to Him ---e.g., they would write ﷲ ﷳ ,
;; “Allah akbar”, to declare the greatness of God-- and, as the previous passage
;; says “in the name of the Lord”, there is a nice calligraphic form that is used
;; by Arabic speakers when starting a task, namely [[basmala:darkgreen|20px|span]]
;; ---this is known as the ‘basmalallah’, which is Arabic for “name of God”.
;; (Using capitalised ‘Quran:⋯’ and ‘Bible:⋯’ results in tooltips.)
;;
;; This file has been tangled from a literate, org-mode, file.

;;; Code:

;; String and list manipulation libraries
;; https://github.com/magnars/dash.el
;; https://github.com/magnars/s.el

(require 's)               ;; “The long lost Emacs string manipulation library”
(require 'dash)            ;; “A modern list library for Emacs”
(require 'cl-lib)          ;; New Common Lisp library; ‘cl-???’ forms.
(require 'org)

(defconst holy-books-version (package-get-version))
(defun holy-books-version ()
  "Print the current holy-books version in the minibuffer."
  (interactive)
  (message holy-books-version))

;;;###autoload
(define-minor-mode holy-books-mode
    "Org-mode links, tooltips, and Lisp look-ups for the Quran & Bible."
  nil nil nil)

(org-link-set-parameters
  "basmala"
  :follow (lambda (label) nil)
  :export (lambda (label description backend)
            (-let [(color size html-tag) (s-split "|" label)]
              (format
               "<%s style=\"color:%s;font-size:%s;padding:25px\">
                     ﷽
                </%s>"
               (or html-tag "center")
               (or color 'darkgreen)
               (or size '60px)
               (or html-tag "center"))))
  :face '(:foreground "green" :weight bold))

(defvar holy-books-quran-cache nil
  "A plist storing the verses looked up by ‘holy-books-quran’ for faster reuse.

Each key in the plist refers to a chapter, and the values are plists:
Keys are verses numbers and values are the actual verses ---but there is
a special key ‘:name’ whose value is the Arabic-English name of the chapter.")

(defvar holy-books-quran-translation "131"
  "The translation code of the Quran; a string.

Possible codes include

Code  Translation
--------------------
131   Dr.  Mustafa Khattab, the Clear Quran (Default)
20    Sahih International
85    Abdul Haleem
19    Picktall
22    Yusuf Ali
95    Abul Ala Maududi
167   Maarif-ul-Quran
57    Transliteration

A longer list of translations can be found here:
https://api.quran.com/api/v3/options/translations")

(defun holy-books-quran (chapter verse)
  "Lookup a verse, as a string, from the Quran.

CHAPTER and VERSE are both numbers, referring to a chapter in the Quran
and a verse it contains.
In the associated Org link, both are treated as strings.

+ Lookups are stored in the variable `holy-books-quran-cache' for faster reuse.
+ Quran lookup is based on https://quran.com .
+ Examples:

    ;; Get verse 2 of chapter 7 of the Quran
    (holy-books-quran 7 2)

    ;; Get English-Arabic name of 7th chapter
    (cl-getf (cl-getf holy-books-quran 7) :name)

The particular translation can be selected by altering the
HOLY-BOOKS-QURAN-TRANSLAITON variable.

--------------------------------------------------------------------------------

There is an Org link form: “quran:chapter:verse|color|size|no-info-p”
Only ‘chapter’ and ‘verse’ are mandatory; when ‘no-info-p’ is given,
the chapter and verse numbers are not mentioned in the resulting output.

Examples:
           quran:7:157|darkgreen|30px|t

           quran:7:157

For now, only Org HTML export is supported.

--------------------------------------------------------------------------------

Finally, there is also an HTML tooltip version with a captial ‘Q’;
it takes the same arguments but only the chapter and verse are actually used.
E.g. Quran:7:157 results in text “Quran 7:157” with a tooltip showing the verse."
  (let (start result)
    ;; get info about the current chapter
    (unless (cl-getf (cl-getf holy-books-quran-cache chapter) :name)
      (switch-to-buffer
       (url-retrieve-synchronously
        (format "https://quran.com/%s/%s?translations=%s"
                chapter verse holy-books-quran-translation)))
      (re-search-forward (format "\"%s " chapter))
      (setq start (point))
      (end-of-line)
      (setq result (buffer-substring-no-properties start (point)))
      (kill-buffer)
      (thread-last (decode-coding-string result 'utf-8)
        (s-chop-suffix "\">")
        (s-split " ")
        (-drop-last 1)
        (mapcar #'s-capitalize)
        (s-join " ")
        (setf (cl-getf (cl-getf holy-books-quran-cache chapter) :name))))

    ;; get the actual verse requested
    (--if-let (cl-getf (cl-getf holy-books-quran-cache chapter) verse)
        it
      (switch-to-buffer
       (url-retrieve-synchronously
        (format "https://quran.com/%s/%s?translations=%s"
                chapter verse holy-books-quran-translation)))
      (re-search-forward "d-block resource")
      (forward-line -2)
      (beginning-of-line)
      (setq start (point))
      (end-of-line)
      (setq result (buffer-substring-no-properties start (point)))
      (kill-buffer)
      (thread-last (decode-coding-string result 'utf-8)
        (s-replace-regexp "<sup.*sup>" "")
        (setf (cl-getf (cl-getf holy-books-quran-cache chapter) verse))))))

;; quran:chapter:verse|color|size|no-info-p
(org-link-set-parameters
 "quran"
 :follow (lambda (_) nil)
 :export (lambda (label _ backend)
           (-let* (((chapter:verse color size no-info-p) (s-split "|" label))
                   ((chapter verse) (s-split ":" chapter:verse)))
             (cond ((eq 'html backend)
                    (format "<span style=\"color:%s;font-size:%s;\">
                             ﴾<em> %s</em>﴿ %s
                       </span>"
                            color size
                            (holy-books-quran chapter verse)
                            (if no-info-p
                                ""
                              (format
                               (concat
                                "<small>"
                                "<a href="
                                "\"https://quran.com/chapter_info/%s?local=en\">"
                                "Quran %s:%s, %s"
                                "</a>"
                                "</small>")
                               chapter
                               chapter
                               verse
                               (cl-getf (cl-getf holy-books-quran-cache chapter)
                                        :name)))))
                   ((eq 'md backend)
                    (format "\n> %s\n>\n> %s\n"
                            (holy-books-quran chapter verse)
                            (if no-info-p
                                ""
                              (format "[Quran %s:%s %s](https://quran.com/chapter_info/%s)"
                                      chapter verse (cl-getf (cl-getf holy-books-quran-cache chapter) :name)
                                      chapter)))))))
 :face '(:foreground "green" :weight bold))


;; Quran:chapter:verse|color|size|no-info-p
(org-link-set-parameters
 "Quran"
 :follow (lambda (_) nil)
 :export (lambda (label _ backend)
           (-let* (((chapter:verse _ __ ___) (s-split "|" label))
                   ((chapter verse) (s-split ":" chapter:verse)))
             (cond ((eq 'html backend)
                    (format "<abbr class=\"tooltip\"
                             title=\"﴾<em> %s</em>﴿ <br><br> %s <br><br> %s\">
                          Quran %s:%s
                       </abbr>&emsp13;"
                            (holy-books-quran chapter verse)
                            (cl-getf (cl-getf holy-books-quran-cache chapter) :name)
                            (format "https://quran.com/%s" chapter)
                            chapter verse))
                   ((eq 'md backend)
                    (format "[Quran %s:%s](%s \"%s - %s\")" chapter verse
                            (format "https://quran.com/%s" chapter)
                            (split-string (holy-books-quran chapter verse))
                            (cl-getf (cl-getf holy-books-quran-cache chapter)
                                     :name))))))
 :face '(:foreground "green" :weight bold))

(defun holy-books-insert-quran ()
 "Insert a Quranic verse at point; prompt user for details."
 (interactive)
 (let ((chapter (string-to-number (read-string "Quran Chapter: ")))
       (verse   (string-to-number (read-string "Quran Verse: "))))
   (if (member 0 (list chapter verse))
       (error (concat "holy-books ∷ There seems to be a typo;"
                      "please enter appropriate numbers."))
     (insert (holy-books-quran chapter verse))
     (fill-paragraph))))

(defvar holy-books-bible-version 'niv
  "The version code of the Holy Bible; a symbol or string.

Possible version codes include:

Code   Version
---------------------------------------
niv    New International Version, DEFAULT
asv    American Standard Version
bbe    Bible in Basic English
drb    Darby's Translation
esv    English Standard Version
kjv    King James Version
nas    New American Standard
nkjv   New King James Version
nlt    New Living Translation
nrs    New Revised Standard Version
rsv    Revised Standard Version
msg    The Message Bible
web    World English Bible
ylt    Young's Literal")

(defun holy-books-bible (book chapter verses)
  "Retrive a verse from the Christian Bible.

CHAPTER is a number.
VERSES is either a number or a string “x-y” of numbers.
BOOK is any of the books of the Bible, with ‘+’ instead of spaces!

Examples:

        (holy-books-bible \"Deuteronomy\" 18 \"18-22\")  ;; Lisp

        bible:Deuteronomy:18:18-22|darkblue   ;; Org-mode

        Bible:Deuteronomy:18:18-22            ;; Tooltip

There is also an Org HTML export link, “bible:book:chapter:verse”
sharing the same optional arguments and variations as the “quran:” link;
see the documentation of the method HOLY-BOOKS-QURAN for details.

The particular version can be selected by altering the
HOLY-BOOKS-BIBLE-VERSION variable.

Currently, Bible lookups are not cached and Quran lookups do not support the
“x-y” verse lookup style.

Possible books include:

 ;; Old Testament
 Genesis Exodus Leviticus Numbers Joshua Judges Ruth
 1+Samuel 2+Samuel 1+Kings 2+Kings 1+Chronicles 2+Chronicles Ezra
 Nehemiah Esther Job Psalms Proverbs Ecclesiastes Song+of+Solomon
 Isaiah Jeremiah Lamentations Ezekiel Daniel Hosea Joel Amos
 Obadiah Jonah Micah Nahum Habakkuk Zephaniah Haggai Zechariah
 Malachi
 ;; New Testament
 Matthew Mark Luke John Acts Romans 1+Corinthians 2+Corinthians
 Galatians Ephesians Philippians Colossians 1+Thessalonians
 2+Thessalonians 1+Timothy 2+Timothy Titus Philemon Hebrews James
 1+Peter 2+Peter 1+John 2+John 3+John Jude Revelation

For example, the following incantation yields the first verse of
the first chapter of each book.

   (s-join \"\n\n<hr>\" (--map (holy-books-bible it 1 1) '(...above list...)))"
  (let (start result)
    (switch-to-buffer
     (url-retrieve-synchronously
      (format "https://www.christianity.com/bible/bible.php?q=%s+%s%%3A%s&ver=%s"
              book chapter verses holy-books-bible-version)))
    (re-search-forward (format "<blockquote>"))
    (setq start (point))
    (re-search-forward (format "</blockquote>"))
    (backward-word)
    (setq result (buffer-substring-no-properties start (point)))
    (kill-buffer)
    (thread-last (decode-coding-string result 'utf-8)
      (s-replace-regexp
       "<span class=\"verse-num\"><strong><a href=\".*?\">.*?</strong> </a>"
       "")
      (s-replace-regexp "<h4>.*?big-chapter-num.*?&nbsp;" "")
      (s-replace-regexp "<a href=\".*?\">.*?</a>" "")
      (s-replace-all '(("</p>" . "") ("<p>" . "") ("</span>" . "")))
      (s-chop-suffix "</")
      (s-chop-suffix "\">"))))

;; bible:book:chapter:verses|color|size|no-info-p
;; Ex. bible:Deuteronomy:18:18-22|darkblue|40px
(org-link-set-parameters
 "bible"
 :follow (lambda (_) nil)
 :export (lambda (label _ backend)
           (-let* (((book:chapter:verse color size no-info-p)
                    (s-split "|" label))
                   ((book chapter verse) (s-split ":" book:chapter:verse)))
             (cond ((eq 'html backend)
                    (format "<span style=\"color:%s;font-size:%s;\">
                             ﴾<em> %s</em>﴿ %s
                       </span>"
                            color size
                            (holy-books-bible book chapter verse)
                            (if no-info-p
                                ""
                              (format
                               (concat "<small>"
                                       "<a href=\"https://www.christianity.com"
                                       "/bible/bible.php?q=%s+%s&ver=niv\">"
                                       "%s %s:%s"
                                       "</a>"
                                       "</small>")
                               book chapter book chapter verse))))
                   ((eq 'md backend)
                    (format "\n> %s\n>\n>%s\n"
                            (holy-books-bible book chapter verse)
                            (if no-info-p
                                ""
                              (format "[%s %s:%s](https://www.christianity.com/bible/bible.php?q=%s+%s&ver=niv)"
                                      book chapter verse
                                      book chapter verse)))))))
 :face '(:foreground "green" :weight bold))

;; Bible:book:chapter:verses|color|size|no-info-p
;; Ex. Bible:Deuteronomy:18:18-22|darkblue|40px
(org-link-set-parameters
 "Bible"
 :follow (lambda (_) nil)
 :export (lambda (label _ backend)
           (-let* (((book:chapter:verse _ __ ___) (s-split "|" label))
                   ((book chapter verse) (s-split ":" book:chapter:verse)))
             (cond ((eq 'html backend)

                    (format "<abbr class=\"tooltip\"
                             title=\"﴾<em> %s</em>﴿ <br><br> %s\">
                         %s %s:%s
                       </abbr>&emsp13;"
                            (s-replace "\"" "″" (holy-books-bible book chapter verse))
                            (format (concat "https://www.christianity.com/"
                                            "bible/bible.php?q=%s+%s")
                                    book chapter)
                            book chapter verse))
                   ((eq 'md backend)
                    (format "[%s %s:%s](%s \"%s\")" book chapter verse
                            (format (concat "https://www.christianity.com/"
                                            "bible/bible.php?q=%s+%s") book chapter)
                            (split-string (s-replace "\"" "″" (holy-books-bible book chapter verse)))
                            )))))
 :face '(:foreground "green" :weight bold))

(defun holy-books-insert-bible ()
 "Insert a Biblical verse at point; prompt user for details.

See the documentation of HOLY-BOOKS-BIBLE for the appropriate
names of books."
 (interactive)
 (let ((book    (read-string "Bible Book: "))
       (chapter (string-to-number (read-string "Bible Chapter: ")))
       (verse   (string-to-number (read-string "Bible Verse: "))))
   (if (member 0 (list chapter verse))
       (error (concat "holy-books ∷ There seems to be a typo;"
                      "please enter appropriate numbers."))
     (insert (s-trim (holy-books-bible book chapter verse)))
     (fill-paragraph))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(provide 'holy-books)

;;; holy-books.el ends here
