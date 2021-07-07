;;; say-what-im-doing.el --- dictate what you're doing with text to speech
;; 
;; Filename: say-what-im-doing.el
;; Description: Make emacs say what you're currently doing with text-to-speech
;; Author: Benaiah Mischenko
;; Maintainer: Benaiah Mischenko
;; Created: Tue May 10 2016
;; Version: 0.2
;; Package-Version: 20160706.1931
;; Package-Commit: 5b2ce6783b02805bcac1107a149bfba3852cd9d5
;; Package-Requires: ()
;; Last-Updated: Tue May 12 2016
;;           By: Benaiah Mischenko
;;     Update #: 1
;; URL: http://github.com/benaiah/say-what-im-doing
;; Doc URL: http://github.com/benaiah/say-what-im-doing
;; Keywords: text to speech, dumb, funny
;; Compatibility: GNU Emacs: 24.x, 25.x
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;;; Commentary:
;; 
;; This makes Emacs say every command you perform out loud, using
;; text-to-speech. There's really no point.
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or (at
;; your option) any later version.
;; 
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;; 
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;;; Code:

(defvar say-what-im-doing-common-commands
  '(
    backward-char
    delete-backward-char
    execute-extended-command
    forward-char
    keyboard-quit
    newline
    next-line
    previous-line
    self-insert-command
    )
  "These comands will not be spoken out loud, as they occur so frequently and repeatedly.")

(defcustom say-what-im-doing-shell-command "say"
  "This is the command-line program that will be used for text-to-speech."
  :group 'say-what-im-doing
  :type 'string)

(defcustom say-what-im-doing-shell-command-options ""
  "Extra options for command."
  :group 'say-what-im-doing
  :type 'string)

(defun say-what-im-doing-command-hook ()
  "This is the function that will be added to `post-command-hook'."
  (if (not (member this-command say-what-im-doing-common-commands))
      (start-process "say-what-im-doing-process"
                     nil say-what-im-doing-shell-command
                     say-what-im-doing-shell-command-options
                     (replace-regexp-in-string "-" " " (format "%s" this-command)))))

;;;###autoload
(define-minor-mode say-what-im-doing-mode
  "This is a mode to make emacs say every command you invoke out
  loud. This uses OS X's \"say\" by default, but can be
  configured to use a different command line program - see
  say-what-im-doing-shell-command."
  :lighter " say"
  :global t
  (if say-what-im-doing-mode
      (add-hook 'post-command-hook 'say-what-im-doing-command-hook)
    (remove-hook 'post-command-hook 'say-what-im-doing-command-hook)))

(provide 'say-what-im-doing)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; say-what-im-doing.el ends here
