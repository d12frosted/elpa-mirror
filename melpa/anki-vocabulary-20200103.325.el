;;; anki-vocabulary.el --- Help you to create vocabulary cards in Anki

;; Copyright (C) 2019-2019 DarkSun <lujun9972@gmail.com>.

;; Author: DarkSun <lujun9972@gmail.com>
;; Keywords: lisp, anki, translator, chinese
;; Package: anki-vocabulary
;; Version: 1.0
;; Package-Requires: ((emacs "24.4") (s "1.0") (youdao-dictionary "0.4") (anki-connect "1.0") (s "1.10"))
;; URL: https://github.com/lujun9972/anki-vocabulary.el

;; This file is NOT part of GNU Emacs.

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

;;; Source code
;;
;; anki-vocabulary's code can be found here:
;;   https://github.com/lujun9972/anki-vocabulary.el

;;; Commentary:

;; anki-vocabulary is a plugin that helps you to create vocabulary cards in Anki
;; First of all, execute =M-x anki-vocabulary-set-ankiconnect= to set the correspondence relation for fields in card.
;; Then,select the sentence and execute =M-x anki-vocabulary=


;;; Code:

(require 's)
(require 'cl-lib)
(require 'subr-x)
(require 'youdao-dictionary)
(require 'anki-connect)
(declare-function pdf-view-active-region-text "ext:pdf-view" ())
(declare-function pdf-view-assert-active-region "ext:pdf-view" () t)


(defgroup anki-vocabulary nil
  ""
  :prefix "anki-vocabulary"
  :group 'tools
  :link '(url-link :tag "Github" "https://github.com/lujun9972/anki-vocabulary.el"))

(defcustom anki-vocabulary-deck-name ""
  "Which deck would the word stored."
  :type 'string)

(defcustom anki-vocabulary-model-name ""
  "Specify the model name."
  :type 'string)

(defcustom anki-vocabulary-field-alist nil
  "Specify the corresponding relationship for fields in card."
  :type 'string)

(defcustom anki-vocabulary-audio-fileds nil
  "Specify fields used to store audio."
  :type 'list)

(defcustom anki-vocabulary-before-addnote-functions nil
  "List of hook functions run before add note.

The functions should accept those arguments:
+ expression(单词)
+ sentence(单词所在句子)
+ sentence_bold(单词所在句子,单词加粗)
+ translation(翻译的句子)
+ glossary(单词释义)
+ phonetic(音标)"
  :type 'hook)

(defcustom anki-vocabulary-after-addnote-functions nil
  "List of hook functions run after add note.

The functions should accept those arguments:
+ expression(单词)
+ sentence(单词所在句子)
+ sentence_bold(单词所在句子,单词加粗)
+ translation(翻译的句子)
+ glossary(单词释义)
+ phonetic(音标)"
  :type 'hook)

;;;###autoload
(defun anki-vocabulary-set-ankiconnect ()
  "Set the correspondence relation for fields in card."
  (interactive)
  (let ((deck-names (anki-connect-deck-names))
        (model-names (anki-connect-model-names)))
    (setq anki-vocabulary-deck-name (completing-read "Select the Deck Name:" deck-names))
    (setq anki-vocabulary-model-name (completing-read "Select the Model Name:" model-names))
    (setq anki-vocabulary-field-alist nil)
    (setq anki-vocabulary-audio-fileds nil)
    (let* ((fields (anki-connect-model-field-names anki-vocabulary-model-name))
           (elements '("${expression:单词}" "${glossary:释义}" "${phonetic:音标}" "${sentence:原文例句}" "${sentence_bold:标粗的原文例句}" "${translation:翻译例句}" "${sound:发声}" "SKIP")))
      (dolist (field fields)
        (let* ((prompt (format "%s" field))
               (element (completing-read prompt elements)))
          (unless (string= element "SKIP")
            (if (equal "${sound:发声}" element)
                (cl-pushnew field anki-vocabulary-audio-fileds)
              (setq elements (remove element elements))
              (add-to-list 'anki-vocabulary-field-alist (cons field element)))))))))

(defun anki-vocabulary--get-normal-text ()
  "Get the text in normal mode."
  (let ((txt (if (region-active-p)
                 (buffer-substring-no-properties (region-beginning) (region-end))
               (or (sentence-at-point)
                   (thing-at-point 'line)))))
    (replace-regexp-in-string "[\r\n]+" " " txt)))

(defun anki-vocabulary--get-pdf-text ()
  "Get the text in pdf mode."
  ;; (if (package-installed-p 'pdf-tools)
  ;;     (require 'pdf-view)
  ;;   (error "`pdf-tools` is required!"))
  (pdf-view-assert-active-region)
  (let* ((txt (pdf-view-active-region-text))
         (txt (string-join txt "\n")))
    (replace-regexp-in-string "[\r\n]+" " " txt)))

(defun anki-vocabulary--get-text ()
  "Get the region text."
  (if (derived-mode-p 'pdf-view-mode)
      (anki-vocabulary--get-pdf-text)
    (anki-vocabulary--get-normal-text)))

(defun anki-vocabulary--select-word-in-string (str &optional default-word)
  "Select word in STR.
Optional argument DEFAULT-WORD specify the default word."
  (let ((words (split-string str "[ \f\t\n\r\v,.:?;\"<>()]+")))
    (completing-read "Pick The Word: " words nil nil default-word)))

(defun anki-vocabulary--get-word ()
  "Get the word at point."
  (unless (derived-mode-p 'pdf-view-mode)
    (word-at-point)))

(defcustom anki-vocabulary-word-searcher #'anki-vocabulary--word-searcher-youdao
  "Function used to search word's meaning.

The function should return an alist like
    `((expression . ,expression)
      (glossary . ,glossary)
      (phonetic . ,phonetic))"
  :type 'function)

(defcustom anki-vocabulary-sentence-translator #'anki-vocabulary--sentence-translator-youdao
  "Function used to translate sentence.

The function should return the translation in a string."
  :type 'function)

(defun anki-vocabulary--word-searcher-youdao (word)
  "Search WORD using youdao.

It returns an alist like
    `((expression . ,expression)
      (glossary . ,glossary)
      (phonetic . ,phonetic))"
  (let* ((json (youdao-dictionary--request word))
         (translation (mapcar #'identity (assoc-default 'translation json)))
         (explains (youdao-dictionary--explains json))
         (format-meanings-function (lambda (explain)
                                     "Format the EXPLAIN to meanings list."
                                     (let* ((tag (car (split-string explain "\\. ")))
                                            (meanings (cadr (split-string explain "\\. "))))
                                       (if meanings ;有些explain中不带词性说明，这时就不会有". "分隔符了
                                           (setq tag (concat tag ". "))
                                         (setq meanings tag)
                                         (setq tag ""))
                                       (setq meanings (split-string meanings "；"))
                                       (mapcar (lambda (meaning)
                                                 (format "%s%s" tag meaning))
                                               meanings))))
         (explains (mapcan format-meanings-function explains))
         (web (assoc-default 'web json)) ;array
         (web-explains (mapcar
                        (lambda (k-v)
                          (format "- %s :: %s"
                                  (assoc-default 'key k-v)
                                  (mapconcat #'identity (assoc-default 'value k-v) "; ")))
                        web))
         (basic (cdr (assoc 'basic json)))
         (expression (cdr (assoc 'query json)))
         (glossary (or explains
                       web-explains
                       translation))
         (phonetic (or (cdr (assoc 'phonetic basic))
                       (cdr (assoc 'us-phonetic basic))
                       (cdr (assoc 'uk-phonetic basic))))          ; 音标
         )
    `((expression . ,expression)
      (glossary . ,glossary)
      (phonetic . ,phonetic))))

(defun anki-vocabulary--sentence-translator-youdao (sentence)
  "Translate SENTENCE using youdao."
  (let ((json (youdao-dictionary--request sentence)))
    (aref (assoc-default 'translation json) 0)))

;;;###autoload
(defun anki-vocabulary (&optional sentence word)
  "Translate SENTENCE and WORD, and then create an anki card."
  (interactive)
  (let* ((sentence (or sentence (anki-vocabulary--get-text))) ; 原句
         (word (or word  (anki-vocabulary--select-word-in-string sentence (anki-vocabulary--get-word))))
         (sentence_bold (replace-regexp-in-string (concat "\\b" (regexp-quote word) "\\b")
                                                  (lambda (word)
                                                    (format "<b>%s</b>" word))
                                                  sentence)) ; 粗体标记的句子
         (translation (funcall anki-vocabulary-sentence-translator sentence)) ; 翻译
         (content (funcall anki-vocabulary-word-searcher word))
         (expression (or (cdr (assoc 'expression content))
                         ""))           ; 单词
         (prompt (format "%s(%s):" translation expression))
         (glossary (or (cdr (assoc 'glossary content))
                       ""))
         (glossary (completing-read prompt glossary)) ; 释义
         (phonetic (or (cdr (assoc 'phonetic content))
                       ""))             ; 音标
         (audio-url (youdao-dictionary--format-voice-url expression))
         (audio-filename (format "youdao-%s.mp3" (md5 audio-url))) ;发声
         (data `((expression:单词 . ,expression)
                 (glossary:释义 . ,glossary)
                 (phonetic:音标 . ,phonetic)
                 (sentence:原文例句 . ,sentence)
                 (sentence_bold:标粗的原文例句 . ,sentence_bold)
                 (translation:翻译例句 . ,translation)
                 (sound:发声 . ,(format "[sound:%s]" audio-filename))))
         (fileds (mapcar #'car anki-vocabulary-field-alist))
         (elements (mapcar #'cdr anki-vocabulary-field-alist))
         (values (mapcar (lambda (e)
                           (s-format e 'aget data))
                         elements))
         (fields (cl-mapcar #'cons fileds values)))
    (run-hook-with-args 'anki-vocabulary-before-addnote-functions expression sentence sentence_bold translation glossary phonetic)
    (if anki-vocabulary-audio-fileds
        (let* ((audio-fileds (cond ((listp anki-vocabulary-audio-fileds)
                                    (apply #'vector anki-vocabulary-audio-fileds))
                                   ((stringp anki-vocabulary-audio-fileds)
                                    (vector anki-vocabulary-audio-fileds))
                                   (t [])))
               (audio `(("url" . ,audio-url)
                        ("filename" . ,audio-filename)
                        ("fields" . ,audio-fileds))))
          (anki-connect-add-note anki-vocabulary-deck-name anki-vocabulary-model-name fields audio))
      (anki-connect-add-note anki-vocabulary-deck-name anki-vocabulary-model-name fields))
    (run-hook-with-args 'anki-vocabulary-after-addnote-functions expression sentence sentence_bold translation glossary phonetic)))

(provide 'anki-vocabulary)

;;; anki-vocabulary.el ends here
