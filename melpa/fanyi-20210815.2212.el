;;; fanyi.el --- Not only English-Chinese translator -*- lexical-binding: t -*-

;; Copyright (C) 2021 Zhiwei Chen
;; SPDX-License-Identifier: GPL-3.0-or-later
;; Author: Zhiwei Chen <condy0919@gmail.com>
;; Keywords: convenience, tools
;; Package-Version: 20210815.2212
;; Package-Commit: b7725b4e1ec64d428cf8378b4d5be317d13cf13a
;; URL: https://github.com/condy0919/fanyi.el
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1") (s "1.12.0"))

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
;; A multi translators interface for Emacs.
;;
;; There is only one public command to users: `fanyi-dwim'.

;;; Code:

(require 's)

(require 'dom)
(require 'seq)
(require 'url)
(require 'json)
(require 'chart)
(require 'eieio)
(require 'imenu)
(require 'cl-lib)
(require 'button)
(require 'outline)
(require 'generator)

;; Silence compile warnings.
(defvar url-http-end-of-headers)

(defgroup fanyi nil
  "Not only English-Chinese translator for Emacs."
  :prefix "fanyi-"
  :group 'tools
  :link '(url-link "https://github.com/condy0919/fanyi.el"))

(defcustom fanyi-sound-player
  (or (executable-find "mpv")
      (executable-find "mplayer")
      (executable-find "mpg123"))
  "Program to play sound."
  :type 'string
  :group 'fanyi)

(defcustom fanyi-use-glyphs t
  "Non-nil means use glyphs when available."
  :type 'boolean
  :group 'fanyi)

(defface fanyi-word-face
  '((t (:height 1.75 :weight bold :foreground "dark cyan")))
  "Face used for user requested word."
  :group 'fanyi)

(defface fanyi-dict-face
  '((t (:height 1.25 :weight bold :foreground "#ecbe7b" :extend t)))
  "Face used for dictionary name."
  :group 'fanyi)

(defface fanyi-sub-headline-face
  '((t (:weight bold :foreground "#a9a1e1" :extend t)))
  "Face used for sub-headline. Normally it's part of speech."
  :group 'fanyi)

(defface fanyi-star-face
  '((t (:foreground "gold")))
  "Face used for star of word."
  :group 'fanyi)

(defface fanyi-female-speaker-face
  '((t (:foreground "#ec5e66")))
  "Face used for female speaker button."
  :group 'fanyi)

(defface fanyi-male-speaker-face
  '((t (:foreground "#57a7b7")))
  "Face used for male speaker button."
  :group 'fanyi)

(defface fanyi-list-face
  '((t (:foreground "#51afef")))
  "Face used for list."
  :group 'fanyi)

(defface fanyi-quote-face
  '((t (:inherit font-lock-comment-face)))
  "Face used for quotes of word."
  :group 'fanyi)

(defface fanyi-ah-pronunciation-face
  '((t (:family "Minion New")))
  "Face used for pronunciation of American Heritage dictionary."
  :group 'fanyi)

(defun fanyi-display-glyphs-p ()
  "Can we use glyphs instead of plain text?"
  (and fanyi-use-glyphs (display-images-p)))

(defun fanyi-play-sound (url)
  "Play URL via external program.
See `fanyi-sound-player'."
  (if (not fanyi-sound-player)
      (user-error "Set `fanyi-sound-player' first")
    (start-process fanyi-sound-player nil fanyi-sound-player url)))

(defconst fanyi-buffer-name "*fanyi*"
  "The default name of translation buffer.")

(defconst fanyi-haici-distribution-chart-title
  "fanyi-haici-distribution-chart"
  "The default name of HaiCi distribution chart buffer.")

(defvar fanyi-buffer-mtx (make-mutex)
  "The mutex for \"*fanyi*\" buffer.")

(defvar fanyi-speaker-xpm
  "\
/* XPM */
static char* speaker_xpm[] = {
\"13 14 3 1\",
\" 	c None\",
\".	c #000000\",
\"+	s color\",
\"        +++  \",
\"       ++++  \",
\"      +++++ +\",
\"     +++++++ \",
\"     ++++++  \",
\"++++ ++++++  \",
\"++++ ++++++++\",
\"++++ ++++++  \",
\"++++ ++++++  \",
\"     ++++++  \",
\"     +++++++ \",
\"      +++++ +\",
\"       ++++  \",
\"        +++  \"};"
  "The speaker xpm image.")

(defclass fanyi-service ()
  ((word :initarg :word
         :type string
         :protection :protected
         :documentation "The query word.")
   (url :initarg :url
        :type string
        :protection :protected
        :documentation "Dictionary translation url.")
   (sound-url :initarg :sound-url
              :type string
              :protection :protected
              :documentation "Dictionary sound url."))
  "The base class of translation service."
  :abstract t)

(defclass fanyi-haici-service (fanyi-service)
  ((syllable :initarg :syllable
             :initform "-"
             :type string
             :documentation "Syllable of the word.")
   (star :initarg :star
         :initform 0
         :type number
         :documentation "Frequency of the word.")
   (level :initarg :level
          :initform ""
          :type string
          :documentation "Level description of the word.")
   (phonetics :initarg :phonetics
              :type list
              :documentation "Phonetics of the word.
It could be either British pronunciation or American pronunciation.")
   (paraphrases :initarg :paraphrases
                :type list
                :documentation "List of (pos . paraphrase).")
   (distribution :initarg :distribution
                 :initform nil
                 :type list
                 :documentation "List of (percent . sense).")
   (related :initarg :related
            :type list
            :documentation "List of related words. e.g. noun, adj and more forms.")
   (origins :initarg :origins
            :type list
            :documentation "The origins of the word."))
  "The HaiCi translation service.")

(defclass fanyi-etymon-service (fanyi-service)
  ((definitions :initarg :definitions
                :type list
                :documentation "List of (word . def).
Where def could be a list of string/(string 'face face)/(string 'button data)."))
  "The etymonline service.")

(defclass fanyi-ah-service (fanyi-service)
  ((syllable :initarg :syllable
             :type string
             :documentation "Syllable.")
   (sound :initarg :sound
          :type string
          :documentation "Sound uri.")
   (pronunciation :initarg :pronunciation
                  :type string
                  :documentation "Pronunciation.")
   (paraphrases :initarg :paraphrases
                :type list
                :documentation "List of (pos . examples . paraphrase).
Where examples could be nil, paraphrase can be a string or a list of strings or a list of lists of strings.")
   (idioms :initarg :idioms
           :type list
           :documentation "Idioms of the word.")
   (synonyms :initarg :synonyms
             :type list
             :documentation "Synonyms of the word."))
  "The American Heritage dictionary service.")

;; Silence unknown slots warning.
(eieio-declare-slots :word :url :sound-url)
(eieio-declare-slots :syllable :star :level :phonetics :paraphrases :distribution :related :origins)
(eieio-declare-slots :definitions)
(eieio-declare-slots :syllable :sound :pronunciation :paraphrases :idioms :synonyms)

(cl-defmethod fanyi-parse-from ((this fanyi-haici-service) dom)
  "Complete the fields of THIS from DOM tree.
A 'not-found exception may be thrown."
  ;; No brief paraphrase is found, return early.
  (unless (dom-by-class dom "dict-basic-ul")
    (throw 'not-found nil))
  ;; syllable, could be nil.
  (when-let* ((str (dom-attr (dom-by-class dom "keyword") 'tip))
              (matches (s-match "\\([a-zA-Z·]+\\)" str)))
    (oset this :syllable (nth 1 matches)))
  ;; star and level description, could be nil.
  (when-let* ((str (dom-attr (dom-by-class dom "level-title") 'level))
              (matches (s-match "\\([12345]\\)" str)))
    (oset this :star (string-to-number (nth 1 matches)))
    (oset this :level str))
  ;; phonetics, a list of (pronunciation, female sound url, male sound url)
  ;;
  ;; British: female, male
  ;; American: female, male
  (let ((phonetics (dom-children (dom-by-class dom "phonetic"))))
    (oset this :phonetics
          (cl-loop for p being the elements of phonetics using (index idx)
                   ;; British -> 1
                   ;; American -> 3
                   when (or (= idx 1) (= idx 3))
                   collect (list
                            ;; pronunciation
                            (dom-text
                             (dom-search p
                                         (lambda (x)
                                           (string= (dom-attr x 'lang) "EN-US"))))
                            ;; female sound url.
                            ;;
                            ;; Since `dom-by-class' uses regexp to match nodes,
                            ;; "sound" can also match "sound fsound".
                            (dom-attr
                             (dom-search p
                                         (lambda (x)
                                           (string= (dom-attr x 'class) "sound fsound")))
                             'naudio)
                            ;; male sound url
                            (dom-attr
                             (dom-search p
                                         (lambda (x)
                                           (string= (dom-attr x 'class) "sound")))
                             'naudio)))))
  ;; brief paraphrases, list of (pos, paraphrase)
  (let ((paraphrases (butlast (dom-by-tag (dom-by-class dom "dict-basic-ul") 'li))))
    (oset this :paraphrases
          (cl-loop for p in paraphrases
                   for pos = (dom-text (nth 3 p))
                   for para = (dom-text (nth 5 p))
                   collect (list pos para))))
  ;; distribution of senses, could be nil
  (when-let* ((chart-basic (dom-attr (dom-by-id dom "dict-chart-basic") 'data))
              (json (json-read-from-string (url-unhex-string chart-basic))))
    (oset this :distribution
          ;; transform (\1 (percent . 55) (sense . "abc"))
          (cl-loop for j in json
                   collect (seq-map #'cdr (seq-drop j 1)))))
  ;; the related words, could be nil.
  (let ((shapes (dom-children (dom-by-class dom "shape"))))
    (oset this :related
          (seq-partition (cl-loop for i in shapes
                                  when (consp i)
                                  collect (s-trim (dom-text i)))
                         2)))
  ;; The origins of the word, could be nil.
  (let ((origins (dom-attributes (dom-children (dom-by-class dom "layout etm")))))
    (oset this :origins (cl-loop for i in origins
                                 when (consp i)
                                 collect (dom-texts i)))))

(cl-defmethod fanyi-render ((this fanyi-haici-service))
  "Render THIS page into a buffer named `fanyi-buffer-name'.
It's NOT thread-safe, caller should hold `fanyi-buffer-mtx'
before calling this method."
  (with-current-buffer (get-buffer-create fanyi-buffer-name)
    (save-excursion
      ;; Go to the end of buffer.
      (goto-char (point-max))
      (let ((inhibit-read-only t))
        ;; The headline about HaiCi service.
        (insert "# 海词\n\n")
        ;; Syllables and star/level description.
        (insert (oref this :syllable)
                " "
                (s-repeat (oref this :star) "★")
                " "
                (oref this :level)
                "\n\n")
        ;; Phonetics.
        ;; British: pronunciation, female sound url, male sound url
        ;; American: pronunciation, female sound url, male sound url
        (let ((phonetics (oref this :phonetics)))
          (cl-assert (equal (length phonetics) 2))
          (cl-loop for i from 0 to 1
                   for (pronunciation female male) = (nth i phonetics)
                   do (insert (if (equal i 0) "英" "  美"))
                   do (insert " " pronunciation " ")
                   do (insert-button "🔊"
                                     'display (when (fanyi-display-glyphs-p)
                                                (find-image `((:type xpm
                                                                     :data ,fanyi-speaker-xpm
                                                                     :ascent center
                                                                     :color-symbols
                                                                     (("color" . ,(face-attribute 'fanyi-female-speaker-face :foreground)))))))
                                     'action #'fanyi-play-sound
                                     'button-data (format (oref this :sound-url) female)
                                     'face 'fanyi-female-speaker-face
                                     'follow-link t)
                   do (insert " ")
                   do (insert-button "🔊"
                                     'display (when (fanyi-display-glyphs-p)
                                                (find-image `((:type xpm
                                                                     :data ,fanyi-speaker-xpm
                                                                     :ascent center
                                                                     :color-symbols
                                                                     (("color" . ,(face-attribute 'fanyi-male-speaker-face :foreground)))))))
                                     'action #'fanyi-play-sound
                                     'button-data (format (oref this :sound-url) male)
                                     'face 'fanyi-male-speaker-face
                                     'follow-link t))
          (insert "\n\n"))
        ;; Paraphrases.
        ;; - n. 荣誉；荣幸；尊敬；信用；正直；贞洁
        ;; - vt. 尊敬；使荣幸；对...表示敬意；兑现
        ;; ...
        (cl-loop for pa in (oref this :paraphrases)
                 for (pos p) = pa
                 do (insert "- " pos " " p "\n"))
        (insert "\n")
        ;; Make a button for distribution chart.
        (when-let ((dist (oref this :distribution)))
          (insert-button "Click to view the distribution chart"
                         'action (lambda (dist)
                                   (chart-bar-quickie
                                    'vertical
                                    fanyi-haici-distribution-chart-title
                                    (seq-map #'cadr dist) "Senses"
                                    (seq-map #'car dist) "Percent"))
                         'button-data dist
                         'follow-link t)
          (insert "\n\n"))
        ;; Make buttons for related words.
        (when-let ((rs (oref this :related)))
          (cl-loop for r in rs
                   for (k v) = r
                   do (insert k " ")
                   do (insert-button v
                                     'action #'fanyi-dwim
                                     'button-data v
                                     'follow-link t)
                   do (insert " "))
          (insert "\n\n"))
        ;; The origins.
        (when-let ((origins (oref this :origins)))
          (insert "## 起源\n\n")
          (cl-loop for o in origins
                   do (insert "- " o "\n"))
          (insert "\n"))
        ;; Visit the url for more information.
        (insert-button "Browse the full page via eww"
                       'action #'eww
                       'button-data (format (oref this :url) (oref this :word))
                       'follow-link t)
        (insert "\n\n")))))

(cl-defmethod fanyi-parse-from ((this fanyi-etymon-service) dom)
  "Complete the fields of THIS from DOM tree.
If the definitions of word are not found, http 404 error is
expected."
  (let ((defs (dom-by-class dom "word--C9UPa")))
    (oset this :definitions
          (cl-loop for def in defs
                   for title = (dom-text (dom-by-class def "word__name--TTbAA"))
                   for details = (dom-children (dom-by-class def "word__defination--2q7ZH"))
                   collect (list title
                                 (seq-mapcat
                                  (lambda (arg)
                                    (pcase arg
                                      ('(p nil) "\n\n")
                                      (_ (cl-assert (> (length arg) 2))
                                         (seq-concatenate
                                          'list
                                          (when (equal (car arg) 'blockquote)
                                            '("> "))
                                          (seq-map (lambda (arg)
                                                     (cond ((stringp arg) arg)
                                                           ((dom-by-class arg "foreign notranslate")
                                                            (cond ((dom-by-tag arg 'strong)
                                                                   (list (dom-texts arg) 'face 'bold))
                                                                  (t
                                                                   (list (dom-text arg) 'face 'italic))))
                                                           ((dom-by-class arg "crossreference notranslate")
                                                            (list (dom-text arg) 'button (dom-text arg)))))
                                                   (cddr arg))))))
                                  details))))))

(cl-defmethod fanyi-render ((this fanyi-etymon-service))
  "Render THIS page into a buffer named `fanyi-buffer-name'.
It's NOT thread-safe, caller should hold `fanyi-buffer-mtx'
before calling this method.

The /italic/ and *bold* styles are borrowed from `org-mode',
while the quote style is from mailing list."
  (with-current-buffer (get-buffer-create fanyi-buffer-name)
    (save-excursion
      ;; Go to the end of buffer.
      (goto-char (point-max))
      (let ((inhibit-read-only t))
        ;; The headline about Etymology service.
        (insert "# Etymonline\n\n")
        (cl-loop for i in (oref this :definitions)
                 for (word def) = i
                 do (insert "## " word "\n\n")
                 do (seq-do (lambda (arg)
                              (pcase arg
                                (`(,s face italic)
                                 (insert "/" s "/"))
                                (`(,s face bold)
                                 (insert "*" s "*"))
                                (`(,s button ,word)
                                 (insert-button s
                                                'action #'fanyi-dwim
                                                'button-data word
                                                'follow-link t))
                                (s
                                 (insert s))))
                            def)
                 do (while (equal (char-before) ?\n)
                      (delete-char -1))
                 do (insert "\n\n"))))))

(iter-defun fanyi--parse-ah-pseg (dom)
  "Helper function to parse the paraphrase segment DOM of American
Heritage dictionary."
  ;; Order of `cond' matters.
  (cond ((dom-by-class dom "ds-single")
         (let ((ds-single (dom-by-class dom "ds-single")))
           ;; Seems a space always exists at front, so a space is emitted for
           ;; indentation.
           (iter-yield " ")
           (cl-loop for child in (dom-children ds-single)
                    do (pcase child
                         ((pred stringp)
                          (iter-yield child))
                         (`(span nil ,s)
                          (iter-yield s))
                         (`(font nil (i nil ,s))
                          (iter-yield (list s 'face 'italic)))
                         (`(a ,_href (span nil ,s1) ,s2)
                          (iter-yield s1)
                          (iter-yield (list s2 'button s2)))
                         (_ (iter-yield ""))))))
        ((dom-by-class dom "sds-list")
         ;; TODO
         )
        ((dom-by-class dom "ds-list")
         (let ((ds-list (dom-by-class dom "ds-list")))
           (cl-loop for ds in ds-list
                    ;; There is no space at front, so two spaces are emitted for
                    ;; indentation.
                    do (iter-yield "  ")
                    do (cl-loop for child in (dom-children ds)
                                do (pcase child
                                     ((pred stringp)
                                      (iter-yield child))
                                     (`(b nil (font ,_face ,s))
                                      (iter-yield s))
                                     (`(span nil ,s)
                                      (iter-yield s))
                                     (`(font nil (i nil ,s))
                                      (iter-yield (list s 'face 'italic)))
                                     (_ (iter-yield ""))))
                    do (iter-yield "\n\n"))))
        (t (iter-yield "\n"))))

(cl-defmethod fanyi-parse-from ((this fanyi-ah-service) dom)
  "Complete the fields of THIS from DOM tree.
A 'not-found exception may be thrown."
  (let ((results (dom-by-id dom "results")))
    ;; Nothing is found.
    (when (string= (dom-text results) "No word definition found")
      (throw 'not-found nil))
    ;; Syllable, sound and pronunciation.
    (let ((rtseg (dom-by-class results "rtseg")))
      (oset this :syllable (dom-texts (dom-child-by-tag rtseg 'b)))
      (oset this :sound (dom-attr (dom-child-by-tag rtseg 'a) 'href))
      ;; The pronunciation contains private unicodes, which conflict with
      ;; `all-the-icons'. Fix later.
      (oset this :pronunciation (s-trim (s-join ""
                                                (seq-map (lambda (arg)
                                                           (pcase arg
                                                             ((pred stringp) arg)
                                                             (`(font ,_face ,s) s)
                                                             (_ "")))
                                                         (dom-children rtseg))))))
    ;; Paraphrases.
    (let ((psegs (dom-by-class results "pseg")))
      (oset this :paraphrases
            (cl-loop for pseg in psegs
                     for pos = (cl-loop for child in (dom-children pseg)
                                        ;; Italic tags are consecutive, so `while'.
                                        while (listp child)
                                        for (i _nil s) = child
                                        when (and (symbolp i) (eq i 'i) (stringp s))
                                        concat s)
                     for examples = (cl-loop for child in (dom-children pseg)
                                             when (pcase child
                                                    (`(b nil ,s)
                                                     s))
                                             collect (dom-texts child))
                     collect (list pos
                                   examples
                                   (cl-loop for it iter-by (fanyi--parse-ah-pseg pseg)
                                            collect it)))))
    ;; Idioms.
    (let ((idms (dom-by-class results "idmseg")))
      )
    ;; Synonyms.
    (let ((syntx (dom-by-class results "syntx")))
      )
    )
  )

(cl-defmethod fanyi-render ((this fanyi-ah-service))
  "Render THIS page into a buffer named `fanyi-buffer-name'.
It's NOT thread-safe, caller should hold `fanyi-buffer-mtx'
before calling this method."
  (with-current-buffer (get-buffer-create fanyi-buffer-name)
    (save-excursion
      ;; Go to the end of buffer.
      (goto-char (point-max))
      (let ((inhibit-read-only t))
        ;; The headline about American Heritage dictionary.
        (insert "# American Heritage\n\n")
        ;; Syllable, sound and pronunciation.
        (insert (oref this :syllable))
        (insert " ")
        (insert-button "🔊"
                       'action #'fanyi-play-sound
                       'button-data (format (oref this :sound-url) (oref this :sound))
                       'face 'fanyi-male-speaker-face
                       'follow-link t)
        (insert " ")
        ;; Use zero width space as boundary to fontify pronunciation. Since the
        ;; pronunciation has private unicodes, which conflict with
        ;; `all-the-icons', we use `fanyi-ah-pronunciation-face' to specify the
        ;; font family to display.
        (insert "\u200b"
                (oref this :pronunciation)
                "\u200b"
                "\n\n")
        ;; Paraphrases.
        (cl-loop for paraphrase in (oref this :paraphrases)
                 for (pos examples para) = paraphrase
                 do (insert "## " pos " "
                            (s-join ", " (seq-map (lambda (s)
                                                    ;; A word may end with a comma. Fix it manually.
                                                    (setq s (s-trim-right s))
                                                    (when (s-suffix? "," s)
                                                      (setq s (substring s 0 -1)))
                                                    (concat "*" s "*"))
                                                  examples))
                            "\n")
                 do (seq-do (lambda (arg)
                              (pcase arg
                                ((pred stringp)
                                 (insert arg))
                                (`(,s face italic)
                                 (insert "/" s "/"))
                                (`(,s face bold)
                                 (insert "*" s "*"))
                                (`(,s button ,data)
                                 (insert-button s
                                                'action #'fanyi-dwim
                                                'button-data data
                                                'follow-link t))))
                            para))
        (insert "\n\n")
        ))
    ))

;; Translation services.

(defconst fanyi-provider-haici
  (fanyi-haici-service :word "dummy"
                       :url "https://dict.cn/%s"
                       :sound-url "https://audio.dict.cn/%s"))

(defconst fanyi-provider-etymon
  (fanyi-etymon-service :word "dummy"
                        :url "https://www.etymonline.com/word/%s"
                        :sound-url "unused"))

(defconst fanyi-provider-ah
  (fanyi-ah-service :word "dummy"
                    :url "https://ahdictionary.com/word/search.html?q=%s"
                    :sound-url "https://ahdictionary.com/%s"))

(defcustom fanyi-providers `(,fanyi-provider-haici
                             ,fanyi-provider-etymon)
  "The providers used by `fanyi-dwim'."
  :type '(repeat fanyi-service)
  :group 'fanyi)

(defvar fanyi--tasks nil)
(defvar fanyi--tasks-completed 0)

(defun fanyi--spawn (instance)
  "Spawn a thread for searching. The result is powered by INSTANCE."
  (let ((url (format (oref instance :url)
                     (oref instance :word))))
    (cl-pushnew
     (make-thread
      (lambda ()
        (url-retrieve url (lambda (status)
                            ;; Something went wrong.
                            (when (or (not status) (plist-member status :error))
                              (user-error "Something went wrong.\n\n%s" (pp-to-string (plist-get status :error))))
                            ;; Redirection is inhibited.
                            (when (plist-member status :redirect)
                              (user-error "Redirection is inhibited.\n\n%s" (pp-to-string (plist-get status :redirect))))
                            ;; Move point to the real http content.
                            (goto-char url-http-end-of-headers)
                            ;; Parse the html into a dom tree.
                            (let ((dom (libxml-parse-html-region (point) (point-max) url)))
                              (catch 'not-found
                                ;; Extract information.
                                (fanyi-parse-from instance dom)
                                ;; Since `fanyi-render' manipulates `fanyi-buffer-name',
                                ;; a mutex is required in multi-threaded situation.
                                (with-mutex fanyi-buffer-mtx
                                  (fanyi-render instance))
                                (cl-incf fanyi--tasks-completed))))
                      nil
                      t
                      t)))
     fanyi--tasks)))

(defvar fanyi--current-word nil)

(defun fanyi-format-header-line ()
  "Used as `header-line-format'."
  (concat "Translating "
          (propertize fanyi--current-word 'face 'fanyi-word-face)
          (when (< fanyi--tasks-completed (length fanyi-providers))
            (format " %d/%d" fanyi--tasks-completed (length fanyi-providers)))))

(defvar fanyi-mode-font-lock-keywords
  '(;; Dictionary name
    ("^# .*" . 'fanyi-dict-face)
    ;; Sub headline
    ("^##" . 'fanyi-sub-headline-face)
    ;; Quotes
    ("^> .*" . 'fanyi-quote-face)
    ;; Fancy star
    ("★" . 'fanyi-star-face)
    ;; List
    ("^-" . 'fanyi-list-face)
    ;; Use Minion New font to fontify pronunciation of American Heritage
    ;; dictionary.
    ("\u200b\\([^\u200b]+?\\)\u200b" . 'fanyi-ah-pronunciation-face)
    ;; Italic
    ("/\\([^/]+?\\)/" . 'italic)
    ;; Bold
    ("\\*\\([^\\*]+?\\)\\*" . 'bold))
  "Keywords to highlight in `fanyi-mode'.")

(defvar fanyi-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map [tab] #'fanyi-tab)
    (define-key map [backtab] #'fanyi-backtab)
    (define-key map "q" #'quit-window)
    (define-key map "s" #'fanyi-dwim)
    map)
  "Keymap for `fanyi-mode'.")

(define-derived-mode fanyi-mode special-mode "Fanyi"
  "Major mode for viewing multi translators result.
\\{fanyi-mode-map}"
  :interactive nil
  :group 'fanyi

  ;; Make it foldable.
  (setq-local outline-regexp "^#+")
  (setq-local outline-minor-mode t)

  (setq font-lock-defaults '(fanyi-mode-font-lock-keywords))
  (setq imenu-generic-expression '(("Dict" "^# \\(.*\\)" 1)))
  (setq header-line-format '((:eval (fanyi-format-header-line)))))

;;;###autoload
(defun fanyi-dwim (word)
  "Translate WORD."
  (interactive (let* ((default (if (use-region-p)
                                   (buffer-substring-no-properties (region-beginning) (region-end))
                                 (thing-at-point 'word t)))
                      (prompt (if (stringp default)
                                  (format "Search Word (default \"%s\"): " default)
                                "Search Word: ")))
                 (list (read-string prompt nil nil default))))
  ;; libxml2 is required.
  (unless (fboundp 'libxml-parse-html-region)
    (error "This function requires Emacs to be compiled with libxml2"))
  ;; Save current query word.
  (setq fanyi--current-word word)
  ;; Cancel the still pending threads.
  (seq-do (lambda (th)
            (when (thread-live-p th)
              (thread-signal th nil nil)))
          fanyi--tasks)
  (setq fanyi--tasks nil)
  ;; Reset the counter of completed tasks.
  (setq fanyi--tasks-completed 0)

  (let ((buf (get-buffer-create fanyi-buffer-name)))
    (with-current-buffer buf
      (let ((inhibit-read-only t)
            (inhibit-point-motion-hooks t))
        ;; Clear the previous search result.
        (erase-buffer)
        (fanyi-mode)))

    ;; Create a new instance per search.
    (let ((instances (seq-map #'clone fanyi-providers)))
      (seq-do (lambda (i)
                ;; Overwrite the dummy word.
                (oset i :word (url-hexify-string word))
                ;; Do search.
                (fanyi--spawn i))
              instances))
    (pop-to-buffer buf)))

;; Internals

(defun fanyi-tab ()
  "Smart tab in `fanyi-mode'."
  (interactive nil fanyi-mode)
  (unless (derived-mode-p 'fanyi-mode)
    (error "Not in fanyi-mode"))
  (if (outline-on-heading-p)
      (outline-cycle)
    (forward-button 1 t t t)))

(defun fanyi-backtab ()
  "Smart backtab in `fanyi-mode'."
  (interactive nil fanyi-mode)
  (unless (derived-mode-p 'fanyi-mode)
    (error "Not in fanyi-mode"))
  (if (outline-on-heading-p)
      (outline-cycle-buffer)
    (backward-button 1 t t t)))

(provide 'fanyi)
;;; fanyi.el ends here
