;;; erc-twitch.el --- Support for Twitch emotes for ERC.  -*- lexical-binding: t -*-

;; Copyright (C) 2015 Vibhav Pant <vibhavp@gmail.com>

;; Url: https://github.com/vibhavp/erc-twitch
;; Package-Version: 20170427.606
;; Package-Commit: 53c6af0cb72e56d897d30a40e7e5066668d6b5ec
;; Author: Vibhav Pant <vibhavp@gmail.com>
;; Version: 1.0
;; Package-Requires: ((json "1.3") (erc "5.0"))
;; Keywords: twitch erc emotes

;;; Commentary:
;; Support for Twitch emotes on ERC.  Enable with `erc-twitch-enable`.

;;; License:

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.
;; This file is not a part of GNU Emacs.
;;; Code:

(require 'json)
(require 'erc)
(require 'cl-lib)

(defvar erc-twitch-emotes nil)
(defcustom erc-twitch-cache-dir (let ((dir (concat user-emacs-directory "erc-twitch/")))
				  (make-directory dir :parents)
				  dir)
  "Directory to cache images and json files to."
  :group 'erc-twitch
  :type 'directory)

(defcustom erc-twitch-networks (list "irc.twitch.tv")
  "IRC networks for which erc-twitch is enabled."
  :group 'erc-twitch
  :type 'list)

(defcustom erc-twitch-colors t
  "Use twitch user colors for displaying messages."
  :group 'erc-twitch
  :type 'boolean)

(defun erc-twitch--get-emotes-json ()
  (let ((json-object-type 'hash-table))
    (with-current-buffer
	(url-retrieve-synchronously "http://twitchemotes.com/api_cache/v2/global.json")
      (json-read-from-string (buffer-substring-no-properties url-http-end-of-headers (point-max))))))

(defun erc-twitch--read-emotes ()
  (let ((json (erc-twitch--get-emotes-json)))
    (setq erc-twitch-emotes (gethash "emotes" json))))

(defun erc-twitch--make-emote-url (image-id)
  (format "http://static-cdn.jtvnw.net/emoticons/v1/%s/1.0" image-id))

(defun erc-twitch--get-emote-image (image-id)
  (let* ((file (format "%s/%d.png" erc-twitch-cache-dir image-id))
	(cached (file-exists-p file)))
    (unless cached
      (url-copy-file (erc-twitch--make-emote-url image-id) file))
    (create-image file)))

(defun erc-twitch--perform-substitution (buffer)
  (unless erc-twitch-emotes
    (erc-twitch--read-emotes))
  (with-current-buffer buffer
    (let ((wordlist (split-string (buffer-substring-no-properties (point-min) (- (point-max) 1)) " ")))
      (save-excursion
	(goto-char (point-min))
	(dolist (word (cdr wordlist))
	  (let ((emote-hash (gethash word erc-twitch-emotes nil)))
	    (when emote-hash
	      (catch 'break
		(while (re-search-forward word nil t)
		  (replace-match "")
		  (let ((start (point)))
		    (insert-image
		     (erc-twitch--get-emote-image (gethash "image_id" emote-hash)) word)
		    (add-text-properties start (point) '(help-echo word)))
		  (throw 'break nil))))))))))

(defun erc-twitch-replace-text ()
  (if (< emacs-major-version 26)
      (erc-twitch--perform-substitution (current-buffer))
    (save-excursion
      (goto-char (point-min))
      (let* ((message-start (re-search-forward "^<\\(.+\\)> "  nil t))
	     (tags (plist-get (text-properties-at (or message-start (point))) 'tags))
	     (emotes (cadr (assoc-string "emotes" tags)))
	     (color (cadr (assoc-string "color" tags)))
	     image colon-posn emote-id start-pos end-pos emote-name)
	(when (and erc-twitch-colors color (color-defined-p color)
		   (match-beginning 1) (match-end 1))
	  (add-text-properties (match-beginning 1) (match-end 1)
			       `(font-lock-face (:foreground ,color))))
	(when (and (stringp emotes) message-start)
	  (dolist (emote (remove "" (split-string emotes "/")))
	    (setq colon-posn (string-match ":" emote 0)
		  emote-id (string-to-number (substring emote 0 colon-posn))
		  emote (substring emote (1+ colon-posn)))
	    (dolist (indices (split-string emote ","))
	      (cl-destructuring-bind (start-pos end-pos)
		  (mapcar #'string-to-number (split-string indices "-"))
		(cl-incf start-pos message-start)
		(cl-incf end-pos (1+ message-start))
		(unless (and (< start-pos (point-max)) (< end-pos (point-max)))
		  (setq image (erc-twitch--get-emote-image emote-id)
			emote-name (buffer-substring-no-properties start-pos end-pos))
		  (add-text-properties start-pos end-pos `(help-echo ,emote-name))
		  (put-text-property start-pos end-pos 'display image))))))))))

(define-erc-module twitch nil
  "Enables usage of Twitch emotes"
  ;;Enable
  ((add-hook 'erc-insert-modify-hook 'erc-twitch-replace-text)
   (add-hook 'erc-send-modify-hook 'erc-twitch-replace-text))
  ;;Disable
  ((remove-hook 'erc-insert-modify-hook 'erc-twitch-replace-text)
   (remove-hook 'erc-send-modify-hook 'erc-twitch-replace-text)))

(provide 'erc-twitch)
;;; erc-twitch.el ends here
