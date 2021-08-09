;;; fanyi.el --- English-Chinese translator -*- lexical-binding: t -*-

;; Copyright (C) 2021 Zhiwei Chen
;; SPDX-License-Identifier: GPL-3.0-or-later
;; Author: Zhiwei Chen <condy0919@gmail.com>
;; Keywords: convenience, tools
;; Package-Version: 20210809.56
;; Package-Commit: 49ff88e6185ace94ac8dcb6c3bf04b6abeaa595a
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
(require 'thingatpt)

;; Silence compile warnings.
(defvar url-http-end-of-headers)

(defgroup fanyi nil
  "English-Chinese translator for Emacs."
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
  '((t (:height 1.25 :weight bold :foreground "#a9a1e1" :extend t)))
  "Face used for dictionary name."
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

;; Silence unknown slots warning.
(eieio-declare-slots :word :url :sound-url)
(eieio-declare-slots :syllable :star :level :phonetics :paraphrases :distribution :related :origins)
(eieio-declare-slots :definitions)

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
  (let ((phonetics (dom-children (dom-by-class dom "phonetic")))
        collection)
    ;; British is at index 1, American is at index 3.
    (dolist (idx (list 1 3))
      (let ((node (nth idx phonetics)))
        (cl-pushnew (list
                     ;; pronunciation
                     (dom-text
                      (dom-search node
                                  (lambda (x)
                                    (string= (dom-attr x 'lang) "EN-US"))))
                     ;; female sound url
                     (dom-attr
                      (dom-search node
                                  (lambda (x)
                                    (string= (dom-attr x 'class) "sound fsound")))
                      'naudio)
                     ;; male sound url
                     (dom-attr
                      (dom-search node
                                  (lambda (x)
                                    (string= (dom-attr x 'class) "sound")))
                      'naudio))
                    collection)))
    (oset this :phonetics (nreverse collection)))
  ;; brief paraphrases, list of (pos, paraphrase)
  (let ((paraphrases (butlast (dom-by-tag (dom-by-class dom "dict-basic-ul") 'li))))
    (oset this :paraphrases
          (cl-loop for p in paraphrases
                   collect (list (dom-text (nth 3 p)) (dom-text (nth 5 p))))))
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
        (insert (format "%s %s %s\n\n"
                        (oref this :syllable)
                        (s-repeat (oref this :star) "★")
                        (oref this :level)))
        ;; Phonetics.
        ;; British: pronunciation, female sound url, male sound url
        ;; American: pronunciation, female sound url, male sound url
        (let ((phonetics (oref this :phonetics)))
          (cl-assert (equal (length phonetics) 2))
          (cl-loop
           for i from 0 to 1
           do (cl-destructuring-bind (pronunciation female male) (nth i phonetics)
                (if (equal i 0)
                    (insert "英")
                  (insert "  美"))
                (insert (format " %s " pronunciation))
                (insert-button "♀"
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
                (insert " ")
                (insert-button "♂"
                               'display (when (fanyi-display-glyphs-p)
                                          (find-image `((:type xpm
                                                               :data ,fanyi-speaker-xpm
                                                               :ascent center
                                                               :color-symbols
                                                               (("color" . ,(face-attribute 'fanyi-male-speaker-face :foreground)))))))
                               'action #'fanyi-play-sound
                               'button-data (format (oref this :sound-url) male)
                               'face 'fanyi-male-speaker-face
                               'follow-link t)))
          (insert "\n\n"))
        ;; Paraphrases.
        ;; - n. 荣誉；荣幸；尊敬；信用；正直；贞洁
        ;; - vt. 尊敬；使荣幸；对...表示敬意；兑现
        ;; ...
        (cl-loop for pa in (oref this :paraphrases)
                 do (cl-destructuring-bind (pos p) pa
                      (insert (format "- %s %s\n" pos p))))
        (insert "\n")
        ;; Make a button for distribution chart.
        (insert-button "Click to view the distribution chart"
                       'action (lambda (dist)
                                 (chart-bar-quickie
                                  'vertical
                                  fanyi-haici-distribution-chart-title
                                  (seq-map #'cadr dist) "Senses"
                                  (seq-map #'car dist) "Percent"))
                       'button-data (oref this :distribution)
                       'follow-link t)
        (insert "\n\n")
        ;; Make buttons for related words.
        (let ((rs (oref this :related)))
          (cl-loop for r in rs
                   do (cl-destructuring-bind (k v) r
                        (insert k)
                        (insert " ")
                        (insert-button v
                                       'action #'fanyi-dwim
                                       'button-data v
                                       'follow-link t)
                        (insert " ")))
          (when rs
            (insert "\n\n")))
        ;; The origins.
        (when-let ((origins (oref this :origins)))
          (insert "## 起源\n\n")
          (cl-loop for o in origins
                   do (insert (format "- %s\n" o)))
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
                   collect (progn
                             (let ((title (dom-text (dom-by-class def "word__name--TTbAA")))
                                   (details (dom-children (dom-by-class def "word__defination--2q7ZH"))))
                               (list title
                                     (seq-mapcat
                                      (lambda (node)
                                        (pcase node
                                          ('(p nil) "\n\n")
                                          (_ (cl-assert (> (length node) 2))
                                             (seq-concatenate
                                              'list
                                              (when (equal (car node) 'blockquote)
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
                                                       (cddr node))))))
                                      details))))))))

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
                 do (cl-destructuring-bind (word def) i
                      (insert "## " word "\n\n")
                      (seq-do (lambda (arg)
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
                              def)))
        (while (equal (char-before) ?\n)
          (delete-char -1))
        (insert "\n\n")))))

;; Translation services.

(defconst fanyi-provider-haici
  (fanyi-haici-service :word "dummy"
                       :url "https://dict.cn/%s"
                       :sound-url "https://audio.dict.cn/%s"))

(defconst fanyi-provider-etymon
  (fanyi-etymon-service :word "dummy"
                        :url "https://www.etymonline.com/word/%s"
                        :sound-url "unused"))

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
    ;; Quotes
    ("^> .*" . 'fanyi-quote-face)
    ;; Fancy star
    ("★" . 'fanyi-star-face)
    ;; List
    ("^-" . 'fanyi-list-face)
    ;; Italic
    ("/\\([^/]+?\\)/" . 'italic)
    ;; Bold
    ("\\*\\([^\\*]+?\\)\\*" . 'bold))
  "Keywords to highlight in `fanyi-mode'.")

(defvar fanyi-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map [tab] #'forward-button)
    (define-key map [backtab] #'backward-button)
    (define-key map "q" #'quit-window)
    (define-key map "s" #'fanyi-dwim)
    map)
  "Keymap for `fanyi-mode'.")

(define-derived-mode fanyi-mode special-mode "Fanyi"
  "Major mode for viewing multi translators result.
\\{fanyi-mode-map}"
  :interactive nil
  :group 'fanyi

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

(provide 'fanyi)
;;; fanyi.el ends here
