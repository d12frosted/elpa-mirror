;;; schrute.el --- Help you remember there is a better way to do something.

;; Copyright (C) 2016 Jorge Araya Navarro

;; Author: Jorge Araya Navarro <elcorreo@deshackra.com>
;; Keywords: convenience
;; Package-Commit: 59faa6c4232ae183cea93237301acad8c0763997
;; Package-Requires: ((emacs "24.3"))
;; Package-Version: 20170521.1840
;; Package-X-Original-Version: 0.2.2
;; Homepage: https://bitbucket.org/shackra/dwight-k.-schrute

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
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Fact: There is a way to do something faster, but you forgot.
;;
;; Dwight K. Schrute-mode or `schrute-mode` for short, is a minor global mode
;; that will help you to remember that there is a better way to do
;; something.  By better I mean using commands like `avy-goto-line` instead of
;; making several invocations of `next-line` in a row with either `C-<down>` or
;; `C-n` keybindings.  If your memory is like mine, you'll often forget those
;; features are available, if you commit the mistake of taking the long route,
;; `schrute-mode` will be there to save the day... just don't forget to
;; configure it!.
;;
;; How to configure
;;
;; add something like this to your Emacs configuration:
;;
;; (setf schrute-shortcuts-commands '((avy-goto-line   . (next-line previous-line))
;;                                    (avy-goto-word-1 . (left-char right-char))))
;;
;; (schrute-mode) ;; and turn on the minor mode.

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

(defgroup schrute nil "Help you remember there is a better way to do something"
  :group 'convenience)

(defcustom schrute-shortcuts-commands nil
  "Command that will be use instead of the command invoked multiple times by the user."
  :type 'list :group 'schrute)

(defcustom schrute-time-passed 0.5
  "Maximum period of time to count command repetitions."
  :type 'float :group 'schrute)

(defcustom schrute-command-repetitions 3
  "Number of repetitions before calling the alternative command.  There is no constrains if you set this variable to 0."
  :type 'integer :group 'schrute)

(defcustom schrute-lighter " Schrute"
  "Lighter for the minor mode.  Use a bear emoji if you can!"
  :type 'string :group 'schrute)

(defvar-local schrute--times-last-command 0 "Times the same command have been invoke.")
(defvar-local schrute--time-last-command (current-time) "Time of invocation for `last-command'.")
(defvar schrute--interesting-commands nil "List of commands we care about.  Generated when `schrute-mode' is activated.")

(defun schrute--call-until-success-1 (cmd)
  "Call command `CMD' until the user comply with the input required."
  (when (not (ignore-errors (call-interactively cmd) t))
    (discard-input)
    (schrute--call-until-success-1 cmd)))

(defun schrute--call-until-success (cmd)
  "Call `schrute--call-until-success' with `CMD' and catch any recursion error."
  (condition-case err
      (schrute--call-until-success-1 cmd)
    (error (when (string= "Lisp nesting exceeds ‘max-lisp-eval-depth’" (error-message-string err))
             (message "Oh my God, Jim! `%s' throws errors as a feature, please redefine and ignore its errors!" cmd)))))

(defun schrute--run-command ()
  "Helper that will run an alternative-command."
  (let* ((alternative-command)
         (command-list))
    (dolist (elem schrute-shortcuts-commands)
      (setf alternative-command (car elem))
      (setf command-list (cdr elem))
      (when (or (member this-command command-list)
               (eq this-command command-list))
        (schrute--call-until-success alternative-command)))))

;;;###autoload
(define-minor-mode schrute-mode "Help you remember there is a better way to do something."
  :lighter schrute-lighter
  :group 'schrute
  :global t
  (schrute-mode-activate))

(defun schrute-mode-activate ()
  "Do some setup when the global minor mode is activated."
  (if schrute-mode
      (add-hook 'post-command-hook #'schrute-check-last-command)
    (remove-hook 'post-command-hook 'schrute-check-last-command))
  ;; regenerate the list of commands we are interested
  (let* ((elemen)
         (command-list))
    (setf schrute--interesting-commands nil)
    (dolist (elemen schrute-shortcuts-commands)
      (setf command-list (cdr elemen))
      (cond ((symbolp command-list) (push command-list schrute--interesting-commands))
            ((listp command-list) (setf schrute--interesting-commands (append schrute--interesting-commands command-list)))))))

;;;###autoload
(defun schrute-check-last-command ()
  "Check what command was used last time.

It also check the time between the last two invocations of the
same command and use the alternative command instead."
  (with-local-quit
    ;; be sure to do the checking when there are commands set, the minor mode
    ;; is on and the buffer the cursor is not inside the mini buffer.
    (when (and schrute--interesting-commands schrute-mode (not (minibufferp)))
      (when (eq this-command last-command)
        (if (member this-command schrute--interesting-commands)
            (let ((time-passed (float-time (time-subtract (current-time) schrute--time-last-command))))
              (if (<= time-passed schrute-time-passed)
                  (setf schrute--times-last-command (1+ schrute--times-last-command)))
              (setf schrute--time-last-command (current-time)))))
      (when (> schrute--times-last-command schrute-command-repetitions)
        (setf schrute--times-last-command 0)
        ;; Call the alternative command for `this-command'
        (schrute--run-command)))))

(provide 'schrute)

;;; schrute.el ends here
