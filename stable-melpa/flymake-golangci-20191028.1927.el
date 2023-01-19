;;; flymake-golangci.el --- A flymake handler for go-mode files using Golang CI lint
;; -*- lexical-binding: t; -*-

;; Copyright (c) 2019 Jorge Javier Araya Navarro

;; Author: Jorge Javier Araya Navarro <jorgejavieran@yahoo.com.mx>
;; URL: https://gitlab.com/shackra/flymake-golangci
;; Package-Version: 20191028.1927
;; Package-Commit: dfc31a1a6ae3f087b49fe6f5f21b3866780aa91c
;; Version: 0
;; Package-Requires: ((flymake-easy "0.1") (emacs "24"))

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

;; Usage:
;;   (require 'flymake-golanci)
;;   (add-hook 'go-mode-hook 'flymake-golangci-load)
;;
;; Uses flymake-easy, from https://github.com/purcell/flymake-easy

;;; Prayer:

;; Domine Iesu Christe, Fili Dei, miserere mei, peccatoris
;; Κύριε Ἰησοῦ Χριστέ, Υἱὲ τοῦ Θεοῦ, ἐλέησόν με τὸν ἁμαρτωλόν.
;; אדון ישוע משיח, בנו של אלוהים, רחם עליי, החוטא.
;; Nkosi Jesu Kristu, iNdodana kaNkulunkulu, ngihawukele mina, isoni.
;; Señor Jesucristo, Hijo de Dios, ten misericordia de mí, pecador.
;; Herr Jesus Christus, Sohn Gottes, hab Erbarmen mit mir Sünder.
;; Господи, Иисусе Христе, Сыне Божий, помилуй мя грешного/грешную.
;; Sinjoro Jesuo Kristo, Difilo, kompatu min pekulon.
;; Tuhan Yesus Kristus, Putera Allah, kasihanilah aku, seorang pendosa.
;; Bwana Yesu Kristo, Mwana wa Mungu, unihurumie mimi mtenda dhambi.
;; Doamne Iisuse Hristoase, Fiul lui Dumnezeu, miluiește-mă pe mine, păcătosul.
;; 主耶穌基督，上帝之子，憐憫我罪人。

;;; Code:

(require 'flymake-easy)
(require 'rx)

(defconst flymake-golangci-err-line-patterns
  `(,(rx bol (group (one-or-more (any alnum punct)))
         ":" (group (one-or-more digit))
         ":" (group (one-or-more digit))
         ": " (group (one-or-more (any alnum blank digit))) line-end)
    ,(rx bol (group (one-or-more (any alnum punct)))
         ":" (group (one-or-more digit))
         ":" (group (one-or-more (any alnum blank digit))) line-end)))

(defgroup flymake-golangci nil "flymake-golangci preferences." :group 'flymake-golanci)

(defcustom flymake-golangci-executable "golangci-lint"
  "The Golang CI lint executable to use for syntax checking."
  :safe #'stringp
  :type 'string
  :group 'flymake-golangci)

(defcustom flymake-golangci-deadline "1m"
  "Timeout for running golangci-lint."
  :type 'string
  :group 'flymake-golangci)

(defcustom flymake-golangci-tests nil
  "Analyze *_test.go files."
  :safe #'booleanp
  :type 'boolean
  :group 'flymake-golangci)

(defcustom flymake-golangci-fast nil
  "Run only fast linters."
  :safe #'booleanp
  :type 'boolean
  :group 'flymake-golangci)

(defcustom flymake-golangci-disable-all nil
  "Disable all linters."
  :safe #'booleanp
  :type 'boolean
  :group 'flymake-golangci)

(defcustom flymake-golangci-enable-all nil
  "Enable all linters."
  :safe #'booleanp
  :type 'boolean
  :group 'flymake-golangci)

(defcustom flymake-golangci-enable-linters nil
  "Enable some linters."
  :type '(repeat (string :tag "linter"))
  :group 'flymake-golangci)

(defcustom flymake-golangci-disable-linters nil
  "Disable some linters."
  :type '(repeat (string :tag "linter"))
  :group 'flymake-golangci)

(defun flymake-golangci-command (filename)
  "Construct a command that flymake can use to check golang source in FILENAME."
  (list
   flymake-golangci-executable "run" "--print-issued-lines=false" "--out-format=line-number"
   (when flymake-golangci-fast "--fast")
   (when flymake-golangci-enable-all "--enable-all")
   (when flymake-golangci-disable-all "--disable-all")
   (when flymake-golangci-tests "--tests")
   (when flymake-golangci-enable-linters (concat "--enable=" flymake-golangci-enable-linters))
   (when flymake-golangci-disable-linters (concat "--disable=" flymake-golangci-disable-linters))
   filename))

;;;###autoload
(defun flymake-golangci-load ()
  "Configure flymake mode to check the current buffer's golang code."
  (interactive)
  (flymake-easy-load 'flymake-golangci-command
                     flymake-golangci-err-line-patterns
                     'tempdir
                     "go"))

(provide 'flymake-golangci)
;;; flymake-golangci.el ends here
